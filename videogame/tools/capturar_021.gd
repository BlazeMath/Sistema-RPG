## Capturas da 0.21: tela nova, menus flutuantes, fichas, mesa compacta.
extends "res://tools/capturar_batalha.gd"

const Sessao := preload("res://core/sessao.gd")
const Prontos := preload("res://core/herois_prontos.gd")


func _rodar() -> void:
	root.size = Vector2i(1280, 720)
	var nomes := Prontos.salvar_prontos()
	Sessao.definir_grupo(nomes.slice(0, 4))
	Sessao.modo = "fazenda"
	tela = load("res://ui/batalha.tscn").instantiate()
	root.add_child(tela)
	await _esperar(0.3)
	tela.nova_batalha(5)
	await _ate_vez_do_heroi()
	var b = tela.batalha
	await _esperar(0.6)
	await _foto("u1_tela_limpa")
	tela._fixar("cartas")
	await _esperar(0.4)
	await _foto("u2_habilidades")
	tela._fixar("cartas")
	tela._fixar("acoes")
	await _esperar(0.4)
	await _foto("u3_acoes")
	tela._fixar("acoes")
	tela._abrir_ficha_do_heroi()
	await _esperar(0.4)
	await _foto("u4_ficha_heroi")
	tela._ficha_painel.visible = false
	var g = b.unidade("rokk") if b.unidade("rokk") != null else b.inimigos_vivos()[0]
	tela._abrir_ficha_do_monstro(g)
	await _esperar(0.4)
	await _foto("u5_ficha_monstro")
	tela._ficha_painel.visible = false
	var u = b.ativa()
	var alvo = b.inimigos_vivos()[0]
	alvo.pos = u.pos + Vector2i(3, 0)
	b._novo_ataque(u, alvo, {})
	tela._atualizar()
	await _esperar(0.5)
	await _foto("u6_mesa")
	b.teste_ataque.parar()
	tela._alternar_inventario()
	await _esperar(0.6)
	await _foto("u7_inventario")
	tela._alternar_inventario()
	b.eventos.append({"tipo": "cura", "id": u.id, "valor": 3})
	b.eventos.append({"tipo": "ataque", "atacante": u.id, "defensor": alvo.id, "magia": true, "tipo_dano": "Radiante"})
	tela._tocar_eventos()
	await _esperar(0.25)
	await _foto("u8_efeitos")
	quit()
