## Sala do jogo em rede (0.26): criar ou entrar numa sala, escolher a missão ou a party,
## cada jogador escolhe o herói dele. As regras da sala moram em ui/rede.gd.
extends Control

const Sessao := preload("res://core/sessao.gd")
const Personagem := preload("res://core/personagem.gd")
const Prontos := preload("res://core/herois_prontos.gd")
const Party := preload("res://core/party.gd")

const ARQUIVO := "user://rede.json"
const COR_FUNDO := Color("121116")
const COR_PAINEL := Color("1c1b22")
const COR_BORDA := Color("34323d")
const COR_TEXTO := Color("e9e4d8")
const COR_SECUNDARIO := Color("9a95a3")
const COR_OURO := Color("c9a45c")
const COR_AVISO := Color("ffcf8a")

var _rede
var _raiz: VBoxContainer
var _aviso: Label
var _nome: LineEdit
var _ip: LineEdit
var _nome_party: LineEdit
var _fonte: Font
var _fonte_negrito: Font
var _config := {"nome": "", "ip": ""}


func _ready() -> void:
	_fonte = load("res://assets/fontes/DejaVuSans.ttf")
	_fonte_negrito = load("res://assets/fontes/DejaVuSans-Bold.ttf")
	_rede = get_node("/root/Rede")
	Sessao.online = false
	if FileAccess.file_exists(ARQUIVO):
		var d = JSON.parse_string(FileAccess.get_file_as_string(ARQUIVO))
		if d is Dictionary:
			_config.merge(d, true)
	if _config["nome"] == "":
		_config["nome"] = OS.get_environment("USERNAME") if OS.get_environment("USERNAME") != "" else "Jogador"
	var fundo := ColorRect.new()
	fundo.color = COR_FUNDO
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	_raiz = VBoxContainer.new()
	_raiz.position = Vector2(28, 18)
	_raiz.size = Vector2(1224, 684)
	_raiz.add_theme_constant_override("separation", 10)
	add_child(_raiz)
	_rede.lobby_mudou.connect(_montar)
	_rede.mensagem.connect(func(t):
		if is_instance_valid(_aviso):
			_aviso.text = t)
	_montar()
	if _rede.ultimo_aviso != "":
		_aviso.text = _rede.ultimo_aviso
		_rede.ultimo_aviso = ""
	var musica = get_node_or_null("/root/Musica")
	if musica != null:
		musica.tocar("menu")


func _guardar_config() -> void:
	var f := FileAccess.open(ARQUIVO, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(_config))


func _montar() -> void:
	var aviso_antigo: String = _aviso.text if is_instance_valid(_aviso) else ""
	for f in _raiz.get_children():
		_raiz.remove_child(f)
		f.queue_free()
	var topo := HBoxContainer.new()
	var titulo := _label("JOGAR EM REDE", 30, COR_OURO, true)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(titulo)
	topo.add_child(_label("versão %s · porta %d" % [_rede.VERSAO, _rede.PORTA], 13, COR_SECUNDARIO))
	_raiz.add_child(topo)
	if not _rede.ativo:
		_montar_entrada()
	elif _rede.jogadores.is_empty():
		_raiz.add_child(_label("Procurando a sala…", 18, COR_TEXTO))
		_raiz.add_child(_botao("Cancelar", func():
			_rede.sair()
			_montar()))
	else:
		_montar_sala()
	_aviso = _label(aviso_antigo, 14, COR_AVISO)
	_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aviso.custom_minimum_size = Vector2(1200, 0)
	_raiz.add_child(_aviso)


# --- Antes de entrar ----------------------------------------------------------------

func _montar_entrada() -> void:
	var hn := HBoxContainer.new()
	hn.add_theme_constant_override("separation", 10)
	hn.add_child(_label("Seu nome:", 16, COR_TEXTO))
	_nome = LineEdit.new()
	_nome.text = _config["nome"]
	_nome.custom_minimum_size = Vector2(260, 34)
	_nome.max_length = 20
	hn.add_child(_nome)
	_raiz.add_child(hn)
	var colunas := HBoxContainer.new()
	colunas.add_theme_constant_override("separation", 16)
	_raiz.add_child(colunas)
	var v1 := _coluna(colunas, "Criar a sala (anfitrião)", 590)
	var t1 := _label("Quem cria a sala guarda a party e a campanha no próprio computador. Os outros entram com um dos endereços que vão aparecer aqui.", 13, COR_SECUNDARIO)
	t1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t1.custom_minimum_size = Vector2(560, 0)
	v1.add_child(t1)
	v1.add_child(_botao("Criar a sala", func():
		var nome := _nome_valido()
		if nome == "":
			return
		var erro: String = _rede.hospedar(nome)
		if erro != "":
			_aviso.text = erro
		_montar()))
	var v2 := _coluna(colunas, "Entrar numa sala", 590)
	var t2 := _label("Digite o endereço que aparece na tela do anfitrião (no Hamachi, o número 25.x.x.x ao lado do nome do computador dele).", 13, COR_SECUNDARIO)
	t2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t2.custom_minimum_size = Vector2(560, 0)
	v2.add_child(t2)
	var hi := HBoxContainer.new()
	hi.add_theme_constant_override("separation", 8)
	_ip = LineEdit.new()
	_ip.text = _config["ip"]
	_ip.placeholder_text = "ex.: 25.12.34.56 ou 192.168.0.10"
	_ip.custom_minimum_size = Vector2(320, 34)
	hi.add_child(_ip)
	hi.add_child(_botao("Entrar", func():
		var nome := _nome_valido()
		if nome == "" or _ip.text.strip_edges() == "":
			if _ip.text.strip_edges() == "":
				_aviso.text = "Digite o endereço do anfitrião."
			return
		_config["ip"] = _ip.text.strip_edges()
		_guardar_config()
		var erro: String = _rede.entrar(_ip.text, nome)
		if erro != "":
			_aviso.text = erro
		_montar()))
	v2.add_child(hi)
	var ajuda := _label("Como jogar:\n• Mesmo Wi-Fi ou cabo: o anfitrião cria a sala e passa o endereço 192.168.x.x (ou 10.x.x.x) que aparece para ele.\n" +
		"• Hamachi: todos entram na mesma rede do Hamachi; o anfitrião cria a sala e passa o endereço 25.x.x.x.\n" +
		"• Na primeira vez, o Windows pergunta se o Sistema 21 pode usar a rede: marque \"Redes privadas\" e permita (no anfitrião é obrigatório).\n" +
		"• Todos precisam da mesma versão do jogo. Cada jogador traz um herói do próprio computador; o anfitrião pode completar o grupo (até 4).", 13, COR_SECUNDARIO)
	ajuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ajuda.custom_minimum_size = Vector2(1200, 0)
	_raiz.add_child(ajuda)
	_raiz.add_child(_botao("Voltar ao menu", func(): get_tree().change_scene_to_file("res://ui/main.tscn")))


func _nome_valido() -> String:
	var nome := _nome.text.strip_edges()
	if nome == "":
		_aviso.text = "Escreva o seu nome."
		return ""
	_config["nome"] = nome
	_guardar_config()
	return nome


# --- Dentro da sala --------------------------------------------------------------

func _montar_sala() -> void:
	var colunas := HBoxContainer.new()
	colunas.add_theme_constant_override("separation", 14)
	colunas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_raiz.add_child(colunas)
	_montar_jogadores(_coluna(colunas, "Jogadores", 380))
	_montar_partida(_coluna(colunas, "Partida", 380))
	_montar_herois(_coluna(colunas, "Seu herói", 430))
	var baixo := HBoxContainer.new()
	baixo.add_theme_constant_override("separation", 10)
	if _rede.anfitriao:
		var motivo: String = _rede.motivo_sem_comecar()
		var bt := _botao("Começar!", func(): _rede.comecar())
		bt.disabled = motivo != ""
		bt.tooltip_text = motivo
		baixo.add_child(bt)
		if motivo != "":
			baixo.add_child(_label(motivo, 13, COR_SECUNDARIO))
	else:
		baixo.add_child(_label("Esperando o anfitrião começar.", 14, COR_SECUNDARIO))
	var esp := Control.new()
	esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baixo.add_child(esp)
	baixo.add_child(_botao("Fechar a sala" if _rede.anfitriao else "Sair da sala", func():
		_rede.sair()
		_montar()))
	_raiz.add_child(baixo)


func _montar_jogadores(v: VBoxContainer) -> void:
	var peers: Array = _rede.jogadores.keys()
	peers.sort()
	for p in peers:
		var j: Dictionary = _rede.jogadores[p]
		var eu: bool = int(p) == _rede.meu_id()
		var t := _label("%s%s%s" % [j["nome"], "  (anfitrião)" if int(p) == 1 else "", "  ← você" if eu else ""], 15, COR_OURO if eu else COR_TEXTO, true)
		v.add_child(t)
		var hs: Array = j["herois"]
		var l := _label("   " + (", ".join(PackedStringArray(hs)) if not hs.is_empty() else "ainda sem herói"), 13, COR_SECUNDARIO)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(350, 0)
		v.add_child(l)
	v.add_child(_label("Heróis no grupo: %d de %d" % [_rede.total_de_herois(), _rede.MAXIMO_HEROIS], 13, COR_SECUNDARIO))
	if _rede.anfitriao:
		v.add_child(_label("Endereços para os amigos digitarem:", 14, COR_OURO, true))
		var ends: Array = _rede.enderecos()
		if ends.is_empty():
			v.add_child(_label("(nenhuma rede encontrada)", 13, COR_SECUNDARIO))
		for e in ends:
			var h := HBoxContainer.new()
			var le := LineEdit.new()
			le.text = e[0]
			le.editable = false
			le.custom_minimum_size = Vector2(170, 30)
			h.add_child(le)
			h.add_child(_label("  " + e[1], 13, COR_SECUNDARIO))
			v.add_child(h)


func _montar_partida(v: VBoxContainer) -> void:
	var cfg: Dictionary = _rede.config
	if not _rede.anfitriao:
		if cfg["tipo"] == "campanha":
			v.add_child(_label("Campanha em party", 16, COR_TEXTO, true))
			v.add_child(_label("Party: %s" % _rede.party_info.get("nome", "(o anfitrião ainda não escolheu)"), 14, COR_TEXTO))
			var t := _label("A party e a campanha ficam salvas no computador do anfitrião. Você vincula o seu herói uma vez; depois, é só escolhê-lo na lista da party.", 12, COR_SECUNDARIO)
			t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			t.custom_minimum_size = Vector2(350, 0)
			v.add_child(t)
		else:
			var nome := ""
			for m in _rede.MODOS:
				if m[0] == cfg["modo"]:
					nome = m[1]
			if nome == "":
				nome = str(cfg.get("nome_modo", cfg["modo"]))
			v.add_child(_label("Missão avulsa", 16, COR_TEXTO, true))
			v.add_child(_label(nome, 14, COR_TEXTO))
		return
	var ob := OptionButton.new()
	ob.focus_mode = Control.FOCUS_NONE
	ob.add_item("Missão avulsa (cada um traz o seu herói)")
	ob.add_item("Campanha em party (fica salva aqui)")
	ob.select(1 if cfg["tipo"] == "campanha" else 0)
	ob.item_selected.connect(func(i):
		if i == 1:
			var lista: Array = _rede.parties
			_rede.definir_config("campanha", "vila", lista[0]["id"] if not lista.is_empty() else "")
		else:
			_rede.definir_config("avulsa", "arena", ""))
	v.add_child(ob)
	if cfg["tipo"] == "avulsa":
		var om := OptionButton.new()
		om.focus_mode = Control.FOCUS_NONE
		var modos: Array = _rede.modos()
		for i in modos.size():
			om.add_item(modos[i][1])
			if modos[i][0] == cfg["modo"]:
				om.select(i)
		om.item_selected.connect(func(i): _rede.definir_config("avulsa", modos[i][0], ""))
		v.add_child(om)
		return
	v.add_child(_label("Party", 15, COR_OURO, true))
	var lista: Array = _rede.parties
	if lista.is_empty():
		v.add_child(_label("Nenhuma party ainda: crie uma.", 13, COR_SECUNDARIO))
	else:
		var op := OptionButton.new()
		op.focus_mode = Control.FOCUS_NONE
		for i in lista.size():
			op.add_item("%s (%d heróis)" % [lista[i]["nome"], lista[i]["membros"].size()])
			if lista[i]["id"] == cfg["party"]:
				op.select(i)
		op.item_selected.connect(func(i): _rede.definir_config("campanha", "vila", lista[i]["id"]))
		v.add_child(op)
	var hn := HBoxContainer.new()
	_nome_party = LineEdit.new()
	_nome_party.placeholder_text = "nome da party nova"
	_nome_party.custom_minimum_size = Vector2(220, 32)
	_nome_party.max_length = 30
	hn.add_child(_nome_party)
	hn.add_child(_botao("Criar party", func():
		var erro: String = _rede.criar_party(_nome_party.text)
		if erro != "":
			_aviso.text = erro))
	v.add_child(hn)
	if not _rede.party_info.is_empty():
		var t := _label("Membros vinculados ficam nesta party (a ficha deles evolui aqui). Para tirar um herói da party:", 12, COR_SECUNDARIO)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.custom_minimum_size = Vector2(350, 0)
		v.add_child(t)
		for m in _rede.party_info["membros"]:
			var nome: String = m["heroi"]
			var bt := _botao("Tirar %s" % nome, func():
				Party.desvincular(_rede.party_info["id"], nome)
				_rede.parties = Party.listar()
				_rede.definir_config("campanha", "vila", _rede.config["party"]))
			bt.disabled = _rede.quem_escolheu(nome) != 0
			v.add_child(bt)


func _montar_herois(v: VBoxContainer) -> void:
	var eu: int = _rede.meu_id()
	var meus: Array = _rede.jogadores.get(eu, {}).get("herois", [])
	if not meus.is_empty():
		v.add_child(_label("Você joga com:", 14, COR_OURO, true))
		for n in meus:
			var nome: String = n
			var h := HBoxContainer.new()
			var l := _label(nome, 14, COR_TEXTO)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(l)
			h.add_child(_botao("Tirar", func(): _rede.escolher({"tirar": nome})))
			v.add_child(h)
	var lista_meus := Personagem.carregar_todos().filter(func(f): return Personagem.validar(f).is_empty())
	if _rede.config["tipo"] == "campanha":
		if _rede.party_info.is_empty():
			v.add_child(_label("Esperando o anfitrião escolher a party.", 13, COR_SECUNDARIO))
			return
		v.add_child(_label("Heróis da party %s" % _rede.party_info["nome"], 14, COR_OURO, true))
		if _rede.party_info["membros"].is_empty():
			v.add_child(_label("Ninguém vinculado ainda.", 13, COR_SECUNDARIO))
		for m in _rede.party_info["membros"]:
			var nome: String = m["heroi"]
			var quem: int = _rede.quem_escolheu(nome)
			var h := HBoxContainer.new()
			var l := _label("%s · %s (de %s)" % [nome, m["resumo"], m["jogador"]], 13, COR_TEXTO)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			l.clip_text = true
			h.add_child(l)
			if quem == 0:
				h.add_child(_botao("Jogar com este", func(): _rede.escolher({"party": nome})))
			else:
				h.add_child(_label("com %s" % _rede.nome_do_jogador(quem), 12, COR_SECUNDARIO))
			v.add_child(h)
		v.add_child(_label("Vincular um herói deste computador à party", 14, COR_OURO, true))
		_lista_dos_meus(v, lista_meus, "Vincular", func(f): _rede.escolher({"vincular": f}))
	else:
		v.add_child(_label("Heróis deste computador", 14, COR_OURO, true))
		_lista_dos_meus(v, lista_meus, "Levar", func(f): _rede.escolher({"ficha": f}))
	var bt := _botao("Adicionar heróis prontos (um de cada classe)", func():
		Prontos.salvar_prontos()
		_montar())
	v.add_child(bt)
	if eu == 1:
		var t := _label("Você (anfitrião) pode levar mais de um herói para completar o grupo.", 12, COR_SECUNDARIO)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.custom_minimum_size = Vector2(400, 0)
		v.add_child(t)


func _lista_dos_meus(v: VBoxContainer, lista: Array, rotulo: String, acao: Callable) -> void:
	if lista.is_empty():
		v.add_child(_label("Nenhum herói completo aqui. Crie um em \"Criar e editar heróis\" ou use os prontos.", 12, COR_SECUNDARIO))
		return
	var rol := ScrollContainer.new()
	rol.custom_minimum_size = Vector2(410, mini(lista.size(), 6) * 40)
	rol.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var vl := VBoxContainer.new()
	vl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rol.add_child(vl)
	for f in lista:
		var ficha: Dictionary = f
		var h := HBoxContainer.new()
		var l := _label("%s · %s" % [f["nome"], Party.resumo_da_ficha(f)], 13, COR_TEXTO)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.clip_text = true
		h.add_child(l)
		var ja: bool = _rede.quem_escolheu(str(f["nome"])) == _rede.meu_id()
		var bt := _botao(rotulo, func(): acao.call(ficha))
		bt.disabled = ja
		h.add_child(bt)
		vl.add_child(h)
	v.add_child(rol)


# --- Peças -------------------------------------------------------------------------

func _coluna(pai: HBoxContainer, titulo: String, largura: int) -> VBoxContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = COR_PAINEL
	sb.border_color = COR_BORDA
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(12)
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(largura, 0)
	pai.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	v.add_child(_label(titulo, 18, COR_OURO, true))
	return v


func _label(t: String, tamanho: int, cor: Color, negrito := false) -> Label:
	var l := Label.new()
	l.text = t
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
	sb.set_content_margin_all(7)
	var sb2 := sb.duplicate()
	sb2.bg_color = Color("34313f")
	sb2.border_color = COR_OURO
	bt.add_theme_stylebox_override("normal", sb)
	bt.add_theme_stylebox_override("hover", sb2)
	bt.add_theme_stylebox_override("pressed", sb2)
	bt.add_theme_color_override("font_color", COR_TEXTO)
	bt.pressed.connect(acao)
	return bt
