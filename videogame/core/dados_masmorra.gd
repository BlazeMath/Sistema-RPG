## Segunda missão (PROVISÓRIA): a cripta sob a capela de Pedravelha (0.15).
##
## A guilda é contratada porque os mortos da cripta da capela velha estão se
## levantando. Goblins acamparam no salão de cima e saqueiam as tumbas. No fundo,
## Sir Aldric, um cavaleiro enterrado com a espada, voltou e comanda os ossos.
##
## Masmorra ESCURA (testa luz e visão): só a entrada, o salão dos goblins (fogueira)
## e a frente da cripta (braseiros) têm luz. Os heróis trazem lanternas (kit) e
## recebem tochas na entrada. Esqueletos e goblins enxergam no escuro.
##
## Ordem dos combates (filosofia do Lucas): obstáculo (ossário) → combate simples
## (salão dos goblins) → descanso curto (capela) → chefe (cripta).
## Mapa 40 × 24: salas abertas em um bloco de pedra.
extends RefCounted

const Combate := preload("res://core/combate.gd")
const Dados := preload("res://core/dados_batalha.gd")
const Encontros := preload("res://core/encontros.gd")
const Exploracao := preload("res://core/dados_exploracao.gd")

const LARGURA := 40
const ALTURA := 24

## Salas: [x1, y1, x2, y2] inclusive (o resto é parede).
const SALAS := {
	"entrada": [1, 9, 6, 14],
	"corredor_a": [7, 11, 10, 12],
	"ossario": [11, 7, 19, 16],
	"corredor_n": [14, 5, 15, 6],
	"salao": [10, 1, 21, 4],
	"corredor_e": [20, 11, 22, 12],
	"capela": [23, 8, 28, 15],
	"corredor_c": [29, 11, 30, 12],
	"cripta": [31, 3, 38, 20],
	"corredor_s": [15, 17, 16, 18],
	"tesouro": [12, 19, 19, 22],
}

## Esqueleto: morto-vivo; fraco contra Concussão e Radiante, resiste a Perfuração.
const ESQUELETO := {"categoria": "morto-vivo", "visao_no_escuro": true, "tipo_dano": "Corte",
	"fraquezas": {"Concussão": 2, "Radiante": 2}, "resiste_tipo": {"Perfuração": 2}}


static func _com(base: Dictionary, extra: Dictionary) -> Dictionary:
	var d := base.duplicate(true)
	d.merge(extra, true)
	return d


static func _ef(tipo: String, extra := {}) -> Dictionary:
	return Exploracao._ef(tipo, extra)


static func missao(fichas) -> Dictionary:
	var n := Dados._quantos(fichas)
	var o := {}
	for x in LARGURA:
		for y in ALTURA:
			o[Vector2i(x, y)] = "parede"
	for nome in SALAS:
		var r: Array = SALAS[nome]
		for x in range(r[0], r[2] + 1):
			for y in range(r[1], r[3] + 1):
				o.erase(Vector2i(x, y))
	# Luz e decoração
	for p in [Vector2i(3, 8), Vector2i(3, 15)]:
		o[p] = "tocha_parede"
	o[Vector2i(15, 2)] = "fogueira"
	for p in [Vector2i(12, 2), Vector2i(18, 3)]:
		o[p] = "mesa"
	o[Vector2i(21, 1)] = "bau"
	for p in [Vector2i(13, 9), Vector2i(13, 14), Vector2i(17, 9), Vector2i(17, 14)]:
		o[p] = "sarcofago"
	for p in [Vector2i(15, 9), Vector2i(15, 14)]:
		o[p] = "pilar"
	o[Vector2i(24, 9)] = "fonte"
	o[Vector2i(27, 11)] = "altar"
	o[Vector2i(30, 11)] = "porta"
	o[Vector2i(30, 12)] = "porta"
	for p in [Vector2i(32, 6), Vector2i(32, 17)]:
		o[p] = "fogueira"
	for p in [Vector2i(34, 7), Vector2i(34, 16), Vector2i(37, 7), Vector2i(37, 16)]:
		o[p] = "pilar"
	o[Vector2i(38, 11)] = "sarcofago"
	o[Vector2i(18, 21)] = "bau"

	var unidades := Dados.herois_cfg(fichas, [Vector2i(2, 11), Vector2i(2, 12), Vector2i(3, 11), Vector2i(3, 12)])
	# Ossário: obstáculo de esqueletos lacaios (deitados: acordam quando alguém chega perto).
	var casas_ossario := [Vector2i(12, 8), Vector2i(18, 8), Vector2i(12, 15), Vector2i(18, 15), Vector2i(16, 8),
		Vector2i(14, 15), Vector2i(19, 11), Vector2i(19, 12), Vector2i(14, 8), Vector2i(16, 15), Vector2i(11, 7), Vector2i(19, 16)]
	var ossos := _com(ESQUELETO, {"alerta": false, "vigia": 3, "grupo": "ossario", "dormindo": true})
	var k_lac: int = Encontros.composicao("obstaculo", n)["lacaio"]
	for k in mini(k_lac, casas_ossario.size()):
		var arqueiro := k % 4 == 3
		var extra := _com(ossos, {"a_distancia": true, "faixas_ideais": [Combate.Faixa.CURTO, Combate.Faixa.MEDIO],
			"perfil_id": "atirador", "tipo_dano": "Perfuração"}) if arqueiro else ossos
		unidades.append(Dados.inimigo_de("esqueleto%d" % (k + 1), "Esqueleto Arqueiro" if arqueiro else "Esqueleto",
			"esqueleto_arqueiro" if arqueiro else "esqueleto", casas_ossario[k], "lacaio", "aggro", n, extra))
	# Salão: combate simples de goblins saqueadores (lacaios = heróis, médios = heróis).
	var goblin := {"alerta": false, "vigia": 4, "grupo": "salao"}
	var medios := [
		["saqueador", "Goblin Brigão", "goblin", Vector2i(14, 3), "tank", {}],
		["arqueiro_g", "Goblin Atirador", "goblin_atirador", Vector2i(19, 2), "aggro",
			{"a_distancia": true, "faixas_ideais": [Combate.Faixa.CURTO, Combate.Faixa.MEDIO], "perfil_id": "atirador"}],
		["saqueador2", "Goblin Brigão", "goblin", Vector2i(17, 3), "tank", {}],
		["arqueiro_g2", "Goblin Atirador", "goblin_atirador", Vector2i(11, 1), "aggro",
			{"a_distancia": true, "faixas_ideais": [Combate.Faixa.CURTO, Combate.Faixa.MEDIO], "perfil_id": "atirador"}],
	]
	for k in mini(n, medios.size()):
		var m: Array = medios[k]
		unidades.append(Encontros.para_combate(Dados.inimigo_de(m[0], m[1], m[2], m[3], "medio", m[4], n, _com(goblin, m[5])), "simples"))
	var casas_salao := [Vector2i(13, 1), Vector2i(16, 1), Vector2i(17, 4), Vector2i(11, 3)]
	for k in mini(n, casas_salao.size()):
		unidades.append(Encontros.para_combate(Dados.inimigo_de("ladrao%d" % (k + 1), "Goblin Ladrão de Tumbas", "goblin", casas_salao[k],
			"lacaio", "aggro", n, _com(goblin, Dados.FUGA_COVARDE)), "simples"))
	# Cripta: o chefe e a guarda de ossos (médios).
	var guarda := _com(ESQUELETO, {"alerta": false, "vigia": 5, "grupo": "cripta"})
	unidades.append(Dados.inimigo_de("aldric", "Sir Aldric, o Cavaleiro Ossudo", "cavaleiro_ossudo", Vector2i(36, 11), "chefe", "neutro", n,
		_com(guarda, {"tamanho": "grande", "ataque_oportunidade": true, "fraquezas": {"Concussão": 2, "Radiante": 3},
			"habilidades": [{"tipo": "muralha", "a_cada": 3},
				{"tipo": "marcar_area", "nome": "Golpe Giratório", "raio": 1, "dano": 8, "a_cada": 3, "tipo_dano": "Corte",
					"aviso": "Sir Aldric ergue o machado acima da cabeça e gira o corpo: as casas marcadas vão ser varridas no próximo turno dele."}],
			"resiste_tipo": {"Perfuração": 2}})))
	var casas_guarda := [Vector2i(35, 9), Vector2i(35, 14), Vector2i(37, 9), Vector2i(37, 14)]
	var k_guarda: int = Encontros.composicao("chefe", n)["medio"]
	for k in mini(k_guarda, casas_guarda.size()):
		unidades.append(Dados.inimigo_de("guarda%d" % (k + 1), "Guarda de Ossos", "esqueleto", casas_guarda[k], "medio", "tank", n, guarda))
	# Cenário interativo (0.19)
	o[Vector2i(11, 9)] = "estante"
	o[Vector2i(1, 9)] = "bau"
	o[Vector2i(36, 12)] = "pedra_alta"
	o[Vector2i(33, 4)] = "mesa"
	return {
		"nome": "Missão: a cripta de Pedravelha",
		"objetivo": "Desça à cripta sob a capela velha e faça os mortos descansarem de novo.",
		"vitoria_ao_derrotar_todos": false,
		"vitoria_se_morrer": ["aldric"],
		"mensagem_vitoria": "Sir Aldric cai, e os ossos da cripta param de se mexer. A capela de Pedravelha volta a ficar em silêncio.",
		"largura": LARGURA, "altura": ALTURA, "obstaculos": o,
		"grupos": {"ossario": {"titulo": "Os ossos acordam", "texto": "Os esqueletos deitados entre os ossos se levantam com um estalo, um depois do outro.", "alerta": false},
			"salao": {"titulo": "Saqueadores", "texto": "Goblins com sacos cheios de ossos e castiçais. Eles largam tudo e puxam as facas."},
			"cripta": {"titulo": "Sir Aldric", "texto": "O cavaleiro de ossos ergue o machado. \"Quem perturba o meu descanso paga com o seu.\""}},
		"escuro": true, "piso": "pedra", "recompensa": 120,
		"gatilhos": _gatilhos(), "armadilhas": _armadilhas_cripta(),
		"luzes": [{"pos": Vector2i(27, 11), "claro": 1, "penumbra": 3, "nome": "velas do altar"}],
		"unidades": unidades,
		"interacoes": [_suportes(), _inscricao(), _sarcofago(), _bau_goblin(), _armadilha(), _bau_tesouro(), _fonte(), _altar(), _porta(),
			Exploracao.estante_lore("registros", Vector2i(11, 9), "Estante de registros",
				"Livros de enterro da capela, cheios de mofo.",
				"O último registro fala de Sir Aldric, cavaleiro da vila, enterrado há cem anos. Alguém escreveu depois, com outra letra: \"Os ossos dele foram pedidos. Pagamos com lodo.\"",
				[], "História"),
			Exploracao.movel_com_itens("bau_coveiro", Vector2i(1, 9), "Baú do coveiro",
				"O baú de ferramentas do coveiro, com cadeado quebrado.", ["oleo_antiespectral", "tocha"]),
			Exploracao.pedra_alta("escombros", Vector2i(36, 12), "Monte de escombros"),
			Exploracao.estante_lore("carta_lodo", Vector2i(33, 4), "Cartas sobre a mesa",
				"Cartas molhadas, com cheiro de brejo, presas sob um castiçal.",
				"As cartas são assinadas por \"M.\", de Brejo Fundo: \"Os ossos que você me der, eu devolvo de pé.\" Quem acorda os mortos de Pedravelha mora no pântano.",
				[], "Ocultismo"),
			Exploracao.ponto_de_descanso("descanso_nicho", Vector2i(14, 20), "Nicho seco",
				"Um nicho de pedra seca, longe das tumbas, com restos de uma fogueira de coveiro.")],
	}


# --- Entrada ---------------------------------------------------------------------

## 0.23: textos das salas e armadilhas (procurar ao entrar).
static func _sala(id: String) -> Array:
	var r: Array = SALAS[id]
	var l := []
	for x in range(r[0], r[2] + 1):
		for y in range(r[1], r[3] + 1):
			l.append(Vector2i(x, y))
	return l


static func _gatilhos() -> Array:
	var t := {
		"ossario": ["O ossário", "Prateleiras de crânios até o teto e ossos espalhados pelo chão. Alguns estão arrumados demais, como se esperassem alguém."],
		"salao": ["O salão dos saqueadores", "Restos de fogueira, sacos rasgados e marcas de garra: goblins acamparam aqui. Ainda estão aqui."],
		"capela": ["A capela de baixo", "Uma capela pequena, com bancos de pedra. A água da fonte é limpa, estranhamente limpa."],
		"cripta": ["A cripta de Sir Aldric", "Um salão alto, com colunas e tochas que acendem sozinhas. No fundo, um cavaleiro de ossos de pé, à espera."],
		"tesouro": ["A sala do tesouro", "Uma sala baixa e seca. Algo brilha no canto."],
	}
	var l := []
	for id in t:
		l.append({"id": "g_" + id, "sala": id, "celulas": _sala(id), "titulo": t[id][0], "texto": t[id][1], "procurar": id != "cripta"})
	return l


static func _armadilhas_cripta() -> Array:
	return [
		{"id": "lajes", "sala": "ossario", "nome": "Laje solta", "celulas": [Vector2i(15, 12)], "dif_achar": 15, "dif_evitar": 16, "dif_desarmar": 15,
			"dano": 4, "texto": "Uma laje que balança, sobre um buraco cheio de ossos pontudos.", "texto_disparo": "A laje vira e você enfia a perna nos ossos."},
		{"id": "agulhas", "sala": "tesouro", "nome": "Agulhas no chão", "celulas": [Vector2i(15, 20), Vector2i(16, 20)], "dif_achar": 16, "dif_evitar": 16, "dif_desarmar": 16,
			"dano": 3, "ficha": "Veneno", "texto": "Agulhas finas, molhadas, saindo das frestas.", "texto_disparo": "Agulhas furam a bota. Arde."},
		{"id": "corredor_e", "sala": "corredor_e", "nome": "Fio de disparo", "celulas": [Vector2i(21, 11)], "dif_achar": 16, "dif_evitar": 15, "dif_desarmar": 14,
			"dano": 4, "texto": "Um fio preso a uma besta escondida na parede.", "texto_disparo": "Um virote sai da parede."},
	]


static func _suportes() -> Dictionary:
	return {"id": "suportes", "nome": "Suportes de tocha", "pos": Vector2i(3, 8), "alcance": 1,
		"texto": "Tochas novas, deixadas pelo sacristão que contratou a guilda. Lá dentro não há luz nenhuma.",
		"opcoes": [
			{"id": "pegar", "texto": "Pegar tochas (2 por herói)", "custo": {"movimento": 1}, "resultado": "pega",
				"resultados": {"pega": {"texto": "Você pega duas tochas. Acender custa uma ação e uma mão livre.",
					"efeitos": [_ef("item", {"item": "tocha", "qtd": 2})]}}},
		]}


static func _inscricao() -> Dictionary:
	return {"id": "inscricao", "nome": "Inscrição na entrada", "pos": Vector2i(3, 15), "alcance": 1,
		"texto": "Letras gastas na pedra, acima de um símbolo do sol: \"Aqui dormem os defensores de Pedravelha.\"",
		"opcoes": [
			{"id": "ler", "texto": "Estudar a inscrição", "custo": {"padrao": 1},
				"abordagens": [
					{"id": "religiao", "texto": "pelos ritos (Religião + Sabedoria)", "teste": {"somar": ["Religião", "sabedoria"]}, "nivel": "facil",
						"resultados": {
							"falha": {"rotulo": "ilegível", "texto": "As letras estão gastas demais.", "efeitos": [_ef("desativar")]},
							"sucesso": {"rotulo": "os ossos", "texto": "Ritos de enterro antigos: os mortos daqui foram enterrados sem bênção. Mortos-vivos são fracos contra luz sagrada (Radiante) e golpes que quebram ossos (Concussão); flechas e lâminas de ponta passam entre as costelas.",
								"efeitos": [_ef("fichas_grupo", {"ficha": "Foco"}), _ef("desativar")]},
						}},
					{"id": "historia", "texto": "pela história (História + Raciocínio)", "teste": {"somar": ["História", "raciocinio"]}, "nivel": "medio",
						"resultados": {
							"falha": {"rotulo": "nada", "texto": "Você não reconhece os nomes.", "efeitos": [_ef("desativar")]},
							"sucesso": {"rotulo": "Sir Aldric", "texto": "Um dos nomes é Sir Aldric, que morreu defendendo a vila. Foi enterrado com a espada, no fundo da cripta, atrás de uma porta trancada.",
								"efeitos": [_ef("marcar", {"id": "aldric"}), _ef("desativar")]},
						}},
				]},
		]}


# --- Ossário e tesouro -------------------------------------------------------------

static func _sarcofago() -> Dictionary:
	return {"id": "sarcofago_aberto", "nome": "Sarcófago aberto", "pos": Vector2i(13, 9), "alcance": 1,
		"texto": "A tampa foi empurrada por dentro. Ainda há panos e moedas no fundo.",
		"opcoes": [
			{"id": "revirar", "texto": "Revirar o sarcófago", "custo": {"padrao": 1}, "teste": {"somar": ["percepcao"]}, "nivel": "facil", "tags": ["procurar"],
				"resultados": {
					"falha": {"rotulo": "só panos", "texto": "Panos podres e pó.", "efeitos": [_ef("desativar")]},
					"sucesso": {"rotulo": "oferendas", "texto": "Moedas de oferenda e um frasco lacrado.",
						"efeitos": [_ef("ouro", {"valor": 15}), _ef("item", {"item": "pocao_de_cura_pequena"}), _ef("desativar")]},
				}},
		]}


static func _armadilha() -> Dictionary:
	return {"id": "piso", "nome": "Piso de lajes soltas", "pos": Vector2i(15, 17), "alcance": 1,
		"texto": "O corredor para a câmara do sul tem lajes diferentes das outras.",
		"opcoes": [
			{"id": "examinar", "texto": "Procurar armadilhas", "custo": {"padrao": 1}, "teste": {"somar": ["percepcao"]}, "nivel": "medio",
				"tags": ["procurar"], "vantagem_com": ["vara_de_3_metros"],
				"resultados": {
					"falha": {"rotulo": "dispara", "texto": "Uma laje afunda e lanças saem da parede!", "efeitos": [_ef("dano", {"valor": 6}), _ef("desativar")]},
					"sucesso": {"rotulo": "desarmada", "texto": "Você trava a laje com a faca. O caminho está seguro.", "efeitos": [_ef("desativar")]},
				}},
		]}


static func _bau_tesouro() -> Dictionary:
	return {"id": "tesouro", "nome": "Baú da capela", "pos": Vector2i(18, 21), "alcance": 1,
		"texto": "O tesouro que a capela guardava para os tempos ruins.",
		"opcoes": [
			{"id": "abrir", "texto": "Abrir o baú", "custo": {"padrao": 1}, "resultado": "abre",
				"resultados": {"abre": {"texto": "Moedas, um kit médico e uma bomba de fumaça.",
					"efeitos": [_ef("ouro", {"valor": 40}), _ef("item", {"item": "kit_medico"}), _ef("item", {"item": "bomba_de_fumaca"}), _ef("desativar")]}}},
		]}


# --- Salão dos goblins ----------------------------------------------------------------

static func _bau_goblin() -> Dictionary:
	return {"id": "bau_goblin", "nome": "Saque dos goblins", "pos": Vector2i(21, 1), "alcance": 1,
		"texto": "O que os goblins tiraram das tumbas: castiçais, anéis e moedas.",
		"opcoes": [
			{"id": "pegar", "texto": "Pegar o saque", "custo": {"padrao": 1}, "sem_alerta": "salao", "resultado": "pega",
				"resultados": {"pega": {"texto": "Vocês recolhem o saque (a guilda devolve o que for da capela).",
					"efeitos": [_ef("ouro", {"valor": 25}), _ef("item", {"item": "pocao_de_mana_pequena"}), _ef("desativar")]}}},
		]}


# --- Capela (descanso) e porta da cripta --------------------------------------------------

static func _fonte() -> Dictionary:
	return {"id": "fonte", "nome": "Fonte de água benta", "pos": Vector2i(24, 9), "alcance": 1,
		"texto": "Água limpa ainda corre na pia de pedra. O lugar parece protegido.",
		"opcoes": [
			{"id": "descansar", "texto": "Descanso curto do grupo (o turno inteiro)", "custo": {"turno": true}, "sem_alerta": true, "resultado": "descanso",
				"resultados": {"descanso": {"texto": "O grupo descansa junto à fonte (todos a até 4 quadrados).",
					"efeitos": [_ef("descanso_curto"), _ef("desativar_opcao", {"opcao": "descansar"})]}}},
		]}


static func _altar() -> Dictionary:
	return {"id": "altar", "nome": "Altar da capela", "pos": Vector2i(27, 11), "alcance": 1,
		"texto": "Velas meio derretidas iluminam um altar com o símbolo do sol.",
		"opcoes": [
			{"id": "orar", "texto": "Orar pelos mortos", "custo": {"padrao": 1}, "teste": {"somar": ["Religião", "espirito"]}, "nivel": "medio",
				"resultados": {
					"falha": {"rotulo": "silêncio", "texto": "Nada acontece.", "efeitos": [_ef("desativar")]},
					"sucesso": {"rotulo": "bênção", "texto": "Uma calma toma o grupo. Cada herói por perto ganha 1 ficha de Preparo.",
						"efeitos": [_ef("fichas_grupo", {"ficha": "Preparo"}), _ef("desativar")]},
				}},
		]}


static func _porta() -> Dictionary:
	var abre := _ef("abrir_caminho", {"celulas": [Vector2i(30, 11), Vector2i(30, 12)], "texto": "A porta da cripta se abre. Lá dentro, braseiros acendem sozinhos."})
	return {"id": "porta", "nome": "Porta da cripta", "pos": Vector2i(29, 11), "alcance": 1,
		"texto": "Uma porta de ferro trancada. Do outro lado, alguém arrasta uma espada pela pedra.",
		"opcoes": [
			{"id": "abrir", "texto": "Abrir a porta",
				"custo": {"padrao": 1},
				"abordagens": [
					{"id": "fechadura", "texto": "pela fechadura (Ladinagem + Destreza)", "teste": {"somar": ["Ladinagem", "destreza"]}, "nivel": "medio",
						"vantagem_com": ["ferramentas_de_ladrao"],
						"resultados": {
							"falha": {"rotulo": "emperra", "texto": "A fechadura não cede. Dá para tentar de novo."},
							"sucesso": {"rotulo": "aberta", "texto": "Clique. A porta abre sem barulho.", "efeitos": [abre, _ef("desativar")]},
						}},
					{"id": "arrombar", "texto": "arrombando (Atletismo + Força)", "teste": {"somar": ["Atletismo", "forca"]}, "nivel": "medio",
						"vantagem_com": ["pe_de_cabra"],
						"resultados": {
							"falha": {"rotulo": "aguenta", "texto": "A porta aguenta, e o barulho ecoa pela cripta.",
								"efeitos": [_ef("alertar", {"grupo": "cripta", "texto": "Na cripta, os ossos se levantam!"})]},
							"sucesso": {"rotulo": "arrombada", "texto": "A porta cai com estrondo.",
								"efeitos": [abre, _ef("alertar", {"grupo": "cripta", "texto": "O estrondo acorda a cripta!"}), _ef("desativar")]},
						}},
				]},
		]}
