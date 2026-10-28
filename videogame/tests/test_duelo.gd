extends RefCounted

const Duelo := preload("res://core/duelo.gd")
const Dados := preload("res://core/dados_duelo.gd")
const Baralho := preload("res://core/baralho.gd")


## Joga um duelo inteiro com o herói puxando até 17 no ataque e defesa automática.
func _simular(semente: int) -> Duelo:
	var d := Duelo.new(Dados.HEROI.duplicate(), Dados.goblin(), semente)
	d.defesa_automatica = true
	d.iniciar()
	for passo in 2000:
		match d.fase:
			Duelo.Fase.VITORIA, Duelo.Fase.DERROTA:
				return d
			Duelo.Fase.HEROI_ESCOLHE:
				d.atacar()
			Duelo.Fase.HEROI_ATACANDO:
				if d.teste_ataque.soma_cartas() < 17:
					d.puxar()
				else:
					d.parar()
			Duelo.Fase.RESOLVIDO:
				d.continuar()
			_:
				d.passo_automatico()
	return d


func test_duelos_sempre_terminam_e_nao_perdem_cartas(t) -> void:
	var vitorias := 0
	var cartas_restantes := 0
	var rodadas := 0
	var n := 400
	for s in n:
		var d := _simular(s + 1)
		t.ok(d.fase == Duelo.Fase.VITORIA or d.fase == Duelo.Fase.DERROTA, "semente %d terminou" % (s + 1))
		t.igual(d.baralho_heroi.total_cartas(), 52, "cartas do herói conservadas (semente %d)" % (s + 1))
		if d.fase == Duelo.Fase.VITORIA:
			vitorias += 1
			cartas_restantes += d.baralho_heroi.baralho.size()
		rodadas += d.rodada
	print("  [balanceamento provisório] vitórias: %d%% · baralho restante médio nas vitórias: %.1f de 52 · rodadas médias: %.1f" % [
		vitorias * 100 / n, float(cartas_restantes) / maxi(vitorias, 1), float(rodadas) / n])


func test_ia_para_no_criterio(t) -> void:
	var d := Duelo.new(Dados.HEROI.duplicate(), Dados.goblin(), 42)
	d.iniciar()
	if d.fase == Duelo.Fase.HEROI_ESCOLHE:
		d.atacar()
		d.parar()
	# Agora a IA joga (defesa ou ataque, conforme a iniciativa).
	var teste = d.teste_defesa if d.fase == Duelo.Fase.IA_DEFENDENDO else d.teste_ataque
	var parada: int = d.inimigo["parada_defesa"] if d.fase == Duelo.Fase.IA_DEFENDENDO else d.inimigo["parada_ataque"]
	while d.passo_automatico():
		pass
	t.ok(teste.estourou or teste.soma_cartas() >= parada, "IA só para ao atingir o critério ou estourando")


func test_heroi_nao_age_fora_da_vez(t) -> void:
	var d := Duelo.new(Dados.HEROI.duplicate(), Dados.goblin(), 7)
	d.iniciar()
	if d.fase == Duelo.Fase.IA_ATACANDO:
		t.ok(not d.atacar(), "não ataca no turno do inimigo")
		t.ok(not d.puxar(), "não puxa enquanto a IA joga")
	else:
		t.ok(not d.puxar(), "não puxa antes de atacar")
		t.ok(not d.continuar(), "não continua sem resultado")
