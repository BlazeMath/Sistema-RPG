## Captura da cripta escura (luz, tochas, esqueletos) e da vila (0.15).
## CAPTURAS=/pasta xvfb-run godot --path . --rendering-driver opengl3 -s res://tools/capturar_masmorra.gd
extends "res://tools/capturar_batalha.gd"

const Sessao := preload("res://core/sessao.gd")
const Personagem := preload("res://core/personagem.gd")
const TC := preload("res://tests/test_classes.gd")


func _rodar() -> void:
	root.size = Vector2i(1280, 720)
	var tc = TC.new()
	var grupo := [tc._ficha("Guerreiro", "Bruna", ["classe.guerreiro.ombro-de-ferro"], ["classe.guerreiro.heroi.foco-mortal", "raca.humano.heroi.incansavel"]),
		tc._ficha("Clérigo", "Tomas", ["classe.clerigo.voz-do-exorcista"], []),
		tc._ficha("Mago", "Aldo", ["classe.mago.aprendiz-de-luz"], []),
		tc._ficha("Ladino", "Lis", [], [])]
	Personagem.salvar_todos(grupo)
	Sessao.definir_grupo(["Bruna", "Tomas", "Aldo", "Lis"])
	Sessao.solo = false
	Sessao.modo = "masmorra"
	tela = load("res://ui/batalha.tscn").instantiate()
	root.add_child(tela)
	await _esperar(0.3)
	tela.nova_batalha(5)
	await _ate_vez_do_heroi()
	var b = tela.batalha
	await _esperar(0.5)
	await _foto("m1_entrada")
	# Leva o grupo ao ossário com as lanternas acesas.
	for h in b.herois():
		h.luz = "lanterna"
	var pos := [Vector2i(10, 11), Vector2i(10, 12), Vector2i(9, 11), Vector2i(9, 12)]
	var hs = b.herois()
	for i in hs.size():
		hs[i].pos = pos[i]
	b.eventos.append({"tipo": "mapa"})
	tela._montar_mundo()
	tela._processar()
	await _esperar(0.8)
	await _foto("m2_ossario_lanternas")
	b.herois()[0].luz = "tocha"
	tela._processar()
	await _esperar(0.5)
	await _foto("m3_tocha")
	tela.queue_free()
	await _esperar(0.3)
	var vila = load("res://ui/vila.tscn").instantiate()
	root.add_child(vila)
	await _esperar(0.6)
	await _foto("m4_vila")
	quit()
