## Janela de jogos salvos (0.18): 3 espaços. modo "salvar" (vila) ou "carregar" (menu e vila).
extends CanvasLayer

const Salvamento := preload("res://core/salvamento.gd")
const COR_OURO := Color("c9a45c")
const COR_TEXTO := Color("e9e4d8")
const COR_SECUNDARIO := Color("9a95a3")

var modo := "carregar"
var depois_de_carregar: Callable   # ex.: ir para a vila
var batalha_atual = null           # salvar no meio da missão (ponto de descanso)

var _caixa: VBoxContainer
var _aviso: Label
var _fonte: Font


func _ready() -> void:
	layer = 60
	_fonte = load("res://assets/fontes/DejaVuSans.ttf")
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.7)
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fundo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	fundo.add_child(centro)
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("1c1b22")
	sb.border_color = COR_OURO
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(20)
	p.add_theme_stylebox_override("panel", sb)
	centro.add_child(p)
	_caixa = VBoxContainer.new()
	_caixa.add_theme_constant_override("separation", 10)
	p.add_child(_caixa)
	visible = false


func abrir(m: String) -> void:
	modo = m
	_montar("")
	visible = true


func _montar(aviso: String) -> void:
	for f in _caixa.get_children():
		f.queue_free()
	_caixa.add_child(_texto("Salvar o jogo" if modo == "salvar" else "Carregar um jogo", 22, COR_OURO))
	for e in range(1, Salvamento.ESPACOS + 1):
		var r := Salvamento.resumo(e)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		var txt := "Espaço %d: vazio" % e
		if not r.is_empty():
			var c: Dictionary = r.get("campanha", {})
			var onde := "na vila" if not r.has("missao") else "em missão: %s" % r["missao"].get("nome", "")
			txt = "Espaço %d · %s · %s\n%s · ouro %d · missões cumpridas: %d" % [e, r.get("data", ""), onde,
				", ".join(PackedStringArray(r.get("herois", []).map(func(x): return "%s (%s)" % [x["nome"], x["classe"]]))),
				int(c.get("ouro", 0)), c.get("concluidas", []).size()]
		var l := _texto(txt, 13, COR_TEXTO if not r.is_empty() else COR_SECUNDARIO)
		l.custom_minimum_size = Vector2(440, 0)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		h.add_child(l)
		var esp := e
		if modo == "salvar":
			h.add_child(_botao("Salvar aqui", func():
				var agora := Time.get_datetime_string_from_system(false, true)
				_montar(Salvamento.salvar(esp, agora, batalha_atual))))
		else:
			var b := _botao("Carregar", func():
				var msg := Salvamento.carregar(esp)
				visible = false
				if Salvamento.Sessao.estado_salvo != "":
					get_tree().change_scene_to_file("res://ui/batalha.tscn")
					return
				if depois_de_carregar.is_valid():
					depois_de_carregar.call(msg))
			b.disabled = r.is_empty()
			h.add_child(b)
		_caixa.add_child(h)
	_aviso = _texto(aviso, 13, COR_OURO)
	_caixa.add_child(_aviso)
	_caixa.add_child(_botao("Fechar", func(): visible = false))


func _texto(t: String, tamanho: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", _fonte)
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	return l


func _botao(texto: String, acao: Callable) -> Button:
	var bt := Button.new()
	bt.text = texto
	bt.focus_mode = Control.FOCUS_NONE
	bt.custom_minimum_size = Vector2(120, 34)
	bt.add_theme_font_override("font", _fonte)
	bt.pressed.connect(acao)
	return bt
