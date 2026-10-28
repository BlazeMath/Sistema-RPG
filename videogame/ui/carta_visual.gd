## Desenho de uma carta de baralho comum (frente ou verso), feito só com código.
extends PanelContainer

signal clicada(carta: int)

const Carta := preload("res://core/carta.gd")

const COR_FRENTE := Color("f3ecdc")
const COR_BORDA := Color("c9bfa6")
const COR_VERMELHO := Color("b3262e")
const COR_PRETO := Color("1d1d22")
const COR_VERSO := Color("5a1e24")
const COR_OURO := Color("c9a45c")

var carta := -1
var para_baixo := false
var clicavel := false

var _posto: Label
var _naipe: Label
var _rotulo: Label
var _estilo: StyleBoxFlat


func configurar(c: int, virada: bool, rotulo: String, tamanho: Vector2, pode_clicar := false) -> void:
	carta = c
	para_baixo = virada
	clicavel = pode_clicar
	custom_minimum_size = tamanho
	_montar(tamanho)


func _montar(tamanho: Vector2) -> void:
	for filho in get_children():
		filho.queue_free()
	_estilo = StyleBoxFlat.new()
	_estilo.set_corner_radius_all(8)
	_estilo.set_border_width_all(2)
	_estilo.set_content_margin_all(4)
	_estilo.bg_color = COR_VERSO if para_baixo else COR_FRENTE
	_estilo.border_color = COR_OURO if para_baixo else COR_BORDA
	add_theme_stylebox_override("panel", _estilo)

	var caixa := VBoxContainer.new()
	caixa.alignment = BoxContainer.ALIGNMENT_CENTER
	caixa.add_theme_constant_override("separation", 0)
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caixa)

	var escala := tamanho.y / 108.0
	_posto = _label(caixa, int(30 * escala))
	_naipe = _label(caixa, int(26 * escala))
	if para_baixo:
		_posto.text = "21"
		_posto.add_theme_color_override("font_color", COR_OURO.darkened(0.15))
		_naipe.text = "?"
		_naipe.add_theme_color_override("font_color", COR_OURO.darkened(0.35))
	else:
		var cor := COR_VERMELHO if Carta.naipe(carta) in [1, 2] else COR_PRETO
		_posto.text = Carta.NOMES_POSTO[Carta.posto(carta)]
		_naipe.text = Carta.NAIPES[Carta.naipe(carta)]
		_posto.add_theme_color_override("font_color", cor)
		_naipe.add_theme_color_override("font_color", cor)
	_rotulo = _label(caixa, int(11 * escala))
	_rotulo.text = ""
	_rotulo.add_theme_color_override("font_color", COR_OURO if para_baixo else Color("6b6457"))

	mouse_filter = Control.MOUSE_FILTER_STOP if clicavel else Control.MOUSE_FILTER_IGNORE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if clicavel else Control.CURSOR_ARROW
	if clicavel:
		_estilo.border_color = COR_OURO
		tooltip_text = "Jogar esta carta no teste"


func definir_rotulo(texto: String) -> void:
	_rotulo.text = texto


func _label(pai: Control, tamanho: int) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tamanho)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(l)
	return l


func _ready() -> void:
	mouse_entered.connect(_ao_entrar)
	mouse_exited.connect(_ao_sair)


func _ao_entrar() -> void:
	if clicavel:
		_estilo.bg_color = Color("fffaf0")
		_estilo.set_border_width_all(3)


func _ao_sair() -> void:
	if clicavel:
		_estilo.bg_color = COR_FRENTE
		_estilo.set_border_width_all(2)


func _gui_input(evento: InputEvent) -> void:
	var clique := evento as InputEventMouseButton
	if clicavel and clique != null and clique.pressed and clique.button_index == MOUSE_BUTTON_LEFT:
		clicada.emit(carta)
