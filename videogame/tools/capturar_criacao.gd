## Ferramenta de desenvolvimento: captura a tela de criação e a de perícias.
extends SceneTree

func _init() -> void:
	_rodar.call_deferred()

func _foto(nome: String) -> void:
	await process_frame
	await process_frame
	var pasta := OS.get_environment("CAPTURAS")
	root.get_texture().get_image().save_png(pasta.path_join(nome + ".png"))
	print("captura: ", nome)

func _rodar() -> void:
	root.size = Vector2i(1280, 720)
	var tela = load("res://ui/criacao.tscn").instantiate()
	root.add_child(tela)
	await create_timer(0.5).timeout
	await _foto("c1_criacao")
	tela._abrir_pericias()
	tela._definir_pericia("Luta", 0)
	await create_timer(0.3).timeout
	await _foto("c2_pericias")
	quit()
