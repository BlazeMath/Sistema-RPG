## Ferramenta de desenvolvimento (0.26): dois Godot no mesmo computador jogam em rede
## sozinhos e, no fim, cada um imprime a assinatura do estado. Uso (dois terminais):
##   REDE_PAPEL=anfitriao REDE_CENARIO=avulsa godot --headless --path . -s res://tools/robo_rede.gd
##   REDE_PAPEL=convidado REDE_CENARIO=avulsa godot --headless --path . -s res://tools/robo_rede.gd
## REDE_CENARIO=campanha: party nova, vila, uma compra do convidado e depois a fazenda.
extends SceneTree

const Batalha := preload("res://core/batalha.gd")
const Prontos := preload("res://core/herois_prontos.gd")
const Instantaneo := preload("res://core/instantaneo.gd")
const Grade := preload("res://core/grade.gd")
const Party := preload("res://core/party.gd")
const Campanha := preload("res://core/campanha.gd")
const Sessao := preload("res://core/sessao.gd")

var papel := ""
var cenario := ""
var rede
var _tentou := {}
var _comandos := 0
var _fotos := ""


func _init() -> void:
	papel = OS.get_environment("REDE_PAPEL")
	cenario = OS.get_environment("REDE_CENARIO")
	_fotos = OS.get_environment("CAPTURAS")
	_rodar.call_deferred()


func _esperar(seg: float) -> void:
	await create_timer(seg).timeout


func _log(t: String) -> void:
	print("[%s] %s" % [papel, t])


func _foto(nome: String) -> void:
	if _fotos == "":
		return
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png(_fotos.path_join("%s_%s.png" % [papel, nome]))


func _ficha(classe: String, nome: String) -> Dictionary:
	var f := Prontos.ficha(classe)
	f["nome"] = nome
	return f


func _rodar() -> void:
	rede = root.get_node("Rede")
	rede.mensagem.connect(func(t): _log("aviso: " + t))
	change_scene_to_file("res://ui/sala.tscn")
	await _esperar(1.0)
	if papel == "anfitriao":
		_log(str(rede.hospedar("Ana")))
		if cenario == "campanha":
			var nome := "Robôs %d" % (Time.get_ticks_usec() % 100000)
			_log("party: " + rede.criar_party(nome))
			rede.escolher({"vincular": _ficha("Guerreiro", "Brom do Anfitrião")})
		else:
			rede.definir_config("avulsa", OS.get_environment("REDE_MODO") if OS.get_environment("REDE_MODO") != "" else "fazenda", "")
			rede.escolher({"ficha": _ficha("Guerreiro", "Brom do Anfitrião")})
			rede.escolher({"ficha": _ficha("Clérigo", "Irmã do Anfitrião")})
		await _foto("sala")
		for i in 200:
			await _esperar(0.25)
			if rede.motivo_sem_comecar() == "" and rede.jogadores.size() >= 2:
				break
		_log("começando: " + rede.motivo_sem_comecar())
		await _foto("sala_pronta")
		rede.comecar()
	else:
		await _esperar(1.5)
		_log(str(rede.entrar("127.0.0.1", "Bia")))
		for i in 100:
			await _esperar(0.2)
			if not rede.jogadores.is_empty():
				break
		await _esperar(1.0)
		if cenario == "campanha":
			rede.escolher({"vincular": _ficha("Mago", "Lume da Convidada")})
		else:
			rede.escolher({"ficha": _ficha("Ladino", "Lume da Convidada")})
		await _foto("sala")
	# Espera a batalha começar.
	for i in 200:
		await _esperar(0.2)
		if rede.tela != null and is_instance_valid(rede.tela) and rede.tela.batalha != null and not rede.tela._aguardando:
			break
	_log("na batalha: %s, heróis %s, donos %s" % [Sessao.modo, rede.tela.batalha.herois().map(func(h): return h.nome), rede.donos])
	await _esperar(2.0)
	await _foto("inicio")
	if cenario == "campanha":
		await _campanha()
	await _jogar(float(OS.get_environment("REDE_SEGUNDOS")) if OS.get_environment("REDE_SEGUNDOS") != "" else 60.0)
	# Para de jogar e deixa assentar.
	await _esperar(6.0)
	await _foto("fim")
	var t = rede.tela
	_log("FINAL seq=%d fase=%d hash=%d ass=%d comandos=%d" % [t._seq_rede, t.batalha.fase, Instantaneo.para_texto(t.batalha).hash(), t._assinatura(), _comandos])
	await _esperar(3.0)
	quit()


func _campanha() -> void:
	# Na vila: o convidado compra (pedido ao anfitrião); depois o anfitrião parte para a fazenda.
	if papel == "convidado":
		var antes: int = Campanha.dinheiro()
		var feito := [false]
		rede.campanha("comprar_item", ["Lume da Convidada", "lanca"], func(r):
			_log("compra: '%s'" % str(r))
			feito[0] = true)
		for i in 50:
			await _esperar(0.2)
			if feito[0]:
				break
		await _esperar(0.5)
		_log("bolsa %d -> %d; arma %s" % [antes, Campanha.dinheiro(), str(Sessao.fichas_online[1].get("arma2", "?"))])
	else:
		for i in 60:
			await _esperar(0.25)
			if Campanha.dinheiro() < Campanha.DINHEIRO_INICIAL:
				break
		_log("bolsa no anfitrião: %d" % Campanha.dinheiro())
		await _esperar(1.0)
		rede.ir_para("fazenda")
	for i in 200:
		await _esperar(0.2)
		if rede.tela != null and is_instance_valid(rede.tela) and Sessao.modo == "fazenda" and rede.tela.batalha != null and not rede.tela._aguardando:
			break
	await _esperar(1.5)
	_log("missão: %s, arma da convidada %s" % [Sessao.modo, str(rede.tela.batalha.unidade("heroi2").arma_reserva)])


func _jogar(segundos: float) -> void:
	var fim := Time.get_ticks_msec() + int(segundos * 1000)
	while Time.get_ticks_msec() < fim:
		await _esperar(0.15)
		var t = rede.tela
		if t == null or not is_instance_valid(t) or t.batalha == null:
			continue
		var b = t.batalha
		if b.fase in [Batalha.Fase.VITORIA, Batalha.Fase.DERROTA]:
			break
		if t._ocupado or t._aguardando or t._esperando_req != 0 or b.fase_automatica() or not t._eu_decido():
			continue
		if OS.get_environment("REDE_DESSINCRONIZAR") != "" and papel == "convidado" and _comandos == 3 and not has_meta("dessincronizou"):
			set_meta("dessincronizou", true)
			b.rng.randi()
			_log("estado mexido de propósito (teste da ressincronização)")
		var cmd := _decidir(b)
		if cmd.is_empty():
			continue
		t._cmd([cmd])
		t._processar()
		_comandos += 1


func _decidir(b) -> Array:
	var F := Batalha.Fase
	match b.fase:
		F.HEROI_ESCOLHE:
			var u = b.ativa()
			var alvos: Array = b.inimigos_vivos()
			var chave := "%s:%d:%d" % [u.id, b.rodada, u.acoes_padrao]
			if alvos.is_empty():
				return ["encerrar_turno", []]
			alvos.sort_custom(func(x, y): return Grade.distancia(u.pos, x.pos) < Grade.distancia(u.pos, y.pos))
			if u.acoes_padrao > 0 and b.motivo_alcance(u, alvos[0], u.pos) == "" and not _tentou.has(chave + ":a"):
				_tentou[chave + ":a"] = true
				return ["heroi_atacar", [alvos[0]]]
			var info: Dictionary = b.alcance_movimento(u)
			var melhor: Vector2i = u.pos
			for p in info["mapa"]:
				if Grade.distancia(p, alvos[0].pos) < Grade.distancia(melhor, alvos[0].pos):
					melhor = p
			if melhor != u.pos and not _tentou.has(chave + ":m%d" % u.acoes_mov):
				_tentou[chave + ":m%d" % u.acoes_mov] = true
				return ["heroi_mover", [melhor]]
			return ["encerrar_turno", []]
		F.HEROI_ATACANDO, F.HEROI_DEFENDENDO, F.INTERACAO_TESTE:
			if b.vantagem_pendente():
				return ["heroi_vantagem_confirmar", []]
			var t = b.teste_do_heroi()
			if t != null and t.soma_cartas() < 16 and t.pode_puxar():
				return ["puxar", []]
			return ["parar", []]
		F.RESOLVIDO, F.INTERACAO_RESOLVIDA:
			return ["continuar", []]
		F.DISTRIBUINDO_DANO:
			var s: Dictionary = b.sugestao_distribuicao()
			return ["heroi_distribuir_dano", [s["escudo"], s["armadura"]]]
		F.PERGUNTA:
			return ["heroi_responder", [str(b.pergunta["opcoes"][0][0])]]
		F.SOMBRA_ESCOLHA:
			return ["heroi_sombra", [false]]
		F.ACAO_LONGA:
			return ["heroi_acao_longa", [false]]
	return []
