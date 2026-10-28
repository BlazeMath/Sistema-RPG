## Ferramenta de desenvolvimento: abre o duelo, joga alguns lances e salva
## capturas de tela em user://capturas/. Precisa de uma tela (real ou virtual):
##   xvfb-run godot --path . --rendering-driver opengl3 -s res://tools/capturar_telas.gd
extends SceneTree

const Duelo := preload("res://core/duelo.gd")

var tela
var pasta := ""


func _init() -> void:
	pasta = OS.get_environment("CAPTURAS")
	if pasta == "":
		pasta = "user://capturas"
	DirAccess.make_dir_recursive_absolute(pasta)
	_rodar.call_deferred()


func _esperar(seg: float) -> void:
	await create_timer(seg).timeout


func _foto(nome: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	img.save_png(pasta.path_join(nome + ".png"))
	print("captura: ", nome)


func _ate(fases: Array, limite := 40) -> void:
	for i in limite:
		if tela.duelo.fase in fases and not tela._ocupado:
			return
		if tela.duelo.fase == Duelo.Fase.RESOLVIDO and not (Duelo.Fase.RESOLVIDO in fases):
			tela._acao("continuar")
		elif tela.duelo.fase == Duelo.Fase.HEROI_ESCOLHE and not (Duelo.Fase.HEROI_ESCOLHE in fases):
			tela._acao("atacar")
		elif tela.duelo.fase in [Duelo.Fase.HEROI_ATACANDO, Duelo.Fase.HEROI_DEFENDENDO] and not (tela.duelo.fase in fases):
			tela._acao("parar")
		await _esperar(0.7)


func _rodar() -> void:
	root.size = Vector2i(1280, 720)
	tela = load("res://ui/main.tscn").instantiate()
	root.add_child(tela)
	await _esperar(0.3)
	tela.novo_combate(int(OS.get_environment("SEMENTE")) if OS.get_environment("SEMENTE") != "" else 1234)
	await _ate([Duelo.Fase.HEROI_ESCOLHE])
	await _foto("1_inicio_turno")
	tela._acao("atacar")
	await _esperar(0.4)
	# Clica de verdade no monte do herói (testa a entrada de mouse).
	var monte: Control = tela._monte_her
	var alvo := monte.get_global_rect().get_center()
	var antes: int = tela.duelo.teste_ataque.cartas.size()
	var mov := InputEventMouseMotion.new()
	mov.position = alvo
	root.push_input(mov)
	await _esperar(0.2)
	for apertado in [true, false]:
		var clique := InputEventMouseButton.new()
		clique.position = alvo
		clique.button_index = MOUSE_BUTTON_LEFT
		clique.pressed = apertado
		root.push_input(clique)
		await process_frame
	await _esperar(0.4)
	print("clique no monte puxou carta: ", tela.duelo.teste_ataque.cartas.size() > antes or tela.duelo.teste_ataque.estourou)
	root.push_input(mov)
	await _esperar(0.3)
	await _foto("2_atacando")
	tela._acao("parar")
	await _ate([Duelo.Fase.RESOLVIDO, Duelo.Fase.VITORIA, Duelo.Fase.DERROTA])
	await _foto("3_resultado")
	await _ate([Duelo.Fase.HEROI_DEFENDENDO, Duelo.Fase.VITORIA, Duelo.Fase.DERROTA])
	await _foto("4_defendendo")
	await _ate([Duelo.Fase.VITORIA, Duelo.Fase.DERROTA], 200)
	await _foto("5_fim")
	quit()
