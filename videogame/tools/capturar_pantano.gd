## Captura do pântano à noite (0.17).
extends "res://tools/capturar_batalha.gd"

const Sessao := preload("res://core/sessao.gd")

func _rodar() -> void:
	root.size = Vector2i(1280, 720)
	var nomes = preload("res://core/herois_prontos.gd").salvar_prontos()
	Sessao.definir_grupo(nomes.slice(0, 4))
	Sessao.solo = false
	Sessao.modo = "pantano"
	tela = load("res://ui/batalha.tscn").instantiate()
	root.add_child(tela)
	await _esperar(0.3)
	tela.nova_batalha(3)
	await _ate_vez_do_heroi()
	await _esperar(0.5)
	await _foto("p1_pantano")
	var b = tela.batalha
	var hs = b.herois()
	var pos := [Vector2i(17, 13), Vector2i(16, 13), Vector2i(17, 12), Vector2i(16, 12)]
	for i in hs.size():
		hs[i].pos = pos[i]
	hs[0].luz = "tocha"
	for o in b.inimigos_vivos():
		if o.grupo == "ruinas":
			o.alerta = true
	tela._montar_mundo()
	tela._processar()
	tela._focar_camera(tela._mundo(Vector2i(20, 15)))
	await _esperar(0.8)
	await _foto("p2_ruinas")
	quit()
