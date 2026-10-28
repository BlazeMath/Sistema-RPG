## Cartas fiéis ao texto e cartas "como parte de um ataque" (0.14).
extends RefCounted

const Batalha := preload("res://core/batalha.gd")
const TC := preload("res://tests/test_classes.gd")


func _b(classe: String, carta: String) -> Batalha:
	return TC.new()._grupo_com(classe, carta, "classe.guerreiro.heroi.foco-mortal")


func _lado(u, slug: String) -> void:
	var c = u.cartas[u.cartas.size() - 1]
	if c.slug() != slug:
		c.lado = 1 - c.lado


func test_ataque_furtivo_durante_o_ataque(t) -> void:
	var b := _b("Ladino", "classe.ladino.ataque-furtivo")
	var u := b.unidade("heroi")
	_lado(u, "ataque-furtivo")
	u.dar_ficha("Sombra", 2)
	var g := b.unidade("goblin1")
	t.ok(b.heroi_atacar(g), "ataque normal")
	t.igual(b.cartas_durante_ataque().size(), 1, "a carta aparece na mesa")
	t.ok(b.heroi_durante_ataque("ataque-furtivo"), "1 Sombra")
	t.ok(b.heroi_durante_ataque("ataque-furtivo"), "2 Sombras")
	t.igual(u.fichas_total("Sombra"), 0, "gastou as duas")
	t.igual(b.ctx["bonus_extra"].size(), 2, "dois bônus de arma no mesmo ataque")
	t.igual(u.acoes_padrao, 1, "só o ataque gastou ação")


func test_cacador_combina_duas_cartas(t) -> void:
	var b := _b("Caçador", "classe.cacador.preparar-o-tiro")
	var u := b.unidade("heroi")
	_lado(u, "tiro-certeiro")
	u.dar_ficha("Mira", 1)
	var g := b.unidade("goblin3")
	g.pos = Vector2i(11, 5)
	u.pos = Vector2i(6, 5)
	b.unidade("goblin1").pos = Vector2i(11, 0)
	t.ok(b.heroi_atacar(g), "atira")
	var lim: int = b.teste_defesa.limite
	t.ok(b.heroi_durante_ataque("mira"), "descarta Mira (com Tiro Certeiro)")
	t.igual(b.teste_defesa.limite, lim - 1, "o defensor perde 1 no limite")


func _mago(carta: String, slug: String) -> Batalha:
	var b := _b("Mago", carta)
	_lado(b.unidade("heroi"), slug)
	return b


func test_repertorio_lista_as_tres_opcoes(t) -> void:
	var b := _mago("classe.mago.aprendiz-de-fogo", "aprendiz-de-fogo")
	var u := b.unidade("heroi")
	var op: Dictionary = b.opcoes_cartas(u)[u.cartas.size() - 1]
	t.igual(op["opcoes"].map(func(o): return o["opcao"]), ["chama-nenem", "manipular-chama", "nuvem-de-brasas"], "três opções na ordem da carta")
	t.igual(op["opcoes"][2]["custo"], 2, "Nuvem de Brasas custa 2")


func test_ventos_cortantes_paga_com_outras_cartas(t) -> void:
	# Conjuração (símbolo no PDF): a fadiga que não cabe na carta vai para outras cartas.
	var b := _mago("classe.mago.aprendiz-de-ar", "aprendiz-de-ar")
	var u := b.unidade("heroi")
	var i := u.cartas.size() - 1
	var op: Dictionary = b.opcoes_cartas(u)[i]
	t.ok(op["opcoes"][2]["pode"], "3 de fadiga numa carta de limite 2, pagando com outras")
	var antes := 0
	for c in u.cartas:
		antes += c.fadiga
	t.ok(b.heroi_usar_carta(i, b.unidade("goblin1"), "ventos-cortantes"), "usa")
	var depois := 0
	for c in u.cartas:
		depois += c.fadiga
	t.igual(depois - antes, 3, "3 de fadiga no total")
	t.igual(u.cartas[i].fadiga, 2, "2 na própria carta")


func test_manipular_chama(t) -> void:
	var b := _mago("classe.mago.aprendiz-de-fogo", "aprendiz-de-fogo")
	var u := b.unidade("heroi")
	var i := u.cartas.size() - 1
	var g := b.unidade("goblin1")
	t.ok(b.heroi_usar_carta(i, g, "manipular-chama"), "no goblin adjacente")
	t.igual(g.fichas_total("Fogo"), 1, "o goblin pega fogo")


func test_arma_petrea(t) -> void:
	var b := _mago("classe.mago.aprendiz-de-terra", "aprendiz-de-terra")
	var u := b.unidade("heroi")
	t.ok(b.heroi_usar_carta(u.cartas.size() - 1, null, "arma-petrea"), "usa")
	t.igual(b.fase, Batalha.Fase.PERGUNTA, "pergunta a arma")
	t.ok(b.heroi_responder("maca"), "escolhe a maça")
	t.igual(u.arma["nome"], "Maça de Pedra", "arma de pedra")
	t.igual(u.dano, 6, "dano da maça")
	t.igual(u.arma["tipo_dano"], "Concussão", "concussão")


func test_muro_fecha_a_passagem(t) -> void:
	var b := _mago("classe.mago.aprendiz-de-terra", "aprendiz-de-terra")
	var u := b.unidade("heroi")
	b.unidade("goblin1").pos = Vector2i(10, 10)
	t.ok(b.heroi_usar_area(u.cartas.size() - 1, u.pos + Vector2i(1, 0), 0, "muro"), "muro à direita")
	t.ok(b.grade.bloqueado(u.pos + Vector2i(1, 0)), "o quadrado ao lado fecha")
	t.ok(not b.grade.linha_de_visao(u.pos, u.pos + Vector2i(4, 0)), "e tapa a visão")


func test_passo_leve_e_nado(t) -> void:
	var b := _mago("classe.mago.aprendiz-de-ar", "aprendiz-de-ar")
	var u := b.unidade("heroi")
	b.unidade("goblin1").pos = Vector2i(10, 10)
	b.criar_zona("piche", "Piche", [u.pos + Vector2i(0, 1)], null, {"terreno_dificil": true, "vinculada": false})
	var antes: int = b.grade.alcance(u.pos, 1, {}, {}, b.modo_de_andar(u)).size()
	t.ok(b.heroi_usar_carta(u.cartas.size() - 1, null, "passo-leve"), "Passo Leve")
	t.ok(b.modo_de_andar(u)["sem_terreno"], "ignora terreno difícil")
	t.igual(b.grade.alcance(u.pos, 1, {}, {}, b.modo_de_andar(u)).size(), antes + 1, "o piche custa 1")
	b.grade.obstaculos[u.pos + Vector2i(-1, -1)] = "agua"
	t.ok(not b.grade.alcance(u.pos, 1, {}, {}, {"nada": true}).is_empty() and b.grade.alcance(u.pos, 1, {}, {}, {"nada": true}).has(u.pos + Vector2i(-1, -1)), "nadando, entra na água")


func test_desarmar(t) -> void:
	var b := _mago("classe.mago.aprendiz-de-agua", "aprendiz-de-agua")
	var g := b.unidade("goblin1")
	b.desarmar(g)
	t.igual(g.dano, 0, "o goblin fica sem arma")
	var h := b.unidade("heroi2")
	b.desarmar(h)
	t.igual(h.arma["nome"], "Desarmado", "o herói larga a arma")


func test_veu_e_lamina_dupla(t) -> void:
	var b := _mago("classe.mago.aprendiz-de-sombra", "aprendiz-de-sombra")
	var u := b.unidade("heroi")
	var i := u.cartas.size() - 1
	t.ok(b.heroi_usar_carta(i, null, "veu"), "Véu")
	t.ok(u.efeitos.has("oculto"), "oculto")
	b.unidade("goblin2").pos = u.pos + Vector2i(1, 1)
	var mao := u.baralho.mao.size()
	t.ok(b.heroi_usar_carta(i, b.unidade("goblin1"), "lamina-das-sombras"), "Lâmina das Sombras")
	t.igual(b.fase, Batalha.Fase.PERGUNTA, "pergunta se descarta")
	t.ok(b.heroi_responder("goblin2"), "descarta para o segundo alvo")
	t.igual(u.baralho.mao.size(), mao - 1, "uma carta a menos na mão")
	t.igual(b.ctx.get("area_fila", []), ["goblin2"], "o segundo alvo se defende depois")


func test_isca_atrai_a_fera(t) -> void:
	var b := _b("Caçador", "classe.cacador.armadilha-de-caca")
	var u := b.unidade("heroi")
	_lado(u, "oleos-e-iscas")
	var i := u.cartas.size() - 1
	var g := b.unidade("goblin2")
	t.ok(not b.opcoes_cartas(u)[i]["opcoes"].filter(func(o): return o["opcao"] == "isca")[0]["pode"], "sem fera, sem isca")
	g.tipo = "toupeira"
	g.espirito = -20   # não resiste
	var cel := u.pos + Vector2i(2, -2)
	t.ok(b.heroi_usar_area(i, cel, 0, "isca"), "joga a isca")
	t.igual(g.efeitos.get("isca", {}).get("pos", Vector2i.ZERO), cel, "a fera vai atrás")


func test_oleo_antidoto_emplastro(t) -> void:
	var b := _b("Caçador", "classe.cacador.armadilha-de-caca")
	var u := b.unidade("heroi")
	_lado(u, "oleos-e-iscas")
	var i := u.cartas.size() - 1
	var g := b.unidade("goblin1")
	t.ok(b.heroi_usar_carta(i, g, "oleo-2"), "Óleo com 2")
	t.igual(g.fichas_total("Fogo"), 2, "2 fichas de Fogo")
	t.igual(u.cartas[i].fadiga, 2, "custou 2")
	var h := b.unidade("heroi2")
	h.pos = u.pos + Vector2i(0, 1)
	h.dar_ficha("Sangramento")
	h.dar_ficha("Ferimento")
	u.cartas[i].fadiga = 0
	t.ok(b.heroi_usar_carta(i, h, "emplastro"), "Emplastro")
	t.igual(h.fichas_total("Sangramento") + h.fichas_total("Ferimento"), 0, "sai Sangramento e Ferimento")


func test_salmos_e_bencao(t) -> void:
	var b := _b("Clérigo", "classe.clerigo.bencao-dos-salmos")
	var u := b.unidade("heroi")
	_lado(u, "bencao-dos-salmos")
	var i := u.cartas.size() - 1
	var h := b.unidade("heroi2")
	h.dar_ficha("Medo")
	t.ok(b.heroi_usar_carta(i, h, "remover"), "remove ficha do aliado ao lado")
	t.igual(h.fichas_total("Medo"), 0, "sem Medo")
	var op: Dictionary = b.opcoes_cartas(u)[i]
	t.igual(op["opcoes"][1]["custo"], 2, "curar custa 2")


func test_cone(t) -> void:
	const Areas := preload("res://core/areas.gd")
	var g := preload("res://core/grade.gd").new(20, 20)
	var reto := Areas.celulas({"forma": "cone", "tamanho": 3}, Vector2i(5, 5), Vector2i(6, 5), 0, g)
	t.igual(reto.size(), 7, "cone reto: 1 + 3 + 3")
	var diag := Areas.celulas({"forma": "cone", "tamanho": 3}, Vector2i(5, 5), Vector2i(6, 6), 0, g)
	t.igual(diag.size(), 9, "cone na diagonal: 3x3")


func test_misseis_divididos(t) -> void:
	var b := _b("Mago", "classe.mago.misseis-magicos")
	var u := b.unidade("heroi")
	_lado(u, "misseis-magicos")
	var g1 := b.unidade("goblin1")
	var g2 := b.unidade("goblin3")
	var v1 := g1.vida
	var v2 := g2.vida
	t.ok(b.heroi_usar_misseis(u.cartas.size() - 1, ["goblin1", "goblin3", "goblin1"]), "dispara")
	t.igual(v1 - g1.vida, 2, "2 mísseis no primeiro")
	t.igual(v2 - g2.vida, 1, "1 no segundo")


func test_mente_belica_escolhe_a_carta(t) -> void:
	var b := _b("Mago", "classe.mago.mente-belica")
	var u := b.unidade("heroi")
	_lado(u, "mente-belica")
	b.perguntar_escolhas = true
	var carta: int = u.baralho.mao[u.baralho.mao.size() - 1]
	t.ok(b.heroi_usar_carta(u.cartas.size() - 1), "usa")
	t.igual(b.fase, Batalha.Fase.PERGUNTA, "pergunta qual")
	b.heroi_responder(str(carta))
	t.ok(carta in u.baralho.descarte, "a carta escolhida foi para o descarte")
	t.ok(u.efeitos.has("mente_belica"), "+3 na próxima magia")


func test_martelo_da_vantagem(t) -> void:
	var b := _b("Clérigo", "")
	var u := b.unidade("heroi")
	u.efeitos["vantagem_na_arma"] = {}
	t.ok(b.heroi_atacar(b.unidade("goblin1")), "ataca")
	t.ok(b.teste_ataque.vantagem, "o ataque tem vantagem")
	t.ok(not u.efeitos.has("vantagem_na_arma"), "a ficha foi gasta")


func test_motivo_de_cada_opcao(t) -> void:
	# A opção de ataque sem alvo não pode bloquear as outras opções da carta.
	var b := _mago("classe.mago.aprendiz-de-terra", "aprendiz-de-terra")
	var u := b.unidade("heroi")
	for o in b.inimigos_vivos():
		o.pos = Vector2i(11, o.pos.y)
	var op: Dictionary = b.opcoes_cartas(u)[u.cartas.size() - 1]
	t.ok(op["opcoes"][0]["pode"], "Arma Pétrea pode, mesmo sem inimigo ao alcance")
	t.ok(not op["opcoes"][2]["pode"], "Enterrar na Fissura não pode")
