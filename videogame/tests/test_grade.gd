extends RefCounted

const Grade := preload("res://core/grade.gd")


func test_distancia_e_adjacencia(t) -> void:
	t.igual(Grade.distancia(Vector2i(0, 0), Vector2i(3, 2)), 3, "maior diferença")
	t.ok(Grade.adjacentes(Vector2i(2, 2), Vector2i(3, 3)), "diagonal é adjacente")
	t.ok(not Grade.adjacentes(Vector2i(2, 2), Vector2i(4, 2)), "a 2 quadrados não é")


func test_alcance_com_velocidade_3(t) -> void:
	var g := Grade.new(10, 10)
	var mapa := g.alcance(Vector2i(5, 5), 3, {}, {})
	t.ok(mapa.has(Vector2i(8, 8)), "3 passos em diagonal")
	t.ok(not mapa.has(Vector2i(9, 5)), "4 passos não")
	t.igual(mapa.size(), 49, "quadrado 7x7")


func test_obstaculo_bloqueia_e_nao_corta_canto(t) -> void:
	var g := Grade.new(5, 5)
	g.obstaculos[Vector2i(1, 0)] = "pedra"
	var mapa := g.alcance(Vector2i(0, 0), 1, {}, {})
	t.ok(not mapa.has(Vector2i(1, 0)), "não entra no obstáculo")
	t.ok(not mapa.has(Vector2i(1, 1)), "não corta o canto do obstáculo")
	t.ok(mapa.has(Vector2i(0, 1)), "reta livre")


func test_impedimento_para_o_movimento(t) -> void:
	var g := Grade.new(10, 10)
	var inimigo := Vector2i(5, 2)
	var perigos := {}
	for d in Grade.DIRECOES:
		perigos[inimigo + d] = true
	var mapa := g.alcance(Vector2i(5, 5), 3, {inimigo: true}, perigos)
	t.ok(mapa.has(Vector2i(5, 3)), "pode chegar ao lado do inimigo")
	t.ok(not mapa.has(Vector2i(5, 2)), "não entra no quadrado do inimigo")
	var continuou := false
	for p in mapa:
		var anterior: Vector2i = mapa[p]["anterior"]
		if anterior != Vector2i(5, 5) and perigos.has(anterior):
			continuou = true
	t.ok(not continuou, "nenhum caminho continua depois de ficar adjacente ao inimigo")


func test_caminho(t) -> void:
	var g := Grade.new(10, 10)
	var mapa := g.alcance(Vector2i(0, 0), 3, {}, {})
	var c := Grade.caminho(mapa, Vector2i(3, 0))
	t.igual(c.size(), 3, "3 passos")
	t.igual(c[-1], Vector2i(3, 0), "termina no destino")


func test_linha_de_visao(t) -> void:
	var g := Grade.new(10, 10)
	g.obstaculos[Vector2i(3, 3)] = "pedra"
	t.ok(not g.linha_de_visao(Vector2i(1, 1), Vector2i(5, 5)), "pedra no meio bloqueia")
	t.ok(g.linha_de_visao(Vector2i(1, 1), Vector2i(1, 6)), "linha livre")
