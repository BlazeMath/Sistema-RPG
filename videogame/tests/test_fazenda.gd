## 0.8: a missão da fazenda Vale Seco.
extends RefCounted

const Batalha := preload("res://core/batalha.gd")
const Fazenda := preload("res://core/dados_fazenda.gd")
const Personagem := preload("res://core/personagem.gd")
const Grade := preload("res://core/grade.gd")


func _missao(n := 4, semente := 3) -> Batalha:
	var fichas := []
	for i in n:
		var f := Personagem.nova()
		f["nome"] = "Herói %d" % (i + 1)
		fichas.append(f)
	var b := Batalha.new(Fazenda.missao(fichas), semente)
	b.iniciar()
	b.indice_vez = b.ordem.find("heroi")
	b._comecar_turno()
	return b


func test_mapa_e_unidades(t) -> void:
	var b := _missao()
	t.igual(b.herois().size(), 4, "quatro heróis")
	t.igual(b.grade.largura, 30, "mapa grande")
	for it in b.interacoes:
		t.ok(b.grade.dentro(it["pos"]), "%s dentro do mapa" % it["id"])
	for u in b.unidades:
		t.ok(not b.grade.bloqueado(u.pos), "%s em casa livre" % u.nome)


func test_conversa_com_rokk_manda_os_goblins_embora(t) -> void:
	var b := _missao()
	b.unidade("heroi").pos = Vector2i(14, 4)
	b.interacao_atual = {"id": "acampamento", "opcao": "falar", "dano": 0, "vitoria": "",
		"op_teste": b.opcao_com_abordagem(b.opcao_da_interacao(b.interacao("acampamento"), "falar"), "diplomacia")}
	b._resolver_interacao(20)
	for id in Fazenda.GOBLINS:
		t.ok(not b.unidade(id).viva(), id + " foi embora")
	t.ok(b.unidade("toupeira").fichas_total("Marcado") > 0, "Rokk contou onde está a Toupeira")
	b.continuar()
	t.igual(b.fase, Batalha.Fase.HEROI_ESCOLHE, "a missão continua")


func test_conversa_falha_vira_briga_so_com_goblins(t) -> void:
	var b := _missao()
	b.interacao_atual = {"id": "acampamento", "opcao": "falar", "dano": 0, "vitoria": "",
		"op_teste": b.opcao_com_abordagem(b.opcao_da_interacao(b.interacao("acampamento"), "falar"), "mentir")}
	b._resolver_interacao(3)
	t.ok(b.unidade("rokk").alerta, "goblins em alerta")
	t.ok(not b.unidade("toupeira").alerta, "a Toupeira continua dormindo")


func test_matar_a_toupeira_cumpre_a_missao(t) -> void:
	var b := _missao()
	var toupeira := b.unidade("toupeira")
	t.ok(toupeira.vida_max > 60, "a Toupeira aguenta um grupo de 4")
	b._aplicar_dano_inimigo(toupeira, 999)
	t.ok(b._verificar_fim(), "fim")
	t.igual(b.fase, Batalha.Fase.VITORIA, "vitória")


func test_descanso_curto_vale_para_o_grupo(t) -> void:
	var b := _missao()
	var cab := b.interacao("cabana")
	var posicoes := [Vector2i(19, 15), Vector2i(19, 16), Vector2i(19, 17), Vector2i(21, 17)]
	var antes := {}
	for i in b.herois().size():
		var h = b.herois()[i]
		h.pos = posicoes[i]
		h.baralho.sofrer_dano(6)
		antes[h.id] = h.baralho.baralho.size()
	for o in b.inimigos_vivos():   # 0.19: descanso só sem inimigos por perto
		if b.inimigo_perto(o.pos, 0) and Grade.distancia(o.pos, b.interacoes.filter(func(i): return i.get("descanso", false))[0]["pos"]) <= b.RAIO_DESCANSO_SEGURO:
			o.pos = Vector2i(-50, -50)
	t.ok(b.heroi_interagir("cabana", "descansar"), "descansa")
	for h in b.herois():
		t.igual(h.baralho.baralho.size(), antes[h.id] + 5, "%s descansou (exila 1, voltam 5)" % h.nome)


func test_poco_queda_de_4_quadrados(t) -> void:
	var b := _missao()
	b.interacao_atual = {"id": "poco", "opcao": "descer", "dano": 0, "vitoria": ""}
	b._resolver_interacao(4)
	t.igual(b.queda_pendente(), 4, "oferece amortecer")
	t.igual(b.opcao_de_amortecer(4)["dificuldade"], 19, "15 + 4")
	t.igual(Batalha.dano_de_queda(4), 9, "3 × 3")


func test_agua_nao_bloqueia_linha_de_visao(t) -> void:
	var b := _missao()
	t.ok(b.grade.linha_de_visao(Vector2i(8, 8), Vector2i(11, 8)), "dá para ver por cima do rio")
	t.ok(not b.grade.linha_de_visao(Vector2i(21, 12), Vector2i(23, 12)), "a rocha bloqueia")
