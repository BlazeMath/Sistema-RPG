## Terceira missão (PROVISÓRIA): o Pântano dos Afogados (0.17).
##
## Gente da aldeia de Brejo Fundo some à noite no pântano. A Bruxa Morgana afoga os
## viajantes e os levanta como afogados; os fantasmas das vítimas vagam pelas ruínas.
##
## Noite de lua: tudo fica pelo menos na penumbra (cobertura parcial contra ataques de
## longe). Fogos-fátuos e fogueiras iluminam. Lodo é terreno difícil; neblina dá
## cobertura. Os fantasmas flutuam sobre a água; os afogados nadam.
##
## Ordem (filosofia do Lucas): obstáculo (afogados no lago) → combate simples (fantasmas
## nas ruínas) → descanso (cabana do eremita) → elite com escolta (a Bruxa Morgana).
## A Bruxa é a primeira inimiga que CONJURA: Mana Densa e Contramagia agora servem.
extends RefCounted

const Combate := preload("res://core/combate.gd")
const Dados := preload("res://core/dados_batalha.gd")
const Encontros := preload("res://core/encontros.gd")
const Exploracao := preload("res://core/dados_exploracao.gd")

const LARGURA := 36
const ALTURA := 24

const AFOGADO := {"categoria": "morto-vivo", "visao_no_escuro": true, "tipo_dano": "Concussão", "velocidade": 2,
	"fraquezas": {"Fogo": 2, "Radiante": 2}, "ao_acertar": [{"ficha": "Imobilizar", "max": 1}]}
const FANTASMA := {"categoria": "morto-vivo", "visao_no_escuro": true, "tipo_dano": "Necrótico", "flutua": true,
	"fraquezas": {"Radiante": 3, "Fogo": 1}, "resiste_tipo": {"Corte": 2, "Perfuração": 2, "Concussão": 2},
	"ao_acertar": [{"ficha": "Medo"}]}

static var CAL_VIDA_BRUXA := 1.6
static var CAL_DANO_BRUXA := 1.0

## Magias da Bruxa (Batalha._ia_conjurar).
const MAGIAS_BRUXA := [
	{"id": "maldicao", "nome": "Maldição do Lodo", "tipo": "ficha", "ficha": "Penalidade", "qtd": 1, "alcance": 8,
		"resistir": "espirito", "dif": 16},
	{"id": "raio", "nome": "Raio de Lodo", "tipo": "ataque", "alcance": 8, "tipo_dano": "Necrótico", "ficha": "Imobilizar"},
]


static func _com(base: Dictionary, extra: Dictionary) -> Dictionary:
	var d := base.duplicate(true)
	d.merge(extra, true)
	return d


static func _ef(tipo: String, extra := {}) -> Dictionary:
	return Exploracao._ef(tipo, extra)


static func _ret(x1: int, y1: int, x2: int, y2: int) -> Array:
	var l := []
	for x in range(x1, x2 + 1):
		for y in range(y1, y2 + 1):
			l.append(Vector2i(x, y))
	return l


static func missao(fichas) -> Dictionary:
	var n := Dados._quantos(fichas)
	var o := {}
	var deco := {}
	# Rios: um em x 8-9 (ponte em y 11-12) e outro em x 26-27 (ponte em y 8-9)
	for y in ALTURA:
		for x in [8, 9]:
			if y != 11 and y != 12:
				o[Vector2i(x, y)] = "agua"
			else:
				deco[Vector2i(x, y)] = "ponte"
		for x in [26, 27]:
			if y != 8 and y != 9:
				o[Vector2i(x, y)] = "agua"
			else:
				deco[Vector2i(x, y)] = "ponte"
	# Lago dos afogados
	for p in _ret(12, 3, 16, 6):
		o[p] = "agua"
	# Ruínas da capela (paredes quebradas)
	for p in [Vector2i(18, 14), Vector2i(19, 14), Vector2i(21, 14), Vector2i(24, 14), Vector2i(18, 15), Vector2i(18, 17),
			Vector2i(18, 19), Vector2i(19, 20), Vector2i(22, 20), Vector2i(24, 20), Vector2i(24, 18), Vector2i(24, 16)]:
		o[p] = "rocha"
	# Cabana do eremita
	for p in [Vector2i(20, 3), Vector2i(21, 3), Vector2i(23, 3)]:
		o[p] = "casa"
	o[Vector2i(22, 5)] = "fogueira"
	# Cabana da bruxa
	for p in [Vector2i(31, 5), Vector2i(32, 5), Vector2i(33, 5), Vector2i(34, 5), Vector2i(34, 6), Vector2i(34, 7)]:
		o[p] = "casa"
	o[Vector2i(32, 11)] = "fogueira"   # caldeirão
	# Árvores mortas
	for p in [Vector2i(1, 2), Vector2i(4, 4), Vector2i(2, 19), Vector2i(5, 16), Vector2i(11, 9), Vector2i(13, 15), Vector2i(16, 10),
			Vector2i(11, 21), Vector2i(23, 10), Vector2i(29, 2), Vector2i(30, 20), Vector2i(35, 14), Vector2i(29, 15)]:
		o[p] = "arvore"
	o[Vector2i(12, 20)] = "saco"   # o barco afundado (casco)

	var unidades := Dados.herois_cfg(fichas, [Vector2i(2, 11), Vector2i(2, 12), Vector2i(3, 11), Vector2i(3, 12)])
	# Lago: obstáculo de afogados (submersos: emergem quando alguém chega perto).
	var casas_lago := [Vector2i(11, 4), Vector2i(17, 4), Vector2i(12, 7), Vector2i(16, 7), Vector2i(14, 7), Vector2i(11, 6),
		Vector2i(17, 6), Vector2i(13, 2), Vector2i(15, 2), Vector2i(11, 2)]
	var k_lac: int = Encontros.composicao("obstaculo", n)["lacaio"]
	for k in mini(k_lac, casas_lago.size()):
		unidades.append(Dados.inimigo_de("afogado%d" % (k + 1), "Afogado", "afogado", casas_lago[k], "lacaio", "aggro", n,
			_com(AFOGADO, {"alerta": false, "vigia": 2, "grupo": "lago", "dormindo": true})))
	# Ruínas: combate simples (fantasmas médios e afogados lacaios).
	var casas_f := [Vector2i(20, 16), Vector2i(22, 18), Vector2i(21, 17), Vector2i(23, 15)]
	var casas_a := [Vector2i(19, 18), Vector2i(23, 19), Vector2i(20, 19), Vector2i(22, 15)]
	for k in mini(n, casas_f.size()):
		unidades.append(Encontros.para_combate(Dados.inimigo_de("fantasma%d" % (k + 1), "Fantasma Afogado", "fantasma", casas_f[k], "medio",
			"control" if k % 2 == 0 else "aggro", n, _com(FANTASMA, {"alerta": false, "vigia": 4, "grupo": "ruinas"})), "simples"))
	for k in mini(n, casas_a.size()):
		unidades.append(Encontros.para_combate(Dados.inimigo_de("afogado_r%d" % (k + 1), "Afogado", "afogado", casas_a[k], "lacaio", "aggro", n,
			_com(AFOGADO, {"alerta": false, "vigia": 4, "grupo": "ruinas"})), "simples"))
	# Cabana da bruxa: elite com escolta (a Bruxa conjura; escolta de afogados e um fantasma).
	var bruxa := Dados.inimigo_de("morgana", "Bruxa Morgana", "bruxa", Vector2i(32, 9), "elite_escoltado", "neutro", n,
		{"alerta": false, "vigia": 6, "grupo": "bruxa", "categoria": "humanoide", "visao_no_escuro": true,
			"a_distancia": true, "faixas_ideais": [Combate.Faixa.CURTO, Combate.Faixa.MEDIO], "perfil_id": "atirador",
			"tipo_dano": "Necrótico", "magias": MAGIAS_BRUXA.duplicate(true), "fraquezas": {"Fogo": 2},
			"habilidades": [{"tipo": "ovo", "a_cada": 3}, {"tipo": "teleporte", "a_cada": 3,
				"texto": "Morgana se desfaz numa poça de lodo e brota do outro lado, longe das lâminas."}]})
	# Calibragem pela simulação (0.17): a escolta do pântano é lenta (afogados) e a maldição
	# não causa dano, então a Bruxa tem mais vida e dano que o elite escoltado comum.
	bruxa["vida"] = int(round(int(bruxa["vida"]) * CAL_VIDA_BRUXA))
	bruxa["dano"] = int(round(int(bruxa["dano"]) * CAL_DANO_BRUXA))
	bruxa["foco"] = {"dano": int(bruxa["dano"]), "nome": "magia do pântano"}
	bruxa["sabedoria"] = 3
	unidades.append(bruxa)
	var comp: Dictionary = Encontros.composicao("elite_escoltado", n)
	var casas_e := [Vector2i(30, 8), Vector2i(30, 11), Vector2i(31, 13), Vector2i(33, 13)]
	for k in mini(int(comp.get("lacaio", 1)), 2):
		unidades.append(Dados.inimigo_de("guarda_a%d" % (k + 1), "Afogado", "afogado", casas_e[k], "lacaio", "tank", n,
			_com(AFOGADO, {"alerta": false, "vigia": 6, "grupo": "bruxa", "escolta": "morgana"})))
	for k in mini(int(comp.get("medio", 1)), 2):
		unidades.append(Dados.inimigo_de("guarda_f%d" % (k + 1), "Fantasma Afogado", "fantasma", casas_e[2 + k], "medio", "aggro", n,
			_com(FANTASMA, {"alerta": false, "vigia": 6, "grupo": "bruxa", "escolta": "morgana"})))
	return {
		"nome": "Missão: o Pântano dos Afogados",
		"objetivo": "Atravesse o pântano à noite e acabe com a Bruxa Morgana.",
		"vitoria_ao_derrotar_todos": false,
		"vitoria_se_morrer": ["morgana"],
		"mensagem_vitoria": "A Bruxa Morgana cai no próprio caldeirão. Os afogados afundam de vez, e Brejo Fundo pode voltar a dormir.",
		"largura": LARGURA, "altura": ALTURA, "obstaculos": o, "decoracao": deco,
		"grupos": {"lago": {"titulo": "Afogados", "texto": "A água do lago borbulha. Mãos inchadas agarram a margem.", "alerta": false},
			"ruinas": {"titulo": "As ruínas assombradas", "texto": "Vultos pálidos flutuam entre as pedras caídas. Afogados se arrastam atrás deles."},
			"bruxa": {"titulo": "A Bruxa Morgana", "texto": "Na porta da cabana, uma mulher de cabelos cheios de lodo sorri. \"Mais ossos para o meu pântano.\" Os servos dela se juntam às suas costas."}},
		"escuro": true, "luz_ambiente": 1, "piso": "lodo", "recompensa": 150,
		"luzes": [{"pos": Vector2i(14, 9), "claro": 2, "penumbra": 3, "nome": "fogo-fátuo"},
			{"pos": Vector2i(19, 11), "claro": 2, "penumbra": 3, "nome": "fogo-fátuo"},
			{"pos": Vector2i(28, 17), "claro": 2, "penumbra": 3, "nome": "fogo-fátuo"}],
		"zonas": [
			{"tipo": "lodo", "nome": "Lodo", "celulas": _ret(10, 8, 17, 10) + _ret(19, 9, 24, 12) + _ret(28, 14, 33, 19),
				"opcoes": {"vinculada": false, "rodadas": -1, "terreno_dificil": true}},
			{"tipo": "fumaca", "nome": "Neblina", "celulas": _ret(28, 6, 31, 12),
				"opcoes": {"vinculada": false, "rodadas": -1, "cobertura": 1}},
		],
		"unidades": unidades,
		"interacoes": [_barqueiro(), _eremita(), _fogueira(), _barco(), _altar_ruinas(),
			Exploracao.arvore_frutifera("amoreira", Vector2i(11, 9), "Amoreira do brejo", "antidoto"),
			Exploracao.pedra_alta("coluna", Vector2i(20, 15), "Coluna caída"),
			Exploracao.movel_com_itens("cesto", Vector2i(6, 10), "Cesto de pesca",
				"Um cesto de vime largo na margem, com redes e um embrulho.", ["racao_de_viagem", "tocha"]),
			Exploracao.estante_lore("livros_eremita", Vector2i(22, 3), "Livros do eremita",
				"Livros inchados de umidade, empilhados numa prateleira torta.",
				"O eremita anotou tudo: Morgana era a curandeira de Brejo Fundo. Quando a febre matou as crianças, a vila a afogou no lago. Ela voltou na primavera seguinte, e o lago voltou com ela.",
				[], "Ocultismo"),
			Exploracao.estante_lore("diario_morgana", Vector2i(33, 6), "Diário de Morgana",
				"Um caderno de capa de couro sobre a mesa da cabana, ao lado do caldeirão.",
				"A última página: \"Os grãos de Rio Raso já apodrecem nos silos. Quando a fome chegar, os mortos não vão faltar. Ele prometeu.\" Quem é \"ele\"?",
				[], "Ocultismo"),
			Exploracao.ponto_de_descanso("descanso_clareira", Vector2i(24, 22), "Clareira seca",
				"Um pedaço de chão firme entre os juncos, com uma pedra lisa para sentar.")],
	}


static func _barqueiro() -> Dictionary:
	return {"id": "barqueiro", "nome": "Barqueiro de Brejo Fundo", "pos": Vector2i(4, 8), "alcance": 1,
		"texto": "Um velho de capuz espera junto a uma vara de pescar. \"Ninguém atravessa o pântano de noite. Mas se vão, levem fogo: os afogados odeiam fogo.\"",
		"opcoes": [
			{"id": "conversar", "texto": "Perguntar sobre a bruxa", "custo": {"padrao": 1},
				"abordagens": [
					{"id": "diplomacia", "texto": "com respeito (Diplomacia)", "teste": {"somar": ["diplomacia"]}, "nivel": "facil",
						"resultados": {
							"falha": {"rotulo": "calado", "texto": "Ele só aponta para leste.", "efeitos": [_ef("desativar_opcao", {"opcao": "conversar"})]},
							"sucesso": {"rotulo": "conselho", "texto": "\"A Morgana amaldiçoa de longe e faz o lodo prender as pernas. Quem sabe magia pode cortar a dela no ar.\" Ele dá duas tochas e um antídoto.",
								"efeitos": [_ef("item", {"item": "tocha", "qtd": 2}), _ef("item", {"item": "antidoto"}), _ef("desativar_opcao", {"opcao": "conversar"})]},
						}},
					{"id": "ocultismo", "texto": "falando de magia (Ocultismo + Raciocínio)", "teste": {"somar": ["Ocultismo", "raciocinio"]}, "nivel": "medio",
						"resultados": {
							"falha": {"rotulo": "nada", "texto": "Ele não entende do que você fala.", "efeitos": [_ef("desativar_opcao", {"opcao": "conversar"})]},
							"sucesso": {"rotulo": "a bruxa", "texto": "Pelos sinais, a Morgana tira força do caldeirão. Fogo e luz sagrada ferem os afogados e os fantasmas. Vocês chegam preparados.",
								"efeitos": [_ef("fichas_grupo", {"ficha": "Foco"}), _ef("marcar", {"id": "morgana"}), _ef("desativar_opcao", {"opcao": "conversar"})]},
						}},
				]},
		]}


static func _eremita() -> Dictionary:
	return {"id": "eremita", "nome": "Cabana do eremita", "pos": Vector2i(21, 4), "alcance": 1,
		"texto": "Uma cabana torta, com ervas penduradas. O eremita fugiu, mas deixou o fogo aceso.",
		"opcoes": [
			{"id": "ervas", "texto": "Procurar ervas e remédios", "custo": {"padrao": 1}, "teste": {"somar": ["Natureza", "sabedoria"]}, "nivel": "facil", "tags": ["procurar"],
				"resultados": {
					"falha": {"rotulo": "mato", "texto": "Só mato seco.", "efeitos": [_ef("desativar_opcao", {"opcao": "ervas"})]},
					"sucesso": {"rotulo": "remédios", "texto": "Um kit médico e uma poção.", "efeitos": [_ef("item", {"item": "kit_medico"}), _ef("item", {"item": "pocao_de_cura_pequena"}), _ef("desativar_opcao", {"opcao": "ervas"})]},
				}},
		]}


static func _fogueira() -> Dictionary:
	return {"id": "fogueira_eremita", "nome": "Fogueira do eremita", "pos": Vector2i(22, 5), "alcance": 1,
		"texto": "O fogo espanta o frio do pântano. Um bom lugar para recuperar o fôlego.",
		"opcoes": [
			{"id": "descansar", "texto": "Descanso curto do grupo (o turno inteiro)", "custo": {"turno": true}, "sem_alerta": true, "resultado": "descanso",
				"resultados": {"descanso": {"texto": "O grupo descansa junto ao fogo (todos a até 4 quadrados).",
					"efeitos": [_ef("descanso_curto"), _ef("desativar_opcao", {"opcao": "descansar"})]}}},
		]}


static func _barco() -> Dictionary:
	return {"id": "barco", "nome": "Barco afundado", "pos": Vector2i(12, 20), "alcance": 1,
		"texto": "O casco de um barco de carga, meio enterrado no lodo. As caixas ainda estão lacradas.",
		"opcoes": [
			{"id": "abrir", "texto": "Forçar as caixas", "custo": {"padrao": 1}, "teste": {"somar": ["Atletismo", "forca"]}, "nivel": "medio",
				"vantagem_com": ["pe_de_cabra"],
				"resultados": {
					"falha": {"rotulo": "presas", "texto": "As tábuas incham com a água e não cedem. Dá para tentar de novo."},
					"sucesso": {"rotulo": "carga", "texto": "Moedas da aldeia e um frasco de piche.",
						"efeitos": [_ef("ouro", {"valor": 45}), _ef("item", {"item": "frasco_de_piche"}), _ef("desativar")]},
				}},
		]}


static func _altar_ruinas() -> Dictionary:
	return {"id": "altar_ruinas", "nome": "Altar das ruínas", "pos": Vector2i(21, 19), "alcance": 1,
		"texto": "Um altar rachado, coberto de limo. Nomes de afogados foram riscados na pedra.",
		"opcoes": [
			{"id": "orar", "texto": "Rezar pelos afogados", "custo": {"padrao": 1}, "teste": {"somar": ["Religião", "espirito"]}, "nivel": "medio",
				"sem_alerta": "ruinas",
				"resultados": {
					"falha": {"rotulo": "silêncio", "texto": "Só o vento responde.", "efeitos": [_ef("desativar")]},
					"sucesso": {"rotulo": "paz", "texto": "Uma calma toma o grupo; cada herói por perto ganha 1 Preparo.",
						"efeitos": [_ef("fichas_grupo", {"ficha": "Preparo"}), _ef("ouro", {"valor": 10}), _ef("desativar")]},
				}},
		]}
