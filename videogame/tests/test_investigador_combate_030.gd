extends RefCounted

const Batalha := preload("res://core/batalha.gd")
const Investigador := preload("res://core/cartas_investigador.gd")
const Teste21 := preload("res://core/teste21.gd")
const Prontos := preload("res://core/herois_prontos.gd")
const Base := preload("res://tests/test_025.gd")


func _arena(heroi: String, cartas: Array, aliado := false, meias := []) -> Batalha:
	var f := Prontos.ficha("Investigador")
	f["herois"][0] = "classe.investigador.heroi." + heroi
	f["cartas"] = cartas.map(func(s): return "classe.investigador." + s)
	f["meias"] = meias.map(func(s): return "classe.investigador." + s)
	var fichas := [f]
	if aliado:
		fichas.append(Prontos.ficha("Guerreiro"))
	var b := Base.new()._arena(fichas)
	b.unidade("goblin1").reacoes = []
	b.dano_na_armadura = false
	return b


func test_pistas_sao_fichas_e_pagam_a_compra_uma_vez(t) -> void:
	var b := _arena("perfilador", ["pressao-calculada"], true)
	var u := b.unidade("heroi2")
	b.indice_vez = b.ordem.find(u.id)
	b._comecar_turno()
	Investigador.ganhar(b, u, 3)
	t.igual(Investigador.pistas(u), 3, "Pistas empilham mesmo em herói de outra classe")
	var antes := u.baralho.mao.size()
	var padrao := u.acoes_padrao
	t.ok(not b.heroi_usar_pistas(4), "não compra mais do que possui")
	t.ok(b.heroi_usar_pistas(2), "aliado também pode gastar")
	t.igual(u.acoes_padrao, padrao - 1, "duas cartas usam uma Padrão")
	t.igual(u.baralho.mao.size(), antes + 2, "comprou duas cartas")
	t.igual(Investigador.pistas(u), 1, "pagou as duas Pistas")
	u.carta_heroi().virar()
	t.igual(Investigador.pistas(u), 0, "a virada remove Pistas da carta")


func test_pressao_propria_habilita_gesto_sem_acumular_bloqueio(t) -> void:
	var b := _arena("perfilador", ["pressao-calculada"])
	var u := b.ativa()
	var alvo := b.unidade("goblin1")
	var c = u.carta_com("pressao-calculada")
	Investigador.ganhar(b, u, 2)
	alvo.dar_ficha("Medo")
	t.ok(b.heroi_usar_carta(u.cartas.find(c), alvo), "ativa a Pressão contra goblinoide perceptível")
	t.igual(alvo.fichas_total("Medo"), 2, "há fichas comum e atribuída")
	t.igual(alvo.fontes_de_fichas["Medo"], [u.id], "somente uma ficha pertence ao Investigador")
	c.virar()
	u.dar_ficha("Bloqueio")
	b.perguntar_escolhas = true
	b.indice_vez = b.ordem.find(alvo.id)
	b._comecar_turno()
	b.baralho_inimigos.baralho.assign([34, 22, 9])
	u.baralho.baralho.assign([35, 5, 4])
	b._novo_ataque(alvo, u, {})
	b.teste_ataque.parar()
	b.teste_defesa.parar()
	b._resolver()
	t.igual(b.pergunta.get("id"), "investigador-gesto", "oferece reação depois do dano calculado")
	var dano: int = b.resultado["dano"]
	t.ok(dano > 1, "o ataque acertou e causaria dano")
	t.igual(b.quem_decide(), u.id, "a reação pertence ao autor da pressão")
	t.ok(b.heroi_responder("Medo"), "paga com seu próprio Medo")
	t.igual(b.resultado["dano"], ceili(dano / 2.0), "reduz o dano calculado à metade")
	t.igual(alvo.fichas_total("Medo"), 1, "mantém o Medo de outra fonte")
	t.igual(u.fichas_total("Bloqueio"), 1, "Bloqueio não se acumula nem é consumido")
	t.igual(Investigador.pistas(u), 0, "gasta a segunda Pista na reação")


func test_leitura_revela_a_fechada_antes_de_compras_adicionais(t) -> void:
	var b := _arena("perfilador", ["pergunta-precisa"])
	var u := b.ativa()
	var c = u.carta_com("pergunta-precisa")
	c.virar()
	var alvo := b.unidade("goblin1")
	u.percepcao = 0
	Investigador.ganhar(b, u, 1)
	b.perguntar_escolhas = true
	b.baralho_inimigos.baralho.assign([34, 4, 3])
	t.ok(b.heroi_atacar(alvo), "inicia um teste contestado de ataque")
	t.igual(b.pergunta.get("id"), "investigador-leitura", "oferece reação antes das compras adicionais")
	var cartas := b.teste_defesa.cartas.duplicate()
	t.ok(not b.teste_defesa.revelado, "a defesa começa fechada")
	t.ok(b.heroi_responder("sim"), "aceita revelar")
	t.ok(b.teste_defesa.revelado, "revela a carta fechada")
	t.igual(b.teste_defesa.cartas, cartas, "não altera as cartas do teste")
	t.igual(Investigador.pistas(u), 0, "paga uma Pista")


func test_perfilador_so_ganha_pista_por_penalidade_propria_e_uma_vez(t) -> void:
	var b := _arena("perfilador", [])
	var u := b.ativa()
	var alvo := b.unidade("goblin1")
	alvo.dar_ficha("Penalidade")
	b.baralho_inimigos.baralho.assign([34, 6, 22, 9])
	var teste := Teste21.new(b.baralho_inimigos)
	teste.puxar()
	t.ok(teste.estourou, "o adversário estourou")
	Investigador.inimigo_estourou(b, alvo, teste)
	t.igual(Investigador.pistas(u), 0, "Penalidade alheia não dispara A Máscara Cai")
	alvo.dar_ficha("Penalidade", 1, u.id)
	Investigador.inimigo_estourou(b, alvo, teste)
	Investigador.inimigo_estourou(b, alvo, teste)
	t.igual(Investigador.pistas(u), 1, "fonte própria dispara uma vez na rodada")
	alvo.tirar_fichas("Penalidade", 2)
	t.ok(alvo.fontes_de_fichas.is_empty(), "remoções limpam a atribuição correspondente")


func test_expor_o_perfil_e_conferir_anotacoes_registram_lados_nativos(t) -> void:
	var b := _arena("perfilador", [], false, ["conferir-anotacoes", "olhar-atento"])
	var u := b.ativa()
	var alvo := b.unidade("goblin1")
	Investigador.ganhar(b, u, 2)
	u.baralho.baralho.assign([35, 22, 9])
	b.baralho_inimigos.baralho.assign([34, 4, 3])
	t.ok(b.heroi_usar_carta(u.cartas.find(u.carta_heroi()), alvo), "a metade do herói oferece Expor o Perfil")
	t.igual(alvo.fontes_de_fichas["Penalidade"], [u.id], "o teste vencido aplica Penalidade atribuída")
	b.perguntar_escolhas = true
	var c = u.carta_com("conferir-anotacoes")
	t.ok(b.heroi_usar_carta(u.cartas.find(c)), "meia carta oferece Conferir Anotações")
	t.igual(b.pergunta.get("id"), "scry", "anotações inicia scry")
	t.igual(Investigador.pistas(u), 0, "as duas ativações gastam uma Pista cada")


func test_percurso_seguro_pede_dois_ajustes_sem_oportunidade(t) -> void:
	var b := _arena("perfilador", ["reconhecimento"], true)
	var u := b.ativa()
	var aliado := b.unidade("heroi2")
	var inimigo := b.unidade("goblin2")
	inimigo.pos = Vector2i(5, 6)
	inimigo.alerta = true
	inimigo.acoes_reacao = 1
	var c = u.carta_com("reconhecimento")
	c.virar()
	Investigador.ganhar(b, u, 1)
	b.perguntar_escolhas = true
	t.ok(b.heroi_usar_carta(u.cartas.find(c), aliado), "ativa Percurso Seguro no aliado")
	t.igual(b.quem_decide(), aliado.id, "aliado escolhe seu Ajustar")
	t.ok(b.heroi_responder("5/4"), "seleciona a primeira casa")
	t.igual(aliado.pos, Vector2i(5, 4), "o aliado Ajusta 1")
	t.ok(b.heroi_responder("4/4"), "seleciona a segunda casa")
	t.igual(aliado.pos, Vector2i(4, 4), "o aliado Ajusta 1 novamente")
	t.igual(inimigo.acoes_reacao, 1, "Ajustar não provoca oportunidade")
