## Monte de cartas viradas (o baralho na mesa). Clicável quando o jogador pode puxar.
extends Control

signal clicado

const COR_VERSO := Color("5a1e24")
const COR_OURO := Color("c9a45c")
const COR_TEXTO := Color("e9e4d8")

var TAM_CARTA := Vector2(70, 100)
const CAMADAS := 4
const DESLOCAMENTO := 3.0

var quantidade := 52
var clicavel := false
var dica_padrao := ""
var _sobre := false
var _fonte: Font


func _init() -> void:
	definir_tamanho(TAM_CARTA)
	mouse_entered.connect(_ao_entrar)
	mouse_exited.connect(_ao_sair)


func definir_tamanho(t: Vector2) -> void:
	TAM_CARTA = t
	custom_minimum_size = Vector2(t.x + CAMADAS * DESLOCAMENTO + 4, t.y + CAMADAS * DESLOCAMENTO + 4)
	queue_redraw()


func _ao_entrar() -> void:
	_sobre = true
	queue_redraw()


func _ao_sair() -> void:
	_sobre = false
	queue_redraw()


func _ready() -> void:
	_fonte = load("res://assets/fontes/DejaVuSans-Bold.ttf")


func configurar(qtd: int, pode_clicar: bool) -> void:
	quantidade = qtd
	clicavel = pode_clicar and qtd > 0
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if clicavel else Control.CURSOR_ARROW
	tooltip_text = "Puxar uma carta (Espaço)" if clicavel else dica_padrao
	queue_redraw()


func _draw() -> void:
	var camadas := clampi(int(ceil(quantidade / 13.0)), 0, CAMADAS)
	if quantidade == 0:
		var vazio := StyleBoxFlat.new()
		vazio.bg_color = Color(0, 0, 0, 0)
		vazio.border_color = Color(1, 1, 1, 0.15)
		vazio.set_border_width_all(2)
		vazio.set_corner_radius_all(8)
		draw_style_box(vazio, Rect2(Vector2(2, CAMADAS * DESLOCAMENTO + 2), TAM_CARTA))
		_texto_central(Rect2(Vector2(2, CAMADAS * DESLOCAMENTO + 2), TAM_CARTA), "vazio", 12, Color(1, 1, 1, 0.3))
		return
	var levanta := 3.0 if (_sobre and clicavel) else 0.0
	for i in camadas:
		var topo := i == camadas - 1
		var pos := Vector2(2 + i * DESLOCAMENTO, 2 + (CAMADAS - i) * DESLOCAMENTO - (levanta if topo else 0.0))
		var sb := StyleBoxFlat.new()
		sb.bg_color = COR_VERSO.lightened(0.12) if (topo and _sobre and clicavel) else COR_VERSO.darkened(0.25 * (camadas - 1 - i) / CAMADAS)
		sb.border_color = COR_OURO if (topo and clicavel) else COR_OURO.darkened(0.5)
		sb.set_border_width_all(3 if (topo and clicavel and _sobre) else 2)
		sb.set_corner_radius_all(8)
		draw_style_box(sb, Rect2(pos, TAM_CARTA))
		if topo:
			var r := Rect2(pos, TAM_CARTA)
			var k := TAM_CARTA.y / 100.0
			_texto_central(Rect2(r.position + Vector2(0, -14 * k), r.size), "21", int(24 * k), COR_OURO.darkened(0.1))
			_texto_central(Rect2(r.position + Vector2(0, 18 * k), r.size), str(quantidade), int(15 * k), COR_TEXTO)
			if clicavel:
				_texto_central(Rect2(r.position + Vector2(0, 38 * k), r.size), "puxar", maxi(int(11 * k), 10), COR_OURO)


func _texto_central(r: Rect2, texto: String, tamanho: int, cor: Color) -> void:
	var fonte := _fonte if _fonte != null else ThemeDB.fallback_font
	var largura := fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x
	var base := r.position + Vector2((r.size.x - largura) / 2.0, r.size.y / 2.0 + tamanho / 3.0)
	draw_string(fonte, base, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, cor)


func _gui_input(evento: InputEvent) -> void:
	var clique := evento as InputEventMouseButton
	if clicavel and clique != null and clique.pressed and clique.button_index == MOUSE_BUTTON_LEFT:
		clicado.emit()
		accept_event()
