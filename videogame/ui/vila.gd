## Vila de Pedravelha (0.15): a guilda entre as missões.
## Quadro de missões, mercado e forja (moedas: cobre, prata e ouro) e estalagem (descanso longo).
## As regras moram em core/campanha.gd; esta tela só mostra e chama.
extends Control

const Sessao := preload("res://core/sessao.gd")
const Campanha := preload("res://core/campanha.gd")
const Itens := preload("res://core/itens.gd")
const Personagem := preload("res://core/personagem.gd")
const ArteItem := preload("res://ui/arte_item.gd")

const COR_FUNDO := Color("121116")
const COR_PAINEL := Color("1c1b22")
const COR_BORDA := Color("34323d")
const COR_TEXTO := Color("e9e4d8")
const COR_SECUNDARIO := Color("9a95a3")
const COR_OURO := Color("c9a45c")

var _ouro: Label
var _aviso: Label
var _mercado: VBoxContainer
var _estalagem: VBoxContainer
var _missoes: VBoxContainer
var _ferreiro: VBoxContainer
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
	var rede = _rede()
	if rede != null:
		rede.campanha_mudou.connect(func():
			if is_inside_tree():
				_montar())
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
	var sub := _label("A região sangra: fome, mortos que não descansam e goblins nas estradas. A guilda paga os contratos em prata, e a prata paga o que vocês precisam para voltar vivos. (1 ouro = 100 pratas = 1.000 cobres.)", 13, COR_SECUNDARIO)
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
		_aviso.text = "Campanha recomeçada: %s, sem feridas." % Campanha.moeda(Campanha.DINHEIRO_INICIAL)
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


## Jogo em rede (0.26): Rede, se a partida é em rede.
func _rede():
	var r = get_node_or_null("/root/Rede")
	return r if r != null and r.ativo and Sessao.online else null


## Compras, vendas e estalagem: em rede viram pedidos ao anfitrião (a party mora lá).
func _na_campanha(metodo: String, args: Array, depois: Callable) -> void:
	var rede = _rede()
	if rede == null:
		depois.call(Campanha.executar(metodo, args))
		_montar()
		return
	_aviso.text = "Falando com o anfitrião…"
	rede.campanha(metodo, args, func(r):
		if is_inside_tree():
			depois.call(r)
			_montar())


## Em rede, cada jogador compra para os próprios heróis (a bolsa é do grupo).
func _fichas_da_loja() -> Array:
	var fichas := Sessao.fichas_do_grupo()
	var rede = _rede()
	if rede == null:
		return fichas
	var minhas := []
	for i in fichas.size():
		if rede.e_meu("heroi" if i == 0 else "heroi%d" % (i + 1)):
			minhas.append(fichas[i])
	return minhas


func _montar() -> void:
	_ouro.text = "Nível do grupo %d   ·   Bolsa: %s" % [Campanha.nivel(), Campanha.moeda(Campanha.dinheiro())]
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
		# 0.27: fases do editor marcadas com este ciclo entram aqui (não contam para subir de nível).
		var do_editor := Campanha.missoes().filter(func(m): return str(m["id"]).begins_with("fase:") and int(m.get("ciclo", 0)) == int(c["numero"]))
		if c["missoes"].is_empty() and do_editor.is_empty():
			_missoes.add_child(_label("Ainda não há missões neste ciclo.", 12, COR_SECUNDARIO))
		for id in c["missoes"]:
			_cartao_missao(Campanha.missao(id), feitas)
		for m in do_editor:
			_cartao_missao(m, feitas)
	_missoes.add_child(_label("Outros contratos", 15, COR_OURO, true))
	for m in Campanha.missoes():
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
		v.add_child(_label("Pagamento: %d pratas para o grupo" % int(m["recompensa"]) if int(m["recompensa"]) > 0 else "Sem pagamento", 12, COR_OURO))
		var id: String = m["id"]
		var rede = _rede()
		var bp := _botao("Partir", func():
			Sessao.vila_pos = Vector2i(-1, -1)
			if rede != null:
				rede.ir_para(id)
				return
			Sessao.campanha = true
			Sessao.solo = false
			Sessao.modo = id
			get_tree().change_scene_to_file("res://ui/batalha.tscn"))
		if rede != null and not rede.anfitriao:
			bp.disabled = true
			bp.text = "Partir (só o anfitrião escolhe a missão)"
		v.add_child(bp)
	_missoes.add_child(p)


## Lojas (0.25): preços em moedas (Campanha.moeda), espaço que o item ocupa e revenda.
## Mercado da Doroteia: consumíveis, ferramentas, roupas, acessórios, focos e livros.
## Forja do Bruno: armas, armaduras e escudos.
const SECOES := {
	"mercado": [["consumivel", "Consumíveis e runas"], ["mochila", "Ferramentas (mochila)"], ["vestir", "Capas, elmos, botas e acessórios"],
		["foco", "Focos"], ["grimorio", "Grimórios e textos sagrados"]],
	"ferreiro": [["arma", "Armas (vão para a segunda arma)"], ["armadura", "Armaduras (troca a atual)"], ["escudo", "Escudos (troca o atual)"]],
}
var _sel_heroi := {}
var _sel_secao := {}


func _montar_mercado() -> void:
	_montar_loja(_mercado, "mercado")


func _montar_ferreiro() -> void:
	_montar_loja(_ferreiro, "ferreiro")


func _ids_da_secao(secao: String) -> Array:
	match secao:
		"consumivel":
			return Itens.CONSUMIVEIS.keys()
		"mochila":
			return Itens.NAO_CONSUMIVEIS.keys().filter(func(i): return Itens.NAO_CONSUMIVEIS[i].get("espaco", "") == "mochila")
		"vestir":
			return Itens.NAO_CONSUMIVEIS.keys().filter(func(i): return Itens.NAO_CONSUMIVEIS[i].get("espaco", "") != "mochila")
		"foco":
			return Itens.FOCOS.keys().filter(func(i): return i != "nenhum")
		"grimorio":
			return Itens.GRIMORIOS.keys()
		"arma":
			return Itens.ARMAS.keys()
		"armadura":
			return Itens.ARMADURAS.keys().filter(func(i): return i != "nenhuma")
		"escudo":
			return Itens.ESCUDOS.keys().filter(func(i): return i != "nenhum")
	return []


func _montar_loja(corpo: VBoxContainer, tipo: String) -> void:
	_limpar(corpo)
	var fichas := _fichas_da_loja()
	if fichas.is_empty():
		corpo.add_child(_label("Monte o grupo em \"Heróis e grupo\".", 13, COR_SECUNDARIO))
		return
	var linha := HBoxContainer.new()
	linha.add_child(_label("Para: ", 13, COR_SECUNDARIO))
	var ob := OptionButton.new()
	ob.focus_mode = Control.FOCUS_NONE
	for f in fichas:
		ob.add_item(f["nome"])
	ob.select(clampi(int(_sel_heroi.get(tipo, 0)), 0, fichas.size() - 1))
	ob.item_selected.connect(func(i): _sel_heroi[tipo] = i; _montar_loja(corpo, tipo))
	linha.add_child(ob)
	linha.add_child(_label("  Mostrar: ", 13, COR_SECUNDARIO))
	var obs := OptionButton.new()
	obs.focus_mode = Control.FOCUS_NONE
	for sec in SECOES[tipo]:
		obs.add_item(sec[1])
	obs.add_item("Vender")
	var n_sec: int = SECOES[tipo].size()
	obs.select(clampi(int(_sel_secao.get(tipo, 0)), 0, n_sec))
	obs.item_selected.connect(func(i): _sel_secao[tipo] = i; _montar_loja(corpo, tipo))
	linha.add_child(obs)
	corpo.add_child(linha)
	var ficha: Dictionary = fichas[ob.selected]
	var ocup := _label(Personagem.texto_ocupacao(ficha), 11, COR_SECUNDARIO)
	ocup.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ocup.custom_minimum_size = Vector2(360, 0)
	corpo.add_child(ocup)
	if tipo == "ferreiro":
		corpo.add_child(_label("Na mão: %s · segunda: %s · %s · %s" % [Itens.nome(ficha["arma"]),
			Itens.ARMAS.get(ficha.get("arma2", "nenhuma"), {}).get("nome", "nada"), Itens.nome(ficha["armadura"]),
			Itens.nome(ficha["escudo"])], 12, COR_SECUNDARIO))
	var lista := VBoxContainer.new()
	lista.add_theme_constant_override("separation", 3)
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rolagem := ScrollContainer.new()
	rolagem.custom_minimum_size = Vector2(380, 400)
	rolagem.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rolagem.add_child(lista)
	corpo.add_child(rolagem)
	var nome_h: String = ficha["nome"]
	if obs.selected >= n_sec:
		_lista_de_venda(lista, ficha)
		return
	var secao: String = SECOES[tipo][obs.selected][0]
	var ids := _ids_da_secao(secao)
	ids.sort_custom(func(x, y): return Campanha.preco(x) < Campanha.preco(y))
	for id in ids:
		var it: Dictionary = Itens.item(id)
		if not it.get("loja", true):
			continue
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 6)
		ArteItem.adicionar(h, it, Vector2(42, 54))
		var prog: bool = it.get("programado", true)
		var tem := _quantos(ficha, id)
		var nome := _label("%s%s%s" % [it["nome"], "" if prog else " *", ("  (tem %d)" % tem) if tem > 0 else ""], 13, COR_TEXTO)
		nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nome.clip_text = true
		nome.custom_minimum_size = Vector2(150, 0)
		nome.tooltip_text = _dica_item(id, it)
		nome.mouse_filter = Control.MOUSE_FILTER_STOP
		h.add_child(nome)
		var preco := Campanha.preco(id)
		var motivo := Campanha.motivo_sem_venda(id)
		var item_id: String = id
		if motivo == "só por encomenda":
			var be := _botao("Encomendar %s" % Campanha.moeda(preco), func():
				_na_campanha("comprar_item", [nome_h, item_id, true], func(r):
					_aviso.text = str(r) if str(r) != "" else "%s encomenda %s: chega depois da próxima missão vencida." % [nome_h, it["nome"]]))
			be.disabled = Campanha.dinheiro() < preco
			be.tooltip_text = "Encomenda: paga agora e recebe ao voltar da próxima missão vencida."
			h.add_child(be)
		elif motivo != "":
			h.add_child(_label("relíquia", 12, COR_SECUNDARIO))
		else:
			var bt := _botao(Campanha.moeda(preco), func():
				_na_campanha("comprar_item", [nome_h, item_id], func(r):
					_aviso.text = str(r) if str(r) != "" else "%s compra %s." % [nome_h, it["nome"]]))
			bt.disabled = Campanha.dinheiro() < preco
			h.add_child(bt)
		lista.add_child(h)
	lista.add_child(_label("* efeito ainda não programado (vale com o mestre). Relíquias não se compram: só se acham.", 11, COR_SECUNDARIO))


func _quantos(f: Dictionary, id: String) -> int:
	var n: int = f.get("consumiveis", []).count(id) + f.get("mochila", []).count(id) + f.get("acessorios", []).count(id) + f.get("grimorios", []).count(id)
	for chave in ["arma", "arma2", "armadura", "escudo", "foco", "costas", "cabeca", "pes"]:
		if f.get(chave, "") == id:
			n += 1
	return n


func _dica_item(id: String, it: Dictionary) -> String:
	var linhas := PackedStringArray()
	linhas.append("%s · %s" % [it.get("categoria", ""), it.get("raridade", "")])
	if Itens.ARMAS.has(id):
		linhas.append(Itens.descricao_arma(it))
	else:
		linhas.append(str(it.get("texto", "")))
	if it.has("vida") and int(it.get("vida", 0)) > 0:
		linhas.append("Vida %d · Resistência %d" % [int(it["vida"]), int(it.get("resistencia", 0))])
	linhas.append("Ocupa: %d em %s%s" % [int(it.get("ocupa", 1)), Personagem.NOMES_ESPACOS.get(it.get("espaco", ""), ""),
		(" (até %d por espaço)" % int(it["pacote"])) if int(it.get("pacote", 1)) > 1 else ""])
	linhas.append("Loja: %s · revenda %s" % [Campanha.NOMES_MERCADO.get(it.get("mercado", "V"), ""), Campanha.moeda(Campanha.preco_venda(id))])
	if str(it.get("nota", "")) != "":
		linhas.append("No jogo: " + str(it["nota"]))
	return "\n".join(linhas)


## Vender: tudo o que o herói carrega fora das mãos (e a segunda arma).
func _lista_de_venda(lista: VBoxContainer, ficha: Dictionary) -> void:
	var vendaveis := []
	for chave in ["consumiveis", "mochila", "acessorios", "grimorios"]:
		for id in ficha.get(chave, []):
			if not id in vendaveis:
				vendaveis.append(id)
	for chave in ["costas", "cabeca", "pes", "arma2"]:
		var id2: String = str(ficha.get(chave, "nenhum"))
		if not id2 in ["nenhum", "nenhuma"] and not id2 in vendaveis:
			vendaveis.append(id2)
	if vendaveis.is_empty():
		lista.add_child(_label("Nada para vender (a arma na mão, a armadura, o escudo e o foco não se vendem aqui: troque-os comprando outro).", 12, COR_SECUNDARIO))
	var nome_h: String = ficha["nome"]
	for id in vendaveis:
		var it: Dictionary = Itens.item(id)
		var hv := HBoxContainer.new()
		hv.add_theme_constant_override("separation", 6)
		ArteItem.adicionar(hv, it, Vector2(42, 54))
		var nv := _label("%s  (tem %d)" % [it.get("nome", id), _quantos(ficha, id)], 13, COR_TEXTO)
		nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nv.tooltip_text = _dica_item(id, it)
		nv.mouse_filter = Control.MOUSE_FILTER_STOP
		hv.add_child(nv)
		var it_id: String = id
		hv.add_child(_botao("Vender: %s" % Campanha.moeda(Campanha.preco_venda(id)), func():
			_na_campanha("vender", [nome_h, it_id], func(r):
				if r:
					_aviso.text = "%s vende %s." % [nome_h, it.get("nome", it_id)])))
		lista.add_child(hv)


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
	var bt := _botao("Descanso atendido (%s)" % Campanha.moeda(custo), func():
		_na_campanha("descansar", [nomes], func(r):
			_aviso.text = "O grupo dorme na estalagem. Baralhos recompostos." if r else "Dinheiro insuficiente para a estalagem."))
	bt.disabled = not algum or Campanha.dinheiro() < custo
	_estalagem.add_child(bt)
	var nota := _label("O descarte volta ao baralho entre as missões; o exílio, só com o descanso longo. Descanso atendido: 5 pratas por herói (cama, comida e cuidados).", 12, COR_SECUNDARIO)
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
