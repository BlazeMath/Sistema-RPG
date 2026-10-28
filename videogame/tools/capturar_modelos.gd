## Captura dos modelos KayKit (0.18): arena, cripta e pântano de perto.
extends "res://tools/capturar_batalha.gd"

const Sessao := preload("res://core/sessao.gd")
const Prontos := preload("res://core/herois_prontos.gd")


func _rodar() -> void:
	root.size = Vector2i(1280, 720)
	var nomes := Prontos.salvar_prontos()
	for modo in ["arena", "masmorra", "pantano"]:
		Sessao.definir_grupo(nomes.slice(0, 4) if modo != "pantano" else nomes.slice(1, 5))
		Sessao.solo = false
		Sessao.modo = modo
		if tela != null:
			tela.queue_free()
		tela = load("res://ui/batalha.tscn").instantiate()
		root.add_child(tela)
		await _esperar(0.3)
		tela.nova_batalha(5)
		await _ate_vez_do_heroi()
		var b = tela.batalha
		var h = b.herois()[0]
		if modo != "arena":
			for x in b.herois():
				x.luz = "lanterna"
			# põe os inimigos perto do grupo para a foto
			var i := 0
			for u in b.unidades:
				if not u.eh_heroi() and i < 4:
					u.pos = h.pos + Vector2i(2 + i % 2, -1 + i)
					i += 1
			b.eventos.append({"tipo": "mapa"})
			tela._montar_mundo()
			tela._processar()
		tela._camera.size = 9.0 if tela._camera.projection == Camera3D.PROJECTION_ORTHOGONAL else tela._camera.size
		tela._focar_camera(Vector3(h.pos.x + 1, 0, h.pos.y))
		await _esperar(1.2)
		await _foto("mod_" + modo)
	quit()
