extends RefCounted

const Combate := preload("res://core/combate.gd")
const Iniciativa := preload("res://core/iniciativa.gd")


func test_dano_pela_formula(t) -> void:
	# Ataque 20 contra defesa 15, arma 4, Força 3, resistência 2 -> 5 + 4 + 3 - 2 = 10.
	t.igual(Combate.calcular_dano(20, 15, 4, 3, 2), 10, "fórmula")


func test_empate_erra(t) -> void:
	t.igual(Combate.calcular_dano(15, 15, 6, 3, 0), 0, "empate não acerta")


func test_resistencia_nao_cura(t) -> void:
	t.igual(Combate.calcular_dano(16, 15, 0, 0, 10), 0, "dano mínimo 0")


func test_faixas_de_distancia(t) -> void:
	t.igual(Combate.faixa(4), Combate.Faixa.CURTO, "4 é curto")
	t.igual(Combate.faixa(5), Combate.Faixa.MEDIO, "5 é médio")
	t.igual(Combate.faixa(8), Combate.Faixa.MEDIO, "8 é médio")
	t.igual(Combate.faixa(12), Combate.Faixa.LONGO, "12 é longo")
	t.igual(Combate.faixa(13), Combate.Faixa.FORA, "13 está fora")


func test_iniciativa_ordena_todos(t) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var ordem := Iniciativa.ordenar([
		{"id": "guerreiro", "destreza": 1, "iniciativa": 0},
		{"id": "ladino", "destreza": 3, "iniciativa": 2},
		{"id": "goblin", "destreza": 2, "iniciativa": 1},
	], rng)
	t.igual(ordem.size(), 3, "todos na ordem")
	t.ok("ladino" in ordem and "goblin" in ordem and "guerreiro" in ordem, "ids preservados")


func test_iniciativa_favorece_modificador_alto(t) -> void:
	# Em 2000 cenas, quem tem +8 deve agir antes de quem tem +0 na maioria das vezes.
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var primeiro_rapido := 0
	for i in 2000:
		var ordem := Iniciativa.ordenar([
			{"id": "lento", "destreza": 0, "iniciativa": 0},
			{"id": "rapido", "destreza": 5, "iniciativa": 3},
		], rng)
		if ordem[0] == "rapido":
			primeiro_rapido += 1
	t.ok(primeiro_rapido > 1400, "rápido age primeiro em %d de 2000" % primeiro_rapido)


func test_simulacao_de_iniciativa_fica_na_faixa(t) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 500:
		var v := Iniciativa.simular_teste(4, rng)
		t.ok(v >= 8 and v <= 25, "valor %d dentro de 8..25 (duas cartas + 4)" % v)
