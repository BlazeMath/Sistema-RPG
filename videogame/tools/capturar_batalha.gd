## Ferramenta de desenvolvimento: abre a batalha, joga alguns lances com cliques
## de verdade e salva capturas. Uso:
##   CAPTURAS=/pasta xvfb-run godot --path . --rendering-driver opengl3 -s res://tools/capturar_batalha.gd
extends SceneTree

const Batalha := preload("res://core/batalha.gd")
const Grade := preload("res://core/grade.gd")

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
	root.get_texture().get_image().save_png(pasta.path_join(nome + ".png"))
	print("captura: ", nome)


func _clicar(celula: Vector2i) -> void:
	var cam: Camera3D = tela._camera
	var ponto := cam.unproject_position(Vector3(celula.x, 0, celula.y))
	var mov := InputEventMouseMotion.new()
	mov.position = ponto
	root.push_input(mov)
	await process_frame
	for apertado in [true, false]:
		var c := InputEventMouseButton.new()
		c.position = ponto
		c.button_index = MOUSE_BUTTON_LEFT
		c.pressed = apertado
		root.push_input(c)
		await process_frame


func _passar_mouse(celula: Vector2i) -> void:
	var mov := InputEventMouseMotion.new()
	mov.position = tela._camera.unproject_position(Vector3(celula.x, 0, celula.y))
	root.push_input(mov)
	await _esperar(0.2)


func _ate_vez_do_heroi(limite := 80) -> void:
	for i in limite:
		var b = tela.batalha
		if b.vez_do_heroi() and not tela._ocupado:
			return
		if b.fase in [Batalha.Fase.VITORIA, Batalha.Fase.DERROTA]:
			return
		if not tela._ocupado:
			if b.fase == Batalha.Fase.DISTRIBUINDO_DANO:
				tela._confirmar_distribuicao()
			elif b.fase == Batalha.Fase.RESOLVIDO:
				tela._acao("continuar")
			elif b.fase in [Batalha.Fase.HEROI_ATACANDO, Batalha.Fase.HEROI_DEFENDENDO]:
				tela._acao("parar")
		await _esperar(0.5)


func _rodar() -> void:
	root.size = Vector2i(1280, 720)
	if OS.get_environment("MODO") != "":
		preload("res://core/sessao.gd").modo = OS.get_environment("MODO")
	tela = load("res://ui/batalha.tscn").instantiate()
	root.add_child(tela)
	await _esperar(0.3)
	tela.nova_batalha(int(OS.get_environment("SEMENTE")) if OS.get_environment("SEMENTE") != "" else 77)
	print("passo: nova batalha"); await _ate_vez_do_heroi()
	print("passo: vez do heroi"); var b = tela.batalha
	var heroi = b.unidade("heroi")
	await _passar_mouse(heroi.pos + Vector2i(2, 0))
	print("passo: mouse")
	await _foto("b1_inicio")
	# Anda 3 em direção aos goblins (clique real no mapa).
	var destino: Vector2i = heroi.pos
	for p in b.alcance_movimento(heroi)["mapa"]:
		if p.x > destino.x:
			destino = p
	await _clicar(destino)
	await _esperar(1.0)
	print("andou para ", heroi.pos, " (destino ", destino, ")")
	await _foto("b2_andou")
	# Termina o turno e deixa os goblins agirem até a vez do herói ou uma defesa.
	tela._acao("encerrar")
	for i in 60:
		if b.fase == Batalha.Fase.HEROI_DEFENDENDO and not tela._ocupado:
			break
		if b.vez_do_heroi() and not tela._ocupado:
			break
		if b.fase == Batalha.Fase.DISTRIBUINDO_DANO and not tela._ocupado:
			await _foto("b3b_distribuir")
			break
		if b.fase == Batalha.Fase.RESOLVIDO and not tela._ocupado:
			tela._acao("continuar")
		await _esperar(0.4)
	await _foto("b3_inimigos")
	await _ate_vez_do_heroi()
	# Procura um goblin para atacar, andando se preciso.
	for tentativa in 6:
		if b.fase in [Batalha.Fase.VITORIA, Batalha.Fase.DERROTA]:
			break
		var alvo = null
		for o in b.inimigos_vivos():
			if b.motivo_sem_ataque(heroi, o) == "":
				alvo = o
		if alvo != null:
			await _clicar(alvo.pos)
			await _esperar(0.6)
			await _foto("b4_mesa")
			tela._acao("parar")
			await _esperar(2.5)
			await _foto("b5_resultado")
			break
		var mais_perto: Vector2i = heroi.pos
		var g = b.inimigos_vivos()[0]
		for p in b.alcance_movimento(heroi)["mapa"]:
			if Grade.distancia(p, g.pos) < Grade.distancia(mais_perto, g.pos):
				mais_perto = p
		if mais_perto != heroi.pos:
			await _clicar(mais_perto)
			await _esperar(1.0)
		else:
			tela._acao("encerrar")
			await _ate_vez_do_heroi()
	quit()
