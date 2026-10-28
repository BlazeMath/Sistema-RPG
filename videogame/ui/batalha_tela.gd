## Tela do grid isométrico (versão de teste 0.6): X1, arena e exploração.
##
## Mouse: clique num quadrado azul para andar; clique num inimigo marcado em
## vermelho para atacar; clique num marcador "!" para interagir. Teclas:
## Espaço = puxar · Enter = parar/continuar/confirmar · E = encerrar turno ·
## I = inventário · N = recomeçar · Esc = fechar janela / menu.
extends Node3D

const Modelos := preload("res://ui/modelos.gd")
const Instantaneo := preload("res://core/instantaneo.gd")
const Batalha := preload("res://core/batalha.gd")
const Dados := preload("res://core/dados_batalha.gd")
const Exploracao := preload("res://core/dados_exploracao.gd")
const Fazenda := preload("res://core/dados_fazenda.gd")
const Masmorra := preload("res://core/dados_masmorra.gd")
const Pantano := preload("res://core/dados_pantano.gd")
const Tutorial := preload("res://core/dados_tutorial.gd")
const Vila := preload("res://core/dados_vila.gd")
const Catacumbas := preload("res://core/dados_catacumbas.gd")
const Sessao := preload("res://core/sessao.gd")
const Campanha := preload("res://core/campanha.gd")
const Itens := preload("res://core/itens.gd")
const Personagem := preload("res://core/personagem.gd")
const Grade := preload("res://core/grade.gd")
const Areas := preload("res://core/areas.gd")
const Teste21 := preload("res://core/teste21.gd")
const Carta := preload("res://core/carta.gd")
const Combate := preload("res://core/combate.gd")
const Reacoes := preload("res://core/reacoes_monstros.gd")
const CartaVisual := preload("res://ui/carta_visual.gd")
const MonteVisual := preload("res://ui/monte_visual.gd")

const COR_FUNDO := Color("121116")
const COR_PAINEL := Color(0.11, 0.105, 0.135, 0.94)
const COR_BORDA := Color("34323d")
const COR_MESA := Color(0.114, 0.165, 0.137, 1.0)
const COR_BORDA_MESA := Color("3d5244")
const COR_TEXTO := Color("e9e4d8")
const COR_SECUNDARIO := Color("9a95a3")
const COR_OURO := Color("c9a45c")
const COR_VIDA_HEROI := Color("6f9e6a")
const COR_VIDA_INIMIGO := Color("b5483f")
const TAM_CARTA_MESA := Vector2(46, 66)
const TAM_CARTA_MAO := Vector2(56, 80)
const TAM_CARTA_MAO_LEQUE := Vector2(66, 94)
const PAUSA_IA := 0.45

var batalha: Batalha
var _ocupado := false
var _geracao := 0   # muda a cada nova batalha; animações antigas param sozinhas
var _linhas_mostradas := 0
var _hover := Vector2i(-99, -99)
var _contagem := {"inimigo": 0, "heroi": 0}

# Mundo 3D
var _camera: Camera3D
var _marcas: Node3D
var _pecas := {}   # id -> Node3D
var _rotulos := {} # id -> Label3D
var _anel: MeshInstance3D
var _fonte: Font
var _fonte_negrito: Font

# Interface
var _hud: Control
var _rodada: Label
var _ordem: VBoxContainer
var _dica: Label
var _her_nome: Label
var _her_vida_txt: Label
var _her_vida: HBoxContainer   # barra em partes (0.20): baralho, mão, descarte, exílio
var _her_zonas: Label
var _acoes: Label
var _mao: Control
var _bt_concentrar: Button
var _bt_folego: Button
var _bt_planejar: Button
var _bt_encerrar: Button
var _auto: CheckBox
var _auto_dist: CheckBox
var _registro: RichTextLabel
var _mesa: PanelContainer
var _mesa_ini_titulo: Label
var _mesa_ini_monte: MonteVisual
var _mesa_ini_cartas: HBoxContainer
var _mesa_ini_total: Label
var _mesa_her_titulo: Label
var _mesa_her_monte: MonteVisual
var _mesa_her_cartas: HBoxContainer
var _mesa_her_total: Label
var _mesa_faixa: Label
var _bt_puxar: Button
var _bt_parar: Button
var _bt_continuar: Button
var _planejar: PanelContainer
var _planejar_cartas: HBoxContainer
var _fim: PanelContainer
var _fim_titulo: Label
var _titulo: Label
var _her_stats: Label
var _itens: HBoxContainer
var _cartas_lista: VBoxContainer
var _mesa_extras: HBoxContainer
var _escolha_fadiga: PanelContainer
var _escolha_fadiga_bts: VBoxContainer
var _planejar_titulo: Label
var _planejar_bts: HBoxContainer
var _modo_carta := -1    # carta escolhida esperando o clique no alvo
var _misseis: Array = []  # Mísseis Mágicos: quem leva cada míssil (cliques)
var _modo_area := -1      # carta de área esperando o clique (prévia no mapa)
var _item_area := ""      # item de área esperando o clique
var _rot_area := 0        # giro das formas não simétricas (tecla R)
var _zonas_no: Node3D
var _nevoa_no: Node3D
var _nevoa_chave := ""
var _modo_aliado := ""     # "tratar", "comandar" ou "orientar": esperando o clique no aliado
var _bt_tratar: Button
var _bt_levantar: Button
var _bt_comandar: Button
var _bt_orientar: Button
var _bt_mulligan: Button
var _bt_pegar_arma: Button
var _bt_recarregar: Button
var _bt_tocha: Button
var _bt_lanterna: Button
var _bt_trocar: Button
var _bt_foco: Button
var _abas: TabContainer
var _h_topo: HBoxContainer
var _pausa = null
var _casa_escolha := {}
var _em_luta := false
var _painel_ini: PanelContainer
var _painel_dir: PanelContainer
var _painel_acoes: PanelContainer
var _bt_correr: Button
var _bt_procurar: Button
var _bt_levantar_aliado: Button
var _bt_saltar: Button
var _bts_manobra := {}
var _painel_intencoes: PanelContainer
var _painel_tut: PanelContainer
var _tut_titulo: Label
var _tut_texto: Label
var _tut_proximo: Button
var _tut_mostrada := -1
var _texto_intencoes: Label
var _baixo: PanelContainer
var _ficha_painel: PanelContainer
var _bt_hab: Button
var _bt_ac: Button
var _bt_reg: Button
var _bt_ficha: Button
var _menus_flutuantes: Array = []
var _fixado := ""
var _menu_aberto := ""
var _brilhos := {}   # "heroi:carta" -> quando disparou   # carta que anda e ataca: {indice, alvo, casas}
var _modelos := {}   # id -> modelo 3D animado (0.18)
var _her_maos: Label
var _fadiga_dialogo: PanelContainer
var _fadiga_linhas: VBoxContainer
var _fadiga_titulo: Label
var _fadiga_dist := {}
var _fadiga_depois: Callable
var _fadiga_confirmada := -1
var _objetivo: Label
var _terreno: Node3D
var _marcadores := {}    # id da interação -> Node3D
var _mesa_ini_linha: Control
var _dialogo: PanelContainer
var _dialogo_titulo: Label
var _dialogo_texto: Label
var _dialogo_corpo: VBoxContainer
var _dialogo_interacao := ""   # interação aberta no diálogo de opções
var _distribuir: PanelContainer
var _dist_titulo: Label
var _dist_linhas: VBoxContainer
var _dist := {"escudo": 0, "armadura": 0}
var _dist_mostrando := false
var _inventario: PanelContainer
var _inventario_lista: VBoxContainer
var _fim_texto: Label
var _campanha_registrada := false
var _resumo_campanha := ""
var _bt_de_novo: Button
var _bt_volta: Button
var _heroi_visto := "heroi"   # herói mostrado na barra de baixo
var _grupo_caixa: HBoxContainer
var _ultimo_ativo := ""
var _camera_alvo := Vector3.ZERO
var _camera_segue := false


func _ready() -> void:
	_fonte = load("res://assets/fontes/DejaVuSans.ttf")
	_fonte_negrito = load("res://assets/fontes/DejaVuSans-Bold.ttf")
	_montar_hud()
	nova_batalha()


func nova_batalha(semente := -1) -> void:
	if semente < 0:
		semente = randi() % 100000
	_geracao += 1
	_ocupado = false
	for filho in get_children():
		if not (filho is CanvasLayer) or filho.name.begins_with("vila_aberta"):
			remove_child(filho)
			filho.queue_free()
	_pecas.clear()
	_tocadores.clear()
	_modelos.clear()
	_rotulos.clear()
	var fichas := Sessao.fichas_do_grupo()
	var cen: Dictionary
	match Sessao.modo:
		"x1": cen = Dados.x1(fichas)
		"trilha": cen = Exploracao.trilha(fichas)
		"fazenda": cen = Fazenda.missao(fichas)
		"masmorra": cen = Masmorra.missao(fichas)
		"pantano": cen = Pantano.missao(fichas)
		"tutorial": cen = Tutorial.missao(fichas)
		"catacumbas": cen = Catacumbas.missao(fichas)
		"vila":
			cen = Vila.cenario(fichas)
			Sessao.campanha = true
			if Sessao.vila_pos != Vector2i(-1, -1):
				cen["unidades"][0]["pos"] = Sessao.vila_pos
		_: cen = Dados.arena(fichas)
	_heroi_visto = "heroi"
	_ultimo_ativo = ""
	batalha = Batalha.new(cen, semente)
	# Jogo salvo no meio da missão (0.19): o retrato substitui o estado novo.
	var restaurada := false
	if Sessao.estado_salvo != "":
		restaurada = Instantaneo.aplicar_texto(batalha, Sessao.estado_salvo)
		Sessao.estado_salvo = ""
	_titulo.text = "SISTEMA 21 · " + cen["nome"]
	_objetivo.text = ""
	_modo_carta = -1
	_modo_area = -1
	_item_area = ""
	_zonas_no = null
	_nevoa_no = null
	_luzes_no = null
	_luzes.clear()
	_nevoa_chave = ""
	_dialogo_interacao = ""
	_dist_mostrando = false
	_dialogo.visible = false
	_distribuir.visible = false
	_inventario.visible = false
	_marcadores.clear()
	_simbolos.clear()
	_terreno = null
	batalha.defesa_automatica = _auto.button_pressed
	batalha.distribuicao_automatica = Sessao.distribuir_sugestao
	batalha.perguntar_sombra = true
	batalha.perguntar_escolhas = true
	batalha.sustentar_automatico = false
	batalha.acoes_longas_automaticas = false
	_linhas_mostradas = 0
	_registro.clear()
	_fim.visible = false
	_planejar.visible = false
	_campanha_registrada = false
	if Sessao.campanha and not restaurada:
		Campanha.aplicar(batalha)
	_montar_mundo()
	if not restaurada:
		batalha.iniciar()
	else:
		_desenhar_zonas()
	batalha.eventos.clear()
	if _painel_narrativa != null and is_instance_valid(_painel_narrativa):
		_painel_narrativa.visible = false
		_texto_narrativa.text = ""
	if not restaurada and not batalha.abertura.is_empty():
		_mostrar_narrativa(str(batalha.abertura.get("titulo", "")), str(batalha.abertura.get("texto", "")))
	_oferecer_salvar = false
	_processar()


# --- Fluxo ------------------------------------------------------------------

func _processar() -> void:
	if _ocupado:
		return
	var geracao := _geracao
	_ocupado = true
	batalha.avancar_tutorial()
	await _tocar_eventos()
	if geracao != _geracao:
		return
	_atualizar()
	while batalha.fase_automatica():
		var pausa := PAUSA_IA * (0.6 if batalha.fase == Batalha.Fase.IA_TURNO else 1.0)
		await get_tree().create_timer(pausa).timeout
		if geracao != _geracao:
			return
		batalha.passo_automatico()
		await _tocar_eventos()
		if geracao != _geracao:
			return
		_atualizar()
	_ocupado = false
	_atualizar()


func _acao(nome: String, carta: Variant = -1) -> void:
	if _ocupado:
		return
	var b := batalha
	if nome != "mao" and nome != "puxar":
		_planejar.visible = false
	match nome:
		"puxar": b.puxar()
		"parar": b.parar()
		"continuar": b.continuar()
		"encerrar":
			if b.vez_do_heroi() and b.fim_de_turno_tem_escolha(b.ativa()):
				_mostrar_fim_de_turno()
				return
			b.encerrar_turno()
		"concentrar": b.heroi_concentrar()
		"folego": b.heroi_recuperar_folego()
		"planejar": b.heroi_planejar()
		"procurar": b.heroi_procurar()
		"levantar_aliado":
			var caidos: Array = b.alvos_de_levantar(b.ativa())
			if caidos.size() == 1:
				b.heroi_levantar_aliado(caidos[0])
			elif caidos.size() > 1:
				_modo_aliado = "levantar"
				_atualizar()
				return
		"correr": b.heroi_correr()
		"saltar": b.heroi_saltar()
		"tratar", "comandar", "orientar", "manobra:derrubar", "manobra:empurrar", "manobra:atrapalhar", "manobra:desarmar", "manobra:agarrar":
			var alvos := _alvos_aliado(nome)
			if alvos.size() == 1:
				_acao_no_aliado(nome, alvos[0])
			else:
				_modo_aliado = nome
				_atualizar()
				return
		"mulligan": b.heroi_mulligan()
		"pegar_arma": b.heroi_pegar_arma()
		"recarregar": b.heroi_recarregar()
		"tocha": b.heroi_luz("tocha")
		"trocar_arma": b.heroi_trocar_arma()
		"foco": b.heroi_usar_foco()
		"lanterna": b.heroi_luz("lanterna")
		"refazer": b.heroi_refazer(carta)
		"levantar": b.heroi_levantar()
		"mao":
			if b.vez_do_heroi() and b.ativa().efeitos.has("topo_da_mao") and b.teste_do_heroi() == null:
				b.heroi_por_no_topo(carta)
			elif b.vantagem_pendente():
				b.heroi_vantagem_trocar(carta)
			else:
				b.jogar_da_mao(carta)
		"reagir": b.heroi_reagir()
		"confirmar_vantagem": b.heroi_vantagem_confirmar()
	_processar()


func _acao_carta(indice: int, virar: bool, opcao := "") -> void:
	if _ocupado:
		return
	var b := batalha
	_planejar.visible = false
	if virar:
		b.heroi_virar(indice)
		_processar()
		return
	var u := b.ativa()
	var c = u.cartas[indice]
	if opcao != "":
		c.opcao = opcao
	var info := b._info_lado(c)
	# Conjuração (0.16): a fadiga que não cabe na carta — o jogador escolhe onde vai.
	if _fadiga_confirmada == indice:
		_fadiga_confirmada = -1
	else:
		b.fadiga_escolhida = {}
		var sobra: int = b.sobra_de_fadiga(u, c, b._custo_fadiga(u, c))
		var cands: Array = b.cartas_para_fadiga(u, c)
		if sobra > 0 and cands.size() >= 2:
			_abrir_fadiga(c, sobra, cands, func(): _acao_carta(indice, false, opcao))
			return
	if str(info.get("alvo", "")) == "area":
		_modo_area = indice
		_rot_area = 0
		_atualizar()
		return
	if str(info.get("alvo", "nenhum")).begins_with("inimigo") or str(info.get("alvo", "nenhum")).begins_with("aliado") \
			or str(info.get("alvo", "")).begins_with("qualquer"):
		_modo_carta = indice
		_misseis = []
		_atualizar()
		return
	b.heroi_usar_carta(indice)
	_processar()


## Tela de fim do turno (0.20): de que cartas sai a fadiga, Respirar Fundo e os efeitos
## que disparam no fim do turno (Bênção Persistente), escolhidos pelo jogador.
func _mostrar_fim_de_turno() -> void:
	for f in _escolha_fadiga_bts.get_children():
		f.queue_free()
	var b := batalha
	var u := b.ativa()
	var op := b.opcoes_fim_de_turno(u)
	var esc := {"fadiga": [], "respirar": [], "opcionais": []}
	var nomes := func(lista: Array) -> Array:
		return lista.map(func(i): return [i, "%s (fadiga %d/%d)" % [u.cartas[i].nome(), u.cartas[i].fadiga, u.cartas[i].limite()]])
	if not op["cartas"].is_empty():
		for k in int(op["pontos"]):
			esc["fadiga"].append(op["cartas"][0])
			_escolha_fadiga_bts.add_child(_seletor("−1 de fadiga em:" if k == 0 else "−1 de fadiga a mais em:", nomes.call(op["cartas"]),
				func(i): esc["fadiga"][k] = i))
	if int(op["respirar"]) > 0 and not op["cartas_respirar"].is_empty():
		for k in int(op["respirar"]):
			esc["respirar"].append(op["cartas_respirar"][0])
			_escolha_fadiga_bts.add_child(_seletor("Respirar Fundo: −1 de fadiga em:", nomes.call(op["cartas_respirar"]),
				func(i): esc["respirar"][k] = i))
	for o in op["opcionais"]:
		var cb := CheckBox.new()
		cb.text = o["texto"]
		cb.focus_mode = Control.FOCUS_NONE
		cb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cb.custom_minimum_size = Vector2(560, 0)
		var id: String = o["id"]
		cb.toggled.connect(func(on):
			if on and not id in esc["opcionais"]:
				esc["opcionais"].append(id)
			elif not on:
				esc["opcionais"].erase(id))
		_escolha_fadiga_bts.add_child(cb)
	var bt := Button.new()
	bt.text = "Encerrar o turno"
	bt.focus_mode = Control.FOCUS_NONE
	bt.custom_minimum_size = Vector2(360, 38)
	bt.pressed.connect(func():
		_escolha_fadiga.visible = false
		batalha.encerrar_turno(esc)
		_processar())
	_escolha_fadiga_bts.add_child(bt)
	_escolha_fadiga.visible = true
	_escolha_fadiga.reset_size()


func _seletor(rotulo: String, itens: Array, ao_mudar: Callable) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.add_child(_label(rotulo, 13, COR_TEXTO))
	var ob := OptionButton.new()
	ob.focus_mode = Control.FOCUS_NONE
	for par in itens:
		ob.add_item(par[1])
		ob.set_item_metadata(ob.item_count - 1, par[0])
	ob.item_selected.connect(func(k): ao_mudar.call(ob.get_item_metadata(k)))
	h.add_child(ob)
	return h


func _usar_item(item: String) -> void:
	if _ocupado:
		return
	if Itens.CONSUMIVEIS.get(item, {}).has("area"):
		_item_area = item
		_rot_area = 0
		_inventario.visible = false
		_atualizar()
		return
	batalha.heroi_usar_item(item)
	_processar()


## Área que está sendo apontada agora (carta ou item), ou {}.
func _spec_area_atual() -> Dictionary:
	var b := batalha
	if not b.vez_do_heroi():
		return {}
	if _modo_area >= 0:
		return b.spec_area(b.ativa().cartas[_modo_area])
	if _item_area != "":
		return Itens.CONSUMIVEIS[_item_area]["area"]
	return {}


func _foco_marcial() -> void:
	var u := batalha.heroi_dono_do_teste()
	if u == null:
		u = batalha.ativa()
	var c := batalha.foco_marcial_olhar(u)
	if c >= 0:
		_mostrar_espiar("Foco Marcial:\ntopo do baralho", [c], batalha.teste_do_heroi() != null)
	_atualizar()


func _alvos_aliado(modo: String) -> Array:
	var u := batalha.ativa()
	match modo:
		"tratar": return batalha.alvos_de_tratar(u)
		"comandar": return batalha.alvos_de_comandar(u)
		"orientar": return batalha.alvos_de_orientar(u)
		"levantar": return batalha.alvos_de_levantar(u)
	if modo.begins_with("manobra:"):
		var tipo := modo.substr(8)
		return batalha.inimigos_vivos().filter(func(o): return batalha.motivo_sem_manobra(u, o, tipo) == "")
	return []


func _acao_no_aliado(modo: String, h) -> void:
	match modo:
		"tratar": batalha.heroi_tratar(h)
		"comandar": batalha.heroi_comandar(h)
		"orientar": batalha.heroi_orientar(h)
		"levantar": batalha.heroi_levantar_aliado(h)
		_:
			if modo.begins_with("manobra:"):
				batalha.heroi_manobra(modo.substr(8), h)


func _clique_no_mapa(celula: Vector2i) -> void:
	if not _ocupado and batalha.fase == Batalha.Fase.RESOLVIDO and batalha.resultado.get("passo", "") != "":
		if batalha.heroi_passo_de_defesa(celula):
			_atualizar_pecas()
			_atualizar()
		return
	if _ocupado or not batalha.vez_do_heroi():
		return
	var b := batalha
	var u := b.ativa()
	var alvo := b.na_posicao(celula)
	var it := b.interacao_em(celula)
	if _modo_carta < 0 and _modo_area < 0 and _item_area == "" and not it.is_empty() and (b.ao_alcance(u, it) or not b.alcance_movimento(u)["mapa"].has(celula)):
		if b.ao_alcance(u, it):
			_abrir_dialogo(it["id"])
		return
	if _modo_area >= 0 or _item_area != "":
		var ok := b.heroi_usar_area(_modo_area, celula, _rot_area) if _modo_area >= 0 else b.heroi_usar_item_area(_item_area, celula)
		if ok:
			_modo_area = -1
			_item_area = ""
			_processar()
		return
	if _modo_aliado != "":
		var modo := _modo_aliado
		_modo_aliado = ""
		for h in _alvos_aliado(modo):
			if h.pos == celula:
				_acao_no_aliado(modo, h)
				_processar()
				return
		_atualizar()
		return
	if not _casa_escolha.is_empty():
		var ce := _casa_escolha
		_casa_escolha = {}
		if celula in ce["casas"]:
			b.heroi_usar_carta(int(ce["indice"]), b.unidade(ce["alvo"]), "", celula)
			_processar()
		else:
			_atualizar()
		return
	if _modo_carta >= 0 and b._info_lado(u.cartas[_modo_carta]).has("misseis"):
		# Mísseis Mágicos: cada clique num inimigo marcado é 1 míssil; no terceiro, dispara.
		if alvo != null and alvo in b.alvos_de_habilidade(u, u.cartas[_modo_carta]):
			_misseis.append(alvo.id)
			if _misseis.size() >= 3:
				var ind := _modo_carta
				_modo_carta = -1
				var ids := _misseis.duplicate()
				_misseis = []
				b.heroi_usar_misseis(ind, ids)
				_processar()
				return
		_atualizar()
		return
	if _modo_carta >= 0:
		var indice := _modo_carta
		_modo_carta = -1
		if alvo == null:
			for h in b.herois():
				if h.pos == celula:
					alvo = h   # aliado caído (Ressurgir)
		if alvo != null and alvo in b.alvos_de_habilidade(u, u.cartas[indice]):
			# Cartas que andam e atacam (0.20): com mais de uma casa possível, o jogador escolhe.
			var passos := b.passos_antes_do_ataque(u.cartas[indice])
			var casas: Array = b.casas_para_atacar(u, alvo, passos) if passos > 0 else []
			if casas.size() > 1:
				_casa_escolha = {"indice": indice, "alvo": alvo.id, "casas": casas}
				_atualizar()
				return
			b.heroi_usar_carta(indice, alvo)
			_processar()
		else:
			_atualizar()
		return
	var alvo_da_confusao: bool = alvo != null and alvo.eh_heroi() and u.efeitos.get("confuso", {}).get("alvo", "") == alvo.id
	if alvo != null and (not alvo.eh_heroi() or alvo_da_confusao):
		if b.heroi_atacar(alvo):
			_planejar.visible = false
			_processar()
		return
	if b.alcance_movimento(u)["mapa"].has(celula):
		_planejar.visible = false
		b.heroi_mover(celula)
		_processar()


func _unhandled_input(evento: InputEvent) -> void:
	if _pausa != null and _pausa.visible:
		return
	var tecla := evento as InputEventKey
	if tecla != null and tecla.pressed and not tecla.echo:
		match tecla.keycode:
			KEY_SPACE: _acao("puxar")
			KEY_ENTER, KEY_KP_ENTER:
				if batalha.fase == Batalha.Fase.DISTRIBUINDO_DANO:
					_confirmar_distribuicao()
				elif batalha.vantagem_pendente():
					_acao("confirmar_vantagem")
				elif batalha.fase in [Batalha.Fase.RESOLVIDO, Batalha.Fase.INTERACAO_RESOLVIDA]:
					_acao("continuar")
				else:
					_acao("parar")
			KEY_E: _acao("encerrar")
			KEY_R:
				if not _spec_area_atual().is_empty():
					_rot_area = (_rot_area + 1) % 4
					_atualizar_marcas()
			KEY_I: _alternar_inventario()
			KEY_C:
				if _ficha_painel.visible:
					_ficha_painel.visible = false
				else:
					_abrir_ficha_do_heroi()
			KEY_L: _fixar("registro")
			KEY_N:
				if not Sessao.campanha:
					nova_batalha()
			KEY_ESCAPE:
				_modo_aliado = ""
				if _modo_area >= 0 or _item_area != "":
					_modo_area = -1
					_item_area = ""
					_atualizar()
					return
				if _ficha_painel.visible:
					_ficha_painel.visible = false
					get_viewport().set_input_as_handled()
					return
				if _modo_carta >= 0 or _escolha_fadiga.visible or _dialogo_interacao != "" or _inventario.visible or not _casa_escolha.is_empty():
					_casa_escolha = {}
					_modo_carta = -1
					_misseis = []
					batalha.fadiga_escolhida = {}
					_escolha_fadiga.visible = false
					_inventario.visible = false
					_fechar_dialogo()
					_atualizar()
				else:
					_abrir_pausa()
			_: return
		get_viewport().set_input_as_handled()
		return
	var mov := evento as InputEventMouseMotion
	if mov != null:
		var c := _celula_do_mouse(mov.position)
		if c != _hover:
			_hover = c
			_atualizar_marcas()
			_atualizar_dica()
		return
	var clique := evento as InputEventMouseButton
	if clique != null and clique.pressed and clique.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and _camera != null:
		_camera.size = clampf(_camera.size * (0.9 if clique.button_index == MOUSE_BUTTON_WHEEL_UP else 1.1), 7.0, 32.0)
		return
	if clique != null and clique.pressed and clique.button_index == MOUSE_BUTTON_LEFT:
		_clique_no_mapa(_celula_do_mouse(clique.position))
	elif clique != null and clique.pressed and clique.button_index == MOUSE_BUTTON_RIGHT and (_modo_carta >= 0 or _modo_aliado != "" or _modo_area >= 0 or _item_area != "" or not _casa_escolha.is_empty()):
		_casa_escolha = {}
		_modo_carta = -1
		_misseis = []
		batalha.fadiga_escolhida = {}
		_modo_aliado = ""
		_modo_area = -1
		_item_area = ""
		_atualizar()
	elif clique != null and clique.pressed and clique.button_index == MOUSE_BUTTON_RIGHT:
		# Botão direito num personagem (0.21): a ficha dele.
		var cel := _celula_do_mouse(clique.position)
		var quem = batalha.na_posicao(cel) if batalha.grade.dentro(cel) else null
		if quem != null and (quem.eh_heroi() or batalha.unidade_visivel(quem)):
			if quem.eh_heroi():
				_abrir_ficha_do_heroi(quem)
			else:
				_abrir_ficha_do_monstro(quem)


func _celula_do_mouse(pos: Vector2) -> Vector2i:
	if _camera == null:
		return Vector2i(-99, -99)
	var origem := _camera.project_ray_origin(pos)
	var direcao := _camera.project_ray_normal(pos)
	if absf(direcao.y) < 0.0001:
		return Vector2i(-99, -99)
	var t := -origem.y / direcao.y
	var ponto := origem + direcao * t
	var c := Vector2i(roundi(ponto.x), roundi(ponto.z))
	return c if batalha.grade.dentro(c) else Vector2i(-99, -99)


# --- Animações --------------------------------------------------------------

func _tocar_eventos() -> void:
	var geracao := _geracao
	while not batalha.eventos.is_empty():
		if geracao != _geracao:
			return
		var e: Dictionary = batalha.eventos.pop_front()
		match e["tipo"]:
			"mover":
				var peca: Node3D = _pecas[e["id"]]
				var mod = _modelos.get(e["id"])
				Modelos.tocar(mod, "Walking_A", false)
				_som("passos")
				for passo in e["caminho"]:
					if geracao != _geracao or not is_instance_valid(peca):
						return
					Modelos.encarar(mod, _mundo(passo) - peca.position)
					var tw := create_tween()
					tw.tween_property(peca, "position", _mundo_unidade(passo), 0.16)
					await tw.finished
				Modelos.tocar(mod, "Idle", false)
				_atualizar_marcas()
			"ataque":
				var a: Node3D = _pecas[e["atacante"]]
				var d: Node3D = _pecas[e["defensor"]]
				var inicio := a.position
				var rumo := (d.position - a.position).normalized() * 0.3
				var mod_a = _modelos.get(e["atacante"])
				if e.get("magia", false):
					_efeito_raio(a.position, d.position, e.get("tipo_dano", ""))
				_som("magia" if e.get("magia", false) else ("tiro" if e.get("distancia", false) else "golpe"))
				if mod_a != null:
					Modelos.encarar(mod_a, d.position - a.position)
					Modelos.tocar(mod_a, Modelos.animacao_de_ataque(mod_a, e.get("magia", false)))
					rumo *= 0.4
					await get_tree().create_timer(0.3).timeout
				var tw := create_tween()
				tw.tween_property(a, "position", inicio + rumo, 0.1)
				tw.tween_property(a, "position", inicio, 0.12)
				await tw.finished
			"dano":
				_flutuar(e["id"], "-%d" % e["valor"], Color("e0574b"))
				_som("acerto")
				if _modelos.has(e["id"]) and not _modelos[e["id"]].get_meta("caido", false):
					Modelos.tocar(_modelos[e["id"]], "Hit_A")
			"errou":
				_flutuar(e["id"], "errou", Color("c9c4b8"))
			"cura":
				_flutuar(e["id"], "+%d" % e["valor"], Color("8fd18a"))
				_efeito_cura(e["id"])
				_som("cura")
			"morte":
				var peca: Node3D = _pecas[e["id"]]
				if _modelos.has(e["id"]):
					_modelos[e["id"]].set_meta("caido", true)
					Modelos.tocar(_modelos[e["id"]], "Death_A", false)
				else:
					var tw := create_tween()
					tw.tween_property(peca, "rotation_degrees", Vector3(80, 0, 0), 0.3)
				_rotulos[e["id"]].visible = false
			"espiar":
				_mostrar_espiar(e["titulo"], e["cartas"], e.get("fundo", false))
			"alerta":
				_flutuar(e["id"], "!", Color("ff6b4a"))
			"brilho":
				_brilhos["%s:%d" % [e["id"], int(e["carta"])]] = Time.get_ticks_msec()
				if _pecas.has(e["id"]):
					_flutuar(e["id"], "✦ " + str(e["nome"]), Color("ffe08a"))
			"mapa":
				_montar_terreno()
			"zonas":
				_desenhar_zonas()
			"narrativa":
				_mostrar_narrativa(str(e.get("titulo", "")), str(e["texto"]))
			"intencao":
				_mostrar_intencoes([e["texto"]])
				if _pecas.has(e["id"]):
					_flutuar(e["id"], "…", Color("ffb39a"))
				await get_tree().create_timer(1.4).timeout
			"area":
				_efeito_area(e["celulas"], str(e.get("tipo_dano", "")))
				_som("magia")
				await get_tree().create_timer(0.35).timeout
			"flutuar":
				if _pecas.has(e["id"]) and (batalha.unidade(e["id"]).eh_heroi() or batalha.unidade_visivel(batalha.unidade(e["id"]))):
					_flutuar(e["id"], str(e["texto"]), Color(str(e.get("cor", "ffffff"))))
					await get_tree().create_timer(0.25).timeout
			"surgir":
				var nova = batalha.unidade(e["id"])
				if nova != null and not _pecas.has(e["id"]):
					_criar_peca(nova)
					_atualizar_pecas()
			"teleporte":
				if _pecas.has(e["id"]):
					var pt: Node3D = _pecas[e["id"]]
					_efeito_cura(e["id"])
					pt.position = _mundo_unidade(batalha.unidade(e["id"]).pos)
					_efeito_cura(e["id"])
					_atualizar_marcas()
			"abrir_vila":
				_abrir_vila(str(e["aba"]))
			"reacao_monstro":
				if _pecas.has(e["id"]) and batalha.unidade_visivel(batalha.unidade(e["id"])):
					_flutuar(e["id"], "✦ " + str(e["nome"]), Color("ff9d5c"))
			"estrategia":
				if _pecas.has(e["id"]):
					_flutuar(e["id"], "! " + str(e["texto"]), Color("ffb347"))
					await get_tree().create_timer(0.5).timeout
			"intencoes":
				_mostrar_intencoes(e["linhas"])
			"reviver":
				if _pecas.has(e["id"]):
					var peca_r: Node3D = _pecas[e["id"]]
					peca_r.position = _mundo_unidade(batalha.unidade(e["id"]).pos)
					peca_r.rotation_degrees = Vector3.ZERO
					if _modelos.has(e["id"]):
						_modelos[e["id"]].set_meta("caido", false)
						Modelos.tocar(_modelos[e["id"]], "Idle", false)
					_rotulos[e["id"]].visible = true
					_flutuar(e["id"], "de pé de novo!", Color("ff6b4a"))
			"sumir":
				if _pecas.has(e["id"]):
					var peca_s: Node3D = _pecas[e["id"]]
					var tw_s := peca_s.create_tween()
					tw_s.tween_property(peca_s, "scale", Vector3(0.01, 0.01, 0.01), 0.4)
					_rotulos[e["id"]].visible = false


func _flutuar(id: String, texto: String, cor: Color) -> void:
	var l := Label3D.new()
	l.text = texto
	l.font = _fonte_negrito
	l.font_size = 64
	l.pixel_size = 0.006
	l.outline_size = 16
	l.modulate = cor
	l.outline_modulate = Color(0, 0, 0, 0.9)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	add_child(l)
	l.position = _pecas[id].position + Vector3(0, 1.7, 0)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position", l.position + Vector3(0, 0.8, 0), 1.0)
	tw.tween_property(l, "modulate:a", 0.0, 1.0).set_delay(0.4)
	tw.chain().tween_callback(l.queue_free)


func _mostrar_espiar(titulo: String, cartas: Array, opcao_fundo: bool) -> void:
	_planejar_titulo.text = titulo
	for filho in _planejar_cartas.get_children():
		filho.queue_free()
	var reordenar: bool = batalha.ativa() != null and batalha.ativa().efeitos.has("planejou") and not opcao_fundo \
		and batalha.ativa().efeitos["planejou"]["cartas"] == cartas and cartas.size() > 1
	for i in cartas.size():
		var c: int = cartas[i]
		var cv := CartaVisual.new()
		cv.configurar(c, false, "", TAM_CARTA_MAO)
		if reordenar:
			var caixa := VBoxContainer.new()
			caixa.add_child(cv)
			var bt_sobe := Button.new()
			bt_sobe.text = "◀ mais em cima" if i > 0 else "topo"
			bt_sobe.disabled = i == 0
			bt_sobe.focus_mode = Control.FOCUS_NONE
			var ii := i
			bt_sobe.pressed.connect(func():
				var nova: Array = cartas.duplicate()
				var tmp = nova[ii - 1]
				nova[ii - 1] = nova[ii]
				nova[ii] = tmp
				if batalha.heroi_reordenar_topo(nova):
					_mostrar_espiar(titulo, nova, false))
			caixa.add_child(bt_sobe)
			_planejar_cartas.add_child(caixa)
		else:
			_planejar_cartas.add_child(cv)
	for filho in _planejar_bts.get_children():
		filho.queue_free()
	if opcao_fundo:
		var bt_fundo := Button.new()
		bt_fundo.text = "Mandar para o fundo"
		bt_fundo.focus_mode = Control.FOCUS_NONE
		bt_fundo.pressed.connect(func():
			if batalha.scry_de != "":
				batalha.heroi_scry(true)
			else:
				batalha.foco_marcial_fundo(batalha.heroi_dono_do_teste())
			_planejar.visible = false
			_atualizar())
		_planejar_bts.add_child(bt_fundo)
	var bt_ok := Button.new()
	bt_ok.text = "Deixar no topo" if opcao_fundo else "Fechar"
	bt_ok.focus_mode = Control.FOCUS_NONE
	bt_ok.pressed.connect(func():
		if batalha.scry_de != "":
			batalha.heroi_scry(false)
		batalha.foco_marcial_visto = -1
		_planejar.visible = false)
	_planejar_bts.add_child(bt_ok)
	_planejar.visible = true


# --- Atualização ------------------------------------------------------------

## O herói mostrado embaixo: quem age, quem está no teste ou quem sofre dano.
func _heroi_foco():
	var b := batalha
	var u = null
	if b.fase == Batalha.Fase.DISTRIBUINDO_DANO and not b.dano_pendente.is_empty():
		u = b.unidade(b.dano_pendente["id"])
	elif b.heroi_dono_do_teste() != null:
		u = b.heroi_dono_do_teste()
	elif b.ativa() != null and b.ativa().eh_heroi():
		u = b.ativa()
	if u != null:
		_heroi_visto = u.id
	var visto = b.unidade(_heroi_visto)
	return visto if visto != null else b.herois()[0]


func _atualizar() -> void:
	var b := batalha
	var heroi = _heroi_foco()
	_atualizar_grupo()
	_seguir_camera()
	_enquadrar_combate()
	_atualizar_tutorial()
	_rodada.text = "Rodada %d" % b.rodada
	for filho in _ordem.get_children():
		filho.queue_free()
	# Iniciativa (0.21): uma linha por personagem; heróis em azul, inimigos em vermelho,
	# quem não foi visto em cinza; a seta e o fundo dourado marcam de quem é a vez.
	for i in b.ordem.size():
		var u := b.unidade(b.ordem[i])
		var visto: bool = b.unidade_visivel(u) or not u.viva()
		# Inimigos nunca vistos não aparecem na lista (senão ela entrega quantos são);
		# só a vez de um deles aparece como "?".
		if not u.eh_heroi() and not visto and i != b.indice_vez:
			continue
		var cor := Color("9fc8ff") if u.eh_heroi() else (Color("ff9c8c") if visto else COR_SECUNDARIO)
		if not u.viva():
			cor = Color("5d5a66")
		var vez_dele: bool = i == b.indice_vez
		var linha := _label("%s %s%s" % ["▶" if vez_dele else "  ", u.nome if visto else "?", "" if u.viva() else " ✝"], 12,
			COR_OURO if vez_dele else cor, vez_dele)
		if vez_dele:
			var fundo := StyleBoxFlat.new()
			fundo.bg_color = Color(0.79, 0.64, 0.36, 0.18)
			fundo.set_corner_radius_all(4)
			linha.add_theme_stylebox_override("normal", fundo)
		_ordem.add_child(linha)

	_her_nome.text = "%s · %s%s" % [heroi.nome, heroi.classe, "" if heroi.viva() else " (inconsciente)"]
	# Barra de vida (Lucas, 0.20): verde = baralho, verde-claro = mão, vermelho = descarte
	# (dá para curar), preto = exílio.
	var partes := [heroi.baralho.baralho.size(), heroi.baralho.mao.size(), heroi.baralho.descarte.size(), heroi.baralho.exilio.size()]
	var dicas := ["Baralho (vida): %d", "Mão: %d", "Descarte: %d (pode voltar com cura)", "Exílio: %d (só volta com descanso)"]
	for k in 4:
		var cr: ColorRect = _her_vida.get_child(k)
		cr.size_flags_stretch_ratio = maxf(float(partes[k]), 0.001)
		cr.visible = partes[k] > 0
		cr.tooltip_text = dicas[k] % partes[k]
	_her_vida_txt.text = "Baralho (vida): %d / 52" % heroi.baralho.baralho.size()
	_her_zonas.text = "%s%s%s" % [
		("Armadura %d/%d" % [heroi.vida_armadura, heroi.armadura["vida"]]) if int(heroi.armadura.get("vida", 0)) > 0 else "Sem armadura",
		("  ·  Escudo %d/%d" % [heroi.vida_escudo, heroi.escudo["vida"]]) if int(heroi.escudo.get("vida", 0)) > 0 else "",
		"  ·  Desc. %d · Exílio %d" % [heroi.baralho.descarte.size(), heroi.baralho.exilio.size()]]
	var maos: Array = b.maos_de(heroi)
	_her_maos.text = "Mãos: %s | %s%s" % [maos[0] if maos[0] != "" else "livre", maos[1] if maos[1] != "" else "livre",
		("   ·   Reserva: " + heroi.arma_reserva["nome"]) if not heroi.arma_reserva.is_empty() else ""]
	if heroi.luz == "lanterna":
		_her_maos.text += "   ·   Lanterna acesa (cinto)"
	var fichas_h := PackedStringArray()
	for f in ["Sombra", "Mira", "Foco", "Preparo", "Bloqueio", "Guarda"]:
		if heroi.fichas_total(f) > 0:
			fichas_h.append("%s %d" % [f, heroi.fichas_total(f)])
	# Só o que muda a jogada agora; números de arma e atributos ficam na Ficha (C).
	var estado := PackedStringArray()
	if heroi.imobilizado():
		estado.append("IMOBILIZADO")
	if heroi.efeitos.has("oculto"):
		estado.append("OCULTO")
	if heroi.efeitos.has("caido"):
		estado.append("CAÍDO")
	if not fichas_h.is_empty():
		estado.append("Fichas: " + ", ".join(fichas_h))
	_her_stats.text = " · ".join(estado)
	var vez := b.vez_do_heroi()
	if vez:
		_acoes.text = "Movimento %d · Padrão %d · Reação %d   ·   Deslocamento %d%s" % [
			heroi.acoes_mov, heroi.acoes_padrao, heroi.acoes_reacao, heroi.deslocamento,
			"   ·   IMPEDIDO" if b.impedido(heroi) else ""]
	elif b.vantagem_pendente():
		_acoes.text = "Vantagem: clique numa carta da mão para trocar, ou confirme (Enter)."
	elif b.teste_do_heroi() != null:
		_acoes.text = "Mesa de 21: puxe, jogue uma carta da mão ou pare."
	elif b.fase == Batalha.Fase.DISTRIBUINDO_DANO:
		_acoes.text = "Escolha como distribuir o dano e confirme (Enter)."
	elif b.fase in [Batalha.Fase.RESOLVIDO, Batalha.Fase.INTERACAO_RESOLVIDA]:
		_acoes.text = "Veja o resultado e continue (Enter)."
	else:
		_acoes.text = "Aguarde a sua vez."
	var livre := vez and not _ocupado
	_bt_concentrar.disabled = not (livre and heroi.acoes_padrao > 0)
	_bt_folego.disabled = not (livre and heroi.acoes_padrao > 0 and not heroi.baralho.descarte.is_empty())
	_bt_planejar.disabled = not (livre and heroi.acoes_padrao > 0)
	_bt_tratar.visible = vez and not b.alvos_de_tratar(heroi).is_empty()
	_bt_levantar.visible = vez and heroi.efeitos.has("caido")
	_bt_comandar.visible = vez and heroi.espirito >= 3
	_bt_comandar.disabled = not (livre and heroi.acoes_padrao > 0 and not b.alvos_de_comandar(heroi).is_empty())
	_bt_orientar.visible = vez and heroi.atributo("diplomacia") > 0
	_bt_orientar.disabled = not (livre and not b.alvos_de_orientar(heroi).is_empty())
	_bt_orientar.text = "Orientar (%d)" % maxi(heroi.atributo("diplomacia") - int(heroi.efeitos.get("orientar", {}).get("usos", 0)), 0)
	_bt_mulligan.visible = vez and b.pode_mulligan(heroi)
	_bt_pegar_arma.visible = vez and heroi.efeitos.has("sem_arma")
	_bt_pegar_arma.disabled = not (livre and Grade.distancia(b.arma_no_chao_de(heroi), heroi.pos) <= 1 and (heroi.acoes_mov > 0 or heroi.acoes_padrao > 0))
	_bt_recarregar.visible = vez and heroi.efeitos.has("descarregada")
	_bt_tocha.visible = vez and b.escuro and ("tocha" in heroi.consumiveis or heroi.luz == "tocha")
	_bt_tocha.text = "Apagar tocha" if heroi.luz == "tocha" else "Acender tocha (%d)" % heroi.consumiveis.count("tocha")
	_bt_tocha.disabled = not livre or b.motivo_luz(heroi, "tocha") != ""
	_bt_lanterna.visible = vez and b.escuro and "lanterna" in heroi.equipamentos
	_bt_lanterna.text = "Apagar lanterna" if heroi.luz == "lanterna" else "Acender lanterna"
	_bt_lanterna.disabled = not livre or b.motivo_luz(heroi, "lanterna") != ""
	_bt_recarregar.disabled = not (livre and heroi.acoes_padrao > 0)
	_bt_trocar.visible = vez and not heroi.arma_reserva.is_empty()
	if not heroi.arma_reserva.is_empty():
		var ct: int = b.custo_troca(heroi)
		_bt_trocar.text = "Trocar por %s" % heroi.arma_reserva["nome"]
		_bt_trocar.tooltip_text = "Guarda %s e pega %s. Custo: %s." % [heroi.arma.get("nome", ""), heroi.arma_reserva["nome"],
			"nenhum (Bandoleira de Armas)" if ct == 0 else ("1 ação (movimento ou Padrão)" if ct == 1 else "2 ações (arma grande)")]
	_bt_trocar.disabled = not livre or b.motivo_troca(heroi) != ""
	_bt_foco.visible = vez and heroi.fichas_total("Foco") > 0
	_bt_foco.disabled = not livre or heroi.baralho.baralho.is_empty()
	_bt_levantar.disabled = not (livre and (heroi.acoes_mov > 0 or heroi.acoes_padrao > 0))
	_bt_tratar.disabled = not (livre and heroi.acoes_padrao > 0)
	_bt_procurar.visible = vez
	_bt_procurar.disabled = not (livre and heroi.acoes_padrao > 0)
	_bt_levantar_aliado.visible = vez and not b.alvos_de_levantar(heroi).is_empty()
	_bt_levantar_aliado.disabled = not (livre and heroi.acoes_padrao > 0)
	_bt_correr.disabled = not livre or b.motivo_sem_correr(heroi, 3) != ""
	_bt_correr.visible = vez
	_bt_saltar.disabled = not livre or b.motivo_sem_correr(heroi, 2) != ""
	_bt_saltar.visible = vez
	for tipo in _bts_manobra:
		var tem_alvo: bool = vez and b.inimigos_vivos().any(func(o): return b.motivo_sem_manobra(heroi, o, tipo) == "")
		_bts_manobra[tipo].visible = vez
		_bts_manobra[tipo].disabled = not livre or not tem_alvo
	_bt_encerrar.disabled = not livre
	for filho in _itens.get_children():
		filho.queue_free()
	var bt_inv := Button.new()
	bt_inv.text = "Inventário (I)"
	bt_inv.focus_mode = Control.FOCUS_NONE
	bt_inv.add_theme_font_size_override("font_size", 12)
	bt_inv.pressed.connect(_alternar_inventario)
	_itens.add_child(bt_inv)
	var vistos := []
	for item in heroi.consumiveis:
		var dados: Dictionary = Itens.CONSUMIVEIS.get(item, {})
		if item in vistos or not dados.get("acao", false):
			continue
		vistos.append(item)
		var bt := Button.new()
		var qtd: int = heroi.quantidade(item)
		bt.text = dados.get("nome", item) + ((" ×%d" % qtd) if qtd > 1 else "")
		bt.tooltip_text = dados.get("texto", "")
		bt.focus_mode = Control.FOCUS_NONE
		bt.add_theme_font_size_override("font_size", 12)
		bt.disabled = not _item_usavel(heroi, item)
		bt.pressed.connect(func(): _usar_item(item))
		_itens.add_child(bt)
	_atualizar_cartas(heroi)

	# Mão
	var teste := b.teste_do_heroi()
	var pode_jogar := teste != null and teste.pode_jogar_da_mao() and not _ocupado
	var vantagem := b.vantagem_pendente() and not _ocupado
	for filho in _mao.get_children():
		filho.queue_free()
	for c in heroi.baralho.mao:
		var cv := CartaVisual.new()
		cv.configurar(c, false, "", TAM_CARTA_MAO_LEQUE, pode_jogar or (vantagem and b.melhor_troca_vantagem(c) >= 0))
		cv.clicada.connect(func(carta): _acao("mao", carta))
		_mao.add_child(cv)
	if heroi.baralho.mao.is_empty():
		_mao.add_child(_label("(mão vazia)", 13, COR_SECUNDARIO))
	_arrumar_leque()
	call_deferred("_arrumar_leque")

	_atualizar_mesa()
	# 0.20: os quadros dos heróis (nome e vida) ficavam por cima da mesa do teste.
	_grupo_caixa.visible = not _mesa.visible and not _dialogo.visible
	_baixo.visible = true   # a mão continua à mão durante o teste (jogar da mão)
	_atualizar_pecas()
	_atualizar_marcas()
	_atualizar_dica()

	while _linhas_mostradas < b.registro.size():
		var linha: String = b.registro[_linhas_mostradas]
		if linha.begins_with("—"):
			_registro.append_text("\n[color=#c9a45c]%s[/color]\n" % linha)
		else:
			_registro.append_text(linha + "\n")
		_linhas_mostradas += 1

	_desenhar_nevoa()
	_atualizar_luzes()
	_trilha_sonora()
	_atualizar_marcadores()
	_atualizar_dialogos()
	if _inventario.visible:
		_montar_inventario()

	if b.fase in [Batalha.Fase.VITORIA, Batalha.Fase.DERROTA] and not _ocupado:
		var missao := b.objetivo != ""
		_fim_titulo.text = ("MISSÃO CUMPRIDA!" if missao else "VITÓRIA!") if b.fase == Batalha.Fase.VITORIA else "DERROTA"
		_fim_titulo.add_theme_color_override("font_color", COR_OURO if b.fase == Batalha.Fase.VITORIA else COR_VIDA_INIMIGO)
		_fim_texto.text = b.mensagem_fim
		if Sessao.campanha:
			if not _campanha_registrada:
				_campanha_registrada = true
				_resumo_campanha = Campanha.registrar_fim(b, Sessao.modo, b.fase == Batalha.Fase.VITORIA)
			_fim_texto.text = b.mensagem_fim + "\n\n" + _resumo_campanha
		_bt_de_novo.visible = not Sessao.campanha
		_bt_volta.text = "Voltar à vila" if Sessao.campanha else "Voltar ao menu"
		_fim.visible = true


func _atualizar_mesa() -> void:
	var b := batalha
	var F := Batalha.Fase
	if b.fase == F.INTERACAO_TESTE:
		_atualizar_mesa_pericia()
		return
	_mesa_ini_linha.visible = true
	var dist_ataque: bool = b.fase == F.DISTRIBUINDO_DANO and b.dano_pendente.get("origem", "") == "ataque"
	var em_teste := b.fase in [F.HEROI_ATACANDO, F.IA_DEFENDENDO, F.IA_ATACANDO, F.HEROI_DEFENDENDO, F.RESOLVIDO] or dist_ataque \
		or (b.fase in [F.VITORIA, F.DERROTA] and not b.resultado.is_empty() and b.interacao_atual.is_empty())
	_mesa.visible = em_teste and b.teste_ataque != null
	if not _mesa.visible:
		_contagem = {"inimigo": 0, "heroi": 0}
		return
	var heroi_ataca := b.atacante.eh_heroi()
	var inimigo = b.defensor if heroi_ataca else b.atacante
	var heroi = b.atacante if heroi_ataca else b.defensor
	var t_ini: Teste21 = b.teste_defesa if heroi_ataca else b.teste_ataque
	var t_her: Teste21 = b.teste_ataque if heroi_ataca else b.teste_defesa
	var revelar := b.fase in [F.RESOLVIDO, F.VITORIA, F.DERROTA, F.DISTRIBUINDO_DANO]
	var esconder: bool = not (revelar or t_ini.estourou)
	_mesa_ini_titulo.text = "%s\n%s%s" % [inimigo.nome, "defende" if heroi_ataca else "ataca",
		(" · limite %d" % t_ini.limite) if t_ini.limite != 21 else ""]
	_mesa_her_titulo.text = "%s\n%s%s%s" % [heroi.nome, "ataca" if heroi_ataca else "defende",
		(" · limite %d" % t_her.limite) if t_her.limite != 21 else "", "\n(cartas à vista)" if t_her.revelado else ""]
	_desenhar_linha(_mesa_ini_cartas, t_ini, "inimigo", esconder)
	_desenhar_linha(_mesa_her_cartas, t_her, "heroi", false)
	_mesa_ini_total.text = _texto_total(t_ini, esconder)
	_mesa_her_total.text = _texto_total(t_her, false)
	var pode_puxar := not _ocupado and b.teste_do_heroi() != null and b.teste_do_heroi().pode_puxar()
	_mesa_her_monte.configurar(heroi.baralho.baralho.size(), pode_puxar)
	_mesa_ini_monte.configurar(b.baralho_inimigos.baralho.size(), false)
	_bt_puxar.disabled = not pode_puxar
	_bt_parar.disabled = not (not _ocupado and b.teste_do_heroi() != null)
	_bt_continuar.disabled = not (not _ocupado and b.fase == F.RESOLVIDO)
	_mesa_faixa.text = _texto_faixa()
	for filho in _mesa_extras.get_children():
		filho.queue_free()
	if not _ocupado:
		for a in b.ajustes_disponiveis():
			var bt := Button.new()
			bt.text = "Somar " + a["nome"]
			bt.tooltip_text = "Soma %+d no teste (conta para estourar)." % a["valor"]
			bt.focus_mode = Control.FOCUS_NONE
			bt.pressed.connect(func():
				batalha.heroi_ajuste(a["nome"])
				_processar())
			_mesa_extras.add_child(bt)
		var dono := b.heroi_dono_do_teste()
		if dono != null and b.teste_do_heroi() != null and b.pode_foco_marcial(dono) and b.foco_marcial_visto < 0:
			var bt := Button.new()
			bt.text = "Foco Marcial (1 fadiga): ver o topo"
			bt.focus_mode = Control.FOCUS_NONE
			bt.pressed.connect(_foco_marcial)
			_mesa_extras.add_child(bt)
		for o in b.cartas_durante_ataque():
			var bt_c := Button.new()
			bt_c.text = o["texto"]
			bt_c.focus_mode = Control.FOCUS_NONE
			var sl: String = o["slug"]
			var op: String = o["opcao"]
			bt_c.pressed.connect(func():
				batalha.heroi_durante_ataque(sl, op)
				_processar())
			_mesa_extras.add_child(bt_c)
		_botoes_carta_fechada()
		if b.texto_reacao() != "":
			var bt := Button.new()
			bt.text = b.texto_reacao()
			bt.focus_mode = Control.FOCUS_NONE
			bt.pressed.connect(func(): _acao("reagir"))
			_mesa_extras.add_child(bt)
	_mesa_extras.visible = _mesa_extras.get_child_count() > 0


func _texto_faixa() -> String:
	var b := batalha
	match b.fase:
		Batalha.Fase.HEROI_ATACANDO:
			return "Você ataca: puxe, jogue da mão ou pare."
		Batalha.Fase.IA_DEFENDENDO:
			return "%s se defende..." % b.defensor.nome
		Batalha.Fase.IA_ATACANDO:
			return "%s ataca..." % b.atacante.nome
		Batalha.Fase.HEROI_DEFENDENDO:
			if b.defesa_automatica:
				return "Defendendo automaticamente (para em 17)..."
			return "Defenda-se: puxe, jogue da mão ou pare."
		Batalha.Fase.RESOLVIDO, Batalha.Fase.VITORIA, Batalha.Fase.DERROTA, Batalha.Fase.DISTRIBUINDO_DANO:
			return _texto_resultado()
	return ""


func _texto_resultado() -> String:
	var r := batalha.resultado
	if r.is_empty():
		return ""
	var a := batalha.unidade(r["atacante"])
	var d := batalha.unidade(r["defensor"])
	var conta := PackedStringArray()
	for parte in r["partes"]:
		conta.append("%s %+d" % [parte[0], parte[1]] if conta.size() > 0 else "%s %d" % [parte[0], parte[1]])
	var unidade := "de dano"
	if d.eh_heroi() and r.has("distribuicao"):
		var dist: Dictionary = r["distribuicao"]
		unidade = "de dano (escudo %d · armadura %d · baralho %d)" % [dist["escudo"], dist["armadura"], dist["vida"]]
	elif d.eh_heroi() and batalha.fase == Batalha.Fase.DISTRIBUINDO_DANO:
		unidade = "de dano: escolha como distribuir"
	if not r["acertou"]:
		if r["dano"] > 0:
			return "%s erra (%d contra %d), mas a Força fere: %d %s." % [a.nome, r["ataque"], r["defesa"], r["dano"], unidade]
		return "%s erra: %d contra %d." % [a.nome, r["ataque"], r["defesa"]]
	return "%s acerta: %d contra %d → %s = %d %s." % [a.nome, r["ataque"], r["defesa"], " ".join(conta), r["dano"], unidade]


func _desenhar_linha(caixa: HBoxContainer, t: Teste21, lado: String, esconder_fechada: bool) -> void:
	for filho in caixa.get_children():
		filho.queue_free()
	var lista: Array[int] = t.cartas.duplicate()
	if t.carta_do_estouro >= 0:
		lista.append(t.carta_do_estouro)
	for i in lista.size():
		var c := lista[i]
		var cv := CartaVisual.new()
		cv.configurar(c, esconder_fechada and i == 1, "", TAM_CARTA_MESA)
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
		if i >= _contagem[lado]:
			var final_mod := cv.modulate
			cv.modulate.a = 0.0
			create_tween().tween_property(cv, "modulate", final_mod, 0.25)
	_contagem[lado] = lista.size()


func _texto_total(t: Teste21, esconder_fechada: bool) -> String:
	if t.estourou:
		var ultima := "—" if t.carta_do_estouro < 0 else Carta.nome(t.carta_do_estouro)
		return "ESTOUROU!\nvale a última (%s): %d" % [ultima, t.resultado()]
	if esconder_fechada:
		var visiveis := 0
		for i in t.cartas.size():
			if i != 1:
				visiveis += 11 if Carta.eh_as(t.cartas[i]) else Carta.valor(t.cartas[i])
		return "Visíveis: %d + ?\n%s" % [visiveis, "parou" if t.encerrado else "..."]
	var extra := ""
	if t.desvantagem:
		extra = "\nfora do alcance ideal"
	elif t.critico():
		extra = "\nCRÍTICO!"
	return "Cartas %d / %d\nTeste: %d%s" % [t.soma_cartas(), t.limite, t.resultado(), extra]


func _atualizar_dica() -> void:
	var b := batalha
	if b == null:
		return
	var texto := ""
	var alvo := b.na_posicao(_hover) if b.grade.dentro(_hover) else null
	if alvo != null and not b.unidade_visivel(alvo):
		alvo = null
	if not _spec_area_atual().is_empty():
		var spec := _spec_area_atual()
		var nome: String = b.ativa().cartas[_modo_area].nome() if _modo_area >= 0 else Itens.CONSUMIVEIS[_item_area]["nome"]
		var motivo: String = b.motivo_area(b.ativa(), spec, _hover) if b.grade.dentro(_hover) else ""
		texto = "%s: %s. Clique para confirmar%s; botão direito ou Esc cancela.%s" % [nome,
			"aponte a direção" if Areas.por_direcao(spec) else ("aponte um inimigo" if spec.get("forma", "") == "aglomerado" else "escolha o centro da área"),
			"; R gira a área" if Areas.gira(spec) else "", ("\n(" + motivo + ")") if motivo != "" else ""]
	elif _modo_aliado != "" and b.vez_do_heroi():
		if _modo_aliado.begins_with("manobra:"):
			texto = "%s: clique num inimigo marcado em verde, ao seu lado. Botão direito ou Esc cancela." % Batalha.MANOBRAS[_modo_aliado.substr(8)]["nome"]
		else:
			texto = "%s: clique num aliado marcado em verde. Botão direito ou Esc cancela." % {"tratar": "Tratar sangramento", "comandar": "Comandar", "orientar": "Orientar", "levantar": "Levantar caído"}[_modo_aliado]
	elif not _casa_escolha.is_empty() and b.vez_do_heroi():
		texto = "Escolha a casa de onde atacar (marcadas em azul claro; ficar onde está também vale). Botão direito ou Esc cancela."
	elif _modo_carta >= 0 and b.vez_do_heroi():
		var c = b.ativa().cartas[_modo_carta]
		if b._info_lado(c).has("misseis"):
			texto = "%s: clique 3 vezes nos inimigos marcados; cada clique é 1 de dano (pode repetir o alvo). %d/3%s. Botão direito ou Esc cancela." % [
				c.nome(), _misseis.size(), (" (" + ", ".join(_misseis.map(func(i): return b.unidade(i).nome)) + ")") if not _misseis.is_empty() else ""]
		else:
			texto = "%s: clique num alvo marcado (vermelho = inimigo, verde = aliado). Botão direito ou Esc cancela." % c.nome()
	elif not b.interacao_em(_hover).is_empty() and b.vez_do_heroi():
		var it := b.interacao_em(_hover)
		texto = "%s: %s\n%s" % [it["nome"], it["texto"], "Clique para interagir." if b.ao_alcance(b.ativa(), it)
			else "Chegue mais perto para interagir (até %d quadrado(s))." % int(it.get("alcance", 1))]
	elif alvo != null and not alvo.eh_heroi() and not alvo.alerta:
		texto = "%s · desatento: percebe heróis a até %d quadrados com linha de visão (área marcada). Atacado de surpresa, defende só com 2 cartas." % [alvo.nome, alvo.vigia]
	elif alvo != null and not alvo.eh_heroi():
		texto = "%s · Vida %d/%d · Dano %d + Força %d · Resistência %d · IA %s (risco %d%%, para em %d atacando)%s%s" % [
			alvo.nome, alvo.vida, alvo.vida_max, alvo.dano, alvo.atributo_dano, alvo.resistencia, alvo.perfil,
			int(alvo.risco * 100), alvo.parada_ataque, " · arco: ideal curto e médio" if alvo.a_distancia else "",
			" · IMOBILIZADO" if alvo.imobilizado() else ""]
		if b.vez_do_heroi():
			var motivo := b.motivo_sem_ataque(b.ativa(), alvo)
			texto += "\n" + ("Clique para atacar." if motivo == "" else "Não dá para atacar: %s." % motivo)
	elif b.vez_do_heroi():
		var u := b.ativa()
		var info := b.alcance_movimento(u)
		if info["mapa"].has(_hover):
			if not info["precisa_acao"]:
				texto = "Clique para andar até aqui (usa o deslocamento que sobrou)."
			elif u.acoes_mov > 0:
				texto = "Clique para andar até aqui (gasta a ação de Movimento)."
			else:
				texto = "Clique para andar até aqui (rebaixa uma ação Padrão para Movimento)."
		else:
			texto = "Sua vez: clique num quadrado azul para andar, num goblin marcado em vermelho para atacar ou num \"!\" para interagir."
			if b.objetivo != "":
				texto += "\nObjetivo: " + b.objetivo
	elif b.fase == Batalha.Fase.IA_TURNO:
		texto = "Vez de %s..." % b.ativa().nome
	_dica.text = texto
	_dica.get_parent().visible = texto != ""


# --- Mundo 3D ---------------------------------------------------------------

const ALTURA_NIVEL := 0.6


func _mundo(c: Vector2i) -> Vector3:
	return Vector3(c.x, (batalha.grade.nivel(c) * ALTURA_NIVEL) if batalha != null else 0.0, c.y)


var _materiais := {}   # cor -> material (reusar deixa mapas grandes leves)


func _material(cor: Color, sem_luz := false) -> StandardMaterial3D:
	var chave := cor.to_html() + ("u" if sem_luz else "")
	if _materiais.has(chave):
		return _materiais[chave]
	var m := StandardMaterial3D.new()
	_materiais[chave] = m
	m.albedo_color = cor
	m.roughness = 0.95
	if sem_luz:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if cor.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _malha(mesh: Mesh, cor: Color, pos: Vector3, pai: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _material(cor)
	mi.position = pos
	(pai if pai != null else self).add_child(mi)
	return mi


func _montar_mundo() -> void:
	var g := batalha.grade
	var ambiente := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = COR_FUNDO
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("8a8ca0")
	env.ambient_light_energy = 0.55
	ambiente.environment = env
	add_child(ambiente)

	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-55, -35, 0)
	sol.light_energy = 1.15
	sol.light_color = Color("ffe9c7")
	sol.shadow_enabled = true
	add_child(sol)
	if batalha.escuro:
		# Luz dinâmica (0.19): no escuro quase não há luz ambiente; as tochas fazem o resto.
		if batalha.luz_ambiente >= 1:
			env.ambient_light_color = Color("5a6890")
			env.ambient_light_energy = 0.32
			sol.light_color = Color("9fb4ff")
			sol.light_energy = 0.32
		else:
			env.ambient_light_color = Color("4a4660")
			env.ambient_light_energy = 0.16
			sol.visible = false

	var centro := Vector3((g.largura - 1) / 2.0, 0, (g.altura - 1) / 2.0)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera_segue = g.largura + g.altura > 26
	_camera.size = 15.5 if _camera_segue else 13.6 * maxf(1.0, (g.largura + g.altura) / 22.0)
	add_child(_camera)
	_camera.position = centro + Vector3(10, 10, 10)
	_camera.look_at(centro, Vector3.UP)
	_camera.h_offset = 1.9
	_camera.v_offset = -0.75

	_montar_terreno()

	_marcas = Node3D.new()
	add_child(_marcas)

	var anel_mesh := TorusMesh.new()
	anel_mesh.inner_radius = 0.38
	anel_mesh.outer_radius = 0.47
	_anel = MeshInstance3D.new()
	_anel.mesh = anel_mesh
	_anel.material_override = _material(COR_OURO, true)
	add_child(_anel)

	for u in batalha.unidades:
		_criar_peca(u)


## Níveis (0.23): bloco de pedra sob o chão elevado e degraus nas escadas.
func _bloco_de_nivel(p: Vector2i, h: float, cor: Color) -> void:
	var m := BoxMesh.new()
	m.size = Vector3(1.0, h, 1.0)
	_malha(m, cor.darkened(0.35), Vector3(p.x, h / 2.0 - 0.12, p.y), _terreno)


func _degraus(p: Vector2i) -> void:
	# a escada sobe para o vizinho mais alto
	var alto := p
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if batalha.grade.nivel(p + d) > batalha.grade.nivel(p):
			alto = p + d
	var dir := Vector3(alto.x - p.x, 0, alto.y - p.y)
	for k in 3:
		var m := BoxMesh.new()
		m.size = Vector3(1.0 if dir.z != 0 else 0.34, ALTURA_NIVEL * (k + 1) / 3.0, 1.0 if dir.x != 0 else 0.34)
		var centro := Vector3(p.x, ALTURA_NIVEL * (k + 1) / 6.0 + batalha.grade.nivel(p) * ALTURA_NIVEL - 0.05, p.y) + dir * (-0.33 + 0.33 * k)
		_malha(m, Color("6d6a72"), centro, _terreno)


func _montar_terreno() -> void:
	if _terreno != null:
		remove_child(_terreno)
		_terreno.queue_free()
	_terreno = Node3D.new()
	add_child(_terreno)
	for p in batalha.armas_no_chao:
		var arma_m := BoxMesh.new()
		arma_m.size = Vector3(0.5, 0.06, 0.12)
		var am := _malha(arma_m, Color("c9c9d2"), _mundo(p) + Vector3(0.15, 0.04, 0.2), _terreno)
		am.rotation_degrees = Vector3(0, 35, 0)
	for p in batalha.chamas:
		var chama := CylinderMesh.new()
		chama.top_radius = 0.0
		chama.bottom_radius = 0.35
		chama.height = 0.9
		var c := _malha(chama, Color("ff7a2c"), _mundo(p) + Vector3(0, 0.75, 0), _terreno)
		c.material_override = _material(Color("ff7a2c"), true)
	var g := batalha.grade
	var centro := Vector3((g.largura - 1) / 2.0, 0, (g.altura - 1) / 2.0)
	var piso := BoxMesh.new()
	piso.size = Vector3(0.97, 0.14, 0.97)
	var agua := BoxMesh.new()
	agua.size = Vector3(1.0, 0.1, 1.0)
	# Chão em MultiMesh: um desenho por cor, leve mesmo em mapas grandes.
	var grupos := {}   # cor -> [posições]
	for x in g.largura:
		for y in g.altura:
			var p := Vector2i(x, y)
			var tipo: String = g.obstaculos.get(p, "")
			if tipo == "parede":
				continue   # paredes: desenhadas em bloco (abaixo)
			var e_agua: bool = tipo.begins_with("agua") or tipo in ["ponte_quebrada", "tronco"]
			var cor: Color
			if e_agua:
				cor = Color("2f5f86") if (x + y) % 2 == 0 else Color("336791")
			elif batalha.piso == "pedra":
				cor = Color("4a4750") if (x + y) % 2 == 0 else Color("524f58")
			elif batalha.piso == "lodo":
				cor = Color("34402c") if (x + y) % 2 == 0 else Color("3a4630")
			else:
				cor = Color("3f5c34") if (x + y) % 2 == 0 else Color("466639")
			# Pedaços de 8×8 (0.19): no modo de compatibilidade cada objeto recebe no máximo
			# 8 luzes; com o chão em pedaços, cada pedaço pega as luzes perto dele.
			var chave := cor.to_html() + "|%d,%d" % [x / 8, y / 8]
			if not grupos.has(chave):
				grupos[chave] = {"cor": cor, "agua": e_agua, "pos": []}
			var hn: float = g.nivel(p) * ALTURA_NIVEL
			grupos[chave]["pos"].append(Vector3(x, (-0.12 if e_agua else -0.07) + hn, y))
			if hn > 0.0:
				_bloco_de_nivel(p, hn, cor)
			if g.escadas.has(p):
				_degraus(p)
	for chave in grupos:
		var gr: Dictionary = grupos[chave]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = agua if gr["agua"] else piso
		mm.instance_count = gr["pos"].size()
		for i in gr["pos"].size():
			mm.set_instance_transform(i, Transform3D(Basis(), gr["pos"][i]))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = _material(gr["cor"])
		_terreno.add_child(mmi)
	var borda := BoxMesh.new()
	borda.size = Vector3(g.largura + 0.4, 0.3, g.altura + 0.4)
	_malha(borda, Color("4a3a2a"), Vector3(centro.x, -0.3, centro.z), _terreno)
	var tabua := BoxMesh.new()
	tabua.size = Vector3(0.95, 0.06, 0.22)
	for p in batalha.decoracao:
		if batalha.decoracao[p] == "ponte":
			for k in 4:
				_malha(tabua, Color("7a5a36"), _mundo(p) + Vector3(0, 0.02, -0.36 + k * 0.24), _terreno)
	# Enfeites (0.18): modelos pequenos que não bloqueiam nada.
	for p in batalha.decoracao:
		var enfeite := Modelos.criar_objeto(str(batalha.decoracao[p]), p, batalha.piso)
		if enfeite != null:
			_terreno.add_child(enfeite)
			enfeite.position = _mundo(p)
	if batalha.piso == "pedra":
		_enfeitar_cantos(g)
	# Paredes da masmorra num MultiMesh só (centenas de blocos).
	var paredes := []
	var feitos := _construcoes_em_bloco(g)
	for p in g.obstaculos:
		if g.obstaculos[p] == "parede":
			paredes.append(p)
		elif not feitos.has(p):
			_criar_obstaculo(p, g.obstaculos[p])
	if not paredes.is_empty():
		var bloco := BoxMesh.new()
		bloco.size = Vector3(1.0, 1.1, 1.0)
		var mat_p := StandardMaterial3D.new()
		mat_p.vertex_color_use_as_albedo = true
		mat_p.roughness = 0.95
		var pedacos := {}   # paredes em pedaços de 8×8 (por causa do limite de luzes por objeto)
		for pp in paredes:
			var k := "%d,%d" % [pp.x / 8, pp.y / 8]
			if not pedacos.has(k):
				pedacos[k] = []
			pedacos[k].append(pp)
		for k in pedacos:
			var lista: Array = pedacos[k]
			var mmp := MultiMesh.new()
			mmp.transform_format = MultiMesh.TRANSFORM_3D
			mmp.use_colors = true
			mmp.mesh = bloco
			mmp.instance_count = lista.size()
			for i in lista.size():
				var pp: Vector2i = lista[i]
				# Pedras de tons e alturas um pouco diferentes (0.18), para a parede não parecer um bloco liso.
				var h := float(absi(pp.x * 92837111 ^ pp.y * 689287499) % 100) / 100.0
				var base := Transform3D(Basis().scaled(Vector3(1.0, 1.0 + h * 0.12, 1.0)), _mundo(pp) + Vector3(0, 0.48 + h * 0.06, 0))
				mmp.set_instance_transform(i, base)
				mmp.set_instance_color(i, Color("2e2b33").lerp(Color("4a4550"), h * 0.8))
			var mip := MultiMeshInstance3D.new()
			mip.multimesh = mmp
			mip.material_override = mat_p
			_terreno.add_child(mip)


## Casas e celeiros de várias casas viram um modelo só (0.18). Devolve as casas já feitas.
func _construcoes_em_bloco(g) -> Dictionary:
	var feitos := {}
	for p in g.obstaculos:
		var tipo: String = g.obstaculos[p]
		if not tipo in ["casa", "celeiro"] or feitos.has(p):
			continue
		var bloco := [p]
		var fila := [p]
		var vistos := {p: true}
		while not fila.is_empty():
			var c: Vector2i = fila.pop_back()
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = c + d
				if not vistos.has(n) and g.obstaculos.get(n, "") == tipo:
					vistos[n] = true
					bloco.append(n)
					fila.append(n)
		if bloco.size() < 2:
			continue
		var mn: Vector2i = bloco[0]
		var mx: Vector2i = bloco[0]
		for c in bloco:
			mn = Vector2i(mini(mn.x, c.x), mini(mn.y, c.y))
			mx = Vector2i(maxi(mx.x, c.x), maxi(mx.y, c.y))
		var tam := mx - mn + Vector2i.ONE
		var m := Modelos.criar_objeto(tipo, mn, batalha.piso, tam)
		if m == null:
			continue
		_terreno.add_child(m)
		m.position = (_mundo(mn) + _mundo(mx)) / 2.0
		for c in bloco:
			feitos[c] = true
	return feitos


## Masmorra (0.18): velas, caveiras e escombros nos cantos das salas (só visual).
func _enfeitar_cantos(g) -> void:
	var tipos := ["velas", "escombro", "caveira_vela", "escombro"]
	for x in g.largura:
		for y in g.altura:
			var p := Vector2i(x, y)
			if g.obstaculos.has(p) or batalha.decoracao.has(p):
				continue
			var paredes := 0
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if g.obstaculos.get(p + d, "") == "parede":
					paredes += 1
			var sorte := absi(x * 73856093 ^ y * 19349663) % 7
			if paredes >= 2 and sorte < 3:
				var m := Modelos.criar_objeto(tipos[(x + y) % tipos.size()], p, batalha.piso)
				if m != null:
					_terreno.add_child(m)
					m.position = _mundo(p) + Vector3(0.22 * signf(randf() - 0.5), 0, 0.22 * signf(randf() - 0.5))


func _criar_obstaculo(p: Vector2i, tipo: String) -> void:
	var pai := _terreno
	var modelo := Modelos.criar_objeto(tipo, p, batalha.piso)
	if modelo != null:
		pai.add_child(modelo)
		modelo.position = _mundo(p)
		return
	match tipo:
		"casa", "celeiro":
			var m := BoxMesh.new()
			m.size = Vector3(1.0, 1.3, 1.0)
			_malha(m, Color("b99c7a") if tipo == "casa" else Color("8a3b2e"), _mundo(p) + Vector3(0, 0.65, 0), pai)
			var teto := PrismMesh.new()
			teto.size = Vector3(1.04, 0.5, 1.04)
			_malha(teto, Color("5a3d2a"), _mundo(p) + Vector3(0, 1.55, 0), pai)
		"npc":
			var corpo := CapsuleMesh.new()
			corpo.radius = 0.24
			corpo.height = 1.1
			_malha(corpo, Color("a7894f"), _mundo(p) + Vector3(0, 0.6, 0), pai)
			var chapeu := CylinderMesh.new()
			chapeu.top_radius = 0.12
			chapeu.bottom_radius = 0.32
			chapeu.height = 0.12
			_malha(chapeu, Color("d8c38a"), _mundo(p) + Vector3(0, 1.2, 0), pai)
		"poco":
			var m := CylinderMesh.new()
			m.top_radius = 0.4
			m.bottom_radius = 0.42
			m.height = 0.5
			_malha(m, Color("8a8a8f"), _mundo(p) + Vector3(0, 0.25, 0), pai)
			var buraco := CylinderMesh.new()
			buraco.top_radius = 0.3
			buraco.bottom_radius = 0.3
			buraco.height = 0.02
			_malha(buraco, Color("111111"), _mundo(p) + Vector3(0, 0.51, 0), pai)
		"tenda":
			var m := PrismMesh.new()
			m.size = Vector3(0.95, 0.9, 0.95)
			_malha(m, Color("7a6a4a"), _mundo(p) + Vector3(0, 0.45, 0), pai)
		"fogueira", "fogueira_apagada":
			for k in 3:
				var lenha := BoxMesh.new()
				lenha.size = Vector3(0.6, 0.08, 0.1)
				var l := _malha(lenha, Color("5a3d22"), _mundo(p) + Vector3(0, 0.05, 0), pai)
				l.rotation_degrees = Vector3(0, 60 * k, 0)
			if tipo == "fogueira":
				var chama := CylinderMesh.new()
				chama.top_radius = 0.0
				chama.bottom_radius = 0.2
				chama.height = 0.45
				var c := _malha(chama, Color("ff9a3c"), _mundo(p) + Vector3(0, 0.3, 0), pai)
				c.material_override = _material(Color("ff9a3c"), true)
		"saco":
			var m := SphereMesh.new()
			m.radius = 0.3
			m.height = 0.5
			_malha(m, Color("cbb88c"), _mundo(p) + Vector3(0, 0.25, 0), pai)
		"monte_terra":
			var m := SphereMesh.new()
			m.radius = 0.48
			m.height = 0.6
			_malha(m, Color("6b5139"), _mundo(p) + Vector3(0, 0.15, 0), pai)
		"tronco":
			var m := CylinderMesh.new()
			m.top_radius = 0.2
			m.bottom_radius = 0.22
			m.height = 1.0
			var t := _malha(m, Color("6b4a2b"), _mundo(p) + Vector3(0, 0.08, 0), pai)
			t.rotation_degrees = Vector3(0, 0, 90)
		"feno":
			var m := BoxMesh.new()
			m.size = Vector3(0.82, 0.62, 0.82)
			_malha(m, Color("c9a74a"), _mundo(p) + Vector3(0, 0.31, 0), pai)
		"pedra":
			var m := SphereMesh.new()
			m.radius = 0.42
			m.height = 0.6
			_malha(m, Color("7d7c84"), _mundo(p) + Vector3(0, 0.25, 0), pai)
		"cerca":
			var m := BoxMesh.new()
			m.size = Vector3(0.98, 0.12, 0.1)
			_malha(m, Color("6b4a2b"), _mundo(p) + Vector3(0, 0.45, 0), pai)
			_malha(m, Color("6b4a2b"), _mundo(p) + Vector3(0, 0.22, 0), pai)
			var poste := BoxMesh.new()
			poste.size = Vector3(0.12, 0.6, 0.12)
			_malha(poste, Color("5a3d22"), _mundo(p) + Vector3(-0.42, 0.3, 0), pai)
		"agua_pedras":
			var m := SphereMesh.new()
			m.radius = 0.3
			m.height = 0.28
			_malha(m, Color("6f7470"), _mundo(p) + Vector3(0.05, -0.02, 0.05), pai)
		"ponte_quebrada":
			var tabua := BoxMesh.new()
			tabua.size = Vector3(0.9, 0.06, 0.2)
			var t1 := _malha(tabua, Color("5e4630"), _mundo(p) + Vector3(0, 0.0, -0.25), pai)
			t1.rotation_degrees = Vector3(0, 12, 8)
			var poste := BoxMesh.new()
			poste.size = Vector3(0.1, 0.5, 0.1)
			_malha(poste, Color("4a3622"), _mundo(p) + Vector3(-0.42, 0.15, 0.42), pai)
		"tocha_parede":
			var m := BoxMesh.new()
			m.size = Vector3(1.0, 1.1, 1.0)
			_malha(m, Color("2e2b33"), _mundo(p) + Vector3(0, 0.48, 0), pai)
			var cabo := BoxMesh.new()
			cabo.size = Vector3(0.08, 0.35, 0.08)
			_malha(cabo, Color("5a3d22"), _mundo(p) + Vector3(0, 1.15, 0), pai)
			var fogo := CylinderMesh.new()
			fogo.top_radius = 0.0
			fogo.bottom_radius = 0.14
			fogo.height = 0.3
			var fo := _malha(fogo, Color("ffb347"), _mundo(p) + Vector3(0, 1.45, 0), pai)
			fo.material_override = _material(Color("ffb347"), true)
		"pilar":
			var m := CylinderMesh.new()
			m.top_radius = 0.34
			m.bottom_radius = 0.4
			m.height = 1.4
			_malha(m, Color("6a6670"), _mundo(p) + Vector3(0, 0.7, 0), pai)
		"sarcofago":
			var m := BoxMesh.new()
			m.size = Vector3(0.9, 0.5, 0.6)
			_malha(m, Color("8a8580"), _mundo(p) + Vector3(0, 0.25, 0), pai)
			var tampa := BoxMesh.new()
			tampa.size = Vector3(0.94, 0.08, 0.64)
			_malha(tampa, Color("a29c95"), _mundo(p) + Vector3(0, 0.54, 0), pai)
		"mesa":
			var m := BoxMesh.new()
			m.size = Vector3(0.9, 0.08, 0.7)
			_malha(m, Color("6b4a2b"), _mundo(p) + Vector3(0, 0.45, 0), pai)
			var perna := BoxMesh.new()
			perna.size = Vector3(0.08, 0.42, 0.08)
			for lx in [-0.38, 0.38]:
				_malha(perna, Color("5a3d22"), _mundo(p) + Vector3(lx, 0.21, 0), pai)
		"fonte":
			var m := CylinderMesh.new()
			m.top_radius = 0.42
			m.bottom_radius = 0.36
			m.height = 0.45
			_malha(m, Color("8f8c93"), _mundo(p) + Vector3(0, 0.22, 0), pai)
			var aguaf := CylinderMesh.new()
			aguaf.top_radius = 0.33
			aguaf.bottom_radius = 0.33
			aguaf.height = 0.02
			_malha(aguaf, Color("5aa0d0"), _mundo(p) + Vector3(0, 0.46, 0), pai)
		"altar":
			var m := BoxMesh.new()
			m.size = Vector3(0.95, 0.7, 0.6)
			_malha(m, Color("b8b0a0"), _mundo(p) + Vector3(0, 0.35, 0), pai)
			var vela := CylinderMesh.new()
			vela.top_radius = 0.04
			vela.bottom_radius = 0.04
			vela.height = 0.2
			for lx in [-0.3, 0.3]:
				var v := _malha(vela, Color("ffe9a8"), _mundo(p) + Vector3(lx, 0.8, 0), pai)
				v.material_override = _material(Color("ffe9a8"), true)
		"porta":
			var m := BoxMesh.new()
			m.size = Vector3(1.0, 1.1, 0.3)
			_malha(m, Color("5c5048"), _mundo(p) + Vector3(0, 0.55, 0), pai)
			var faixa := BoxMesh.new()
			faixa.size = Vector3(1.02, 0.08, 0.34)
			_malha(faixa, Color("3a3a40"), _mundo(p) + Vector3(0, 0.8, 0), pai)
		"rocha":
			var m := BoxMesh.new()
			m.size = Vector3(0.96, 1.5, 0.96)
			_malha(m, Color("6d6a70") if (p.x + p.y) % 2 == 0 else Color("78747b"), _mundo(p) + Vector3(0, 0.75, 0), pai)
		"arvore":
			var tronco := CylinderMesh.new()
			tronco.top_radius = 0.08
			tronco.bottom_radius = 0.11
			tronco.height = 0.6
			_malha(tronco, Color("5a3d22"), _mundo(p) + Vector3(0, 0.3, 0), pai)
			var copa := CylinderMesh.new()
			copa.top_radius = 0.0
			copa.bottom_radius = 0.42
			copa.height = 1.1
			_malha(copa, Color("2e4d2a"), _mundo(p) + Vector3(0, 1.05, 0), pai)
		"bau":
			var m := BoxMesh.new()
			m.size = Vector3(0.7, 0.45, 0.48)
			_malha(m, Color("6b4a2b"), _mundo(p) + Vector3(0, 0.22, 0), pai)
			var faixa := BoxMesh.new()
			faixa.size = Vector3(0.72, 0.07, 0.5)
			_malha(faixa, COR_OURO.darkened(0.2), _mundo(p) + Vector3(0, 0.36, 0), pai)
		"carroca":
			var m := BoxMesh.new()
			m.size = Vector3(0.9, 0.4, 0.62)
			_malha(m, Color("7a5a36"), _mundo(p) + Vector3(0, 0.42, 0), pai)
			var saco := SphereMesh.new()
			saco.radius = 0.2
			saco.height = 0.34
			_malha(saco, Color("d8c69a"), _mundo(p) + Vector3(-0.15, 0.72, 0), pai)
			_malha(saco, Color("cbb88c"), _mundo(p) + Vector3(0.18, 0.7, 0.05), pai)
			var roda := CylinderMesh.new()
			roda.top_radius = 0.22
			roda.bottom_radius = 0.22
			roda.height = 0.06
			for lado in [-1, 1]:
				var r := _malha(roda, Color("4a3622"), _mundo(p) + Vector3(0, 0.22, 0.34 * lado), pai)
				r.rotation_degrees = Vector3(90, 0, 0)


## Marcadores "!" nos pontos de interação: dourado quando dá para interagir.
func _atualizar_marcadores() -> void:
	var b := batalha
	for it in b.interacoes:
		var id: String = it["id"]
		if not _marcadores.has(id):
			var n := Node3D.new()
			add_child(n)
			n.position = _mundo(it["pos"]) + Vector3(0, 1.0 if not b.grade.obstaculos.get(it["pos"], "") in ["rocha", "casa", "celeiro", "npc"] else 2.0, 0)
			var l := Label3D.new()
			l.text = "!"
			l.font = _fonte_negrito
			l.font_size = 72
			l.pixel_size = 0.007
			l.outline_size = 14
			l.outline_modulate = Color(0, 0, 0, 0.9)
			l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			l.no_depth_test = true
			n.add_child(l)
			var tw := l.create_tween().set_loops()
			tw.tween_property(l, "position:y", 0.18, 0.7).set_trans(Tween.TRANS_SINE)
			tw.tween_property(l, "position:y", 0.0, 0.7).set_trans(Tween.TRANS_SINE)
			_marcadores[id] = n
		var no: Node3D = _marcadores[id]
		no.visible = it.get("ativa", true) and (not b.nevoa_de_guerra or b.explorado.has(it["pos"]))
		if it.get("descanso", false):
			_simbolo_de_descanso(it)
		var perto := b.vez_do_heroi() and b.ao_alcance(b.ativa(), it)
		(no.get_child(0) as Label3D).modulate = Color("ffe08a") if perto else Color("b9954f")


## Ponto de descanso (0.19): um círculo de runas no chão. Cinza enquanto há inimigos
## por perto; dourado quando dá para descansar; verde depois de usado (dá para salvar).
var _simbolos := {}


func _simbolo_de_descanso(it: Dictionary) -> void:
	var b := batalha
	var id: String = it["id"]
	if not _simbolos.has(id) or not is_instance_valid(_simbolos[id]):
		var n := Node3D.new()
		add_child(n)
		n.position = _mundo(it["pos"]) + Vector3(0, 0.03, 0)
		var anel := TorusMesh.new()
		anel.inner_radius = 0.5 if not b.grade.obstaculos.has(it["pos"]) else 0.72
		anel.outer_radius = anel.inner_radius + 0.07
		var mi := MeshInstance3D.new()
		mi.mesh = anel
		mi.scale = Vector3(1, 0.15, 1)
		n.add_child(mi)
		for k in 6:
			var runa := BoxMesh.new()
			runa.size = Vector3(0.06, 0.01, 0.18)
			var r := MeshInstance3D.new()
			r.mesh = runa
			var ang := k * TAU / 6.0
			r.position = Vector3(cos(ang), 0, sin(ang)) * (anel.inner_radius - 0.14)
			r.rotation.y = -ang
			n.add_child(r)
		if it.get("chao", false):
			var cama := Modelos.criar_objeto("saco_de_dormir", it["pos"], b.piso)
			if cama != null:
				n.add_child(cama)
				cama.position = Vector3(0.12, -0.03, 0.1)
		_simbolos[id] = n
	var cor := Color("7f8590")
	if b.descansos_usados.has(id):
		cor = Color("7fe0a0")
	elif b.descanso_liberado(it):
		cor = Color("ffd36b")
	var n2: Node3D = _simbolos[id]
	n2.visible = not b.nevoa_de_guerra or b.explorado.has(it["pos"])
	for f in n2.get_children():
		if f is MeshInstance3D:
			f.material_override = _material(cor, true)


## Onde uma unidade fica de pé: em cima da pedra alta, mais alto (0.19).
func _mundo_unidade(c: Vector2i) -> Vector3:
	var extra := 0.85 if batalha.grade.obstaculos.get(c, "") == "pedra_alta" else 0.0
	if batalha.grade.escadas.has(c):
		extra += ALTURA_NIVEL / 2.0
	return _mundo(c) + Vector3(0, extra, 0)


func _criar_peca(u) -> void:
	var peca := Node3D.new()
	add_child(peca)
	peca.position = _mundo_unidade(u.pos)
	var base := CylinderMesh.new()
	base.top_radius = 0.36
	base.bottom_radius = 0.38
	base.height = 0.06
	_malha(base, Color("4f7fb3") if u.eh_heroi() else Color("9b3b33"), Vector3(0, 0.03, 0), peca)
	var altura := 1.0
	var modelo := Modelos.criar(u.tipo)
	if modelo != null:
		peca.add_child(modelo)
		_modelos[u.id] = modelo
		altura = float(modelo.get_meta("altura")) + 0.1
	else:
		match u.tipo:
			"guerreiro":
				var corpo := CapsuleMesh.new()
				corpo.radius = 0.27
				corpo.height = 1.15
				_malha(corpo, Color("8ea3b8"), Vector3(0, 0.62, 0), peca)
				var espada := BoxMesh.new()
				espada.size = Vector3(0.07, 0.75, 0.07)
				_malha(espada, Color("d8dde3"), Vector3(0.34, 0.65, 0.1), peca)
				var escudo := CylinderMesh.new()
				escudo.top_radius = 0.22
				escudo.bottom_radius = 0.22
				escudo.height = 0.06
				var e := _malha(escudo, Color("6b4a2b"), Vector3(-0.3, 0.6, 0.05), peca)
				e.rotation_degrees = Vector3(0, 0, 90)
				altura = 1.3
			"ladino":
				var corpo := CapsuleMesh.new()
				corpo.radius = 0.24
				corpo.height = 1.05
				_malha(corpo, Color("3b3946"), Vector3(0, 0.57, 0), peca)
				var capuz := SphereMesh.new()
				capuz.radius = 0.2
				capuz.height = 0.3
				_malha(capuz, Color("26242e"), Vector3(0, 1.05, 0), peca)
				var adaga := BoxMesh.new()
				adaga.size = Vector3(0.05, 0.38, 0.05)
				_malha(adaga, Color("cfd4da"), Vector3(0.3, 0.55, 0.12), peca)
				altura = 1.25
			"clerigo":
				var corpo := CylinderMesh.new()
				corpo.top_radius = 0.18
				corpo.bottom_radius = 0.32
				corpo.height = 1.05
				_malha(corpo, Color("e6dfcc"), Vector3(0, 0.55, 0), peca)
				var cabeca := SphereMesh.new()
				cabeca.radius = 0.16
				cabeca.height = 0.32
				_malha(cabeca, Color("d9b48f"), Vector3(0, 1.2, 0), peca)
				var simbolo := TorusMesh.new()
				simbolo.inner_radius = 0.07
				simbolo.outer_radius = 0.12
				var sb := _malha(simbolo, COR_OURO, Vector3(0, 0.75, 0.26), peca)
				sb.rotation_degrees = Vector3(90, 0, 0)
				altura = 1.35
			"cacador":
				var corpo := CapsuleMesh.new()
				corpo.radius = 0.24
				corpo.height = 1.1
				_malha(corpo, Color("4f6b3a"), Vector3(0, 0.6, 0), peca)
				var arco := TorusMesh.new()
				arco.inner_radius = 0.32
				arco.outer_radius = 0.36
				var a := _malha(arco, Color("8a6a3c"), Vector3(0.3, 0.65, 0), peca)
				a.rotation_degrees = Vector3(90, 0, 0)
				altura = 1.3
			"mago":
				var corpo := CylinderMesh.new()
				corpo.top_radius = 0.16
				corpo.bottom_radius = 0.3
				corpo.height = 1.0
				_malha(corpo, Color("5b3f8c"), Vector3(0, 0.52, 0), peca)
				var chapeu := CylinderMesh.new()
				chapeu.top_radius = 0.0
				chapeu.bottom_radius = 0.22
				chapeu.height = 0.45
				_malha(chapeu, Color("43306b"), Vector3(0, 1.25, 0), peca)
				var cajado := CylinderMesh.new()
				cajado.top_radius = 0.03
				cajado.bottom_radius = 0.03
				cajado.height = 1.2
				_malha(cajado, Color("7a5a36"), Vector3(0.32, 0.62, 0), peca)
				var orbe := SphereMesh.new()
				orbe.radius = 0.08
				orbe.height = 0.16
				_malha(orbe, Color("9fd3ff"), Vector3(0.32, 1.25, 0), peca)
				altura = 1.5
			"afogado":
				var corpo := CapsuleMesh.new()
				corpo.radius = 0.25
				corpo.height = 1.05
				_malha(corpo, Color("5f7a66"), Vector3(0, 0.55, 0), peca)
				var algas := CylinderMesh.new()
				algas.top_radius = 0.27
				algas.bottom_radius = 0.33
				algas.height = 0.35
				_malha(algas, Color("3d5a2c"), Vector3(0, 0.25, 0), peca)
				for lx in [-0.07, 0.07]:
					var olho := SphereMesh.new()
					olho.radius = 0.035
					olho.height = 0.07
					var ol := _malha(olho, Color("d8f0a0"), Vector3(lx, 0.95, 0.2), peca)
					ol.material_override = _material(Color("d8f0a0"), true)
				altura = 1.2
			"fantasma":
				var corpo := CylinderMesh.new()
				corpo.top_radius = 0.2
				corpo.bottom_radius = 0.02
				corpo.height = 0.9
				var c := _malha(corpo, Color(0.85, 0.92, 1.0, 0.55), Vector3(0, 0.85, 0), peca)
				c.material_override = _material(Color(0.85, 0.92, 1.0, 0.55), true)
				var cab := SphereMesh.new()
				cab.radius = 0.2
				cab.height = 0.4
				var cb := _malha(cab, Color(0.9, 0.95, 1.0, 0.6), Vector3(0, 1.38, 0), peca)
				cb.material_override = _material(Color(0.9, 0.95, 1.0, 0.6), true)
				altura = 1.6
			"bruxa":
				var corpo := CylinderMesh.new()
				corpo.top_radius = 0.15
				corpo.bottom_radius = 0.34
				corpo.height = 1.05
				_malha(corpo, Color("2b2236"), Vector3(0, 0.53, 0), peca)
				var cabeca := SphereMesh.new()
				cabeca.radius = 0.15
				cabeca.height = 0.3
				_malha(cabeca, Color("8fa07a"), Vector3(0, 1.18, 0), peca)
				var chapeu := CylinderMesh.new()
				chapeu.top_radius = 0.0
				chapeu.bottom_radius = 0.26
				chapeu.height = 0.55
				var ch := _malha(chapeu, Color("1c1626"), Vector3(0, 1.55, 0), peca)
				ch.rotation_degrees = Vector3(0, 0, -12)
				var aba := CylinderMesh.new()
				aba.top_radius = 0.38
				aba.bottom_radius = 0.38
				aba.height = 0.04
				_malha(aba, Color("1c1626"), Vector3(0, 1.3, 0), peca)
				var orbe := SphereMesh.new()
				orbe.radius = 0.09
				orbe.height = 0.18
				var ob := _malha(orbe, Color("7dff9a"), Vector3(0.34, 0.85, 0.1), peca)
				ob.material_override = _material(Color("7dff9a"), true)
				altura = 1.9
			"esqueleto", "esqueleto_arqueiro", "cavaleiro_ossudo":
				var grande: bool = u.tipo == "cavaleiro_ossudo"
				var k := 1.35 if grande else 1.0
				var osso := Color("e2dccb")
				var corpo := CylinderMesh.new()
				corpo.top_radius = 0.16 * k
				corpo.bottom_radius = 0.1 * k
				corpo.height = 0.55 * k
				_malha(corpo, osso, Vector3(0, 0.62 * k, 0), peca)
				for lx in [-0.09, 0.09]:
					var perna := CylinderMesh.new()
					perna.top_radius = 0.04 * k
					perna.bottom_radius = 0.04 * k
					perna.height = 0.4 * k
					_malha(perna, osso, Vector3(lx * k, 0.2 * k, 0), peca)
				var cranio := SphereMesh.new()
				cranio.radius = 0.15 * k
				cranio.height = 0.3 * k
				_malha(cranio, osso, Vector3(0, 1.02 * k, 0), peca)
				for lx in [-0.05, 0.05]:
					var olho := SphereMesh.new()
					olho.radius = 0.035 * k
					olho.height = 0.07 * k
					var ol := _malha(olho, Color("7fe0ff") if grande else Color("1a1a1a"), Vector3(lx * k, 1.04 * k, 0.12 * k), peca)
					if grande:
						ol.material_override = _material(Color("7fe0ff"), true)
				if u.tipo == "esqueleto_arqueiro":
					var arco := TorusMesh.new()
					arco.inner_radius = 0.26
					arco.outer_radius = 0.3
					var a := _malha(arco, Color("6b5a3c"), Vector3(0.28, 0.6, 0), peca)
					a.rotation_degrees = Vector3(90, 0, 0)
				else:
					var espada := BoxMesh.new()
					espada.size = Vector3(0.06, 0.7 * k, 0.06)
					_malha(espada, Color("9a9ea6"), Vector3(0.3 * k, 0.6 * k, 0.08), peca)
				if grande:
					var elmo := CylinderMesh.new()
					elmo.top_radius = 0.12
					elmo.bottom_radius = 0.22
					elmo.height = 0.25
					_malha(elmo, Color("6e6a62"), Vector3(0, 1.55, 0), peca)
					var escudo := CylinderMesh.new()
					escudo.top_radius = 0.28
					escudo.bottom_radius = 0.28
					escudo.height = 0.06
					var e := _malha(escudo, Color("4a4038"), Vector3(-0.4, 0.8, 0.05), peca)
					e.rotation_degrees = Vector3(0, 0, 90)
				altura = 1.3 * k
			"toupeira":
				var corpo := SphereMesh.new()
				corpo.radius = 0.62
				corpo.height = 0.95
				_malha(corpo, Color("5b4636"), Vector3(0, 0.5, 0), peca)
				var focinho := SphereMesh.new()
				focinho.radius = 0.18
				focinho.height = 0.3
				_malha(focinho, Color("d08a8a"), Vector3(0.45, 0.45, 0.45), peca)
				for lado in [-1, 1]:
					var garra := PrismMesh.new()
					garra.size = Vector3(0.3, 0.18, 0.3)
					_malha(garra, Color("e8e0c8"), Vector3(0.35 + 0.2 * lado, 0.12, 0.35 - 0.2 * lado), peca)
				altura = 1.1
			_:
				var corpo := CapsuleMesh.new()
				corpo.radius = 0.22
				corpo.height = 0.8
				_malha(corpo, Color("6e9440"), Vector3(0, 0.45, 0), peca)
				for lado in [-1, 1]:
					var orelha := PrismMesh.new()
					orelha.size = Vector3(0.12, 0.22, 0.05)
					var o := _malha(orelha, Color("7da84a"), Vector3(0.2 * lado, 0.78, 0), peca)
					o.rotation_degrees = Vector3(0, 0, -70 * lado)
				if u.tipo == "goblin_atirador":
					var chapeu := CylinderMesh.new()
					chapeu.top_radius = 0.0
					chapeu.bottom_radius = 0.2
					chapeu.height = 0.3
					_malha(chapeu, Color("6b4a2b"), Vector3(0, 0.95, 0), peca)
					var arco := TorusMesh.new()
					arco.inner_radius = 0.26
					arco.outer_radius = 0.3
					var a := _malha(arco, Color("8a6a3c"), Vector3(0.28, 0.5, 0), peca)
					a.rotation_degrees = Vector3(90, 0, 0)
				altura = 1.0
	var r := Label3D.new()
	r.font = _fonte_negrito
	r.font_size = 34
	r.pixel_size = 0.0065
	r.outline_size = 10
	r.outline_modulate = Color(0, 0, 0, 0.85)
	r.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	r.no_depth_test = true
	r.position = Vector3(0, altura + 0.35, 0)
	peca.add_child(r)
	_pecas[u.id] = peca
	_rotulos[u.id] = r
	if not u.viva() and not u.eh_heroi():
		peca.visible = false   # jogo carregado: quem já caiu não aparece
		r.visible = false


func _atualizar_pecas() -> void:
	var b := batalha
	for u in b.unidades:
		var r: Label3D = _rotulos[u.id]
		var extra := ""
		if not u.eh_heroi() and u.viva() and not u.fichas.is_empty():
			var fs := PackedStringArray()
			for f in u.fichas:
				fs.append(f if int(u.fichas[f]) == 1 else "%s %d" % [f, u.fichas[f]])
			extra = "\n" + ", ".join(fs)
		elif u.eh_heroi() and u.viva() and u.fichas_total("Fogo") + u.fichas_total("Sangramento") + u.fichas_total("Veneno") > 0:
			var fs := PackedStringArray()
			for f in ["Fogo", "Sangramento", "Veneno"]:
				if u.fichas_total(f) > 0:
					fs.append("%s %d" % [f, u.fichas_total(f)])
			extra = "\n" + ", ".join(fs)
		elif u.eh_heroi() and not u.viva():
			extra = "\n(inconsciente)"
		elif u.eh_heroi() and u.efeitos.has("oculto"):
			extra = "\n(oculto)"
		if u.viva() and u.efeitos.has("caido"):
			extra += "\n(caído)"
		if u.viva() and u.efeitos.has("confuso"):
			extra += "\n(confuso)"
		r.text = "%s\n%s%s%s" % [u.nome, u.vida_texto(), extra,
			("\n(dormindo)" if u.dormindo else "\n(desatento)") if u.viva() and not u.eh_heroi() and not u.alerta else ""]
		r.modulate = Color("cfe1ff") if u.eh_heroi() else Color("ffd2c8")
		if u.eh_heroi() and _pecas.has(u.id):
			_barra_de_vida(u, r)
		if not u.eh_heroi() and _pecas.has(u.id) and u.viva():
			var ve := b.unidade_visivel(u)
			_pecas[u.id].visible = ve
			r.visible = ve
		if u.eh_heroi() and _pecas.has(u.id):
			var caido: bool = not u.viva()
			if _modelos.has(u.id):
				var m: Node3D = _modelos[u.id]
				if caido != bool(m.get_meta("caido", false)):
					m.set_meta("caido", caido)
					Modelos.tocar(m, "Death_A" if caido else "Lie_StandUp", not caido)
			else:
				_pecas[u.id].rotation_degrees = Vector3(80, 0, 0) if caido else Vector3.ZERO
	var ativa := b.ativa()
	_anel.visible = ativa != null and ativa.viva()
	if _anel.visible and not _ocupado:
		_anel.position = _pecas[ativa.id].position + Vector3(0, 0.08, 0)
	elif _anel.visible:
		_anel.position = _mundo(ativa.pos) + Vector3(0, 0.08, 0)


func _atualizar_marcas() -> void:
	if _marcas == null:
		return
	for filho in _marcas.get_children():
		filho.queue_free()
	var b := batalha
	var plano := PlaneMesh.new()
	plano.size = Vector2(0.9, 0.9)
	if not _ocupado and b.fase == Batalha.Fase.RESOLVIDO and b.resultado.get("passo", "") != "":
		var quem := b.unidade(b.resultado["passo"])
		for d in Grade.DIRECOES:
			var p: Vector2i = quem.pos + d
			if b.grade.dentro(p) and not b.grade.bloqueado(p) and b.na_posicao(p) == null:
				_marca(plano, p, Color(0.35, 0.6, 1.0, 0.45))
	elif not _ocupado and not _spec_area_atual().is_empty():
		var spec := _spec_area_atual()
		var u := b.ativa()
		var valido := b.grade.dentro(_hover) and b.motivo_area(u, spec, _hover) == ""
		if b.grade.dentro(_hover):
			for p in b.celulas_da_area(u, spec, _hover, _rot_area):
				_marca(plano, p, Color(1.0, 0.55, 0.15, 0.55) if valido else Color(0.6, 0.6, 0.6, 0.35), 0.011)
		if spec.has("alcance") and spec.get("forma", "") != "aglomerado":
			var r := int(spec["alcance"])
			for x in range(-r, r + 1):
				for y in range(-r, r + 1):
					var q: Vector2i = u.pos + Vector2i(x, y)
					if b.grade.dentro(q) and b.motivo_area(u, spec, q) == "":
						_marca(plano, q, Color(1.0, 0.85, 0.4, 0.12), 0.004)
	elif b.vez_do_heroi() and not _ocupado and _modo_aliado != "":
		for o in _alvos_aliado(_modo_aliado):
			_marca(plano, o.pos, Color(0.3, 0.95, 0.45, 0.6))
	elif b.vez_do_heroi() and not _ocupado and not _casa_escolha.is_empty():
		for p in _casa_escolha["casas"]:
			_marca(plano, p, Color(0.35, 0.85, 1.0, 0.55))
	elif b.vez_do_heroi() and not _ocupado and _modo_carta >= 0:
		var u := b.ativa()
		for o in b.alvos_de_habilidade(u, u.cartas[_modo_carta]):
			_marca(plano, o.pos, Color(0.95, 0.25, 0.2, 0.65) if not o.eh_heroi() else Color(0.3, 0.95, 0.45, 0.6))
	elif b.vez_do_heroi() and not _ocupado:
		var u := b.ativa()
		var info := b.alcance_movimento(u)
		var cor := Color(0.35, 0.6, 1.0, 0.45) if not info["precisa_acao"] else Color(0.35, 0.6, 1.0, 0.32)
		for p in info["mapa"]:
			_marca(plano, p, cor)
		for o in b.inimigos_vivos():
			if b.motivo_sem_ataque(u, o) == "":
				_marca(plano, o.pos, Color(0.95, 0.25, 0.2, 0.55))
	var vigia = b.na_posicao(_hover) if b.grade.dentro(_hover) else null
	if vigia != null and not vigia.eh_heroi() and not vigia.alerta:
		for x in range(-vigia.vigia, vigia.vigia + 1):
			for y in range(-vigia.vigia, vigia.vigia + 1):
				var p: Vector2i = vigia.pos + Vector2i(x, y)
				if p != vigia.pos and b.grade.dentro(p) and b.grade.linha_de_visao(vigia.pos, p):
					_marca(plano, p, Color(1.0, 0.45, 0.2, 0.22), 0.009)
	if b.vez_do_heroi() and not _ocupado and _modo_carta < 0:
		for it in b.interacoes_ativas():
			if b.ao_alcance(b.ativa(), it):
				_marca(plano, it["pos"], Color(1.0, 0.8, 0.3, 0.5), 0.01)
	if b.grade.dentro(_hover):
		_marca(plano, _hover, Color(1.0, 0.85, 0.4, 0.35), 0.012)


## Zonas no mapa: cada tipo com uma cor; a armadilha é um quadradinho escuro.
const CORES_ZONA := {"nevoa": Color(0.8, 0.85, 0.95, 0.35), "fumaca": Color(0.55, 0.55, 0.6, 0.45),
	"penitencia": Color(0.95, 0.35, 0.2, 0.28), "louvor": Color(1.0, 0.9, 0.4, 0.28), "conduite": Color(0.4, 0.8, 1.0, 0.28),
	"justica": Color(1.0, 0.75, 0.3, 0.28), "covil": Color(0.4, 0.9, 0.4, 0.22), "piche": Color(0.12, 0.1, 0.08, 0.6),
	"armadilha": Color(0.35, 0.22, 0.12, 0.85), "muro": Color(0.5, 0.45, 0.4, 1.0),
	"lodo": Color(0.25, 0.2, 0.1, 0.45), "rito": Color(1.0, 0.95, 0.6, 0.18), "marca": Color(1.0, 0.1, 0.05, 0.55)}


func _desenhar_zonas() -> void:
	if _zonas_no == null:
		_zonas_no = Node3D.new()
		add_child(_zonas_no)
	for f in _zonas_no.get_children():
		f.queue_free()
	var plano := PlaneMesh.new()
	plano.size = Vector2(0.98, 0.98)
	var peq := PlaneMesh.new()
	peq.size = Vector2(0.4, 0.4)
	for z in batalha.zonas:
		var cor: Color = CORES_ZONA.get(z["tipo"], Color(1, 1, 1, 0.25))
		for c in z["celulas"]:
			var mi := MeshInstance3D.new()
			if z["tipo"] == "muro":
				# Muro de Rocha: um bloco alto que tapa a passagem e a visão.
				var bloco := BoxMesh.new()
				bloco.size = Vector3(0.96, 1.1, 0.96)
				mi.mesh = bloco
				mi.material_override = _material(cor, false)
				mi.position = _mundo(c) + Vector3(0, 0.55, 0)
				_zonas_no.add_child(mi)
				if c == z["celulas"][0]:
					var lv := Label3D.new()
					lv.text = "Muro %d PV" % int(z.get("vida", 12))
					lv.font = _fonte_negrito
					lv.font_size = 30
					lv.pixel_size = 0.006
					lv.outline_size = 8
					lv.billboard = BaseMaterial3D.BILLBOARD_ENABLED
					lv.no_depth_test = true
					lv.position = _mundo(c) + Vector3(0, 1.4, 0)
					_zonas_no.add_child(lv)
				continue
			mi.mesh = peq if z["tipo"] == "armadilha" else plano
			mi.material_override = _material(cor, true)
			mi.position = _mundo(c) + Vector3(0, 0.02 if z["tipo"] in ["nevoa", "fumaca"] else 0.008, 0)
			_zonas_no.add_child(mi)
	# Armadilhas achadas (0.23): casas em vermelho com um "!" em cima.
	for c in batalha.casas_de_armadilha():
		var q := PlaneMesh.new()
		q.size = Vector2(0.9, 0.9)
		var mt := MeshInstance3D.new()
		mt.mesh = q
		mt.material_override = _material(Color(0.9, 0.15, 0.1, 0.6), true)
		mt.position = _mundo(c) + Vector3(0, 0.012, 0)
		_zonas_no.add_child(mt)


## Névoa (0.19): uma "tampa" escura com uma textura de 1 pixel por quadrado e filtro
## linear, para o escuro crescer aos poucos. O que está à vista fica limpo; a partir da
## borda da visão (12 quadrados) fica cada vez mais opaco, até sumir; atrás de paredes
## fica meio apagado. O que já foi visto fica lembrado, meio escurecido.
## A tampa fica a ALTURA_NEVOA acima do chão e deslocada na direção da câmera
## (que olha sempre de (10, 10, 10)), para cobrir cada quadrado e o que está nele.
const ALTURA_NEVOA := 2.0
const NEVOA_RAMPA := 7.0        # quadrados entre a borda da visão e o escuro total
var _nevoa_img: Image
var _nevoa_tex: ImageTexture


func _desenhar_nevoa() -> void:
	var b := batalha
	if not b.nevoa_de_guerra:
		return
	var vis := b.visao_dos_herois()
	var chave := b._visao_chave + "|%d" % b.explorado.size()
	if chave == _nevoa_chave and _nevoa_no != null:
		return
	_nevoa_chave = chave
	var g := b.grade
	if _nevoa_no == null:
		_nevoa_img = Image.create(g.largura, g.altura, false, Image.FORMAT_RGBA8)
		_nevoa_tex = ImageTexture.create_from_image(_nevoa_img)
		var plano := PlaneMesh.new()
		plano.size = Vector2(g.largura, g.altura)
		var mi := MeshInstance3D.new()
		mi.mesh = plano
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_texture = _nevoa_tex
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.render_priority = 10
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var centro := Vector3((g.largura - 1) / 2.0, 0, (g.altura - 1) / 2.0)
		mi.position = centro + Vector3.ONE * ALTURA_NEVOA
		_nevoa_no = mi
		add_child(mi)
	var olhos: Array = b.herois_ativos()
	if olhos.is_empty():
		olhos = b.herois()
	var cor := COR_FUNDO
	for x in g.largura:
		for y in g.altura:
			var p := Vector2i(x, y)
			var a := 0.0
			if not vis.has(p):
				var d := 999
				for h in olhos:
					d = mini(d, Grade.distancia(h.pos, p))
				if d <= Batalha.ALCANCE_VISAO:
					a = 0.62   # perto, mas atrás de parede (ou no escuro)
				else:
					a = clampf(0.45 + 0.55 * float(d - Batalha.ALCANCE_VISAO) / NEVOA_RAMPA, 0.45, 1.0)
				if b.explorado.has(p):
					a = minf(a, 0.55)
			_nevoa_img.set_pixel(x, y, Color(cor.r, cor.g, cor.b, a))
	# (update() não chegava ao desenho no modo de compatibilidade: textura nova a cada mudança)
	_nevoa_tex = ImageTexture.create_from_image(_nevoa_img)
	(_nevoa_no as MeshInstance3D).material_override.albedo_texture = _nevoa_tex


# --- Luz dinâmica (0.19) --------------------------------------------------------
## Nas missões escuras, cada fonte de luz do jogo vira uma luz de verdade: a tocha e a
## lanterna andam com o herói; tochas de parede, fogueiras e chamas tremulam.
var _luzes_no: Node3D
var _luzes := {}          # chave -> OmniLight3D
var _luz_tempo := 0.0


func _cor_da_luz(nome: String) -> Color:
	match nome:
		"lanterna", "lanterna_da_fe", "luz_da_verdade":
			return Color("ffe6b0")
		"fogo-fátuo":
			return Color("8fe6d8")
	return Color("ffa64d")


func _atualizar_luzes() -> void:
	var b := batalha
	if not b.escuro:
		return
	if _luzes_no == null:
		_luzes_no = Node3D.new()
		add_child(_luzes_no)
	var quero := {}   # chave -> [pai, posição local, alcance, cor, tremula]
	for u in b.unidades:
		if not u.viva() or not _pecas.has(u.id):
			continue
		var tipo := ""
		if u.luz != "" and Batalha.LUZES.has(u.luz):
			tipo = u.luz
		elif u.efeitos.has("lanterna_da_fe"):
			tipo = "lanterna_da_fe"
		elif u.fichas_total("Fogo") > 0:
			tipo = "fogo"
		if tipo != "":
			var r: Array = Batalha.LUZES.get(tipo, [4, 4])
			quero["u:" + u.id + ":" + tipo] = [_pecas[u.id], Vector3(0.25, 1.2, 0.2), float(maxi(r[0], r[1])), _cor_da_luz(tipo), tipo != "lanterna"]
	for l in b.luzes:
		if l.get("segue", "") != "" and _pecas.has(l["segue"]):
			quero["l:" + str(l)] = [_pecas[l["segue"]], Vector3(0, 1.3, 0), float(maxi(int(l["claro"]), int(l["penumbra"]))), _cor_da_luz(l.get("nome", "")), false]
		elif l.has("pos"):
			quero["l:" + str(l["pos"])] = [_luzes_no, _mundo(l["pos"]) + Vector3(0, 1.0, 0), float(maxi(int(l["claro"]), int(l["penumbra"]))),
				_cor_da_luz(l.get("nome", "")), l.get("nome", "") != "fogo-fátuo"]
	for p in b.grade.obstaculos:
		var t: String = b.grade.obstaculos[p]
		if t in ["fogueira", "tocha_parede"]:
			quero["o:" + str(p)] = [_luzes_no, _mundo(p) + Vector3(0, 1.3 if t == "tocha_parede" else 0.8, 0), float(Batalha.LUZES[t][1]), _cor_da_luz(t), true]
	for p in b.chamas:
		quero["c:" + str(p)] = [_luzes_no, _mundo(p) + Vector3(0, 0.8, 0), float(Batalha.LUZES["chamas"][1]), _cor_da_luz("fogo"), true]
	for k in _luzes.keys():
		if not quero.has(k) or not is_instance_valid(_luzes[k]):
			if is_instance_valid(_luzes[k]):
				_luzes[k].queue_free()
			_luzes.erase(k)
	for k in quero:
		if _luzes.has(k):
			continue
		var q: Array = quero[k]
		var luz := OmniLight3D.new()
		luz.omni_range = q[2] + 1.5
		luz.omni_attenuation = 1.3
		luz.light_color = q[3]
		luz.light_energy = 1.8
		luz.shadow_enabled = false
		luz.position = q[1]
		luz.set_meta("tremula", q[4])
		luz.set_meta("base", 1.8)
		q[0].add_child(luz)
		_luzes[k] = luz


## Mão em leque (0.21): as cartas se sobrepõem num arco; a carta sob o mouse sobe.
func _arrumar_leque() -> void:
	var cartas := _mao.get_children().filter(func(c): return c is PanelContainer and not c.is_queued_for_deletion())
	var n := cartas.size()
	var largura: float = maxf(_mao.size.x, 420.0)
	var tam := TAM_CARTA_MAO_LEQUE
	var passo: float = minf(tam.x * 0.78, (largura - tam.x) / maxf(n - 1, 1))
	var inicio: float = largura / 2.0 - (passo * (n - 1) + tam.x) / 2.0
	for i in n:
		var cv: Control = cartas[i]
		var meio: float = i - (n - 1) / 2.0
		cv.custom_minimum_size = tam
		cv.size = tam
		cv.pivot_offset = Vector2(tam.x / 2.0, tam.y)
		cv.rotation = deg_to_rad(meio * 5.0)
		cv.position = Vector2(inicio + i * passo, 6 + absf(meio) * absf(meio) * 2.0)
		cv.set_meta("y", cv.position.y)
		cv.z_index = i
		if not cv.has_meta("ligado"):
			cv.set_meta("ligado", true)
			cv.mouse_entered.connect(func():
				cv.z_index = 50
				cv.position.y = float(cv.get_meta("y")) - 16)
			cv.mouse_exited.connect(func():
				cv.z_index = cartas.find(cv)
				cv.position.y = float(cv.get_meta("y")))


func _process(delta: float) -> void:
	_atualizar_menus_flutuantes()
	# WASD / setas (0.20): a câmera desliza enquanto a tecla está apertada.
	if _camera != null and (_pausa == null or not _pausa.visible):
		var dir := Vector2.ZERO
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			dir.y -= 1
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			dir.y += 1
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			dir.x -= 1
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			dir.x += 1
		if dir != Vector2.ZERO:
			var direita := Vector3(1, 0, -1).normalized()
			var cima := Vector3(-1, 0, -1).normalized()
			_camera.position += (direita * dir.x - cima * dir.y) * _camera.size * 0.9 * delta
	if _luzes.is_empty():
		return
	_luz_tempo += delta
	var i := 0
	for k in _luzes:
		var luz = _luzes[k]
		i += 1
		if is_instance_valid(luz) and luz.get_meta("tremula", false):
			luz.light_energy = float(luz.get_meta("base")) * (0.86 + 0.1 * sin(_luz_tempo * 9.0 + i * 1.7) + 0.06 * sin(_luz_tempo * 23.0 + i))


func _marca(plano: PlaneMesh, p: Vector2i, cor: Color, altura := 0.006) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = plano
	mi.material_override = _material(cor, true)
	mi.position = _mundo(p) + Vector3(0, altura, 0)
	_marcas.add_child(mi)


# --- Interface --------------------------------------------------------------

func _label(texto: String, tamanho := 15, cor := COR_TEXTO, negrito := false) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	if negrito:
		l.add_theme_font_override("font", _fonte_negrito)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _caixa(fundo: Color, borda: Color, raio := 10, margem := 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fundo
	sb.border_color = borda
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(raio)
	sb.set_content_margin_all(margem)
	return sb


func _painel(fundo := COR_PAINEL, borda := COR_BORDA, margem := 12) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _caixa(fundo, borda, 10, margem))
	return p


func _botao(texto: String, acao: String, largura := 150) -> Button:
	var bt := Button.new()
	bt.text = texto
	bt.custom_minimum_size = Vector2(largura, 36)
	bt.focus_mode = Control.FOCUS_NONE
	bt.pressed.connect(func(): _acao(acao))
	return bt


func _criar_tema() -> Theme:
	var t := Theme.new()
	t.default_font = _fonte
	t.default_font_size = 15
	t.set_color("font_color", "Label", COR_TEXTO)
	t.set_color("font_color", "CheckBox", COR_TEXTO)
	t.set_color("default_color", "RichTextLabel", COR_TEXTO)
	var normal := _caixa(Color("2a2833"), COR_OURO.darkened(0.3), 6, 8)
	var foco := _caixa(Color("34313f"), COR_OURO, 6, 8)
	var desligado := _caixa(Color("1f1e25"), COR_BORDA, 6, 8)
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
	var vazio := StyleBoxEmpty.new()
	for estado in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		t.set_stylebox(estado, "CheckBox", vazio)
	return t


func _barra(cor: Color, largura: int) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(largura, 12)
	pb.add_theme_stylebox_override("background", _caixa(Color("2a2833"), Color("2a2833"), 4, 0))
	pb.add_theme_stylebox_override("fill", _caixa(cor, cor, 4, 0))
	pb.max_value = 52
	return pb


func _linha_mesa() -> Array:
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 10)
	var titulo := _label("", 12, COR_TEXTO, true)
	titulo.custom_minimum_size = Vector2(120, 0)
	titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	linha.add_child(titulo)
	var monte := MonteVisual.new()
	monte.definir_tamanho(TAM_CARTA_MESA)
	monte.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(monte)
	var cartas := HBoxContainer.new()
	cartas.add_theme_constant_override("separation", 6)
	cartas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cartas.custom_minimum_size = Vector2(0, TAM_CARTA_MESA.y)
	linha.add_child(cartas)
	var total := _label("", 12)
	total.custom_minimum_size = Vector2(110, 0)
	total.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	total.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	linha.add_child(total)
	return [linha, titulo, monte, cartas, total]


func _montar_hud() -> void:
	# Interface 0.21 (pedido do Lucas): tela mais limpa. Fixo na tela só o essencial
	# (topo fino, iniciativa num quadro, barra de baixo baixa com a mão em leque); cartas,
	# ações, itens e registro abrem ao passar o mouse nos botões (clique fixa).
	var camada := CanvasLayer.new()
	add_child(camada)
	_hud = Control.new()
	_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.theme = _criar_tema()
	camada.add_child(_hud)

	# Topo fino
	var topo := _painel(Color(0.07, 0.07, 0.09, 0.82), COR_BORDA, 5)
	topo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	topo.offset_left = 12
	topo.offset_right = -12
	topo.offset_top = 8
	_hud.add_child(topo)
	var h_topo := HBoxContainer.new()
	h_topo.add_theme_constant_override("separation", 14)
	topo.add_child(h_topo)
	_h_topo = h_topo
	_titulo = _label("SISTEMA 21", 15, COR_OURO)
	_titulo.add_theme_font_override("font", load("res://assets/fontes/DejaVuSerif-Bold.ttf"))
	h_topo.add_child(_titulo)
	_rodada = _label("", 13, COR_TEXTO, true)
	h_topo.add_child(_rodada)
	_objetivo = _label("", 12, COR_SECUNDARIO)
	_objetivo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_objetivo.clip_text = true
	h_topo.add_child(_objetivo)
	_bt_reg = _botao_topo("Registro (L)")
	_bt_reg.pressed.connect(func(): _fixar("registro"))
	h_topo.add_child(_bt_reg)
	var bt_menu := _botao_topo("Menu (Esc)")
	bt_menu.pressed.connect(_abrir_pausa)
	h_topo.add_child(bt_menu)

	# Iniciativa (0.21): quadro com a ordem; seta e cor na vez de quem é.
	_painel_ini = _painel(Color(0.07, 0.07, 0.09, 0.82), COR_BORDA, 8)
	_painel_ini.position = Vector2(12, 50)
	_painel_ini.custom_minimum_size = Vector2(172, 0)
	_hud.add_child(_painel_ini)
	var v_ini := VBoxContainer.new()
	v_ini.add_theme_constant_override("separation", 1)
	_painel_ini.add_child(v_ini)
	var t_ini := _label("Iniciativa", 12, COR_OURO, true)
	v_ini.add_child(t_ini)
	_ordem = VBoxContainer.new()
	_ordem.add_theme_constant_override("separation", 0)
	v_ini.add_child(_ordem)

	# Dica (uma ou duas linhas, no alto ao centro)
	var p_dica := _painel(Color(0.07, 0.07, 0.09, 0.78), COR_BORDA, 6)
	p_dica.position = Vector2(200, 50)
	p_dica.custom_minimum_size = Vector2(620, 0)
	p_dica.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(p_dica)
	_dica = _label("", 12, COR_TEXTO)
	_dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dica.custom_minimum_size = Vector2(604, 0)
	p_dica.add_child(_dica)

	# Painel das cartas e do registro (abre pelo botão "Habilidades" ou "Registro").
	_painel_dir = _painel(COR_PAINEL, COR_BORDA, 6)
	_painel_dir.position = Vector2(1280 - 316, 50)
	_painel_dir.custom_minimum_size = Vector2(304, 518)
	_painel_dir.size = Vector2(304, 518)
	_hud.add_child(_painel_dir)
	_abas = TabContainer.new()
	_abas.custom_minimum_size = Vector2(292, 506)
	_painel_dir.add_child(_abas)
	var rolagem := ScrollContainer.new()
	rolagem.name = "Cartas"
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_abas.add_child(rolagem)
	_cartas_lista = VBoxContainer.new()
	_cartas_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cartas_lista.add_theme_constant_override("separation", 8)
	rolagem.add_child(_cartas_lista)
	var v_reg := VBoxContainer.new()
	v_reg.name = "Registro"
	_abas.add_child(v_reg)
	_registro = RichTextLabel.new()
	_registro.bbcode_enabled = true
	_registro.scroll_following = true
	_registro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_registro.add_theme_font_size_override("normal_font_size", 12)
	v_reg.add_child(_registro)
	_painel_dir.visible = false

	# Barra de baixo (mais baixa): herói | ações e mão em leque | botões
	_baixo = _painel(Color(0.08, 0.08, 0.1, 0.92), COR_BORDA, 8)
	_baixo.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_baixo.offset_left = 12
	_baixo.offset_right = -12
	_baixo.offset_top = -150
	_baixo.offset_bottom = -8
	_hud.add_child(_baixo)
	var h_baixo := HBoxContainer.new()
	h_baixo.add_theme_constant_override("separation", 16)
	_baixo.add_child(h_baixo)

	var v_info := VBoxContainer.new()
	v_info.custom_minimum_size = Vector2(270, 0)
	v_info.add_theme_constant_override("separation", 4)
	_her_nome = _label("", 16, COR_TEXTO, true)
	v_info.add_child(_her_nome)
	_her_vida_txt = _label("", 13)
	v_info.add_child(_her_vida_txt)
	_her_vida = HBoxContainer.new()
	_her_vida.add_theme_constant_override("separation", 0)
	_her_vida.custom_minimum_size = Vector2(260, 12)
	for cor in [COR_VIDA_HEROI, Color("8fc98a"), Color("b8443a"), Color("0b0a0e")]:
		var cr := ColorRect.new()
		cr.color = cor
		cr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cr.mouse_filter = Control.MOUSE_FILTER_STOP
		_her_vida.add_child(cr)
	v_info.add_child(_her_vida)
	_her_zonas = _label("", 11, COR_SECUNDARIO)
	v_info.add_child(_her_zonas)
	_her_stats = _label("", 11, Color("9fd3ff"))
	_her_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_her_stats.custom_minimum_size = Vector2(260, 0)
	v_info.add_child(_her_stats)
	_her_maos = _label("", 12, COR_TEXTO)   # (o detalhe das mãos fica na ficha e no inventário)
	h_baixo.add_child(v_info)

	var v_meio := VBoxContainer.new()
	v_meio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v_meio.add_theme_constant_override("separation", 2)
	_acoes = _label("", 12, COR_OURO, true)
	_acoes.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v_meio.add_child(_acoes)
	_mao = Control.new()   # mão em leque (0.21): as cartas se espalham com um pouco de giro
	_mao.custom_minimum_size = Vector2(420, 112)
	_mao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v_meio.add_child(_mao)
	h_baixo.add_child(v_meio)

	var v_bt := VBoxContainer.new()
	v_bt.add_theme_constant_override("separation", 6)
	var h_menus := HBoxContainer.new()
	h_menus.add_theme_constant_override("separation", 6)
	_bt_hab = _botao_menu("Habilidades ▴")
	_bt_hab.pressed.connect(func(): _fixar("cartas"))
	_bt_ac = _botao_menu("Ações ▴")
	_bt_ac.pressed.connect(func(): _fixar("acoes"))
	_bt_ficha = _botao_menu("Ficha (C)")
	_bt_ficha.pressed.connect(_abrir_ficha_do_heroi)
	for bt in [_bt_hab, _bt_ac, _bt_ficha]:
		h_menus.add_child(bt)
	v_bt.add_child(h_menus)
	_bt_encerrar = _botao("Encerrar turno (E)", "encerrar", 300)
	_bt_encerrar.custom_minimum_size = Vector2(300, 42)
	_bt_encerrar.add_theme_font_size_override("font_size", 15)
	v_bt.add_child(_bt_encerrar)
	_itens = HBoxContainer.new()   # botões rápidos: inventário e itens de ação
	_itens.add_theme_constant_override("separation", 6)
	v_bt.add_child(_itens)
	h_baixo.add_child(v_bt)

	# Menu de ações (abre ao passar o mouse em "Ações")
	_painel_acoes = _painel(Color(0.07, 0.07, 0.09, 0.96), COR_OURO.darkened(0.35), 10)
	_painel_acoes.position = Vector2(1280 - 12 - 420, 720 - 150 - 8 - 230)
	_painel_acoes.custom_minimum_size = Vector2(420, 0)
	_hud.add_child(_painel_acoes)
	var grade := GridContainer.new()
	grade.columns = 3
	grade.add_theme_constant_override("h_separation", 6)
	grade.add_theme_constant_override("v_separation", 6)
	_painel_acoes.add_child(grade)
	_bt_concentrar = _botao("Concentrar", "concentrar")
	_bt_concentrar.tooltip_text = "Ação padrão: compra 1 carta do baralho para a mão."
	_bt_folego = _botao("Recuperar fôlego", "folego")
	_bt_folego.tooltip_text = "Ação padrão: cura igual à Constituição. Exila 1 carta do descarte e devolve as outras ao fundo do baralho."
	_bt_planejar = _botao("Planejar", "planejar")
	_bt_planejar.tooltip_text = "Ação padrão: olha as 2 cartas do topo do seu baralho."
	_bt_tratar = _botao("Tratar sangramento", "tratar")
	_bt_tratar.tooltip_text = "Ação padrão: teste de Medicina + Sabedoria em você ou num aliado adjacente."
	_bt_levantar = _botao("Levantar-se", "levantar")
	_bt_levantar.tooltip_text = "Ação de movimento completa: sai de Caído. Provoca ataque de oportunidade."
	_bt_comandar = _botao("Comandar", "comandar")
	_bt_comandar.tooltip_text = "Ação padrão (Espírito 3): um aliado à vista a até 4 quadrados compra 1 carta (2 com Espírito 5)."
	_bt_orientar = _botao("Orientar", "orientar")
	_bt_orientar.tooltip_text = "Ação livre: um aliado à vista a até 4 quadrados ganha 1 ficha de Foco. Usos por cena = Diplomacia."
	_bt_mulligan = _botao("Mulligan", "mulligan")
	_bt_mulligan.tooltip_text = "Sabedoria 5: devolva a mão, embaralhe e compre de novo (uma vez, no começo da cena)."
	_bt_pegar_arma = _botao("Pegar a arma", "pegar_arma")
	_bt_pegar_arma.tooltip_text = "Ação de movimento: pega a arma arremessada."
	_bt_recarregar = _botao("Recarregar", "recarregar")
	_bt_recarregar.tooltip_text = "Ação padrão: recarrega a Besta Pesada."
	_bt_tocha = _botao("Acender tocha", "tocha")
	_bt_tocha.tooltip_text = "Ação padrão e uma mão livre: gasta 1 tocha. Ilumina ao alcance curto e deixa o médio na penumbra."
	_bt_lanterna = _botao("Acender lanterna", "lanterna")
	_bt_lanterna.tooltip_text = "Ação de movimento: a lanterna (presa ao cinto) ilumina ao alcance curto."
	_bt_trocar = _botao("Trocar arma", "trocar_arma")
	_bt_foco = _botao("Usar Foco (scry 1)", "foco")
	_bt_foco.tooltip_text = "Ação livre: descarta 1 ficha de Foco para ver a carta do topo do baralho e escolher se ela fica ou vai para o fundo."
	_bt_correr = _botao("Correr", "correr")
	_bt_correr.tooltip_text = "3 ações de movimento (a de Movimento e as 2 Padrão). Teste de Atletismo + Força:\n2–8 avança 1 e cai · 9–12 velocidade · 13–16 o dobro · 17–21 o triplo · 22+ 4× + Atletismo.\nIgnora impedimento. Até o seu próximo turno, os inimigos têm vantagem para atacá-lo."
	_bt_saltar = _botao("Saltar", "saltar")
	_bt_saltar.tooltip_text = "2 ações de movimento. Teste de Atletismo + Força:\n2–8 avança 1 e cai · 9–12 salta 1 · 13–16, 2 · 17–21, 3 · 22+, 4.\nIgnora impedimento e terreno difícil: é o jeito de escapar de um cerco. O ataque de oportunidade contra você tem vantagem."
	_bt_procurar = _botao("Procurar", "procurar")
	_bt_procurar.tooltip_text = "Ação padrão: Percepção + Investigação para achar armadilhas e coisas escondidas a até 5 casas."
	_bt_levantar_aliado = _botao("Levantar caído", "levantar_aliado")
	_bt_levantar_aliado.tooltip_text = "Ação padrão, ao lado de um aliado caído: Medicina + Sabedoria. Dificuldade de 17 (40+ cartas no descarte) a 25 (menos de 5).\nDá para gastar uma poção ou uma carta que cura: +1 no limite a cada 2 de cura.\nPassou: ele volta com 20% do descarte + a cura usada."
	var extras := [_bt_procurar, _bt_levantar_aliado, _bt_correr, _bt_saltar]
	for tipo in Batalha.MANOBRAS:
		var m: Dictionary = Batalha.MANOBRAS[tipo]
		var btm := _botao(m["nome"], "manobra:" + tipo)
		btm.tooltip_text = "Manobra (ação padrão, inimigo ao lado): Luta + Força contra a Força dele. Se vencer: %s.\nInimigo maior que você: −5 no limite por tamanho." % m["texto"]
		_bts_manobra[tipo] = btm
		extras.append(btm)
	for bt in [_bt_concentrar, _bt_folego, _bt_planejar, _bt_tratar, _bt_levantar, _bt_comandar, _bt_orientar, _bt_mulligan, _bt_pegar_arma, _bt_recarregar, _bt_tocha, _bt_lanterna, _bt_trocar, _bt_foco] + extras:
		bt.custom_minimum_size = Vector2(130, 30)
		bt.add_theme_font_size_override("font_size", 12)
		bt.clip_text = true
		grade.add_child(bt)
	_painel_acoes.visible = false
	_menus_flutuantes = [[_bt_hab, _painel_dir, "cartas"], [_bt_reg, _painel_dir, "registro"], [_bt_ac, _painel_acoes, "acoes"]]

	# Treino (0.22): a etapa do tutorial, à esquerda, embaixo da iniciativa.
	_painel_tut = _painel(Color(0.08, 0.1, 0.07, 0.94), Color("7fae5a"), 10)
	_painel_tut.position = Vector2(8, 170)
	_painel_tut.custom_minimum_size = Vector2(214, 0)
	_hud.add_child(_painel_tut)
	var vt := VBoxContainer.new()
	vt.add_theme_constant_override("separation", 6)
	_painel_tut.add_child(vt)
	var ht := HBoxContainer.new()
	_tut_titulo = _label("", 14, Color("b9e08f"), true)
	_tut_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tut_titulo.custom_minimum_size = Vector2(170, 0)
	_tut_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ht.add_child(_tut_titulo)
	var bt_min := Button.new()
	bt_min.text = "–"
	bt_min.focus_mode = Control.FOCUS_NONE
	bt_min.tooltip_text = "Esconder ou mostrar a explicação"
	bt_min.pressed.connect(func():
		_tut_texto.visible = not _tut_texto.visible
		bt_min.text = "–" if _tut_texto.visible else "+"
		_painel_tut.reset_size())
	ht.add_child(bt_min)
	vt.add_child(ht)
	_tut_texto = _label("", 12, COR_TEXTO)
	_tut_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tut_texto.custom_minimum_size = Vector2(214, 0)
	vt.add_child(_tut_texto)
	_tut_proximo = Button.new()
	_tut_proximo.text = "Próximo"
	_tut_proximo.focus_mode = Control.FOCUS_NONE
	_tut_proximo.pressed.connect(func():
		if batalha.tutorial_proximo():
			_processar())
	vt.add_child(_tut_proximo)
	_painel_tut.visible = false

	# Opções que antes ficavam na tela: agora no Esc → Configurações (os objetos guardam o estado).
	_auto = CheckBox.new()
	_auto.toggled.connect(_ao_mudar_defesa)
	_auto_dist = CheckBox.new()
	_auto_dist.button_pressed = Sessao.distribuir_sugestao
	_auto_dist.toggled.connect(func(on):
		Sessao.distribuir_sugestao = on
		batalha.distribuicao_automatica = on
		if on and batalha.fase == Batalha.Fase.DISTRIBUINDO_DANO:
			var sug := batalha.sugestao_distribuicao()
			batalha.heroi_distribuir_dano(sug["escudo"], sug["armadura"])
		_processar())

	# Planejar (cartas do topo)
	_planejar = _painel(Color(0.07, 0.07, 0.09, 0.92), COR_OURO.darkened(0.3), 10)
	_planejar.position = Vector2(330, 720 - 150 - 130)
	var h_plan := HBoxContainer.new()
	h_plan.add_theme_constant_override("separation", 8)
	_planejar.add_child(h_plan)
	_planejar_titulo = _label("Topo do seu\nbaralho:", 13, COR_OURO, true)
	h_plan.add_child(_planejar_titulo)
	_planejar_cartas = HBoxContainer.new()
	_planejar_cartas.add_theme_constant_override("separation", 6)
	h_plan.add_child(_planejar_cartas)
	_planejar_bts = HBoxContainer.new()
	_planejar_bts.add_theme_constant_override("separation", 6)
	h_plan.add_child(_planejar_bts)
	_hud.add_child(_planejar)

	# Mesa de 21 (0.21: mais baixa e compacta, no lugar da barra de baixo, para ver o mapa)
	_mesa = _painel(Color(COR_MESA.r, COR_MESA.g, COR_MESA.b, 0.93), COR_BORDA_MESA, 6)
	_mesa.position = Vector2(250, 720 - 158 - 222)
	_mesa.custom_minimum_size = Vector2(780, 0)
	_hud.add_child(_mesa)
	var v_mesa := VBoxContainer.new()
	v_mesa.add_theme_constant_override("separation", 2)
	_mesa.add_child(v_mesa)
	var li := _linha_mesa()
	_mesa_ini_titulo = li[1]
	_mesa_ini_monte = li[2]
	_mesa_ini_cartas = li[3]
	_mesa_ini_total = li[4]
	_mesa_ini_monte.dica_padrao = "Baralho compartilhado dos inimigos (não é a vida deles)"
	v_mesa.add_child(li[0])
	_mesa_ini_linha = li[0]
	_mesa_faixa = _label("", 12, COR_OURO, true)
	_mesa_faixa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mesa_faixa.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mesa_faixa.custom_minimum_size = Vector2(0, 18)
	_mesa_faixa.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	v_mesa.add_child(_mesa_faixa)
	_mesa_extras = HBoxContainer.new()
	_mesa_extras.alignment = BoxContainer.ALIGNMENT_CENTER
	_mesa_extras.add_theme_constant_override("separation", 8)
	v_mesa.add_child(_mesa_extras)
	var lh := _linha_mesa()
	_mesa_her_titulo = lh[1]
	_mesa_her_monte = lh[2]
	_mesa_her_cartas = lh[3]
	_mesa_her_total = lh[4]
	_mesa_her_monte.clicado.connect(func(): _acao("puxar"))
	v_mesa.add_child(lh[0])
	var h_bt := HBoxContainer.new()
	h_bt.alignment = BoxContainer.ALIGNMENT_CENTER
	h_bt.add_theme_constant_override("separation", 10)
	_bt_puxar = _botao("Puxar (Espaço)", "puxar", 140)
	_bt_parar = _botao("Parar (Enter)", "parar", 140)
	_bt_continuar = _botao("Continuar (Enter)", "continuar", 140)
	for btm in [_bt_puxar, _bt_parar, _bt_continuar]:
		btm.custom_minimum_size = Vector2(140, 30)
	for bt in [_bt_puxar, _bt_parar, _bt_continuar]:
		h_bt.add_child(bt)
	v_mesa.add_child(h_bt)

	# Fim
	_fim = _painel(Color(0.07, 0.07, 0.09, 0.96), COR_OURO, 24)
	_fim.position = Vector2(370, 200)
	_fim.custom_minimum_size = Vector2(380, 0)
	_hud.add_child(_fim)
	var v_fim := VBoxContainer.new()
	v_fim.alignment = BoxContainer.ALIGNMENT_CENTER
	v_fim.add_theme_constant_override("separation", 14)
	_fim.add_child(v_fim)
	_fim_titulo = _label("", 34, COR_OURO, true)
	_fim_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v_fim.add_child(_fim_titulo)
	_fim_texto = _label("", 14, COR_TEXTO)
	_fim_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fim_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fim_texto.custom_minimum_size = Vector2(330, 0)
	v_fim.add_child(_fim_texto)
	_bt_de_novo = Button.new()
	_bt_de_novo.text = "Jogar de novo (N)"
	_bt_de_novo.custom_minimum_size = Vector2(0, 40)
	_bt_de_novo.focus_mode = Control.FOCUS_NONE
	_bt_de_novo.pressed.connect(func(): nova_batalha())
	v_fim.add_child(_bt_de_novo)
	_bt_volta = Button.new()
	_bt_volta.text = "Voltar ao menu"
	_bt_volta.custom_minimum_size = Vector2(0, 40)
	_bt_volta.focus_mode = Control.FOCUS_NONE
	_bt_volta.pressed.connect(func():
		if Sessao.campanha:
			Sessao.modo = "vila"
			get_tree().change_scene_to_file("res://ui/batalha.tscn")
		else:
			get_tree().change_scene_to_file("res://ui/main.tscn"))
	v_fim.add_child(_bt_volta)
	_fim.visible = false

	_escolha_fadiga = _painel(Color(0.07, 0.07, 0.09, 0.97), COR_OURO, 18)
	_escolha_fadiga.position = Vector2(290, 200)
	_hud.add_child(_escolha_fadiga)
	var v_fad := VBoxContainer.new()
	v_fad.add_theme_constant_override("separation", 8)
	_escolha_fadiga.add_child(v_fad)
	v_fad.add_child(_label("Fim do turno", 16, COR_OURO, true))
	_escolha_fadiga_bts = VBoxContainer.new()
	_escolha_fadiga_bts.add_theme_constant_override("separation", 6)
	v_fad.add_child(_escolha_fadiga_bts)
	var bt_cancela := Button.new()
	bt_cancela.text = "Voltar (Esc)"
	bt_cancela.focus_mode = Control.FOCUS_NONE
	bt_cancela.pressed.connect(func(): _escolha_fadiga.visible = false)
	v_fad.add_child(bt_cancela)
	_escolha_fadiga.visible = false
	_montar_dialogos()

	# Grupo: quadros pequenos dos heróis, à esquerda acima da barra de baixo.
	_grupo_caixa = HBoxContainer.new()
	_grupo_caixa.position = Vector2(12, 720 - 150 - 8 - 44)
	_grupo_caixa.add_theme_constant_override("separation", 6)
	_hud.add_child(_grupo_caixa)

	# Fichas (do herói e do monstro): modal grande, montado ao abrir.
	_ficha_painel = _painel(Color(0.06, 0.06, 0.08, 0.98), COR_OURO, 14)
	_ficha_painel.position = Vector2(140, 46)
	_ficha_painel.custom_minimum_size = Vector2(1000, 600)
	_ficha_painel.size = Vector2(1000, 600)
	_hud.add_child(_ficha_painel)
	_ficha_painel.visible = false


func _botao_topo(texto: String) -> Button:
	var bt := Button.new()
	bt.text = texto
	bt.focus_mode = Control.FOCUS_NONE
	bt.custom_minimum_size = Vector2(0, 24)
	bt.add_theme_font_size_override("font_size", 12)
	return bt


func _botao_menu(texto: String) -> Button:
	var bt := Button.new()
	bt.text = texto
	bt.focus_mode = Control.FOCUS_NONE
	bt.custom_minimum_size = Vector2(96, 32)
	bt.add_theme_font_size_override("font_size", 13)
	return bt


## Menus flutuantes (0.21): abrem com o mouse em cima do botão ou do próprio painel;
## um clique no botão deixa o menu fixo (clique de novo solta).
func _fixar(nome: String) -> void:
	_fixado = "" if _fixado == nome else nome
	if nome == "registro":
		_abas.current_tab = 1
	elif nome == "cartas":
		_abas.current_tab = 0


func _atualizar_menus_flutuantes() -> void:
	if _menus_flutuantes.is_empty():
		return
	var mouse := _hud.get_global_mouse_position()
	var abertos := {}
	for m in _menus_flutuantes:
		var bt: Control = m[0]
		var painel: Control = m[1]
		var sobre_bt: bool = bt.is_visible_in_tree() and bt.get_global_rect().has_point(mouse)
		# 0.23: o painel encosta no botão; botão + painel contam como uma área só.
		var sobre_painel: bool = painel.visible and painel.get_global_rect().merge(bt.get_global_rect()).grow(4).has_point(mouse)
		if _fixado == m[2] or sobre_bt or (sobre_painel and _menu_aberto == m[2]):
			abertos[painel] = m[2]
	# o painel das cartas também fica aberto enquanto se escolhe o alvo de uma carta
	if _modo_carta >= 0 or not _casa_escolha.is_empty() or _modo_area >= 0:
		abertos[_painel_dir] = abertos.get(_painel_dir, "cartas")
	for m in _menus_flutuantes:
		var painel2: Control = m[1]
		var abrir: bool = abertos.has(painel2)
		painel2.visible = abrir and not _mesa.visible and not _ficha_painel.visible
		if abrir and abertos[painel2] == m[2]:
			_menu_aberto = m[2]
			if painel2 == _painel_dir:
				_abas.current_tab = 1 if m[2] == "registro" else 0
			if painel2.visible:
				if painel2 == _painel_acoes:
					painel2.reset_size()
				var r: Rect2 = (m[0] as Control).get_global_rect()
				var x := clampf(r.end.x - painel2.size.x, 4.0, 1276.0 - painel2.size.x)
				painel2.global_position = Vector2(x, r.end.y) if m[2] == "registro" else Vector2(x, r.position.y - painel2.size.y)
	if abertos.is_empty():
		_menu_aberto = ""


## Cor de cada origem (faixa do topo da carta), como nos PDFs: Clérigo dourado, Mago azul...
const CORES_ORIGEM := {"arma": Color("6a5440"), "guerreiro": Color("8a3b2e"), "ladino": Color("3b3456"), "clerigo": Color("8a6a2a"),
	"cacador": Color("3d5a32"), "mago": Color("2d4a7a"), "raca": Color("5a4a3a"), "background": Color("4a4a52"), "item": Color("44505a")}


func _cor_da_carta(c) -> Color:
	if c.tipo == "heroi":
		return Color("6e5520")
	var partes: PackedStringArray = str(c.id).split(".")
	if partes.size() > 1 and partes[0] == "classe":
		return CORES_ORIGEM.get(partes[1], Color("44434c"))
	return CORES_ORIGEM.get(partes[0] if partes.size() > 0 else "", Color("44434c"))


## Uma carta de habilidade desenhada como carta: faixa colorida com o nome e o limite,
## tags, o texto inteiro (a de herói mostra os quatro efeitos), fadiga em bolinhas,
## fichas, e os botões (usar, opções, virar com ação ou com Preparo).
func _carta_ui(op: Dictionary, b) -> Control:
	var c = op["carta"]
	var cor := _cor_da_carta(c)
	var escolhida: bool = op["indice"] == _modo_carta or op["indice"] == _modo_area
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("17161d")
	sb.border_color = COR_OURO if escolhida else cor.lightened(0.25)
	sb.set_border_width_all(2 if escolhida else 1)
	# Brilho por ~3 s quando a carta acabou de disparar um efeito (0.21)
	var dono_b = _heroi_da_carta(c)
	if dono_b != null and Time.get_ticks_msec() - int(_brilhos.get("%s:%d" % [dono_b.id, op["indice"]], -99999)) < 3000:
		sb.border_color = Color("ffe08a")
		sb.set_border_width_all(3)
		sb.shadow_color = Color(1.0, 0.85, 0.4, 0.55)
		sb.shadow_size = 10
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(0)
	p.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	# Faixa do topo: nome + limite de fadiga
	var faixa := PanelContainer.new()
	var sbf := StyleBoxFlat.new()
	sbf.bg_color = cor
	sbf.corner_radius_top_left = 7
	sbf.corner_radius_top_right = 7
	sbf.set_content_margin_all(6)
	faixa.add_theme_stylebox_override("panel", sbf)
	v.add_child(faixa)
	var hf := HBoxContainer.new()
	faixa.add_child(hf)
	var nome := _label(("★ " if c.tipo == "heroi" else "") + c.nome(), 13, Color("f4ecd8"), true)
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nome.custom_minimum_size = Vector2(170, 0)
	hf.add_child(nome)
	if c.limite() > 0:
		var gotas := ""
		for k in c.limite():
			gotas += "●" if k < c.fadiga else "○"
		var fl := _label(gotas, 12, Color("ffb36b"), true)
		fl.tooltip_text = "Fadiga %d de %d" % [c.fadiga, c.limite()]
		fl.mouse_filter = Control.MOUSE_FILTER_STOP
		hf.add_child(fl)
	# Corpo
	var corpo := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		corpo.add_theme_constant_override("margin_" + lado, 7)
	v.add_child(corpo)
	var vc := VBoxContainer.new()
	vc.add_theme_constant_override("separation", 3)
	corpo.add_child(vc)
	var tags: Array = c.lado_ativo().get("tags", [])
	if not tags.is_empty() or b.eh_conjuracao(c):
		var tl := _label(("✦ Conjuração · " if b.eh_conjuracao(c) else "") + " · ".join(PackedStringArray(tags.filter(func(t): return t != "Conjuração"))), 10, COR_SECUNDARIO)
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tl.custom_minimum_size = Vector2(250, 0)
		if b.eh_conjuracao(c):
			tl.tooltip_text = "Conjuração: a fadiga que não couber nesta carta pode ir para outras cartas suas (você escolhe)."
			tl.mouse_filter = Control.MOUSE_FILTER_STOP
		vc.add_child(tl)
	if c.tipo == "heroi":
		var l = c.lado_ativo()
		for par in [["PASSIVA", l.get("passiva", "")], ["ATIVADA", l.get("ativada", "")], ["DESENCADEADA", l.get("desencadeada", "")], ["AO CRITAR 21", l.get("critico", "")]]:
			var t := RichTextLabel.new()
			t.bbcode_enabled = true
			t.fit_content = true
			t.scroll_active = false
			t.custom_minimum_size = Vector2(250, 0)
			t.add_theme_font_size_override("normal_font_size", 11)
			t.add_theme_font_size_override("bold_font_size", 11)
			t.text = "[b][color=#c9a45c]%s[/color][/b] %s" % [par[0], par[1]]
			vc.add_child(t)
	elif c.tipo == "arma" and _heroi_da_carta(c) != null:
		var ta := _label(Itens.descricao_arma(_heroi_da_carta(c).arma), 11, COR_TEXTO)
		ta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ta.custom_minimum_size = Vector2(250, 0)
		vc.add_child(ta)
	else:
		var bruto := str(c.lado_ativo().get("texto", ""))
		if op.has("opcoes") and "•" in bruto:
			bruto = bruto.split("•")[0].replace("REPERTÓRIO:", "").strip_edges() + "\nRepertório: escolha uma opção abaixo."
		var texto := _label(bruto, 11, COR_TEXTO)
		texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		texto.custom_minimum_size = Vector2(250, 0)
		vc.add_child(texto)
	var dono_c = _heroi_da_carta(c)
	var nota_c: String = b.nota_da_carta(dono_c, c) if dono_c != null else ""
	if nota_c != "":
		vc.add_child(_label(nota_c, 11, COR_OURO, true))
	if c.fichas_texto() != "":
		vc.add_child(_label("Fichas: " + c.fichas_texto(), 11, Color("9fd3ff"), true))
	var outro: String = c.lados[1 - c.lado]["nome"] if c.lados.size() > 1 else ""
	if outro != "":
		var verso := _label("Verso: " + outro, 10, COR_SECUNDARIO)
		verso.tooltip_text = str(c.lados[1 - c.lado].get("texto", ""))
		verso.mouse_filter = Control.MOUSE_FILTER_STOP
		vc.add_child(verso)
	# Botões
	if op.has("opcoes"):
		for o in op["opcoes"]:
			var bo := Button.new()
			var acao_o = {"padrao": "Ação", "movimento": "Movimento"}.get(o["acao"], "")
			bo.text = "%s · %d fadiga%s" % [o["nome"], o["custo"], (", " + acao_o) if acao_o != "" else ""]
			bo.focus_mode = Control.FOCUS_NONE
			bo.alignment = HORIZONTAL_ALIGNMENT_LEFT
			bo.add_theme_font_size_override("font_size", 12)
			bo.disabled = _ocupado or not o["pode"]
			bo.tooltip_text = o["motivo"]
			var io: int = op["indice"]
			var id_o: String = o["opcao"]
			bo.pressed.connect(func(): _acao_carta(io, false, id_o))
			vc.add_child(bo)
			var desc := _descricao_opcao(str(c.lado_ativo().get("texto", "")), str(o["nome"]))
			if desc != "":
				var dl := _label(desc, 10, COR_SECUNDARIO)
				dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				dl.custom_minimum_size = Vector2(250, 0)
				vc.add_child(dl)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	vc.add_child(h)
	if op.has("opcoes"):
		pass
	elif op["uso"] == "ativada":
		var bt := Button.new()
		var acao = {"padrao": "Ação", "movimento": "Movimento", "reacao": "Reação"}.get(op["acao"], "livre")
		bt.text = "Usar (%d fadiga, %s)" % [op["custo"], acao]
		bt.focus_mode = Control.FOCUS_NONE
		bt.add_theme_font_size_override("font_size", 12)
		bt.disabled = _ocupado or not op["pode"]
		bt.tooltip_text = op["motivo"]
		var i: int = op["indice"]
		bt.pressed.connect(func(): _acao_carta(i, false))
		h.add_child(bt)
	elif op["uso"] != "sem_programa":
		h.add_child(_label({"passiva": "passiva", "reacao": "reação (o jogo pergunta)", "na_mesa": "usada na mesa de 21", "ao_virar": "efeito ao virar", "fora": "sem efeito na batalha", "fim_turno": "no fim do turno (ao passar)"}.get(op["uso"], ""), 11, COR_OURO))
	else:
		h.add_child(_label("ainda não programada", 11, COR_VIDA_INIMIGO))
	if c.tipo == "arma" and c.lados.size() > 1:
		# Carta de arma (0.21): virar = trocar para a outra arma.
		var u_a = _heroi_da_carta(c)
		var bt_t := Button.new()
		var custo_t: int = b.custo_troca(u_a) if u_a != null else 1
		bt_t.text = "Trocar para %s (%s)" % [c.lados[1 - c.lado]["nome"], "livre" if custo_t == 0 else "%d Padrão" % custo_t]
		bt_t.focus_mode = Control.FOCUS_NONE
		bt_t.add_theme_font_size_override("font_size", 12)
		bt_t.disabled = _ocupado or not op["pode_virar"]
		bt_t.pressed.connect(func(): _acao("trocar_arma"))
		h.add_child(bt_t)
	elif c.lados.size() > 1:
		var vez: bool = b.vez_do_heroi()
		var u = b.ativa()
		var bv := Button.new()
		bv.text = "Virar (ação)"
		bv.focus_mode = Control.FOCUS_NONE
		bv.add_theme_font_size_override("font_size", 12)
		bv.disabled = _ocupado or not vez or u.acoes_padrao <= 0
		bv.tooltip_text = "Gasta a ação Padrão e apaga as fichas voláteis desta carta."
		var j: int = op["indice"]
		bv.pressed.connect(func(): _acao_virar(j, "acao"))
		h.add_child(bv)
		if op["carta"].tem_ficha("Preparo"):
			var bp := Button.new()
			bp.text = "Virar (Preparo)"
			bp.focus_mode = Control.FOCUS_NONE
			bp.add_theme_font_size_override("font_size", 12)
			bp.disabled = _ocupado or not vez
			bp.tooltip_text = "Gasta 1 ficha de Preparo (sem gastar ação) e apaga as fichas voláteis desta carta."
			bp.pressed.connect(func(): _acao_virar(j, "preparo"))
			h.add_child(bp)
	return p


func _acao_virar(indice: int, modo: String) -> void:
	if _ocupado:
		return
	_planejar.visible = false
	batalha.heroi_virar(indice, modo)
	_processar()


func _atualizar_cartas(heroi) -> void:
	for filho in _cartas_lista.get_children():
		filho.queue_free()
	if heroi.cartas.is_empty():
		_cartas_lista.add_child(_label("(nenhuma carta)", 12, COR_SECUNDARIO))
		return
	var b := batalha
	for op in b.opcoes_cartas(heroi):
		_cartas_lista.add_child(_carta_ui(op, b))


func _ao_mudar_defesa(ligado: bool) -> void:
	batalha.defesa_automatica = ligado
	_processar()


# --- Interações, distribuição do dano e inventário (0.6) ---------------------

func _montar_dialogos() -> void:
	# Diálogo de interação: opções e resultado.
	_dialogo = _painel(Color(0.07, 0.07, 0.09, 0.97), COR_OURO, 18)
	_dialogo.position = Vector2(150, 70)
	_dialogo.custom_minimum_size = Vector2(660, 0)
	_hud.add_child(_dialogo)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	_dialogo.add_child(v)
	_dialogo_titulo = _label("", 17, COR_OURO, true)
	v.add_child(_dialogo_titulo)
	_dialogo_texto = _label("", 14)
	_dialogo_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogo_texto.custom_minimum_size = Vector2(620, 0)
	v.add_child(_dialogo_texto)
	_dialogo_corpo = VBoxContainer.new()
	_dialogo_corpo.add_theme_constant_override("separation", 8)
	v.add_child(_dialogo_corpo)
	_dialogo.visible = false

	# Distribuição do dano.
	_distribuir = _painel(Color(0.08, 0.06, 0.07, 0.97), COR_VIDA_INIMIGO, 16)
	_distribuir.position = Vector2(200, 64)
	_distribuir.custom_minimum_size = Vector2(560, 0)
	_hud.add_child(_distribuir)
	var vd := VBoxContainer.new()
	vd.add_theme_constant_override("separation", 8)
	_distribuir.add_child(vd)
	_dist_titulo = _label("", 17, Color("f0a090"), true)
	_dist_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dist_titulo.custom_minimum_size = Vector2(520, 0)
	vd.add_child(_dist_titulo)
	_dist_linhas = VBoxContainer.new()
	_dist_linhas.add_theme_constant_override("separation", 6)
	vd.add_child(_dist_linhas)
	_distribuir.visible = false

	# Inventário.
	_inventario = _painel(Color(0.07, 0.07, 0.09, 0.97), COR_OURO.darkened(0.2), 14)
	_inventario.position = Vector2(150, 62)
	_inventario.custom_minimum_size = Vector2(660, 440)
	_hud.add_child(_inventario)
	var vi := VBoxContainer.new()
	vi.add_theme_constant_override("separation", 8)
	_inventario.add_child(vi)
	var cab := HBoxContainer.new()
	cab.add_child(_label("Inventário", 17, COR_OURO, true))
	var esp := Control.new()
	esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(esp)
	var fechar := Button.new()
	fechar.text = "Fechar (I)"
	fechar.focus_mode = Control.FOCUS_NONE
	fechar.pressed.connect(_alternar_inventario)
	cab.add_child(fechar)
	vi.add_child(cab)
	var rol := ScrollContainer.new()
	rol.custom_minimum_size = Vector2(630, 390)
	rol.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vi.add_child(rol)
	_inventario_lista = VBoxContainer.new()
	_inventario_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inventario_lista.add_theme_constant_override("separation", 4)
	rol.add_child(_inventario_lista)
	_inventario.visible = false


func _atualizar_dialogos() -> void:
	var b := batalha
	# Perguntas da batalha (Sombra contra o alvo, ação de vários turnos)
	if b.fase == Batalha.Fase.SOMBRA_ESCOLHA and not _ocupado:
		_dialogo_interacao = ""
		_mostrar_pergunta("Ficha de Sombra", b.texto_sombra(), [
			["Gastar 1 Sombra", func(): b.heroi_sombra(true)],
			["Não gastar", func(): b.heroi_sombra(false)]])
	elif b.fase == Batalha.Fase.PERGUNTA and not _ocupado:
		_dialogo_interacao = ""
		var botoes := []
		for o in b.pergunta.get("opcoes", []):
			var id: String = o[0]
			botoes.append([o[1], func(): b.heroi_responder(id)])
		_mostrar_pergunta("Decisão", b.pergunta.get("texto", ""), botoes)
	elif b.fase == Batalha.Fase.ACAO_LONGA and not _ocupado:
		_dialogo_interacao = ""
		_mostrar_pergunta("Ação demorada", b.texto_acao_longa(), [
			["Continuar a ação", func(): b.heroi_acao_longa(true)],
			["Parar e fazer outra coisa", func(): b.heroi_acao_longa(false)]])
	# Resultado de interação
	elif b.fase == Batalha.Fase.INTERACAO_RESOLVIDA and not _ocupado:
		_dialogo_interacao = ""
		if b.interacao(str(b.interacao_atual.get("id", ""))).get("descanso", false):
			_oferecer_salvar = true
		_mostrar_resultado_interacao()
	elif _dialogo_interacao != "":
		if not b.vez_do_heroi() or b.interacao(_dialogo_interacao).is_empty() or not b.interacao(_dialogo_interacao).get("ativa", true):
			_fechar_dialogo()
		elif not _ocupado:
			_abrir_dialogo(_dialogo_interacao)
	else:
		_dialogo.visible = false
	if not _ocupado and b.fase == Batalha.Fase.HEROI_ESCOLHE and not _dialogo.visible:
		_perguntar_ficha_pendente()
	if _oferecer_salvar and not _ocupado and b.fase == Batalha.Fase.HEROI_ESCOLHE and b.motivo_salvar() == "":
		_oferecer_salvar = false
		_abrir_saves_da_missao()
	# Distribuição
	var distribuindo := b.fase == Batalha.Fase.DISTRIBUINDO_DANO and not _ocupado
	if distribuindo and not _dist_mostrando:
		var sug := b.sugestao_distribuicao()
		_dist = {"escudo": sug["escudo"], "armadura": sug["armadura"]}
	_dist_mostrando = distribuindo
	_distribuir.visible = distribuindo
	if distribuindo:
		_montar_distribuicao()


func _texto_custo(custo: Dictionary) -> String:
	if custo.get("turno", false):
		return "o turno inteiro"
	if custo.has("movimento"):
		return "%d ações de movimento" % int(custo["movimento"]) if int(custo["movimento"]) > 1 else "1 ação de movimento"
	if custo.has("padrao"):
		return "%d ação Padrão" % int(custo["padrao"])
	return "sem custo"


func _abrir_dialogo(id: String) -> void:
	var b := batalha
	var it := b.interacao(id)
	var u := b.ativa()
	_dialogo_interacao = id
	_modo_carta = -1
	_inventario.visible = false
	_planejar.visible = false
	_dialogo_titulo.text = it["nome"]
	_dialogo_texto.text = it["texto"] + "\nO que você faz?"
	for f in _dialogo_corpo.get_children():
		_dialogo_corpo.remove_child(f)
		f.queue_free()
	for op in b.opcoes_visiveis(it):
		if op.has("abordagens"):
			_dialogo_corpo.add_child(_caixa_abordagens(it, op))
			continue
		var motivo := b.motivo_sem_opcao(u, it, op)
		var caixa := VBoxContainer.new()
		caixa.add_theme_constant_override("separation", 2)
		var bt := Button.new()
		bt.text = "%s   ·   %s" % [op["texto"], _texto_custo(op.get("custo", {}))]
		bt.alignment = HORIZONTAL_ALIGNMENT_LEFT
		bt.focus_mode = Control.FOCUS_NONE
		bt.custom_minimum_size = Vector2(620, 34)
		bt.disabled = motivo != "" or _ocupado
		var op_id: String = op["id"]
		bt.pressed.connect(func(): _escolher_opcao(id, op_id))
		caixa.add_child(bt)
		var detalhes := PackedStringArray()
		if op.has("teste"):
			detalhes.append("Teste: " + b.descricao_do_teste(u, op))
			if not op.has("dificuldade"):
				detalhes.append("Faixas: " + b.descricao_das_faixas(op))
		else:
			detalhes.append("Sem teste.")
		if op.has("consome"):
			detalhes.append("Gasta: %s (você tem %d)." % [b._nome_item(op["consome"]), u.quantidade(op["consome"])])
		if op.has("requer"):
			detalhes.append("Usa: %s." % b._nome_item(op["requer"]))
		if motivo != "":
			detalhes.append("Indisponível: %s." % motivo)
		var l := _label("\n".join(detalhes), 12, COR_SECUNDARIO if motivo == "" else Color("b07a6e"))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(610, 0)
		caixa.add_child(l)
		_dialogo_corpo.add_child(caixa)
	var cancelar := Button.new()
	cancelar.text = "Cancelar (Esc)"
	cancelar.focus_mode = Control.FOCUS_NONE
	cancelar.custom_minimum_size = Vector2(200, 34)
	cancelar.pressed.connect(func():
		_fechar_dialogo()
		_atualizar())
	_dialogo_corpo.add_child(cancelar)
	_dialogo.visible = true
	_dialogo.reset_size()


## Uma ação que pode ser feita de vários jeitos: um botão por abordagem.
func _caixa_abordagens(it: Dictionary, op: Dictionary) -> Control:
	var b := batalha
	var u := b.ativa()
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 3)
	var motivo_base := b.motivo_sem_opcao(u, it, op)
	caixa.add_child(_label("%s   ·   %s%s" % [op["texto"], _texto_custo(op.get("custo", {})),
		("   ·   indisponível: " + motivo_base) if motivo_base != "" else ""], 14, COR_TEXTO, true))
	caixa.add_child(_label("Escolha como tentar (cada jeito tem a sua dificuldade e pode descobrir coisas diferentes):", 12, COR_SECUNDARIO))
	for ab in op["abordagens"]:
		var ef := b.opcao_com_abordagem(op, ab["id"])
		var motivo := b.motivo_sem_opcao(u, it, ef)
		var bt := Button.new()
		bt.text = "%s   —   %s" % [ab.get("texto", ab["id"]), b.descricao_do_teste(u, ef)]
		bt.alignment = HORIZONTAL_ALIGNMENT_LEFT
		bt.focus_mode = Control.FOCUS_NONE
		bt.custom_minimum_size = Vector2(620, 32)
		bt.disabled = motivo != "" or _ocupado
		if not ef.has("dificuldade"):
			bt.tooltip_text = "Faixas: " + b.descricao_das_faixas(ef)
		if motivo != "":
			bt.tooltip_text = "Indisponível: " + motivo
		var op_id: String = op["id"]
		var ab_id: String = ab["id"]
		var id: String = it["id"]
		bt.pressed.connect(func(): _escolher_opcao(id, op_id, ab_id))
		caixa.add_child(bt)
	return caixa


func _mostrar_pergunta(titulo: String, texto: String, botoes: Array) -> void:
	_dialogo_titulo.text = titulo
	_dialogo_texto.text = texto
	for f in _dialogo_corpo.get_children():
		_dialogo_corpo.remove_child(f)
		f.queue_free()
	for par in botoes:
		var bt := Button.new()
		bt.text = par[0]
		bt.focus_mode = Control.FOCUS_NONE
		bt.custom_minimum_size = Vector2(620, 36)
		var f: Callable = par[1]
		bt.pressed.connect(func():
			if _ocupado:
				return
			_dialogo.visible = false
			f.call()
			_processar())
		_dialogo_corpo.add_child(bt)
	_dialogo.visible = true
	_dialogo.reset_size()


func _fechar_dialogo() -> void:
	_dialogo_interacao = ""
	_dialogo.visible = false


func _escolher_opcao(id: String, opcao: String, abordagem := "") -> void:
	if _ocupado:
		return
	_fechar_dialogo()
	batalha.heroi_interagir(id, opcao, abordagem)
	_processar()


func _mostrar_resultado_interacao() -> void:
	var r := batalha.resultado_interacao
	_dialogo_titulo.text = r.get("titulo", "")
	var linhas := PackedStringArray()
	if int(r.get("valor", -1)) >= 0:
		linhas.append("Teste: %d → %s%s" % [r["valor"], r.get("rotulo", ""), "  (21 natural!)" if r.get("critico", false) else ""])
	var t := batalha.teste_pericia
	if int(r.get("valor", -1)) >= 0 and t != null:
		var nomes := PackedStringArray()
		for c in t.cartas:
			nomes.append(Carta.nome(c))
		if t.estourou:
			linhas.append("Cartas: %s — estourou; vale a última (%s) + %d (%s)." % [" ".join(nomes), Carta.nome(t.carta_do_estouro) if t.carta_do_estouro >= 0 else "—", t.modificador, _nome_atributo_interacao()])
		else:
			linhas.append("Cartas: %s (%d) + %d (%s)." % [" ".join(nomes), t.soma_cartas(), t.modificador, _nome_atributo_interacao()])
	linhas.append(r.get("texto", ""))
	_dialogo_texto.text = "\n\n".join(linhas)
	for f in _dialogo_corpo.get_children():
		_dialogo_corpo.remove_child(f)
		f.queue_free()
	for e in r.get("efeitos", []):
		var l := _label("• " + e, 14, COR_OURO)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(610, 0)
		_dialogo_corpo.add_child(l)
	var n := batalha.queda_pendente()
	if n > 0:
		var u := batalha.ativa()
		var op := batalha.opcao_de_amortecer(n)
		var bt_tenta := Button.new()
		bt_tenta.text = "Tentar amortecer: %s (precisa de %d ou mais)" % [batalha.descricao_do_teste(u, op), op["dificuldade"]]
		bt_tenta.focus_mode = Control.FOCUS_NONE
		bt_tenta.custom_minimum_size = Vector2(620, 36)
		bt_tenta.pressed.connect(func():
			batalha.heroi_amortecer_queda(true)
			_processar())
		_dialogo_corpo.add_child(bt_tenta)
		var bt_cai := Button.new()
		bt_cai.text = "Cair sem testar: %d de dano (Enter)" % Batalha.dano_de_queda(n)
		bt_cai.focus_mode = Control.FOCUS_NONE
		bt_cai.custom_minimum_size = Vector2(620, 36)
		bt_cai.pressed.connect(func(): _acao("continuar"))
		_dialogo_corpo.add_child(bt_cai)
	else:
		for o in r.get("refazer", []) if r.get("pendente", false) else []:
			var br := Button.new()
			br.text = "Refazer o teste: " + o["texto"]
			br.focus_mode = Control.FOCUS_NONE
			br.custom_minimum_size = Vector2(620, 36)
			var slug: String = o["slug"]
			br.pressed.connect(func(): _acao("refazer", slug))
			_dialogo_corpo.add_child(br)
		var bt := Button.new()
		bt.text = "Aceitar o resultado (Enter)" if r.get("pendente", false) else "Continuar (Enter)"
		bt.focus_mode = Control.FOCUS_NONE
		bt.custom_minimum_size = Vector2(200, 36)
		bt.pressed.connect(func(): _acao("continuar"))
		_dialogo_corpo.add_child(bt)
	_dialogo.visible = true
	_dialogo.reset_size()


## A mesa de 21 num teste de atributo: só a linha do herói, com as faixas.
func _atualizar_mesa_pericia() -> void:
	var b := batalha
	var u := b.ativa()
	var op := b.opcao_atual()
	var t := b.teste_pericia
	_mesa.visible = true
	_mesa_ini_linha.visible = false
	var tst: Dictionary = op.get("teste", {})
	_mesa_her_titulo.text = "%s\n%s%s" % [u.nome, tst.get("pericia", "Teste"),
		(" · limite %d" % t.limite) if t.limite != 21 else ""]
	_desenhar_linha(_mesa_her_cartas, t, "heroi", false)
	var nome_at: String = b.nome_do_modificador(op)
	if t.estourou:
		_mesa_her_total.text = "ESTOUROU!\núltima carta + %d (%s) = %d\n→ %s" % [t.modificador, nome_at, t.resultado(), _rotulo_faixa(op, t.resultado())]
	else:
		_mesa_her_total.text = "Cartas %d / %d\n+ %d (%s) = %d\n→ %s" % [t.soma_cartas(), t.limite, t.modificador, nome_at, t.resultado(), _rotulo_faixa(op, t.resultado())]
	var pode_puxar := not _ocupado and t.pode_puxar()
	_mesa_her_monte.configurar(u.baralho.baralho.size(), pode_puxar)
	_bt_puxar.disabled = not pode_puxar
	_bt_parar.disabled = _ocupado or t.encerrado
	_bt_continuar.disabled = true
	var instr := "Puxe (Espaço ou clique no baralho), jogue da mão ou pare (Enter). Perícia e atributo não contam para estourar."
	if b.vantagem_pendente():
		instr = "Vantagem: clique numa carta da mão para trocar pela carta usada que mais ajuda, ou confirme (Enter)."
	var alvo_txt := ("Dificuldade %d (atingir já basta)" % int(op["dificuldade"])) if op.has("dificuldade") else "Faixas: " + b.descricao_das_faixas(op)
	_mesa_faixa.text = "%s · %s\n%s" % [op.get("texto", ""), alvo_txt, instr]
	for filho in _mesa_extras.get_children():
		filho.queue_free()
	if b.vantagem_pendente() and not _ocupado:
		var bt := Button.new()
		bt.text = "Confirmar sem trocar (Enter)"
		bt.focus_mode = Control.FOCUS_NONE
		bt.pressed.connect(func(): _acao("confirmar_vantagem"))
		_mesa_extras.add_child(bt)
	_botoes_carta_fechada()
	_mesa_extras.visible = _mesa_extras.get_child_count() > 0


## Ficha de Foco entre a carta aberta e a fechada (0.20).
func _botoes_carta_fechada() -> void:
	var b := batalha
	if _ocupado or b.teste_do_heroi() == null or not b.teste_do_heroi().fechada_pendente:
		return
	if b.foco_no_teste_disponivel():
		var bt_f := Button.new()
		bt_f.text = "Usar Foco: ver a próxima carta antes da fechada (scry 1)"
		bt_f.focus_mode = Control.FOCUS_NONE
		bt_f.pressed.connect(func():
			batalha.heroi_foco_no_teste()
			_processar())
		_mesa_extras.add_child(bt_f)
	var bt_r := Button.new()
	bt_r.text = "Receber a carta fechada"
	bt_r.focus_mode = Control.FOCUS_NONE
	bt_r.pressed.connect(func():
		batalha.heroi_receber_fechada()
		_processar())
	_mesa_extras.add_child(bt_r)


func _nome_atributo_interacao() -> String:
	var b := batalha
	if b.fase == Batalha.Fase.INTERACAO_RESOLVIDA and b.resultado_interacao.has("atributo"):
		return b.resultado_interacao["atributo"]
	return b.nome_do_modificador(b.opcao_atual())


func _rotulo_faixa(op: Dictionary, valor: int) -> String:
	if not op.has("faixas"):
		return ""
	var rid := batalha._faixa(op, valor)
	return op["resultados"][rid].get("rotulo", rid)


# --- Distribuição do dano -----------------------------------------------------

func _montar_distribuicao() -> void:
	var b := batalha
	var u := b.unidade(b.dano_pendente["id"])
	var d: int = b.dano_pendente["dano"]
	var lim := b.limites_distribuicao()
	_dist["escudo"] = clampi(_dist["escudo"], 0, lim["escudo"])
	_dist["armadura"] = clampi(_dist["armadura"], 0, mini(lim["armadura"], d - _dist["escudo"]))
	var vida: int = d - _dist["escudo"] - _dist["armadura"]
	var origem := "do ataque" if b.dano_pendente["origem"] == "ataque" else "do acidente"
	_dist_titulo.text = "%s sofre %d de dano %s. Distribua entre escudo, armadura e baralho:" % [u.nome, d, origem]
	for f in _dist_linhas.get_children():
		_dist_linhas.remove_child(f)
		f.queue_free()
	if int(u.escudo.get("vida", 0)) > 0:
		_dist_linhas.add_child(_linha_dist("escudo", "Escudo", "vida %d/%d → %d" % [u.vida_escudo, int(u.escudo["vida"]), u.vida_escudo - _dist["escudo"]],
			lim["escudo"], d))
	if int(u.armadura.get("vida", 0)) > 0:
		var resto_arm: int = u.vida_armadura - _dist["armadura"]
		var nota := ""
		if b._cota_disponivel(u) and u.vida_armadura > 0:
			nota = " · Cota de Malha: 1 vez por cena aguenta tudo e fica com 1"
			if _dist["armadura"] >= u.vida_armadura:
				resto_arm = 1
		_dist_linhas.add_child(_linha_dist("armadura", u.armadura["nome"], "vida %d/%d → %d%s" % [u.vida_armadura, int(u.armadura["vida"]), resto_arm, nota],
			lim["armadura"], d))
	var cartas := u.baralho.baralho.size()
	var l_vida := _label("Baralho (vida): %d carta(s) trituradas → restam %d%s" % [vida, maxi(cartas - vida, 0),
		"  ·  VOCÊ CAI!" if vida >= cartas else ""], 15, Color("f0a090") if vida >= cartas else COR_TEXTO, true)
	_dist_linhas.add_child(l_vida)
	var dica := _label("Escudo e armadura protegem o baralho, mas quebrados deixam de dar resistência (e a armadura deixa de exilar cartas no fim do turno).", 12, COR_SECUNDARIO)
	dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dica.custom_minimum_size = Vector2(520, 0)
	_dist_linhas.add_child(dica)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	for par in [["Tudo no baralho", "baralho"], ["Sugestão: escudo → armadura", "sugestao"], ["Confirmar (Enter)", "confirmar"]]:
		var bt := Button.new()
		bt.text = par[0]
		bt.focus_mode = Control.FOCUS_NONE
		var acao: String = par[1]
		bt.pressed.connect(func(): _botao_distribuicao(acao))
		h.add_child(bt)
	_dist_linhas.add_child(h)
	_distribuir.reset_size()


func _linha_dist(chave: String, nome: String, info: String, maximo: int, total: int) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var l := _label(nome, 15, COR_TEXTO, true)
	l.custom_minimum_size = Vector2(130, 0)
	h.add_child(l)
	var menos := Button.new()
	menos.text = "−"
	menos.custom_minimum_size = Vector2(34, 30)
	menos.focus_mode = Control.FOCUS_NONE
	menos.disabled = _dist[chave] <= 0
	menos.pressed.connect(func():
		_dist[chave] -= 1
		_montar_distribuicao())
	h.add_child(menos)
	var v := _label(str(_dist[chave]), 18, COR_OURO, true)
	v.custom_minimum_size = Vector2(30, 0)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_child(v)
	var mais := Button.new()
	mais.text = "+"
	mais.custom_minimum_size = Vector2(34, 30)
	mais.focus_mode = Control.FOCUS_NONE
	mais.disabled = _dist[chave] >= maximo or _dist["escudo"] + _dist["armadura"] >= total
	mais.pressed.connect(func():
		_dist[chave] += 1
		_montar_distribuicao())
	h.add_child(mais)
	h.add_child(_label(info, 12, COR_SECUNDARIO))
	return h


func _botao_distribuicao(acao: String) -> void:
	match acao:
		"baralho":
			_dist = {"escudo": 0, "armadura": 0}
			_montar_distribuicao()
		"sugestao":
			var s := batalha.sugestao_distribuicao()
			_dist = {"escudo": s["escudo"], "armadura": s["armadura"]}
			_montar_distribuicao()
		"confirmar":
			_confirmar_distribuicao()


func _confirmar_distribuicao() -> void:
	if _ocupado or batalha.fase != Batalha.Fase.DISTRIBUINDO_DANO:
		return
	if batalha.heroi_distribuir_dano(_dist["escudo"], _dist["armadura"]):
		_dist_mostrando = false
		_distribuir.visible = false
		_processar()


# --- Inventário -------------------------------------------------------------------

func _alternar_inventario() -> void:
	_inventario.visible = not _inventario.visible
	if _inventario.visible:
		_fechar_dialogo()
		_montar_inventario()


func _item_usavel(u, item: String) -> bool:
	var dados: Dictionary = Itens.CONSUMIVEIS.get(item, {})
	if _ocupado or not batalha.vez_do_heroi() or batalha.ativa() != u or u.acoes_padrao <= 0 or not dados.get("acao", false):
		return false
	if item == "pocao_de_cura_pequena" and u.baralho.descarte.is_empty():
		return false
	return true


func _montar_inventario() -> void:
	var u = _heroi_foco()
	for f in _inventario_lista.get_children():
		_inventario_lista.remove_child(f)
		f.queue_free()
	# O personagem e o que está em cada mão (0.21); muda quando ele troca de arma.
	var topo_inv := HBoxContainer.new()
	topo_inv.add_theme_constant_override("separation", 14)
	_inventario_lista.add_child(topo_inv)
	topo_inv.add_child(_retrato_3d(u))
	var v_maos := VBoxContainer.new()
	v_maos.add_theme_constant_override("separation", 4)
	topo_inv.add_child(v_maos)
	v_maos.add_child(_label(u.nome, 15, COR_OURO, true))
	var maos: Array = batalha.maos_de(u)
	for par in [["Mão principal", maos[0]], ["Outra mão", maos[1]],
			["Cinto", "lanterna acesa" if u.luz == "lanterna" else ("lanterna" if "lanterna" in u.equipamentos else "—")],
			["Guardada", u.arma_reserva.get("nome", "—") if not u.arma_reserva.is_empty() else "—"]]:
		var linha := HBoxContainer.new()
		var r := _label(par[0] + ":", 12, COR_SECUNDARIO)
		r.custom_minimum_size = Vector2(110, 0)
		linha.add_child(r)
		linha.add_child(_label(par[1] if par[1] != "" else "livre", 12, COR_TEXTO, true))
		v_maos.add_child(linha)
	if not u.arma_reserva.is_empty():
		var bt_t := Button.new()
		var ct: int = batalha.custo_troca(u)
		bt_t.text = "Trocar para %s (%s)" % [u.arma_reserva["nome"], "livre" if ct == 0 else "%d Padrão" % ct]
		bt_t.focus_mode = Control.FOCUS_NONE
		bt_t.disabled = _ocupado or not batalha.vez_do_heroi() or batalha.ativa() != u or batalha.motivo_troca(u) != ""
		bt_t.pressed.connect(func():
			_acao("trocar_arma")
			_montar_inventario())
		v_maos.add_child(bt_t)
	_inventario_lista.add_child(_label("Equipado", 14, COR_OURO, true))
	_inventario_lista.add_child(_linha_inv("%s · dano %d + %s" % [u.arma["nome"], u.dano, "Destreza" if Itens.atributo_da_arma(u.arma) == "destreza" else "Força"], "Arma.", ""))
	if int(u.armadura.get("vida", 0)) > 0:
		_inventario_lista.add_child(_linha_inv("%s · vida %d/%d · resistência %d" % [u.armadura["nome"], u.vida_armadura, int(u.armadura["vida"]), int(u.armadura["resistencia"])],
			"Armadura %s. Em testes de movimento (nadar, escalar, saltar), limite %s." % [{"leve": "leve", "media": "média", "pesada": "pesada"}.get(u.armadura["classe"], ""), {"media": "19", "pesada": "17"}.get(u.armadura["classe"], "21")], ""))
	if int(u.escudo.get("vida", 0)) > 0:
		_inventario_lista.add_child(_linha_inv("%s · vida %d/%d · resistência %d" % [u.escudo["nome"], u.vida_escudo, int(u.escudo["vida"]), int(u.escudo["resistencia"])], "Escudo.", ""))
	_inventario_lista.add_child(_label("Consumíveis", 14, COR_OURO, true))
	var vistos := []
	for item in u.consumiveis:
		if item in vistos:
			continue
		vistos.append(item)
		var dados: Dictionary = Itens.CONSUMIVEIS.get(item, {})
		var uso: String = dados.get("uso", "")
		if not dados.get("programado", false):
			uso = "Ainda sem efeito no jogo."
		_inventario_lista.add_child(_linha_inv("%s ×%d" % [dados.get("nome", item), u.quantidade(item)], dados.get("texto", "") + ("\n" + uso if uso != "" else ""),
			item if dados.get("acao", false) else ""))
	if vistos.is_empty():
		_inventario_lista.add_child(_label("(nenhum)", 12, COR_SECUNDARIO))
	_inventario_lista.add_child(_label("Kit de aventura e itens permanentes", 14, COR_OURO, true))
	for item in u.equipamentos:
		var dados: Dictionary = Itens.NAO_CONSUMIVEIS.get(item, {})
		var uso: String = dados.get("uso", "") if dados.get("programado", false) else "Ainda sem efeito no jogo."
		_inventario_lista.add_child(_linha_inv(dados.get("nome", item), dados.get("texto", "") + "\n" + uso, ""))


## Retrato 3D do herói (modelo girando devagar) para o inventário (0.21).
func _retrato_3d(u) -> Control:
	var caixa := SubViewportContainer.new()
	caixa.custom_minimum_size = Vector2(170, 200)
	caixa.stretch = true
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.size = Vector2i(170, 200)
	caixa.add_child(vp)
	var m := Modelos.criar(u.tipo)
	if m == null:
		return caixa
	vp.add_child(m)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 1.7
	cam.position = Vector3(0, 0.7, 3)
	vp.add_child(cam)
	cam.look_at(Vector3(0, 0.62, 0), Vector3.UP)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-40, 30, 0)
	vp.add_child(luz)
	var amb := WorldEnvironment.new()
	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("9a9cb0")
	env.ambient_light_energy = 0.7
	amb.environment = env
	vp.add_child(amb)
	var tw := m.create_tween().set_loops()
	tw.tween_property(m, "rotation:y", TAU, 9.0).from(0.0)
	return caixa


func _linha_inv(titulo: String, texto: String, item_usar: String) -> Control:
	var p := _painel(Color("201f27"), COR_BORDA, 8)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	p.add_child(h)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(_label(titulo, 13, COR_TEXTO, true))
	var l := _label(texto, 11, COR_SECUNDARIO)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(480, 0)
	v.add_child(l)
	h.add_child(v)
	if item_usar != "":
		var bt := Button.new()
		bt.text = "Usar (1 ação)"
		bt.focus_mode = Control.FOCUS_NONE
		bt.disabled = not _item_usavel(_heroi_foco(), item_usar)
		bt.pressed.connect(func(): _usar_item(item_usar))
		h.add_child(bt)
	return p



# --- Grupo e câmera (0.8) -------------------------------------------------------

func _atualizar_grupo() -> void:
	var b := batalha
	for f in _grupo_caixa.get_children():
		_grupo_caixa.remove_child(f)
		f.queue_free()
	if b.herois().size() <= 1:
		return
	var ativa := b.ativa()
	for h in b.herois():
		var vez: bool = ativa == h
		var p := _painel(Color("2a2833") if h.id != _heroi_visto else Color("3a3446"), COR_OURO if vez else COR_BORDA, 6)
		p.custom_minimum_size = Vector2(190, 0)
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		p.tooltip_text = "Clique para ver as cartas e o inventário deste herói."
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		p.add_child(v)
		v.add_child(_label("%s%s · %s" % ["▶ " if vez else "", h.nome, h.classe], 12, COR_OURO if vez else COR_TEXTO, true))
		var linha := "%d/52%s%s%s" % [h.baralho.baralho.size(),
			("  ·  Arm %d" % h.vida_armadura) if int(h.armadura.get("vida", 0)) > 0 else "",
			("  ·  Esc %d" % h.vida_escudo) if int(h.escudo.get("vida", 0)) > 0 else "",
			"  ·  CAÍDO" if not h.viva() else ""]
		v.add_child(_label(linha, 11, COR_SECUNDARIO if h.viva() else COR_VIDA_INIMIGO))
		var id: String = h.id
		p.gui_input.connect(func(e):
			var mb := e as InputEventMouseButton
			if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				_heroi_visto = id
				_atualizar())
		_grupo_caixa.add_child(p)


## Mapas grandes: a câmera vai até a unidade da vez.
func _seguir_camera() -> void:
	var b := batalha
	if _camera == null or not _camera_segue or b.ativa() == null:
		return
	var a := b.ativa()
	if a.id == _ultimo_ativo:
		return
	_ultimo_ativo = a.id
	# Lucas (0.20): a câmera só vai até o inimigo se os heróis o enxergam agora; quem está
	# escondido nas sombras não é seguido (senão a câmera entrega onde ele está).
	if not a.eh_heroi() and not b.unidade_visivel(a):
		return
	_focar_camera(_mundo(a.pos))


## 0.23: no teste de ataque, a câmera põe atacante e defensor na parte de cima da tela,
## acima da mesa, para dar para ver os dois e as cartas ao mesmo tempo.
var _combate_enquadrado := ""


func _enquadrar_combate() -> void:
	var b := batalha
	var em_ataque: bool = b.fase in [Batalha.Fase.HEROI_ATACANDO, Batalha.Fase.HEROI_DEFENDENDO, Batalha.Fase.IA_ATACANDO, Batalha.Fase.IA_DEFENDENDO]
	if _camera == null or not em_ataque or b.atacante == null or b.defensor == null:
		if not em_ataque and b.fase != Batalha.Fase.RESOLVIDO and _combate_enquadrado != "":
			_combate_enquadrado = ""
			if _camera != null and b.ativa() != null and b.ativa().eh_heroi():
				_focar_camera(_mundo(b.ativa().pos))   # o teste acabou: volta para quem joga
		return
	var chave: String = b.atacante.id + ">" + b.defensor.id
	if chave == _combate_enquadrado:
		return
	_combate_enquadrado = chave
	if not b.atacante.eh_heroi() and not b.unidade_visivel(b.atacante):
		return
	var meio := (_mundo(b.atacante.pos) + _mundo(b.defensor.pos)) / 2.0
	var d := 175.0 * _camera.size / 720.0 / 0.577
	_focar_camera(meio + Vector3(1, 0, 1).normalized() * d)


func _focar_camera(ponto: Vector3) -> void:
	_camera_alvo = ponto
	var tw := _camera.create_tween()
	tw.tween_property(_camera, "position", ponto + Vector3(10, 10, 10), 0.35).set_trans(Tween.TRANS_SINE)


## WASD ou setas: arrasta a câmera na tela (a visão é isométrica).
func _mover_camera(dir: Vector2) -> void:
	if _camera == null:
		return
	var direita := Vector3(1, 0, -1).normalized()
	var cima := Vector3(-1, 0, -1).normalized()
	var passo := _camera.size * 0.12
	_camera.position += (direita * dir.x - cima * dir.y) * passo


# --- Distribuir a fadiga da Conjuração (0.16) ---------------------------------------

func _montar_fadiga() -> void:
	_fadiga_dialogo = _painel(Color(0.07, 0.07, 0.09, 0.97), COR_OURO, 18)
	_fadiga_dialogo.position = Vector2(300, 200)
	_fadiga_dialogo.custom_minimum_size = Vector2(440, 0)
	_hud.add_child(_fadiga_dialogo)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_fadiga_dialogo.add_child(v)
	_fadiga_titulo = _label("", 15, COR_OURO, true)
	_fadiga_titulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fadiga_titulo.custom_minimum_size = Vector2(400, 0)
	v.add_child(_fadiga_titulo)
	_fadiga_linhas = VBoxContainer.new()
	_fadiga_linhas.add_theme_constant_override("separation", 6)
	v.add_child(_fadiga_linhas)
	_fadiga_dialogo.visible = false


func _abrir_fadiga(c, sobra: int, cands: Array, depois: Callable) -> void:
	if _fadiga_dialogo == null:
		_montar_fadiga()
	_fadiga_dist = {}
	_fadiga_depois = depois
	_desenhar_fadiga(c, sobra, cands)
	_fadiga_dialogo.visible = true


func _desenhar_fadiga(c, sobra: int, cands: Array) -> void:
	for f in _fadiga_linhas.get_children():
		f.queue_free()
	var posta := 0
	for k in _fadiga_dist:
		posta += int(_fadiga_dist[k])
	_fadiga_titulo.text = "%s: %d de fadiga não cabe na carta. Espalhe nas suas outras cartas (faltam %d)." % [c.nome(), sobra, sobra - posta]
	for cd in cands:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		var n := int(_fadiga_dist.get(cd["indice"], 0))
		var l := _label("%s  (livre %d)" % [cd["nome"], int(cd["espaco"])], 13, COR_TEXTO)
		l.custom_minimum_size = Vector2(260, 0)
		h.add_child(l)
		var menos := Button.new()
		menos.text = "−"
		menos.custom_minimum_size = Vector2(32, 28)
		menos.focus_mode = Control.FOCUS_NONE
		menos.disabled = n <= 0
		var idx: int = cd["indice"]
		menos.pressed.connect(func():
			_fadiga_dist[idx] = n - 1
			_desenhar_fadiga(c, sobra, cands))
		h.add_child(menos)
		h.add_child(_label(str(n), 14, COR_OURO, true))
		var mais := Button.new()
		mais.text = "+"
		mais.custom_minimum_size = Vector2(32, 28)
		mais.focus_mode = Control.FOCUS_NONE
		mais.disabled = posta >= sobra or n >= int(cd["espaco"])
		mais.pressed.connect(func():
			_fadiga_dist[idx] = n + 1
			_desenhar_fadiga(c, sobra, cands))
		h.add_child(mais)
		_fadiga_linhas.add_child(h)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	var ok := Button.new()
	ok.text = "Confirmar"
	ok.focus_mode = Control.FOCUS_NONE
	ok.disabled = posta != sobra
	ok.pressed.connect(func():
		_fadiga_dialogo.visible = false
		batalha.fadiga_escolhida = _fadiga_dist.duplicate()
		_fadiga_confirmada = c.get_meta("indice", -1) if c.has_meta("indice") else _indice_da_carta(c)
		_fadiga_depois.call())
	hb.add_child(ok)
	var cancela := Button.new()
	cancela.text = "Cancelar"
	cancela.focus_mode = Control.FOCUS_NONE
	cancela.pressed.connect(func():
		_fadiga_dialogo.visible = false
		batalha.fadiga_escolhida = {})
	hb.add_child(cancela)
	_fadiga_linhas.add_child(hb)


func _indice_da_carta(c) -> int:
	var u := batalha.ativa()
	return u.cartas.find(c)


## O pedaço do texto da carta que descreve uma opção ("• 1 de fadiga, Ação: Nome - descrição").
func _descricao_opcao(texto: String, nome: String) -> String:
	for seg in texto.replace("\n", "•").split("•"):
		var t: String = seg.strip_edges()
		var base := nome.split(" (")[0]
		if base != "" and base in t:
			var i := t.find(" - ")
			return t.substr(i + 3) if i >= 0 else t
	return ""


## Música conforme a situação: combate quando há inimigo em alerta à vista;
## senão a da exploração (a da cripta no escuro).
func _trilha_sonora() -> void:
	var musica = get_node_or_null("/root/Musica")
	if musica == null:
		return
	var b := batalha
	# A luta começa quando um inimigo em alerta aparece e só acaba quando não sobra
	# nenhum inimigo em alerta (não troca de música só porque ele saiu da vista).
	if b.inimigos_vivos().any(func(o): return o.alerta and b.unidade_visivel(o)):
		_em_luta = true
	elif not b.inimigos_vivos().any(func(o): return o.alerta):
		_em_luta = false
	var luta := _em_luta
	if luta:
		musica.tocar("batalha")
	elif b.escuro:
		musica.tocar("cripta")
	else:
		musica.tocar("exploracao")


# --- Menu de pausa (0.18) ----------------------------------------------------------------

func _abrir_pausa() -> void:
	if _pausa == null:
		_pausa = load("res://ui/menu_pausa.gd").new()
		add_child(_pausa)
	_pausa.opcoes_extras = [
		{"texto": "Defesa automática (para em 17)", "valor": _auto.button_pressed, "ao_mudar": func(on): _auto.button_pressed = on},
		{"texto": "Dano: sempre usar a sugestão", "valor": _auto_dist.button_pressed, "ao_mudar": func(on): _auto_dist.button_pressed = on},
	]
	_pausa.botoes_extras = [] if Sessao.campanha else [{"texto": "Recomeçar a missão (N)", "acao": func(): nova_batalha()}]
	var motivo := batalha.motivo_salvar()
	_pausa.ao_salvar = Callable()
	_pausa.motivo_sem_salvar = motivo
	if motivo == "":
		_pausa.ao_salvar = func():
			_pausa.fechar()
			_abrir_saves_da_missao()
			return ""
	_pausa.abrir()


func _heroi_da_carta(c):
	for h in batalha.herois():
		if c in h.cartas:
			return h
	return null


## Fichas recebidas por heróis (0.20): quando havia mais de uma carta possível, o jogador
## escolhe onde a ficha fica (cada carta tem no máximo uma de cada tipo).
func _perguntar_ficha_pendente() -> void:
	var b := batalha
	for h in b.herois():
		while not h.fichas_a_escolher.is_empty():
			var p: Dictionary = h.fichas_a_escolher.pop_front()
			var ficha: String = p["ficha"]
			var atual: int = int(p["carta"])
			if atual >= h.cartas.size() or not h.cartas[atual].tem_ficha(ficha):
				continue
			var opcoes: Array = b.cartas_para_ficha(h, ficha, atual)
			if opcoes.size() < 2:
				continue
			var botoes := []
			for i in opcoes:
				var idx: int = i
				botoes.append(["%s%s" % [h.cartas[idx].nome(), "  (onde está)" if idx == atual else ""], func(): b.mover_ficha(h, ficha, atual, idx)])
			_mostrar_pergunta("Ficha de %s · %s" % [ficha, h.nome],
				"%s recebeu 1 ficha de %s. Em qual carta ela fica? (Cada carta tem no máximo uma de cada tipo.)" % [h.nome, ficha], botoes)
			return


## Salvar no meio da missão (0.19): só nos pontos de descanso (Batalha.motivo_salvar).
var _saves = null
var _oferecer_salvar := false


func _abrir_saves_da_missao() -> void:
	if _saves == null:
		_saves = load("res://ui/janela_saves.gd").new()
		add_child(_saves)
	_saves.batalha_atual = batalha
	_saves.abrir("salvar")


# --- Fichas (0.21) -------------------------------------------------------------------
## Ficha do herói (C ou botão direito no herói): atributos com o que dão, perícias,
## equipamento, mãos, números de dano e as cartas com os DOIS lados.
## Ficha do monstro (botão direito no inimigo): vida, atributos, ações, fraquezas e
## resistências já descobertas, fichas e efeitos.

func _abrir_ficha_do_heroi(h = null) -> void:
	if h == null:
		h = _heroi_foco()
	var b := batalha
	var cols := _ficha_base("%s · %s · %s · %s" % [h.nome, h.classe, h.raca, h.background])
	# Coluna 1: atributos e perícias
	var c1: VBoxContainer = cols[0]
	c1.add_child(_label("Atributos", 14, COR_OURO, true))
	for a in Personagem.ATRIBUTOS:
		var v := int(h.atributos.get(a, 0))
		c1.add_child(_label("%s %d" % [Personagem.NOMES_ATRIBUTOS[a], v], 13, COR_TEXTO, true))
		var t := _label(Personagem.texto_atributo(a, v), 11, COR_SECUNDARIO)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.custom_minimum_size = Vector2(300, 0)
		c1.add_child(t)
	c1.add_child(_label("Perícias", 14, COR_OURO, true))
	for n in [3, 2, 1]:
		var lista := PackedStringArray()
		for p in h.pericias:
			if int(h.pericias[p]) == n:
				lista.append(p)
		if not lista.is_empty():
			var lp := _label("%d: %s" % [n, ", ".join(lista)], 11, COR_TEXTO)
			lp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lp.custom_minimum_size = Vector2(300, 0)
			c1.add_child(lp)
	# Coluna 2: equipamento e números
	var c2: VBoxContainer = cols[1]
	c2.add_child(_label("Combate", 14, COR_OURO, true))
	var maos: Array = b.maos_de(h)
	for linha in [
		"Dano da arma: %d + %s %d = %d" % [h.dano, "Destreza" if Itens.atributo_da_arma(h.arma) == "destreza" else "Força", h.atributo_dano, h.dano + h.atributo_dano],
		"Resistência: %d" % b._resistencia_de(h),
		"Velocidade: %d · Ações: 1 Movimento, %d Padrão, %d Reação" % [b._velocidade(h), h.padrao_por_turno, h.reacao_por_turno],
		"Mãos: %s | %s" % [maos[0] if maos[0] != "" else "livre", maos[1] if maos[1] != "" else "livre"],
		"Luz: %s" % ({"tocha": "tocha acesa", "lanterna": "lanterna acesa (cinto)"}.get(h.luz, "nenhuma")),
	]:
		c2.add_child(_label(linha, 12, COR_TEXTO))
	c2.add_child(_label("Equipamento", 14, COR_OURO, true))
	var eq := [["Arma", h.arma.get("nome", "—"), Itens.descricao_arma(h.arma)]]
	if not h.arma_reserva.is_empty():
		eq.append(["Reserva", h.arma_reserva["nome"], Itens.descricao_arma(h.arma_reserva)])
	eq.append(["Armadura", h.armadura.get("nome", "—"), "%s Vida %d/%d." % [h.armadura.get("texto", ""), h.vida_armadura, int(h.armadura.get("vida", 0))]])
	if int(h.escudo.get("vida", 0)) > 0:
		eq.append(["Escudo", h.escudo["nome"], "Vida %d/%d, resistência %d. Ocupa uma mão." % [h.vida_escudo, h.escudo["vida"], h.escudo["resistencia"]]])
	if h.foco.get("tipo", "") != "":
		eq.append(["Foco", h.foco.get("nome", ""), "Dano mágico %d. %s" % [int(h.foco.get("dano", 0)), h.foco.get("texto", "")]])
	for e in eq:
		c2.add_child(_label("%s: %s" % [e[0], e[1]], 12, COR_TEXTO, true))
		var le := _label(str(e[2]), 11, COR_SECUNDARIO)
		le.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		le.custom_minimum_size = Vector2(300, 0)
		c2.add_child(le)
	var itens := PackedStringArray()
	for item in h.consumiveis:
		if not Itens.CONSUMIVEIS.get(item, {}).get("nome", item) in itens:
			itens.append(Itens.CONSUMIVEIS.get(item, {}).get("nome", item))
	var li := _label("Consumíveis: " + (", ".join(itens) if not itens.is_empty() else "nenhum"), 11, COR_TEXTO)
	li.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	li.custom_minimum_size = Vector2(300, 0)
	c2.add_child(li)
	# Coluna 3: cartas, os dois lados
	var c3: VBoxContainer = cols[2]
	c3.add_child(_label("Cartas (os dois lados)", 14, COR_OURO, true))
	for c in h.cartas:
		c3.add_child(_label("%s%s" % [c.nome(), "  · fadiga %d/%d" % [c.fadiga, c.limite()] if c.limite() > 0 else ""], 13, COR_TEXTO, true))
		if c.fichas_texto() != "":
			c3.add_child(_label("Fichas: " + c.fichas_texto(), 11, Color("9fd3ff")))
		for k in c.lados.size():
			var l: Dictionary = c.lados[k]
			var txt := ""
			if c.tipo == "heroi":
				txt = "PASSIVA %s\nATIVADA %s\nDESENCADEADA %s\nAO CRITAR %s" % [l.get("passiva", ""), l.get("ativada", ""), l.get("desencadeada", ""), l.get("critico", "")]
			else:
				txt = str(l.get("texto", ""))
			var titulo := ("▶ " if k == c.lado else "   ") + ("Frente" if k == 0 else "Verso") + ": " + str(l.get("nome", ""))
			c3.add_child(_label(titulo, 11, COR_OURO if k == c.lado else COR_SECUNDARIO, true))
			var lt := _label(txt, 11, COR_TEXTO if k == c.lado else COR_SECUNDARIO)
			lt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lt.custom_minimum_size = Vector2(300, 0)
			c3.add_child(lt)
	_ficha_painel.visible = true


## Treino (0.22): mostra a etapa atual do tutorial.
func _atualizar_tutorial() -> void:
	var b := batalha
	var e := b.etapa_tutorial()
	_painel_tut.visible = not e.is_empty() and b.fase != Batalha.Fase.VITORIA and b.fase != Batalha.Fase.DERROTA
	if e.is_empty():
		return
	if _tut_mostrada != b.tutorial_etapa:
		_tut_mostrada = b.tutorial_etapa
		_tut_titulo.text = "Treino · " + str(e["titulo"])
		_tut_texto.text = str(e["texto"])
		_tut_texto.visible = true
		_painel_tut.reset_size()
		var tw := _painel_tut.create_tween()
		_painel_tut.modulate = Color(1.6, 1.6, 1.2)
		tw.tween_property(_painel_tut, "modulate", Color.WHITE, 0.8)
	_tut_proximo.visible = e.get("cond", {}).get("tipo", "botao") == "botao"
	_tut_proximo.disabled = _ocupado


## Barrinha de vida em cima de cada herói (0.23): verde = baralho e mão, vermelho = descarte, preto = exílio.
func _barra_de_vida(u, r: Label3D) -> void:
	var bz = u.baralho
	var chave := "%d/%d/%d/%d" % [bz.baralho.size(), bz.mao.size(), bz.descarte.size(), bz.exilio.size()]
	var sp: Sprite3D = r.get_node_or_null("barra")
	if sp == null:
		sp = Sprite3D.new()
		sp.name = "barra"
		sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sp.no_depth_test = true
		sp.pixel_size = 0.012
		sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sp.position = Vector3(0, -0.28, 0)
		r.add_child(sp)
	if sp.get_meta("chave", "") == chave:
		return
	sp.set_meta("chave", chave)
	var total := maxi(bz.baralho.size() + bz.mao.size() + bz.descarte.size() + bz.exilio.size(), 1)
	var largura := 60
	var img := Image.create(largura + 2, 7, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0.85))
	var partes := [[bz.baralho.size() + bz.mao.size(), Color("4fbf5a")], [bz.descarte.size(), Color("c94a3a")], [bz.exilio.size(), Color("1a1a1a")]]
	var x := 1
	for par in partes:
		var w := int(round(float(par[0]) / total * largura))
		for i in w:
			if x >= largura + 1:
				break
			for y in range(1, 6):
				img.set_pixel(x, y, par[1])
			x += 1
	sp.texture = ImageTexture.create_from_image(img)


## Explosão de uma área (0.23): as casas acendem com a cor do tipo de dano.
func _efeito_area(celulas: Array, tipo: String) -> void:
	var cor: Color = {"Radiante": Color("fff2a8"), "Fogo": Color("ff7a2c"), "Necrótico": Color("8a5ad0"), "Elétrico": Color("8fd8ff"),
		"Gelo": Color("bfe8ff"), "Concussão": Color("d8c8a8"), "Corte": Color("ff5050")}.get(tipo, Color("ffb050"))
	for c in celulas:
		var q := BoxMesh.new()
		q.size = Vector3(0.95, 0.5, 0.95)
		var mi := MeshInstance3D.new()
		mi.mesh = q
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(cor.r, cor.g, cor.b, 0.7)
		mi.material_override = m
		add_child(mi)
		mi.position = _mundo(c) + Vector3(0, 0.25, 0)
		var tw := mi.create_tween()
		tw.set_parallel(true)
		tw.tween_property(mi, "scale", Vector3(1.0, 2.2, 1.0), 0.5)
		tw.tween_property(m, "albedo_color:a", 0.0, 0.7)
		tw.chain().tween_callback(mi.queue_free)
	if not celulas.is_empty():
		var luz := OmniLight3D.new()
		luz.light_color = cor
		luz.light_energy = 3.0
		luz.omni_range = 4.0
		add_child(luz)
		var meio := Vector3.ZERO
		for c in celulas:
			meio += _mundo(c)
		luz.position = meio / celulas.size() + Vector3(0, 1.0, 0)
		var tw2 := luz.create_tween()
		tw2.tween_property(luz, "light_energy", 0.0, 0.7)
		tw2.tween_callback(luz.queue_free)


## Texto de narração (salas, inimigos que surgem, chefes): quadro no alto, até um clique.
var _painel_narrativa: PanelContainer
var _texto_narrativa: Label


func _mostrar_narrativa(titulo: String, texto: String) -> void:
	if _painel_narrativa == null or not is_instance_valid(_painel_narrativa):
		_painel_narrativa = _painel(Color(0.09, 0.08, 0.06, 0.95), COR_OURO.darkened(0.2), 14)
		_painel_narrativa.position = Vector2(300, 60)
		_painel_narrativa.custom_minimum_size = Vector2(680, 0)
		_painel_narrativa.mouse_filter = Control.MOUSE_FILTER_STOP
		_texto_narrativa = _label("", 15, COR_TEXTO)
		_texto_narrativa.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_texto_narrativa.custom_minimum_size = Vector2(650, 0)
		_texto_narrativa.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_painel_narrativa.add_child(_texto_narrativa)
		_hud.add_child(_painel_narrativa)
		_painel_narrativa.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed:
				_painel_narrativa.visible = false)
	var antes := _texto_narrativa.text if _painel_narrativa.visible else ""
	if texto in antes:
		return
	_texto_narrativa.text = (antes + "\n\n" if antes != "" else "") + ("%s\n" % titulo.to_upper() if titulo != "" else "") + texto + "\n(clique para fechar)"
	_texto_narrativa.text = _texto_narrativa.text.replace("\n(clique para fechar)\n\n", "\n\n")
	_painel_narrativa.reset_size()
	_painel_narrativa.visible = true


## Vila andável (0.23): o prédio abre por cima do mapa; Esc ou "Voltar" fecha.
func _abrir_vila(aba: String) -> void:
	if batalha.ativa() != null:
		Sessao.vila_pos = batalha.ativa().pos
	var cena: Control = load("res://ui/vila.tscn").instantiate()
	cena.aba = aba
	var camada := CanvasLayer.new()
	camada.name = "vila_aberta"
	camada.layer = 20
	add_child(camada)
	camada.add_child(cena)
	cena.tree_exited.connect(func():
		if is_instance_valid(camada):
			camada.queue_free())


## Fim do turno dos monstros (0.22): quadro com o que cada inimigo à vista pretende fazer.
## Some sozinho depois de alguns segundos ou com um clique.
var _tween_intencoes: Tween


func _mostrar_intencoes(linhas: Array) -> void:
	if _painel_intencoes == null or not is_instance_valid(_painel_intencoes):
		_painel_intencoes = _painel(Color(0.12, 0.05, 0.04, 0.93), Color("c0503a"), 10)
		_painel_intencoes.position = Vector2(330, 118)
		_painel_intencoes.custom_minimum_size = Vector2(620, 0)
		_painel_intencoes.mouse_filter = Control.MOUSE_FILTER_STOP
		var v := VBoxContainer.new()
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_painel_intencoes.add_child(v)
		v.add_child(_label("O que vocês percebem", 13, Color("ffb39a"), true))
		_texto_intencoes = _label("", 13, COR_TEXTO)
		_texto_intencoes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_texto_intencoes.custom_minimum_size = Vector2(600, 0)
		v.add_child(_texto_intencoes)
		_hud.add_child(_painel_intencoes)
		_hud.move_child(_painel_intencoes, 0)   # por baixo das fichas e menus
		_painel_intencoes.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed:
				_painel_intencoes.visible = false)
	_texto_intencoes.text = "\n".join(PackedStringArray(linhas.map(func(l): return "• " + str(l))))
	_painel_intencoes.reset_size()
	_painel_intencoes.visible = true
	_painel_intencoes.modulate.a = 1.0
	if _tween_intencoes != null and _tween_intencoes.is_valid():
		_tween_intencoes.kill()
	_tween_intencoes = _painel_intencoes.create_tween()
	_tween_intencoes.tween_interval(4.5)
	_tween_intencoes.tween_property(_painel_intencoes, "modulate:a", 0.0, 0.8)
	_tween_intencoes.tween_callback(func(): _painel_intencoes.visible = false)


func _abrir_ficha_do_monstro(o) -> void:
	var b := batalha
	var cols := _ficha_base("%s%s" % [o.nome, "  ·  %s, %s" % [o.patamar, o.papel] if o.patamar != "" else ""])
	var c1: VBoxContainer = cols[0]
	c1.add_child(_label("Vida %d / %d" % [o.vida, o.vida_max], 15, COR_VIDA_INIMIGO, true))
	c1.add_child(_label("Atributos", 14, COR_OURO, true))
	for par in [["Força", o.forca], ["Destreza", o.destreza], ["Constituição", o.constituicao], ["Percepção", o.percepcao],
			["Sabedoria", o.sabedoria], ["Raciocínio", o.raciocinio], ["Espírito", o.espirito]]:
		c1.add_child(_label("%s %d" % [par[0], int(par[1])], 12, COR_TEXTO))
	if not o.pericias.is_empty():
		c1.add_child(_label("Perícias", 14, COR_OURO, true))
		for p in o.pericias:
			c1.add_child(_label("%s %d" % [p, int(o.pericias[p])], 12, COR_TEXTO))
	if o.categoria != "":
		c1.add_child(_label("Tipo: %s" % o.categoria, 12, COR_SECUNDARIO))
	var c2: VBoxContainer = cols[1]
	c2.add_child(_label("Ações", 14, COR_OURO, true))
	var acoes := [
		"%d ação(ões) Padrão, %d Reação por turno · Velocidade %d" % [o.padrao_por_turno, o.reacao_por_turno, o.velocidade],
		"Ataque %s: dano %d%s (%s)" % ["à distância" if o.a_distancia else "corpo a corpo", o.dano, (" + %d" % o.atributo_dano) if o.atributo_dano > 0 else "", o.tipo_dano],
	]
	if o.resistencia > 0:
		acoes.append("Resistência %d" % o.resistencia)
	if o.ataque_oportunidade:
		acoes.append("Faz ataque de oportunidade em quem sai do lado dele.")
	if o.espalha_ataques:
		acoes.append("Cada ataque do turno num herói diferente.")
	for ef in o.ao_acertar:
		acoes.append("Ao acertar: %d ficha(s) de %s." % [int(ef.get("qtd", 1)), ef["ficha"]])
	if o.cura_aliado > 0:
		acoes.append("Cura %d de um aliado ferido no lugar de atacar." % o.cura_aliado)
	for m in o.magias:
		acoes.append("Magia: %s (alcance %d)." % [m.get("nome", ""), int(m.get("alcance", 8))])
	for r in o.reacoes:
		acoes.append(Reacoes.descricao(r))
	if o.perfil != "":
		acoes.append("Comportamento: %s" % o.perfil)
	for a in acoes:
		var la := _label(a, 12, COR_TEXTO)
		la.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		la.custom_minimum_size = Vector2(300, 0)
		c2.add_child(la)
	c2.add_child(_label("Fraquezas e resistências", 14, COR_OURO, true))
	var d: Dictionary = b.descobertas.get(o.tipo, {})
	var achou := false
	for t in d.get("fraquezas", {}):
		c2.add_child(_label("Fraco contra %s (+%d)" % [t, int(d["fraquezas"][t])], 12, Color("8fd18a")))
		achou = true
	for t in d.get("resistencias", {}):
		c2.add_child(_label("Resiste a %s (−%d)" % [t, int(d["resistencias"][t])], 12, Color("e0a070")))
		achou = true
	if not achou:
		c2.add_child(_label("Ainda não descobertas: aparecem aqui quando um ataque as revela.", 11, COR_SECUNDARIO))
	var c3: VBoxContainer = cols[2]
	if o.alerta and o.intencao != "":
		c3.add_child(_label("Pretende", 14, COR_OURO, true))
		var li := _label(o.intencao, 12, Color("ffb39a"))
		li.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		li.custom_minimum_size = Vector2(280, 0)
		c3.add_child(li)
	c3.add_child(_label("Fichas e efeitos", 14, COR_OURO, true))
	var efs_visiveis: Array = o.efeitos.keys().filter(func(e): return not (e in ["alvo_turno", "atacados", "curou", "remontou"] or str(e).begins_with("reagiu_")))
	if o.fichas.is_empty() and efs_visiveis.is_empty():
		c3.add_child(_label("Nenhum.", 12, COR_SECUNDARIO))
	for f in o.fichas:
		c3.add_child(_label("%s ×%d" % [f, int(o.fichas[f])], 12, Color("9fd3ff")))
	for e in o.efeitos:
		if e in ["alvo_turno", "atacados", "curou", "remontou"] or str(e).begins_with("reagiu_"):
			continue   # marcas internas
		var txt_e := str(e).replace("_", " ")
		if e == "inspirado":
			txt_e = "+%d de dano no próximo ataque (%s)" % [int(o.efeitos[e].get("valor", 1)), o.efeitos[e].get("nome", "")]
		elif e == "agarrado":
			txt_e = "agarrado: não sai do lugar"
		c3.add_child(_label(txt_e, 12, COR_TEXTO))
	if not o.alerta:
		c3.add_child(_label("Desatento (percebe heróis a até %d quadrados)." % o.vigia, 12, COR_SECUNDARIO))
	_ficha_painel.visible = true


## Monta o esqueleto da ficha: título, três colunas roláveis e o botão de fechar.
func _ficha_base(titulo: String) -> Array:
	for f in _ficha_painel.get_children():
		f.queue_free()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_ficha_painel.add_child(v)
	var h_t := HBoxContainer.new()
	var tl := _label(titulo, 18, COR_OURO, true)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_t.add_child(tl)
	var bt := Button.new()
	bt.text = "Fechar (Esc)"
	bt.focus_mode = Control.FOCUS_NONE
	bt.pressed.connect(func(): _ficha_painel.visible = false)
	h_t.add_child(bt)
	v.add_child(h_t)
	var rol := ScrollContainer.new()
	rol.custom_minimum_size = Vector2(970, 530)
	rol.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(rol)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 24)
	rol.add_child(h)
	var cols := []
	for k in 3:
		var c := VBoxContainer.new()
		c.add_theme_constant_override("separation", 3)
		c.custom_minimum_size = Vector2(305, 0)
		h.add_child(c)
		cols.append(c)
	return cols



# --- Efeitos visuais e sons (0.21) ------------------------------------------------------

## Cura: uma coluna de luz dourada sobe em quem foi curado.
func _efeito_cura(id: String) -> void:
	if not _pecas.has(id):
		return
	var peca: Node3D = _pecas[id]
	var col := CylinderMesh.new()
	col.top_radius = 0.42
	col.bottom_radius = 0.46
	col.height = 1.8
	var mi := MeshInstance3D.new()
	mi.mesh = col
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1.0, 0.85, 0.35, 0.45)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.position = peca.position + Vector3(0, 0.9, 0)
	var luz := OmniLight3D.new()
	luz.light_color = Color("ffd36b")
	luz.light_energy = 2.5
	luz.omni_range = 3.0
	mi.add_child(luz)
	mi.scale = Vector3(0.3, 0.2, 0.3)
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3(1, 1, 1), 0.35).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(m, "albedo_color:a", 0.0, 0.9).set_delay(0.3)
	tw.parallel().tween_property(luz, "light_energy", 0.0, 0.9).set_delay(0.3)
	tw.tween_callback(mi.queue_free)


## Magia: um raio de luz do conjurador até o alvo (cor pelo tipo de dano).
func _efeito_raio(de: Vector3, ate: Vector3, tipo: String) -> void:
	var cor: Color = {"Radiante": Color("fff2a8"), "Fogo": Color("ff8a3d"), "Necrótico": Color("8a5ad0"),
		"Elétrico": Color("8fd8ff"), "Gelo": Color("bfe8ff"), "Arcano": Color("b58cff")}.get(tipo, Color("b58cff"))
	var a := de + Vector3(0, 0.9, 0)
	var b := ate + Vector3(0, 0.8, 0)
	var dist := a.distance_to(b)
	if dist < 0.1:
		return
	var feixe := CylinderMesh.new()
	feixe.top_radius = 0.07
	feixe.bottom_radius = 0.07
	feixe.height = dist
	var mi := MeshInstance3D.new()
	mi.mesh = feixe
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(cor.r, cor.g, cor.b, 0.9)
	mi.material_override = m
	add_child(mi)
	mi.position = (a + b) / 2.0
	mi.look_at(b, Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.RIGHT)
	mi.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	var luz := OmniLight3D.new()
	luz.light_color = cor
	luz.light_energy = 2.0
	luz.omni_range = 2.5
	add_child(luz)
	luz.position = b
	var tw := mi.create_tween()
	tw.tween_property(m, "albedo_color:a", 0.0, 0.45)
	tw.parallel().tween_property(luz, "light_energy", 0.0, 0.45)
	tw.tween_callback(func():
		mi.queue_free()
		luz.queue_free())


var _sons := {}
var _tocadores: Array = []


## Sons curtos (0.21): passos, golpe, tiro, magia, acerto, cura (assets/sons, gerados por
## tools/gerar_sons.py). Usam o volume da música (desligam junto com ela).
func _som(nome: String) -> void:
	var musica = get_node_or_null("/root/Musica")
	if musica != null and musica.mudo:
		return
	if not _sons.has(nome):
		var caminho := "res://assets/sons/%s.wav" % nome
		_sons[nome] = load(caminho) if ResourceLoader.exists(caminho) else null
	if _sons[nome] == null:
		return
	if _tocadores.is_empty():
		for i in 4:
			var p := AudioStreamPlayer.new()
			add_child(p)
			_tocadores.append(p)
	var livre: AudioStreamPlayer = _tocadores[0]
	for p in _tocadores:
		if is_instance_valid(p) and not p.playing:
			livre = p
			break
	if not is_instance_valid(livre):
		return
	livre.stream = _sons[nome]
	livre.volume_db = (linear_to_db(maxf(musica.volume, 0.01)) if musica != null else 0.0) - 4.0
	livre.play()
