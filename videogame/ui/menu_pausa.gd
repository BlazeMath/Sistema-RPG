## Menu de pausa (0.18): Esc dentro das fases e da vila.
## Continuar, configurações (música, tela cheia e opções da tela que abriu o menu),
## salvar o jogo (quando a tela permite), voltar ao menu principal e sair do jogo.
extends CanvasLayer

const COR_OURO := Color("c9a45c")
const COR_TEXTO := Color("e9e4d8")
const COR_SECUNDARIO := Color("9a95a3")
const ARQUIVO_CONFIG := "user://config.json"

## Opções extras da tela que abriu: [{"texto", "valor": bool, "ao_mudar": Callable}]
var opcoes_extras: Array = []
## Botões extras da tela que abriu: [{"texto", "acao": Callable}] (ex.: Recomeçar a missão)
var botoes_extras: Array = []
## Se não vazio, mostra "Salvar jogo" e chama isto; "motivo_sem_salvar" explica quando não dá.
var ao_salvar: Callable
var motivo_sem_salvar := ""

var _fundo: ColorRect
var _caixa: VBoxContainer
var _config: VBoxContainer
var _aviso: Label
var _fonte: Font


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fonte = load("res://assets/fontes/DejaVuSans.ttf")
	_fundo = ColorRect.new()
	_fundo.color = Color(0, 0, 0, 0.66)
	_fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_fundo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fundo.add_child(centro)
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("1c1b22")
	sb.border_color = COR_OURO
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(22)
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(420, 0)
	centro.add_child(p)
	_caixa = VBoxContainer.new()
	_caixa.add_theme_constant_override("separation", 10)
	p.add_child(_caixa)
	visible = false


func abrir() -> void:
	_montar()
	visible = true


func fechar() -> void:
	visible = false


func _montar() -> void:
	for f in _caixa.get_children():
		f.queue_free()
	var t := _texto("PAUSA", 26, COR_OURO)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_override("font", load("res://assets/fontes/DejaVuSerif-Bold.ttf"))
	_caixa.add_child(t)
	_caixa.add_child(_botao("Continuar (Esc)", fechar))
	_caixa.add_child(_botao("Configurações", func(): _config.visible = not _config.visible))
	_config = VBoxContainer.new()
	_config.add_theme_constant_override("separation", 6)
	_config.visible = false
	_caixa.add_child(_config)
	_montar_config()
	if ao_salvar.is_valid():
		var bs := _botao("Salvar o jogo", func():
			_aviso.text = ao_salvar.call())
		_caixa.add_child(bs)
	elif motivo_sem_salvar != "":
		var bs := _botao("Salvar o jogo", func(): pass)
		bs.disabled = true
		bs.tooltip_text = motivo_sem_salvar
		_caixa.add_child(bs)
		var nota := _texto(motivo_sem_salvar, 11, COR_SECUNDARIO)
		nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nota.custom_minimum_size = Vector2(380, 0)
		_caixa.add_child(nota)
	for be in botoes_extras:
		var acao_be: Callable = be["acao"]
		_caixa.add_child(_botao(be["texto"], func():
			fechar()
			acao_be.call()))
	_caixa.add_child(_botao("Voltar ao menu principal", func():
		visible = false
		get_tree().change_scene_to_file("res://ui/main.tscn")))
	_caixa.add_child(_botao("Sair do jogo", func(): get_tree().quit()))
	_aviso = _texto("", 12, COR_TEXTO)
	_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aviso.custom_minimum_size = Vector2(380, 0)
	_caixa.add_child(_aviso)


func _montar_config() -> void:
	var musica = get_node_or_null("/root/Musica")
	if musica != null:
		var h := HBoxContainer.new()
		h.add_child(_texto("Volume da música", 13, COR_TEXTO))
		var s := HSlider.new()
		s.min_value = 0
		s.max_value = 100
		s.value = musica.volume * 100
		s.custom_minimum_size = Vector2(180, 20)
		s.focus_mode = Control.FOCUS_NONE
		s.value_changed.connect(func(v): musica.definir_volume(v / 100.0))
		h.add_child(s)
		_config.add_child(h)
		_config.add_child(_caixinha("Música desligada (tecla M)", musica.mudo, func(on):
			if on != musica.mudo:
				musica.alternar_mudo()))
	_config.add_child(_caixinha("Tela cheia", DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN, func(on):
		definir_tela_cheia(on)))
	for o in opcoes_extras:
		_config.add_child(_caixinha(o["texto"], bool(o["valor"]), o["ao_mudar"]))


static func definir_tela_cheia(on: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)
	var f := FileAccess.open(ARQUIVO_CONFIG, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"tela_cheia": on}))


static func aplicar_config_salva() -> void:
	if not FileAccess.file_exists(ARQUIVO_CONFIG):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(ARQUIVO_CONFIG))
	if d is Dictionary and d.get("tela_cheia", false) and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _unhandled_input(evento: InputEvent) -> void:
	if visible and evento is InputEventKey and evento.pressed and not evento.echo and evento.keycode == KEY_ESCAPE:
		fechar()
		get_viewport().set_input_as_handled()


func _texto(t: String, tamanho: int, cor: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", _fonte)
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	return l


func _caixinha(texto: String, valor: bool, ao_mudar: Callable) -> CheckBox:
	var cb := CheckBox.new()
	cb.text = texto
	cb.button_pressed = valor
	cb.focus_mode = Control.FOCUS_NONE
	cb.add_theme_font_override("font", _fonte)
	cb.toggled.connect(ao_mudar)
	return cb


func _botao(texto: String, acao: Callable) -> Button:
	var bt := Button.new()
	bt.text = texto
	bt.focus_mode = Control.FOCUS_NONE
	bt.custom_minimum_size = Vector2(380, 38)
	bt.add_theme_font_override("font", _fonte)
	bt.add_theme_font_size_override("font_size", 15)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("2a2833")
	sb.border_color = Color("8d733f")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	var sb2 := sb.duplicate()
	sb2.bg_color = Color("34313f")
	sb2.border_color = COR_OURO
	bt.add_theme_stylebox_override("normal", sb)
	bt.add_theme_stylebox_override("hover", sb2)
	bt.add_theme_stylebox_override("pressed", sb2)
	bt.add_theme_color_override("font_color", COR_TEXTO)
	bt.pressed.connect(acao)
	return bt
