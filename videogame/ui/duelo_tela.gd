## Tela do duelo de teste: a mesa de 21 entre o herói e um goblin.
##
## Atalhos: A = atacar · Espaço = puxar · Enter = parar/continuar ·
## E = encerrar turno · N = novo combate.
extends Control

const Duelo := preload("res://core/duelo.gd")
const Dados := preload("res://core/dados_duelo.gd")
const Teste21 := preload("res://core/teste21.gd")
const Carta := preload("res://core/carta.gd")
const CartaVisual := preload("res://ui/carta_visual.gd")
const MonteVisual := preload("res://ui/monte_visual.gd")

const COR_FUNDO := Color("121116")
const COR_PAINEL := Color("1c1b22")
const COR_BORDA := Color("34323d")
const COR_MESA := Color("1d2a23")
const COR_BORDA_MESA := Color("3d5244")
const COR_TEXTO := Color("e9e4d8")
const COR_SECUNDARIO := Color("9a95a3")
const COR_OURO := Color("c9a45c")
const COR_VIDA_HEROI := Color("6f9e6a")
const COR_VIDA_INIMIGO := Color("b5483f")

const TAM_CARTA_MESA := Vector2(70, 100)
const TAM_CARTA_MAO := Vector2(64, 92)
const PAUSA_IA := 0.55

var duelo: Duelo
var _ocupado := false
var _linhas_mostradas := 0
var _contagem_anterior := {"inimigo": 0, "heroi": 0}

# Elementos da tela
var _rodada: Label
var _ini_nome: Label
var _ini_stats: Label
var _ini_vida_txt: Label
var _ini_vida: ProgressBar
var _linha_ini_titulo: Label
var _linha_ini_cartas: HBoxContainer
var _linha_ini_total: Label
var _linha_her_titulo: Label
var _linha_her_cartas: HBoxContainer
var _linha_her_total: Label
var _monte_ini: MonteVisual
var _monte_her: MonteVisual
var _faixa: Label
var _her_stats: Label
var _her_vida_txt: Label
var _her_vida: ProgressBar
var _her_zonas: Label
var _mao: HBoxContainer
var _bt_atacar: Button
var _bt_puxar: Button
var _bt_parar: Button
var _bt_encerrar: Button
var _bt_continuar: Button
var _registro: RichTextLabel
var _auto: CheckBox
var _semente: Label


func _ready() -> void:
	theme = _criar_tema()
	_montar_tela()
	novo_combate()


# --- Fluxo ------------------------------------------------------------------

func novo_combate(semente := -1) -> void:
	if semente < 0:
		semente = randi() % 100000
	duelo = Duelo.new(Dados.HEROI.duplicate(), Dados.goblin(), semente)
	duelo.defesa_automatica = _auto.button_pressed
	_linhas_mostradas = 0
	_registro.clear()
	_contagem_anterior = {"inimigo": 0, "heroi": 0}
	duelo.iniciar()
	_processar()


func _processar() -> void:
	if _ocupado:
		return
	_ocupado = true
	_atualizar()
	while duelo.fase_automatica():
		await get_tree().create_timer(PAUSA_IA).timeout
		duelo.passo_automatico()
		_atualizar()
	_ocupado = false
	_atualizar()


func _acao(nome: String, carta := -1) -> void:
	if _ocupado:
		return
	match nome:
		"atacar": duelo.atacar()
		"puxar": duelo.puxar()
		"parar": duelo.parar()
		"encerrar": duelo.encerrar_turno()
		"continuar": duelo.continuar()
		"mao": duelo.jogar_da_mao(carta)
	_processar()


func _unhandled_input(evento: InputEvent) -> void:
	var tecla := evento as InputEventKey
	if tecla == null or not tecla.pressed or tecla.echo:
		return
	match tecla.keycode:
		KEY_A: _acao("atacar")
		KEY_SPACE: _acao("puxar")
		KEY_ENTER, KEY_KP_ENTER:
			if duelo.fase == Duelo.Fase.RESOLVIDO:
				_acao("continuar")
			else:
				_acao("parar")
		KEY_E: _acao("encerrar")
		KEY_N: novo_combate()
		KEY_ESCAPE: get_tree().change_scene_to_file("res://ui/main.tscn")
		_: return
	get_viewport().set_input_as_handled()


# --- Atualização ------------------------------------------------------------

func _atualizar() -> void:
	var d := duelo
	var ini := d.inimigo
	var her := d.heroi

	_rodada.text = "Rodada %d · Ordem: %s" % [d.rodada, " → ".join(PackedStringArray(d.ordem.map(func(i): return "Você" if i == "heroi" else "Goblin")))]

	_ini_nome.text = ini["nome"]
	_ini_stats.text = "Ataque +%d · Defesa +%d · Dano %d · Resistência %d · IA %s: para em %d atacando e em %d defendendo" % [
		ini["ataque"], ini["defesa"], ini["dano"], ini["resistencia"], ini["perfil"], ini["parada_ataque"], ini["parada_defesa"]]
	_ini_vida.max_value = ini["vida"]
	_ini_vida.value = d.vida_inimigo
	_ini_vida_txt.text = "Vida %d / %d" % [d.vida_inimigo, ini["vida"]]

	_her_stats.text = "Ataque +%d · Defesa +%d · Dano %d + Força %d · Resistência %d" % [
		her["ataque"], her["defesa"], her["dano_arma"], her["atributo_dano"], her["resistencia"]]
	var b := d.baralho_heroi
	_her_vida.value = b.baralho.size()
	_her_vida_txt.text = "Baralho (sua vida): %d / 52" % b.baralho.size()
	_her_zonas.text = "Mão %d · Descarte %d · Exílio %d" % [b.mao.size(), b.descarte.size(), b.exilio.size()]

	# Mesa
	var mostrar_mesa := d.fase != Duelo.Fase.HEROI_ESCOLHE and d.teste_ataque != null
	var t_ini: Teste21 = null
	var t_her: Teste21 = null
	if mostrar_mesa:
		t_ini = d.teste_defesa if d.atacante == "heroi" else d.teste_ataque
		t_her = d.teste_ataque if d.atacante == "heroi" else d.teste_defesa
	var revelar := d.fase in [Duelo.Fase.RESOLVIDO, Duelo.Fase.VITORIA, Duelo.Fase.DERROTA]
	if t_ini != null:
		_linha_ini_titulo.text = "Goblin %s\n%s +%d" % [
			"defende" if d.atacante == "heroi" else "ataca",
			"Defesa" if d.atacante == "heroi" else "Ataque", t_ini.modificador]
		_linha_her_titulo.text = "Você %s\n%s +%d" % [
			"ataca" if d.atacante == "heroi" else "defende",
			"Ataque" if d.atacante == "heroi" else "Defesa", t_her.modificador]
	else:
		_linha_ini_titulo.text = "Goblin"
		_linha_her_titulo.text = "Você"
	_desenhar_linha(_linha_ini_cartas, t_ini, "inimigo", not (revelar or (t_ini != null and t_ini.estourou)))
	_desenhar_linha(_linha_her_cartas, t_her, "heroi", false)
	_linha_ini_total.text = _texto_total(t_ini, not (revelar or (t_ini != null and t_ini.estourou)))
	_linha_her_total.text = _texto_total(t_her, false)
	_faixa.text = _texto_faixa()
	var pode_puxar := not _ocupado and d.teste_do_heroi() != null and d.teste_do_heroi().pode_puxar()
	_monte_her.configurar(b.baralho.size(), pode_puxar)
	_monte_ini.configurar(d.baralho_inimigo.baralho.size(), false)

	# Mão
	var pode_jogar := d.teste_do_heroi() != null and not _ocupado and d.teste_do_heroi().pode_puxar()
	for filho in _mao.get_children():
		filho.queue_free()
	for c in b.mao:
		var cv := CartaVisual.new()
		cv.configurar(c, false, "", TAM_CARTA_MAO, pode_jogar)
		cv.clicada.connect(func(carta): _acao("mao", carta))
		_mao.add_child(cv)
	if b.mao.is_empty():
		_mao.add_child(_label_simples("(mão vazia)", 14, COR_SECUNDARIO))

	# Botões
	var minha_vez := not _ocupado
	_bt_atacar.disabled = not (minha_vez and d.pode_atacar())
	_bt_encerrar.disabled = not (minha_vez and d.fase == Duelo.Fase.HEROI_ESCOLHE)
	_bt_puxar.disabled = not (minha_vez and d.teste_do_heroi() != null and d.teste_do_heroi().pode_puxar())
	_bt_parar.disabled = not (minha_vez and d.teste_do_heroi() != null)
	_bt_continuar.disabled = not (minha_vez and d.fase == Duelo.Fase.RESOLVIDO)
	_bt_atacar.text = "Atacar (A) · %d ações" % d.acoes_restantes if d.fase == Duelo.Fase.HEROI_ESCOLHE else "Atacar (A)"

	# Registro
	while _linhas_mostradas < d.registro.size():
		var linha: String = d.registro[_linhas_mostradas]
		if linha.begins_with("—"):
			_registro.append_text("\n[color=#c9a45c]%s[/color]\n" % linha)
		else:
			_registro.append_text(linha + "\n")
		_linhas_mostradas += 1
	_semente.text = "Semente do combate: %d" % d.semente


func _desenhar_linha(caixa: HBoxContainer, t: Teste21, lado: String, esconder_fechada: bool) -> void:
	for filho in caixa.get_children():
		filho.queue_free()
	if t == null:
		_contagem_anterior[lado] = 0
		caixa.add_child(_label_simples("aguardando ataque", 14, COR_SECUNDARIO))
		return
	var lista: Array[int] = t.cartas.duplicate()
	if t.carta_do_estouro >= 0:
		lista.append(t.carta_do_estouro)
	for i in lista.size():
		var c := lista[i]
		var virada := esconder_fechada and i == 1
		var cv := CartaVisual.new()
		cv.configurar(c, virada, "", TAM_CARTA_MESA)
		caixa.add_child(cv)
		var rotulo := ""
		if i == 0:
			rotulo = "aberta"
		elif i == 1:
			rotulo = "fechada"
		elif c == t.carta_do_estouro and i == lista.size() - 1:
			rotulo = "estouro"
		elif c in t.da_mao:
			rotulo = "da mão"
		cv.definir_rotulo(rotulo)
		if t.estourou and c != t.carta_do_estouro:
			cv.modulate = Color(1, 1, 1, 0.45)
		if i >= _contagem_anterior[lado]:
			var final_mod := cv.modulate
			cv.modulate.a = 0.0
			create_tween().tween_property(cv, "modulate", final_mod, 0.25)
	_contagem_anterior[lado] = lista.size()


func _texto_total(t: Teste21, esconder_fechada: bool) -> String:
	if t == null:
		return ""
	if t.estourou:
		var ultima := "—" if t.carta_do_estouro < 0 else Carta.nome(t.carta_do_estouro)
		return "ESTOUROU!\nvale a última carta (%s): %d" % [ultima, t.resultado()]
	if esconder_fechada:
		var visiveis := 0
		for i in t.cartas.size():
			if i != 1:
				visiveis += Carta.valor(t.cartas[i]) if not Carta.eh_as(t.cartas[i]) else 11
		return "Cartas visíveis: %d + ?\n%s" % [visiveis, _situacao(t)]
	var crit := "  · CRÍTICO!" if t.critico() else ""
	return "Cartas %d / %d%s\nTeste: %d  (%s)" % [t.soma_cartas(), t.limite, crit, t.resultado(), _situacao(t)]


func _situacao(t: Teste21) -> String:
	if t.encerrado:
		return "parou"
	var d := duelo
	var jogando: Teste21 = null
	match d.fase:
		Duelo.Fase.HEROI_ATACANDO, Duelo.Fase.IA_ATACANDO:
			jogando = d.teste_ataque
		Duelo.Fase.HEROI_DEFENDENDO, Duelo.Fase.IA_DEFENDENDO:
			jogando = d.teste_defesa
	return "jogando" if t == jogando else "aguardando"


func _texto_faixa() -> String:
	var d := duelo
	var nome: String = d.inimigo["nome"]
	match d.fase:
		Duelo.Fase.HEROI_ESCOLHE:
			return "Sua vez · %d %s. Ataque (A) ou encerre o turno (E)." % [d.acoes_restantes, "ação restante" if d.acoes_restantes == 1 else "ações restantes"]
		Duelo.Fase.HEROI_ATACANDO:
			return "Você está atacando: clique no seu baralho para puxar (ou Espaço), jogue uma carta da mão ou pare (Enter)."
		Duelo.Fase.IA_DEFENDENDO:
			return "%s está se defendendo..." % nome
		Duelo.Fase.IA_ATACANDO:
			return "%s está atacando..." % nome
		Duelo.Fase.HEROI_DEFENDENDO:
			if d.defesa_automatica:
				return "Defendendo automaticamente (para em 17)..."
			return "Defenda-se: clique no seu baralho para puxar (ou Espaço), jogue uma carta da mão ou pare (Enter)."
		Duelo.Fase.RESOLVIDO:
			return _texto_resultado() + "   ·   Continuar (Enter)"
		Duelo.Fase.VITORIA:
			return "VITÓRIA! %s   ·   Novo combate (N)" % _texto_resultado()
		Duelo.Fase.DERROTA:
			return "DERROTA: seu baralho acabou.   ·   Novo combate (N)"
	return ""


func _texto_resultado() -> String:
	var r := duelo.resultado
	if r.is_empty():
		return ""
	var dif: int = r["ataque"] - r["defesa"]
	if r["atacante"] == "heroi":
		if not r["acertou"]:
			return "Você errou: %d contra %d." % [r["ataque"], r["defesa"]]
		return "Você acertou: %d contra %d → %d + arma %d + Força %d − resistência %d = %d de dano." % [
			r["ataque"], r["defesa"], dif, r["arma"], r["atributo"], r["resistencia"], r["dano"]]
	if not r["acertou"]:
		return "Você se defendeu: %d contra %d." % [r["ataque"], r["defesa"]]
	return "O goblin acertou: %d contra %d → %d + dano %d − sua resistência %d = %d cartas perdidas." % [
		r["ataque"], r["defesa"], dif, r["arma"], r["resistencia"], r["dano"]]


func _ao_mudar_defesa_automatica(ligado: bool) -> void:
	duelo.defesa_automatica = ligado
	_processar()


# --- Montagem da tela -------------------------------------------------------

func _criar_tema() -> Theme:
	var t := Theme.new()
	t.default_font = load("res://assets/fontes/DejaVuSans.ttf")
	t.default_font_size = 16
	t.set_color("font_color", "Label", COR_TEXTO)
	t.set_color("font_color", "CheckBox", COR_TEXTO)
	t.set_color("default_color", "RichTextLabel", COR_TEXTO)
	var normal := _caixa(Color("2a2833"), COR_OURO.darkened(0.3), 6)
	var foco := _caixa(Color("34313f"), COR_OURO, 6)
	var desligado := _caixa(Color("1f1e25"), COR_BORDA, 6)
	for estado in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb: StyleBoxFlat = normal
		if estado in ["hover", "pressed", "focus"]:
			sb = foco
		elif estado == "disabled":
			sb = desligado
		t.set_stylebox(estado, "Button", sb)
	t.set_color("font_color", "Button", COR_TEXTO)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color("5d5a66"))
	return t


func _caixa(fundo: Color, borda: Color, raio := 10, margem := 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fundo
	sb.border_color = borda
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(raio)
	sb.set_content_margin_all(margem)
	return sb


func _painel(fundo := COR_PAINEL, borda := COR_BORDA) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _caixa(fundo, borda, 10, 14))
	return p


func _label_simples(texto: String, tamanho := 16, cor := COR_TEXTO, negrito := false) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	if negrito:
		l.add_theme_font_override("font", load("res://assets/fontes/DejaVuSans-Bold.ttf"))
	return l


func _barra(cor: Color, largura: int) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(largura, 14)
	var fundo := _caixa(Color("2a2833"), Color("2a2833"), 4, 0)
	var cheio := _caixa(cor, cor, 4, 0)
	pb.add_theme_stylebox_override("background", fundo)
	pb.add_theme_stylebox_override("fill", cheio)
	return pb


func _espaco() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


func _botao(texto: String, acao: String) -> Button:
	var bt := Button.new()
	bt.text = texto
	bt.custom_minimum_size = Vector2(0, 40)
	bt.focus_mode = Control.FOCUS_NONE
	bt.pressed.connect(func(): _acao(acao))
	return bt


func _linha_mesa(titulo_ref: String) -> Array:
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 12)
	linha.custom_minimum_size = Vector2(0, 116)
	var titulo := _label_simples("", 16, COR_TEXTO, true)
	titulo.custom_minimum_size = Vector2(124, 0)
	titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	linha.add_child(titulo)
	var monte := MonteVisual.new()
	monte.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(monte)
	var cartas := HBoxContainer.new()
	cartas.add_theme_constant_override("separation", 8)
	cartas.alignment = BoxContainer.ALIGNMENT_BEGIN
	cartas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(cartas)
	var total := _label_simples("", 16, COR_TEXTO)
	total.custom_minimum_size = Vector2(190, 0)
	total.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	total.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	linha.add_child(total)
	return [linha, titulo, cartas, total, monte]


func _montar_tela() -> void:
	var fundo := ColorRect.new()
	fundo.color = COR_FUNDO
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	var margem := MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 16)
	add_child(margem)

	var colunas := HBoxContainer.new()
	colunas.add_theme_constant_override("separation", 16)
	margem.add_child(colunas)

	var esq := VBoxContainer.new()
	esq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	esq.add_theme_constant_override("separation", 12)
	colunas.add_child(esq)

	# Topo
	var topo := HBoxContainer.new()
	var titulo := _label_simples("SISTEMA 21 · Duelo de teste", 22, COR_OURO)
	titulo.add_theme_font_override("font", load("res://assets/fontes/DejaVuSerif-Bold.ttf"))
	topo.add_child(titulo)
	topo.add_child(_espaco())
	_rodada = _label_simples("", 15, COR_SECUNDARIO)
	topo.add_child(_rodada)
	esq.add_child(topo)

	# Inimigo
	var p_ini := _painel()
	var h_ini := HBoxContainer.new()
	p_ini.add_child(h_ini)
	var v_ini := VBoxContainer.new()
	v_ini.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ini_nome = _label_simples("", 20, COR_TEXTO, true)
	_ini_stats = _label_simples("", 13, COR_SECUNDARIO)
	_ini_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v_ini.add_child(_ini_nome)
	v_ini.add_child(_ini_stats)
	h_ini.add_child(v_ini)
	var v_vida_ini := VBoxContainer.new()
	v_vida_ini.alignment = BoxContainer.ALIGNMENT_CENTER
	_ini_vida_txt = _label_simples("", 15)
	_ini_vida_txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_ini_vida = _barra(COR_VIDA_INIMIGO, 240)
	v_vida_ini.add_child(_ini_vida_txt)
	v_vida_ini.add_child(_ini_vida)
	h_ini.add_child(v_vida_ini)
	esq.add_child(p_ini)

	# Mesa
	var mesa := _painel(COR_MESA, COR_BORDA_MESA)
	mesa.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var v_mesa := VBoxContainer.new()
	v_mesa.alignment = BoxContainer.ALIGNMENT_CENTER
	v_mesa.add_theme_constant_override("separation", 10)
	mesa.add_child(v_mesa)
	var li := _linha_mesa("inimigo")
	_linha_ini_titulo = li[1]; _linha_ini_cartas = li[2]; _linha_ini_total = li[3]; _monte_ini = li[4]
	_monte_ini.dica_padrao = "Baralho compartilhado dos inimigos (não é a vida deles)"
	v_mesa.add_child(li[0])
	_faixa = _label_simples("", 16, COR_OURO, true)
	_faixa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_faixa.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_faixa.custom_minimum_size = Vector2(0, 48)
	_faixa.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	v_mesa.add_child(_faixa)
	var lh := _linha_mesa("heroi")
	_linha_her_titulo = lh[1]; _linha_her_cartas = lh[2]; _linha_her_total = lh[3]; _monte_her = lh[4]
	_monte_her.clicado.connect(func(): _acao("puxar"))
	v_mesa.add_child(lh[0])
	esq.add_child(mesa)

	# Herói
	var p_her := _painel()
	var v_her := VBoxContainer.new()
	v_her.add_theme_constant_override("separation", 10)
	p_her.add_child(v_her)
	var h_her := HBoxContainer.new()
	var v_her_info := VBoxContainer.new()
	v_her_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v_her_info.add_child(_label_simples("Guerreiro (você)", 20, COR_TEXTO, true))
	_her_stats = _label_simples("", 13, COR_SECUNDARIO)
	v_her_info.add_child(_her_stats)
	h_her.add_child(v_her_info)
	var v_vida_her := VBoxContainer.new()
	_her_vida_txt = _label_simples("", 15)
	_her_vida_txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_her_vida = _barra(COR_VIDA_HEROI, 240)
	_her_vida.max_value = 52
	_her_zonas = _label_simples("", 13, COR_SECUNDARIO)
	_her_zonas.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v_vida_her.add_child(_her_vida_txt)
	v_vida_her.add_child(_her_vida)
	v_vida_her.add_child(_her_zonas)
	h_her.add_child(v_vida_her)
	v_her.add_child(h_her)

	var h_acoes := HBoxContainer.new()
	h_acoes.add_theme_constant_override("separation", 10)
	var rot_mao := _label_simples("Mão", 14, COR_SECUNDARIO, true)
	rot_mao.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h_acoes.add_child(rot_mao)
	_mao = HBoxContainer.new()
	_mao.add_theme_constant_override("separation", 6)
	_mao.custom_minimum_size = Vector2(0, TAM_CARTA_MAO.y)
	h_acoes.add_child(_mao)
	h_acoes.add_child(_espaco())
	var grade := GridContainer.new()
	grade.columns = 3
	grade.add_theme_constant_override("h_separation", 8)
	grade.add_theme_constant_override("v_separation", 8)
	_bt_atacar = _botao("Atacar (A)", "atacar")
	_bt_puxar = _botao("Puxar (Espaço)", "puxar")
	_bt_parar = _botao("Parar (Enter)", "parar")
	_bt_encerrar = _botao("Encerrar turno (E)", "encerrar")
	_bt_continuar = _botao("Continuar (Enter)", "continuar")
	for bt in [_bt_atacar, _bt_puxar, _bt_parar, _bt_encerrar, _bt_continuar]:
		bt.custom_minimum_size.x = 168
		grade.add_child(bt)
	h_acoes.add_child(grade)
	v_her.add_child(h_acoes)
	esq.add_child(p_her)

	# Coluna direita
	var dir := VBoxContainer.new()
	dir.custom_minimum_size = Vector2(320, 0)
	dir.add_theme_constant_override("separation", 10)
	colunas.add_child(dir)
	dir.add_child(_label_simples("Registro do combate", 16, COR_OURO, true))
	var p_reg := _painel()
	p_reg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_registro = RichTextLabel.new()
	_registro.bbcode_enabled = true
	_registro.scroll_following = true
	_registro.add_theme_font_size_override("normal_font_size", 13)
	p_reg.add_child(_registro)
	dir.add_child(p_reg)
	_auto = CheckBox.new()
	_auto.text = "Defesa automática (para em 17)"
	_auto.focus_mode = Control.FOCUS_NONE
	_auto.toggled.connect(_ao_mudar_defesa_automatica)
	dir.add_child(_auto)
	var ajuda := _label_simples("Clique no seu baralho (o monte na mesa) para puxar uma carta. Clique numa carta da mão para jogá-la no teste (ela conta para estourar). O Ás vale 1 ou 11 sozinho.", 12, COR_SECUNDARIO)
	ajuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dir.add_child(ajuda)
	_semente = _label_simples("", 12, COR_SECUNDARIO)
	dir.add_child(_semente)
	var bt_novo := Button.new()
	bt_novo.text = "Novo combate (N)"
	bt_novo.custom_minimum_size = Vector2(0, 40)
	bt_novo.focus_mode = Control.FOCUS_NONE
	bt_novo.pressed.connect(func(): novo_combate())
	dir.add_child(bt_novo)
