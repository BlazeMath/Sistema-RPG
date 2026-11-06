## Capturas da 0.27: editor de fases (biblioteca, mapa, inspetores) e a fase de exemplo no jogo.
extends "res://tools/capturar_batalha.gd"

const Sessao := preload("res://core/sessao.gd")
const Prontos := preload("res://core/herois_prontos.gd")


func _rodar() -> void:
	root.size = Vector2i(1280, 720)
	var nomes := Prontos.salvar_prontos()
	Sessao.definir_grupo(nomes.slice(0, 3))
	var ed = load("res://ui/editor_fases.tscn").instantiate()
	root.add_child(ed)
	await _esperar(0.6)
	await _foto("e1_biblioteca")
	ed._biblioteca.queue_free()
	ed._biblioteca = null
	ed._abrir("exemplo_moinho")
	await _esperar(0.4)
	await _foto("e2_mapa_fase")
	ed._escolher_ferramenta("objeto")
	ed._selecionar("inimigo", "chefe")
	await _esperar(0.4)
	await _foto("e3_inimigo")
	ed._escolher_ferramenta("interacao")
	ed._selecionar("interacao", "caixa")
	await _esperar(0.4)
	await _foto("e4_interacao")
	ed._escolher_ferramenta("area")
	ed._selecionar("area", "ponte_teste")
	await _esperar(0.4)
	await _foto("e5_area")
	var e: Dictionary = ed._inimigo_por_id("brigao")
	e["proprios"]["ativo"] = true
	ed._selecionar("inimigo", "brigao")
	ed._insp.get_parent().scroll_vertical = 600
	await _esperar(0.4)
	await _foto("e6_numeros_proprios")
	ed._validar(true)
	ed._escolher_ferramenta("chao")
	await _esperar(0.4)
	await _foto("e7_chao_validar")
	ed.queue_free()
	await _esperar(0.3)
	Sessao.modo = "fase:exemplo_moinho"
	Sessao.fase_teste = "exemplo_moinho"
	tela = load("res://ui/batalha.tscn").instantiate()
	root.add_child(tela)
	await _esperar(0.3)
	tela.nova_batalha(9)
	await _esperar(1.5)
	await _foto("e8_jogo_abertura")
	await _ate_vez_do_heroi()
	await _esperar(0.8)
	await _foto("e9_jogo")
	quit()
