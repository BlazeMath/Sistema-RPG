extends RefCounted

const Batalha := preload("res://core/batalha.gd")
const Dados := preload("res://core/dados_batalha.gd")
const Grade := preload("res://core/grade.gd")


## Herói simples: vai até o goblin mais próximo e ataca; puxa até 17; defesa automática.
func _simular(semente: int, cenario := {}) -> Batalha:
	var b := Batalha.new(cenario if not cenario.is_empty() else Dados.cenario(), semente)
	b.defesa_automatica = true
	b.iniciar()
	for passo in 5000:
		match b.fase:
			Batalha.Fase.VITORIA, Batalha.Fase.DERROTA:
				return b
			Batalha.Fase.HEROI_ESCOLHE:
				_turno_heroi(b)
			Batalha.Fase.HEROI_ATACANDO:
				if b.teste_ataque.soma_cartas() < 17:
					b.puxar()
				else:
					b.parar()
			Batalha.Fase.RESOLVIDO:
				b.continuar()
			_:
				b.passo_automatico()
	return b


func _turno_heroi(b: Batalha) -> void:
	var u := b.ativa()
	var alvos := b.inimigos_vivos()
	alvos.sort_custom(func(x, y): return Grade.distancia(u.pos, x.pos) < Grade.distancia(u.pos, y.pos))
	var alvo = alvos[0]
	if b.heroi_atacar(alvo):
		return
	var info := b.alcance_movimento(u)
	var melhor := u.pos
	for p in info["mapa"]:
		if Grade.distancia(p, alvo.pos) < Grade.distancia(melhor, alvo.pos):
			melhor = p
	if melhor != u.pos and b.heroi_mover(melhor):
		return
	b.encerrar_turno()


func test_batalhas_terminam_e_conservam_cartas(t) -> void:
	var vitorias := 0
	var rodadas := 0
	var restante := 0
	var n := 300
	for s in n:
		var b := _simular(s + 1)
		t.ok(b.fase == Batalha.Fase.VITORIA or b.fase == Batalha.Fase.DERROTA, "semente %d terminou (fase %d)" % [s + 1, b.fase])
		t.igual(b.unidade("heroi").baralho.total_cartas(), 52, "cartas conservadas (semente %d)" % (s + 1))
		rodadas += b.rodada
		if b.fase == Batalha.Fase.VITORIA:
			vitorias += 1
			restante += b.unidade("heroi").baralho.baralho.size()
	print("  [arena, herói padrão] vitórias: %d%% · baralho restante médio nas vitórias: %.1f · rodadas médias: %.1f" % [
		vitorias * 100 / n, float(restante) / maxi(vitorias, 1), float(rodadas) / n])


func test_movimento_gasta_acao_e_impede(t) -> void:
	var b := Batalha.new(Dados.cenario(), 3)
	b.iniciar()
	# Força a vez do herói para testar o movimento.
	b.indice_vez = b.ordem.find("heroi")
	b._comecar_turno()
	var u := b.ativa()
	t.ok(b.heroi_mover(Vector2i(3, 5)), "andou 2")
	t.igual(u.acoes_mov, 0, "gastou a ação de movimento")
	t.igual(u.deslocamento, 1, "sobrou 1 de deslocamento")
	t.ok(b.heroi_mover(Vector2i(4, 5)), "usou o que sobrou")
	t.igual(u.acoes_padrao, 2, "não gastou padrão")
	t.ok(b.heroi_mover(Vector2i(6, 5)), "rebaixou uma padrão para mover")
	t.igual(u.acoes_padrao, 1, "padrão rebaixada")
	# Coloca um goblin ao lado e confere o impedimento.
	var g := b.unidade("goblin1")
	g.pos = Vector2i(8, 5)
	u.deslocamento = 3
	t.ok(b.heroi_mover(Vector2i(7, 5)), "ficou adjacente")
	t.igual(u.deslocamento, 0, "impedido: deslocamento zerou")
	t.ok(b.impedido(u), "está impedido")
	var info := b.alcance_movimento(u)
	for p in info["mapa"]:
		t.igual(Grade.distancia(p, u.pos), 1, "impedido só anda 1 quadrado")


func test_ataque_corpo_a_corpo_exige_adjacencia(t) -> void:
	var b := Batalha.new(Dados.cenario(), 3)
	b.iniciar()
	b.indice_vez = b.ordem.find("heroi")
	b._comecar_turno()
	var g := b.unidade("goblin1")
	t.ok(not b.heroi_atacar(g), "longe demais")
	g.pos = Vector2i(2, 6)
	g.pos = Vector2i(2, 6)
	t.ok(b.heroi_atacar(g), "adjacente na diagonal")
	t.igual(b.fase, Batalha.Fase.HEROI_ATACANDO, "mesa de 21 aberta")


func test_x1_termina(t) -> void:
	var vitorias := 0
	var n := 200
	var restante := 0
	for s in n:
		var b := _simular(s + 1, Dados.x1(preload("res://core/personagem.gd").nova()))
		t.ok(b.fase == Batalha.Fase.VITORIA or b.fase == Batalha.Fase.DERROTA, "x1 semente %d terminou" % (s + 1))
		if b.fase == Batalha.Fase.VITORIA:
			vitorias += 1
			restante += b.unidade("heroi").baralho.baralho.size()
	print("  [X1 contra o Chefe Goblin, herói padrão] vitórias: %d%% · baralho restante médio: %.1f" % [vitorias * 100 / n, float(restante) / maxi(vitorias, 1)])
