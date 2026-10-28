## Capturas da 0.23: vila andável, catacumbas (níveis, narração), loja.
extends "res://tools/capturar_batalha.gd"

const Sessao := preload("res://core/sessao.gd")
const Prontos := preload("res://core/herois_prontos.gd")


func _rodar() -> void:
	root.size = Vector2i(1280, 720)
	var nomes := Prontos.salvar_prontos()
	Sessao.definir_grupo(nomes.slice(0, 4))
	Sessao.modo = "vila"
	tela = load("res://ui/batalha.tscn").instantiate()
	root.add_child(tela)
	await _esperar(0.3)
	tela.nova_batalha(5)
	await _ate_vez_do_heroi()
	await _esperar(0.8)
	await _foto("v1_vila")
	tela._abrir_vila("ferreiro")
	await _esperar(0.6)
	await _foto("v2_ferreiro")
	Sessao.modo = "catacumbas"
	tela.nova_batalha(5)
	await _ate_vez_do_heroi()
	await _esperar(0.8)
	await _foto("c1_entrada")
	var b = tela.batalha
	var u = b.ativa()
	u.pos = Vector2i(22, 21)
	b.grade.obstaculos.erase(Vector2i(13, 15))
	b.grade.obstaculos.erase(Vector2i(13, 16))
	tela._montar_terreno()
	tela._atualizar_pecas()
	tela._focar_camera(tela._mundo(Vector2i(22, 16)))
	b._verificar_avistamentos()
	tela._processar()
	await _esperar(1.5)
	await _foto("c2_salao_niveis")
	quit()
