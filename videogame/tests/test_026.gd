## 0.26: jogo em rede. O que importa no motor: duas batalhas montadas do mesmo retrato,
## recebendo os mesmos comandos na mesma ordem, terminam idênticas (é assim que o
## anfitrião e os convidados ficam iguais). Também: quem decide cada momento, a party
## salva no anfitrião e a campanha só na memória dos convidados.
extends RefCounted

const Batalha := preload("res://core/batalha.gd")
const Dados := preload("res://core/dados_batalha.gd")
const Fazenda := preload("res://core/dados_fazenda.gd")
const Masmorra := preload("res://core/dados_masmorra.gd")
const Instantaneo := preload("res://core/instantaneo.gd")
const Personagem := preload("res://core/personagem.gd")
const Campanha := preload("res://core/campanha.gd")
const Prontos := preload("res://core/herois_prontos.gd")
const Party := preload("res://core/party.gd")
const Grade := preload("res://core/grade.gd")


func _fichas(classes: Array) -> Array:
	var lista := []
	for c in classes:
		var f := Prontos.ficha(c)
		f["nome"] = "%s da Rede" % c
		lista.append(f)
	return lista


## Monta como o anfitrião em rede: inicia, tira o retrato e recarrega dele; o convidado
## carrega o mesmo retrato numa batalha montada com as mesmas fichas.
func _par(montar: Callable, semente: int) -> Array:
	var a := Batalha.new(montar.call(), semente)
	a.defesa_automatica = false
	a.distribuicao_automatica = false
	a.perguntar_sombra = true
	a.perguntar_escolhas = true
	a.sustentar_automatico = false
	a.acoes_longas_automaticas = false
	a.iniciar()
	a.eventos.clear()
	var texto := Instantaneo.para_texto(a)
	var anfitriao := Batalha.new(montar.call(), semente)
	Instantaneo.aplicar_texto(anfitriao, texto)
	var convidado := Batalha.new(montar.call(), semente)
	Instantaneo.aplicar_texto(convidado, texto)
	return [anfitriao, convidado]


func _cod(v: Variant) -> Variant:
	if v is Object and v != null and v.has_method("eh_heroi"):
		return {"__u": v.id}
	if v is Array:
		return v.map(func(x): return _cod(x))
	return v


func _dec(b, v: Variant) -> Variant:
	if v is Dictionary and v.has("__u"):
		return b.unidade(v["__u"])
	if v is Array:
		return v.map(func(x): return _dec(b, x))
	return v


var _tentou := {}   # "id:rodada:acao" -> true (o jogador simples não repete a mesma tentativa)


## Um jogador simples decide o próximo comando (como os cliques da tela).
func _decidir(b) -> Array:
	var F := Batalha.Fase
	if b.fase_automatica():
		return ["passo_automatico", []]
	match b.fase:
		F.HEROI_ESCOLHE:
			var u = b.ativa()
			var alvos: Array = b.inimigos_vivos()
			if alvos.is_empty() or u.acoes_padrao <= 0 and u.acoes_mov <= 0:
				return ["encerrar_turno", []]
			alvos.sort_custom(func(x, y): return Grade.distancia(u.pos, x.pos) < Grade.distancia(u.pos, y.pos))
			var chave := "%s:%d:%d" % [u.id, b.rodada, u.acoes_padrao]
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


## Joga até o fim (ou n comandos) no anfitrião e repete os mesmos comandos no convidado.
func _jogar_em_par(t, par: Array, n: int, nome: String) -> void:
	_tentou = {}
	var a = par[0]
	var c = par[1]
	var feitos := 0
	var conferidos := 0
	for i in n:
		if a.fase in [Batalha.Fase.VITORIA, Batalha.Fase.DERROTA]:
			break
		var cmd := _decidir(a)
		if cmd.is_empty():
			break
		var args: Array = _cod(cmd[1])
		a.callv(cmd[0], _dec(a, args))
		c.callv(cmd[0], _dec(c, args))
		feitos += 1
		a.eventos.clear()
		c.eventos.clear()
		if i % 25 == 0:
			conferidos += 1
			if Instantaneo.para_texto(a) != Instantaneo.para_texto(c):
				t.ok(false, "%s: estados diferentes depois do comando %d (%s)" % [nome, i, cmd[0]])
				return
	t.ok(feitos > 30, "%s: a partida andou (%d comandos)" % [nome, feitos])
	t.igual(Instantaneo.para_texto(a), Instantaneo.para_texto(c), "%s: anfitrião e convidado terminam iguais" % nome)
	t.igual(a.rng.state, c.rng.state, "%s: mesmo gerador" % nome)


func test_rede_arena_identica(t) -> void:
	var fichas := _fichas(["Guerreiro", "Mago", "Bruxo"])
	_jogar_em_par(t, _par(func(): return Dados.arena(fichas), 123), 900, "arena")


func test_rede_fazenda_identica(t) -> void:
	var fichas := _fichas(["Ladino", "Clérigo"])
	_jogar_em_par(t, _par(func(): return Fazenda.missao(fichas), 77), 900, "fazenda")


func test_rede_cripta_identica(t) -> void:
	var fichas := _fichas(["Caçador", "Guerreiro", "Clérigo", "Bruxo"])
	_jogar_em_par(t, _par(func(): return Masmorra.missao(fichas), 5), 700, "cripta")


func test_quem_decide(t) -> void:
	var fichas := _fichas(["Guerreiro", "Mago"])
	var b := Batalha.new(Dados.arena(fichas, false), 9)
	b.iniciar()
	b.indice_vez = b.ordem.find("heroi2")
	b._comecar_turno()
	t.igual(b.quem_decide(), "heroi2", "na vez de um herói, decide o dono dele")
	b.perguntar("guarda", "?", [["sim", "s"], ["nao", "n"]], {"quem": "heroi2", "guarda": "heroi"})
	t.igual(b.quem_decide(), "heroi", "Guarda: decide quem tem a ficha")
	b.fase = b.pergunta["volta"]
	b.pergunta = {}
	b.indice_vez = b.ordem.find("goblin1")
	b._comecar_turno()
	if b.fase_automatica():
		t.igual(b.quem_decide(), "", "vez dos monstros: ninguém (o anfitrião)")
	b.fase = Batalha.Fase.VITORIA
	t.igual(b.quem_decide(), "", "fim de jogo: ninguém")


func test_party_no_anfitriao(t) -> void:
	var nome := "Teste de Rede 026"
	Party.apagar(Party.id_de(nome))
	var p := Party.criar(nome)
	t.ok(not p.is_empty(), "party criada")
	t.ok(Party.criar(nome).is_empty(), "nome repetido é recusado")
	var f := Prontos.ficha("Guerreiro")
	f["nome"] = "Herói Vinculado"
	t.igual(Party.vincular(p["id"], f, "Ana"), "", "vincula o herói de um jogador")
	t.ok(Party.vincular(p["id"], f, "Ana") != "", "o mesmo herói não entra duas vezes")
	var p2 := Party.carregar(p["id"])
	t.igual(p2["membros"].size(), 1, "membro guardado")
	t.igual(str(p2["membros"][0]["jogador"]), "Ana", "com o nome do jogador")
	t.igual(Party.fichas(p["id"]).size(), 1, "a ficha fica no computador do anfitrião")
	# Campanha e heróis apontam para a pasta da party enquanto ela está aberta.
	Party.abrir(p["id"])
	t.igual(Personagem.carregar_todos().size(), 1, "heróis da party")
	t.igual(Campanha.dinheiro(), Campanha.DINHEIRO_INICIAL, "campanha nova da party")
	var r = Campanha.executar("comprar_item", ["Herói Vinculado", "lanca"])
	t.igual(str(r), "", "compra pela party (%s)" % str(r))
	t.ok(Campanha.dinheiro() < Campanha.DINHEIRO_INICIAL, "a bolsa da party paga")
	Party.fechar()
	Party.abrir(p["id"])
	t.ok(Campanha.dinheiro() < Campanha.DINHEIRO_INICIAL, "a compra ficou salva na party")
	Party.fechar()
	t.igual(Personagem.arquivo, Personagem.ARQUIVO, "fechar volta aos heróis normais")
	Party.desvincular(p["id"], "Herói Vinculado")
	t.igual(Party.carregar(p["id"])["membros"].size(), 0, "desvincular tira o herói")
	Party.apagar(p["id"])
	t.ok(Party.carregar(p["id"]).is_empty(), "party apagada")


func test_campanha_na_memoria(t) -> void:
	var f := Prontos.ficha("Ladino")
	f["nome"] = "Convidado"
	Personagem.memoria = [f]
	Campanha.memoria = true
	Campanha.dados = Campanha._novos_dados()
	Campanha.dados["cobre"] = 1234
	t.igual(Campanha.dinheiro(), 1234, "convidado lê a bolsa que o anfitrião mandou")
	Campanha.salvar()
	t.igual(Personagem.carregar_todos().size(), 1, "heróis da party vêm da memória")
	var lista := Personagem.carregar_todos()
	lista[0]["xp"] = 99
	t.ok(int(Personagem.carregar_todos()[0]["xp"]) != 99, "carregar devolve cópia")
	Personagem.salvar_todos(lista)
	t.igual(int(Personagem.carregar_todos()[0]["xp"]), 99, "salvar fica só na memória")
	Party.fechar()
	t.ok(Personagem.memoria == null and not Campanha.memoria, "fora da rede volta ao disco")
