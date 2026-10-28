## 0.16: fadiga escolhida, escuro com 1 carta, Planejar 2, Foco (scry), Preparo ou ação, mãos e troca de arma.
extends RefCounted

const Batalha := preload("res://core/batalha.gd")
const Itens := preload("res://core/itens.gd")
const TC := preload("res://tests/test_classes.gd")
const T2 := preload("res://tests/test_cartas2.gd")


func test_fadiga_escolhida(t) -> void:
	var b: Batalha = T2.new()._mago("classe.mago.aprendiz-de-ar", "aprendiz-de-ar")
	var u := b.unidade("heroi")
	var i := u.cartas.size() - 1
	var c = u.cartas[i]
	t.igual(b.sobra_de_fadiga(u, c, 3), 1, "1 não cabe na carta")
	var destino: int = b.cartas_para_fadiga(u, c)[0]["indice"]
	b.fadiga_escolhida = {destino: 1}
	var antes: int = u.cartas[destino].fadiga
	t.ok(b.heroi_usar_carta(i, b.unidade("goblin1"), "ventos-cortantes"), "usa")
	t.igual(u.cartas[destino].fadiga, antes + 1, "a sobra foi para a carta escolhida")


func test_escuro_uma_carta(t) -> void:
	var b := TC.new()._grupo_com("Guerreiro", "", "classe.guerreiro.heroi.foco-mortal")
	b.escuro = true
	var u := b.unidade("heroi")
	var g := b.unidade("goblin3")
	u.a_distancia = true
	u.alcance_corpo = 1
	g.pos = u.pos + Vector2i(1, 0)
	u.efeitos["ver_teste"] = {}
	# ao lado sempre enxerga; afastado no escuro não dá nem para atirar
	g.pos = u.pos + Vector2i(3, 0)
	t.ok(b.motivo_alcance(u, g, u.pos) != "", "no escuro não atira em quem não vê")


func test_planejar_mostra_duas(t) -> void:
	var b := TC.new()._grupo_com("Guerreiro", "", "classe.guerreiro.heroi.foco-mortal")
	var u := b.unidade("heroi")
	u.raciocinio = 1
	b.eventos.clear()
	t.ok(b.heroi_planejar(), "planeja")
	var ev = b.eventos.filter(func(e): return e["tipo"] == "espiar")
	t.igual(ev[0]["cartas"].size(), 2, "2 cartas do topo")


func test_foco_scry(t) -> void:
	var b := TC.new()._grupo_com("Guerreiro", "", "classe.guerreiro.heroi.foco-mortal")
	var u := b.unidade("heroi")
	u.dar_ficha("Foco")
	b.perguntar_escolhas = true
	var topo: int = u.baralho.baralho[-1]
	t.ok(b.heroi_usar_foco(), "descarta Foco")
	t.igual(b.fase, Batalha.Fase.PERGUNTA, "pergunta")
	b.heroi_responder("fundo")
	t.igual(u.baralho.baralho[0], topo, "a carta foi para o fundo")
	t.igual(u.fichas_total("Foco"), 0, "ficha gasta")


func test_virar_com_acao_mesmo_com_preparo(t) -> void:
	var b := TC.new()._grupo_com("Guerreiro", "classe.guerreiro.ombro-de-ferro", "classe.guerreiro.heroi.foco-mortal")
	var u := b.unidade("heroi")
	u.cartas[u.cartas.size() - 1].dar_ficha("Preparo")   # 0.20: o Preparo vira só a carta em que está
	var padrao := u.acoes_padrao
	t.ok(b.heroi_virar(u.cartas.size() - 1, "acao"), "vira gastando a ação")
	t.igual(u.acoes_padrao, padrao - 1, "gastou a ação")
	t.igual(u.fichas_total("Preparo"), 0, "virar apaga as fichas da carta (o Preparo dela também)")
	u.cartas[u.cartas.size() - 1].dar_ficha("Preparo")
	t.ok(not b.heroi_virar(0, "preparo") or u.cartas[0].tem_ficha("Preparo"), "o Preparo não vira outra carta")
	t.ok(b.heroi_virar(u.cartas.size() - 1, "preparo"), "vira com o Preparo")
	t.igual(u.fichas_total("Preparo"), 0, "agora gastou o Preparo")


func test_trocar_arma(t) -> void:
	var b := TC.new()._grupo_com("Guerreiro", "", "classe.guerreiro.heroi.foco-mortal")
	var u := b.unidade("heroi")
	u.arma_reserva = Itens.ARMAS["maca"].duplicate(true)
	var pad := u.acoes_padrao
	t.ok(b.heroi_trocar_arma(), "troca")
	t.igual(u.arma["nome"], "Maça", "maça na mão")
	t.igual(u.dano, 6, "dano da maça")
	t.igual(u.arma_reserva["nome"], "Espada Longa", "a espada vai para a reserva")
	t.igual(u.acoes_padrao, pad, "Guerreiro com a Bandoleira: a troca não custa ação")
	t.igual(b.custo_troca(u), 1, "Bandoleira: só uma troca grátis por turno")
	t.ok(b.heroi_trocar_arma(), "troca de volta")
	t.igual(u.acoes_padrao, pad - 1, "segunda troca no turno custa 1 ação Padrão")
	u.equipamentos.erase("bandoleira_de_armas")
	t.ok(b.heroi_trocar_arma(), "troca de novo")
	t.igual(u.acoes_padrao, pad - 2, "sem a Bandoleira, 1 ação Padrão")
	t.igual(b.maos_de(u), ["Maça", "Escudo leve"], "mãos")
	t.ok(not b.heroi_trocar_arma(), "sem ação Padrão, não troca")
	u.arma_reserva = Itens.ARMAS["montante"].duplicate(true) if Itens.ARMAS.has("montante") else u.arma_reserva
	if u.arma_reserva.get("tamanho", "") == "grande":
		t.igual(b.custo_troca(u), 2, "arma grande: 2 ações Padrão")


func test_herois_prontos_validos(t) -> void:
	const Prontos := preload("res://core/herois_prontos.gd")
	const Personagem := preload("res://core/personagem.gd")
	for f in Prontos.todas():
		t.igual(Personagem.validar(f), [] as Array[String], "%s válido" % f["nome"])


func test_salvar_e_carregar(t) -> void:
	const Salvamento := preload("res://core/salvamento.gd")
	const Campanha := preload("res://core/campanha.gd")
	const Sessao := preload("res://core/sessao.gd")
	const Prontos := preload("res://core/herois_prontos.gd")
	var nomes := Prontos.salvar_prontos()
	Sessao.definir_grupo(nomes.slice(0, 2))
	Campanha.dados = {"ouro": 77, "feridas": {nomes[0]: {"exilio": 4, "descarte": 0}}, "concluidas": ["fazenda"]}
	Salvamento.salvar(3, "teste")
	Campanha.dados = {"ouro": 1, "feridas": {}, "concluidas": []}
	Sessao.definir_grupo([nomes[4]])
	Salvamento.carregar(3)
	t.igual(Campanha.ouro(), 77, "ouro volta")
	t.igual(Sessao.nomes_do_grupo(), nomes.slice(0, 2), "grupo volta")
	t.igual(int(Campanha.feridas_de(nomes[0])["exilio"]), 4, "exílio volta")
	Salvamento.apagar(3)
	Campanha.dados = {}
