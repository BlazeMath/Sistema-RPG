## Editor de fases (0.27). Mapa 2D visto de cima: pinta o chão, põe objetos (com
## colisão e visão escolhidas), luzes, o início dos heróis, inimigos, áreas que
## disparam falas, testes, armadilhas ou a chegada, e pontos de interação com
## efeitos. O botão Testar abre a fase no jogo de verdade (3D) com o grupo atual.
## A fase é só dados: core/fase.gd guarda, valida e converte para a Batalha.
extends Control

const Fase := preload("res://core/fase.gd")
const Bestiario := preload("res://core/bestiario.gd")
const Itens := preload("res://core/itens.gd")
const Personagem := preload("res://core/personagem.gd")
const Sessao := preload("res://core/sessao.gd")
const Campanha := preload("res://core/campanha.gd")

const COR_FUNDO := Color("121116")
const COR_PAINEL := Color("1c1b22")
const COR_BORDA := Color("34323d")
const COR_TEXTO := Color("e9e4d8")
const COR_SECUNDARIO := Color("9a95a3")
const COR_OURO := Color("c9a45c")
const COR_AVISO := Color("ffcf8a")
const COR_PATAMAR := {"lacaio": Color("8f8a80"), "medio": Color("d08a3a"), "conjurador": Color("4aa3c9"), "elite": Color("c94a4a"),
	"elite_escoltado": Color("c94a7a"), "chefe": Color("9a5ad0")}
const COR_AREA := {"fala": Color(0.35, 0.6, 1.0), "teste": Color(1.0, 0.75, 0.25), "efeito": Color(0.4, 0.9, 0.6),
	"armadilha": Color(1.0, 0.3, 0.3), "chegada": Color(0.95, 0.95, 0.3)}

## Ferramentas: id -> [rótulo, dica]
const FERRAMENTAS := [
	["selecionar", "Selecionar", "Clique para ver e editar. Arraste um inimigo, interação, luz ou objeto para mudá-lo de lugar."],
	["chao", "Chão", "Pinte o chão. \"Vazio\" apaga a casa (é o formato do mapa). Shift + arrastar = retângulo; Ctrl + clique = balde."],
	["altura", "Altura", "Andares: pinte a altura das casas (como nas Catacumbas). Escadas ligam alturas vizinhas."],
	["objeto", "Objetos", "Escolha o objeto e se ele tem colisão e se bloqueia a visão. Shift + arrastar = retângulo (paredes)."],
	["luz", "Luz", "Ponha uma fonte de luz (para fases escuras). Fogueiras e tochas já iluminam sozinhas."],
	["inicio", "Início", "Onde os heróis começam: 1 é o primeiro herói do grupo, 2 o segundo..."],
	["inimigo", "Inimigos", "Escolha no bestiário e clique no mapa. Depois ajuste no painel da direita."],
	["area", "Áreas", "Pinte as casas de uma área. Quando um herói entra, ela fala, pede um teste, dispara uma armadilha ou cumpre a chegada."],
	["interacao", "Interação", "Ponha um ponto de interação (baú, livro, porta, pessoa...) e crie as opções e os efeitos no painel da direita."],
	["borracha", "Borracha", "Apaga o que estiver na casa (inimigo, interação, luz, objeto, área e início), um por clique."],
]

var fase: Dictionary = {}
var _somente_leitura := false
var _sujo := false
var _ferramenta := "selecionar"
var _pincel := "pedra"
var _obj_colisao := true
var _obj_visao := "padrao"
var _altura := 1
var _selecao := {"tipo": "fase", "id": ""}
var _historico: Array = []
var _futuro: Array = []
var _ultimo_registro := 0
var _zoom := 28.0
var _offset := Vector2(20, 20)
var _arrastando_vista := false
var _pintando := false
var _ret_inicio := Vector2i(-1, -1)
var _casa_mouse := Vector2i(-1, -1)
var _movendo := {}
var _escolhendo_casas: Array = []   # lista viva de casas de um efeito "abrir caminho"
var _problemas: Array = []

var _fonte: Font
var _fonte_negrito: Font
var _grade: Control
var _paleta: VBoxContainer
var _opcoes: VBoxContainer
var _insp: VBoxContainer
var _titulo: Label
var _status: Label
var _dica: Label
var _bts_ferramenta := {}
var _biblioteca: PanelContainer
var _janela: PanelContainer
var _tooltip_casas: Label


func _ready() -> void:
	_fonte = load("res://assets/fontes/DejaVuSans.ttf")
	_fonte_negrito = load("res://assets/fontes/DejaVuSans-Bold.ttf")
	var fundo := ColorRect.new()
	fundo.color = COR_FUNDO
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	_montar_tela()
	var id := Sessao.fase_teste
	Sessao.fase_teste = ""
	if id != "" and not Fase.carregar(id).is_empty():
		_abrir(id)
	else:
		_abrir_fase(Fase.carregar("exemplo_moinho") if not Fase.carregar("exemplo_moinho").is_empty() else Fase.nova(), true)
		_mostrar_biblioteca()
	var musica = get_node_or_null("/root/Musica")
	if musica != null:
		musica.tocar("menu")


# --- Montagem da tela ------------------------------------------------------------------

func _montar_tela() -> void:
	var topo := HBoxContainer.new()
	topo.position = Vector2(8, 6)
	topo.size = Vector2(1264, 36)
	topo.add_theme_constant_override("separation", 6)
	add_child(topo)
	topo.add_child(_botao("Biblioteca", _mostrar_biblioteca))
	topo.add_child(_botao("Nova", _janela_nova))
	topo.add_child(_botao("Salvar", _salvar))
	topo.add_child(_botao("Desfazer", _desfazer))
	topo.add_child(_botao("Refazer", _refazer))
	topo.add_child(_botao("Validar", func(): _validar(true)))
	topo.add_child(_botao("Testar no jogo", _testar))
	_titulo = _label("", 15, COR_OURO, true)
	_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_titulo.clip_text = true
	topo.add_child(_titulo)
	topo.add_child(_botao("Propriedades da fase", func(): _selecionar("fase", "")))
	topo.add_child(_botao("Menu", _voltar_menu))

	# Esquerda: ferramentas, paleta e opções.
	var esq := _painel_fixo(Vector2(6, 48), Vector2(232, 666))
	var ve := VBoxContainer.new()
	ve.add_theme_constant_override("separation", 6)
	esq.add_child(ve)
	var gf := GridContainer.new()
	gf.columns = 2
	gf.add_theme_constant_override("h_separation", 4)
	gf.add_theme_constant_override("v_separation", 4)
	ve.add_child(gf)
	for f in FERRAMENTAS:
		var id: String = f[0]
		var bt := _botao(f[1], func(): _escolher_ferramenta(id))
		bt.custom_minimum_size = Vector2(104, 28)
		bt.toggle_mode = true
		bt.tooltip_text = f[2]
		gf.add_child(bt)
		_bts_ferramenta[id] = bt
	_dica = _label("", 12, COR_SECUNDARIO)
	_dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dica.custom_minimum_size = Vector2(212, 0)
	ve.add_child(_dica)
	_opcoes = VBoxContainer.new()
	_opcoes.add_theme_constant_override("separation", 4)
	ve.add_child(_opcoes)
	var rol := ScrollContainer.new()
	rol.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rol.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ve.add_child(rol)
	_paleta = VBoxContainer.new()
	_paleta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_paleta.add_theme_constant_override("separation", 2)
	rol.add_child(_paleta)

	# Centro: a grade.
	var moldura := _painel_fixo(Vector2(242, 48), Vector2(656, 640))
	_grade = Control.new()
	_grade.clip_contents = true
	_grade.mouse_filter = Control.MOUSE_FILTER_STOP
	_grade.focus_mode = Control.FOCUS_CLICK
	moldura.add_child(_grade)
	_grade.draw.connect(_desenhar)
	_grade.gui_input.connect(_entrada_grade)
	_grade.mouse_exited.connect(func():
		_casa_mouse = Vector2i(-1, -1)
		_grade.queue_redraw())
	_status = _label("", 12, COR_SECUNDARIO)
	_status.position = Vector2(246, 694)
	_status.size = Vector2(650, 20)
	_status.clip_text = true
	add_child(_status)

	# Direita: inspetor.
	var dir := _painel_fixo(Vector2(904, 48), Vector2(370, 666))
	var rol2 := ScrollContainer.new()
	rol2.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dir.add_child(rol2)
	_insp = VBoxContainer.new()
	_insp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_insp.add_theme_constant_override("separation", 5)
	rol2.add_child(_insp)


func _painel_fixo(pos: Vector2, tam: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	p.position = pos
	p.size = tam
	p.custom_minimum_size = tam
	var sb := StyleBoxFlat.new()
	sb.bg_color = COR_PAINEL
	sb.border_color = COR_BORDA
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(8)
	p.add_theme_stylebox_override("panel", sb)
	add_child(p)
	return p


# --- Abrir, salvar, histórico --------------------------------------------------------------

func _abrir(id: String) -> void:
	_abrir_fase(Fase.carregar(id), Fase.eh_exemplo(id))


func _abrir_fase(f: Dictionary, exemplo: bool) -> void:
	fase = Fase.normalizar(f)
	_somente_leitura = exemplo
	_sujo = false
	_historico = []
	_futuro = []
	_problemas = []
	_escolhendo_casas = []
	_enquadrar()
	_escolher_ferramenta("selecionar")
	_selecionar("fase", "")
	_atualizar_titulo()


func _atualizar_titulo() -> void:
	_titulo.text = "%s%s%s" % [fase.get("nome", ""), "  (exemplo: salvar cria uma cópia sua)" if _somente_leitura else "", "  •" if _sujo else ""]


## Guarda o estado para o Desfazer (mudanças seguidas em menos de 0,8 s contam como uma).
func _registrar(forcar := false) -> void:
	var agora := Time.get_ticks_msec()
	if forcar or agora - _ultimo_registro > 800:
		_historico.append(JSON.stringify(fase))
		if _historico.size() > 80:
			_historico.pop_front()
		_futuro = []
	_ultimo_registro = agora
	_sujo = true
	_atualizar_titulo()


func _desfazer() -> void:
	if _historico.is_empty():
		return
	_futuro.append(JSON.stringify(fase))
	fase = Fase.normalizar(JSON.parse_string(_historico.pop_back()))
	_depois_de_historico()


func _refazer() -> void:
	if _futuro.is_empty():
		return
	_historico.append(JSON.stringify(fase))
	fase = Fase.normalizar(JSON.parse_string(_futuro.pop_back()))
	_depois_de_historico()


func _depois_de_historico() -> void:
	_sujo = true
	_ultimo_registro = 0
	_atualizar_titulo()
	_montar_inspetor()
	_grade.queue_redraw()


func _salvar() -> bool:
	if _somente_leitura:
		fase["id"] = Fase.id_livre(str(fase["nome"]) + " minha")
		fase["nome"] = str(fase["nome"]).trim_prefix("Exemplo: ")
		_somente_leitura = false
	var erro := Fase.salvar(fase)
	if erro != "":
		_aviso(erro)
		return false
	_sujo = false
	_atualizar_titulo()
	_aviso("Fase salva na biblioteca.")
	return true


func _aviso(t: String) -> void:
	_status.text = t
	_status.add_theme_color_override("font_color", COR_AVISO)
	var g := get_tree().create_timer(4.0)
	g.timeout.connect(func():
		if is_instance_valid(_status):
			_status.add_theme_color_override("font_color", COR_SECUNDARIO)
			_atualizar_status())


func _voltar_menu() -> void:
	if _sujo:
		_confirmar("A fase tem mudanças não salvas. Sair mesmo assim?", func(): get_tree().change_scene_to_file("res://ui/main.tscn"))
	else:
		get_tree().change_scene_to_file("res://ui/main.tscn")


func _testar() -> void:
	var erros := Fase.validar(fase)
	if not erros.is_empty():
		_problemas = erros
		_validar(true)
		_confirmar("A fase tem %d problema(s) (lista no painel da direita). Testar mesmo assim?" % erros.size(), _ir_testar)
		return
	_ir_testar()


func _ir_testar() -> void:
	if not _salvar():
		return
	Sessao.fase_teste = str(fase["id"])
	Sessao.modo = Fase.PREFIXO + str(fase["id"])
	Sessao.campanha = false
	Sessao.solo = false
	Sessao.online = false
	Sessao.estado_salvo = ""
	get_tree().change_scene_to_file("res://ui/batalha.tscn")


# --- Ferramentas e paleta ------------------------------------------------------------------

func _escolher_ferramenta(id: String) -> void:
	_ferramenta = id
	for k in _bts_ferramenta:
		_bts_ferramenta[k].button_pressed = k == id
	for f in FERRAMENTAS:
		if f[0] == id:
			_dica.text = f[2]
	match id:
		"chao":
			if not Fase.CHAOS.has(_pincel):
				_pincel = "pedra"
		"objeto":
			if not Fase.OBJETOS.has(_pincel):
				_pincel = "parede"
				_definir_objeto("parede")
		"inimigo":
			if not Bestiario.PRESETS.has(_pincel):
				_pincel = "goblin_brigao"
		"inicio":
			if not _pincel.is_valid_int():
				_pincel = "0"
		"area":
			if not fase["areas"].any(func(a): return a["id"] == _pincel):
				_pincel = fase["areas"][0]["id"] if not fase["areas"].is_empty() else ""
	_montar_paleta()
	_grade.queue_redraw()


func _definir_objeto(tipo: String) -> void:
	_pincel = tipo
	var info: Dictionary = Fase.OBJETOS[tipo]
	_obj_colisao = info["colisao"]
	_obj_visao = "padrao"


func _limpar(c: Control) -> void:
	for f in c.get_children():
		c.remove_child(f)
		f.queue_free()


func _item_paleta(texto: String, ativo: bool, acao: Callable, cor := Color.TRANSPARENT) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	if cor != Color.TRANSPARENT:
		var q := ColorRect.new()
		q.color = cor
		q.custom_minimum_size = Vector2(14, 14)
		q.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(q)
	var bt := _botao(texto, acao)
	bt.toggle_mode = true
	bt.button_pressed = ativo
	bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bt.alignment = HORIZONTAL_ALIGNMENT_LEFT
	bt.clip_text = true
	h.add_child(bt)
	_paleta.add_child(h)


func _montar_paleta() -> void:
	_limpar(_paleta)
	_limpar(_opcoes)
	match _ferramenta:
		"chao":
			for t in Fase.CHAOS:
				var tipo: String = t
				_item_paleta(Fase.CHAOS[t]["nome"] + ("  (piso da fase)" if t == fase["piso"] else ""), _pincel == t,
					func():
						_pincel = tipo
						_montar_paleta(), Color(Fase.CHAOS[t]["cor"]))
		"altura":
			for n in [-1, 0, 1, 2]:
				var alt: int = n
				_item_paleta("Altura %d%s" % [n, " (chão)" if n == 0 else (" (fosso)" if n < 0 else "")], _pincel == "a%d" % n,
					func():
						_pincel = "a%d" % alt
						_montar_paleta())
			_item_paleta("Escada / rampa (liga alturas)", _pincel == "escada", func():
				_pincel = "escada"
				_montar_paleta())
		"objeto":
			var cc := CheckBox.new()
			cc.text = "Colisão (bloqueia o passo)"
			cc.button_pressed = _obj_colisao
			cc.toggled.connect(func(v): _obj_colisao = v)
			_estilo_texto(cc)
			_opcoes.add_child(cc)
			var ov := _opcao_lista(["padrao", "bloqueia", "livre"], ["Visão: como o objeto", "Visão: bloqueia", "Visão: não bloqueia"], _obj_visao,
				func(v): _obj_visao = v)
			_opcoes.add_child(ov)
			for t in Fase.OBJETOS:
				var tipo: String = t
				var info: Dictionary = Fase.OBJETOS[t]
				_item_paleta("%s  %s" % [info["letra"], info["nome"]], _pincel == t, func():
					_definir_objeto(tipo)
					_montar_paleta())
		"inimigo":
			for id in Bestiario.PRESETS:
				var pid: String = id
				var pr: Dictionary = Bestiario.PRESETS[id]
				_item_paleta("%s (%s)" % [pr["nome"], Bestiario.PATAMARES[pr["patamar"]]], _pincel == id, func():
					_pincel = pid
					_montar_paleta(), COR_PATAMAR.get(pr["patamar"], Color.GRAY))
		"inicio":
			for i in 4:
				var k: int = i
				_item_paleta("Herói %d%s" % [i + 1, "" if i < fase["inicio"].size() else " (sem lugar)"], _pincel == str(i), func():
					_pincel = str(k)
					_montar_paleta(), Color("4fbf6a"))
		"area":
			_opcoes.add_child(_botao("+ Nova área", func():
				var a := _nova_area("fala")
				_pincel = a["id"]
				_selecionar("area", a["id"])
				_montar_paleta()))
			for a in fase["areas"]:
				var aid: String = a["id"]
				_item_paleta("%s · %s (%d casas)" % [a.get("nome", aid), Fase.TIPOS_DE_AREA.get(a.get("tipo", "fala"), "?").split(" ")[0], a.get("celulas", []).size()],
					_pincel == aid, func():
						_pincel = aid
						_selecionar("area", aid)
						_montar_paleta(), COR_AREA.get(a.get("tipo", "fala"), Color.WHITE))
			if fase["areas"].is_empty():
				_paleta.add_child(_label("Crie uma área e pinte as casas dela no mapa. Botão direito apaga a casa da área.", 12, COR_SECUNDARIO, false, 210))
		"interacao":
			for it in fase["interacoes"]:
				var iid: String = it["id"]
				_item_paleta("! %s" % it.get("nome", iid), _selecao.get("id", "") == iid, func(): _selecionar("interacao", iid), COR_OURO)
		"selecionar", "borracha", "luz":
			_paleta.add_child(_label("Inimigos: %d · Interações: %d · Áreas: %d · Objetos: %d" % [fase["inimigos"].size(), fase["interacoes"].size(),
				fase["areas"].size(), fase["objetos"].size()], 12, COR_SECUNDARIO, false, 210))
			for e in fase["inimigos"]:
				var eid: String = e["id"]
				_item_paleta("%s%s" % [e.get("nome", eid), "  ★" if e.get("alvo", false) else ""], _selecao.get("id", "") == eid,
					func(): _selecionar("inimigo", eid), COR_PATAMAR.get(e.get("patamar", "medio"), Color.GRAY))


# --- Grade: desenho ---------------------------------------------------------------------------

func _enquadrar() -> void:
	var l := float(fase["largura"])
	var a := float(fase["altura"])
	_zoom = clampf(minf(620.0 / l, 600.0 / a), 8.0, 48.0)
	_offset = Vector2((640.0 - l * _zoom) / 2.0, (624.0 - a * _zoom) / 2.0)
	if is_instance_valid(_grade):
		_grade.queue_redraw()


func _casa_em(pos: Vector2) -> Vector2i:
	var c := (pos - _offset) / _zoom
	return Vector2i(floori(c.x), floori(c.y))


func _rect(p: Vector2i) -> Rect2:
	return Rect2(_offset + Vector2(p) * _zoom, Vector2(_zoom, _zoom))


func _dentro(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < int(fase["largura"]) and p.y < int(fase["altura"])


func _desenhar() -> void:
	if fase.is_empty():
		return
	var l := int(fase["largura"])
	var a := int(fase["altura"])
	var cor_piso := Color(Fase.CHAOS.get(fase["piso"], Fase.CHAOS["grama"])["cor"])
	var tam_fonte := int(clampf(_zoom * 0.55, 8, 22))
	# Chão
	for x in l:
		for y in a:
			var p := Vector2i(x, y)
			var c := Fase.texto_casa(p)
			var t: String = fase["chao"].get(c, fase["piso"])
			var cor := Color(Fase.CHAOS.get(t, Fase.CHAOS["grama"])["cor"]) if fase["chao"].has(c) else cor_piso
			if (x + y) % 2 == 0:
				cor = cor.darkened(0.07)
			var n := int(fase["niveis"].get(c, 0))
			if n != 0:
				cor = cor.lightened(0.12 * n) if n > 0 else cor.darkened(0.3)
			var r := _rect(p)
			_grade.draw_rect(r, cor)
			if t == "vazio":
				_grade.draw_line(r.position, r.end, Color(0.3, 0.3, 0.35), 1)
				_grade.draw_line(Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), Color(0.3, 0.3, 0.35), 1)
			elif t == "dificil":
				for k in 3:
					var o := r.position + Vector2(0, r.size.y * (k + 1) / 4.0)
					_grade.draw_line(o, o + Vector2(r.size.x, -r.size.y * 0.25), Color(0, 0, 0, 0.35), 1)
			if n != 0 and _zoom >= 16:
				_grade.draw_string(_fonte, r.position + Vector2(2, 10), str(n), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 1, 1, 0.7))
			if c in fase["escadas"]:
				_texto_na_casa(p, "⇅", Color.WHITE, tam_fonte)
	# Linhas da grade
	if _zoom >= 10:
		for x in l + 1:
			_grade.draw_line(_offset + Vector2(x * _zoom, 0), _offset + Vector2(x * _zoom, a * _zoom), Color(0, 0, 0, 0.25), 1)
		for y in a + 1:
			_grade.draw_line(_offset + Vector2(0, y * _zoom), _offset + Vector2(l * _zoom, y * _zoom), Color(0, 0, 0, 0.25), 1)
	# Áreas
	for ar in fase["areas"]:
		var cor_a: Color = COR_AREA.get(ar.get("tipo", "fala"), Color.WHITE)
		var sel: bool = (_selecao["tipo"] == "area" and _selecao["id"] == ar["id"]) or (_ferramenta == "area" and _pincel == ar["id"])
		for c in ar.get("celulas", []):
			var r := _rect(Fase.casa(c))
			_grade.draw_rect(r, Color(cor_a, 0.38 if sel else 0.22))
			_grade.draw_rect(r.grow(-1), Color(cor_a, 0.9 if sel else 0.5), false, 2 if sel else 1)
		if not ar.get("celulas", []).is_empty() and _zoom >= 14:
			var r0 := _rect(Fase.casa(ar["celulas"][0]))
			_grade.draw_string(_fonte, r0.position + Vector2(2, r0.size.y - 3), {"fala": "F", "teste": "T", "efeito": "E", "armadilha": "A", "chegada": "C"}.get(ar.get("tipo", "fala"), "?"),
				HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(9, tam_fonte - 4), Color(cor_a, 1))
	# Objetos
	for o in fase["objetos"]:
		var p := Fase.casa(str(o["pos"]))
		var r := _rect(p).grow(-_zoom * 0.08)
		var info: Dictionary = Fase.OBJETOS.get(o["tipo"], {"letra": "?", "colisao": true, "visao": "bloqueia"})
		var col := bool(o.get("colisao", info["colisao"]))
		if o["tipo"] == "parede":
			_grade.draw_rect(_rect(p), Color("6b6773") if col else Color("6b6773", 0.5))
		else:
			_grade.draw_rect(r, Color(0.12, 0.1, 0.08, 0.75))
			_texto_na_casa(p, info["letra"], COR_TEXTO, tam_fonte)
		if col:
			_grade.draw_rect(r, Color("d05050"), false, 1.5)
		var vis: String = str(o.get("visao", "padrao"))
		if vis != "padrao":
			_grade.draw_circle(r.position + Vector2(r.size.x - 3, 3), maxf(2.0, _zoom * 0.08), Color("60a0ff") if vis == "bloqueia" else Color("ffffff"))
		if _selecao["tipo"] == "objeto" and _selecao["id"] == str(o["pos"]):
			_grade.draw_rect(_rect(p), COR_OURO, false, 2.5)
	# Luzes
	for lz in fase["luzes"]:
		var p := Fase.casa(str(lz["pos"]))
		var cen := _rect(p).get_center()
		_grade.draw_circle(cen, _zoom * 0.22, Color("ffd060"))
		_grade.draw_arc(cen, _zoom * (0.5 + float(lz.get("penumbra", 4))), 0, TAU, 48, Color(1, 0.85, 0.4, 0.25), 1)
		_grade.draw_arc(cen, _zoom * (0.5 + float(lz.get("claro", 2))), 0, TAU, 48, Color(1, 0.85, 0.4, 0.5), 1)
		if _selecao["tipo"] == "luz" and _selecao["id"] == str(lz["pos"]):
			_grade.draw_rect(_rect(p), COR_OURO, false, 2.5)
	# Interações
	for it in fase["interacoes"]:
		var p := Fase.casa(str(it["pos"]))
		var r := _rect(p).grow(-_zoom * 0.18)
		_grade.draw_rect(r, Color(COR_OURO, 0.25))
		_grade.draw_rect(r, COR_OURO, false, 2)
		_texto_na_casa(p, "!", COR_OURO if not it.get("oculta", false) else COR_SECUNDARIO, tam_fonte + 2)
		if _selecao["tipo"] == "interacao" and _selecao["id"] == it["id"]:
			_grade.draw_rect(_rect(p), Color.WHITE, false, 2.5)
	# Início dos heróis
	for i in fase["inicio"].size():
		var p := Fase.casa(str(fase["inicio"][i]))
		var cen := _rect(p).get_center()
		_grade.draw_circle(cen, _zoom * 0.38, Color("2f8a46"))
		_grade.draw_arc(cen, _zoom * 0.38, 0, TAU, 24, Color("a6f0b8"), 1.5)
		_texto_na_casa(p, str(i + 1), Color.WHITE, tam_fonte)
	# Inimigos
	for e in fase["inimigos"]:
		var p := Fase.casa(str(e["pos"]))
		var cen := _rect(p).get_center()
		var cor: Color = COR_PATAMAR.get(e.get("patamar", "medio"), Color.GRAY)
		var sel: bool = _selecao["tipo"] == "inimigo" and _selecao["id"] == e["id"]
		if sel:
			var v := int(e.get("vigia", 4))
			var rv := Rect2(_offset + Vector2(p - Vector2i(v, v)) * _zoom, Vector2(2 * v + 1, 2 * v + 1) * _zoom)
			_grade.draw_rect(rv, Color(cor, 0.12))
			_grade.draw_rect(rv, Color(cor, 0.6), false, 1)
		_grade.draw_circle(cen, _zoom * 0.42, cor)
		_grade.draw_arc(cen, _zoom * 0.42, 0, TAU, 24, Color.WHITE if sel else Color(0, 0, 0, 0.6), 2.5 if sel else 1.0)
		var palavras := str(e.get("nome", "?")).split(" ", false)
		var sigla := ""
		for w in palavras.slice(0, 2):
			sigla += w.left(1)
		_texto_na_casa(p, sigla, Color.WHITE, maxi(8, tam_fonte - 3))
		if e.get("alvo", false):
			_grade.draw_string(_fonte_negrito, _rect(p).position + Vector2(_zoom - 10, 10), "★", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COR_AVISO)
		if not e.get("saque", []).is_empty():
			_grade.draw_string(_fonte_negrito, _rect(p).position + Vector2(1, _zoom - 2), "$", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("8fe08f"))
		if e.get("dormindo", false):
			_grade.draw_string(_fonte, _rect(p).position + Vector2(_zoom - 10, _zoom - 2), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("a0c0ff"))
	# Casas escolhidas para um efeito "abrir caminho"
	for c in _escolhendo_casas:
		_grade.draw_rect(_rect(Fase.casa(c)).grow(-2), Color("40e0ff"), false, 3)
	# Retângulo em andamento
	if _ret_inicio != Vector2i(-1, -1) and _casa_mouse != Vector2i(-1, -1):
		var r0 := _rect(Vector2i(mini(_ret_inicio.x, _casa_mouse.x), mini(_ret_inicio.y, _casa_mouse.y)))
		var r1 := _rect(Vector2i(maxi(_ret_inicio.x, _casa_mouse.x), maxi(_ret_inicio.y, _casa_mouse.y)))
		_grade.draw_rect(Rect2(r0.position, r1.end - r0.position), Color(1, 1, 1, 0.8), false, 2)
	# Casa sob o mouse
	if _dentro(_casa_mouse):
		_grade.draw_rect(_rect(_casa_mouse), Color(1, 1, 1, 0.6), false, 1.5)
	# Borda do mapa
	_grade.draw_rect(Rect2(_offset, Vector2(l, a) * _zoom), COR_OURO.darkened(0.3), false, 2)


func _texto_na_casa(p: Vector2i, t: String, cor: Color, tam: int) -> void:
	var r := _rect(p)
	var larg := _fonte_negrito.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
	_grade.draw_string(_fonte_negrito, r.position + Vector2((r.size.x - larg) / 2.0, r.size.y / 2.0 + tam * 0.36), t, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, cor)


# --- Grade: entrada ---------------------------------------------------------------------------

func _entrada_grade(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var b: InputEventMouseButton = ev
		if b.button_index == MOUSE_BUTTON_WHEEL_UP or b.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if b.pressed:
				var antes := (b.position - _offset) / _zoom
				_zoom = clampf(_zoom * (1.12 if b.button_index == MOUSE_BUTTON_WHEEL_UP else 1 / 1.12), 6.0, 80.0)
				_offset = b.position - antes * _zoom
				_grade.queue_redraw()
			return
		if b.button_index == MOUSE_BUTTON_MIDDLE:
			_arrastando_vista = b.pressed
			return
		var c := _casa_em(b.position)
		if b.button_index == MOUSE_BUTTON_RIGHT:
			if b.pressed:
				if _ferramenta == "area" and _dentro(c):
					_pintar_area(c, false)
					_pintando = true
				else:
					_arrastando_vista = true
			else:
				_arrastando_vista = false
				_pintando = false
			return
		if b.button_index != MOUSE_BUTTON_LEFT:
			return
		if b.pressed:
			_grade.grab_focus()
			if not _escolhendo_casas.is_empty() or _selecao.get("escolhendo", false):
				_alternar_casa_escolhida(c)
				return
			if not _dentro(c):
				return
			if b.shift_pressed and _ferramenta in ["chao", "objeto", "altura", "area", "borracha"]:
				_ret_inicio = c
				return
			if b.ctrl_pressed and _ferramenta == "chao":
				_balde(c)
				return
			if _ferramenta == "selecionar":
				_clique_selecionar(c)
				return
			_pintando = true
			_aplicar(c, true)
		else:
			if _ret_inicio != Vector2i(-1, -1):
				_aplicar_retangulo(_ret_inicio, c)
				_ret_inicio = Vector2i(-1, -1)
			if not _movendo.is_empty():
				_soltar_movendo(c)
			_pintando = false
	elif ev is InputEventMouseMotion:
		var m: InputEventMouseMotion = ev
		if _arrastando_vista:
			_offset += m.relative
			_grade.queue_redraw()
			return
		var c := _casa_em(m.position)
		if c != _casa_mouse:
			_casa_mouse = c
			_atualizar_status()
			if _pintando and _dentro(c) and _ret_inicio == Vector2i(-1, -1):
				if _ferramenta == "area" and (m.button_mask & MOUSE_BUTTON_MASK_RIGHT) != 0:
					_pintar_area(c, false)
				elif _ferramenta in ["chao", "objeto", "altura", "area", "borracha"]:
					_aplicar(c, false)
			_grade.queue_redraw()


func _unhandled_input(ev: InputEvent) -> void:
	if not ev is InputEventKey or not ev.pressed:
		return
	var k: InputEventKey = ev
	if k.ctrl_pressed and k.keycode == KEY_Z:
		_desfazer()
	elif k.ctrl_pressed and k.keycode == KEY_Y:
		_refazer()
	elif k.ctrl_pressed and k.keycode == KEY_S:
		_salvar()
	elif k.keycode == KEY_DELETE and _grade.has_focus():
		_apagar_selecao()
	elif k.keycode == KEY_ESCAPE and not _escolhendo_casas.is_empty():
		_terminar_escolha()


func _atualizar_status() -> void:
	if not _dentro(_casa_mouse):
		_status.text = "Roda do mouse: zoom · botão do meio ou direito: arrastar o mapa · Ctrl+Z desfaz · Ctrl+S salva"
		return
	var c := Fase.texto_casa(_casa_mouse)
	var partes := PackedStringArray(["Casa %s" % c])
	partes.append(Fase.CHAOS.get(fase["chao"].get(c, fase["piso"]), {"nome": "?"})["nome"])
	var o := _objeto_em(c)
	if not o.is_empty():
		partes.append("%s%s" % [Fase.OBJETOS.get(o["tipo"], {"nome": o["tipo"]})["nome"], " (colisão)" if bool(o.get("colisao", true)) else " (sem colisão)"])
	var e := _inimigo_em(c)
	if not e.is_empty():
		partes.append(e.get("nome", ""))
	for a in fase["areas"]:
		if c in a.get("celulas", []):
			partes.append("área " + str(a.get("nome", a["id"])))
	_status.text = " · ".join(partes)


# --- Aplicar ferramentas -----------------------------------------------------------------------

func _objeto_em(c: String) -> Dictionary:
	for o in fase["objetos"]:
		if str(o["pos"]) == c:
			return o
	return {}


func _inimigo_em(c: String) -> Dictionary:
	for e in fase["inimigos"]:
		if str(e["pos"]) == c:
			return e
	return {}


func _interacao_em(c: String) -> Dictionary:
	for it in fase["interacoes"]:
		if str(it["pos"]) == c:
			return it
	return {}


func _luz_em(c: String) -> Dictionary:
	for lz in fase["luzes"]:
		if str(lz["pos"]) == c:
			return lz
	return {}


func _aplicar(p: Vector2i, primeiro: bool) -> void:
	var c := Fase.texto_casa(p)
	match _ferramenta:
		"chao":
			var atual: String = fase["chao"].get(c, fase["piso"])
			if atual == _pincel:
				return
			_registrar()
			if _pincel == fase["piso"]:
				fase["chao"].erase(c)
			else:
				fase["chao"][c] = _pincel
		"altura":
			_registrar()
			if _pincel == "escada":
				if primeiro:
					if c in fase["escadas"]:
						fase["escadas"].erase(c)
					else:
						fase["escadas"].append(c)
			else:
				var n := int(_pincel.trim_prefix("a"))
				if n == 0:
					fase["niveis"].erase(c)
				else:
					fase["niveis"][c] = n
		"objeto":
			var o := _objeto_em(c)
			if not o.is_empty() and o["tipo"] == _pincel and bool(o.get("colisao", true)) == _obj_colisao and str(o.get("visao", "padrao")) == _obj_visao:
				return
			_registrar()
			if not o.is_empty():
				fase["objetos"].erase(o)
			fase["objetos"].append({"pos": c, "tipo": _pincel, "colisao": _obj_colisao, "visao": _obj_visao})
		"luz":
			if not primeiro:
				return
			var lz := _luz_em(c)
			if lz.is_empty():
				_registrar(true)
				lz = {"pos": c, "claro": 2, "penumbra": 4, "nome": "luz"}
				fase["luzes"].append(lz)
			_selecionar("luz", c)
		"inicio":
			if not primeiro:
				return
			_registrar(true)
			var i := int(_pincel)
			while fase["inicio"].size() <= i:
				fase["inicio"].append(c)
			fase["inicio"][i] = c
			_pincel = str(mini(i + 1, 3))
			_montar_paleta()
		"inimigo":
			if not primeiro:
				return
			var e := _inimigo_em(c)
			if e.is_empty():
				_registrar(true)
				e = _novo_inimigo(_pincel, c)
			_selecionar("inimigo", e["id"])
		"area":
			_pintar_area(p, true)
		"interacao":
			if not primeiro:
				return
			var it := _interacao_em(c)
			if it.is_empty():
				_registrar(true)
				it = _nova_interacao(c)
			_selecionar("interacao", it["id"])
			_montar_paleta()
		"borracha":
			_apagar_em(c)
	_grade.queue_redraw()


func _aplicar_retangulo(a: Vector2i, b: Vector2i) -> void:
	_registrar(true)
	for x in range(mini(a.x, b.x), maxi(a.x, b.x) + 1):
		for y in range(mini(a.y, b.y), maxi(a.y, b.y) + 1):
			var p := Vector2i(x, y)
			if _dentro(p):
				_ultimo_registro = Time.get_ticks_msec()
				_aplicar(p, true)
	_montar_paleta()
	_grade.queue_redraw()


func _balde(p: Vector2i) -> void:
	var c0 := Fase.texto_casa(p)
	var alvo: String = fase["chao"].get(c0, fase["piso"])
	if alvo == _pincel:
		return
	_registrar(true)
	var fila := [p]
	var visto := {p: true}
	while not fila.is_empty():
		var q: Vector2i = fila.pop_back()
		var cq := Fase.texto_casa(q)
		if _pincel == fase["piso"]:
			fase["chao"].erase(cq)
		else:
			fase["chao"][cq] = _pincel
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = q + d
			if _dentro(n) and not visto.has(n) and fase["chao"].get(Fase.texto_casa(n), fase["piso"]) == alvo:
				visto[n] = true
				fila.append(n)
	_grade.queue_redraw()


func _pintar_area(p: Vector2i, adicionar: bool) -> void:
	var a := _area(_pincel)
	if a.is_empty():
		if not adicionar:
			return
		a = _nova_area("fala")
		_pincel = a["id"]
		_montar_paleta()
	var c := Fase.texto_casa(p)
	if adicionar and not c in a["celulas"]:
		_registrar()
		a["celulas"].append(c)
	elif not adicionar and c in a["celulas"]:
		_registrar()
		a["celulas"].erase(c)
	else:
		return
	_selecao = {"tipo": "area", "id": a["id"]}
	_grade.queue_redraw()


func _apagar_em(c: String) -> void:
	var e := _inimigo_em(c)
	if not e.is_empty():
		_registrar(true)
		fase["inimigos"].erase(e)
		return
	var it := _interacao_em(c)
	if not it.is_empty():
		_registrar(true)
		fase["interacoes"].erase(it)
		return
	var lz := _luz_em(c)
	if not lz.is_empty():
		_registrar(true)
		fase["luzes"].erase(lz)
		return
	if c in fase["inicio"] and fase["inicio"].size() > 1:
		_registrar(true)
		fase["inicio"].erase(c)
		return
	var o := _objeto_em(c)
	if not o.is_empty():
		_registrar()
		fase["objetos"].erase(o)
		return
	for a in fase["areas"]:
		if c in a["celulas"]:
			_registrar()
			a["celulas"].erase(c)
			return


func _clique_selecionar(p: Vector2i) -> void:
	var c := Fase.texto_casa(p)
	var e := _inimigo_em(c)
	if not e.is_empty():
		_selecionar("inimigo", e["id"])
		_movendo = {"tipo": "inimigo", "de": c}
		return
	var it := _interacao_em(c)
	if not it.is_empty():
		_selecionar("interacao", it["id"])
		_movendo = {"tipo": "interacao", "de": c}
		return
	var lz := _luz_em(c)
	if not lz.is_empty():
		_selecionar("luz", c)
		_movendo = {"tipo": "luz", "de": c}
		return
	var i: int = fase["inicio"].find(c)
	if i >= 0:
		_selecionar("inicio", str(i))
		_movendo = {"tipo": "inicio", "de": c}
		return
	var o := _objeto_em(c)
	if not o.is_empty():
		_selecionar("objeto", c)
		_movendo = {"tipo": "objeto", "de": c}
		return
	for a in fase["areas"]:
		if c in a.get("celulas", []):
			_selecionar("area", a["id"])
			return
	_selecionar("fase", "")


func _soltar_movendo(p: Vector2i) -> void:
	var m := _movendo
	_movendo = {}
	var c := Fase.texto_casa(p)
	if c == m["de"] or not _dentro(p):
		return
	_registrar(true)
	match m["tipo"]:
		"inimigo":
			if _inimigo_em(c).is_empty():
				_inimigo_em(m["de"])["pos"] = c
		"interacao":
			if _interacao_em(c).is_empty():
				_interacao_em(m["de"])["pos"] = c
		"luz":
			if _luz_em(c).is_empty():
				_luz_em(m["de"])["pos"] = c
				_selecao["id"] = c
		"inicio":
			var i: int = fase["inicio"].find(m["de"])
			if i >= 0 and not c in fase["inicio"]:
				fase["inicio"][i] = c
		"objeto":
			if _objeto_em(c).is_empty():
				_objeto_em(m["de"])["pos"] = c
				_selecao["id"] = c
	_grade.queue_redraw()


func _apagar_selecao() -> void:
	match _selecao["tipo"]:
		"inimigo":
			_registrar(true)
			fase["inimigos"] = fase["inimigos"].filter(func(e): return e["id"] != _selecao["id"])
		"interacao":
			_registrar(true)
			fase["interacoes"] = fase["interacoes"].filter(func(x): return x["id"] != _selecao["id"])
		"area":
			_registrar(true)
			fase["areas"] = fase["areas"].filter(func(x): return x["id"] != _selecao["id"])
		"luz", "objeto":
			_apagar_em(_selecao["id"])
		_:
			return
	_selecionar("fase", "")
	_montar_paleta()
	_grade.queue_redraw()


# --- Coisas novas -------------------------------------------------------------------------------

func _id_livre(base: String, lista: Array) -> String:
	var id := Fase.id_de(base)
	var n := 1
	var cand := id
	while lista.any(func(x): return str(x.get("id", "")) == cand):
		n += 1
		cand = "%s%d" % [id, n]
	return cand


func _novo_inimigo(preset: String, c: String) -> Dictionary:
	var pr := Bestiario.preset(preset)
	var e := {"id": _id_livre(preset, fase["inimigos"]), "preset": preset, "nome": pr["nome"], "pos": c,
		"patamar": pr["patamar"], "papel": pr["papel"], "grupo": "grupo1", "alerta": false, "vigia": 4, "dormindo": false,
		"alvo": false, "saque": [], "proprios": {"ativo": false}}
	fase["inimigos"].append(e)
	if not fase["grupos"].has("grupo1"):
		fase["grupos"]["grupo1"] = {"titulo": "Inimigos!", "texto": "", "alerta": true}
	return e


func _nova_area(tipo: String) -> Dictionary:
	_registrar(true)
	var a := {"id": _id_livre("area", fase["areas"]), "nome": "Área %d" % (fase["areas"].size() + 1), "tipo": tipo, "celulas": [],
		"titulo": "", "texto": "", "parar": true, "procurar": false, "efeitos": [],
		"teste": {"somar": ["percepcao"], "nivel": "medio"},
		"resultados": {"sucesso": {"texto": "", "efeitos": []}, "falha": {"texto": "", "efeitos": []}},
		"armadilha": {"dano": 4, "ficha": "", "achar": "medio", "evitar": "medio", "desarmar": "medio", "texto_disparo": "O mecanismo dispara!"}}
	fase["areas"].append(a)
	return a


func _nova_interacao(c: String) -> Dictionary:
	var it := {"id": _id_livre("ponto", fase["interacoes"]), "nome": "Ponto de interação", "pos": c, "alcance": 1, "texto": "",
		"oculta": false, "opcoes": [_nova_opcao([])]}
	fase["interacoes"].append(it)
	return it


func _nova_opcao(lista: Array) -> Dictionary:
	return {"id": _id_livre("opcao", lista), "texto": "Examinar", "custo": "padrao", "uma_vez": true, "sem_inimigos": false,
		"requer_item": "", "requer_classe": [], "teste": {"ativo": false, "somar": ["percepcao"], "nivel": "medio"},
		"resultados": {"feito": {"texto": "", "efeitos": []}, "sucesso": {"texto": "", "efeitos": []}, "falha": {"texto": "", "efeitos": []}}}


func _area(id: String) -> Dictionary:
	for a in fase["areas"]:
		if a["id"] == id:
			return a
	return {}


# --- Inspetor --------------------------------------------------------------------------------------

func _selecionar(tipo: String, id: String) -> void:
	if not _escolhendo_casas.is_empty():
		_terminar_escolha()
	_selecao = {"tipo": tipo, "id": id}
	_montar_inspetor()
	_grade.queue_redraw()


func _montar_inspetor() -> void:
	_limpar(_insp)
	if not _problemas.is_empty():
		_insp.add_child(_label("Problemas (%d)" % _problemas.size(), 15, COR_AVISO, true))
		for pr in _problemas:
			var p: Dictionary = pr
			var bt := _botao("• " + str(p["texto"]), func():
				if p["tipo"] in ["inimigo", "area", "interacao"]:
					_selecionar(p["tipo"], p["id"])
				elif p["tipo"] == "inicio":
					_escolher_ferramenta("inicio")
				else:
					_selecionar("fase", ""))
			bt.alignment = HORIZONTAL_ALIGNMENT_LEFT
			bt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			bt.custom_minimum_size = Vector2(340, 0)
			_insp.add_child(bt)
		_insp.add_child(_botao("Esconder a lista", func():
			_problemas = []
			_montar_inspetor()))
		_insp.add_child(HSeparator.new())
	match _selecao["tipo"]:
		"inimigo":
			var e := _inimigo_por_id(_selecao["id"])
			if not e.is_empty():
				_insp_inimigo(e)
				return
		"area":
			var a := _area(_selecao["id"])
			if not a.is_empty():
				_insp_area(a)
				return
		"interacao":
			for it in fase["interacoes"]:
				if it["id"] == _selecao["id"]:
					_insp_interacao(it)
					return
		"objeto":
			var o := _objeto_em(_selecao["id"])
			if not o.is_empty():
				_insp_objeto(o)
				return
		"luz":
			var lz := _luz_em(_selecao["id"])
			if not lz.is_empty():
				_insp_luz(lz)
				return
		"inicio":
			_insp.add_child(_label("Início do herói %d" % (int(_selecao["id"]) + 1), 17, COR_OURO, true))
			_insp.add_child(_texto_ajuda("Arraste no mapa (ferramenta Selecionar) ou use a ferramenta Início. O herói 1 é o primeiro do grupo."))
			return
	_insp_fase()


func _inimigo_por_id(id: String) -> Dictionary:
	for e in fase["inimigos"]:
		if e["id"] == id:
			return e
	return {}


func _cabecalho(texto: String) -> void:
	_insp.add_child(_label(texto, 17, COR_OURO, true))


func _secao(texto: String, pai: Control = null) -> void:
	var l := _label(texto, 14, COR_OURO, true)
	(pai if pai != null else _insp).add_child(l)


## Campo de texto que grava em d[chave].
func _campo_texto(pai: Control, rotulo: String, d: Dictionary, chave: String, longo := false, depois := Callable()) -> void:
	if rotulo != "":
		pai.add_child(_label(rotulo, 12, COR_SECUNDARIO))
	if longo:
		var te := TextEdit.new()
		te.text = str(d.get(chave, ""))
		te.custom_minimum_size = Vector2(318, 70)
		te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		te.text_changed.connect(func():
			_registrar()
			d[chave] = te.text
			if depois.is_valid():
				depois.call())
		_estilo_texto(te)
		pai.add_child(te)
	else:
		var le := LineEdit.new()
		le.text = str(d.get(chave, ""))
		le.custom_minimum_size = Vector2(318, 28)
		le.text_changed.connect(func(t):
			_registrar()
			d[chave] = t
			if depois.is_valid():
				depois.call())
		_estilo_texto(le)
		pai.add_child(le)


func _campo_numero(pai: Control, rotulo: String, d: Dictionary, chave: String, minimo: int, maximo: int, padrao := 0, depois := Callable()) -> void:
	var h := HBoxContainer.new()
	var l := _label(rotulo, 12, COR_SECUNDARIO)
	l.custom_minimum_size = Vector2(200, 0)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.add_child(l)
	var sp := SpinBox.new()
	sp.min_value = minimo
	sp.max_value = maximo
	sp.value = int(d.get(chave, padrao))
	sp.custom_minimum_size = Vector2(110, 26)
	sp.value_changed.connect(func(v):
		_registrar()
		d[chave] = int(v)
		if depois.is_valid():
			depois.call())
	h.add_child(sp)
	pai.add_child(h)


func _campo_caixa(pai: Control, rotulo: String, d: Dictionary, chave: String, padrao := false, depois := Callable()) -> void:
	var cb := CheckBox.new()
	cb.text = rotulo
	cb.button_pressed = bool(d.get(chave, padrao))
	cb.toggled.connect(func(v):
		_registrar()
		d[chave] = v
		if depois.is_valid():
			depois.call())
	_estilo_texto(cb)
	pai.add_child(cb)


## Lista suspensa: valores e rótulos; grava em d[chave].
func _campo_lista(pai: Control, rotulo: String, d: Dictionary, chave: String, valores: Array, rotulos: Array, depois := Callable()) -> void:
	if rotulo != "":
		pai.add_child(_label(rotulo, 12, COR_SECUNDARIO))
	pai.add_child(_opcao_lista(valores, rotulos, str(d.get(chave, valores[0] if not valores.is_empty() else "")), func(v):
		_registrar()
		d[chave] = v
		if depois.is_valid():
			depois.call()))


func _opcao_lista(valores: Array, rotulos: Array, atual: String, ao_mudar: Callable) -> OptionButton:
	var ob := OptionButton.new()
	ob.focus_mode = Control.FOCUS_NONE
	ob.fit_to_longest_item = false
	ob.custom_minimum_size = Vector2(318, 28)
	ob.clip_text = true
	for i in valores.size():
		ob.add_item(str(rotulos[i]))
		if str(valores[i]) == atual:
			ob.select(i)
	ob.item_selected.connect(func(i): ao_mudar.call(valores[i]))
	_estilo_texto(ob)
	return ob


func _texto_ajuda(t: String) -> Label:
	var l := _label(t, 12, COR_SECUNDARIO)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(340, 0)
	return l


func _insp_fase() -> void:
	_cabecalho("Propriedades da fase")
	_campo_texto(_insp, "Nome", fase, "nome", false, _atualizar_titulo)
	_campo_texto(_insp, "Descrição (aparece na biblioteca)", fase, "descricao", true)
	var tam := {"largura": fase["largura"], "altura": fase["altura"]}
	_campo_numero(_insp, "Largura (casas)", tam, "largura", 4, Fase.MAXIMO)
	_campo_numero(_insp, "Altura (casas)", tam, "altura", 4, Fase.MAXIMO)
	_insp.add_child(_botao("Aplicar o tamanho", func():
		_registrar(true)
		_redimensionar(int(tam["largura"]), int(tam["altura"]))))
	_campo_lista(_insp, "Piso padrão (o resto do chão)", fase, "piso", Fase.PISOS, Fase.PISOS.map(func(p): return Fase.CHAOS[p]["nome"]), func(): _grade.queue_redraw())
	_campo_caixa(_insp, "Fase escura (luz conta)", fase, "escuro")
	_campo_lista(_insp, "Luz da lua / ambiente (fase escura)", fase, "luz_ambiente", [0, 1], ["Breu", "Noite com lua"])
	_secao("Abertura (texto ao começar)")
	_campo_texto(_insp, "Título", fase["abertura"], "titulo")
	_campo_texto(_insp, "Texto", fase["abertura"], "texto", true)
	_secao("Objetivo")
	var obj: Dictionary = fase["objetivo"]
	_campo_lista(_insp, "", obj, "tipo", Fase.OBJETIVOS.keys(), Fase.OBJETIVOS.values(), _montar_inspetor)
	if obj["tipo"] == "sobreviver":
		_campo_numero(_insp, "Rodadas para sobreviver", obj, "rodadas", 1, 50, 8)
	if obj["tipo"] == "derrotar_alvos":
		_insp.add_child(_texto_ajuda("Marque \"Alvo do objetivo\" nos inimigos que precisam cair (★ no mapa)."))
	if obj["tipo"] == "chegar":
		_insp.add_child(_texto_ajuda("Crie uma área do tipo Chegada: quando um herói entra nela, a fase está cumprida."))
	if obj["tipo"] == "interagir":
		_insp.add_child(_texto_ajuda("Ponha o efeito Vitória no resultado de uma opção de interação."))
	_campo_texto(_insp, "Texto do objetivo (o jogador vê)", obj, "texto")
	_campo_texto(_insp, "Mensagem de vitória", obj, "mensagem_vitoria", true)
	_secao("Grupos de inimigos")
	_insp.add_child(_texto_ajuda("Inimigos do mesmo grupo acordam juntos. O texto aparece quando os heróis veem o grupo pela primeira vez."))
	for g in _grupos_usados():
		if not fase["grupos"].has(g):
			fase["grupos"][g] = {"titulo": "Inimigos!", "texto": "", "alerta": true}
	for g in fase["grupos"].keys():
		var gd: Dictionary = fase["grupos"][g]
		_insp.add_child(_label("Grupo \"%s\"" % g, 13, COR_TEXTO, true))
		_campo_texto(_insp, "", gd, "titulo")
		_campo_texto(_insp, "", gd, "texto", true)
		_campo_caixa(_insp, "Ao ser visto, o grupo entra na luta", gd, "alerta", true)
	_secao("Campanha (mural da guilda)")
	var camp: Dictionary = fase["campanha"]
	_campo_caixa(_insp, "Aparece no mural como contrato", camp, "no_mural")
	_campo_texto(_insp, "Texto do contrato", camp, "texto", true)
	_campo_numero(_insp, "Pagamento (pratas)", camp, "recompensa", 0, 5000, 100)
	_campo_numero(_insp, "Ciclo da campanha (0 = outros contratos)", camp, "ciclo", 0, 4, 0)
	_insp.add_child(_label("Precisa ter terminado antes:", 12, COR_SECUNDARIO))
	for m in Campanha.missoes():
		var mid: String = m["id"]
		if mid == Fase.PREFIXO + str(fase["id"]):
			continue
		var cb := CheckBox.new()
		cb.text = str(m["nome"])
		cb.button_pressed = mid in camp["requer"]
		cb.toggled.connect(func(v):
			_registrar()
			if v and not mid in camp["requer"]:
				camp["requer"].append(mid)
			elif not v:
				camp["requer"].erase(mid))
		_estilo_texto(cb)
		_insp.add_child(cb)


func _grupos_usados() -> Array:
	var l := []
	for e in fase["inimigos"]:
		var g := str(e.get("grupo", ""))
		if g != "" and not g in l:
			l.append(g)
	return l


func _redimensionar(l: int, a: int) -> void:
	fase["largura"] = l
	fase["altura"] = a
	var dentro := func(c) -> bool:
		var p := Fase.casa(str(c))
		return p.x < l and p.y < a
	for k in fase["chao"].keys():
		if not dentro.call(k):
			fase["chao"].erase(k)
	for k in fase["niveis"].keys():
		if not dentro.call(k):
			fase["niveis"].erase(k)
	fase["escadas"] = fase["escadas"].filter(func(c): return dentro.call(c))
	for chave in ["objetos", "luzes", "inimigos", "interacoes"]:
		fase[chave] = fase[chave].filter(func(x): return dentro.call(x["pos"]))
	fase["inicio"] = fase["inicio"].filter(func(c): return dentro.call(c))
	for ar in fase["areas"]:
		ar["celulas"] = ar["celulas"].filter(func(c): return dentro.call(c))
	_enquadrar()
	_montar_inspetor()


func _insp_objeto(o: Dictionary) -> void:
	_cabecalho("Objeto")
	_campo_lista(_insp, "Tipo", o, "tipo", Fase.OBJETOS.keys(), Fase.OBJETOS.values().map(func(i): return i["nome"]), func(): _grade.queue_redraw())
	_campo_caixa(_insp, "Colisão (bloqueia o passo)", o, "colisao", true, func(): _grade.queue_redraw())
	_campo_lista(_insp, "Visão", o, "visao", ["padrao", "bloqueia", "livre"], ["Como o objeto", "Bloqueia a visão", "Não bloqueia a visão"],
		func(): _grade.queue_redraw())
	_insp.add_child(_texto_ajuda("Sem colisão o objeto vira enfeite: os personagens passam por cima. Para algo acontecer ao clicar no objeto, ponha uma Interação na mesma casa."))


func _insp_luz(lz: Dictionary) -> void:
	_cabecalho("Luz")
	_campo_texto(_insp, "Nome", lz, "nome")
	_campo_numero(_insp, "Raio de luz forte (casas)", lz, "claro", 0, 12, 2, func(): _grade.queue_redraw())
	_campo_numero(_insp, "Raio de penumbra (casas)", lz, "penumbra", 0, 16, 4, func(): _grade.queue_redraw())


func _insp_inimigo(e: Dictionary) -> void:
	_cabecalho(str(e.get("nome", "Inimigo")))
	var pr := Bestiario.preset(str(e.get("preset", "")))
	_insp.add_child(_texto_ajuda(str(pr.get("texto", ""))))
	_campo_lista(_insp, "Monstro do bestiário (modelo, alcance, fraquezas e habilidades)", e, "preset", Bestiario.ids(),
		Bestiario.ids().map(func(i): return Bestiario.PRESETS[i]["nome"]), func():
			var p2 := Bestiario.preset(str(e["preset"]))
			e["nome"] = p2["nome"]
			e["patamar"] = p2["patamar"]
			e["papel"] = p2["papel"]
			_montar_inspetor()
			_grade.queue_redraw())
	_campo_texto(_insp, "Nome", e, "nome", false, func(): _grade.queue_redraw())
	_campo_lista(_insp, "Patamar (quanto aguenta e quanto bate)", e, "patamar", Bestiario.PATAMARES.keys(), Bestiario.PATAMARES.values(),
		func():
			_montar_inspetor()
			_grade.queue_redraw())
	_campo_lista(_insp, "Papel", e, "papel", Bestiario.PAPEIS.keys(), Bestiario.PAPEIS.values(), _montar_inspetor)
	_campo_texto(_insp, "Grupo (acordam juntos)", e, "grupo")
	_campo_caixa(_insp, "Já começa alerta (procurando os heróis)", e, "alerta")
	_campo_caixa(_insp, "Dormindo (acorda quando alguém chega perto)", e, "dormindo", false, func(): _grade.queue_redraw())
	_campo_numero(_insp, "Vigia: percebe heróis a até (casas)", e, "vigia", 0, 20, 4, func(): _grade.queue_redraw())
	_campo_caixa(_insp, "Alvo do objetivo (★)", e, "alvo", false, func(): _grade.queue_redraw())
	var cfg := Fase._inimigo(e, 4)
	_insp.add_child(_label("Com 4 heróis: vida %d · dano %d · resistência %d · velocidade %d · %d ataque(s) por turno%s" % [int(cfg.get("vida", 0)),
		int(cfg.get("dano", 0)), int(cfg.get("resistencia", 0)), int(cfg.get("velocidade", 3)), int(cfg.get("padrao_por_turno", 1)),
		" · à distância" if cfg.get("a_distancia", false) else ""], 12, COR_AVISO, false, 340))
	_secao("Números próprios")
	if not e.has("proprios"):
		e["proprios"] = {"ativo": false}
	var p: Dictionary = e["proprios"]
	_campo_caixa(_insp, "Usar números próprios", p, "ativo", false, func():
		if p["ativo"] and not p.has("vida"):
			for k in ["dano", "resistencia", "velocidade"]:
				p[k] = int(cfg.get(k, 0))
			p["vida"] = int(cfg.get("vida", 20))
			p["ataques_por_turno"] = int(cfg.get("padrao_por_turno", 1))
			p["a_distancia"] = bool(cfg.get("a_distancia", false))
			p["ataque_oportunidade"] = bool(cfg.get("ataque_oportunidade", false))
			p["tamanho"] = str(cfg.get("tamanho", "medio"))
			p["categoria"] = str(cfg.get("categoria", ""))
			p["tipo_dano"] = str(cfg.get("tipo_dano", "Corte"))
			p["visao_no_escuro"] = bool(cfg.get("visao_no_escuro", false))
			p["fraquezas"] = cfg.get("fraquezas", {}).duplicate()
			p["resiste_tipo"] = cfg.get("resiste_tipo", {}).duplicate()
			p["perfil"] = ""
		_montar_inspetor())
	if p.get("ativo", false):
		_campo_numero(_insp, "Vida (para 4 heróis; muda 30% por herói)", p, "vida", 1, 999, 20)
		_campo_numero(_insp, "Dano", p, "dano", 0, 99, 5)
		_campo_numero(_insp, "Resistência", p, "resistencia", 0, 20, 0)
		_campo_numero(_insp, "Velocidade (casas)", p, "velocidade", 0, 12, 3)
		_campo_numero(_insp, "Ataques por turno", p, "ataques_por_turno", 0, 4, 1)
		_campo_caixa(_insp, "Ataca à distância", p, "a_distancia")
		_campo_caixa(_insp, "Ataque de oportunidade", p, "ataque_oportunidade")
		_campo_caixa(_insp, "Enxerga no escuro", p, "visao_no_escuro")
		_campo_lista(_insp, "Tamanho", p, "tamanho", Bestiario.TAMANHOS, Bestiario.TAMANHOS)
		_campo_lista(_insp, "Categoria (devoções)", p, "categoria", Bestiario.CATEGORIAS, Bestiario.CATEGORIAS.map(func(c): return c if c != "" else "nenhuma"))
		_campo_lista(_insp, "Tipo de dano", p, "tipo_dano", Bestiario.TIPOS_DE_DANO, Bestiario.TIPOS_DE_DANO)
		_campo_lista(_insp, "Jeito de puxar cartas", p, "perfil", Bestiario.PERFIS.keys(), Bestiario.PERFIS.values())
		_insp.add_child(_label("Fraquezas (+) e resistências (−) por tipo de dano", 12, COR_SECUNDARIO))
		var grade_f := GridContainer.new()
		grade_f.columns = 2
		for t in Bestiario.TIPOS_DE_DANO:
			var tipo: String = t
			grade_f.add_child(_label(t, 12, COR_TEXTO))
			var sp := SpinBox.new()
			sp.min_value = -9
			sp.max_value = 9
			sp.value = int(p.get("fraquezas", {}).get(t, 0)) - int(p.get("resiste_tipo", {}).get(t, 0))
			sp.custom_minimum_size = Vector2(100, 24)
			sp.value_changed.connect(func(v):
				_registrar()
				if not p.has("fraquezas"):
					p["fraquezas"] = {}
				if not p.has("resiste_tipo"):
					p["resiste_tipo"] = {}
				p["fraquezas"].erase(tipo)
				p["resiste_tipo"].erase(tipo)
				if v > 0:
					p["fraquezas"][tipo] = int(v)
				elif v < 0:
					p["resiste_tipo"][tipo] = int(-v))
			grade_f.add_child(sp)
		_insp.add_child(grade_f)
	_secao("Saque (o que ele deixa ao cair)")
	if not e.has("saque"):
		e["saque"] = []
	_editor_efeitos(_insp, e["saque"])
	_insp.add_child(HSeparator.new())
	_insp.add_child(_botao("Apagar este inimigo", _apagar_selecao))


func _insp_area(a: Dictionary) -> void:
	_cabecalho(str(a.get("nome", "Área")))
	_insp.add_child(_texto_ajuda("%d casa(s). Com a ferramenta Áreas, o botão esquerdo pinta e o direito apaga casas desta área." % a.get("celulas", []).size()))
	_insp.add_child(_botao("Pintar esta área no mapa", func():
		_escolher_ferramenta("area")
		_pincel = a["id"]
		_montar_paleta()
		_grade.queue_redraw()))
	_campo_texto(_insp, "Nome (só no editor)", a, "nome", false, _montar_paleta)
	_campo_lista(_insp, "Tipo", a, "tipo", Fase.TIPOS_DE_AREA.keys(), Fase.TIPOS_DE_AREA.values(), func():
		_montar_inspetor()
		_montar_paleta()
		_grade.queue_redraw())
	var tipo: String = a.get("tipo", "fala")
	match tipo:
		"fala":
			_campo_texto(_insp, "Título", a, "titulo")
			_campo_texto(_insp, "Texto", a, "texto", true)
			_campo_caixa(_insp, "O herói para de andar ao entrar", a, "parar", true)
			_campo_caixa(_insp, "Oferecer \"procurar armadilhas e coisas escondidas\"", a, "procurar")
		"teste":
			_campo_texto(_insp, "Título", a, "titulo")
			_campo_texto(_insp, "Texto ao entrar", a, "texto", true)
			_editor_teste(_insp, a["teste"], false)
			for r in [["sucesso", "Se passar"], ["falha", "Se falhar"]]:
				_secao(r[1])
				var res: Dictionary = a["resultados"][r[0]]
				_campo_texto(_insp, "Texto", res, "texto", true)
				_editor_efeitos(_insp, res["efeitos"])
		"efeito":
			_campo_texto(_insp, "Título", a, "titulo")
			_campo_texto(_insp, "Texto", a, "texto", true)
			_secao("Efeitos")
			_editor_efeitos(_insp, a["efeitos"])
		"armadilha":
			var ar: Dictionary = a["armadilha"]
			_campo_texto(_insp, "Texto (quando achada)", a, "texto", true)
			_campo_texto(_insp, "Texto ao disparar", ar, "texto_disparo")
			_campo_numero(_insp, "Dano", ar, "dano", 0, 50, 4)
			_campo_lista(_insp, "Ficha em quem pisar", ar, "ficha", [""] + Fase.FICHAS, ["nenhuma"] + Fase.FICHAS)
			_campo_lista(_insp, "Achar (Percepção + Investigação)", ar, "achar", Fase.NIVEIS.keys(), Fase.NIVEIS.values())
			_campo_lista(_insp, "Escapar (Acrobacia + Destreza)", ar, "evitar", Fase.NIVEIS.keys(), Fase.NIVEIS.values())
			_campo_lista(_insp, "Desarmar", ar, "desarmar", Fase.NIVEIS.keys(), Fase.NIVEIS.values())
		"chegada":
			_campo_texto(_insp, "Título", a, "titulo")
			_campo_texto(_insp, "Texto (sem texto: usa a mensagem de vitória)", a, "texto", true)
			_insp.add_child(_texto_ajuda("Quando um herói entra aqui, a fase está cumprida. Ponha o objetivo da fase em \"Chegar\"."))
	_insp.add_child(HSeparator.new())
	_insp.add_child(_botao("Apagar esta área", _apagar_selecao))


## Teste: atributo + perícia e o nível.
func _editor_teste(pai: Control, t: Dictionary, com_ativo: bool) -> void:
	if com_ativo:
		_campo_caixa(pai, "Pede um teste", t, "ativo", false, _montar_inspetor)
		if not t.get("ativo", false):
			return
	var somar: Array = t.get("somar", [])
	if not t.has("somar"):
		t["somar"] = somar
	var atual_attr := ""
	var atual_per := ""
	for c in somar:
		if Fase.ATRIBUTOS.has(c):
			atual_attr = c
		else:
			atual_per = c
	var pericias := [""]
	for g in Personagem.PERICIAS:
		pericias.append_array(Personagem.PERICIAS[g])
	var escolha := {"attr": atual_attr, "per": atual_per}
	var aplicar := func():
		t["somar"] = []
		if escolha["per"] != "":
			t["somar"].append(escolha["per"])
		if escolha["attr"] != "":
			t["somar"].append(escolha["attr"])
	_campo_lista(pai, "Perícia", escolha, "per", pericias, pericias.map(func(p): return p if p != "" else "nenhuma"), aplicar)
	_campo_lista(pai, "Atributo", escolha, "attr", [""] + Fase.ATRIBUTOS.keys(), ["nenhum"] + Fase.ATRIBUTOS.values(), aplicar)
	_campo_lista(pai, "Dificuldade", t, "nivel", Fase.NIVEIS.keys(), Fase.NIVEIS.values())


func _insp_interacao(it: Dictionary) -> void:
	_cabecalho(str(it.get("nome", "Interação")))
	_campo_texto(_insp, "Nome", it, "nome", false, _montar_paleta)
	_campo_texto(_insp, "Texto ao olhar", it, "texto", true)
	_campo_numero(_insp, "Alcance (casas)", it, "alcance", 1, 6, 1)
	_campo_caixa(_insp, "Escondida (aparece quando alguém procura)", it, "oculta", false, func(): _grade.queue_redraw())
	for i in it["opcoes"].size():
		var o: Dictionary = it["opcoes"][i]
		_insp.add_child(HSeparator.new())
		var h := HBoxContainer.new()
		var l := _label("Opção %d" % (i + 1), 14, COR_OURO, true)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		h.add_child(_botao("Apagar opção", func():
			_registrar(true)
			it["opcoes"].erase(o)
			_montar_inspetor()))
		_insp.add_child(h)
		_campo_texto(_insp, "Texto do botão", o, "texto")
		_campo_lista(_insp, "Custo", o, "custo", Fase.CUSTOS.keys(), Fase.CUSTOS.values())
		_campo_caixa(_insp, "Só uma vez (some depois de usada)", o, "uma_vez", true)
		_campo_caixa(_insp, "Só sem inimigos alertas", o, "sem_inimigos")
		_campo_numero(_insp, "Precisa de quantas pistas (investigação)", o, "requer_pistas", 0, 20, 0)
		var itens := [""] + _ids_de_itens()
		_campo_lista(_insp, "Precisa ter o item", o, "requer_item", itens, itens.map(func(x): return Itens.nome(x) if x != "" else "nenhum"))
		var hc := HFlowContainer.new()
		hc.add_child(_label("Só as classes:", 12, COR_SECUNDARIO))
		for cl in Personagem.CLASSES:
			var classe: String = cl
			var cb := CheckBox.new()
			cb.text = cl
			cb.button_pressed = cl in o.get("requer_classe", [])
			cb.toggled.connect(func(v):
				_registrar()
				if not o.has("requer_classe"):
					o["requer_classe"] = []
				if v and not classe in o["requer_classe"]:
					o["requer_classe"].append(classe)
				elif not v:
					o["requer_classe"].erase(classe))
			_estilo_texto(cb)
			hc.add_child(cb)
		_insp.add_child(hc)
		_editor_teste(_insp, o["teste"], true)
		if o["teste"].get("ativo", false):
			for r in [["sucesso", "Se passar"], ["falha", "Se falhar"]]:
				_secao(r[1])
				if not o["resultados"].has(r[0]):
					o["resultados"][r[0]] = {"texto": "", "efeitos": []}
				var res: Dictionary = o["resultados"][r[0]]
				_campo_texto(_insp, "Texto", res, "texto", true)
				_editor_efeitos(_insp, res["efeitos"])
		else:
			_secao("Resultado")
			if not o["resultados"].has("feito"):
				o["resultados"]["feito"] = {"texto": "", "efeitos": []}
			var res2: Dictionary = o["resultados"]["feito"]
			_campo_texto(_insp, "Texto", res2, "texto", true)
			_editor_efeitos(_insp, res2["efeitos"])
	_insp.add_child(HSeparator.new())
	_insp.add_child(_botao("+ Nova opção", func():
		_registrar(true)
		it["opcoes"].append(_nova_opcao(it["opcoes"]))
		_montar_inspetor()))
	_insp.add_child(_botao("Apagar esta interação", _apagar_selecao))


func _ids_de_itens() -> Array:
	var l := Itens.CONSUMIVEIS.keys() + Itens.NAO_CONSUMIVEIS.keys()
	l.sort_custom(func(a, b): return Itens.nome(a) < Itens.nome(b))
	return l


## Lista de efeitos (saque, áreas, resultados de interação).
func _editor_efeitos(pai: Control, lista: Array) -> void:
	for i in lista.size():
		var ef: Dictionary = lista[i]
		var caixa := VBoxContainer.new()
		caixa.add_theme_constant_override("separation", 2)
		var h := HBoxContainer.new()
		var tipos: Array = Fase.EFEITOS.keys()
		var ob := _opcao_lista(tipos, tipos.map(func(t): return Fase.EFEITOS[t]["nome"]), str(ef.get("tipo", "ouro")), func(v):
			_registrar(true)
			var novo := {"tipo": v}
			ef.clear()
			ef.merge(novo)
			_montar_inspetor())
		ob.custom_minimum_size = Vector2(270, 28)
		h.add_child(ob)
		h.add_child(_botao("✕", func():
			_registrar(true)
			lista.erase(ef)
			_montar_inspetor()))
		caixa.add_child(h)
		var esq: Dictionary = Fase.EFEITOS.get(ef.get("tipo", ""), {"campos": []})
		for campo in esq["campos"]:
			var chave: String = campo[0]
			match campo[1]:
				"int":
					_campo_numero(caixa, campo[2], ef, chave, -99, 9999, 1 if chave == "qtd" else 0)
				"texto":
					_campo_texto(caixa, campo[2], ef, chave)
				"texto_longo":
					_campo_texto(caixa, campo[2], ef, chave, true)
				"item":
					var itens := _ids_de_itens()
					if not ef.has(chave):
						ef[chave] = itens[0]
					_campo_lista(caixa, campo[2], ef, chave, itens, itens.map(func(x): return Itens.nome(x)))
				"ficha":
					if not ef.has(chave):
						ef[chave] = Fase.FICHAS[0]
					_campo_lista(caixa, campo[2], ef, chave, Fase.FICHAS, Fase.FICHAS)
				"grupo":
					var gs := [""] + _grupos_usados()
					_campo_lista(caixa, campo[2], ef, chave, gs, gs.map(func(g): return g if g != "" else "todos"))
				"interacao":
					var ids: Array = fase["interacoes"].map(func(x): return x["id"])
					if ids.is_empty():
						caixa.add_child(_label("(não há interações na fase)", 12, COR_SECUNDARIO))
					else:
						if not ef.has(chave):
							ef[chave] = ids[0]
						_campo_lista(caixa, campo[2], ef, chave, ids, fase["interacoes"].map(func(x): return x.get("nome", x["id"])))
				"inimigo":
					var ids2: Array = fase["inimigos"].map(func(x): return x["id"])
					if ids2.is_empty():
						caixa.add_child(_label("(não há inimigos na fase)", 12, COR_SECUNDARIO))
					else:
						if not ef.has(chave):
							ef[chave] = ids2[0]
						_campo_lista(caixa, campo[2], ef, chave, ids2, fase["inimigos"].map(func(x): return x.get("nome", x["id"])))
				"missao":
					var ms: Array = Campanha.missoes()
					if not ef.has(chave) and not ms.is_empty():
						ef[chave] = ms[0]["id"]
					_campo_lista(caixa, campo[2], ef, chave, ms.map(func(m): return m["id"]), ms.map(func(m): return m["nome"]))
				"casas":
					if not ef.has(chave):
						ef[chave] = []
					var casas: Array = ef[chave]
					var hb := HBoxContainer.new()
					hb.add_child(_label("%d casa(s)" % casas.size(), 12, COR_TEXTO))
					hb.add_child(_botao("Escolher no mapa", func(): _comecar_escolha(casas)))
					caixa.add_child(hb)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 1, 1, 0.03)
		sb.set_content_margin_all(4)
		sb.set_corner_radius_all(4)
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", sb)
		p.add_child(caixa)
		pai.add_child(p)
	pai.add_child(_botao("+ Efeito", func():
		_registrar(true)
		lista.append({"tipo": "ouro", "valor": 10})
		_montar_inspetor()))


func _comecar_escolha(casas: Array) -> void:
	_escolhendo_casas = casas
	_aviso("Clique nas casas que vão abrir (clique de novo para tirar). Esc ou o botão Concluir terminam.")
	_selecao["escolhendo"] = true
	var bt := _botao("Concluir a escolha de casas", _terminar_escolha)
	_insp.add_child(bt)
	_insp.move_child(bt, 0)
	_grade.queue_redraw()


func _alternar_casa_escolhida(p: Vector2i) -> void:
	if not _dentro(p):
		return
	var c := Fase.texto_casa(p)
	_registrar()
	if c in _escolhendo_casas:
		_escolhendo_casas.erase(c)
	else:
		_escolhendo_casas.append(c)
	_grade.queue_redraw()


func _terminar_escolha() -> void:
	_escolhendo_casas = []
	_selecao.erase("escolhendo")
	_montar_inspetor()
	_grade.queue_redraw()


# --- Validação ----------------------------------------------------------------------------------

func _validar(mostrar: bool) -> void:
	_problemas = Fase.validar(fase)
	if mostrar:
		_aviso("Nenhum problema encontrado." if _problemas.is_empty() else "%d problema(s): veja o painel da direita." % _problemas.size())
	_montar_inspetor()


# --- Biblioteca e janelas ----------------------------------------------------------------------

func _mostrar_biblioteca() -> void:
	if _biblioteca != null:
		_biblioteca.queue_free()
	_biblioteca = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.06, 0.08, 0.98)
	sb.border_color = COR_OURO
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(18)
	_biblioteca.add_theme_stylebox_override("panel", sb)
	_biblioteca.position = Vector2(140, 40)
	_biblioteca.size = Vector2(1000, 640)
	_biblioteca.custom_minimum_size = Vector2(1000, 640)
	add_child(_biblioteca)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_biblioteca.add_child(v)
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 8)
	var t := _label("Biblioteca de fases", 22, COR_OURO, true)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(t)
	topo.add_child(_botao("Nova fase", func():
		_biblioteca.queue_free()
		_biblioteca = null
		_janela_nova()))
	topo.add_child(_botao("Abrir a pasta das fases", func():
		DirAccess.make_dir_recursive_absolute(Fase.PASTA)
		OS.shell_open(ProjectSettings.globalize_path(Fase.PASTA))))
	topo.add_child(_botao("Fechar", func():
		_biblioteca.queue_free()
		_biblioteca = null))
	v.add_child(topo)
	v.add_child(_texto_ajuda("Cada fase é um arquivo .json na pasta das fases: dá para mandar para um amigo e ele põe na pasta dele. \"Jogar\" usa o grupo de heróis atual (escolhido em \"Heróis e grupo\")."))
	var rol := ScrollContainer.new()
	rol.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rol.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(rol)
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 6)
	rol.add_child(lista)
	var fases := Fase.listar()
	if fases.is_empty():
		lista.add_child(_label("Nenhuma fase ainda. Clique em \"Nova fase\".", 14, COR_SECUNDARIO))
	for x in fases:
		var id: String = x["id"]
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(_label("%s%s%s" % [x["nome"], "   [exemplo]" if x["exemplo"] else "", "   [no mural]" if x["no_mural"] else ""], 15, COR_TEXTO, true))
		if str(x.get("descricao", "")) != "":
			info.add_child(_label(str(x["descricao"]), 12, COR_SECUNDARIO, false, 560))
		h.add_child(info)
		h.add_child(_botao("Editar", func():
			if _sujo:
				_confirmar("A fase aberta tem mudanças não salvas. Abrir outra mesmo assim?", func():
					_biblioteca.queue_free()
					_biblioteca = null
					_abrir(id))
				return
			_biblioteca.queue_free()
			_biblioteca = null
			_abrir(id)))
		h.add_child(_botao("Jogar", func():
			Sessao.fase_teste = ""
			Sessao.modo = Fase.PREFIXO + id
			Sessao.campanha = false
			Sessao.solo = false
			Sessao.online = false
			Sessao.estado_salvo = ""
			get_tree().change_scene_to_file("res://ui/batalha.tscn")))
		h.add_child(_botao("Duplicar", func():
			Fase.duplicar(id)
			_mostrar_biblioteca()))
		if not x["exemplo"]:
			h.add_child(_botao("Apagar", func():
				_confirmar("Apagar a fase \"%s\"? Não dá para desfazer." % x["nome"], func():
					Fase.apagar(id)
					_mostrar_biblioteca())))
		lista.add_child(h)
		lista.add_child(HSeparator.new())


func _janela_nova() -> void:
	var dados := {"nome": "Fase nova", "largura": 20, "altura": 14}
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	v.add_child(_label("Nova fase", 18, COR_OURO, true))
	_campo_texto(v, "Nome", dados, "nome")
	_campo_numero(v, "Largura (casas)", dados, "largura", 4, Fase.MAXIMO, 20)
	_campo_numero(v, "Altura (casas)", dados, "altura", 4, Fase.MAXIMO, 14)
	var h := HBoxContainer.new()
	h.add_child(_botao("Criar", func():
		_fechar_janela()
		var f := Fase.nova(str(dados["nome"]), int(dados["largura"]), int(dados["altura"]))
		f["id"] = Fase.id_livre(str(dados["nome"]))
		_abrir_fase(f, false)
		_sujo = true
		_atualizar_titulo()))
	h.add_child(_botao("Cancelar", _fechar_janela))
	v.add_child(h)
	_abrir_janela(v)


func _confirmar(texto: String, sim: Callable) -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.add_child(_label(texto, 15, COR_TEXTO, false, 420))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.add_child(_botao("Sim", func():
		_fechar_janela()
		sim.call()))
	h.add_child(_botao("Não", _fechar_janela))
	v.add_child(h)
	_abrir_janela(v)


func _abrir_janela(conteudo: Control) -> void:
	_fechar_janela()
	_janela = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.07, 0.09, 0.99)
	sb.border_color = COR_OURO
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(18)
	_janela.add_theme_stylebox_override("panel", sb)
	_janela.position = Vector2(400, 230)
	_janela.add_child(conteudo)
	add_child(_janela)


func _fechar_janela() -> void:
	if _janela != null and is_instance_valid(_janela):
		_janela.queue_free()
	_janela = null


# --- Peças -------------------------------------------------------------------------------------------

func _label(t: String, tamanho: int, cor: Color, negrito := false, largura := 0) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", _fonte_negrito if negrito else _fonte)
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	if largura > 0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(largura, 0)
	return l


var _icones_caixa := []


## Caixinhas visíveis no tema escuro (a padrão do Godot some no fundo).
func _icone_caixa(marcada: bool) -> Texture2D:
	if _icones_caixa.is_empty():
		for m in [false, true]:
			var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			for i in 16:
				for j in 16:
					var borda := i <= 1 or j <= 1 or i >= 14 or j >= 14
					if borda:
						img.set_pixel(i, j, COR_OURO)
					elif m and i >= 4 and j >= 4 and i <= 11 and j <= 11:
						img.set_pixel(i, j, COR_OURO)
			_icones_caixa.append(ImageTexture.create_from_image(img))
	return _icones_caixa[1 if marcada else 0]


func _estilo_texto(c: Control) -> void:
	c.add_theme_font_override("font", _fonte)
	c.add_theme_font_size_override("font_size", 13)
	if c is CheckBox:
		c.add_theme_icon_override("unchecked", _icone_caixa(false))
		c.add_theme_icon_override("checked", _icone_caixa(true))
		c.add_theme_color_override("font_color", COR_TEXTO)


func _botao(texto: String, acao: Callable) -> Button:
	var bt := Button.new()
	bt.text = texto
	bt.focus_mode = Control.FOCUS_NONE
	bt.add_theme_font_override("font", _fonte)
	bt.add_theme_font_size_override("font_size", 13)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("2a2833")
	sb.border_color = Color("8d733f")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 7
	sb.content_margin_right = 7
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	var sb2 := sb.duplicate()
	sb2.bg_color = Color("3a3446")
	sb2.border_color = COR_OURO
	bt.add_theme_stylebox_override("normal", sb)
	bt.add_theme_stylebox_override("hover", sb2)
	bt.add_theme_stylebox_override("pressed", sb2)
	bt.add_theme_stylebox_override("hover_pressed", sb2)
	bt.add_theme_color_override("font_color", COR_TEXTO)
	bt.add_theme_color_override("font_pressed_color", COR_OURO)
	bt.pressed.connect(acao)
	return bt
