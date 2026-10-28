## 0.23: levantar caídos, armadilhas, salas, níveis, chefes, catacumbas, vila, cartas novas.
extends RefCounted

const Batalha := preload("res://core/batalha.gd")
const Grade := preload("res://core/grade.gd")
const TC := preload("res://tests/test_classes.gd")
const Baralho := preload("res://core/baralho.gd")


func _b() -> Batalha:
	return TC.new()._grupo_com("Guerreiro", "", "classe.guerreiro.heroi.foco-mortal")


func test_dificuldade_de_levantar(t) -> void:
	t.igual(Batalha.dificuldade_de_levantar(40), 17, "40+ no descarte: 17")
	t.igual(Batalha.dificuldade_de_levantar(37), 18, "35-39: 18")
	t.igual(Batalha.dificuldade_de_levantar(30), 19, "30-34: 19")
	t.igual(Batalha.dificuldade_de_levantar(3), 25, "0-4: 25")


func test_levantar_volta_com_20_por_cento_mais_cura(t) -> void:
	var b := _b()
	var h2 := b.unidade("heroi2")
	h2.baralho.sofrer_dano(h2.baralho.baralho.size())
	t.igual(h2.baralho.estado, Baralho.Estado.INCONSCIENTE, "caiu")
	var desc := h2.baralho.descarte.size()
	b.interacao_atual = {"alvo": h2.id}
	b._efeito_levantar(h2, 3)
	t.igual(h2.baralho.estado, Baralho.Estado.ATIVO, "de pé")
	t.igual(h2.baralho.baralho.size(), int(desc * 0.2) + 3, "20% do descarte + 3 da cura")
	t.ok(b.alvos_de_levantar(b.unidade("heroi")).is_empty(), "já não é alvo")


func test_diagonal_entre_dois_aliados(t) -> void:
	var b := _b()
	var u := b.unidade("heroi")
	for o in b.inimigos_vivos():
		o.pos = Vector2i(11, b.inimigos_vivos().find(o) + 1)
	u.pos = Vector2i(2, 2)
	b.unidade("heroi2").pos = Vector2i(3, 2)
	var mapa: Dictionary = b.alcance_movimento(u)["mapa"]
	t.ok(mapa.has(Vector2i(3, 3)) or b.grade.bloqueado(Vector2i(3, 3)), "passa na diagonal ao lado de aliado")


func test_niveis_e_escada(t) -> void:
	var g := Grade.new(6, 3)
	g.niveis[Vector2i(3, 1)] = 1
	g.niveis[Vector2i(4, 1)] = 1
	t.ok(not g.vizinhos(Vector2i(2, 1)).has(Vector2i(3, 1)), "sem escada não sobe")
	g.escadas[Vector2i(2, 1)] = true
	t.ok(g.vizinhos(Vector2i(2, 1)).has(Vector2i(3, 1)), "pela escada sobe")
	t.ok(g.vizinhos(Vector2i(1, 1), false, true).has(Vector2i(1, 0)), "escalando ignora")


func test_catacumbas_monta(t) -> void:
	var C := preload("res://core/dados_catacumbas.gd")
	var cen := C.missao(TC.new()._ficha("Guerreiro", "T", [], ["classe.guerreiro.heroi.foco-mortal"]))
	t.ok(C.salas().size() >= 10, "pelo menos 10 salas")
	var b := Batalha.new(cen, 3)
	b.iniciar()
	t.ok(b.armadilhas.size() >= 5, "várias armadilhas")
	t.ok(b.grade.nivel(Vector2i(24, 12)) == 1, "braço do salão no alto")
	var it := b.interacao("descanso_galeria")
	var op: Dictionary = it["opcoes"][0]
	t.ok(b.motivo_sem_opcao(b.ativa(), it, op) != "", "descanso trancado no começo")
	t.ok(b.eventos.any(func(e): return e["tipo"] == "narrativa"), "texto de abertura")


func test_gatilho_e_armadilha(t) -> void:
	var C := preload("res://core/dados_catacumbas.gd")
	var b := Batalha.new(C.missao(TC.new()._ficha("Guerreiro", "T", [], ["classe.guerreiro.heroi.foco-mortal"])), 3)
	b.perguntar_escolhas = false
	b.iniciar()
	b.indice_vez = b.ordem.find("heroi")
	b._comecar_turno()
	var u := b.unidade("heroi")
	u.pos = Vector2i(7, 15)
	t.ok(b._casa_do_heroi(u, Vector2i(8, 15)), "entrar no corredor para e conta a sala")
	t.ok(b.gatilhos_feitos.has("g_corredor"), "gatilho feito")
	t.ok(not b._casa_do_heroi(u, Vector2i(9, 15)), "só uma vez")
	t.ok(b._casa_do_heroi(u, Vector2i(10, 15)), "placa de pressão dispara")
	t.igual(b.fase, Batalha.Fase.INTERACAO_TESTE, "teste para escapar")


func test_revelar_armadilha(t) -> void:
	var C := preload("res://core/dados_catacumbas.gd")
	var b := Batalha.new(C.missao(TC.new()._ficha("Guerreiro", "T", [], ["classe.guerreiro.heroi.foco-mortal"])), 3)
	b.iniciar()
	t.ok(b._revelar_armadilha("dardos") != "", "revelada")
	t.ok(b.casas_de_armadilha().has(Vector2i(10, 15)), "aparece no mapa")
	t.ok(b.interacao("armadilha_dardos").size() > 0, "vira interação de desarmar")
	b._desarmar_armadilha("dardos")
	t.ok(b.casas_de_armadilha().is_empty(), "desarmada some")


func test_chefe_em_guarda_e_protegido(t) -> void:
	var b := _b()
	var g := b.unidade("goblin2")
	g.habilidades = [{"tipo": "defensivo", "regen": 5}]
	g.protegido_por = ["goblin3"]
	b._aplicar_dano_inimigo(g, 10)
	t.igual(g.vida, g.vida_max - 5, "protegido: metade")
	g.efeitos["turnos_ia"] = {"n": 1}
	t.ok(b._ia_habilidades(g), "turno par: fica em guarda e não ataca")
	t.ok(g.efeitos.has("postura_defensiva"), "em guarda")


func test_ovo_choca(t) -> void:
	var b := _b()
	var g := b.unidade("goblin2")
	g.alerta = true
	g.habilidades = [{"tipo": "ovo", "a_cada": 2}]
	var antes := b.unidades.size()
	b._ia_habilidades(g)
	t.igual(b.unidades.size(), antes + 1, "pôs um ovo")
	var ovo = b.unidades[-1]
	t.ok(b.interacoes.any(func(it): return it.get("unidade", "") == ovo.id), "o ovo tem interação")
	g.efeitos.erase("hab_turno")
	b._ia_habilidades(g)
	t.ok(not ovo.viva(), "chocou")
	t.ok(b.unidades.any(func(o): return o.nome == "Cria do Pântano" and o.viva()), "nasceu a cria")


func test_marca_e_golpe(t) -> void:
	var b := _b()
	var g := b.unidade("goblin2")
	g.alerta = true
	g.habilidades = [{"tipo": "marcar_area", "nome": "Golpe", "raio": 1, "dano": 4, "a_cada": 1}]
	b._ia_habilidades(g)
	t.ok(b.zonas.any(func(z): return z["tipo"] == "marca"), "marca no mapa")
	var alvo := b._escolher_alvo(g)
	var antes := alvo.baralho.baralho.size()
	g.efeitos.erase("hab_turno")
	b._ia_habilidades(g)
	t.ok(alvo.baralho.baralho.size() < antes, "quem ficou na marca sofre")


func test_escolta_espera_o_lider(t) -> void:
	var b := _b()
	var l := b.unidade("goblin2")
	var e := b.unidade("goblin3")
	e.escolta = l.id
	e.alerta = true
	t.ok(b._ia_escolta(e), "líder ainda não lutou: fica para trás")
	l.efeitos["engajou"] = {}
	t.ok(not b._ia_escolta(e), "depois, luta normalmente")


func test_vila_monta(t) -> void:
	var V := preload("res://core/dados_vila.gd")
	var b := Batalha.new(V.cenario(TC.new()._ficha("Guerreiro", "T", [], ["classe.guerreiro.heroi.foco-mortal"])), 3)
	b.iniciar()
	t.ok(b.exploracao_livre, "anda livre")
	t.ok(b.ativa().deslocamento >= 30, "deslocamento sem fim")
	t.ok(b.interacao("mural").size() > 0, "mural da guilda")
	t.igual(b.motivo_salvar(), "", "salva em qualquer lugar")
	t.ok(b.fase != Batalha.Fase.VITORIA, "sem vitória automática")


func test_cartas_novas_registradas(t) -> void:
	var b := _b()
	var Extras := preload("res://core/cartas_extras.gd")
	for s in ["finta", "olha-la", "hino-de-coragem", "estudar-a-presa", "servo-sombrio"]:
		t.ok(Extras.LADOS.has(s), s)
	var u := b.unidade("heroi")
	u.efeitos["finta"] = {}
	b._novo_ataque(u, b.unidade("goblin1"), {})
	t.ok(b.teste_ataque.vantagem, "Finta dá vantagem")


func test_diagonal_entre_dois_aliados_de_verdade(t) -> void:
	var f := TC.new()._ficha("Guerreiro", "T", [], ["classe.guerreiro.heroi.foco-mortal"])
	var Dados := preload("res://core/dados_batalha.gd")
	var b := Batalha.new(Dados.arena([f, f.duplicate(true), f.duplicate(true)], false), 3)
	b.iniciar()
	for o in b.inimigos_vivos():
		o.pos = Vector2i(11, b.inimigos_vivos().find(o) + 1)
	b.indice_vez = b.ordem.find("heroi")
	b._comecar_turno()
	var u := b.unidade("heroi")
	u.pos = Vector2i(2, 2)
	b.unidade("heroi2").pos = Vector2i(3, 2)
	b.unidade("heroi3").pos = Vector2i(2, 3)
	var mapa: Dictionary = b.alcance_movimento(u)["mapa"]
	t.ok(mapa.has(Vector2i(3, 3)), "diagonal entre dois aliados: " + str(mapa.get(Vector2i(3, 3), "fora")))
	t.ok(b.heroi_mover(Vector2i(3, 3)), "e anda")
