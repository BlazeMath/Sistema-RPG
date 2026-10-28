## Captura da batalha com os heróis prontos (cartas como cartas, mãos, troca de arma), 0.16.
extends "res://tools/capturar_batalha.gd"

const Sessao := preload("res://core/sessao.gd")

func _rodar() -> void:
	root.size = Vector2i(1280, 720)
	var nomes = preload("res://core/herois_prontos.gd").salvar_prontos()
	Sessao.definir_grupo(nomes.slice(0, 4))
	Sessao.solo = false
	Sessao.modo = "arena"
	tela = load("res://ui/batalha.tscn").instantiate()
	root.add_child(tela)
	await _esperar(0.3)
	tela.nova_batalha(9)
	await _ate_vez_do_heroi()
	await _esperar(0.5)
	await _foto("u1_batalha")
	var b = tela.batalha
	for h in b.herois():
		if h.classe == "Clérigo":
			b.indice_vez = b.ordem.find(h.id)
			b._comecar_turno()
	tela._processar()
	await _esperar(0.3)
	var u = b.ativa()
	# Mago: força a sobra de fadiga para abrir a escolha
	for i in u.cartas.size():
		var c = u.cartas[i]
		if b.eh_conjuracao(c) and c.limite() > 0:
			c.fadiga = c.limite()
			tela._acao_carta(i, false, b._info_lado(c).get("opcao", ""))
			break
	await _esperar(0.4)
	await _foto("u2_fadiga")
	quit()
