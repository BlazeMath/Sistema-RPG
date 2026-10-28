## 0.20: fim de turno com escolhas, fichas (1 por carta, escolher a carta, Mira), Foco entre
## a carta aberta e a fechada, Larápio, Folha de Carvalho, Devorador, atravessar aliados.
extends RefCounted

const Batalha := preload("res://core/batalha.gd")
const TC := preload("res://tests/test_classes.gd")
const Personagem := preload("res://core/personagem.gd")
const Encontros := preload("res://core/encontros.gd")


func test_bencao_persistente_no_fim_do_turno(t) -> void:
	var b := TC.new()._grupo_com("Clérigo", "classe.clerigo.toque-restaurador", "")
	var u := b.unidade("heroi")
	var c = u.cartas[u.cartas.size() - 1]
	c.lado = 1   # Bênção Persistente
	t.igual(c.slug(), "bencao-persistente", "verso do Toque Restaurador")
	var op := b.opcoes_fim_de_turno(u)
	t.ok(op["opcionais"].any(func(o): return o["id"] == "bencao-persistente"), "oferecida no fim do turno")
	u.baralho.sofrer_dano(3)
	u.vida_armadura = 0   # (armadura média pesa no fim do turno e exilaria mais uma)
	var exilio := u.baralho.exilio.size()
	b.encerrar_turno({"opcionais": ["bencao-persistente"]})
	t.igual(c.fadiga, 1, "1 de fadiga na carta")
	t.igual(u.baralho.exilio.size(), exilio + 1, "exila 1 do descarte")


func test_fim_de_turno_escolhe_a_carta(t) -> void:
	var b := TC.new()._grupo_com("Guerreiro", "classe.guerreiro.ombro-de-ferro", "classe.guerreiro.heroi.foco-mortal")
	var u := b.unidade("heroi")
	u.cartas[0].fadiga = 2
	u.cartas[1].fadiga = 1
	t.ok(b.fim_de_turno_tem_escolha(u), "duas cartas com fadiga: abre a tela")
	b.encerrar_turno({"fadiga": [1]})
	t.igual(u.cartas[1].fadiga, 0, "saiu da carta escolhida")
	t.igual(u.cartas[0].fadiga, 2, "a outra ficou")


func test_uma_ficha_de_cada_tipo_por_carta(t) -> void:
	var b := TC.new()._grupo_com("Guerreiro", "classe.guerreiro.ombro-de-ferro", "classe.guerreiro.heroi.foco-mortal")
	var u := b.unidade("heroi")
	u.dar_ficha("Preparo", 5)
	t.igual(u.fichas_total("Preparo"), u.cartas.size(), "uma por carta; o resto se perde")
	for c in u.cartas:
		t.igual(int(c.fichas.get("Preparo", 0)), 1, "no máximo 1 em %s" % c.nome())
	t.ok(not u.fichas_a_escolher.is_empty(), "a tela pergunta onde fica")


func test_mover_ficha_e_preparo_da_carta(t) -> void:
	var b := TC.new()._grupo_com("Guerreiro", "classe.guerreiro.ombro-de-ferro", "classe.guerreiro.heroi.foco-mortal")
	var u := b.unidade("heroi")
	u.dar_ficha("Preparo")
	var de := 0 if u.cartas[0].tem_ficha("Preparo") else 1
	var para := 1 - de
	t.ok(b.mover_ficha(u, "Preparo", de, para), "move a ficha para outra carta")
	t.ok(u.cartas[para].tem_ficha("Preparo") and not u.cartas[de].tem_ficha("Preparo"), "trocou de carta")
	if u.cartas[de].lados.size() > 1:
		t.ok(not b.heroi_virar(de, "preparo"), "o Preparo não vira outra carta")


func test_mira_e_ficha_propria(t) -> void:
	var b := TC.new()._grupo_com("Caçador", "", "classe.cacador.heroi.folha-de-carvalho")
	var u := b.unidade("heroi")
	var g := b.unidade("goblin1")
	u.cartas[0].fichas["Mira"] = 1
	g.pos = u.pos + Vector2i(3, 0)
	b.teste_ataque = null
	b._novo_ataque(u, g, {})
	while b.teste_ataque.encerrado:   # (estourou de cara: tenta de novo)
		b._novo_ataque(u, g, {})
	var antes := b.teste_defesa.limite
	var ops := b.cartas_durante_ataque()
	t.ok(ops.any(func(o): return o["slug"] == "mira"), "descartar Mira é da ficha (sem carta)")
	t.ok(b.heroi_durante_ataque("mira"), "descarta")
	t.igual(b.teste_defesa.limite, antes - 1, "−1 no limite do defensor")


func test_foco_entre_aberta_e_fechada(t) -> void:
	var b := TC.new()._grupo_com("Guerreiro", "", "classe.guerreiro.heroi.foco-mortal")
	b.perguntar_escolhas = true
	var u := b.unidade("heroi")
	var g := b.unidade("goblin1")
	u.carta_heroi().fichas["Foco"] = 1
	b._novo_ataque(u, g, {})
	t.igual(b.teste_ataque.cartas.size(), 1, "só a carta aberta")
	t.ok(b.foco_no_teste_disponivel(), "pode gastar o Foco agora")
	var topo: int = u.baralho.baralho[-1]
	t.ok(b.heroi_foco_no_teste(), "gasta o Foco (scry 1)")
	t.igual(b.fase, Batalha.Fase.PERGUNTA, "pergunta topo ou fundo")
	b.heroi_responder("fundo")
	t.ok(u.baralho.baralho[0] == topo, "a carta foi para o fundo")
	t.ok(b.heroi_receber_fechada(), "recebe a fechada")
	t.igual(b.teste_ataque.cartas.size() if not b.teste_ataque.estourou else 2, 2, "agora são 2 cartas")


func test_folha_de_carvalho_dois_botoes(t) -> void:
	var b := TC.new()._grupo_com("Caçador", "", "classe.cacador.heroi.folha-de-carvalho")
	var u := b.unidade("heroi")
	var ops := b.opcoes_cartas(u)
	var heroi_op: Dictionary = ops.filter(func(o): return o["carta"].tipo == "heroi")[0]
	t.igual(heroi_op.get("opcoes", []).size(), 2, "uma opção para cada ativada")
	t.ok(b.heroi_usar_carta(heroi_op["indice"], null, "ferimento"), "usa a do Ferimento")
	t.ok(u.efeitos.has("folha_ferimento"), "preparada")


func test_devorador_repertorio_gratis(t) -> void:
	var f := Personagem.nova()
	f["classe"] = "Mago"
	f["cartas"] = ["classe.mago.aprendiz-de-fogo", "classe.mago.aprendiz-de-terra"]
	f["herois"] = ["classe.mago.heroi.devorador-de-grimorios", "raca.humano.heroi.incansavel"]
	t.igual(Personagem.custo_xp(f), 1, "um Aprendiz sai de graça")


func test_lacaio_tem_11_de_vida(t) -> void:
	t.igual(int(Encontros.status("lacaio", "aggro", 4)["vida"]), 11, "lacaio com 11")
	var chefe := int(Encontros.status("chefe", "neutro", 4)["vida"])
	t.ok(chefe >= 125 and chefe <= 135, "chefe com ~130 (%d)" % chefe)


func test_herois_atravessam_aliados(t) -> void:
	var b := TC.new()._grupo_com("Guerreiro", "", "")
	var u := b.unidade("heroi")
	for o in b.inimigos_vivos():
		o.pos = Vector2i(11, b.inimigos_vivos().find(o))
	u.pos = Vector2i(3, 5)
	b.unidade("heroi2").pos = Vector2i(4, 5)
	u.deslocamento = 2
	var m: Dictionary = b.alcance_movimento(u)["mapa"]
	t.ok(m.has(Vector2i(5, 5)), "passa pelo aliado")
	t.ok(not m.has(Vector2i(4, 5)), "mas não para na casa dele")


func test_descanso_bloqueado_em_combate(t) -> void:
	var b := TC.new()._grupo_com("Guerreiro", "", "")
	var g := b.unidade("goblin1")
	g.alerta = true
	t.ok(b.heroi_em_combate() != "", "inimigo em alerta indo atrás de um herói: em combate")


func test_ombro_de_ferro_escolhe_a_casa(t) -> void:
	var b := TC.new()._grupo_com("Guerreiro", "classe.guerreiro.ombro-de-ferro", "")
	var u := b.unidade("heroi")
	var g := b.unidade("goblin1")   # ao lado
	var casas := b.casas_para_atacar(u, g, 1)
	t.ok(casas.size() > 1, "com o inimigo ao lado, ainda dá para andar 1 antes de atacar")
