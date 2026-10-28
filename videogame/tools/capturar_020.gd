## Capturas da 0.20: fim do turno, ficha escolhendo a carta, Foco na mesa, barra de vida.
extends "res://tools/capturar_batalha.gd"

const Sessao := preload("res://core/sessao.gd")
const Prontos := preload("res://core/herois_prontos.gd")


func _rodar() -> void:
	root.size = Vector2i(1280, 720)
	var nomes := Prontos.salvar_prontos()
	Sessao.definir_grupo(nomes.slice(0, 4))
	Sessao.modo = "arena"
	tela = load("res://ui/batalha.tscn").instantiate()
	root.add_child(tela)
	await _esperar(0.3)
	tela.nova_batalha(5)
	await _ate_vez_do_heroi()
	var b = tela.batalha
	var u = b.ativa()
	u.baralho.sofrer_dano(9)
	u.baralho.exilio.append(u.baralho.descarte.pop_back())
	u.cartas[0].fadiga = 1
	u.cartas[1].fadiga = 1
	tela._atualizar()
	tela._mostrar_fim_de_turno()
	await _esperar(0.4)
	await _foto("t1_fim_do_turno")
	tela._escolha_fadiga.visible = false
	u.dar_ficha("Preparo")
	tela._atualizar()
	await _esperar(0.4)
	await _foto("t2_ficha_escolhe_carta")
	tela._dialogo.visible = false
	u.cartas[0].fichas["Foco"] = 1
	var alvo = b.inimigos_vivos()[0]
	for o in b.inimigos_vivos():
		if b.motivo_sem_ataque(u, o) == "":
			alvo = o
	alvo.pos = u.pos + Vector2i(2, 0) if not u.a_distancia else u.pos + Vector2i(3, 0)
	b._novo_ataque(u, alvo, {})
	tela._atualizar()
	await _esperar(0.4)
	await _foto("t3_foco_na_mesa")
	quit()
