## Capturas da 0.22: treino (tutorial), ações novas, intenções e reações dos monstros.
extends "res://tools/capturar_batalha.gd"

const Sessao := preload("res://core/sessao.gd")
const Prontos := preload("res://core/herois_prontos.gd")


func _rodar() -> void:
	root.size = Vector2i(1280, 720)
	var nomes := Prontos.salvar_prontos()
	Sessao.definir_grupo(nomes.slice(0, 4))
	Sessao.modo = "tutorial"
	tela = load("res://ui/batalha.tscn").instantiate()
	root.add_child(tela)
	await _esperar(0.3)
	tela.nova_batalha(5)
	await _ate_vez_do_heroi()
	var b = tela.batalha
	await _esperar(0.6)
	await _foto("t1_boas_vindas")
	tela._tut_proximo.pressed.emit()
	await _esperar(0.8)
	await _foto("t2_andar")
	var u = b.ativa()
	b.heroi_mover(b.unidade("boneco").pos + Vector2i(-1, 0)) if b.alcance_movimento(u)["mapa"].has(b.unidade("boneco").pos + Vector2i(-1, 0)) else null
	if not Grade.adjacentes(u.pos, b.unidade("boneco").pos):
		u.pos = b.unidade("boneco").pos + Vector2i(-1, 0)
	tela._processar()
	await _esperar(1.2)
	b.heroi_atacar(b.unidade("boneco"))
	tela._atualizar()
	await _esperar(0.6)
	await _foto("t3_atacar_mesa")
	b.teste_ataque.parar()
	b.continuar() if b.fase != Batalha.Fase.HEROI_ESCOLHE else null
	for f in ["atacou", "carta", "acao", "encerrou", "subiu", "saltou"]:
		b._tut(f)
	b.fase = Batalha.Fase.HEROI_ESCOLHE
	u.acoes_padrao = 2
	u.acoes_mov = 1
	tela._processar()
	await _esperar(1.0)
	tela._fixar("acoes")
	await _esperar(0.4)
	await _foto("t4_manobras_acoes")
	tela._fixar("acoes")
	b._tut("manobra")
	tela._processar()
	await _esperar(1.5)
	await _foto("t5_luta")
	# Intenções e reação: coloca um goblin perto e passa a vez.
	var g = b.unidade("goblin_treino1")
	g.pos = u.pos + Vector2i(2, 1)
	b.encerrar_turno()
	tela._processar()
	await _ate_vez_do_heroi()
	await _esperar(0.4)
	await _foto("t6_intencoes")
	tela._abrir_ficha_do_monstro(g)
	await _esperar(0.4)
	await _foto("t7_ficha_reacoes")
	quit()
