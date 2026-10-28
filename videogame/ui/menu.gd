## Menu inicial das versões de teste.
## Esquerda: modos de jogo. Direita: o grupo (até 4 heróis salvos), com os heróis prontos.
extends Control

const VERSAO := "0.23"
const Sessao := preload("res://core/sessao.gd")
const Personagem := preload("res://core/personagem.gd")
const Prontos := preload("res://core/herois_prontos.gd")

var _grupo: VBoxContainer
var _resumo: Label


func _ready() -> void:
	Sessao.solo = false
	Sessao.campanha = false
	var fundo := ColorRect.new()
	fundo.color = Color("121116")
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 14)
	centro.add_child(raiz)
	var titulo := Label.new()
	titulo.text = "SISTEMA 21"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_override("font", load("res://assets/fontes/DejaVuSerif-Bold.ttf"))
	titulo.add_theme_font_size_override("font_size", 56)
	titulo.add_theme_color_override("font_color", Color("c9a45c"))
	raiz.add_child(titulo)
	raiz.add_child(_texto("Versão de teste %s" % VERSAO, 14, Color("9a95a3"), true))
	var colunas := HBoxContainer.new()
	colunas.add_theme_constant_override("separation", 28)
	raiz.add_child(colunas)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	colunas.add_child(v)
	v.add_child(_botao("Vila de Pedravelha (andar pela vila, guilda, lojas)", "res://ui/batalha.tscn", "vila"))
	var saves = load("res://ui/janela_saves.gd").new()
	add_child(saves)
	saves.depois_de_carregar = func(_msg):
		Sessao.modo = "vila"
		get_tree().change_scene_to_file("res://ui/batalha.tscn")
	v.add_child(_botao_acao("Carregar jogo salvo (vai para a vila)", func(): saves.abrir("carregar")))
	v.add_child(_botao("Treino: aprenda a jogar (tutorial)", "res://ui/batalha.tscn", "tutorial"))
	v.add_child(_botao("Missão: a fazenda Vale Seco", "res://ui/batalha.tscn", "fazenda"))
	v.add_child(_botao("Missão: a cripta de Pedravelha (escura)", "res://ui/batalha.tscn", "masmorra"))
	v.add_child(_botao("Missão: o Pântano dos Afogados (noite)", "res://ui/batalha.tscn", "pantano"))
	v.add_child(_botao("Missão longa: as Catacumbas de Vel-Dorath", "res://ui/batalha.tscn", "catacumbas"))
	v.add_child(_botao("Exploração: a trilha do riacho", "res://ui/batalha.tscn", "trilha"))
	v.add_child(_botao("Arena: combate simples", "res://ui/batalha.tscn", "arena"))
	v.add_child(_botao("X1 contra o Chefe Goblin (primeiro herói)", "res://ui/batalha.tscn", "x1"))
	v.add_child(_botao("Criar e editar heróis", "res://ui/criacao.tscn"))
	v.add_child(_botao("Mesa de 21 pura (versão 0.3)", "res://ui/duelo.tscn"))
	v.add_child(_botao("Sair", ""))
	# Grupo
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("1c1b22")
	sb.border_color = Color("34323d")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(14)
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(380, 0)
	colunas.add_child(p)
	var vg := VBoxContainer.new()
	vg.add_theme_constant_override("separation", 8)
	p.add_child(vg)
	vg.add_child(_texto("Grupo para jogar (até 4)", 18, Color("c9a45c")))
	vg.add_child(_texto("Vale para a arena, as missões, a trilha e a vila.", 12, Color("9a95a3")))
	_grupo = VBoxContainer.new()
	_grupo.add_theme_constant_override("separation", 4)
	vg.add_child(_grupo)
	var bt_prontos := _botao_acao("Adicionar heróis prontos (um de cada classe)", func():
		var nomes := Prontos.salvar_prontos()
		Sessao.definir_grupo(nomes.slice(0, 4))
		_montar_grupo())
	vg.add_child(bt_prontos)
	_resumo = _texto("", 13, Color("e9e4d8"))
	_resumo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_resumo.custom_minimum_size = Vector2(350, 0)
	vg.add_child(_resumo)
	_montar_grupo()
	var musica = get_node_or_null("/root/Musica")
	if musica != null:
		musica.tocar("menu")
	var som := _botao_acao("Música: %s (M liga e desliga)" % ("desligada" if musica != null and musica.mudo else "ligada"), func(): pass)
	som.pressed.connect(func():
		if musica != null:
			musica.alternar_mudo()
			som.text = "Música: %s (M liga e desliga)" % ("desligada" if musica.mudo else "ligada"))
	vg.add_child(som)


func _montar_grupo() -> void:
	for f in _grupo.get_children():
		f.queue_free()
	var salvos := Personagem.carregar_todos()
	var validos := salvos.filter(func(f): return Personagem.validar(f).is_empty()).map(func(f): return f["nome"])
	var nomes: Array = Sessao.nomes_do_grupo().filter(func(n): return n in validos)
	if nomes.size() != Sessao.nomes_do_grupo().size():
		Sessao.definir_grupo(nomes)   # tira do grupo quem está incompleto ou foi apagado
	for f in salvos:
		var valido := Personagem.validar(f).is_empty()
		var cb := CheckBox.new()
		cb.text = "%s · %s%s" % [f["nome"], f["classe"], "" if valido else " (incompleto)"]
		cb.button_pressed = f["nome"] in nomes
		cb.disabled = not valido or (not cb.button_pressed and nomes.size() >= Sessao.MAXIMO_GRUPO)
		cb.focus_mode = Control.FOCUS_NONE
		var nome: String = f["nome"]
		cb.toggled.connect(func(on):
			var g: Array = Sessao.nomes_do_grupo().duplicate()
			if on and not nome in g:
				g.append(nome)
			elif not on:
				g.erase(nome)
			Sessao.definir_grupo(g)
			_montar_grupo())
		_grupo.add_child(cb)
	var fichas := Sessao.fichas_do_grupo()
	var lista := PackedStringArray()
	for f in fichas:
		lista.append("%s (%s)" % [f["nome"], f["classe"]])
	_resumo.text = "Jogando com: " + ", ".join(lista)


func _texto(t: String, tamanho: int, cor: Color, centro := false) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", load("res://assets/fontes/DejaVuSans.ttf"))
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	if centro:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _estilo(bt: Button) -> void:
	bt.focus_mode = Control.FOCUS_NONE
	bt.add_theme_font_override("font", load("res://assets/fontes/DejaVuSans.ttf"))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("2a2833")
	sb.border_color = Color("8d733f")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(8)
	var sb2 := sb.duplicate()
	sb2.bg_color = Color("34313f")
	sb2.border_color = Color("c9a45c")
	bt.add_theme_stylebox_override("normal", sb)
	bt.add_theme_stylebox_override("hover", sb2)
	bt.add_theme_stylebox_override("pressed", sb2)
	bt.add_theme_color_override("font_color", Color("e9e4d8"))


func _botao_acao(texto: String, acao: Callable) -> Button:
	var bt := Button.new()
	bt.text = texto
	_estilo(bt)
	bt.add_theme_font_size_override("font_size", 14)
	bt.pressed.connect(acao)
	return bt


func _botao(texto: String, cena: String, modo := "") -> Button:
	var bt := Button.new()
	bt.text = texto
	bt.custom_minimum_size = Vector2(440, 44)
	_estilo(bt)
	bt.add_theme_font_size_override("font_size", 17)
	if cena == "":
		bt.pressed.connect(func(): get_tree().quit())
	else:
		bt.pressed.connect(func():
			if modo != "":
				Sessao.modo = modo
			get_tree().change_scene_to_file(cena))
	return bt
