## Captura dos botões de repertório, da mira do cone e da pergunta da Arma Pétrea (0.14).
## CAPTURAS=/pasta xvfb-run godot --path . --rendering-driver opengl3 -s res://tools/capturar_repertorio.gd
extends "res://tools/capturar_batalha.gd"

const Sessao := preload("res://core/sessao.gd")
const TC := preload("res://tests/test_classes.gd")


func _rodar() -> void:
	root.size = Vector2i(1280, 720)
	var mago: Dictionary = TC.new()._ficha("Mago", "Aldo", ["classe.mago.aprendiz-de-terra"], ["classe.mago.heroi.controlador-do-arcano", "raca.humano.heroi.incansavel"])
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
	var i: int = u.cartas.size() - 1
	if u.cartas[i].slug() != "aprendiz-de-terra":
		u.cartas[i].lado = 1 - u.cartas[i].lado
	tela._processar()
	await _esperar(0.5)
	tela._cartas_lista.get_parent().scroll_vertical = 400
	await _esperar(0.2)
	await _foto("r1_botoes")
	tela._acao_carta(i, false, "muro")
	await _passar_mouse(u.pos + Vector2i(1, 0))
	await _foto("r2_muro")
	tela._modo_area = -1
	b.heroi_usar_area(i, u.pos + Vector2i(0, -1), 0, "muro")
	tela._processar()
	await _esperar(0.8)
	await _foto("r2b_muro_criado")
	tela._acao_carta(i, false, "arma-petrea")
	await _esperar(0.5)
	await _foto("r3_arma_petrea")
	quit()
