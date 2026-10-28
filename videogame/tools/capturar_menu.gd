## Captura do menu (grupo e heróis prontos), 0.16.
extends "res://tools/capturar_batalha.gd"

func _rodar() -> void:
	root.size = Vector2i(1280, 720)
	preload("res://core/herois_prontos.gd").salvar_prontos()
	var m = load("res://ui/main.tscn").instantiate()
	root.add_child(m)
	await _esperar(0.6)
	await _foto("menu")
	quit()
