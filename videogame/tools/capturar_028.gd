## Capturas da 0.28: as missões prontas no editor e no jogo, e a vitrine dos monstros novos.
extends "res://tools/capturar_batalha.gd"

const Sessao := preload("res://core/sessao.gd")
const Prontos := preload("res://core/herois_prontos.gd")
const Fase := preload("res://core/fase.gd")

const MISSOES := ["investigacao_vau_cinzento", "zumbis_sinos_mudos", "bandidos_cao_vermelho", "baile_mascaras_prata",
	"deserto_kesh_tar", "torre_vaelor"]
const NOVOS := ["rato_gigante", "lobo", "lobo_atroz", "aranha_gigante", "escorpiao_gigante", "zumbi", "zumbi_inchado", "carnical",
	"mumia", "bandido", "bandido_besteiro", "capanga", "capitao_bandido", "cultista", "guarda_corrupto", "assassino",
	"duelista", "orc", "ogro", "troll", "gargula", "armadura_animada", "elemental_fogo", "elemental_terra", "diabrete",
	"verme_da_areia", "mago_vaelor"]


func _jogo(id: String, nome: String) -> void:
	Sessao.modo = "fase:" + id
	Sessao.fase_teste = ""
	tela = load("res://ui/batalha.tscn").instantiate()
	root.add_child(tela)
	await _esperar(0.3)
	tela.nova_batalha(9)
	await _esperar(1.2)
	await _foto(nome + "_a")
	await _ate_vez_do_heroi()
	await _esperar(0.8)
	await _foto(nome + "_b")
	tela.queue_free()
	await _esperar(0.3)


func _rodar() -> void:
	root.size = Vector2i(1280, 720)
	var nomes := Prontos.salvar_prontos()
	Sessao.definir_grupo(nomes.slice(0, 4))
	# Vitrine: todos os monstros novos em fila, alertas, perto dos heróis.
	var v := Fase.nova("Vitrine 0.28", 20, 12)
	v["inicio"] = ["2,5", "2,6", "3,5", "3,6"]
	for i in NOVOS.size():
		v["inimigos"].append({"id": "m%d" % i, "preset": NOVOS[i], "pos": "%d,%d" % [6 + (i % 7) * 2, 1 + int(i / 7) * 3], "alerta": false, "vigia": 1})
	v["objetivo"]["tipo"] = "derrotar_todos"
	Fase.salvar(v)
	var ed = load("res://ui/editor_fases.tscn").instantiate()
	root.add_child(ed)
	await _esperar(0.6)
	ed._biblioteca.queue_free()
	ed._biblioteca = null
	for i in MISSOES.size():
		ed._abrir(MISSOES[i])
		await _esperar(0.4)
		await _foto("m%d_editor_%s" % [i + 1, MISSOES[i]])
	ed.queue_free()
	await _esperar(0.3)
	await _jogo(Fase.id_de("Vitrine 0.28"), "v_vitrine")
	for i in MISSOES.size():
		await _jogo(MISSOES[i], "m%d_jogo" % (i + 1))
	Fase.apagar(Fase.id_de("Vitrine 0.28"))
	quit()
