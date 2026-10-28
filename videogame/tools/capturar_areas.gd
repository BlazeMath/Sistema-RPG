## Captura da mira de área (prévia) e das zonas no mapa (0.11).
## CAPTURAS=/pasta xvfb-run godot --path . --rendering-driver opengl3 -s res://tools/capturar_areas.gd
extends "res://tools/capturar_batalha.gd"

const Sessao := preload("res://core/sessao.gd")
const TC := preload("res://tests/test_classes.gd")


func _rodar() -> void:
	root.size = Vector2i(1280, 720)
	var mago: Dictionary = TC.new()._ficha("Mago", "Aldo", ["classe.mago.aprendiz-de-fogo"], ["classe.mago.heroi.controlador-do-arcano", "raca.humano.heroi.incansavel"])
	mago["consumiveis"] = ["bomba_de_fumaca", "frasco_de_piche"]
	Sessao.solo = true
	Sessao.ficha = mago
	Sessao.modo = "arena"
	tela = load("res://ui/batalha.tscn").instantiate()
	root.add_child(tela)
	await _esperar(0.3)
	tela.nova_batalha(5)
	await _ate_vez_do_heroi()
	var b = tela.batalha
	var u = b.ativa()
	# Zonas de item no mapa
	b.criar_zona("piche", "Piche", b.celulas_da_area(u, {"forma": "quadrado", "tamanho": 3}, u.pos + Vector2i(3, 2), 0), null, {"vinculada": false, "terreno_dificil": true})
	b.criar_zona("fumaca", "Fumaça", b.celulas_da_area(u, {"forma": "quadrado", "tamanho": 3}, u.pos + Vector2i(3, -2), 0), null, {"vinculada": false, "cobertura": 1})
	tela._processar()
	await _esperar(0.5)
	# Mira da Labareda Voraz (linha)
	var i: int = u.cartas.size() - 1
	if u.cartas[i].slug() != "labareda-voraz":
		u.cartas[i].lado = 1 - u.cartas[i].lado
	tela._acao_carta(i, false)
	await _passar_mouse(u.pos + Vector2i(3, 0))
	await _foto("a1_linha")
	tela._modo_area = -1
	tela._item_area = "frasco_de_piche"
	await _passar_mouse(u.pos + Vector2i(2, 3))
	await _foto("a2_item_area")
	quit()
