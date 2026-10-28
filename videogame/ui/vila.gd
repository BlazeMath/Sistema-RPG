## Vila de Pedravelha (0.15): a guilda entre as missões.
## Quadro de missões, mercado (consumíveis com ouro) e estalagem (descanso longo).
## As regras moram em core/campanha.gd; esta tela só mostra e chama.
extends Control

const Sessao := preload("res://core/sessao.gd")
const Campanha := preload("res://core/campanha.gd")
const Itens := preload("res://core/itens.gd")

const COR_FUNDO := Color("121116")
const COR_PAINEL := Color("1c1b22")
const COR_BORDA := Color("34323d")
const COR_TEXTO := Color("e9e4d8")
const COR_SECUNDARIO := Color("9a95a3")
const COR_OURO := Color("c9a45c")

var _ouro: Label
var _aviso: Label
var _heroi: OptionButton
var _mercado: VBoxContainer
var _estalagem: VBoxContainer
var _missoes: VBoxContainer
var _ferreiro: VBoxContainer
var _heroi_f: OptionButton
## 0.23: aberta por dentro da vila andável. "missoes", "mercado", "ferreiro" ou "estalagem":
## mostra só aquele lugar, com um botão de voltar para a rua.
var aba := ""
var _fonte: Font
var _fonte_negrito: Font
var _saves
var _pausa


func _ready() -> void:
	_fonte = load("res://assets/fontes/DejaVuSans.ttf")
	_fonte_negrito = load("res://assets/fontes/DejaVuSans-Bold.ttf") if ResourceLoader.exists("res://assets/fontes/DejaVuSans-Bold.ttf") else _fonte
	Sessao.solo = false
	Campanha.carregar()
	var fundo := ColorRect.new()
	fundo.color = COR_FUNDO
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	var raiz := VBoxContainer.new()
	raiz.position = Vector2(24, 18)
	raiz.size = Vector2(1232, 684)
	raiz.add_theme_constant_override("separation", 12)
	add_child(raiz)
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 24)
	raiz.add_child(topo)
	var titulo := _label("VILA DE PEDRAVELHA · Guilda dos Aventureiros", 24, COR_OURO, true)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(titulo)
	_ouro = _label("", 20, COR_OURO, true)
	topo.add_child(_ouro)
	var sub := _label("A região sangra: fome, mortos que não descansam e goblins nas estradas. A guilda aceita contratos por ouro, e o ouro paga o que vocês precisam para voltar vivos.", 13, COR_SECUNDARIO)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	raiz.add_child(sub)
	var colunas := HBoxContainer.new()
	colunas.add_theme_constant_override("separation", 14)
	colunas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	raiz.add_child(colunas)
	_missoes = _coluna(colunas, "Quadro de missões", 420)
	_mercado = _coluna(colunas, "Mercado", 400)
	_ferreiro = _coluna(colunas, "Forja do Bruno", 400)
	_estalagem = _coluna(colunas, "Estalagem do Corvo", 380)
	_ferreiro.get_parent().get_parent().visible = aba == "ferreiro"
	var baixo := HBoxContainer.new()
	baixo.add_theme_constant_override("separation", 10)
	raiz.add_child(baixo)
	_aviso = _label("", 14, COR_TEXTO)
	_aviso.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baixo.add_child(_aviso)
	if aba != "":
		# Dentro de um prédio da vila andável: só aquele lugar e o botão de voltar.
		titulo.text = {"missoes": "MURAL DA GUILDA", "mercado": "MERCADO DA DOROTEIA", "ferreiro": "FORJA DO BRUNO", "estalagem": "ESTALAGEM DO CORVO"}.get(aba, "VILA")
		for par in [[_missoes, "missoes"], [_mercado, "mercado"], [_ferreiro, "ferreiro"], [_estalagem, "estalagem"]]:
			par[0].get_parent().get_parent().visible = par[1] == aba
			if par[1] == aba:
				par[0].get_parent().get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
		baixo.add_child(_botao("Voltar para a rua (Esc)", func(): queue_free()))
		_montar()
		return
	baixo.add_child(_botao("Salvar jogo", func(): _saves.abrir("salvar")))
	baixo.add_child(_botao("Carregar jogo", func(): _saves.abrir("carregar")))
	baixo.add_child(_botao("Heróis e grupo", func(): get_tree().change_scene_to_file("res://ui/criacao.tscn")))
	baixo.add_child(_botao("Recomeçar campanha", func():
		Campanha.reiniciar()
		_aviso.text = "Campanha recomeçada: %d de ouro, sem feridas." % Campanha.OURO_INICIAL
		_montar()))
	baixo.add_child(_botao("Menu", func(): get_tree().change_scene_to_file("res://ui/main.tscn")))
	_saves = load("res://ui/janela_saves.gd").new()
	add_child(_saves)
	_saves.depois_de_carregar = func(msg):
		_aviso.text = msg
		_montar()
	_pausa = load("res://ui/menu_pausa.gd").new()
	add_child(_pausa)
	_pausa.ao_salvar = func():
		_saves.abrir("salvar")
		_pausa.fechar()
		return ""
	_montar()
	var musica = get_node_or_null("/root/Musica")
	if musica != null:
		musica.tocar("menu")


func _montar() -> void:
	_ouro.text = "Nível do grupo %d   ·   Ouro: %d" % [Campanha.nivel(), Campanha.ouro()]
	_montar_missoes()
	_montar_mercado()
	_montar_ferreiro()
	_montar_estalagem()


func _montar_missoes() -> void:
	_limpar(_missoes)
	var feitas: Array = Campanha.carregar()["concluidas"]
	# Ciclos da campanha (0.19): três missões por ciclo; cada uma abre a seguinte.
	for c in Campanha.CICLOS:
		var cab := _label("Ciclo %d · %s%s" % [int(c["numero"]), c["nome"], "  ✔" if Campanha.ciclo_completo(int(c["numero"])) else ""], 15, COR_OURO, true)
		_missoes.add_child(cab)
		if c["missoes"].is_empty():
			_missoes.add_child(_label("Ainda não há missões neste ciclo.", 12, COR_SECUNDARIO))
		for id in c["missoes"]:
			_cartao_missao(Campanha.missao(id), feitas)
	_missoes.add_child(_label("Outros contratos", 15, COR_OURO, true))
	for m in Campanha.MISSOES:
		if not m.has("ciclo"):
			_cartao_missao(m, feitas)


func _cartao_missao(m: Dictionary, feitas: Array) -> void:
	var p := _painel()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	var trancada := Campanha.motivo_trancada(m["id"])
	v.add_child(_label(("[trancada] " if trancada != "" else "") + m["nome"] + ("  ✔" if m["id"] in feitas else ""), 16, COR_TEXTO if trancada == "" else COR_SECUNDARIO, true))
	var t := _label(m["texto"] if trancada == "" else trancada, 12, COR_SECUNDARIO)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(380, 0)
	v.add_child(t)
	if trancada == "":
		v.add_child(_label("Pagamento: %d de ouro" % int(m["recompensa"]) if int(m["recompensa"]) > 0 else "Sem pagamento", 12, COR_OURO))
		var id: String = m["id"]
		v.add_child(_botao("Partir", func():
			Sessao.vila_pos = Vector2i(-1, -1)
			Sessao.campanha = true
			Sessao.solo = false
			Sessao.modo = id
			get_tree().change_scene_to_file("res://ui/batalha.tscn")))
	_missoes.add_child(p)


func _montar_mercado() -> void:
	_limpar(_mercado)
	var fichas := Sessao.fichas_do_grupo()
	var linha := HBoxContainer.new()
	linha.add_child(_label("Comprar para: ", 13, COR_SECUNDARIO))
	var antes := _heroi.get_item_text(_heroi.selected) if _heroi != null and _heroi.selected >= 0 else ""
	_heroi = OptionButton.new()
	for f in fichas:
		_heroi.add_item(f["nome"])
		if f["nome"] == antes:
			_heroi.select(_heroi.item_count - 1)
	_heroi.item_selected.connect(func(_i): _montar_mercado())
	linha.add_child(_heroi)
	_mercado.add_child(linha)
	if fichas.is_empty():
		return
	var ficha: Dictionary = fichas[maxi(_heroi.selected, 0)]
	var lista := VBoxContainer.new()
	lista.add_theme_constant_override("separation", 4)
	var rolagem := ScrollContainer.new()
	rolagem.custom_minimum_size = Vector2(380, 470)
	rolagem.add_child(lista)
	_mercado.add_child(rolagem)
	for item in Itens.CONSUMIVEIS:
		var it: Dictionary = Itens.CONSUMIVEIS[item]
		if not it.get("loja", true):
			continue
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		var nome := _label("%s  (tem %d)" % [it["nome"], ficha["consumiveis"].count(item)], 13, COR_TEXTO)
		nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nome.tooltip_text = it.get("texto", "")
		nome.mouse_filter = Control.MOUSE_FILTER_STOP
		h.add_child(nome)
		var preco := Campanha.preco(item)
		var nome_heroi: String = ficha["nome"]
		var bt := _botao("%d ouro" % preco, func():
			if Campanha.comprar(nome_heroi, item):
				_aviso.text = "%s compra %s." % [nome_heroi, it["nome"]]
			else:
				_aviso.text = "Ouro insuficiente (ou herói não salvo)."
			_montar())
		bt.disabled = Campanha.ouro() < preco
		h.add_child(bt)
		lista.add_child(h)
	# Vender (0.23): o que o herói carrega; achados valiosos (gemas, lascas) valem mais.
	var vendaveis := {}
	for item in ficha["consumiveis"]:
		vendaveis[item] = true
	if not vendaveis.is_empty():
		lista.add_child(_label("Vender", 15, COR_OURO, true))
	for item in vendaveis:
		var it_v: Dictionary = Itens.CONSUMIVEIS.get(item, {"nome": item})
		var hv := HBoxContainer.new()
		var nv := _label("%s  (tem %d)" % [it_v.get("nome", item), ficha["consumiveis"].count(item)], 13, COR_TEXTO)
		nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hv.add_child(nv)
		var nome_h: String = ficha["nome"]
		var it_id: String = item
		hv.add_child(_botao("Vender: %d ouro" % Campanha.preco_venda(item), func():
			if Campanha.vender(nome_h, it_id):
				_aviso.text = "%s vende %s." % [nome_h, it_v.get("nome", it_id)]
			_montar()))
		lista.add_child(hv)


## Forja (0.23): armas (vão para a mão reserva), armaduras e escudos.
func _montar_ferreiro() -> void:
	_limpar(_ferreiro)
	var fichas := Sessao.fichas_do_grupo()
	if fichas.is_empty():
		return
	var linha := HBoxContainer.new()
	linha.add_child(_label("Comprar para: ", 13, COR_SECUNDARIO))
	var antes := _heroi_f.get_item_text(_heroi_f.selected) if _heroi_f != null and _heroi_f.selected >= 0 else ""
	_heroi_f = OptionButton.new()
	for f in fichas:
		_heroi_f.add_item(f["nome"])
		if f["nome"] == antes:
			_heroi_f.select(_heroi_f.item_count - 1)
	_heroi_f.item_selected.connect(func(_i): _montar_ferreiro())
	linha.add_child(_heroi_f)
	_ferreiro.add_child(linha)
	var ficha: Dictionary = fichas[maxi(_heroi_f.selected, 0)]
	_ferreiro.add_child(_label("Na mão: %s · reserva: %s · %s · %s" % [Itens.ARMAS.get(ficha["arma"], {}).get("nome", "-"),
		Itens.ARMAS.get(ficha.get("arma2", "nenhuma"), {}).get("nome", "nada"), Itens.ARMADURAS.get(ficha["armadura"], {}).get("nome", "-"),
		Itens.ESCUDOS.get(ficha["escudo"], {}).get("nome", "-")], 12, COR_SECUNDARIO))
	var lista := VBoxContainer.new()
	var rolagem := ScrollContainer.new()
	rolagem.custom_minimum_size = Vector2(380, 440)
	rolagem.add_child(lista)
	_ferreiro.add_child(rolagem)
	for grupo in [["arma", Itens.ARMAS, "Armas (vão para a reserva)"], ["armadura", Itens.ARMADURAS, "Armaduras"], ["escudo", Itens.ESCUDOS, "Escudos"]]:
		lista.add_child(_label(grupo[2], 15, COR_OURO, true))
		for id in grupo[1]:
			if id in ["nenhuma", "nenhum"]:
				continue
			var it: Dictionary = grupo[1][id]
			var h := HBoxContainer.new()
			var nome := _label(it["nome"], 13, COR_TEXTO)
			nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			nome.tooltip_text = it.get("texto", "dano %s, %s" % [str(it.get("dano", "")), str(it.get("tipo_dano", ""))])
			nome.mouse_filter = Control.MOUSE_FILTER_STOP
			h.add_child(nome)
			var preco := Campanha.preco_equip(grupo[0], id)
			var nome_h: String = ficha["nome"]
			var campo: String = grupo[0]
			var item_id: String = id
			var bt := _botao("%d ouro" % preco, func():
				var r := Campanha.comprar_equip(nome_h, campo, item_id)
				_aviso.text = r if r != "" else "%s compra %s." % [nome_h, it["nome"]]
				_montar())
			bt.disabled = Campanha.ouro() < preco
			h.add_child(bt)
			lista.add_child(h)


func _montar_estalagem() -> void:
	_limpar(_estalagem)
	var fichas := Sessao.fichas_do_grupo()
	var nomes := []
	var algum := false
	for f in fichas:
		nomes.append(f["nome"])
		var fe := Campanha.feridas_de(f["nome"])
		var perdeu := int(fe.get("exilio", 0))
		algum = algum or perdeu > 0
		var t := _label("%s (%s): %s" % [f["nome"], f["classe"],
			"inteiro (52 cartas)" if perdeu == 0 else "%d carta(s) no exílio → começa a próxima missão com %d cartas" % [perdeu, 52 - perdeu]],
			13, COR_TEXTO if perdeu == 0 else Color("e0a080"))
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.custom_minimum_size = Vector2(350, 0)
		_estalagem.add_child(t)
	var custo := Campanha.custo_descanso(nomes)
	var bt := _botao("Descanso longo (%d ouro)" % custo, func():
		if Campanha.descansar(nomes):
			_aviso.text = "O grupo dorme na estalagem. Baralhos recompostos."
		else:
			_aviso.text = "Ouro insuficiente para a estalagem."
		_montar())
	bt.disabled = not algum or Campanha.ouro() < custo
	_estalagem.add_child(bt)
	var nota := _label("O descarte volta ao baralho entre as missões; o exílio, só com o descanso longo.", 12, COR_SECUNDARIO)
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nota.custom_minimum_size = Vector2(350, 0)
	_estalagem.add_child(nota)


# --- Peças ---------------------------------------------------------------------------

func _coluna(pai: Control, titulo: String, largura: int) -> VBoxContainer:
	var p := _painel()
	p.custom_minimum_size = Vector2(largura, 0)
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pai.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	v.add_child(_label(titulo, 18, COR_OURO, true))
	var corpo := VBoxContainer.new()
	corpo.add_theme_constant_override("separation", 8)
	v.add_child(corpo)
	return corpo


func _painel() -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = COR_PAINEL
	sb.border_color = COR_BORDA
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(10)
	p.add_theme_stylebox_override("panel", sb)
	return p


func _label(texto: String, tamanho: int, cor: Color, negrito := false) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_override("font", _fonte_negrito if negrito else _fonte)
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	return l


func _botao(texto: String, acao: Callable) -> Button:
	var bt := Button.new()
	bt.text = texto
	bt.focus_mode = Control.FOCUS_NONE
	bt.add_theme_font_override("font", _fonte)
	bt.add_theme_font_size_override("font_size", 14)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("2a2833")
	sb.border_color = Color("8d733f")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(6)
	var sb2 := sb.duplicate()
	sb2.bg_color = Color("34313f")
	sb2.border_color = COR_OURO
	bt.add_theme_stylebox_override("normal", sb)
	bt.add_theme_stylebox_override("hover", sb2)
	bt.add_theme_stylebox_override("pressed", sb2)
	bt.add_theme_color_override("font_color", COR_TEXTO)
	bt.pressed.connect(acao)
	return bt


func _limpar(no: Node) -> void:
	for f in no.get_children():
		f.queue_free()



func _unhandled_input(evento: InputEvent) -> void:
	if aba != "" and evento is InputEventKey and evento.pressed and evento.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		queue_free()
		return
	if evento is InputEventKey and evento.pressed and not evento.echo and evento.keycode == KEY_ESCAPE:
		if _saves.visible:
			_saves.visible = false
		elif not _pausa.visible:
			_pausa.abrir()
		get_viewport().set_input_as_handled()
