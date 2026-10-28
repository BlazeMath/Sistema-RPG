## Ferramenta de desenvolvimento: abre a trilha do riacho, interage com cliques
## de verdade e salva capturas. Uso:
##   CAPTURAS=/pasta xvfb-run godot --path . --rendering-driver opengl3 -s res://tools/capturar_exploracao.gd
extends SceneTree

const Batalha := preload("res://core/batalha.gd")

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
	var ponto: Vector2 = tela._camera.unproject_position(Vector3(celula.x, 0, celula.y))
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


func _tecla(k: Key) -> void:
	for apertado in [true, false]:
		var e := InputEventKey.new()
		e.keycode = k
		e.pressed = apertado
		root.push_input(e)
		await process_frame


func _ate_vez_do_heroi() -> void:
	for i in 80:
		if tela.batalha.vez_do_heroi() and not tela._ocupado:
			return
		await _esperar(0.3)


func _rodar() -> void:
	root.size = Vector2i(1280, 720)
	preload("res://core/sessao.gd").modo = "trilha"
	tela = load("res://ui/batalha.tscn").instantiate()
	root.add_child(tela)
	await _esperar(0.3)
	tela.nova_batalha(int(OS.get_environment("SEMENTE")) if OS.get_environment("SEMENTE") != "" else 21)
	await _ate_vez_do_heroi()
	var b = tela.batalha
	var heroi = b.unidade("heroi")
	if OS.get_environment("QUEDA") != "":
		heroi.pos = Vector2i(8, 2)
		tela._pecas["heroi"].position = Vector3(8, 0, 2)
		b.interacao_atual = {"id": "paredao", "opcao": "escalar", "dano": 0, "vitoria": ""}
		b._resolver_interacao(4)
		tela._atualizar()
		await _esperar(0.3)
		await _foto("q1_queda")
		b.heroi_amortecer_queda(true)
		tela._processar()
		await _esperar(0.6)
		await _foto("q2_amortecer")
		await _tecla(KEY_ENTER)
		await _esperar(0.6)
		await _foto("q3_resultado")
		quit()
		return
	await _clicar(Vector2i(3, 5))
	await _esperar(1.0)
	print("herói em ", heroi.pos)
	var mov := InputEventMouseMotion.new()
	mov.position = tela._camera.unproject_position(Vector3(4, 0, 5))
	root.push_input(mov)
	await _esperar(0.3)
	await _foto("e1_inicio")
	await _clicar(Vector2i(4, 5))
	await _esperar(0.4)
	await _foto("e2_dialogo")
	tela._escolher_opcao("riacho", "nadar")
	await _esperar(0.8)
	await _foto("e3_teste")
	await _tecla(KEY_ENTER)
	await _esperar(0.8)
	await _foto("e4_resultado")
	print("fase: ", b.fase, " resultado: ", b.resultado_interacao.get("rotulo", ""))
	await _tecla(KEY_ENTER)
	await _esperar(0.8)
	if b.fase == Batalha.Fase.DISTRIBUINDO_DANO:
		await _foto("e5_distribuir")
		await _tecla(KEY_ENTER)
		await _esperar(0.5)
	# Distribuição forçada para a captura.
	if b.vez_do_heroi():
		b._dano_no_heroi(heroi, 6, "interacao", Batalha.Fase.HEROI_ESCOLHE)
		tela._atualizar()
		await _esperar(0.3)
		await _foto("e6_distribuir")
		tela._botao_distribuicao("baralho")
		await _esperar(0.2)
		await _foto("e6b_distribuir_baralho")
		await _tecla(KEY_ENTER)
		await _esperar(0.6)
	await _tecla(KEY_I)
	await _esperar(0.4)
	await _foto("e7_inventario")
	await _tecla(KEY_I)
	# Do outro lado: baú, com o herói ao lado.
	heroi.pos = Vector2i(6, 1)
	tela._atualizar_pecas()
	tela._pecas["heroi"].position = Vector3(6, 0, 1)
	tela._atualizar()
	await _clicar(Vector2i(7, 1))
	await _esperar(0.4)
	await _foto("e8_bau")
	tela._fechar_dialogo()
	var mov2 := InputEventMouseMotion.new()
	mov2.position = tela._camera.unproject_position(Vector3(12, 0, 6))
	root.push_input(mov2)
	await _esperar(0.3)
	await _foto("e9_vigia")
	# Combate: goblins alertas atacam e o jogador distribui o dano.
	tela._auto.button_pressed = true
	b._alertar_inimigos()
	var brigao = b.unidade("dorminhoco")
	brigao.pos = heroi.pos + Vector2i(0, 1)
	tela._pecas["dorminhoco"].position = Vector3(brigao.pos.x, 0, brigao.pos.y)
	tela._acao("encerrar")
	for i in 120:
		if not tela._ocupado:
			if b.fase == Batalha.Fase.DISTRIBUINDO_DANO:
				await _esperar(0.3)
				await _foto("e10_distribuir_ataque")
				await _tecla(KEY_ENTER)
				await _esperar(0.5)
				await _foto("e11_resultado_ataque")
				break
			elif b.fase == Batalha.Fase.RESOLVIDO:
				tela._acao("continuar")
			elif b.vez_do_heroi():
				tela._acao("encerrar")
			elif b.fase in [Batalha.Fase.VITORIA, Batalha.Fase.DERROTA]:
				break
		await _esperar(0.3)
	quit()
