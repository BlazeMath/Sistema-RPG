## Áreas e zonas (0.11).
extends RefCounted

const Batalha := preload("res://core/batalha.gd")
const Areas := preload("res://core/areas.gd")
const Grade := preload("res://core/grade.gd")
const TC := preload("res://tests/test_classes.gd")


func _b(classe := "Guerreiro", carta := "") -> Batalha:
	var b: Batalha = TC.new()._grupo_com(classe, carta, "classe.guerreiro.heroi.foco-mortal")
	return b


func test_formas(t) -> void:
	var g := Grade.new(12, 10)
	t.igual(Areas.celulas({"forma": "quadrado", "tamanho": 3}, Vector2i(0, 0), Vector2i(5, 5), 0, g).size(), 9, "3x3")
	var r0 := Areas.celulas({"forma": "quadrado", "tamanho": 2}, Vector2i(0, 0), Vector2i(5, 5), 0, g)
	var r2 := Areas.celulas({"forma": "quadrado", "tamanho": 2}, Vector2i(0, 0), Vector2i(5, 5), 2, g)
	t.ok(r0 != r2 and r0.size() == 4, "2x2 gira")
	g.obstaculos[Vector2i(4, 2)] = "rocha"
	var linha := Areas.celulas({"forma": "linha", "comprimento": 4}, Vector2i(1, 2), Vector2i(3, 2), 0, g)
	t.igual(linha, [Vector2i(2, 2), Vector2i(3, 2)], "a linha para na parede")
	var adj := Areas.celulas({"forma": "adjacente", "tamanho": 3}, Vector2i(5, 5), Vector2i(8, 5), 0, g)
	t.ok(Vector2i(6, 4) in adj and Vector2i(8, 6) in adj and not Vector2i(5, 5) in adj, "3x3 colada, para a direita")


func test_ataque_em_area_um_teste_varias_defesas(t) -> void:
	var b := _b("Mago", "classe.mago.aprendiz-de-fogo")
	var u := b.unidade("heroi")
	var i := u.cartas.size() - 1
	if u.cartas[i].slug() != "labareda-voraz":
		u.cartas[i].lado = 1 - u.cartas[i].lado
	t.igual(u.cartas[i].slug(), "labareda-voraz", "Labareda Voraz")
	b.unidade("goblin1").pos = u.pos + Vector2i(1, 0)
	b.unidade("goblin2").pos = u.pos + Vector2i(3, 0)
	b.unidade("goblin3").pos = Vector2i(11, 9)
	b.unidade("heroi2").pos = u.pos + Vector2i(2, 0)
	t.ok(b.heroi_usar_area(i, u.pos + Vector2i(1, 0)), "usa na linha")
	var defensores := {}
	var ataque := -1
	for passo in 60:
		if b.fase in [Batalha.Fase.IA_DEFENDENDO, Batalha.Fase.HEROI_DEFENDENDO]:
			defensores[b.defensor.id] = true
		if b.fase == Batalha.Fase.RESOLVIDO:
			if ataque < 0:
				ataque = b.resultado["ataque"]
			t.igual(b.resultado["ataque"], ataque, "o mesmo teste de ataque")
			b.continuar()
		elif b.fase == Batalha.Fase.HEROI_ATACANDO:
			b.parar()
		elif b.fase == Batalha.Fase.PERGUNTA:
			b.heroi_responder("nao")
		elif b.fase_automatica():
			b.passo_automatico()
		elif b.fase == Batalha.Fase.HEROI_DEFENDENDO:
			b.parar()
		elif b.fase == Batalha.Fase.DISTRIBUINDO_DANO:
			var s := b.sugestao_distribuicao()
			b.heroi_distribuir_dano(s["escudo"], s["armadura"])
		else:
			break
	t.igual(defensores.size(), 3, "dois goblins e o aliado defendem (a área acerta aliados)")


func test_zonas_iguais_nao_somam(t) -> void:
	var b := _b()
	var u := b.unidade("heroi")
	var cels := Areas.celulas({"forma": "quadrado", "tamanho": 3}, u.pos, u.pos, 0, b.grade)
	var op := {"teste": {"atributo": "forca"}, "dificuldade": 10}
	var sem := b.limite_do_teste(u, op)
	b.criar_zona("louvor", "Terra do Louvor", cels, u, {"rodadas": -1})
	b.criar_zona("louvor", "Terra do Louvor", cels, b.unidade("heroi2"), {"rodadas": -1})
	t.igual(b.limite_do_teste(u, op), sem + 1, "duas iguais: +1 só")


func test_zona_de_magia_some_com_o_conjurador(t) -> void:
	var b := _b()
	var u := b.unidade("heroi")
	var h2 := b.unidade("heroi2")
	b.criar_zona("conduite", "Halo", [u.pos], h2)
	b.criar_zona("fumaca", "Fumaça", [u.pos], null, {"vinculada": false})
	h2.baralho.sofrer_dano(60)
	b._limpar_zonas_de_caidos()
	t.igual(b.zonas.size(), 1, "a do conjurador caído some; a do item fica")
	t.igual(b.zonas[0]["tipo"], "fumaca", "a fumaça continua")


func test_terreno_dificil_e_piche(t) -> void:
	var b := _b()
	var u := b.unidade("heroi")
	for o in b.inimigos_vivos():
		o.pos = Vector2i(11, b.inimigos_vivos().find(o))
	b.unidade("heroi2").pos = Vector2i(0, 9)
	u.pos = Vector2i(3, 5)
	u.destreza = 0
	var cels := []
	for y in range(3, 8):
		cels.append(Vector2i(4, y))
	b.criar_zona("piche", "Piche", cels, null, {"vinculada": false, "terreno_dificil": true})
	var mapa: Dictionary = b.alcance_movimento(u)["mapa"]
	t.igual(int(mapa[Vector2i(4, 5)]["custo"]), 2, "terreno difícil vale 2")
	t.ok(b.heroi_mover(Vector2i(4, 5)), "entra no piche")
	t.igual(u.fichas_total("Imobilizar"), 1, "quem entra no piche ganha Imobilizar")


func test_armadilha_pega_inimigo(t) -> void:
	var b := _b()
	var g := b.unidade("goblin1")
	b.criar_zona("armadilha", "Armadilha", [g.pos + Vector2i(-1, 0)], b.unidade("heroi"), {"rodadas": -1, "vinculada": false})
	var vida := g.vida
	b._percorrer(g, [g.pos + Vector2i(-1, 0)], false)
	t.igual(g.vida, vida - 6, "6 de dano")
	t.igual(g.fichas_total("Imobilizar"), 1, "e Imobilizar")
	t.ok(b.zonas.is_empty(), "a armadilha dispara uma vez")


func test_fumaca_da_cobertura(t) -> void:
	var b := _b()
	var a := b.unidade("goblin3")
	var h := b.unidade("heroi")
	a.pos = Vector2i(11, 5)
	b.criar_zona("fumaca", "Fumaça", Areas.celulas({"forma": "quadrado", "tamanho": 3}, h.pos, h.pos, 0, b.grade), null, {"vinculada": false, "cobertura": 1})
	t.igual(b.cobertura_de(a, h), 1, "dentro da fumaça: cobertura parcial")


func test_sustentar_paga_ou_some(t) -> void:
	var b := _b("Clérigo", "classe.clerigo.zona-da-penitencia")
	var u := b.unidade("heroi")
	var i := u.cartas.size() - 1
	if u.cartas[i].slug() != "zona-da-penitencia":
		u.cartas[i].lado = 1 - u.cartas[i].lado
	t.ok(b.heroi_usar_area(i, u.pos + Vector2i(1, 0)), "cria a zona")
	t.igual(b.zonas.size(), 1, "zona no mapa")
	var c = u.cartas[i]
	var f: int = c.fadiga
	b.rodada += 1
	b._comecar_turno()
	t.igual(c.fadiga, f + 1, "no início do turno paga 1 para sustentar")
	for outra in u.cartas:
		outra.fadiga = outra.limite() + (1 if outra.slug() == "simbolo-sagrado" else 0)   # Conjuração: todas cheias (o Símbolo tira 1 no início do turno)
	b.rodada += 1
	b._comecar_turno()
	t.ok(b.zonas.is_empty(), "sem poder pagar, a zona some")


func test_penitencia_dobra_magia(t) -> void:
	var b := _b("Clérigo", "")
	var u := b.unidade("heroi")
	var g := b.unidade("goblin1")
	b.criar_zona("penitencia", "Penitência", [g.pos], u, {"rodadas": -1})
	b._novo_ataque(u, g, {"magico": true})
	b.teste_ataque.resultado_forcado = 20
	b.teste_ataque.parar()
	b.teste_defesa.resultado_forcado = 15
	b.teste_defesa.parar()
	b._resolver()
	t.ok(b.resultado["partes"].any(func(p): return str(p[0]).contains("Penitência")), "o dano da divindade dobra na zona")


func test_inimigo_evita_piche_se_nao_alcanca(t) -> void:
	var b := _b()
	var g := b.unidade("goblin2")
	for o in b.herois():
		o.pos = Vector2i(0, b.herois().find(o))
	g.pos = Vector2i(10, 5)
	var cels := []
	for y in range(0, 10):
		cels.append(Vector2i(9, y))
	cels.erase(Vector2i(9, 9))
	b.criar_zona("piche", "Piche", cels, b.unidade("heroi"), {"vinculada": false, "terreno_dificil": true})
	g.novo_turno()
	g.alerta = true
	b._ia_andar(g, func(p): return -Grade.distancia(p, Vector2i(0, 0)), false, b.unidade("heroi"))
	t.ok(not g.pos in cels, "não pisa no piche quando não alcança o alvo de qualquer jeito")


func test_nevoa_de_guerra(t) -> void:
	var b := _b()
	var h := b.unidade("heroi")
	var g := b.unidade("goblin1")
	t.ok(b.unidade_visivel(g), "goblin à vista")
	b.grade.obstaculos[h.pos + Vector2i(1, 0)] = "rocha"
	b.grade.obstaculos[h.pos + Vector2i(1, 1)] = "rocha"
	b.grade.obstaculos[h.pos + Vector2i(1, -1)] = "rocha"
	b.unidade("heroi2").pos = h.pos + Vector2i(-1, 0)
	g.pos = h.pos + Vector2i(3, 0)
	b.unidade("heroi2").baralho.sofrer_dano(60)
	t.ok(not b.unidade_visivel(g), "atrás das rochas, fora da vista")
	t.ok(b.explorado.has(h.pos), "onde o grupo esteve fica explorado")
