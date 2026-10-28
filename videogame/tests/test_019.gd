## 0.19: Muro com vida, reações sempre perguntadas, Contramagia com teste do conjurador.
extends RefCounted

const Batalha := preload("res://core/batalha.gd")
const TC := preload("res://tests/test_classes.gd")


func test_muro_tem_vida_e_sofre_empurrao(t) -> void:
	var b := TC.new()._grupo_com("Guerreiro", "", "")
	var u := b.unidade("heroi")
	var g := b.unidade("goblin1")
	var z := b.criar_zona("muro", "Muro de Rocha", [Vector2i(9, 5), Vector2i(9, 6)], u, {"bloqueia": true, "vinculada": false, "vida": 12})
	g.pos = Vector2i(8, 5)
	b._empurrar(g, u.pos, 2)
	t.igual(int(z["vida"]), 8, "o muro sofre o dano do empurrão (2 por quadrado que faltou)")
	b.dano_no_muro(z, 8, "teste")
	t.ok(not z in b.zonas, "sem vida, o muro desmorona")
	t.ok(not b.grade.bloqueado(Vector2i(9, 5)), "e a passagem abre")


func test_inimigo_quebra_o_muro(t) -> void:
	var b := TC.new()._grupo_com("Guerreiro", "", "")
	var u := b.unidade("heroi")
	var g := b.unidade("goblin1")
	# Fecha o herói num canto com muro: o goblin só chega quebrando.
	for o in b.inimigos_vivos():
		if o != g:
			o.vida = 0
	b.unidade("heroi2").pos = Vector2i(0, 9)
	u.pos = Vector2i(0, 0)
	var z := b.criar_zona("muro", "Muro de Rocha", [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], u, {"bloqueia": true, "vinculada": false, "vida": 12})
	g.pos = Vector2i(2, 1)
	g.alerta = true
	g.novo_turno()
	t.ok(not b._muro_no_caminho(g, u).is_empty(), "o muro é o que separa")
	t.ok(b._ia_quebrar_muro(g, z), "golpeia o muro")
	t.ok(int(z["vida"]) < 12, "o muro perde vida")


func test_golpe_de_oportunidade_pergunta(t) -> void:
	var b := TC.new()._grupo_com("Guerreiro", "classe.guerreiro.golpe-de-oportunidade", "")
	var u := b.unidade("heroi")
	var g := b.unidade("goblin1")
	var c = u.carta_com("golpe-de-oportunidade")
	t.ok(c != null, "tem a carta")
	b.perguntar_escolhas = true
	g.pos = u.pos + Vector2i(1, 0)
	var rea := u.acoes_reacao
	b._percorrer(g, [g.pos + Vector2i(1, 0)], false)
	t.igual(b.fase, Batalha.Fase.PERGUNTA, "pergunta antes de usar a Reação")
	b.heroi_responder("nao")
	t.igual(u.acoes_reacao, rea, "deixou passar: a Reação fica")
	t.igual(g.pos, u.pos + Vector2i(2, 0), "e o inimigo termina o movimento")


func test_contramagia_conjurador_testa(t) -> void:
	var b := TC.new()._grupo_com("Mago", "classe.mago.contramagia", "")
	var opcoes: Array = b.opcoes_de_anular(b.unidade("heroi2"), b.unidade("goblin1"))
	var texto := ""
	for o in opcoes:
		texto += str(o[1])
	t.ok("Contramagia" in texto and "teste de Sabedoria" in texto, "Contramagia contra o teste do conjurador")


func test_retrato_da_batalha(t) -> void:
	const Inst := preload("res://core/instantaneo.gd")
	const Masmorra := preload("res://core/dados_masmorra.gd")
	var tc = TC.new()
	var fichas := [tc._ficha("Guerreiro", "A", [], ["classe.guerreiro.heroi.foco-mortal", "raca.humano.heroi.incansavel"]), tc._ficha("Mago", "B", [], [])]
	var b := Batalha.new(Masmorra.missao(fichas), 11)
	b.iniciar()
	var h := b.unidade("heroi")
	h.pos += Vector2i(1, 0)
	h.baralho.exilio.append(h.baralho.baralho.pop_back())
	h.cartas[0].dar_ficha("Foco")
	b.ouro_ganho = 33
	b.atacante = h
	var texto := Inst.para_texto(b)
	var c := Batalha.new(Masmorra.missao(fichas), 99)
	t.ok(Inst.aplicar_texto(c, texto), "aplica")
	var h2 := c.unidade("heroi")
	t.igual(h2.pos, h.pos, "posição volta")
	t.igual(h2.baralho.exilio.size(), h.baralho.exilio.size(), "exílio volta")
	t.igual(h2.baralho.baralho, h.baralho.baralho, "ordem do baralho volta")
	t.igual(c.ouro_ganho, 33, "ouro achado volta")
	t.ok(c.atacante == h2, "referências apontam para a mesma unidade")
	t.igual(str(h2.cartas[0].fichas), str(h.cartas[0].fichas), "fichas nas cartas voltam")
	t.igual(c.rng.state, b.rng.state, "sorteio continua igual")
	t.igual(c.grade.obstaculos.size(), b.grade.obstaculos.size(), "mapa volta")
	t.igual(c.interacoes.size(), b.interacoes.size(), "interações voltam")


func test_ponto_de_descanso_e_salvar(t) -> void:
	const Masmorra := preload("res://core/dados_masmorra.gd")
	const Salvamento := preload("res://core/salvamento.gd")
	const Sessao := preload("res://core/sessao.gd")
	const Inst := preload("res://core/instantaneo.gd")
	var tc = TC.new()
	var fichas := [tc._ficha("Guerreiro", "A", [], []), tc._ficha("Mago", "B", [], [])]
	var b := Batalha.new(Masmorra.missao(fichas), 5)
	b.iniciar()
	var fonte := b.interacao("fonte")
	t.ok(fonte.get("descanso", false), "a fonte da capela é ponto de descanso")
	var op: Dictionary = fonte["opcoes"][0]
	t.ok(op.has("sem_inimigos_perto"), "só sem inimigos por perto")
	var h := b.unidade("heroi")
	h.pos = fonte["pos"] + Vector2i(-1, 0)
	var o = b.inimigos_vivos()[0]
	o.pos = fonte["pos"] + Vector2i(-3, 0)
	b.indice_vez = b.ordem.find("heroi")
	b.fase = Batalha.Fase.HEROI_ESCOLHE
	b._comecar_turno()
	t.ok(b.motivo_sem_opcao(h, fonte, op).contains("inimigos por perto"), "inimigo perto: fechado")
	for x in b.inimigos_vivos():
		x.pos = Vector2i(1, 1) if b.grade.dentro(Vector2i(1, 1)) else x.pos
		x.alerta = false
		x.vida = 0
	t.igual(b.motivo_sem_opcao(h, fonte, op), "", "área limpa: aberto")
	t.ok(b.motivo_salvar() != "", "antes de descansar, não salva")
	b.descansos_usados["fonte"] = true
	b.fase = Batalha.Fase.HEROI_ESCOLHE
	t.igual(b.motivo_salvar(), "", "depois de descansar, salva ali")
	Sessao.modo = "masmorra"
	Salvamento.salvar(3, "teste", b)
	Sessao.estado_salvo = ""
	Salvamento.carregar(3)
	t.igual(Sessao.modo, "masmorra", "volta para a missão")
	t.ok(Sessao.estado_salvo != "", "com o retrato da batalha")
	var c := Batalha.new(Masmorra.missao(fichas), 77)
	t.ok(Inst.aplicar_texto(c, Sessao.estado_salvo), "aplica")
	t.igual(c.unidade("heroi").pos, h.pos, "o herói está onde parou")
	t.ok(c.descansos_usados.has("fonte"), "o descanso feito continua")
	Sessao.estado_salvo = ""
	Salvamento.apagar(3)


func test_ciclo_sobe_nivel_e_destrava(t) -> void:
	const Campanha := preload("res://core/campanha.gd")
	const Personagem := preload("res://core/personagem.gd")
	var guardado := Campanha.dados.duplicate(true)
	Campanha.dados = {"ouro": 0, "feridas": {}, "concluidas": [], "nivel": 1, "desbloqueadas": []}
	t.igual(Campanha.motivo_trancada("fazenda"), "", "a primeira missão está aberta")
	t.ok(Campanha.motivo_trancada("masmorra") != "", "a cripta espera a fazenda")
	Campanha.dados["concluidas"] = ["fazenda", "masmorra"]
	t.igual(Campanha.motivo_trancada("pantano"), "", "o pântano abre depois da cripta")
	t.igual(Campanha._verificar_nivel(), "", "ciclo incompleto: não sobe")
	var fichas_antes := Personagem.carregar_todos()
	Campanha.dados["concluidas"].append("pantano")
	t.ok(Campanha._verificar_nivel().contains("NÍVEL 2"), "fechou o ciclo: nível 2")
	t.igual(Campanha.nivel(), 2, "nível guardado")
	for f in Personagem.carregar_todos():
		t.ok(int(f["xp"]) >= 3, "%s com XP do nível 2" % f["nome"])
	Personagem.salvar_todos(fichas_antes)
	Campanha.dados = guardado


func test_pedra_alta_da_vantagem(t) -> void:
	const Fazenda := preload("res://core/dados_fazenda.gd")
	var tc = TC.new()
	var b := Batalha.new(Fazenda.missao([tc._ficha("Caçador", "A", [], [])]), 3)
	b.iniciar()
	var h := b.unidade("heroi")
	var pedra := b.interacao("pedra_vigia")
	t.ok(not pedra.is_empty(), "a fazenda tem a pedra do vigia")
	h.pos = pedra["pos"] + Vector2i(-1, 0)
	b.indice_vez = b.ordem.find("heroi")
	b._comecar_turno()
	b.interacao_atual = {"id": "pedra_vigia", "opcao": "escalar", "dano": 0, "vitoria": ""}
	b._aplicar_efeito(h, pedra, {"tipo": "subir"})
	t.igual(h.pos, pedra["pos"], "subiu na pedra")
	t.ok(b.no_alto(h), "está no alto")
	var o = b.inimigos_vivos()[0]
	o.pos = h.pos + Vector2i(3, 0)
	b._novo_ataque(h, o, {})
	t.ok(b.teste_ataque.vantagem, "ataque do alto tem vantagem")
	var m: Dictionary = b.alcance_movimento(h)["mapa"]
	t.ok(m.size() > 1, "dá para descer andando")


func test_arvore_e_lore(t) -> void:
	const Pantano := preload("res://core/dados_pantano.gd")
	var tc = TC.new()
	var b := Batalha.new(Pantano.missao([tc._ficha("Mago", "A", [], [])]), 3)
	b.iniciar()
	var h := b.unidade("heroi")
	var arv := b.interacao("amoreira")
	b._aplicar_efeito(h, arv, {"tipo": "item", "item": "frutas_silvestres", "qtd": 2})
	t.igual(h.consumiveis.count("frutas_silvestres"), 2, "colheu frutas")
	b._aplicar_efeito(h, b.interacao("diario_morgana"), {"tipo": "lore", "texto": "teste de lore"})
	t.ok("teste de lore" in b.lore_achada, "lore guardada")
