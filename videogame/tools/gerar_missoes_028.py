#!/usr/bin/env python3
"""Gera as missões prontas da 0.28 como fases do editor (data/fases/*.json).

Cada missão é montada aqui com funções pequenas (paredes, casas, inimigos, áreas,
interações) e salva no mesmo formato que o editor de fases usa: depois de gerada,
o Lucas pode abrir no editor, duplicar e mudar o que quiser.

Rodar:  python3 tools/gerar_missoes_028.py
"""
import json
import os
import random

RAIZ = os.path.join(os.path.dirname(__file__), "..", "data", "fases")


def c(x, y):
    return "%d,%d" % (x, y)


# --- efeitos ---------------------------------------------------------------------------
def ouro(v): return {"tipo": "ouro", "valor": v}
def item(i, q=1): return {"tipo": "item", "item": i, "qtd": q}
def pista(n, t="", categoria=None):
    efeito = {"tipo": "pista", "nome": n, "texto": t}
    if categoria:
        efeito["categoria"] = categoria
    return efeito
def lore(t): return {"tipo": "lore", "texto": t}
def narrar(ti, te): return {"tipo": "narrar", "titulo": ti, "texto": te}
def alertar(g, t=""): return {"tipo": "alertar", "grupo": g, "texto": t}
def abrir(cels, t=""): return {"tipo": "abrir_caminho", "celulas": [c(*p) for p in cels], "texto": t}
def ativar(i, t=""): return {"tipo": "ativar", "id": i, "texto": t}
def desativar(): return {"tipo": "desativar"}
def vitoria(t): return {"tipo": "vitoria", "texto": t}
def dano(v): return {"tipo": "dano", "valor": v}
def ficha(f): return {"tipo": "ficha", "ficha": f}
def fichas_grupo(f): return {"tipo": "fichas_grupo", "ficha": f}
def descanso(): return {"tipo": "descanso_curto"}
def retirar(g, t=""): return {"tipo": "retirar", "grupo": g, "texto": t}
def queda(q): return {"tipo": "queda", "quadrados": q}


def opc(id, texto, custo="padrao", teste=None, nivel="medio", sucesso=None, falha=None, feito=None,
        uma_vez=True, pistas=0, classes=None, item_req="", sem_inimigos=False, investigador=None):
    """Opção de interação. teste = lista do que somar (perícia, atributo)."""
    o = {"id": id, "texto": texto, "custo": custo, "uma_vez": uma_vez, "sem_inimigos": sem_inimigos,
         "requer_item": item_req, "requer_classe": classes or [], "requer_pistas": pistas,
         "teste": {"ativo": teste is not None, "somar": teste or ["percepcao"], "nivel": nivel},
         "resultados": {"feito": {"texto": "", "efeitos": []}, "sucesso": {"texto": "", "efeitos": []},
                        "falha": {"texto": "", "efeitos": []}}}
    for chave, val in (("sucesso", sucesso), ("falha", falha), ("feito", feito)):
        if val is not None:
            o["resultados"][chave] = {"texto": val[0], "efeitos": val[1] if len(val) > 1 else []}
    if investigador:
        o["investigador"] = investigador
    return o


def variante_investigador(opcao, id, texto, carta):
    """Troca a ação da interação sem mudar o teste nem suas consequências."""
    return dict(opcao, id=id, texto=texto, custo="movimento", investigador={**opcao["investigador"], "carta": carta})


class Fase:
    def __init__(s, id, nome, largura, altura, piso="pedra", descricao=""):
        s.f = {"versao": 1, "id": id, "nome": nome, "descricao": descricao, "largura": largura, "altura": altura,
               "piso": piso, "escuro": False, "luz_ambiente": 0, "abertura": {"titulo": "", "texto": ""},
               "chao": {}, "niveis": {}, "escadas": [], "objetos": [], "luzes": [], "inicio": [],
               "inimigos": [], "grupos": {}, "areas": [], "interacoes": [],
               "objetivo": {"tipo": "derrotar_todos", "texto": "", "rodadas": 8, "mensagem_vitoria": ""},
               "campanha": {"no_mural": True, "texto": "", "recompensa": 100, "requer": [], "ciclo": 0}}
        s.ocupado = {}

    # chão e altura
    def chao(s, x, y, t):
        s.f["chao"][c(x, y)] = t

    def ret_chao(s, x0, y0, x1, y1, t):
        for x in range(x0, x1 + 1):
            for y in range(y0, y1 + 1):
                s.chao(x, y, t)

    def nivel(s, x0, y0, x1, y1, n):
        for x in range(x0, x1 + 1):
            for y in range(y0, y1 + 1):
                if n:
                    s.f["niveis"][c(x, y)] = n
                else:
                    s.f["niveis"].pop(c(x, y), None)

    def escada(s, x, y):
        s.f["escadas"].append(c(x, y))

    # objetos
    def obj(s, x, y, t, colisao=True, visao="padrao"):
        k = c(x, y)
        s.f["objetos"] = [o for o in s.f["objetos"] if o["pos"] != k]
        s.f["objetos"].append({"pos": k, "tipo": t, "colisao": colisao, "visao": visao})

    def tirar_obj(s, x, y):
        k = c(x, y)
        s.f["objetos"] = [o for o in s.f["objetos"] if o["pos"] != k]

    def paredes(s, x0, y0, x1, y1, aberturas=(), tipo="parede"):
        """Contorno de uma sala; aberturas = casas sem parede (portas abertas)."""
        for x in range(x0, x1 + 1):
            for y in range(y0, y1 + 1):
                if (x in (x0, x1) or y in (y0, y1)) and (x, y) not in aberturas:
                    s.obj(x, y, tipo)

    def bloco(s, x0, y0, x1, y1, tipo="casa"):
        """Prédio maciço (vira um modelo só no jogo)."""
        for x in range(x0, x1 + 1):
            for y in range(y0, y1 + 1):
                s.obj(x, y, tipo)

    def luz(s, x, y, claro=2, penumbra=4, nome="luz"):
        s.f["luzes"].append({"pos": c(x, y), "claro": claro, "penumbra": penumbra, "nome": nome})

    # gente
    def inicio(s, *ps):
        s.f["inicio"] = [c(*p) for p in ps]

    def inimigo(s, id, preset, x, y, patamar=None, papel=None, nome=None, grupo="", alerta=False, vigia=4,
                dormindo=False, alvo=False, saque=None, proprios=None):
        e = {"id": id, "preset": preset, "pos": c(x, y), "grupo": grupo, "alerta": alerta, "vigia": vigia,
             "dormindo": dormindo, "alvo": alvo, "saque": saque or [], "proprios": proprios or {"ativo": False}}
        if patamar: e["patamar"] = patamar
        if papel: e["papel"] = papel
        if nome: e["nome"] = nome
        s.f["inimigos"].append(e)

    def grupo(s, g, titulo, texto, alerta=True):
        s.f["grupos"][g] = {"titulo": titulo, "texto": texto, "alerta": alerta}

    def area(s, id, nome, tipo, cels, **kw):
        a = {"id": id, "nome": nome, "tipo": tipo, "celulas": [c(*p) for p in cels], "titulo": kw.get("titulo", ""),
             "texto": kw.get("texto", ""), "parar": kw.get("parar", True), "procurar": kw.get("procurar", False),
             "efeitos": kw.get("efeitos", []),
             "teste": {"somar": kw.get("teste", ["percepcao"]), "nivel": kw.get("nivel", "medio")},
             "resultados": {"sucesso": {"texto": kw.get("sucesso", ("", []))[0], "efeitos": kw.get("sucesso", ("", []))[1]},
                            "falha": {"texto": kw.get("falha", ("", []))[0], "efeitos": kw.get("falha", ("", []))[1]}},
             "armadilha": kw.get("armadilha", {"dano": 4, "ficha": "", "achar": "medio", "evitar": "medio", "desarmar": "medio",
                                               "texto_disparo": "O mecanismo dispara!"})}
        s.f["areas"].append(a)

    def interacao(s, id, nome, x, y, texto, opcoes, alcance=1, oculta=False):
        s.f["interacoes"].append({"id": id, "nome": nome, "pos": c(x, y), "alcance": alcance, "texto": texto,
                                  "oculta": oculta, "opcoes": opcoes})

    def npc(s, id, nome, x, y, texto, opcoes):
        s.obj(x, y, "npc")
        s.interacao(id, nome, x, y, texto, opcoes)

    def salvar(s):
        os.makedirs(RAIZ, exist_ok=True)
        with open(os.path.join(RAIZ, s.f["id"] + ".json"), "w", encoding="utf-8") as arq:
            json.dump(s.f, arq, ensure_ascii=False, indent="\t")
        print("ok", s.f["id"], "inimigos", len(s.f["inimigos"]), "interações", len(s.f["interacoes"]), "áreas", len(s.f["areas"]))


def descanso_em(f, id, nome, x, y, texto, tipo=None):
    if tipo:
        f.obj(x, y, tipo)
    f.interacao(id, nome, x, y, texto, [opc("descansar", "Descanso curto do grupo (o turno inteiro)", custo="turno", sem_inimigos=True,
        feito=("O grupo recupera o fôlego. É um bom lugar para salvar o jogo.", [descanso()]))])


# =================================================================================================
# 1. Investigação: o envenenador de Vau-Cinzento
# =================================================================================================
def investigacao():
    f = Fase("investigacao_vau_cinzento", "Vau-Cinzento: o poço envenenado", 34, 24, "pedra",
             "Investigação numa cidadezinha: três mortos depois de beber do poço da praça. Converse, procure pistas e descubra quem envenenou a água.")
    f.f["abertura"] = {"titulo": "Vau-Cinzento", "texto": "Três moradores morreram depois de beber do poço da praça. A guarda diz que foi febre do rio, mas o prefeito não acredita e pagou a guilda em segredo. Converse com as pessoas, examine o que for estranho e junte pelo menos três pistas antes de acusar alguém. Ninguém aqui sabe quem vocês são."}
    f.f["objetivo"] = {"tipo": "derrotar_alvos", "texto": "Descubra quem envenenou o poço (3 pistas) e detenha o culpado.", "rodadas": 8,
                       "mensagem_vitoria": "O capitão Orsk cai. No armazém, caixas de beladona e um livro com o selo do Círculo Rubro: a cidade estava sendo esvaziada para o culto comprar as terras do vau."}
    f.f["campanha"].update({"texto": "Investigação (nível sugerido 1–2). Três mortos em Vau-Cinzento depois de beber do poço. O prefeito suspeita de alguém de dentro. Muita conversa, pouca luta até a hora certa.",
                            "recompensa": 150, "requer": ["fazenda"]})
    # ruas de pedra; o rio a leste
    f.ret_chao(29, 0, 33, 23, "agua")
    f.ret_chao(26, 0, 28, 23, "madeira")   # cais
    # quarteirões (casas maciças)
    for (x0, y0, x1, y1) in [(1, 1, 5, 4), (8, 1, 12, 3), (1, 8, 4, 11), (1, 15, 5, 18), (8, 19, 13, 22), (16, 1, 20, 3), (15, 19, 19, 22)]:
        f.bloco(x0, y0, x1, y1)
    # praça
    f.ret_chao(11, 9, 18, 14, "terra")
    f.obj(14, 11, "poco")
    for p in [(11, 9), (18, 9), (11, 14), (18, 14)]:
        f.obj(p[0], p[1], "arvore")
    # boticário (sala aberta)
    f.paredes(6, 5, 11, 8, aberturas=[(8, 8)])
    f.ret_chao(7, 6, 10, 7, "madeira")
    f.obj(7, 6, "estante"); f.obj(10, 6, "mesa")
    # taverna
    f.paredes(20, 8, 25, 14, aberturas=[(20, 11)])
    f.ret_chao(21, 9, 24, 13, "madeira")
    f.obj(22, 9, "barril"); f.obj(23, 9, "barril"); f.obj(22, 12, "mesa"); f.obj(24, 12, "mesa")
    f.luz(23, 11, 2, 4, "lareira")
    # posto da guarda
    f.paredes(6, 13, 11, 17, aberturas=[(9, 13)])
    f.ret_chao(7, 14, 10, 16, "madeira")
    f.obj(7, 16, "bau"); f.obj(10, 14, "mesa")
    # armazém do cais (fechado)
    f.paredes(21, 15, 27, 22, aberturas=[])
    f.ret_chao(22, 16, 26, 21, "madeira")
    for p in [(22, 16), (23, 16), (26, 16), (26, 21), (22, 21)]:
        f.obj(p[0], p[1], "caixa")
    f.obj(24, 21, "saco")
    f.obj(21, 18, "porta")
    f.inicio((1, 13), (2, 13), (1, 14), (2, 14))
    f.area("chegada", "Entrada da cidade", "fala", [(1, 12), (2, 12), (3, 13), (3, 14)], titulo="Vau-Cinzento",
           texto="Janelas fechadas em pleno dia. Uma senhora tira o balde do poço, olha para a água e desiste. O cheiro do rio é forte, mas tem outra coisa: algo doce, de flor.")
    # --- pistas ---
    beladona = pista("Beladona no poço", "O poço foi envenenado de propósito com beladona moída.", "mecanismo")
    venda = pista("Venda ao capitão", "O boticário vendeu um saco de beladona ao capitão Orsk.", "intencao")
    botas = pista("Botas de barro vermelho", "Um guarda com botas sujas do barro vermelho do cais esteve no poço à noite.", "cenario")
    moedas = pista("Moedas novas", "O capitão Orsk anda gastando moedas novas de origem desconhecida.", "geral")
    armazem = pista("Armazém do cais", "O capitão frequenta o armazém do cais à noite.", "cenario")
    recibo = pista("Recibo do Círculo Rubro", "Alguém paga o capitão para esvaziar a cidade.", "intencao")
    examinar = opc("examinar", "Examinar a corda e a água (Investigação + Raciocínio)", teste=["Investigação", "raciocinio"], nivel="facil",
        sucesso=("Na corda há resto de pétalas moídas: beladona, e muita. Alguém jogou um saco inteiro aqui, de noite, puxando pela corda.", [beladona]),
        falha=("Só uma mancha roxa. Pode ser qualquer coisa.",), uma_vez=False,
        investigador={"dica_falha": "O boticário pode ajudar a reconhecer o resíduo da corda. Quem conhece Medicina também pode tentar pelo cheiro."})
    f.interacao("poco_praca", "Poço da praça", 14, 11, "A água parece limpa. Na corda do balde, uma mancha roxa seca.", [
        examinar,
        opc("provar", "Reconhecer o veneno pelo cheiro (Medicina + Sabedoria)", teste=["Medicina", "sabedoria"],
            sucesso=("Doce e amargo ao mesmo tempo: beladona. Não é febre do rio. Foi gente.", [beladona]),
            falha=("O cheiro sobe à cabeça. Você se afasta tonto.", [ficha("Penalidade")]),
            investigador={"dica_falha": "Deixe o balde em repouso e procure resíduo na corda. A mancha pode conservar um vestígio que a água já diluiu."}),
        variante_investigador(examinar, "examinar_vestigios", "Examinar os Vestígios na corda e na água", "detetive-analitico"),
        opc("hipotese_corda", "Hipótese de Trabalho sobre a mancha na corda", custo="movimento", uma_vez=False,
            feito=("Se a mancha veio de algo jogado no poço, ainda deve haver resíduo na corda. Você decide procurar pelo material da mancha.",),
            investigador={"carta": "hipotese-de-trabalho", "hipotese": {"interacao": "poco_praca", "opcao": "examinar"}})])
    ler_faro = opc("ler", "Perceber o que ele esconde (Intuição + Percepção)", teste=["Intuição", "percepcao"],
        sucesso=("Ele não é culpado: está com medo. \"Vendi beladona para o capitão da guarda, um saco inteiro. Disse que era para ratos. Se ele souber que eu falei...\"", [venda]),
        falha=("Ele jura que não sabe de nada e pede que vocês saiam.",), uma_vez=False,
        investigador={"dica_falha": "Se Faro não falar, pergunte na praça a quem costuma passar por lá. Marta está sentada perto do poço."})
    f.npc("boticario", "Boticário Faro", 8, 7, "Um senhor magro que não para de arrumar frascos. Ele sua frio quando vocês entram.", [
        ler_faro,
        opc("pressionar", "Pressionar com ameaças (Intimidação + Força)", teste=["Intimidação", "forca"], nivel="facil",
            sucesso=("\"Foi o capitão! O capitão Orsk comprou a beladona!\" Ele chora. Lá fora, alguém viu a cena.", [venda]),
            falha=("Ele se tranca nos fundos. A notícia de que a guilda está ameaçando gente corre a praça.",),
            investigador={"dica_falha": "As ameaças fecharam essa conversa. Você ainda pode procurar testemunhas na praça ou na taverna."}),
        variante_investigador(ler_faro, "entrevista_breve", "Entrevista Breve com Faro", "entrevista-breve"),
        opc("hipotese_faro", "Hipótese de Trabalho sobre a hesitação de Faro", custo="movimento", uma_vez=False,
            feito=("Faro arruma os mesmos frascos desde que vocês entraram. Você prepara perguntas para observar quando ele hesita.",),
            investigador={"carta": "hipotese-de-trabalho", "hipotese": {"interacao": "boticario", "opcao": "ler"}})])
    f.npc("viuva", "Viúva Marta", 13, 13, "Ela perdeu o marido para o poço. Está sentada na borda da praça, sem chorar.", [
        opc("consolar", "Consolar e perguntar com calma (Acalmar + Diplomacia)", teste=["Acalmar", "diplomacia"], nivel="facil",
            sucesso=("\"Na noite antes, eu vi um homem no poço. Capa da guarda, botas sujas de barro vermelho. Barro do cais, do lado dos armazéns.\"", [botas]),
            falha=("Ela olha através de vocês e não diz nada.",), uma_vez=False,
            investigador={"dica_falha": "Dê tempo a Marta. Enquanto isso, pergunte na taverna quem circula pela cidade depois de escurecer."})])
    f.npc("taverneiro", "Taverneiro Bruno", 23, 10, "Um homem enorme que limpa o mesmo copo há uma hora.", [
        opc("jogar", "Apostar nos dados com ele (Jogatina + Raciocínio)", teste=["Jogatina", "raciocinio"],
            sucesso=("Você ganha, e ele ri e fala: \"O capitão Orsk anda pagando rodada com moeda nova, do tipo que nem a prefeitura tem. Diz que é herança.\"", [moedas, ouro(5)]),
            falha=("Você perde 5 pratas e a paciência dele.", [ouro(-5)]), uma_vez=False,
            investigador={"dica_falha": "A mesa ao lado continua conversando sobre a noite. Talvez aceite conversar se vocês pagarem uma rodada."}),
        opc("comprar", "Pagar uma rodada para a mesa (Negociação + Diplomacia)", teste=["Negociação", "diplomacia"], nivel="facil",
            sucesso=("Os bêbados falam: o capitão vive no armazém do cais, de noite. \"Coisa de contrabando\", dizem.", [armazem]),
            falha=("Ninguém fala nada útil, mas todos bebem.",),
            investigador={"dica_falha": "Bruno escuta as mesas a noite inteira. Uma partida de dados pode dar espaço para falar a sós com ele."})])
    descanso_em(f, "lareira", "Lareira da taverna", 24, 11, "Um canto quente e quieto.")
    abrir_bau = opc("abrir", "Abrir a fechadura (Ladinagem + Destreza)", teste=["Ladinagem", "destreza"],
        sucesso=("Dentro: 30 pratas novas e um recibo dobrado com o selo de um círculo vermelho: \"Pelo vau, quando estiver vazio.\"", [recibo, ouro(30), desativar()]),
        falha=("A gazua quebra dentro da fechadura com um estalo alto.", [alertar("guarda_posto", "Os guardas lá fora ouvem o barulho!")]), uma_vez=False,
        investigador={"dica_falha": "A guarda ouviu o estalo. Se for arriscado insistir, a taverna é outra fonte sobre as rondas e os gastos recentes."})
    f.interacao("bau_guarda", "Baú do posto da guarda", 7, 16, "Um baú trancado embaixo da mesa do capitão. O posto está vazio: a guarda está no cais.", [
        abrir_bau,
        opc("forcar", "Arrombar com o pé de cabra (Atletismo + Força)", teste=["Atletismo", "forca"], item_req="pe_de_cabra",
            sucesso=("A tampa salta. O recibo com o círculo vermelho está lá dentro, com as moedas.", [recibo, ouro(30), desativar()]),
            falha=("O barulho chama os guardas!", [alertar("guarda_posto", "Os guardas lá fora ouvem o barulho!")]),
            investigador={"dica_falha": "O pé de cabra não cedeu a tampa. A fechadura ainda pode ser aberta, se vocês conseguirem lidar com a guarda."}),
        variante_investigador(abrir_bau, "maos_ao_caso", "Mãos ao Caso na fechadura do baú", "maos-ao-caso")])
    f.inimigo("guarda_posto1", "guarda_corrupto", 27, 4, grupo="guarda_posto", vigia=1, nome="Guarda de Orsk")
    f.inimigo("guarda_posto2", "guarda_corrupto", 27, 6, grupo="guarda_posto", vigia=1, nome="Guarda de Orsk")
    f.grupo("guarda_posto", "Guardas de Orsk", "\"Ei! Quem mexeu no posto do capitão?\"")
    # armazém: só abre com 3 pistas
    f.interacao("porta_armazem", "Porta do armazém", 21, 18, "Porta grossa, trancada por dentro. Há barro vermelho na soleira e vozes lá dentro.", [
        opc("acusar", "Juntar as pistas e entrar com a guarda da cidade (precisa de 3 pistas)", custo="padrao", pistas=3,
            feito=("Com as provas, os guardas honestos derrubam a porta junto com vocês. O capitão Orsk e os cultistas do Círculo Rubro sacam as armas.", [abrir([(21, 18)]), alertar("armazem", "\"Matem todos! O culto paga em dobro!\"")])),
        opc("arrombar", "Arrombar sem provas (Atletismo + Força)", teste=["Atletismo", "forca"], nivel="dificil",
            sucesso=("A porta cede. Lá dentro, o capitão e os cultistas pegam as armas. Sem provas, vai ser na força.", [abrir([(21, 18)]), alertar("armazem")]),
            falha=("A porta aguenta, e o ombro reclama.", [dano(2)]), uma_vez=False),
        opc("ligar_poco_boticario", "Ligar os Pontos entre o poço e o boticário",
            investigador={"carta": "ligar-os-pontos", "evidencias": [beladona["nome"], venda["nome"]],
                "deducao": {"id": "vau_acesso_ao_veneno", "categoria": "intencao",
                    "texto": "A compra descrita por Faro deu ao capitão acesso à mesma substância usada no poço. Falta ligar alguém que tinha acesso a ela à praça naquela noite."}}),
        opc("ligar_praca_taverna", "Ligar os Pontos entre os relatos da praça e da taverna",
            investigador={"carta": "ligar-os-pontos", "evidencias": [botas["nome"], armazem["nome"]],
                "deducao": {"id": "vau_rota_do_cais", "categoria": "cenario",
                    "texto": "O barro nas botas liga o homem visto no poço à área do cais. A taverna situa o capitão no armazém à noite. Vale verificar o armazém, mas as botas não identificam quem as calçava."}}),
        opc("ligar_taverna_posto", "Ligar os Pontos entre a taverna e o posto da guarda",
            investigador={"carta": "ligar-os-pontos", "evidencias": [moedas["nome"], recibo["nome"]],
                "deducao": {"id": "vau_pagamento", "categoria": "intencao",
                    "texto": "As moedas novas no baú são compatíveis com os gastos que Bruno descreveu. O recibo aponta um pagamento para esvaziar o vau. Os dois achados sustentam esse motivo, sem mostrar como o poço foi envenenado."}}),
        opc("conclusao_fundamentada", "Conclusão Fundamentada sobre o que aconteceu na praça",
            investigador={"carta": "conclusao-fundamentada", "evidencias": [beladona["nome"], venda["nome"], botas["nome"]], "preparo": True,
                "deducao": {"id": "vau_meio_e_oportunidade", "categoria": "mecanismo",
                    "texto": "A beladona confirma o envenenamento. A mancha na corda é um vestígio de como a substância pode ter chegado à água. Faro liga o capitão à compra, e Marta viu uma pessoa com capa da guarda no poço naquela noite. Falta identificar quem usava a capa."}})])
    f.inimigo("orsk", "guarda_corrupto", 25, 18, patamar="elite_escoltado", papel="neutro", nome="Capitão Orsk", grupo="armazem", alvo=True,
              saque=[ouro(40), item("pocao_de_cura_pequena")])
    f.inimigo("cultista1", "cultista", 24, 17, grupo="armazem", saque=[item("antidoto")])
    f.inimigo("cultista2", "cultista", 24, 20, grupo="armazem")
    f.inimigo("rato1", "rato_gigante", 23, 19, grupo="armazem")
    f.inimigo("rato2", "rato_gigante", 26, 19, grupo="armazem")
    f.grupo("armazem", "O Círculo Rubro", "Velas vermelhas num círculo de giz. O capitão Orsk tira o elmo da guarda e pega uma maça.")
    # moradores (enfeite)
    for p in [(15, 7), (19, 16), (6, 20)]:
        f.obj(p[0], p[1], "npc")
    f.interacao("morador", "Morador assustado", 15, 7, "\"Não bebam do poço! Nem da fonte! Só vinho, se tiverem.\"", [
        opc("ouvir", "Ouvir os boatos", custo="nenhum", feito=("\"Dizem que é maldição do rio. Mas o rio sempre esteve aí, e a gente nunca morreu dele.\"", [lore("Os moradores culpam uma maldição do rio.")]))])
    f.salvar()


# =================================================================================================
# 2. Zumbis: a Rua dos Sinos Mudos
# =================================================================================================
def zumbis():
    f = Fase("zumbis_sinos_mudos", "Os Sinos Mudos: o bairro dos mortos", 36, 26, "pedra",
             "Limpe um bairro tomado por zumbis à noite, de rua em rua, até o cemitério onde o coveiro faz os mortos levantarem.")
    f.f["escuro"] = True
    f.f["luz_ambiente"] = 1
    f.f["abertura"] = {"titulo": "Os Sinos Mudos", "texto": "Os sinos do bairro do Sino pararam de tocar há três noites, e os mortos saíram do cemitério. A guarda fechou as ruas com barricadas. Zumbis voltam a levantar se não forem queimados, abençoados ou esmagados: usem fogo, luz e martelo. Limpem o bairro inteiro."}
    f.f["objetivo"] = {"tipo": "derrotar_todos", "texto": "Limpe o bairro: derrote todos os mortos-vivos.", "rodadas": 8,
                       "mensagem_vitoria": "O último zumbi cai. Na capela, os sinos voltam a tocar sozinhos, como se agradecessem. O bairro pode enterrar seus mortos de novo, desta vez de verdade."}
    f.f["campanha"].update({"texto": "Limpeza (nível sugerido 2). Mortos andando no bairro do Sino. Levem fogo, água abençoada e armas pesadas: eles levantam de novo.",
                            "recompensa": 200, "requer": ["masmorra"]})
    # barricada de entrada, ruas, três setores
    for (x0, y0, x1, y1) in [(0, 0, 6, 4), (10, 0, 16, 4), (0, 9, 4, 14), (9, 8, 14, 12), (0, 19, 7, 25), (11, 17, 16, 25), (20, 0, 23, 6)]:
        f.bloco(x0, y0, x1, y1)
    # barricadas internas (separam setores; abrem por interação)
    for y in range(13, 17):
        f.obj(18, y, "caixa")
    f.obj(18, 12, "barril"); f.obj(18, 17, "barril")
    # praça do sino com fontes de luz
    f.ret_chao(5, 5, 9, 8, "terra")
    f.obj(7, 6, "fonte")
    f.obj(5, 15, "fogueira")
    f.obj(15, 6, "tocha_parede")
    # cemitério (grama, lápides) com muro
    f.paredes(20, 8, 35, 25, aberturas=[(20, 15), (20, 16)], tipo="cerca")
    f.ret_chao(21, 9, 34, 24, "terra")
    for (x, y) in [(23, 11), (25, 11), (27, 11), (23, 14), (25, 14), (27, 14), (23, 19), (25, 19), (27, 19), (30, 21), (32, 21)]:
        f.obj(x, y, "lapide")
    # capela
    f.paredes(29, 9, 34, 16, aberturas=[(29, 13)])
    f.ret_chao(30, 10, 33, 15, "pedra")
    f.obj(33, 12, "altar"); f.obj(30, 10, "velas", colisao=False); f.obj(33, 15, "velas", colisao=False)
    f.luz(32, 12, 2, 4, "velas da capela")
    f.inicio((1, 6), (2, 6), (1, 7), (2, 7))
    f.area("entrada", "Barricada", "fala", [(3, 6), (3, 7), (3, 5), (3, 8)], titulo="A barricada",
           texto="Do outro lado da barricada, tudo está quieto demais. Uma lanterna caída ainda queima na rua. Ao longe, um gemido responde ao vento.")
    # setor 1: rua do sino (zumbis dormindo / vagando)
    for i, (x, y) in enumerate([(8, 13), (10, 15), (12, 14), (14, 16), (9, 17)]):
        f.inimigo("zumbi_rua%d" % i, "zumbi", x, y, grupo="rua", vigia=3, dormindo=(i % 2 == 0))
    f.inimigo("inchado_rua", "zumbi_inchado", 15, 14, grupo="rua", vigia=3)
    f.grupo("rua", "A rua do Sino", "Os mortos da rua viram a cabeça ao mesmo tempo. Os que estavam deitados se levantam devagar.")
    # setor 2: becos (carniçais)
    f.inimigo("carnical1", "carnical", 17, 4, grupo="becos", vigia=4)
    f.inimigo("carnical2", "carnical", 19, 7, grupo="becos", vigia=4)
    f.inimigo("zumbi_beco", "zumbi", 25, 4, grupo="becos", vigia=3, dormindo=True)
    f.grupo("becos", "Carniçais", "Duas figuras magras demais saem de um porão, de quatro, farejando.")
    # setor 3: cemitério e capela
    for i, (x, y) in enumerate([(24, 12), (26, 17), (28, 20), (31, 22), (24, 22)]):
        f.inimigo("zumbi_cem%d" % i, "zumbi", x, y, grupo="cemiterio", vigia=4, dormindo=True)
    f.inimigo("inchado_cem", "zumbi_inchado", 28, 16, grupo="cemiterio", vigia=3, dormindo=True)
    f.inimigo("coveiro", "cultista", 32, 13, patamar="elite_escoltado", nome="Hesk, o Coveiro", grupo="capela", vigia=6,
              saque=[ouro(35), item("agua_abencoada"), lore("O diário de Hesk: ele queria só ver a filha de novo. O livro que o ensinou veio de uma torre ao sul.")])
    f.inimigo("carnical_capela", "carnical", 31, 11, grupo="capela", vigia=4)
    f.grupo("cemiterio", "O cemitério", "A terra das covas se mexe. Mãos saem do chão em todo o cemitério.")
    f.grupo("capela", "Hesk, o Coveiro", "Um velho de avental de couro ergue um livro aberto diante do altar. \"Só mais um pouco... ela já quase lembra do meu nome!\"")
    # recursos para queimar e abençoar
    f.obj(4, 17, "barril")
    f.interacao("oleo", "Barris de óleo de lamparina", 4, 17, "Óleo de lamparina da loja de velas, ainda lacrado.", [
        opc("pegar", "Encher frascos (para jogar fogo)", custo="padrao",
            feito=("Vocês enchem três frascos de piche e óleo. Fogo resolve zumbi.", [item("frasco_de_piche", 3), item("tocha", 2)]))])
    f.npc("sobrevivente", "Sobreviventes na janela", 6, 4, "Uma família presa no sobrado grita da janela.", [
        opc("acalmar", "Acalmar e pedir ajuda (Acalmar + Diplomacia)", teste=["Acalmar", "diplomacia"], nivel="facil",
            sucesso=("Eles descem uma cesta pela janela: água benta da capela e um aviso: \"O coveiro! Foi o coveiro, com aquele livro!\"", [item("agua_abencoada", 2), lore("Os sobreviventes viram o coveiro Hesk lendo um livro no cemitério antes dos mortos levantarem.")]),
            falha=("Eles têm medo de abrir a janela. Um deles joga uma tocha: \"Fogo! Usem fogo!\"", [item("tocha")]))])
    f.interacao("barricada_meio", "Barricada da guarda", 18, 14, "Caixas e barris amarrados com corda bloqueiam a rua do cemitério.", [
        opc("desmontar", "Desmontar a barricada (o turno inteiro)", custo="turno",
            feito=("As caixas caem com estrondo. O caminho para o cemitério está aberto, e o barulho acordou alguma coisa lá dentro.", [abrir([(18, y) for y in range(12, 18)]), alertar("cemiterio")])),
        opc("escalar", "Pular por cima (Atletismo + Destreza)", teste=["Atletismo", "destreza"], custo="movimento",
            sucesso=("Você passa por cima e abre um vão entre os barris para os outros.", [abrir([(18, 14), (18, 15)])]),
            falha=("Os barris rolam e você cai do outro lado, ralado.", [dano(3), abrir([(18, 14), (18, 15)])]))])
    descanso_em(f, "sacristia", "Banco da praça", 8, 5, "Um banco de pedra embaixo do sino da praça, longe dos mortos.")
    f.interacao("sino", "Corda do sino da capela", 30, 15, "A corda do sino foi cortada. Amarrando de volta, o sino toca de novo.", [
        opc("tocar", "Amarrar e tocar o sino (Atletismo + Força)", teste=["Atletismo", "forca"],
            sucesso=("O sino toca. Os mortos que ainda andam param, cobrem os ouvidos que não têm mais e ficam fracos.", [fichas_grupo("Foco"), narrar("O sino", "Os zumbis cambaleiam com o som do sino.")]),
            falha=("A corda escapa e o badalo bate uma vez só, torto.",))])
    f.salvar()


# =================================================================================================
# 3. Bandidos: o Bairro do Cão Vermelho
# =================================================================================================
def bandidos():
    f = Fase("bandidos_cao_vermelho", "O Bairro do Cão Vermelho", 38, 26, "pedra",
             "Invadam um bairro tomado por bandidos: becos, telhados com besteiros e o curtume onde o capitão se esconde. Dá para entrar lutando, pelos esgotos ou comprando um informante.")
    f.f["abertura"] = {"titulo": "O Cão Vermelho", "texto": "O bando do Cão Vermelho tomou o bairro dos curtumes: cobra pedágio, sequestra comerciantes e tem besteiros nos telhados. O conselho da cidade quer o capitão Ferrabrás, vivo ou morto. Os telhados são altos: quem está lá em cima vê tudo. Procurem outros caminhos."}
    f.f["objetivo"] = {"tipo": "derrotar_alvos", "texto": "Derrote o capitão Ferrabrás, no curtume.", "rodadas": 8,
                       "mensagem_vitoria": "Ferrabrás cai entre os tonéis do curtume. Os bandidos que sobram largam as armas. O bairro vai demorar a esquecer o cheiro de couro e medo, mas hoje à noite as janelas vão abrir."}
    f.f["campanha"].update({"texto": "Invasão (nível sugerido 2–3). O bando do Cão Vermelho domina o bairro dos curtumes. Besteiros nos telhados, reféns no depósito e um capitão que não foge de briga.",
                            "recompensa": 220, "requer": ["fase:investigacao_vau_cinzento"]})
    # blocos e telhados (nível 1 = telhado andável)
    for (x0, y0, x1, y1) in [(0, 0, 8, 3), (0, 22, 9, 25), (13, 22, 20, 25), (24, 0, 29, 3)]:
        f.bloco(x0, y0, x1, y1)
    # telhados acessíveis com escadas
    f.nivel(10, 4, 14, 8, 1); f.escada(10, 9); f.nivel(10, 9, 10, 9, 1)
    f.nivel(17, 13, 21, 17, 1); f.escada(16, 15); f.nivel(16, 15, 16, 15, 1)
    f.ret_chao(10, 4, 14, 8, "madeira"); f.ret_chao(17, 13, 21, 17, "madeira")
    f.nivel(10, 9, 10, 9, 1)
    # beco sem saída (entrada em 3,12): o muro do leste só abre com o informante
    for y in range(4, 12):
        f.obj(7, y, "parede")
    for x in range(1, 9):
        if x != 3:
            f.obj(x, 12, "parede")
    # portão do bairro (cercas de 12 a 20; o vão em 9,21 é a boca do esgoto)
    for y in range(12, 21):
        f.obj(9, y, "cerca")
    f.obj(9, 15, "porta")   # portão fechado
    # curtume (sala grande a leste)
    f.paredes(26, 8, 37, 20, aberturas=[(26, 14)])
    f.ret_chao(27, 9, 36, 19, "terra")
    for (x, y) in [(29, 10), (31, 10), (33, 10), (29, 18), (31, 18), (33, 18)]:
        f.obj(x, y, "barril")
    f.obj(36, 14, "mesa"); f.obj(35, 10, "bau")
    f.obj(26, 14, "porta")
    f.tirar_obj(28, 20)    # saída do esgoto dentro do curtume
    # depósito com reféns
    f.paredes(20, 3, 23, 8, aberturas=[])
    f.ret_chao(21, 4, 22, 7, "madeira")
    f.obj(21, 4, "npc"); f.obj(22, 4, "npc")
    f.obj(23, 6, "porta")
    # esgoto: corredor fechado em terreno difícil, da boca (9,21) até o curtume (28,20)
    f.ret_chao(9, 21, 28, 21, "dificil")
    f.chao(28, 20, "dificil")
    for x in range(10, 30):
        if x < 26:
            f.obj(x, 20, "parede")
        if not (13 <= x <= 20):
            f.obj(x, 22, "parede")
    f.obj(29, 21, "parede")
    f.inicio((1, 15), (1, 16), (2, 15), (2, 16))
    f.area("chegada", "Fim da rua", "fala", [(4, 14), (4, 15), (4, 16), (4, 17)], titulo="O portão do Cão Vermelho",
           texto="Um portão improvisado de cercas e uma porta velha. Lá de cima, nos telhados, alguém assobia: avisaram que vocês chegaram.")
    f.area("esgoto", "Esgoto", "teste", [(9, 21), (10, 21)], titulo="Pelo esgoto",
           texto="A grade do esgoto está solta. Lá dentro, água até o joelho e um cheiro de matar.", teste=["Furtividade", "destreza"], nivel="medio",
           sucesso=("Vocês avançam pelo esgoto sem ninguém perceber.", []),
           falha=("Um balde de couro boia e bate na parede. Ecoa até o curtume.", [alertar("curtume", "Gritos no curtume: \"Tem gente no esgoto!\"")]))
    # inimigos: rua, telhados, curtume
    f.inimigo("bandido_portao1", "bandido", 11, 14, grupo="rua", vigia=5)
    f.inimigo("bandido_portao2", "bandido", 12, 17, grupo="rua", vigia=5)
    f.inimigo("capanga_rua", "capanga", 14, 15, grupo="rua", vigia=4)
    f.inimigo("besteiro_telhado1", "bandido_besteiro", 12, 6, grupo="rua", vigia=8)
    f.inimigo("besteiro_telhado2", "bandido_besteiro", 19, 15, grupo="rua", vigia=8)
    f.grupo("rua", "O bando", "\"Pedágio, forasteiros! Ou deixam as bolsas, ou deixam o sangue!\"")
    f.inimigo("bandido_dep", "bandido", 21, 9, grupo="deposito", vigia=3)
    f.inimigo("bandido_dep2", "bandido", 24, 6, grupo="deposito", vigia=3)
    f.grupo("deposito", "Guardas do depósito", "Dois bandidos jogam dados na porta do depósito.")
    f.inimigo("ferrabras", "capitao_bandido", 34, 14, nome="Capitão Ferrabrás", grupo="curtume", vigia=6, alvo=True,
              saque=[ouro(60), item("pocao_de_cura_pequena", 2)])
    f.inimigo("capanga_cap1", "capanga", 32, 12, grupo="curtume", vigia=5)
    f.inimigo("capanga_cap2", "capanga", 32, 16, grupo="curtume", vigia=5)
    f.inimigo("besteiro_cap", "bandido_besteiro", 35, 18, grupo="curtume", vigia=6, saque=[item("flecha_explosiva", 2)])
    f.inimigo("bandido_cap", "bandido", 29, 14, grupo="curtume", vigia=5)
    f.grupo("curtume", "Ferrabrás", "No meio dos tonéis de tinta, um homem de casaco vermelho larga o copo e pega a cimitarra: \"Vieram até a minha casa? Que educados.\"")
    # caminhos alternativos
    f.npc("informante", "Garoto dos recados", 3, 18, "Um garoto magro, de olho no bolso de vocês.", [
        opc("pagar", "Pagar 10 pratas pelo caminho (Negociação + Diplomacia)", teste=["Negociação", "diplomacia"], nivel="facil",
            sucesso=("Ele pega as moedas e abre uma porta de serviço no muro do beco: \"Por aqui ninguém vigia.\"", [ouro(-10), abrir([(7, 8)]), lore("O informante conta que Ferrabrás guarda os reféns no depósito de couro.")]),
            falha=("Ele pega as moedas e some. Pelo menos contou dos reféns no depósito.", [ouro(-10), lore("Há reféns no depósito de couro.")]))])
    f.interacao("portao", "Portão do Cão Vermelho", 9, 15, "Uma porta velha presa entre cercas, trancada com corrente.", [
        opc("arrombar", "Arrombar (Atletismo + Força)", teste=["Atletismo", "forca"], nivel="medio",
            sucesso=("A corrente arrebenta.", [abrir([(9, 15)])]),
            falha=("A porta range e não abre. Lá de dentro, alguém ri.", [alertar("rua")]), uma_vez=False),
        opc("gazua", "Abrir o cadeado (Ladinagem + Destreza)", teste=["Ladinagem", "destreza"], nivel="facil",
            sucesso=("O cadeado cede sem barulho.", [abrir([(9, 15)])]),
            falha=("O cadeado emperra. Tente de novo.",), uma_vez=False)])
    f.interacao("porta_curtume", "Porta do curtume", 26, 14, "Uma porta grossa de couro curtido sobre madeira. Lá dentro, risadas e o cheiro de tinta.", [
        opc("arrombar", "Arrombar (Atletismo + Força)", teste=["Atletismo", "forca"],
            sucesso=("A porta voa para dentro.", [abrir([(26, 14)]), alertar("curtume")]),
            falha=("A porta treme. Lá dentro, alguém grita: \"Às armas!\"", [alertar("curtume")]), uma_vez=False),
        opc("gazua", "Abrir a tranca em silêncio (Ladinagem + Destreza)", teste=["Ladinagem", "destreza"], nivel="medio",
            sucesso=("A tranca cede sem barulho.", [abrir([(26, 14)])]),
            falha=("A tranca emperra.",), uma_vez=False)])
    f.interacao("refens", "Porta do depósito", 23, 6, "Gemidos atrás da porta: comerciantes amarrados.", [
        opc("libertar", "Soltar os reféns", custo="padrao", sem_inimigos=True,
            feito=("Quatro comerciantes saem tremendo. O mais velho aperta a mão de vocês: \"O curtume tem uma porta pelo esgoto. E o Ferrabrás tem medo de fogo.\" Eles juntam o que tinham para pagar.", [abrir([(23, 6)]), ouro(30), lore("Os reféns contam que o curtume tem entrada pelo esgoto.")]))])
    f.interacao("bau_curtume", "Baú do capitão", 35, 10, "O baú do bando, com cadeado de bronze.", [
        opc("abrir", "Abrir (Ladinagem + Destreza)", teste=["Ladinagem", "destreza"],
            sucesso=("Pratas, joias roubadas e uma carta do Círculo Rubro pedindo o bairro \"limpo até a lua nova\".", [ouro(45), item("mascara_do_impostor"), lore("O Círculo Rubro também pagava Ferrabrás.")]),
            falha=("A fechadura é boa demais.",), uma_vez=False)])
    f.interacao("tonel", "Tonéis de óleo de curtume", 29, 10, "Tonéis de óleo para amaciar couro. Inflamáveis.", [
        opc("derrubar", "Derrubar e incendiar (Atletismo + Força)", teste=["Atletismo", "forca"],
            sucesso=("O óleo escorre pelo chão do curtume e pega fogo. Os bandidos perto dos tonéis gritam.", [narrar("Fogo no curtume", "O fogo se espalha pelo óleo derramado.")]),
            falha=("O tonel não tomba.",), uma_vez=False)])
    descanso_em(f, "esconderijo", "Porão abandonado", 2, 20, "Um porão sem janelas, longe dos telhados.")
    f.salvar()


# =================================================================================================
# 4. O baile de máscaras
# =================================================================================================
def baile():
    f = Fase("baile_mascaras_prata", "O Baile das Máscaras de Prata", 32, 24, "pedra",
             "Missão social: infiltrados num baile de máscaras, converse com os convidados, use perícias sociais e descubra quem quer envenenar a Duquesa no brinde da meia-noite.")
    f.f["escuro"] = True
    f.f["luz_ambiente"] = 1
    f.f["abertura"] = {"titulo": "O Baile das Máscaras de Prata", "texto": "A Duquesa Lisandra dá o baile do equinócio. A guilda recebeu um bilhete sem assinatura: \"Ela não vai ver o amanhecer. O brinde é à meia-noite.\" Vocês entraram como convidados, de máscara. Ninguém pode saber quem vocês são até a hora certa. Conversem, observem e juntem três pistas antes de acusar alguém diante da Duquesa. Uma acusação errada ofende a casa."}
    f.f["objetivo"] = {"tipo": "derrotar_alvos", "texto": "Descubra o envenenador (3 pistas), desmascare-o no brinde e detenha-o.", "rodadas": 8,
                       "mensagem_vitoria": "O Barão Corvin cai sobre o próprio frasco de veneno, que se quebra no mármore. A Duquesa tira a máscara, olha para vocês e ergue a taça vazia: \"À guilda. Que tenha sempre gente melhor do que os meus convidados.\""}
    f.f["campanha"].update({"texto": "Social (nível sugerido 3). Um bilhete anônimo avisa que a Duquesa Lisandra vai morrer no brinde do baile de máscaras. Vão como convidados. Conversa vale mais que espada, até a meia-noite.",
                            "recompensa": 250, "requer": ["fase:bandidos_cao_vermelho"]})
    # salão (piso de pedra polida = padrão), jardins, adega, corredor de serviço e varanda
    f.paredes(0, 0, 31, 23)
    f.ret_chao(1, 17, 30, 22, "grama")      # jardim ao sul
    for x in range(1, 31):
        if x not in (14, 15, 16):
            f.obj(x, 16, "cerca")
    for (x, y) in [(3, 19), (8, 20), (22, 19), (27, 20)]:
        f.obj(x, y, "arvore")
    f.obj(15, 20, "fonte")
    # salão de baile
    for (x, y) in [(6, 4), (6, 11), (25, 4), (25, 11)]:
        f.obj(x, y, "pilar")
    for (x, y) in [(10, 3), (12, 3), (19, 3), (21, 3)]:
        f.obj(x, y, "mesa")
    f.obj(15, 2, "mesa")   # mesa do brinde
    for (x, y) in [(3, 2), (28, 2), (3, 13), (28, 13)]:
        f.obj(x, y, "velas", colisao=False)
        f.luz(x, y, 2, 5, "candelabro")
    f.luz(15, 8, 3, 6, "lustre")
    # corredor de serviço (escondido) a leste
    f.paredes(26, 5, 31, 10)
    f.ret_chao(27, 6, 30, 9, "madeira")
    f.obj(26, 8, "porta")
    # varanda a oeste (o barão foge para lá)
    f.paredes(0, 5, 4, 10)
    f.ret_chao(1, 6, 3, 9, "madeira")
    f.obj(4, 8, "porta")
    # adega (sala a nordeste do salão, porta aberta)
    f.paredes(19, 11, 24, 15, aberturas=[(21, 11)])
    f.ret_chao(20, 12, 23, 14, "terra")
    f.obj(20, 14, "barril"); f.obj(23, 12, "barril"); f.obj(22, 14, "estante")
    f.inicio((14, 21), (16, 21), (13, 20), (17, 20))
    f.area("entrada", "Escadaria do jardim", "fala", [(14, 17), (15, 17), (16, 17)], titulo="O salão",
           texto="Música de cordas, perfume e sussurros. Cinquenta máscaras de prata giram sob o lustre. Na mesa do brinde, uma taça de cristal azul separada das outras: a da Duquesa. Faltam duas horas para a meia-noite.")
    # --- convidados (social) ---
    f.npc("duquesa", "Duquesa Lisandra", 15, 4, "Máscara de cisne, voz cansada de quem cumprimenta gente há três horas.", [
        opc("cumprimentar", "Cumprimentar com toda a etiqueta (Nobreza + Diplomacia)", teste=["Nobreza", "diplomacia"], nivel="facil",
            sucesso=("Ela gosta de vocês. \"Venham ao brinde perto de mim. Brindo com a taça azul, a da minha mãe. Ninguém mais toca nela, só o mordomo.\"", [pista("A taça azul", "Só a Duquesa bebe da taça azul, servida pelo mordomo.")]),
            falha=("Vocês tropeçam no cumprimento. Ela sorri com educação e vira para outro convidado.",), uma_vez=False),
        opc("avisar", "Avisar do bilhete agora", custo="nenhum",
            feito=("\"Recebo bilhetes assim toda semana.\" Ela não muda nada. Vão precisar de provas.", [lore("A Duquesa não leva avisos a sério sem provas.")]))])
    f.npc("mordomo", "Mordomo Alaric", 15, 3, "Luvas brancas, guarda a mesa do brinde como um cão de guarda.", [
        opc("ler", "Perceber se ele é sincero (Intuição + Percepção)", teste=["Intuição", "percepcao"],
            sucesso=("Ele é leal até o osso. Baixinho: \"O Barão Corvin insistiu em servir o vinho do brinde ele mesmo. Disse que é costume da terra dele. Não gostei.\"", [pista("O Barão quer servir o vinho", "O Barão Corvin pediu para servir o vinho do brinde.")]),
            falha=("\"Tudo está em ordem, senhor.\" Ele não diz mais nada.",), uma_vez=False)])
    f.npc("barao", "Convidado de máscara de corvo", 9, 8, "Máscara de corvo, luvas pretas, um perfume forte demais. Ele não dança.", [
        opc("atuar", "Fingir ser um admirador da corte dele (Atuação + Mentira)", teste=["Atuação", "mentira"],
            sucesso=("O Barão Corvin se abre: reclama que a Duquesa tomou as terras dele no tribunal, \"mas a justiça vem, às vezes num copo\". O colete dele tem um volume de frasco.", [pista("O frasco no colete", "O Barão Corvin carrega um frasco escondido e odeia a Duquesa.")]),
            falha=("Ele estreita os olhos atrás da máscara. \"Já nos vimos antes?\" e se afasta.",)),
        opc("irritar", "Provocar para ele perder a calma (Irritar + Raciocínio)", teste=["Irritar", "raciocinio"], nivel="dificil",
            sucesso=("Ele explode: \"Aquela mulher vai pagar!\" e logo se recompõe. Metade do salão ouviu.", [pista("Ameaça em público", "O Barão ameaçou a Duquesa em público.")]),
            falha=("Ele ri de você e oferece um copo. Você não aceita.",))])
    f.npc("poeta", "Poeta bêbado", 22, 7, "Um poeta de máscara torta declama para uma coluna.", [
        opc("versos", "Responder em versos (Arte + Raciocínio)", teste=["Arte", "raciocinio"], nivel="facil",
            sucesso=("Ele aplaude e fala alto demais: \"O corvo perdeu o ninho no tribunal! Corvin, o falido! Vendeu até a prata da mãe!\"", [pista("O Barão falido", "O Barão Corvin perdeu tudo para a Duquesa e está falido."), lore("O poeta chama o Barão de \"corvo sem ninho\".")]),
            falha=("Ele chora no seu ombro e esquece o que ia dizer.",))])
    f.npc("dama", "Dama de vermelho", 8, 3, "Uma mulher de máscara vermelha joga cartas sozinha, e ganha.", [
        opc("cartas", "Jogar cartas com ela (Jogatina + Raciocínio)", teste=["Jogatina", "raciocinio"],
            sucesso=("Você perde de propósito na hora certa. Ela, satisfeita: \"Espiã? Não, querido, só observadora. O Barão trouxe dois 'criados' que ninguém contratou. Estão no corredor de serviço.\"", [pista("Criados que ninguém contratou", "O Barão escondeu dois homens armados no corredor de serviço."), ouro(10)]),
            falha=("Ela leva 10 pratas suas com um sorriso.", [ouro(-10)]), uma_vez=False)])
    f.npc("capitao_guarda", "Capitão da guarda da casa", 24, 13, "Armadura de gala e cara de quem preferia estar dormindo.", [
        opc("liderar", "Convencer a ficar atento (Liderança + Diplomacia)", teste=["Liderança", "diplomacia"],
            sucesso=("Ele concorda em ficar perto da Duquesa na meia-noite e deixa vocês descerem à adega \"para ver o vinho\".", [lore("A guarda da casa vai ajudar na hora do brinde.")]),
            falha=("\"Convidados não dão ordens à guarda.\"",))])
    f.npc("musicos", "Quarteto de cordas", 15, 14, "Quatro músicos tocam sem parar desde o pôr do sol.", [
        opc("tocar", "Pedir uma valsa para o grupo (Arte + Diplomacia)", teste=["Arte", "diplomacia"], nivel="facil",
            sucesso=("Eles tocam a valsa do equinócio. Vocês dançam, ouvem conversas e ficam mais atentos.", [fichas_grupo("Foco")]),
            falha=("Eles tocam outra coisa, mas tocam bem.",))])
    f.interacao("adega", "Estante da adega", 22, 14, "Garrafas empoeiradas e uma vazia, nova, sem pó.", [
        opc("examinar", "Examinar a garrafa nova (Investigação + Percepção)", teste=["Investigação", "percepcao"], nivel="facil",
            sucesso=("Dentro, gotas de um líquido negro que cheira a amêndoa amarga. No vidro, o brasão de um corvo.", [pista("Garrafa com o corvo", "Uma garrafa de veneno com o brasão do corvo na adega.")]),
            falha=("Só garrafas velhas e teias.",), uma_vez=False)])
    # a acusação na meia-noite
    f.interacao("brinde", "Mesa do brinde", 15, 2, "A taça azul brilha. Os sinos da meia-noite vão tocar logo.", [
        opc("acusar_barao", "Interromper o brinde e desmascarar o Barão Corvin (precisa de 3 pistas)", custo="padrao", pistas=3,
            feito=("Vocês contam tudo diante do salão. A Duquesa derruba a taça azul: o vinho chia no mármore. O Barão arranca a máscara de corvo, salta a janela para a varanda e grita: \"Agora!\" A porta de serviço explode e os 'criados' entram de lâmina na mão.",
                   [abrir([(9, 8), (4, 8), (26, 8)]), alertar("conspiracao", "Os assassinos atacam!")])),
        opc("acusar_mordomo", "Acusar o mordomo", custo="padrao",
            feito=("O salão fica em silêncio. A Duquesa, gelada: \"Alaric me serve há trinta anos.\" Ninguém mais conversa com vocês com boa vontade. Melhor encontrar provas de verdade.", [ficha("Penalidade")])),
        opc("acusar_dama", "Acusar a dama de vermelho", custo="padrao",
            feito=("A dama ri tanto que a máscara cai. A Duquesa não acha graça nenhuma.", [ficha("Penalidade")]))])
    f.inimigo("corvin", "duelista", 2, 7, nome="Barão Corvin", grupo="conspiracao", vigia=12, alvo=True,
              saque=[ouro(50), item("mascara_do_impostor"), lore("No colete do Barão: o frasco e uma carta do Círculo Rubro prometendo devolver as terras dele.")])
    f.inimigo("assassino1", "assassino", 28, 7, grupo="conspiracao", vigia=12)
    f.inimigo("assassino2", "assassino", 29, 9, grupo="conspiracao", vigia=12)
    f.inimigo("assassino3", "assassino", 1, 9, grupo="conspiracao", vigia=12)
    f.grupo("conspiracao", "A conspiração", "Os convidados gritam e fogem para o jardim. A música para no meio da nota.")
    # convidados de enfeite
    for (x, y) in [(11, 6), (18, 6), (12, 10), (20, 10), (17, 12), (10, 13)]:
        f.obj(x, y, "npc")
    f.interacao("convidados", "Roda de convidados", 18, 6, "Fofocas sobre todo mundo.", [
        opc("fofoca", "Ouvir as fofocas (Política + Raciocínio)", teste=["Política", "raciocinio"], nivel="facil",
            sucesso=("\"O Barão Corvin perdeu o processo das terras para a Duquesa no inverno.\" \"E veio ao baile mesmo assim? Que coragem... ou que outra coisa.\"", [lore("O Barão Corvin perdeu as terras para a Duquesa num processo.")]),
            falha=("Falam de vestidos a noite inteira.",))])
    descanso_em(f, "jardim", "Banco do jardim", 15, 19, "Um banco perto da fonte, longe da música.")
    f.salvar()


# =================================================================================================
# 5. O deserto: as Areias de Kesh-Tar (mapa grande; o grupo não sabe o tamanho)
# =================================================================================================
def deserto():
    L, A = 60, 48
    f = Fase("deserto_kesh_tar", "As Areias de Kesh-Tar", L, A, "pedra",
             "Mapa aberto e grande no deserto, sem bordas à vista: encontre a caravana perdida e o Selo de Kesh. Escorpiões, saqueadores, múmias e um verme enorme.")
    random.seed(28)
    # tudo areia; borda irregular de vazio (o mapa não tem forma de retângulo)
    for x in range(L):
        for y in range(A):
            borda = min(x, y, L - 1 - x, A - 1 - y)
            if borda < 3 and random.random() < (0.9 if borda == 0 else 0.55 if borda == 1 else 0.25):
                f.chao(x, y, "vazio")
            else:
                f.chao(x, y, "areia")
    # dunas (terreno difícil) em faixas
    for (cx, cy, r) in [(15, 30, 4), (32, 20, 5), (45, 35, 4), (24, 10, 3), (50, 14, 3)]:
        for x in range(cx - r, cx + r + 1):
            for y in range(cy - 1, cy + 2):
                if 0 <= x < L and 0 <= y < A and f.f["chao"].get(c(x, y)) == "areia":
                    f.chao(x, y, "dificil")
    # rochas espalhadas
    for _ in range(40):
        x, y = random.randrange(4, L - 4), random.randrange(4, A - 4)
        if f.f["chao"].get(c(x, y)) == "areia":
            f.obj(x, y, random.choice(["rocha", "pedra", "pedra"]))
    # oásis (sudoeste)
    f.ret_chao(8, 34, 12, 37, "agua")
    f.ret_chao(6, 32, 14, 33, "grama"); f.ret_chao(6, 38, 14, 39, "grama")
    for (x, y) in [(7, 33), (13, 33), (7, 38), (13, 38), (6, 35)]:
        f.obj(x, y, "arvore")
    # ruínas do templo (centro-norte), com múmias
    f.paredes(26, 4, 36, 12, aberturas=[(31, 12), (31, 4)], tipo="parede")
    f.ret_chao(27, 5, 35, 11, "pedra")
    for (x, y) in [(28, 6), (34, 6), (28, 10), (34, 10)]:
        f.obj(x, y, "pilar")
    f.obj(31, 6, "sarcofago")
    # caravana perdida (nordeste)
    f.ret_chao(46, 6, 54, 12, "terra")
    for (x, y, t) in [(47, 7, "tenda"), (52, 7, "caixa"), (53, 8, "barril"), (49, 11, "saco"), (51, 11, "caixa"), (48, 9, "fogueira_apagada"), (54, 11, "escombro")]:
        f.obj(x, y, t)
    f.obj(50, 9, "bau")
    # acampamento dos saqueadores (sudeste)
    f.ret_chao(40, 36, 47, 41, "terra")
    for (x, y, t) in [(41, 37, "tenda"), (46, 37, "tenda"), (43, 39, "fogueira"), (45, 40, "caixa")]:
        f.obj(x, y, t)
    f.inicio((20, 44), (21, 44), (20, 43), (21, 43))
    # chão de onde se começa precisa existir
    for p in [(20, 44), (21, 44), (20, 43), (21, 43), (20, 45), (21, 45)]:
        f.chao(p[0], p[1], "areia")
    f.f["abertura"] = {"titulo": "Kesh-Tar", "texto": "A caravana do mercador Idris sumiu no deserto de Kesh-Tar levando o Selo de Kesh, uma relíquia que a guilda prometeu entregar. Ninguém sabe quanto o deserto se estende daqui: só que de dia ele queima e de noite ele come gente. Sigam os rastros, achem água e não fiquem parados onde a areia gira."}
    f.f["objetivo"] = {"tipo": "interagir", "texto": "Encontre a caravana perdida e recupere o Selo de Kesh.", "rodadas": 8,
                       "mensagem_vitoria": "O Selo de Kesh pesa mais do que parece. Atrás de vocês, a areia se fecha sobre a caravana de Idris. Agora é só voltar... seguindo as próprias pegadas, antes que o vento as apague."}
    f.f["campanha"].update({"texto": "Exploração (nível sugerido 3–4). A caravana do mercador Idris sumiu nas Areias de Kesh-Tar com o Selo de Kesh. Deserto aberto e sem fim à vista. Levem água e paciência.",
                            "recompensa": 280, "requer": ["pantano"]})
    f.area("rastros1", "Rastros", "fala", [(22, 40), (23, 40), (24, 40), (22, 39)], titulo="Rastros de carroça",
           texto="Marcas de roda meio apagadas seguem para o norte e depois viram para o leste. Ao lado, pegadas que não são de gente: muitas patas, pequenas, em fila.")
    f.area("rastros2", "Rastros do verme", "fala", [(38, 18), (39, 18), (40, 18), (38, 19), (39, 19), (40, 19)], titulo="A areia afundada",
           texto="Um sulco largo como uma estrada atravessa as dunas, afundado e liso. Algo enorme passou por baixo da areia. Os rastros da caravana vão na mesma direção.")
    f.area("calor1", "Sol a pino", "teste", [(x, 28) for x in range(18, 30)], titulo="Sol a pino",
           texto="O calor sobe da areia em ondas.", teste=["Sobrevivência", "constituicao"], nivel="medio",
           sucesso=("Vocês cobrem a cabeça e economizam água. Seguem.", []),
           falha=("A visão escurece por um instante. O corpo cobra o preço do sol.", [dano(3)]))
    f.area("miragem", "Miragem", "fala", [(30, 34), (31, 34), (32, 34)], titulo="Miragem",
           texto="Um lago azul brilha ao leste. Quando vocês piscam, é só areia de novo.")
    f.area("areia_movedica", "Areia movediça", "armadilha", [(35, 26), (36, 26), (35, 27), (36, 27)],
           texto="A areia aqui é lisa e escura demais.",
           armadilha={"dano": 4, "ficha": "Imobilizar", "achar": "medio", "evitar": "medio", "desarmar": "dificil", "texto_disparo": "A areia engole suas pernas até a cintura!"})
    descanso_em(f, "oasis", "Água do oásis", 10, 33, "Água fresca e sombra de palmeira.")
    f.interacao("oasis_beber", "Encher os cantis", 12, 37, "Água limpa e funda.", [
        opc("encher", "Encher os cantis e comer tâmaras", custo="padrao",
            feito=("Os cantis pesam de novo. Vocês comem tâmaras das palmeiras.", [item("racao_de_viagem", 2), item("frutas_silvestres", 2)]))])
    # inimigos
    f.inimigo("escorp1", "escorpiao_gigante", 16, 24, grupo="escorpioes", vigia=5)
    f.inimigo("escorp2", "escorpiao_gigante", 19, 21, grupo="escorpioes", vigia=5)
    f.grupo("escorpioes", "Escorpiões", "A areia se mexe e duas carapaças do tamanho de um homem surgem, com o ferrão erguido.")
    f.inimigo("saq1", "bandido", 42, 38, nome="Saqueador do Deserto", grupo="saqueadores", vigia=6)
    f.inimigo("saq2", "bandido", 44, 36, nome="Saqueador do Deserto", grupo="saqueadores", vigia=6)
    f.inimigo("saq3", "bandido_besteiro", 46, 39, nome="Arqueiro do Deserto", grupo="saqueadores", vigia=7)
    f.inimigo("saq_chefe", "capanga", 43, 40, nome="Chefe dos Saqueadores", grupo="saqueadores", vigia=6,
              saque=[ouro(30), lore("Um mapa rabiscado: a caravana foi engolida \"pela boca da areia\", a nordeste, perto das ruínas.")])
    f.grupo("saqueadores", "Saqueadores", "Homens de turbante e lenço no rosto se levantam do acampamento. \"Mais sedentos para a coleção!\"")
    f.inimigo("mumia1", "mumia", 29, 8, grupo="templo", vigia=4, dormindo=True)
    f.inimigo("mumia2", "mumia", 33, 8, grupo="templo", vigia=4, dormindo=True)
    f.grupo("templo", "As múmias", "Ataduras rangem. Os guardiões do templo se levantam dos nichos.")
    f.interacao("sarcofago", "Sarcófago do sacerdote", 31, 6, "Hieróglifos de um sacerdote do sol. A tampa está entreaberta.", [
        opc("ler", "Ler os hieróglifos (História + Raciocínio)", teste=["História", "raciocinio"],
            sucesso=("\"Aquele que dorme na areia odeia o frio e o trovão.\" Um aviso sobre o verme. Dentro do sarcófago, um amuleto de sol.", [lore("O verme da areia é fraco contra Gelo e Trovão."), item("runa_de_agua"), ouro(25)]),
            falha=("Só desenhos de sóis e cobras.",)),
        opc("saquear", "Abrir e saquear", custo="padrao",
            feito=("Ouro antigo e um sopro de poeira amaldiçoada.", [ouro(40), ficha("Medo"), alertar("templo")]))])
    f.inimigo("verme", "verme_da_areia", 50, 15, grupo="verme", vigia=7,
              saque=[ouro(60), lore("No estômago do verme, uma bolsa do mercador Idris, ainda fechada.")])
    f.grupo("verme", "O Verme da Areia", "O chão explode. Uma boca redonda, cheia de dentes em espiral, sobe da areia até tapar o sol.")
    f.interacao("bau_caravana", "Cofre da caravana de Idris", 50, 9, "O cofre de ferro do mercador, meio enterrado.", [
        opc("selo", "Desenterrar o cofre e pegar o Selo de Kesh", custo="turno", sem_inimigos=True,
            feito=("Dentro do cofre, embrulhado em seda, o Selo de Kesh. E o diário de Idris: \"O verme veio ao meio-dia. Fujam do que gira.\"", [ouro(50), vitoria("O Selo de Kesh está com vocês.")]))])
    f.interacao("diario_idris", "Corpo de um guarda da caravana", 47, 11, "Um guarda caído, coberto de areia até o peito.", [
        opc("revistar", "Revistar", custo="movimento",
            feito=("No cinto: uma poção e um bilhete: \"O cofre está embaixo da carroça grande. Não façam barulho perto da areia lisa.\"", [item("pocao_de_cura_pequena")]))])
    f.salvar()


# =================================================================================================
# 6. A torre do mago: andares em níveis, invocações e Vaelor no topo
# =================================================================================================
def torre():
    f = Fase("torre_vaelor", "A Torre de Vaelor", 40, 30, "pedra",
             "Subam os quatro andares da torre do mago: armaduras animadas, gárgulas, armadilhas mágicas, um laboratório de invocações e, no observatório, o próprio Vaelor.")
    f.f["escuro"] = True
    f.f["luz_ambiente"] = 1
    f.f["abertura"] = {"titulo": "A Torre de Vaelor", "texto": "O livro que acordou os mortos de Hesk veio desta torre. Vaelor, o mago que mora no topo, vende segredos proibidos a quem paga, e agora não responde mais às cartas da cidade. Cada andar é mais alto que o outro; a escada sobe em espiral. Tudo aqui foi feito para impedir visitas."}
    f.f["objetivo"] = {"tipo": "derrotar_alvos", "texto": "Suba até o observatório e derrote Vaelor.", "rodadas": 8,
                       "mensagem_vitoria": "Vaelor cai entre os instrumentos do observatório. As invocações se apagam como velas. Lá embaixo, as portas da torre se abrem sozinhas: a casa não tem mais dono."}
    f.f["campanha"].update({"texto": "Masmorra (nível sugerido 4–5). A torre de Vaelor, o mago que vende segredos proibidos. Quatro andares de guardiões e armadilhas, e um mago que chama criaturas do fogo. Levem quem saiba de magia.",
                            "recompensa": 350, "requer": ["fase:deserto_kesh_tar"]})
    # o mapa fora da torre não existe
    for x in range(40):
        for y in range(30):
            f.chao(x, y, "vazio")

    def sala(x0, y0, x1, y1, nivel, piso="pedra"):
        for x in range(x0, x1 + 1):
            for y in range(y0, y1 + 1):
                f.chao(x, y, piso)
                if nivel:
                    f.f["niveis"][c(x, y)] = nivel
        f.paredes(x0, y0, x1, y1)

    def escada(cels, nivel):
        """Casas de escada (sobem um nível)."""
        for (x, y) in cels:
            f.tirar_obj(x, y)
            f.chao(x, y, "madeira")
            if nivel:
                f.f["niveis"][c(x, y)] = nivel
            else:
                f.f["niveis"].pop(c(x, y), None)
            f.escada(x, y)

    # Andar 0 (térreo): salão de entrada, sudoeste
    sala(1, 16, 14, 28, 0)
    # Andar 1: biblioteca, noroeste
    sala(1, 1, 14, 14, 1)
    # Andar 2: laboratório, nordeste
    sala(17, 1, 31, 14, 2)
    # Andar 3: observatório, sudeste
    sala(17, 16, 38, 28, 3)
    # escadas: térreo → biblioteca (x 6-7, y 14-16)
    escada([(6, 15), (7, 15)], 1)
    for p in [(6, 16), (7, 16)]:
        f.tirar_obj(*p)
    for p in [(6, 14), (7, 14)]:
        f.tirar_obj(*p)
    # biblioteca → laboratório (x 14-17, y 7)
    escada([(15, 7), (16, 7)], 2)
    for p in [(14, 7), (17, 7)]:
        f.tirar_obj(*p)
    f.chao(15, 7, "madeira"); f.chao(16, 7, "madeira")
    f.f["niveis"][c(15, 7)] = 1
    # laboratório → observatório (x 24, y 14-16)
    escada([(24, 15)], 3)
    for p in [(24, 14), (24, 16)]:
        f.tirar_obj(*p)
    f.escada(24, 14)
    # a porta selada do térreo para a escada
    f.obj(6, 16, "porta"); f.obj(7, 16, "porta")
    # porta de entrada do térreo
    f.inicio((7, 26), (8, 26), (7, 27), (8, 27))
    # térreo: armaduras animadas, armadilha de runa
    for (x, y) in [(3, 18), (12, 18), (3, 25), (12, 25)]:
        f.obj(x, y, "pilar")
    for (x, y) in [(4, 17), (11, 17)]:
        f.obj(x, y, "tocha_parede")
        f.luz(x, y + 1, 2, 4, "tocha")
    f.luz(8, 26, 2, 4, "porta aberta")
    f.inimigo("armadura1", "armadura_animada", 5, 19, grupo="terreo", vigia=4, dormindo=True)
    f.inimigo("armadura2", "armadura_animada", 10, 19, grupo="terreo", vigia=4, dormindo=True)
    f.grupo("terreo", "As armaduras", "Duas armaduras vazias nas paredes viram a cabeça ao mesmo tempo. O visor brilha azul.")
    f.area("runa_terreo", "Runa no piso", "armadilha", [(7, 21), (8, 21), (7, 22), (8, 22)],
           texto="Uma runa riscada no piso, quase invisível sob a poeira.",
           armadilha={"dano": 6, "ficha": "Fogo", "achar": "medio", "evitar": "medio", "desarmar": "medio", "texto_disparo": "A runa explode em chamas debaixo dos seus pés!"})
    f.interacao("selo_porta", "Porta selada", 7, 16, "Duas portas de ferro com um selo de luz azul. Do outro lado, a escada em espiral.", [
        opc("dissipar", "Desfazer o selo (Arcanismo + Raciocínio)", teste=["Arcanismo", "raciocinio"], nivel="medio",
            sucesso=("O selo se desmancha em faíscas. A escada sobe no escuro.", [abrir([(6, 16), (7, 16)])]),
            falha=("O selo dá um choque na sua mão.", [dano(3)]), uma_vez=False),
        opc("forcar", "Forçar as portas (Atletismo + Força)", teste=["Atletismo", "forca"], nivel="dificil",
            sucesso=("As portas cedem com um estalo, e o selo explode.", [abrir([(6, 16), (7, 16)]), dano(4)]),
            falha=("O selo joga você longe.", [dano(5)]), uma_vez=False)])
    descanso_em(f, "banco_terreo", "Banco da entrada", 10, 27, "Um banco de pedra junto da porta. Daqui ainda dá para ver o céu.")
    # andar 1: biblioteca, gárgulas, piso falso
    for (x, y) in [(3, 3), (5, 3), (9, 3), (11, 3), (3, 11), (11, 11)]:
        f.obj(x, y, "estante")
    f.obj(7, 8, "mesa")
    f.obj(2, 7, "velas", colisao=False); f.luz(2, 7, 2, 4, "velas")
    f.obj(13, 2, "velas", colisao=False); f.luz(13, 2, 2, 4, "velas")
    f.inimigo("gargula1", "gargula", 4, 6, grupo="biblioteca", vigia=4, dormindo=True)
    f.inimigo("gargula2", "gargula", 11, 7, grupo="biblioteca", vigia=4, dormindo=True)
    f.grupo("biblioteca", "As gárgulas", "As estátuas dos cantos abrem as asas. Pedra rangendo contra pedra.")
    f.area("piso_falso", "Piso falso", "teste", [(9, 9), (10, 9), (9, 10), (10, 10)], titulo="Piso falso",
           texto="O piso afunda!", teste=["Acrobacia", "destreza"], nivel="medio",
           sucesso=("Você se joga para o lado a tempo.", []),
           falha=("Você cai até o meio da perna num buraco de lâminas.", [dano(5), ficha("Sangramento")]))
    f.interacao("livros", "Mesa de estudos", 7, 8, "Anotações de Vaelor sobre invocação.", [
        opc("ler", "Ler as anotações (Ocultismo + Raciocínio)", teste=["Ocultismo", "raciocinio"],
            sucesso=("\"A invocação depende de mim. Se eu cair, tudo o que chamei volta para o nada.\" E na margem: \"o fogo odeia o gelo\".", [lore("Se Vaelor cair, as invocações somem. Os elementais do fogo são fracos contra Gelo."), item("pergaminho_do_desencantamento")]),
            falha=("Letras que mudam de lugar quando você olha.", [ficha("Confusão")])),
        opc("estante", "Procurar livros de valor (Investigação + Percepção)", teste=["Investigação", "percepcao"], nivel="facil",
            sucesso=("Dois tomos raros e uma poção esquecida atrás deles.", [ouro(30), item("pocao_de_mana_pequena")]),
            falha=("Poeira e mais poeira.",))])
    # andar 2: laboratório, invocações, círculo
    for (x, y) in [(19, 3), (29, 3), (19, 12), (29, 12)]:
        f.obj(x, y, "mesa")
    f.obj(24, 7, "altar")
    f.obj(20, 6, "fogueira"); f.obj(28, 9, "fogueira")
    f.luz(20, 6, 2, 4, "braseiro"); f.luz(28, 9, 2, 4, "braseiro"); f.luz(24, 7, 1, 3, "círculo")
    f.inimigo("elem_fogo", "elemental_fogo", 22, 5, grupo="laboratorio", vigia=5)
    f.inimigo("elem_terra", "elemental_terra", 26, 9, grupo="laboratorio", vigia=5)
    f.inimigo("diabrete1", "diabrete", 21, 11, grupo="laboratorio", vigia=6)
    f.inimigo("diabrete2", "diabrete", 28, 4, grupo="laboratorio", vigia=6)
    f.grupo("laboratorio", "O laboratório", "Um círculo de giz no chão brilha vermelho. Coisas saem dele, uma de cada vez.")
    f.interacao("circulo", "Círculo de invocação", 24, 7, "Um círculo de giz e sal em volta do altar, ainda quente.", [
        opc("quebrar", "Quebrar o círculo (Arcanismo + Espírito)", teste=["Arcanismo", "espirito"], nivel="medio",
            sucesso=("Você apaga uma linha do giz. Tudo o que saiu do círculo se desfaz no ar.", [retirar("laboratorio", "As criaturas do laboratório se desfazem em fumaça.")]),
            falha=("O círculo cospe fogo na sua cara.", [dano(4), ficha("Fogo")]), uma_vez=False)])
    descanso_em(f, "despensa", "Despensa do laboratório", 30, 13, "Uma despensa com água e pão velho, longe dos frascos.")
    f.area("antes_topo", "Escada do observatório", "fala", [(23, 13), (24, 13), (25, 13)], titulo="A última escada",
           texto="De cima vem uma voz calma: \"Subam. Faz tempo que ninguém sobe. Eu já ia descer para buscar vocês.\"")
    # andar 3: observatório e Vaelor
    for (x, y) in [(20, 19), (35, 19), (20, 25), (35, 25)]:
        f.obj(x, y, "pilar")
    f.obj(28, 22, "mesa")
    for (x, y) in [(19, 17), (36, 27)]:
        f.obj(x, y, "velas", colisao=False)
        f.luz(x, y, 2, 4, "velas")
    f.luz(28, 21, 3, 6, "globo celeste")
    f.inimigo("vaelor", "mago_vaelor", 33, 22, grupo="topo", vigia=10, alvo=True,
              saque=[ouro(80), item("anel_do_iniciado"), item("pocao_de_amplificacao"),
                     lore("O grimório de Vaelor tem uma lista de compradores. Um nome aparece muitas vezes: o Círculo Rubro.")])
    f.inimigo("armadura_topo", "armadura_animada", 30, 20, grupo="topo", vigia=8)
    f.grupo("topo", "Vaelor", "Um homem alto, de manto cheio de estrelas bordadas, fecha o livro. \"Visitas. Que pena: estava tão quieto.\"")
    f.salvar()


if __name__ == "__main__":
    investigacao()
    zumbis()
    bandidos()
    baile()
    deserto()
    torre()
