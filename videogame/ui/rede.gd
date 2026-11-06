## Jogo em rede (0.26): mesma rede (Wi-Fi/cabo) ou Hamachi. Autoload "Rede".
##
## O anfitrião é a autoridade. As regras são deterministas (tudo sai do gerador com
## semente), então ninguém manda o estado inteiro a cada jogada: o anfitrião manda o
## retrato da batalha uma vez (core/instantaneo.gd) e, depois, só a lista ordenada de
## comandos ({seq, passos: [[método, argumentos]]}). Cada computador aplica os mesmos
## comandos na mesma ordem e chega ao mesmo estado. Os convidados pedem; o anfitrião
## confere se quem pediu é o dono do herói que decide aquele momento, aplica e repassa.
## Uma assinatura curta do estado vai junto: se um convidado divergir, ele pede o
## retrato de novo e continua dali.
##
## Campanha: a party fica salva no anfitrião (core/party.gd). Nos convidados, a campanha
## e as fichas da party vivem só na memória (Campanha.memoria / Personagem.memoria);
## compras, vendas e estalagem viram pedidos ao anfitrião, que responde com o estado novo.
extends Node

signal lobby_mudou
signal campanha_mudou
signal mensagem(texto: String)
signal todos_prontos

const Sessao := preload("res://core/sessao.gd")
const Personagem := preload("res://core/personagem.gd")
const Campanha := preload("res://core/campanha.gd")
const Party := preload("res://core/party.gd")
const Fase := preload("res://core/fase.gd")

const VERSAO := "0.32"
const PORTA := 7021
const MAXIMO_HEROIS := 4
const MAXIMO_CONVIDADOS := 3
const METODOS_CAMPANHA := ["comprar_item", "vender", "descansar"]
## Missões avulsas que dá para jogar em rede (o treino é só para um jogador).
const MODOS := [["arena", "Arena: combate simples"], ["fazenda", "Missão: a fazenda Vale Seco"],
	["masmorra", "Missão: a cripta de Pedravelha"], ["pantano", "Missão: o Pântano dos Afogados"],
	["catacumbas", "Missão longa: as Catacumbas de Vel-Dorath"], ["trilha", "Exploração: a trilha do riacho"],
	["x1", "X1 contra o Chefe Goblin"]]

## Missões avulsas + as fases criadas no editor deste computador (0.27).
func modos() -> Array:
	var l := MODOS.duplicate()
	for x in Fase.listar():
		l.append([Fase.PREFIXO + x["id"], "Fase criada: %s" % x["nome"]])
	return l


var ativo := false
var anfitriao := false
var meu_nome := "Jogador"
## peer -> {"nome", "herois": [nomes dos heróis escolhidos], "conectado"}
var jogadores := {}
## Anfitrião, missão avulsa: nome do herói -> ficha (cada jogador manda a sua).
var fichas_avulsas := {}
## {"tipo": "avulsa"|"campanha", "modo", "party": id}
var config := {"tipo": "avulsa", "modo": "arena", "party": ""}
## Party aberta (anfitrião manda para todos): {"id", "nome", "membros": [{"heroi", "jogador", "resumo"}]}
var party_info := {}
var parties: Array = []    # só no anfitrião: as parties salvas (para a escolha)
var em_jogo := false
var donos := {}            # id da unidade ("heroi", "heroi2"...) -> peer
var tela = null            # ui/batalha_tela.gd em uso
var partida := 0           # muda a cada batalha nova; comandos de outra partida são ignorados
var seq := 0               # anfitrião: último comando mandado
var ultimo_aviso := ""     # mostrado na sala (ex.: "o anfitrião saiu")
var _prontos := {}
var _esperando_estado: Array = []
var _req := 0
var _respostas := {}       # pedido de campanha -> Callable


func _ready() -> void:
	multiplayer.peer_connected.connect(_entrou)
	multiplayer.peer_disconnected.connect(_saiu)
	multiplayer.connected_to_server.connect(_conectado)
	multiplayer.connection_failed.connect(_falhou)
	multiplayer.server_disconnected.connect(_anfitriao_saiu)


func meu_id() -> int:
	return multiplayer.get_unique_id() if ativo else 1


# --- Conexão -------------------------------------------------------------------

func hospedar(nome: String) -> String:
	sair()
	var p := ENetMultiplayerPeer.new()
	var e := p.create_server(PORTA, MAXIMO_CONVIDADOS)
	if e != OK:
		return "Não deu para abrir a sala na porta %d (outro Sistema 21 já está aberto neste computador?)." % PORTA
	multiplayer.multiplayer_peer = p
	ativo = true
	anfitriao = true
	meu_nome = nome
	jogadores = {1: {"nome": nome, "herois": [], "conectado": true}}
	fichas_avulsas = {}
	config = {"tipo": "avulsa", "modo": "arena", "party": ""}
	party_info = {}
	parties = Party.listar()
	em_jogo = false
	lobby_mudou.emit()
	return ""


func entrar(ip: String, nome: String) -> String:
	sair()
	var p := ENetMultiplayerPeer.new()
	var e := p.create_client(ip.strip_edges(), PORTA)
	if e != OK:
		return "Endereço inválido: %s" % ip
	multiplayer.multiplayer_peer = p
	ativo = true
	anfitriao = false
	meu_nome = nome
	jogadores = {}
	return ""


func sair() -> void:
	if multiplayer.multiplayer_peer != null and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	ativo = false
	anfitriao = false
	em_jogo = false
	jogadores = {}
	donos = {}
	party_info = {}
	tela = null
	Sessao.online = false
	Sessao.fichas_online = []
	Sessao.campanha = false
	Fase.memoria = {}
	Party.fechar()


## Endereços deste computador para os outros digitarem (Hamachi = 25.x.x.x).
func enderecos() -> Array:
	var lista := []
	for ip in IP.get_local_addresses():
		if ip.contains(":") or ip.begins_with("127.") or ip.begins_with("169.254."):
			continue
		var tipo := "Hamachi" if ip.begins_with("25.") else ("rede local / Wi-Fi" if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172.") else "outra rede")
		lista.append([ip, tipo])
	lista.sort_custom(func(a, b): return a[1] < b[1])
	return lista


func _conectado() -> void:
	_ola.rpc_id(1, meu_nome, VERSAO)


func _falhou() -> void:
	sair()
	ultimo_aviso = "Não achei a sala nesse endereço. Confira o IP, se o anfitrião criou a sala e se o firewall do Windows deixou o Sistema 21 usar a rede."
	_ir_para_sala()


func _anfitriao_saiu() -> void:
	sair()
	ultimo_aviso = "O anfitrião fechou a sala ou a conexão caiu."
	_ir_para_sala()


func _entrou(_peer: int) -> void:
	pass   # espera o "olá" com o nome e a versão


func _saiu(peer: int) -> void:
	if not anfitriao or not jogadores.has(peer):
		return
	var nome: String = jogadores[peer]["nome"]
	if em_jogo:
		jogadores[peer]["conectado"] = false
		_avisar_todos("%s caiu. O anfitrião controla os heróis dele até ele voltar (é só entrar de novo com o mesmo nome)." % nome)
		_prontos.erase(peer)
		_conferir_prontos()
	else:
		jogadores.erase(peer)
		_avisar_todos("%s saiu da sala." % nome)
	_difundir_lobby()
	if tela != null and is_instance_valid(tela):
		tela.rede_mudou()


func _ir_para_sala() -> void:
	get_tree().change_scene_to_file("res://ui/sala.tscn")


@rpc("any_peer", "call_remote", "reliable")
func _ola(nome: String, versao: String) -> void:
	if not anfitriao:
		return
	var de := multiplayer.get_remote_sender_id()
	if versao != VERSAO:
		_recusado.rpc_id(de, "Versões diferentes: o anfitrião está na %s e você na %s. Usem a mesma versão." % [VERSAO, versao])
		return
	if em_jogo:
		# Volta de quem caiu: mesmo nome, retoma os heróis.
		for p in jogadores.keys():
			if jogadores[p]["nome"] == nome and not jogadores[p]["conectado"]:
				var j: Dictionary = jogadores[p]
				jogadores.erase(p)
				j["conectado"] = true
				jogadores[de] = j
				for id in donos.keys():
					if donos[id] == p:
						donos[id] = de
				_avisar_todos("%s voltou." % nome)
				_difundir_lobby()
				_ir.rpc_id(de, _info_da_cena(Sessao.modo))
				return
		_recusado.rpc_id(de, "A partida já começou. Para voltar a uma partida, entre com o mesmo nome de antes.")
		return
	if jogadores.size() >= MAXIMO_HEROIS:
		_recusado.rpc_id(de, "A sala está cheia.")
		return
	var usado := jogadores.values().map(func(j): return j["nome"])
	var final := nome
	var n := 2
	while final in usado:
		final = "%s (%d)" % [nome, n]
		n += 1
	jogadores[de] = {"nome": final, "herois": [], "conectado": true}
	_avisar_todos("%s entrou na sala." % final)
	_difundir_lobby()


@rpc("authority", "call_remote", "reliable")
func _recusado(motivo: String) -> void:
	sair()
	ultimo_aviso = motivo
	_ir_para_sala()


func _avisar_todos(texto: String) -> void:
	mensagem.emit(texto)
	if ativo and anfitriao:
		_aviso.rpc(texto)


@rpc("authority", "call_remote", "reliable")
func _aviso(texto: String) -> void:
	mensagem.emit(texto)


# --- Sala -----------------------------------------------------------------------

func _estado_lobby() -> Dictionary:
	var js := {}
	for p in jogadores:
		js[p] = jogadores[p].duplicate(true)
	return {"jogadores": js, "config": config.duplicate(), "party": party_info.duplicate(true)}


func _difundir_lobby() -> void:
	if not anfitriao:
		return
	_lobby.rpc(_estado_lobby())
	lobby_mudou.emit()


@rpc("authority", "call_remote", "reliable")
func _lobby(e: Dictionary) -> void:
	jogadores = e["jogadores"]
	config = e["config"]
	party_info = e["party"]
	lobby_mudou.emit()


## Quantos heróis já foram escolhidos na sala.
func total_de_herois() -> int:
	var n := 0
	for p in jogadores:
		n += jogadores[p]["herois"].size()
	return n


## Quem já escolheu este herói (peer) ou 0.
func quem_escolheu(heroi: String) -> int:
	for p in jogadores:
		if heroi in jogadores[p]["herois"]:
			return p
	return 0


## Anfitrião: muda a missão ou a party. Zera as escolhas de heróis.
func definir_config(tipo: String, modo: String, party_id: String) -> void:
	if not anfitriao:
		return
	config = {"tipo": tipo, "modo": modo, "party": party_id}
	for m in modos():
		if m[0] == modo:
			config["nome_modo"] = m[1]
	for p in jogadores:
		jogadores[p]["herois"] = []
	fichas_avulsas = {}
	_atualizar_party()
	_difundir_lobby()


func _atualizar_party() -> void:
	party_info = {}
	if anfitriao:
		parties = Party.listar()
	if config["tipo"] != "campanha" or config["party"] == "":
		return
	var p := Party.carregar(config["party"])
	if p.is_empty():
		return
	var fichas := Party.fichas(p["id"])
	var membros := []
	for m in p["membros"]:
		var f: Dictionary = {}
		for x in fichas:
			if str(x.get("nome", "")) == str(m["heroi"]):
				f = x
		membros.append({"heroi": m["heroi"], "jogador": m["jogador"], "resumo": Party.resumo_da_ficha(f) if not f.is_empty() else "?"})
	party_info = {"id": p["id"], "nome": p["nome"], "membros": membros}


func criar_party(nome: String) -> String:
	var p := Party.criar(nome)
	if p.is_empty():
		return "Já existe uma party com esse nome (ou o nome está vazio)."
	parties = Party.listar()
	definir_config("campanha", "vila", p["id"])
	return ""


## Escolha de herói na sala. d = {"ficha": f} (missão avulsa), {"party": nome} (herói da
## party), {"vincular": f} (vincular um herói deste computador à party) ou {"tirar": nome}.
func escolher(d: Dictionary) -> void:
	if anfitriao:
		_escolher_de(1, d)
	else:
		_escolher.rpc_id(1, d)


@rpc("any_peer", "call_remote", "reliable")
func _escolher(d: Dictionary) -> void:
	if anfitriao:
		_escolher_de(multiplayer.get_remote_sender_id(), d)


func _escolher_de(de: int, d: Dictionary) -> void:
	if not jogadores.has(de) or em_jogo:
		return
	var j: Dictionary = jogadores[de]
	var erro := ""
	var nome := ""
	if d.has("tirar"):
		j["herois"].erase(str(d["tirar"]))
		fichas_avulsas.erase(str(d["tirar"]))
		_difundir_lobby()
		return
	if d.has("ficha"):
		nome = str(d["ficha"].get("nome", ""))
		if config["tipo"] != "avulsa":
			erro = "O anfitrião escolheu a campanha: escolha um herói da party."
		elif not Personagem.validar(d["ficha"]).is_empty():
			erro = "A ficha de %s tem pendências; termine na criação de heróis." % nome
		elif quem_escolheu(nome) not in [0, de]:
			erro = "Outro jogador já trouxe um herói chamado %s." % nome
		else:
			fichas_avulsas[nome] = d["ficha"].duplicate(true)
	elif d.has("vincular"):
		nome = str(d["vincular"].get("nome", ""))
		if config["tipo"] != "campanha" or party_info.is_empty():
			erro = "Não há party aberta."
		else:
			erro = Party.vincular(party_info["id"], d["vincular"], j["nome"])
			if erro == "":
				_atualizar_party()
	elif d.has("party"):
		nome = str(d["party"])
		if party_info.is_empty() or not party_info["membros"].any(func(m): return m["heroi"] == nome):
			erro = "%s não está na party." % nome
		elif quem_escolheu(nome) not in [0, de]:
			erro = "Outro jogador já está com %s." % nome
	if erro == "" and nome != "" and not nome in j["herois"]:
		# Convidado joga com um herói; o anfitrião pode completar o grupo com mais.
		if de != 1:
			for antigo in j["herois"]:
				fichas_avulsas.erase(antigo)
			j["herois"] = []
		if total_de_herois() >= MAXIMO_HEROIS:
			erro = "O grupo já tem %d heróis." % MAXIMO_HEROIS
		else:
			j["herois"].append(nome)
	if erro != "":
		if de == 1:
			mensagem.emit(erro)
		else:
			_aviso.rpc_id(de, erro)
	_difundir_lobby()


func motivo_sem_comecar() -> String:
	if total_de_herois() == 0:
		return "Ninguém escolheu herói ainda."
	for p in jogadores:
		if jogadores[p]["conectado"] and jogadores[p]["herois"].is_empty():
			return "%s ainda não escolheu o herói." % jogadores[p]["nome"]
	if config["tipo"] == "campanha" and party_info.is_empty():
		return "Escolha ou crie a party."
	return ""


## Anfitrião: começa. Campanha vai para a vila; missão avulsa vai direto para a missão.
func comecar() -> void:
	if not anfitriao or motivo_sem_comecar() != "":
		return
	em_jogo = true
	if config["tipo"] == "campanha":
		Party.abrir(config["party"])
		Sessao.vila_pos = Vector2i(-1, -1)
		ir_para("vila")
	else:
		ir_para(config["modo"])


## Ordem dos heróis na batalha: os do anfitrião primeiro, depois os convidados por chegada.
func _ordem_dos_herois() -> Array:
	var ordem := []
	var peers := jogadores.keys()
	peers.sort()
	for p in peers:
		for n in jogadores[p]["herois"]:
			ordem.append([n, p])
	return ordem


func _fichas_atuais(ordem: Array) -> Array:
	var lista := []
	var da_party := Personagem.carregar_todos() if config["tipo"] == "campanha" else []
	for par in ordem:
		if config["tipo"] == "campanha":
			for f in da_party:
				if str(f.get("nome", "")) == par[0]:
					lista.append(f)
		else:
			lista.append(fichas_avulsas.get(par[0], {}))
	return lista


func _info_da_cena(modo: String) -> Dictionary:
	var ordem := _ordem_dos_herois()
	var info := {"modo": modo, "campanha": config["tipo"] == "campanha", "fichas": _fichas_atuais(ordem),
		"donos": ordem.map(func(par): return par[1]), "partida": partida, "vila_pos": Sessao.vila_pos}
	if info["campanha"]:
		info["camp"] = estado_campanha()
	if modo.begins_with(Fase.PREFIXO):
		# 0.27: o convidado não tem a fase no computador dele; vai junto.
		info["fase"] = Fase.carregar(modo.trim_prefix(Fase.PREFIXO))
	return info


## Anfitrião: leva todo mundo para uma cena (missão, vila, de novo).
func ir_para(modo: String) -> void:
	if not anfitriao:
		return
	partida += 1
	seq = 0
	_prontos = {}
	_esperando_estado = []
	var info := _info_da_cena(modo)
	_ir.rpc(info)
	_aplicar_cena(info)


@rpc("authority", "call_remote", "reliable")
func _ir(info: Dictionary) -> void:
	_aplicar_cena(info)


func _aplicar_cena(info: Dictionary) -> void:
	em_jogo = true
	partida = int(info["partida"])
	Sessao.online = true
	Sessao.solo = false
	Sessao.fichas_online = info["fichas"]
	Sessao.modo = info["modo"]
	Sessao.campanha = info["campanha"]
	Sessao.vila_pos = info["vila_pos"]
	Sessao.estado_salvo = ""
	donos = {}
	for i in info["donos"].size():
		donos["heroi" if i == 0 else "heroi%d" % (i + 1)] = int(info["donos"][i])
	if info.has("camp") and not anfitriao:
		_aplicar_campanha(info["camp"])
	if info.has("fase") and not anfitriao:
		Fase.memoria[str(info["modo"]).trim_prefix(Fase.PREFIXO)] = info["fase"]
	tela = null
	get_tree().change_scene_to_file("res://ui/batalha.tscn")


## Anfitrião: todos voltam para a sala (a party continua escolhida).
func voltar_para_sala() -> void:
	if not anfitriao:
		return
	_para_sala.rpc()
	_para_sala()


@rpc("authority", "call_remote", "reliable")
func _para_sala() -> void:
	em_jogo = false
	tela = null
	Sessao.online = false
	if not anfitriao:
		Personagem.memoria = null
		Campanha.memoria = false
		Campanha.dados = {}
		Fase.memoria = {}
	else:
		Party.fechar()
		_atualizar_party()
		for p in jogadores.keys():
			if not jogadores[p]["conectado"]:
				jogadores.erase(p)
		_difundir_lobby()
	_ir_para_sala()


# --- Donos dos heróis ------------------------------------------------------------

## Quem controla o herói agora (quem caiu passa para o anfitrião).
func dono_de(id: String) -> int:
	var p := int(donos.get(id, 1))
	if p != 1 and not (jogadores.has(p) and jogadores[p].get("conectado", true)):
		return 1
	return p


## O jogador deste computador decide por este herói? ("" = vez dos monstros: só o anfitrião.)
func e_meu(id: String) -> bool:
	if not ativo:
		return true
	if id == "":
		return anfitriao
	return dono_de(id) == meu_id()


func nome_do_jogador(peer: int) -> String:
	return str(jogadores.get(peer, {}).get("nome", "?"))


# --- Batalha ------------------------------------------------------------------------

func registrar_tela(t) -> void:
	tela = t


## Anfitrião: a batalha está montada; manda o retrato para quem já pediu.
func batalha_montada() -> void:
	for p in _esperando_estado:
		_mandar_estado(p)
	_esperando_estado = []
	_conferir_prontos()


func _conferir_prontos() -> void:
	if not anfitriao:
		return
	for p in jogadores:
		if p != 1 and jogadores[p]["conectado"] and not _prontos.has(p):
			return
	todos_prontos.emit()


## Convidado: pede o retrato da batalha (ao entrar na cena ou se divergiu).
func pedir_estado() -> void:
	_pedir_estado.rpc_id(1, partida)


@rpc("any_peer", "call_remote", "reliable")
func _pedir_estado(da_partida: int) -> void:
	if not anfitriao:
		return
	var de := multiplayer.get_remote_sender_id()
	if da_partida != partida or tela == null or not is_instance_valid(tela) or not tela.pronta_para_rede():
		if not de in _esperando_estado:
			_esperando_estado.append(de)
		return
	_mandar_estado(de)
	_conferir_prontos()


func _mandar_estado(p: int) -> void:
	if tela == null or not is_instance_valid(tela) or not jogadores.has(p):
		return
	_prontos[p] = true
	_estado.rpc_id(p, tela.retrato_para_rede())


@rpc("authority", "call_remote", "reliable")
func _estado(d: Dictionary) -> void:
	if tela != null and is_instance_valid(tela) and int(d["partida"]) == partida:
		tela.receber_estado(d)


func enviar_pedido(cmd: Dictionary) -> void:
	_pedido.rpc_id(1, cmd)


@rpc("any_peer", "call_remote", "reliable")
func _pedido(cmd: Dictionary) -> void:
	if not anfitriao or tela == null or not is_instance_valid(tela):
		return
	cmd["de"] = multiplayer.get_remote_sender_id()
	if int(cmd.get("partida", -1)) != partida:
		return
	tela.pedido_remoto(cmd)


## Anfitrião: o pedido não vale (não é a vez daquele jogador, por exemplo).
func recusar(peer: int, req: int, motivo: String) -> void:
	if peer == 1:
		if tela != null and is_instance_valid(tela):
			tela.recusa(req, motivo)
	else:
		_recusa.rpc_id(peer, req, motivo)


@rpc("authority", "call_remote", "reliable")
func _recusa(req: int, motivo: String) -> void:
	if tela != null and is_instance_valid(tela):
		tela.recusa(req, motivo)


## Anfitrião: repassa um comando já aplicado aqui.
func difundir(cmd: Dictionary) -> void:
	seq += 1
	cmd["seq"] = seq
	cmd["partida"] = partida
	if ativo and anfitriao and jogadores.size() > 1:
		_comando.rpc(cmd)


@rpc("authority", "call_remote", "reliable")
func _comando(cmd: Dictionary) -> void:
	if tela != null and is_instance_valid(tela) and int(cmd.get("partida", -1)) == partida:
		tela.comando_remoto(cmd)


## Anfitrião: o resumo da campanha no fim da missão.
func difundir_resumo(texto: String) -> void:
	if anfitriao:
		_resumo.rpc(texto, partida)


@rpc("authority", "call_remote", "reliable")
func _resumo(texto: String, da_partida: int) -> void:
	if tela != null and is_instance_valid(tela) and da_partida == partida:
		tela.receber_resumo(texto)


# --- Campanha ------------------------------------------------------------------------

func estado_campanha() -> Dictionary:
	return {"dados": Campanha.carregar().duplicate(true), "fichas": Personagem.carregar_todos(), "fases": Fase.fases_do_mural()}


func difundir_campanha() -> void:
	if anfitriao and ativo:
		_refrescar_fichas()
		_campanha.rpc(estado_campanha())
		campanha_mudou.emit()


## As fichas do grupo em jogo seguem a party (compras, vendas, fim de missão).
func _refrescar_fichas() -> void:
	var todas := Personagem.carregar_todos()
	var novas := []
	for f in Sessao.fichas_online:
		var nova: Dictionary = f
		for x in todas:
			if str(x.get("nome", "")) == str(f.get("nome", "")):
				nova = x
		novas.append(nova)
	Sessao.fichas_online = novas


@rpc("authority", "call_remote", "reliable")
func _campanha(e: Dictionary) -> void:
	_aplicar_campanha(e)
	campanha_mudou.emit()


func _aplicar_campanha(e: Dictionary) -> void:
	Campanha.memoria = true
	Campanha.dados = e["dados"]
	Personagem.memoria = e["fichas"]
	for id in e.get("fases", {}):
		Fase.memoria[id] = e["fases"][id]
	_refrescar_fichas()


## Compra, venda e estalagem na vila. No anfitrião roda na hora; no convidado vira pedido
## e "depois" recebe o resultado quando o anfitrião responde.
func campanha(metodo: String, args: Array, depois: Callable) -> void:
	if not ativo or anfitriao:
		var r = Campanha.executar(metodo, args) if metodo in METODOS_CAMPANHA else null
		if ativo:
			difundir_campanha()
		depois.call(r)
		return
	_req += 1
	_respostas[_req] = depois
	_campanha_pedido.rpc_id(1, _req, metodo, args)


@rpc("any_peer", "call_remote", "reliable")
func _campanha_pedido(req: int, metodo: String, args: Array) -> void:
	if not anfitriao or not metodo in METODOS_CAMPANHA:
		return
	var de := multiplayer.get_remote_sender_id()
	var r = Campanha.executar(metodo, args)
	difundir_campanha()
	_campanha_resposta.rpc_id(de, req, r)


@rpc("authority", "call_remote", "reliable")
func _campanha_resposta(req: int, r: Variant) -> void:
	var f: Callable = _respostas.get(req, Callable())
	_respostas.erase(req)
	if f.is_valid():
		f.call(r)
