## Ferramenta de desenvolvimento: monta um grupo de 4 (Guerreiro, Ladino,
## Clérigo e Mago), abre a missão da fazenda e salva capturas.
extends SceneTree

const Batalha := preload("res://core/batalha.gd")
const Personagem := preload("res://core/personagem.gd")
const Sessao := preload("res://core/sessao.gd")

var tela
var pasta := ""


func _init() -> void:
	pasta = OS.get_environment("CAPTURAS")
	DirAccess.make_dir_recursive_absolute(pasta)
	_rodar.call_deferred()


func _esperar(seg: float) -> void:
	await create_timer(seg).timeout


func _foto(nome: String) -> void:
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png(pasta.path_join(nome + ".png"))
	print("captura: ", nome)


func _ficha(nome: String, classe: String, cartas: Array, meias: Array, herois: Array, arma: String, armadura: String, escudo: String, foco := "nenhum") -> Dictionary:
	var f := Personagem.nova()
	f["nome"] = nome
	f["classe"] = classe
	f["cartas"] = cartas
	f["meias"] = meias
	f["herois"] = herois
	f["arma"] = arma
	f["armadura"] = armadura
	f["escudo"] = escudo
	f["foco"] = foco
	return f


func _mover_heroi(id: String, p: Vector2i) -> void:
	var u = tela.batalha.unidade(id)
	u.pos = p
	tela._pecas[id].position = Vector3(p.x, 0, p.y)


func _rodar() -> void:
	root.size = Vector2i(1280, 720)
	var grupo := [
		_ficha("Bruna", "Guerreiro", ["classe.guerreiro.ombro-de-ferro", "classe.guerreiro.postura-do-leao"], [],
			["classe.guerreiro.heroi.foco-mortal", "raca.humano.heroi.incansavel"], "espada_longa", "cota_de_malha", "escudo_leve"),
		_ficha("Tico", "Ladino", ["classe.ladino.ataque-furtivo"], ["classe.ladino.sumico", "classe.ladino.pe-ligeiro"],
			["classe.ladino.heroi.larapio", "raca.humano.heroi.incansavel"], "faca", "couro_do_batedor", "nenhum"),
		_ficha("Irmã Lúcia", "Clérigo", ["classe.clerigo.toque-restaurador", "classe.clerigo.feixe-de-luz"], [],
			["classe.clerigo.heroi.estrela-do-amanhecer", "raca.humano.heroi.incansavel"], "maca", "couro_do_batedor", "nenhum", "simbolo_sagrado"),
		_ficha("Aldo", "Mago", ["classe.mago.aprendiz-de-fogo"], ["classe.mago.armadura-arcana", "classe.mago.misseis-magicos"],
			["classe.mago.heroi.controlador-do-arcano", "raca.humano.heroi.incansavel"], "faca", "nenhuma", "nenhum", "varinha_eletrizante"),
	]
	for f in grupo:
		var erros := Personagem.validar(f)
		if not erros.is_empty():
			print("ficha inválida ", f["nome"], ": ", erros)
	Personagem.salvar_todos(grupo)
	Sessao.definir_grupo(grupo.map(func(f): return f["nome"]))
	Sessao.solo = false
	Sessao.modo = "fazenda"
	tela = load("res://ui/batalha.tscn").instantiate()
	root.add_child(tela)
	await _esperar(0.3)
	tela.nova_batalha(5)
	for i in 60:
		if tela.batalha.vez_do_heroi() and not tela._ocupado:
			break
		await _esperar(0.3)
	var b = tela.batalha
	await _esperar(0.6)
	await _foto("f1_inicio")
	# Conversa com o fazendeiro
	_mover_heroi(b.ativa().id, Vector2i(3, 7))
	tela._ultimo_ativo = ""
	tela._atualizar()
	await _esperar(0.5)
	tela._abrir_dialogo("fazendeiro")
	await _esperar(0.3)
	await _foto("f2_fazendeiro")
	tela._escolher_opcao("fazendeiro", "conversar", "diplomacia")
	await _esperar(0.6)
	await _foto("f3_teste")
	tela._acao("parar")
	await _esperar(0.6)
	await _foto("f4_resultado")
	tela._acao("continuar")
	await _esperar(0.4)
	# Acampamento goblin
	var u = b.ativa()
	_mover_heroi(u.id, Vector2i(14, 4))
	tela._focar_camera(Vector3(15, 0, 5))
	await _esperar(0.6)
	tela._abrir_dialogo("acampamento")
	await _esperar(0.3)
	await _foto("f5_rokk")
	tela._fechar_dialogo()
	# Covil: o mago mira a Toupeira
	var mago = b.unidade("heroi4")
	var toupeira = b.unidade("toupeira")
	toupeira.alerta = true
	b.indice_vez = b.ordem.find("heroi4")
	b._comecar_turno()
	_mover_heroi("heroi4", Vector2i(23, 14))
	_mover_heroi("heroi3", Vector2i(23, 15))
	_mover_heroi("heroi", Vector2i(24, 15))
	_mover_heroi("heroi2", Vector2i(23, 16))
	tela._ultimo_ativo = ""
	tela._atualizar()
	await _esperar(0.6)
	var indice := -1
	for i in mago.cartas.size():
		if mago.cartas[i].slug() == "aprendiz-de-fogo":
			indice = i
	tela._acao_carta(indice, false)
	await _esperar(0.3)
	await _foto("f6_magia")
	tela._clique_no_mapa(toupeira.pos)
	await _esperar(0.8)
	await _foto("f7_mesa_magia")
	tela._acao("parar")
	for i in 30:
		await _esperar(0.3)
		if not tela._ocupado and b.fase == Batalha.Fase.RESOLVIDO:
			break
	await _foto("f8_resultado_magia")
	tela._acao("continuar")
	await _esperar(0.4)
	# Clérigo cura um aliado
	b.unidade("heroi").baralho.sofrer_dano(8)
	b.indice_vez = b.ordem.find("heroi3")
	b._comecar_turno()
	tela._ultimo_ativo = ""
	tela._atualizar()
	await _esperar(0.5)
	var clerigo = b.unidade("heroi3")
	for i in clerigo.cartas.size():
		if clerigo.cartas[i].slug() == "toque-restaurador":
			indice = i
	tela._acao_carta(indice, false)
	await _esperar(0.3)
	await _foto("f9_cura_aliado")
	quit()
