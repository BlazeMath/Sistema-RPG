## Captura do menu de pausa e da janela de jogos salvos (0.18).
extends "res://tools/capturar_batalha.gd"

const Sessao := preload("res://core/sessao.gd")
const Prontos := preload("res://core/herois_prontos.gd")


func _rodar() -> void:
	root.size = Vector2i(1280, 720)
	var nomes := Prontos.salvar_prontos()
	Sessao.definir_grupo(nomes.slice(0, 4))
	Sessao.modo = "arena"
	tela = load("res://ui/batalha.tscn").instantiate()
	root.add_child(tela)
	await _esperar(0.3)
	tela.nova_batalha(5)
	await _ate_vez_do_heroi()
	tela._abrir_pausa()
	tela._pausa._config.visible = true
	await _esperar(0.4)
	await _foto("p1_pausa")
	tela.queue_free()
	var vila = load("res://ui/vila.tscn").instantiate()
	root.add_child(vila)
	await _esperar(0.4)
	print("vila ok")
	load("res://core/salvamento.gd").salvar(1, "21/10/2026 20:50")
	await _foto("p3_vila")
	vila._saves.abrir("carregar")
	print("aberto")
	await _esperar(0.4)
	await _foto("p2_salvar")
	quit()
