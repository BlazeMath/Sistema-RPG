## Capturas da 0.25: inventário na criação, lojas com moedas, Bruxo na batalha.
extends "res://tools/capturar_batalha.gd"

const Sessao := preload("res://core/sessao.gd")
const Prontos := preload("res://core/herois_prontos.gd")


func _rodar() -> void:
	root.size = Vector2i(1280, 720)
	var nomes := Prontos.salvar_prontos()
	var vesna: String = nomes.filter(func(n): return n.begins_with("Vesna"))[0]
	Sessao.definir_grupo([vesna] + nomes.slice(0, 2))
	Sessao.ficha = Prontos.ficha("Bruxo")
	var cri = load("res://ui/criacao.tscn").instantiate()
	root.add_child(cri)
	await _esperar(0.6)
	await _foto("i1_criacao_bruxo")
	cri._abrir_inventario()
	await _esperar(0.4)
	await _foto("i2_inventario")
	cri.queue_free()
	await _esperar(0.2)
	Sessao.modo = "vila"
	tela = load("res://ui/batalha.tscn").instantiate()
	root.add_child(tela)
	await _esperar(0.3)
	tela.nova_batalha(5)
	await _ate_vez_do_heroi()
	await _esperar(0.5)
	tela._abrir_vila("mercado")
	await _esperar(0.6)
	await _foto("i3_mercado")
	var v = root.find_child("vila_aberta", true, false)
	if v != null:
		v.queue_free()
	await _esperar(0.2)
	Sessao.modo = "arena"
	Sessao.definir_grupo([vesna])
	tela.nova_batalha(7)
	await _ate_vez_do_heroi()
	await _esperar(0.8)
	var b = tela.batalha
	var ini = preload("res://core/cartas_bruxo.gd").carta_inicial(b.ativa())
	print("ativa: ", b.ativa().nome, " pactos: ", preload("res://core/cartas_bruxo.gd").pactos(b.ativa()))
	tela._fixar("cartas")
	await _esperar(0.5)
	await _foto("i4_batalha")
	quit()
