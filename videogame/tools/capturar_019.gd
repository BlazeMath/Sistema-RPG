## Capturas da 0.19: ponto de descanso, pedra alta, estante, névoa e luz.
extends "res://tools/capturar_batalha.gd"

const Sessao := preload("res://core/sessao.gd")
const Prontos := preload("res://core/herois_prontos.gd")


func _missao(modo: String) -> void:
	var nomes := Prontos.salvar_prontos()
	Sessao.definir_grupo(nomes.slice(0, 4))
	Sessao.solo = false
	Sessao.modo = modo
	if tela != null:
		tela.queue_free()
		await _esperar(0.2)
	tela = load("res://ui/batalha.tscn").instantiate()
	root.add_child(tela)
	await _esperar(0.3)
	tela.nova_batalha(5)
	await _ate_vez_do_heroi()


func _olhar(c: Vector2i) -> void:
	tela._camera.size = 11.0
	tela._focar_camera(Vector3(c.x, 0, c.y))
	await _esperar(0.8)


func _rodar() -> void:
	root.size = Vector2i(1280, 720)
	await _missao("fazenda")
	var b = tela.batalha
	var h = b.ativa()
	h.pos = Vector2i(5, 15)
	h.alerta = true
	b.eventos.append({"tipo": "mapa"})
	tela._processar()
	await _olhar(Vector2i(6, 14))
	await _foto("a1_descanso_fazenda")
	# sobe na pedra do vigia
	var pedra = b.interacao("pedra_vigia")
	h.pos = pedra["pos"] + Vector2i(-1, 0)
	b._aplicar_efeito(h, pedra, {"tipo": "subir"})
	tela._processar()
	await _olhar(pedra["pos"])
	await _foto("a2_pedra_alta")
	await _missao("masmorra")
	b = tela.batalha
	h = b.ativa()
	h.luz = "lanterna"
	h.pos = Vector2i(12, 10)
	b.eventos.append({"tipo": "mapa"})
	tela._processar()
	await _olhar(Vector2i(13, 11))
	await _foto("a3_cripta_estante")
	quit()
