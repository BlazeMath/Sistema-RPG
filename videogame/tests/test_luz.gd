## 0.15: escuro e luz, devoções e tipos de dano, a cripta, Conjuração e a campanha.
extends RefCounted

const Batalha := preload("res://core/batalha.gd")
const Dados := preload("res://core/dados_batalha.gd")
const Masmorra := preload("res://core/dados_masmorra.gd")
const Devocoes := preload("res://core/devocoes.gd")
const TC := preload("res://tests/test_classes.gd")


func _arena_escura(classe := "Guerreiro") -> Batalha:
	var tc = TC.new()
	var f: Dictionary = tc._ficha(classe, "Testador", [], [])
	var cen := Dados.arena([f], false)
	cen["escuro"] = true
	var b := Batalha.new(cen, 3)
	b.iniciar()
	var u := b.unidade("heroi")
	u.pos = Vector2i(2, 5)
	for o in b.inimigos_vivos():
		o.pos = Vector2i(9, o.pos.y)
		o.visao_no_escuro = false
	b.indice_vez = b.ordem.find("heroi")
	b._comecar_turno()
	return b


func test_escuro_sem_luz(t) -> void:
	var b := _arena_escura()
	var u := b.unidade("heroi")
	var g = b.inimigos_vivos()[0]
	t.igual(b.nivel_de_luz(g.pos), 0, "breu")
	t.ok(not b.ve_de(u, u.pos, g.pos), "não enxerga o goblin longe")
	t.ok(not b.visivel(g.pos), "o goblin some na névoa")
	t.ok(b.ve_de(u, u.pos, u.pos + Vector2i(1, 0)), "ao lado sempre enxerga")


func test_lanterna_e_tocha(t) -> void:
	var b := _arena_escura()
	var u := b.unidade("heroi")
	t.ok(b.heroi_luz("lanterna"), "acende a lanterna")
	t.igual(b.nivel_de_luz(u.pos + Vector2i(4, 0)), 2, "claro a 4")
	t.igual(b.nivel_de_luz(u.pos + Vector2i(6, 0)), 0, "escuro a 6")
	b.heroi_luz("lanterna")
	t.igual(u.luz, "", "apaga")
	u.consumiveis.append("tocha")
	u.escudo = {"nome": "Sem escudo", "vida": 0, "resistencia": 0}
	t.ok(b.heroi_luz("tocha"), "acende a tocha (mão livre)")
	t.igual(b.nivel_de_luz(u.pos + Vector2i(6, 0)), 1, "penumbra a 6 com tocha")
	t.ok(not "tocha" in u.consumiveis, "a tocha foi gasta")


func test_tocha_precisa_de_mao_livre(t) -> void:
	var b := _arena_escura()
	var u := b.unidade("heroi")   # Guerreiro: espada e escudo
	u.consumiveis.append("tocha")
	t.igual(b.motivo_luz(u, "tocha"), "precisa de uma mão livre", "espada e escudo ocupam as mãos")


func test_visao_no_escuro_e_penumbra(t) -> void:
	var b := _arena_escura()
	var u := b.unidade("heroi")
	var g = b.inimigos_vivos()[0]
	u.visao_no_escuro = true
	t.ok(b.ve_de(u, u.pos, g.pos), "com visão no escuro, enxerga")
	t.igual(b.nivel_visto_por(u, g.pos), 1, "como penumbra")
	u.a_distancia = true
	t.igual(b.cobertura_de(u, g), 1, "atirar na penumbra: cobertura parcial")


func test_ataque_no_escuro_tem_desvantagem(t) -> void:
	var b := _arena_escura()
	var u := b.unidade("heroi")
	var g = b.inimigos_vivos()[0]
	g.pos = u.pos + Vector2i(1, 0)
	b.escuro = true
	# ao lado sempre enxerga: sem desvantagem
	t.ok(b.heroi_atacar(g), "ataca ao lado")
	t.ok(not b.teste_ataque.desvantagem, "ao lado não tem desvantagem")


func test_devocao_e_martelo(t) -> void:
	var b := TC.new()._grupo_com("Clérigo", "", "classe.clerigo.heroi.o-martelo-da-luz")
	var u := b.unidade("heroi")
	var g := b.unidade("goblin1")
	u.divindade = "martelo"
	t.ok(Devocoes.inimigo_da_devocao("martelo", g.categoria), "goblins são inimigos de Karrak")
	b._novo_ataque(u, g, {})
	var bonus := b._bonus_por_tipo(u, g, true)
	t.ok(bonus.any(func(x): return x[0].begins_with("O Martelo da Luz")), "+3 contra inimigo da devoção")
	u.efeitos["martelo_da_luz"] = {}
	t.ok("Trovão" in b.tipos_de_dano(u, {}), "a arma ganha o tipo da devoção")


func test_esqueleto_fraquezas(t) -> void:
	var b := TC.new()._grupo_com("Guerreiro", "", "classe.guerreiro.heroi.foco-mortal")
	var u := b.unidade("heroi")
	var g := b.unidade("goblin1")
	g.fraquezas = {"Concussão": 2}
	g.resiste_tipo = {"Corte": 2}
	b._novo_ataque(u, g, {})
	u.arma["tipo_dano"] = "Concussão"
	t.ok(b._bonus_por_tipo(u, g, true).any(func(x): return x[1] == 2), "maça contra esqueleto: +2")
	u.arma["tipo_dano"] = "Corte"
	t.ok(b._bonus_por_tipo(u, g, true).any(func(x): return x[1] == -2), "espada contra osso resistente: −2")


func test_cripta_monta(t) -> void:
	var tc = TC.new()
	var fichas := [tc._ficha("Guerreiro", "A", [], []), tc._ficha("Clérigo", "B", [], []), tc._ficha("Mago", "C", [], []), tc._ficha("Ladino", "D", [], [])]
	var b := Batalha.new(Masmorra.missao(fichas), 5)
	b.iniciar()
	t.ok(b.escuro, "a cripta é escura")
	t.ok(b.unidade("aldric") != null, "o chefe está lá")
	t.igual(b.unidade("aldric").categoria, "morto-vivo", "morto-vivo")
	t.ok(b.inimigos_vivos().filter(func(o): return o.grupo == "ossario").size() >= 7, "obstáculo de esqueletos (7 para 4)")
	t.igual(b.nivel_de_luz(Vector2i(4, 11)), 2, "a entrada é iluminada pelas tochas da parede")
	t.igual(b.nivel_de_luz(Vector2i(15, 12)), 0, "o ossário é breu")
	t.ok(b.grade.bloqueado(Vector2i(30, 11)), "a porta da cripta está fechada")


func test_rito_de_purificacao(t) -> void:
	var b := TC.new()._grupo_com("Clérigo", "classe.clerigo.voz-do-exorcista", "")
	var u := b.unidade("heroi")
	var c = u.cartas[u.cartas.size() - 1]
	if c.slug() != "rito-de-purificacao":
		c.lado = 1 - c.lado
	t.igual(c.slug(), "rito-de-purificacao", "lado certo")
	var g := b.unidade("goblin1")
	g.categoria = "morto-vivo"
	var vida := g.vida
	t.ok(b.heroi_usar_carta(u.cartas.size() - 1), "cria o rito")
	b._rito_no_turno(g)
	t.igual(vida - g.vida, 1, "1 de dano no morto-vivo")
	t.igual(g.fichas_total("Penalidade"), 1, "e 1 Penalidade")


func test_campanha_feridas(t) -> void:
	const Campanha := preload("res://core/campanha.gd")
	Campanha.dados = {"ouro": 30, "feridas": {"Testador": {"exilio": 3, "descarte": 5}}, "concluidas": []}
	var b := _arena_escura()
	var antes: int = b.unidade("heroi").baralho.baralho.size()
	Campanha.aplicar(b)
	var u := b.unidade("heroi")
	t.igual(u.baralho.exilio.size(), 3, "começa com o exílio da missão anterior")
	t.igual(u.baralho.descarte.size(), 0, "o descarte voltou ao baralho entre as missões")
	t.igual(u.baralho.baralho.size(), antes - 3, "só o exílio fica fora")
	t.igual(Campanha.custo_descanso(["Testador"]), Campanha.CUSTO_ESTALAGEM, "estalagem por herói")
	Campanha.dados = {}
