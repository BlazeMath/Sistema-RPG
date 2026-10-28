## Tela de criação de heróis (versão de teste 0.7).
##
## O jogador escolhe nome, classe, raça, background, XP (0 a 10), distribui os
## atributos (3, 3, 2, 2, 1, 1, 1, 0, 0) e, numa tela própria, as perícias
## (quatro com 3, seis com 2, oito com 1; o resto 0). Depois escolhe as cartas de habilidade
## (até o XP), duas metades de carta de herói e os itens comuns. Os heróis ficam
## salvos no computador e podem ser levados para o X1 ou para a arena.
extends Control

const Personagem := preload("res://core/personagem.gd")
const Catalogo := preload("res://core/catalogo.gd")
const Efeitos := preload("res://core/efeitos.gd")
const Itens := preload("res://core/itens.gd")
const Devocoes := preload("res://core/devocoes.gd")
const Sessao := preload("res://core/sessao.gd")

const COR_FUNDO := Color("121116")
const COR_PAINEL := Color("1c1b22")
const COR_BORDA := Color("34323d")
const COR_TEXTO := Color("e9e4d8")
const COR_SECUNDARIO := Color("9a95a3")
const COR_OURO := Color("c9a45c")
const COR_ERRO := Color("e07a6f")
const COR_OK := Color("8fd18a")

var ficha: Dictionary
var salvos: Array = []
var indice_salvo := -1
var _montando := false

var _lista: ItemList
var _nome: LineEdit
var _classe: OptionButton
var _raca: OptionButton
var _background: OptionButton
var _xp: SpinBox
var _xp_info: Label
var _botoes_atrib := {}   # atributo -> [Button x4]
var _atrib_info: Label
var _arma: OptionButton
var _armadura: OptionButton
var _escudo: OptionButton
var _foco: OptionButton
var _divindade: OptionButton
var _arma2: OptionButton
var _itens_info: Label
var _escolhas_caixa: VBoxContainer
var _escolhas_chaves := []
var _escolhas_temp := {}   # chave -> Array com uma posição por escolha
var _consumiveis := {}    # id -> SpinBox (quantidade; na fase de teste não há preço)
var _cartas_caixa: VBoxContainer
var _erros: Label
var _fonte_negrito: Font
var _pericias_info: Label
var _tela_pericias: PanelContainer
var _pericias_contagem: Label
var _botoes_pericia := {}   # perícia -> [Button x4]
var _grupo_lista: VBoxContainer
var _grupo_info: Label


func _ready() -> void:
	_fonte_negrito = load("res://assets/fontes/DejaVuSans-Bold.ttf")
	theme = _tema()
	salvos = Personagem.carregar_todos()
	ficha = Sessao.ficha_atual().duplicate(true)
	_montar()
	_carregar_na_tela()


# --- Montagem ---------------------------------------------------------------

func _tema() -> Theme:
	var t := Theme.new()
	t.default_font = load("res://assets/fontes/DejaVuSans.ttf")
	t.default_font_size = 14
	for tipo in ["Label", "CheckBox", "Button", "OptionButton", "LineEdit", "ItemList"]:
		t.set_color("font_color", tipo, COR_TEXTO)
	var normal := _caixa(Color("2a2833"), COR_OURO.darkened(0.35), 6, 6)
	var foco := _caixa(Color("34313f"), COR_OURO, 6, 6)
	var desligado := _caixa(Color("1f1e25"), COR_BORDA, 6, 6)
	var apertado := _caixa(Color("5a4a2a"), COR_OURO, 6, 6)
	for tipo in ["Button", "OptionButton"]:
		t.set_stylebox("normal", tipo, normal)
		t.set_stylebox("hover", tipo, foco)
		t.set_stylebox("focus", tipo, foco)
		t.set_stylebox("pressed", tipo, apertado)
		t.set_stylebox("disabled", tipo, desligado)
		t.set_color("font_disabled_color", tipo, Color("5d5a66"))
		t.set_color("font_pressed_color", tipo, Color.WHITE)
	t.set_stylebox("normal", "LineEdit", _caixa(Color("2a2833"), COR_BORDA, 6, 6))
	t.set_stylebox("panel", "ItemList", _caixa(Color("17161c"), COR_BORDA, 6, 6))
	t.set_color("font_disabled_color", "CheckBox", Color("6a6672"))
	return t


func _caixa(fundo: Color, borda: Color, raio := 10, margem := 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fundo
	sb.border_color = borda
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(raio)
	sb.set_content_margin_all(margem)
	return sb


func _painel() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _caixa(COR_PAINEL, COR_BORDA, 10, 12))
	return p


func _label(texto: String, tamanho := 14, cor := COR_TEXTO, negrito := false) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	if negrito:
		l.add_theme_font_override("font", _fonte_negrito)
	return l


func _botao(texto: String, f: Callable, largura := 0) -> Button:
	var b := Button.new()
	b.text = texto
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(largura, 34)
	b.pressed.connect(f)
	return b


func _opcoes(lista: Array, disponiveis: Array) -> OptionButton:
	var o := OptionButton.new()
	o.focus_mode = Control.FOCUS_NONE
	for i in lista.size():
		var nome: String = lista[i]
		o.add_item(nome if nome in disponiveis else nome + " (em breve)")
		o.set_item_disabled(i, not nome in disponiveis)
	return o


func _montar() -> void:
	var fundo := ColorRect.new()
	fundo.color = COR_FUNDO
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	var margem := MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 12)
	add_child(margem)
	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 10)
	margem.add_child(raiz)

	var topo := HBoxContainer.new()
	var titulo := _label("SISTEMA 21 · Criação de heróis", 22, COR_OURO)
	titulo.add_theme_font_override("font", load("res://assets/fontes/DejaVuSerif-Bold.ttf"))
	topo.add_child(titulo)
	var esp := Control.new()
	esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(esp)
	topo.add_child(_label("Versão 0.23: vila para explorar, masmorra longa, armadilhas, chefes novos, levantar caídos", 13, COR_SECUNDARIO))
	topo.add_child(_botao("Voltar ao menu", func(): get_tree().change_scene_to_file("res://ui/main.tscn"), 150))
	raiz.add_child(topo)

	var colunas := HBoxContainer.new()
	colunas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	colunas.add_theme_constant_override("separation", 12)
	raiz.add_child(colunas)

	# Coluna 1: heróis salvos
	var p1 := _painel()
	p1.custom_minimum_size = Vector2(250, 0)
	colunas.add_child(p1)
	var v1 := VBoxContainer.new()
	v1.add_theme_constant_override("separation", 8)
	p1.add_child(v1)
	v1.add_child(_label("Heróis salvos", 15, COR_OURO, true))
	_lista = ItemList.new()
	_lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lista.item_selected.connect(_ao_escolher_salvo)
	v1.add_child(_lista)
	var h_lista := HBoxContainer.new()
	h_lista.add_child(_botao("Novo", _novo, 110))
	h_lista.add_child(_botao("Excluir", _excluir, 110))
	v1.add_child(h_lista)
	v1.add_child(_label("Grupo (até 4 heróis)", 15, COR_OURO, true))
	_grupo_lista = VBoxContainer.new()
	_grupo_lista.add_theme_constant_override("separation", 2)
	v1.add_child(_grupo_lista)
	_grupo_info = _label("", 11, COR_SECUNDARIO)
	_grupo_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_grupo_info.custom_minimum_size = Vector2(220, 0)
	v1.add_child(_grupo_info)
	v1.add_child(_label("Testar este herói sozinho:", 13, COR_SECUNDARIO, true))
	v1.add_child(_botao("Exploração: a trilha do riacho", func(): _jogar("trilha")))
	v1.add_child(_botao("X1 contra o Chefe Goblin", func(): _jogar("x1")))
	v1.add_child(_botao("Arena contra 3 goblins", func(): _jogar("arena")))
	v1.add_child(_botao("Missão: a fazenda Vale Seco", func(): _jogar("fazenda")))
	v1.add_child(_botao("Missão: a cripta (escura)", func(): _jogar("masmorra")))
	v1.add_child(_botao("Missão: o pântano (noite)", func(): _jogar("pantano")))

	# Coluna 2: ficha
	var p2 := _painel()
	p2.custom_minimum_size = Vector2(430, 0)
	colunas.add_child(p2)
	var rolagem2 := ScrollContainer.new()
	rolagem2.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p2.add_child(rolagem2)
	var v2 := VBoxContainer.new()
	v2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v2.add_theme_constant_override("separation", 6)
	rolagem2.add_child(v2)
	v2.add_child(_label("Ficha", 15, COR_OURO, true))
	_nome = LineEdit.new()
	_nome.placeholder_text = "Nome do herói"
	_nome.text_changed.connect(func(t): ficha["nome"] = t; _validar())
	v2.add_child(_nome)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 6)
	g.add_child(_label("Classe"))
	_classe = _opcoes(Personagem.CLASSES, Personagem.DISPONIVEIS)
	_classe.item_selected.connect(func(i): _mudar_origem("classe", Personagem.CLASSES[i]))
	g.add_child(_classe)
	g.add_child(_label("Raça"))
	_raca = _opcoes(Personagem.RACAS, Personagem.DISPONIVEIS)
	_raca.item_selected.connect(func(i): _mudar_origem("raca", Personagem.RACAS[i]))
	g.add_child(_raca)
	g.add_child(_label("Background"))
	_background = _opcoes(Personagem.BACKGROUNDS, Personagem.DISPONIVEIS)
	_background.item_selected.connect(func(i): _mudar_origem("background", Personagem.BACKGROUNDS[i]))
	g.add_child(_background)
	g.add_child(_label("XP"))
	var h_xp := HBoxContainer.new()
	_xp = SpinBox.new()
	_xp.min_value = 0
	_xp.max_value = 10
	_xp.value_changed.connect(func(v): ficha["xp"] = int(v); _validar())
	h_xp.add_child(_xp)
	_xp_info = _label("", 13, COR_SECUNDARIO)
	h_xp.add_child(_xp_info)
	g.add_child(h_xp)
	v2.add_child(g)

	v2.add_child(_label("Atributos: dois 3, dois 2, três 1 e dois 0", 13, COR_OURO, true))
	var ga := GridContainer.new()
	ga.columns = 2
	ga.add_theme_constant_override("v_separation", 1)
	for a in Personagem.ATRIBUTOS:
		# (i) com o que o atributo dá (0.21)
		var l := _label(Personagem.NOMES_ATRIBUTOS[a] + "  ⓘ", 13)
		l.custom_minimum_size = Vector2(110, 0)
		var e: Dictionary = Personagem.EFEITOS_ATRIBUTO.get(a, {})
		l.tooltip_text = "%s\n3: %s\n5: %s" % [e.get("base", ""), e.get(3, "") if str(e.get(3, "")) != "" else "—", e.get(5, "")]
		l.mouse_filter = Control.MOUSE_FILTER_STOP
		ga.add_child(l)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 4)
		var lista := []
		for v in 4:
			var bt := Button.new()
			bt.text = str(v)
			bt.toggle_mode = true
			bt.focus_mode = Control.FOCUS_NONE
			bt.custom_minimum_size = Vector2(34, 22)
			bt.add_theme_font_size_override("font_size", 12)
			bt.pressed.connect(func(): _definir_atributo(a, v))
			h.add_child(bt)
			lista.append(bt)
		_botoes_atrib[a] = lista
		ga.add_child(h)
	v2.add_child(ga)
	_atrib_info = _label("", 12, COR_SECUNDARIO)
	_atrib_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_atrib_info.custom_minimum_size = Vector2(400, 0)
	v2.add_child(_atrib_info)

	v2.add_child(_label("Perícias: quatro com 3, seis com 2 e oito com 1", 13, COR_OURO, true))
	_pericias_info = _label("", 12, COR_SECUNDARIO)
	_pericias_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pericias_info.custom_minimum_size = Vector2(400, 0)
	v2.add_child(_pericias_info)
	v2.add_child(_botao("Escolher perícias", _abrir_pericias, 200))

	v2.add_child(_label("Itens comuns", 13, COR_OURO, true))
	var gi := GridContainer.new()
	gi.columns = 2
	gi.add_theme_constant_override("h_separation", 10)
	gi.add_child(_label("Arma"))
	_arma = OptionButton.new()
	for id in Itens.ARMAS:
		var a: Dictionary = Itens.ARMAS[id]
		_arma.add_item("%s (%d + %s)" % [a["nome"], a["dano"], "Des" if Itens.atributo_da_arma(a) == "destreza" else "For"])
		_arma.set_item_metadata(_arma.item_count - 1, id)
	_arma.item_selected.connect(func(i): ficha["arma"] = _arma.get_item_metadata(i); _validar())
	gi.add_child(_arma)
	gi.add_child(_label("Segunda arma"))
	_arma2 = OptionButton.new()
	_arma2.add_item("Nenhuma")
	_arma2.set_item_metadata(0, "nenhuma")
	for id in Itens.ARMAS:
		var a2: Dictionary = Itens.ARMAS[id]
		_arma2.add_item("%s (%d + %s)" % [a2["nome"], a2["dano"], "Des" if Itens.atributo_da_arma(a2) == "destreza" else "For"])
		_arma2.set_item_metadata(_arma2.item_count - 1, id)
	_arma2.tooltip_text = "Guardada. Na batalha, \"Trocar arma\" custa uma ação (duas se uma delas for grande)."
	_arma2.item_selected.connect(func(i): ficha["arma2"] = _arma2.get_item_metadata(i); _validar())
	gi.add_child(_arma2)
	gi.add_child(_label("Armadura"))
	_armadura = OptionButton.new()
	for id in Itens.ARMADURAS:
		_armadura.add_item(Itens.ARMADURAS[id]["nome"])
		_armadura.set_item_metadata(_armadura.item_count - 1, id)
		_armadura.set_item_tooltip(_armadura.item_count - 1, Itens.ARMADURAS[id]["texto"])
	_armadura.item_selected.connect(func(i): ficha["armadura"] = _armadura.get_item_metadata(i); _validar())
	gi.add_child(_armadura)
	gi.add_child(_label("Escudo"))
	_escudo = OptionButton.new()
	for id in Itens.ESCUDOS:
		var e: Dictionary = Itens.ESCUDOS[id]
		_escudo.add_item(e["nome"] + ("" if e["vida"] == 0 else " (%d de vida, resistência %d)" % [e["vida"], e["resistencia"]]))
		_escudo.set_item_metadata(_escudo.item_count - 1, id)
	_escudo.item_selected.connect(func(i): ficha["escudo"] = _escudo.get_item_metadata(i); _validar())
	gi.add_child(_escudo)
	gi.add_child(_label("Foco mágico"))
	_foco = OptionButton.new()
	_foco.item_selected.connect(func(i): ficha["foco"] = _foco.get_item_metadata(i); _validar())
	gi.add_child(_foco)
	gi.add_child(_label("Divindade (Clérigo)"))
	_divindade = OptionButton.new()
	for id in Devocoes.DIVINDADES:
		var dv: Dictionary = Devocoes.DIVINDADES[id]
		_divindade.add_item("%s · Devoção da %s" % [dv["nome"], dv["devocao"]])
		_divindade.set_item_metadata(_divindade.item_count - 1, id)
		_divindade.set_item_tooltip(_divindade.item_count - 1, dv["texto"])
	_divindade.item_selected.connect(func(i): ficha["divindade"] = _divindade.get_item_metadata(i); _validar())
	gi.add_child(_divindade)
	v2.add_child(gi)
	# Efeitos dos itens escolhidos, à vista (0.21)
	_itens_info = _label("", 12, COR_SECUNDARIO)
	_itens_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_itens_info.custom_minimum_size = Vector2(400, 0)
	v2.add_child(_itens_info)
	var gc := GridContainer.new()
	gc.columns = 4
	for id in Itens.CONSUMIVEIS:
		var c: Dictionary = Itens.CONSUMIVEIS[id]
		var l := _label(c["nome"] + ("" if c["programado"] else " *"), 12)
		l.tooltip_text = c["texto"] + ("" if c["programado"] else "\n* ainda não programado: não tem efeito no jogo")
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		var sb := SpinBox.new()
		sb.min_value = 0
		sb.max_value = 20
		sb.custom_minimum_size = Vector2(64, 0)
		sb.tooltip_text = l.tooltip_text
		sb.value_changed.connect(func(v): _definir_consumivel(id, int(v)))
		_consumiveis[id] = sb
		gc.add_child(l)
		gc.add_child(sb)
	v2.add_child(gc)
	_escolhas_caixa = VBoxContainer.new()
	v2.add_child(_escolhas_caixa)
	var kit := Label.new()
	kit.text = "Todo herói leva o Kit Inicial de Aventura (corda, pé de cabra, pederneira, kit de reparos, kit de acampamento, lanterna, vara de 3 m, espelho) e o item básico da classe."
	kit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kit.custom_minimum_size = Vector2(300, 0)
	kit.add_theme_font_size_override("font_size", 11)
	kit.add_theme_color_override("font_color", Color("9a95a3"))
	v2.add_child(kit)

	# Coluna 3: cartas
	var p3 := _painel()
	p3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p3.custom_minimum_size = Vector2(300, 0)
	colunas.add_child(p3)
	var v3 := VBoxContainer.new()
	p3.add_child(v3)
	v3.add_child(_label("Cartas (passe o mouse para ler o texto)", 15, COR_OURO, true))
	var rolagem := ScrollContainer.new()
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v3.add_child(rolagem)
	_cartas_caixa = VBoxContainer.new()
	_cartas_caixa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cartas_caixa.custom_minimum_size = Vector2(100, 0)
	_cartas_caixa.add_theme_constant_override("separation", 2)
	rolagem.add_child(_cartas_caixa)

	var baixo := HBoxContainer.new()
	baixo.add_theme_constant_override("separation", 12)
	_erros = _label("", 13, COR_ERRO)
	_erros.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_erros.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baixo.add_child(_erros)
	baixo.add_child(_botao("Salvar herói", _salvar, 180))
	raiz.add_child(baixo)


func _montar_cartas() -> void:
	for filho in _cartas_caixa.get_children():
		filho.queue_free()
	_cartas_caixa.add_child(_label("Carta de herói: escolha 2 metades", 13, COR_OURO, true))
	for ent in [ficha["classe"], ficha["raca"], ficha["background"]]:
		for h in Catalogo.herois_de(ent):
			var cb := CheckBox.new()
			var prog := Efeitos.heroi_programado(h)
			var info: Dictionary = Efeitos.HEROIS.get(Catalogo.slug(h["nome"]), {})
			cb.text = "%s · %s%s" % [ent, h["nome"], "" if prog else "  (não programada)"]
			if info.get("parcial", false):
				cb.text += "  (parcial)"
			cb.tooltip_text = "%s\n\nPassiva: %s\nAtivada: %s\nDesencadeada: %s\nAo critar 21: %s\nLimite de fadiga: %d%s" % [
				h.get("descricao", ""), h["passiva"], h["ativada"], h["desencadeada"], h["critico"], h["limite_fadiga"],
				("\n\nObs.: " + info["nota"]) if info.has("nota") else ""]
			cb.disabled = not prog
			cb.clip_text = true
			cb.button_pressed = h["id"] in ficha["herois"]
			cb.focus_mode = Control.FOCUS_NONE
			cb.toggled.connect(func(on): _alternar_lista("herois", h["id"], on, 2))
			_cartas_caixa.add_child(cb)
	for ent in [ficha["classe"], ficha["raca"], ficha["background"]]:
		_cartas_caixa.add_child(_label("Cartas de habilidade · " + ent, 13, COR_OURO, true))
		var grupo_atual := ""
		for c in Catalogo.habilidades_de(ent):
			if c["lados"][0] != null and c["lados"][1] == null and (c["lados"][0].get("texto") == null or str(c["lados"][0]["texto"]).strip_edges() == ""):
				continue   # cartas sem texto (Saltério de Cura, Grimório da Chama Sagrada): não existem na lista final
			var grupo: String = c["grupo"].split("(")[0].strip_edges()
			if grupo != grupo_atual and ent == ficha["classe"]:
				grupo_atual = grupo
				_cartas_caixa.add_child(_label("  " + grupo, 12, COR_SECUNDARIO))
			var cb := CheckBox.new()
			var prog := Efeitos.carta_programada(c)
			var a = c["lados"][0]
			var b = c["lados"][1]
			if c["meia_carta"]:
				cb.text = "%s  (meia carta)" % a["nome"]
			else:
				cb.text = "%s ↔ %s  (%d XP)" % [a["nome"], b["nome"] if b != null else "—", c["xp"]]
			if not prog:
				cb.text += "  (não programada)"
			var nota := Efeitos.nota_carta(c)
			cb.tooltip_text = "Lado A · %s (fadiga %s)\n%s%s%s" % [a["nome"], str(a["limite_fadiga"]), a["texto"],
				("\n\nLado B · %s (fadiga %s)\n%s" % [b["nome"], str(b["limite_fadiga"]), b["texto"]]) if b != null and not c["meia_carta"] else
				"\n\nMeia carta: escolha duas; juntas formam uma carta de 1 XP com um lado de cada.",
				("\n\nObs.: " + nota) if nota != "" else ""]
			cb.disabled = not prog
			cb.clip_text = true
			cb.focus_mode = Control.FOCUS_NONE
			cb.add_theme_font_size_override("font_size", 13)
			var chave := "meias" if c["meia_carta"] else "cartas"
			cb.button_pressed = c["id"] in ficha[chave]
			cb.toggled.connect(func(on): _alternar_lista(chave, c["id"], on, 99))
			_cartas_caixa.add_child(cb)


# --- Estado -----------------------------------------------------------------

func _carregar_na_tela() -> void:
	_montando = true
	_lista.clear()
	for f in salvos:
		_lista.add_item(f["nome"] + ("" if Personagem.validar(f).is_empty() else "  (incompleto)"))
	_montar_grupo()
	if indice_salvo >= 0 and indice_salvo < _lista.item_count:
		_lista.select(indice_salvo)
	_nome.text = ficha["nome"]
	_classe.select(Personagem.CLASSES.find(ficha["classe"]))
	_raca.select(Personagem.RACAS.find(ficha["raca"]))
	_background.select(Personagem.BACKGROUNDS.find(ficha["background"]))
	_xp.value = ficha["xp"]
	for a in Personagem.ATRIBUTOS:
		for v in 4:
			_botoes_atrib[a][v].button_pressed = int(ficha["atributos"][a]) == v
	if not ficha.has("pericias"):
		ficha["pericias"] = {}
	_atualizar_pericias()
	_selecionar_meta(_arma, ficha["arma"])
	_selecionar_meta(_arma2, ficha.get("arma2", "nenhuma"))
	_selecionar_meta(_armadura, ficha["armadura"])
	_selecionar_meta(_escudo, ficha["escudo"])
	_montar_focos()
	_escolhas_chaves = ["?"]
	for id in _consumiveis:
		_consumiveis[id].value = ficha["consumiveis"].count(id)
	_montar_cartas()
	_montando = false
	_validar()


## Trocar classe, raça ou background tira as cartas que não pertencem mais ao herói.
func _mudar_origem(chave: String, valor: String) -> void:
	if _montando:
		return
	ficha[chave] = valor
	if chave == "classe":
		var tipo: String = Itens.TIPO_DE_FOCO.get(valor, "")
		if Itens.FOCOS.get(ficha.get("foco", "nenhum"), {}).get("tipo", "") != tipo:
			ficha["foco"] = Itens.FOCO_DA_CLASSE.get(valor, "nenhum")
			if ficha["foco"] != "nenhum":
				ficha["escudo"] = "nenhum"
				_selecionar_meta(_escudo, "nenhum")
		_montar_focos()
	var origens := [ficha["classe"], ficha["raca"], ficha["background"]]
	for lista in ["cartas", "meias"]:
		ficha[lista] = ficha[lista].filter(func(id): return Catalogo.habilidade(id).get("entidade", "") in origens)
	ficha["herois"] = ficha["herois"].filter(func(id): return Catalogo.heroi(id).get("entidade", "") in origens)
	_montar_cartas()
	_validar()


func _selecionar_meta(o: OptionButton, valor: String) -> void:
	for i in o.item_count:
		if o.get_item_metadata(i) == valor:
			o.select(i)


func _definir_atributo(a: String, v: int) -> void:
	ficha["atributos"][a] = v
	for i in 4:
		_botoes_atrib[a][i].button_pressed = i == v
	_validar()


func _alternar_lista(chave: String, id: String, on: bool, maximo: int) -> void:
	if _montando:
		return
	var lista: Array = ficha[chave]
	if on and not id in lista:
		lista.append(id)
		if lista.size() > maximo:
			lista.pop_front()
			_montar_cartas()
	elif not on:
		lista.erase(id)
	_validar()


func _definir_consumivel(id: String, qtd: int) -> void:
	if _montando:
		return
	while ficha["consumiveis"].count(id) > qtd:
		ficha["consumiveis"].erase(id)
	while ficha["consumiveis"].count(id) < qtd:
		ficha["consumiveis"].append(id)


func _validar() -> bool:
	if _montando:
		return false
	if _itens_info != null:
		var arma: Dictionary = Itens.ARMAS.get(ficha["arma"], {})
		var arma2: Dictionary = Itens.ARMAS.get(ficha.get("arma2", "nenhuma"), {})
		var arm: Dictionary = Itens.ARMADURAS.get(ficha["armadura"], {})
		var esc: Dictionary = Itens.ESCUDOS.get(ficha["escudo"], {})
		var fo: Dictionary = Itens.FOCOS.get(ficha.get("foco", "nenhum"), {})
		var linhas := PackedStringArray()
		linhas.append("%s: %s" % [arma.get("nome", ""), Itens.descricao_arma(arma).replace("\n", " — ")])
		if not arma2.is_empty():
			linhas.append("%s (reserva): %s" % [arma2["nome"], Itens.descricao_arma(arma2).replace("\n", " — ")])
		linhas.append("%s: %s" % [arm.get("nome", ""), arm.get("texto", "")])
		if int(esc.get("vida", 0)) > 0:
			linhas.append("%s: %d de vida, resistência %d; ocupa uma mão." % [esc["nome"], esc["vida"], esc["resistencia"]])
		if fo.get("tipo", "") != "":
			linhas.append("%s: dano %d, limite %d de fadiga. %s" % [fo["nome"], int(fo.get("dano", 0)), int(fo.get("limite", 0)), fo.get("texto", "")])
		_itens_info.text = "\n".join(linhas)
	var usado := Personagem.custo_xp(ficha)
	_xp_info.text = "  usado pelas cartas: %d de %d" % [usado, ficha["xp"]]
	var contagem := {0: 0, 1: 0, 2: 0, 3: 0}
	for a in Personagem.ATRIBUTOS:
		contagem[int(ficha["atributos"][a])] += 1
	var faltas := PackedStringArray()
	for v in [3, 2, 1, 0]:
		var esperado: int = Personagem.DISTRIBUICAO.count(v)
		if contagem[v] != esperado:
			faltas.append("%d×%d (tem %d)" % [esperado, v, contagem[v]])
	_atrib_info.text = ("Distribuição certa. " if faltas.is_empty() else "Falta acertar: " + ", ".join(faltas) + ". ") + _efeitos_atributos()
	if Personagem.escolhas_pendentes(ficha) != _escolhas_chaves:
		_montar_escolhas()
	var erros := Personagem.validar(ficha)
	if erros.is_empty() and ficha["classe"] in ["Mago", "Clérigo"] and ficha.get("foco", "nenhum") == "nenhum":
		erros = ["Sem foco mágico o herói não faz ataques mágicos (escolha varinha, orbe, cajado ou símbolo sagrado)."]
		_erros.text = erros[0]
		_erros.add_theme_color_override("font_color", COR_OURO)
		return true
	if erros.is_empty():
		_erros.text = "Ficha pronta para salvar e jogar."
		_erros.add_theme_color_override("font_color", COR_OK)
	else:
		_erros.text = " · ".join(PackedStringArray(erros))
		_erros.add_theme_color_override("font_color", COR_ERRO)
	return erros.is_empty()


func _efeitos_atributos() -> String:
	var at: Dictionary = ficha["atributos"]
	var e := PackedStringArray()
	if at["forca"] >= 3:
		e.append("Força %d: dano mesmo errando" % at["forca"])
	if at["destreza"] >= 3:
		e.append("Destreza 3: +1 de Velocidade")
	if at["constituicao"] >= 3:
		e.append("Constituição 3: Regeneração 1")
	if at["percepcao"] >= 3:
		e.append("Percepção 3: a carta fechada do defensor fica à vista")
	if at["sabedoria"] >= 3:
		e.append("Sabedoria 3: +1 ou −1 num teste")
	if at["raciocinio"] >= 3:
		e.append("Raciocínio 3: reordena o topo ao Planejar")
	if at["espirito"] >= 3:
		e.append("Espírito 3: ação Comandar")
	if at["mentira"] >= 3:
		e.append("Mentira 3: uma carta do ataque volta ao baralho")
	e.append("mão inicial %d (2 + Sabedoria)" % (2 + int(at["sabedoria"])))
	e.append("Recuperar o fôlego cura %d" % at["constituicao"])
	if at["espirito"] > 0:
		e.append("descanso curto devolve %d do exílio" % at["espirito"])
	if at["diplomacia"] > 0:
		e.append("Orientar %d× por cena" % at["diplomacia"])
	return "Na batalha: " + "; ".join(e) + "."


func _ao_escolher_salvo(i: int) -> void:
	indice_salvo = i
	ficha = salvos[i].duplicate(true)
	_carregar_na_tela()


func _novo() -> void:
	indice_salvo = -1
	ficha = Personagem.nova()
	ficha["nome"] = ""
	# Lucas (0.23): personagem novo começa com os atributos zerados.
	for a in ficha["atributos"]:
		ficha["atributos"][a] = 0
	_carregar_na_tela()


func _excluir() -> void:
	if indice_salvo < 0:
		return
	salvos.remove_at(indice_salvo)
	Personagem.salvar_todos(salvos)
	_novo()


func _salvar() -> void:
	if not _validar():
		return
	if indice_salvo >= 0:
		salvos[indice_salvo] = ficha.duplicate(true)
	else:
		salvos.append(ficha.duplicate(true))
		indice_salvo = salvos.size() - 1
	Personagem.salvar_todos(salvos)
	Sessao.ficha = ficha.duplicate(true)
	_carregar_na_tela()
	_erros.text = "Herói salvo: %s." % ficha["nome"]
	_erros.add_theme_color_override("font_color", COR_OK)


func _montar_grupo() -> void:
	for f in _grupo_lista.get_children():
		_grupo_lista.remove_child(f)
		f.queue_free()
	var nomes: Array = Sessao.nomes_do_grupo().filter(func(n): return salvos.any(func(f): return f["nome"] == n))
	for f in salvos:
		var cb := CheckBox.new()
		var nome: String = f["nome"]
		var valido := Personagem.validar(f).is_empty()
		cb.text = "%s · %s%s" % [nome, f["classe"], "" if valido else " (incompleto)"]
		cb.button_pressed = nome in nomes
		cb.disabled = not valido or (not nome in nomes and nomes.size() >= Sessao.MAXIMO_GRUPO)
		cb.focus_mode = Control.FOCUS_NONE
		cb.clip_text = true
		cb.add_theme_font_size_override("font_size", 12)
		cb.toggled.connect(func(on): _alternar_grupo(nome, on))
		_grupo_lista.add_child(cb)
	_grupo_info.text = ("Grupo: " + ", ".join(PackedStringArray(nomes))) if not nomes.is_empty() else "Marque até 4 heróis salvos. O grupo vale para os modos do menu; você controla cada um no seu turno."


func _alternar_grupo(nome: String, on: bool) -> void:
	var nomes: Array = Sessao.nomes_do_grupo().duplicate()
	if on and not nome in nomes:
		nomes.append(nome)
	elif not on:
		nomes.erase(nome)
	Sessao.definir_grupo(nomes)
	_montar_grupo()


func _jogar(modo: String) -> void:
	if not _validar():
		return
	Sessao.solo = true
	Sessao.ficha = ficha.duplicate(true)
	Sessao.modo = modo
	get_tree().change_scene_to_file("res://ui/batalha.tscn")



# --- Perícias -----------------------------------------------------------------

func _montar_tela_pericias() -> void:
	_tela_pericias = PanelContainer.new()
	_tela_pericias.add_theme_stylebox_override("panel", _caixa(Color(0.07, 0.07, 0.09, 0.98), COR_OURO, 10, 18))
	_tela_pericias.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tela_pericias.offset_left = 40
	_tela_pericias.offset_right = -40
	_tela_pericias.offset_top = 30
	_tela_pericias.offset_bottom = -30
	add_child(_tela_pericias)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	_tela_pericias.add_child(v)
	var cab := HBoxContainer.new()
	var t := _label("Perícias", 22, COR_OURO, true)
	t.add_theme_font_override("font", load("res://assets/fontes/DejaVuSerif-Bold.ttf"))
	cab.add_child(t)
	var esp := Control.new()
	esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(esp)
	cab.add_child(_botao("Zerar todas", _zerar_pericias, 140))
	cab.add_child(_botao("Concluir", func(): _tela_pericias.visible = false, 140))
	v.add_child(cab)
	var expl := _label("Escolha quatro perícias com 3, seis com 2 e oito com 1. As outras ficam com 0. Num teste, a perícia soma com o atributo e não conta para estourar.", 13, COR_SECUNDARIO)
	expl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(expl)
	_pericias_contagem = _label("", 15, COR_TEXTO, true)
	v.add_child(_pericias_contagem)
	var colunas := HBoxContainer.new()
	colunas.add_theme_constant_override("separation", 28)
	colunas.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(colunas)
	for grupo in Personagem.PERICIAS:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 3)
		col.add_child(_label(grupo, 16, COR_OURO, true))
		for nome in Personagem.PERICIAS[grupo]:
			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 4)
			var l := _label(nome, 13)
			l.custom_minimum_size = Vector2(130, 0)
			h.add_child(l)
			var lista := []
			for valor in 4:
				var bt := Button.new()
				bt.text = str(valor)
				bt.toggle_mode = true
				bt.focus_mode = Control.FOCUS_NONE
				bt.custom_minimum_size = Vector2(34, 24)
				bt.add_theme_font_size_override("font_size", 12)
				bt.pressed.connect(func(): _definir_pericia(nome, valor))
				h.add_child(bt)
				lista.append(bt)
			_botoes_pericia[nome] = lista
			col.add_child(h)
		colunas.add_child(col)
	_tela_pericias.visible = false


func _zerar_pericias() -> void:
	ficha["pericias"] = {}
	_atualizar_pericias()
	_validar()


func _abrir_pericias() -> void:
	if _tela_pericias == null:
		_montar_tela_pericias()
	_atualizar_pericias()
	_tela_pericias.visible = true


func _definir_pericia(nome: String, valor: int) -> void:
	var atual := int(ficha["pericias"].get(nome, 0))
	var cont := Personagem.contagem_pericias(ficha)
	if valor > 0 and valor != atual and cont[valor] >= Personagem.DISTRIBUICAO_PERICIAS[valor]:
		_atualizar_pericias()
		return
	if valor == 0:
		ficha["pericias"].erase(nome)
	else:
		ficha["pericias"][nome] = valor
	_atualizar_pericias()
	_validar()


func _atualizar_pericias() -> void:
	var cont := Personagem.contagem_pericias(ficha)
	var partes := PackedStringArray()
	for valor in [3, 2, 1]:
		partes.append("com %d: %d de %d" % [valor, cont[valor], Personagem.DISTRIBUICAO_PERICIAS[valor]])
	var resumo := PackedStringArray()
	for valor in [3, 2, 1]:
		var nomes := PackedStringArray()
		for grupo in Personagem.PERICIAS:
			for nome in Personagem.PERICIAS[grupo]:
				if int(ficha["pericias"].get(nome, 0)) == valor:
					nomes.append(nome)
		if not nomes.is_empty():
			resumo.append("%d: %s" % [valor, ", ".join(nomes)])
	if _pericias_info != null:
		_pericias_info.text = (" · ".join(partes) + "\n" + "\n".join(resumo)) if not resumo.is_empty() else "Nenhuma perícia escolhida (" + " · ".join(partes) + ")."
	if _pericias_contagem != null:
		_pericias_contagem.text = "   ·   ".join(partes)
	for nome in _botoes_pericia:
		var atual := int(ficha["pericias"].get(nome, 0))
		for valor in 4:
			var bt: Button = _botoes_pericia[nome][valor]
			bt.button_pressed = valor == atual
			bt.disabled = valor > 0 and valor != atual and cont[valor] >= Personagem.DISTRIBUICAO_PERICIAS[valor]


## Cartas como Mente Maleável e Mil Ofícios pedem escolhas de perícia ou atributo.
func _montar_escolhas() -> void:
	for f in _escolhas_caixa.get_children():
		_escolhas_caixa.remove_child(f)
		f.queue_free()
	_escolhas_chaves = Personagem.escolhas_pendentes(ficha)
	if not ficha.has("escolhas"):
		ficha["escolhas"] = {}
	for chave in ficha["escolhas"].keys():
		if not chave in _escolhas_chaves:
			ficha["escolhas"].erase(chave)
	var pericias := []
	for grupo in Personagem.PERICIAS:
		pericias.append_array(Personagem.PERICIAS[grupo])
	for chave in _escolhas_chaves:
		var e: Dictionary = Personagem.ESCOLHAS[chave]
		_escolhas_caixa.add_child(_label(e["texto"], 12, COR_OURO))
		var feitas: Array = ficha["escolhas"].get(chave, [])
		var temp := []
		var linha := HBoxContainer.new()
		for k in int(e["qtd"]):
			temp.append(feitas[k] if k < feitas.size() else "")
			var o := OptionButton.new()
			o.add_theme_font_size_override("font_size", 12)
			o.add_item("—")
			o.set_item_metadata(0, "")
			var lista_op: Array = e.get("opcoes", pericias)
			if e.has("menor_que"):
				lista_op = lista_op.filter(func(pp): return int(ficha.get("pericias", {}).get(pp, 0)) < int(e["menor_que"]) or pp in feitas)
			for op in lista_op:
				o.add_item(Personagem.NOMES_ATRIBUTOS.get(op, op))
				o.set_item_metadata(o.item_count - 1, op)
			_selecionar_meta(o, temp[k])
			var kk := k
			o.item_selected.connect(func(i): _definir_escolha(chave, kk, o.get_item_metadata(i)))
			linha.add_child(o)
		_escolhas_temp[chave] = temp
		_escolhas_caixa.add_child(linha)


func _definir_escolha(chave: String, k: int, valor: String) -> void:
	_escolhas_temp[chave][k] = valor
	var lista := []
	for v in _escolhas_temp[chave]:
		if v != "" and not v in lista:
			lista.append(v)
	ficha["escolhas"][chave] = lista
	_validar()


## Só os focos do tipo da classe (arcano: Mago; sagrado: Clérigo).
func _montar_focos() -> void:
	_foco.clear()
	var tipo: String = Itens.TIPO_DE_FOCO.get(ficha["classe"], "")
	for id in Itens.FOCOS:
		var fo: Dictionary = Itens.FOCOS[id]
		if fo["tipo"] != "" and fo["tipo"] != tipo:
			continue
		_foco.add_item(fo["nome"] + ("" if id == "nenhum" else " (+%d de dano mágico, %d mão%s)" % [fo["dano"], fo["maos"], "s" if int(fo["maos"]) > 1 else ""]))
		_foco.set_item_metadata(_foco.item_count - 1, id)
		_foco.set_item_tooltip(_foco.item_count - 1, fo["texto"] + ("" if id == "nenhum" else "\nLimite de fadiga %d." % int(fo.get("limite", 0))))
	_foco.disabled = tipo == ""
	_selecionar_meta(_foco, ficha.get("foco", "nenhum"))
	_divindade.disabled = ficha["classe"] != "Clérigo"
	_selecionar_meta(_divindade, ficha.get("divindade", Devocoes.PADRAO))
