## Cenário de exploração PROVISÓRIO: a trilha do riacho.
##
## O herói precisa recuperar a carroça de sementes que os goblins roubaram da
## fazenda. Para chegar lá: atravessar o riacho (nadar, saltar pelas pedras ou
## pela ponte quebrada), passar pelo paredão ou contornar os vigias.
##
## Formato de uma interação:
##   id, nome, pos (marcador), alcance (distância máxima do herói), texto
##   opcoes: [{id, texto, teste {atributo, pericia, movimento}, custo
##            {padrao | movimento | turno}, requer (item), consome (item),
##            vantagem_com [itens], sem_alerta, travessia, faixas [[mínimo, resultado]],
##            resultado (sem teste), resultados {id: {rotulo, texto, efeitos}}}]
## Efeitos: atravessar, mover, dano, queda (quadrados), item, desativar, desativar_opcao, ativar,
##   abrir_caminho, alertar, parar, deslocamento, ficha, fadiga, descanso_curto, vitoria.
## As faixas seguem as tabelas do livro (capítulo 11) quando existem.
extends RefCounted

const IA := preload("res://core/ia_inimigo.gd")
const Combate := preload("res://core/combate.gd")
const Personagem := preload("res://core/personagem.gd")
const Dados := preload("res://core/dados_batalha.gd")


static func _ef(tipo: String, extra := {}) -> Dictionary:
	var e := {"tipo": tipo}
	e.merge(extra)
	return e


## Ponto de descanso (0.19): um símbolo no chão onde o grupo para, come e descansa.
## Só abre sem inimigos por perto; depois de descansar, dá para salvar o jogo ali.
static func ponto_de_descanso(id: String, pos: Vector2i, nome := "Ponto de descanso", texto := "") -> Dictionary:
	return {"id": id, "nome": nome, "pos": pos, "alcance": 1, "descanso": true, "chao": true,
		"texto": texto if texto != "" else "Um lugar abrigado, com marcas de fogueiras antigas. Dá para parar, comer algo e recuperar o fôlego.",
		"opcoes": [
			{"id": "descansar", "texto": "Descanso curto do grupo (o turno inteiro)", "custo": {"turno": true}, "sem_alerta": true,
				"resultado": "descanso",
				"resultados": {"descanso": {"texto": "O grupo para, come alguma coisa e recupera o fôlego (todos a até 4 quadrados). Agora dá para salvar o jogo aqui.",
					"efeitos": [_ef("descanso_curto"), _ef("desativar_opcao", {"opcao": "descansar"})]}}},
		]}


# --- Interações de cenário (0.19) ----------------------------------------------
## Coisas do cenário que dão pequenas vantagens a quem procura. Cada função devolve
## uma interação pronta; as missões só escolhem onde pôr.

## Árvore com frutos (cura um pouco) e algo escondido entre as raízes.
static func arvore_frutifera(id: String, pos: Vector2i, nome := "Árvore com frutos", achado := "antidoto") -> Dictionary:
	return {"id": id, "nome": nome, "pos": pos, "alcance": 1,
		"texto": "Galhos carregados de frutos pequenos. As raízes grossas abrem buracos na terra.",
		"opcoes": [
			{"id": "colher", "texto": "Colher frutos", "custo": {"padrao": 1}, "resultado": "colhe",
				"resultados": {"colhe": {"texto": "Frutos maduros: comer um cura 2 e tira 1 de fadiga.",
					"efeitos": [_ef("item", {"item": "frutas_silvestres", "qtd": 2}), _ef("desativar_opcao", {"opcao": "colher"})]}}},
			{"id": "raizes", "texto": "Procurar entre as raízes", "custo": {"padrao": 1}, "teste": {"somar": ["Investigação", "percepcao"]}, "nivel": "medio",
				"resultados": {
					"falha": {"rotulo": "nada", "texto": "Terra, minhocas e uma pedra bonita. Nada útil.", "efeitos": [_ef("desativar_opcao", {"opcao": "raizes"})]},
					"sucesso": {"rotulo": "achado", "texto": "Embrulhado num pano velho, alguém escondeu algo aqui.",
						"efeitos": [_ef("item", {"item": achado}), _ef("desativar_opcao", {"opcao": "raizes"})]},
				}},
		]}


## Pedra alta: quem escala fica em cima (obstáculo "pedra_alta") e ataca com vantagem.
static func pedra_alta(id: String, pos: Vector2i, nome := "Pedra alta") -> Dictionary:
	return {"id": id, "nome": nome, "pos": pos, "alcance": 1,
		"texto": "Uma rocha da altura de um homem, com apoios para as mãos. Lá de cima se vê longe.",
		"opcoes": [
			{"id": "escalar", "texto": "Escalar e ficar em cima", "custo": {"movimento": 1}, "teste": {"somar": ["Escalada", "forca"]}, "nivel": "facil",
				"resultados": {
					"falha": {"rotulo": "escorrega", "texto": "A mão escorrega no musgo. Dá para tentar de novo.", "efeitos": []},
					"sucesso": {"rotulo": "em cima", "texto": "Você chega ao topo.", "efeitos": [_ef("subir")]},
				}},
		]}


## Móvel (baú, armário, cômoda, caixote) com coisas dentro.
static func movel_com_itens(id: String, pos: Vector2i, nome: String, texto: String, itens: Array, ouro := 0) -> Dictionary:
	var efeitos := []
	for i in itens:
		efeitos.append(_ef("item", {"item": i}))
	if ouro > 0:
		efeitos.append(_ef("ouro", {"valor": ouro}))
	efeitos.append(_ef("desativar"))
	return {"id": id, "nome": nome, "pos": pos, "alcance": 1, "texto": texto,
		"opcoes": [
			{"id": "revirar", "texto": "Revirar", "custo": {"padrao": 1}, "resultado": "acha",
				"resultados": {"acha": {"texto": "Vocês reviram tudo.", "efeitos": efeitos}}},
		]}


## Estante, livro, inscrição: um teste para entender e um pedaço da história (lore).
## "extra": efeitos a mais no sucesso (ex.: desbloquear uma missão, fichas).
static func estante_lore(id: String, pos: Vector2i, nome: String, texto: String, lore: String, extra := [], pericia := "História") -> Dictionary:
	return {"id": id, "nome": nome, "pos": pos, "alcance": 1, "texto": texto,
		"opcoes": [
			{"id": "ler", "texto": "Ler com atenção", "custo": {"padrao": 1}, "teste": {"somar": [pericia, "raciocinio"]}, "nivel": "facil",
				"resultados": {
					"falha": {"rotulo": "confuso", "texto": "Letras apagadas e uma língua antiga. Vocês entendem pouco.", "efeitos": [_ef("desativar")]},
					"sucesso": {"rotulo": "entende", "texto": lore, "efeitos": [_ef("lore", {"texto": lore})] + extra + [_ef("desativar")]},
				}},
		]}


static func trilha(fichas) -> Dictionary:
	var obstaculos := {}
	for y in 10:
		obstaculos[Vector2i(4, y)] = "agua"
		obstaculos[Vector2i(5, y)] = "agua"
	obstaculos[Vector2i(4, 2)] = "agua_pedras"
	obstaculos[Vector2i(5, 2)] = "agua_pedras"
	obstaculos[Vector2i(4, 8)] = "ponte_quebrada"
	obstaculos[Vector2i(5, 8)] = "ponte_quebrada"
	for y in 5:
		obstaculos[Vector2i(9, y)] = "rocha"
	for p in [Vector2i(0, 0), Vector2i(1, 1), Vector2i(0, 8), Vector2i(2, 9), Vector2i(13, 5), Vector2i(8, 9)]:
		obstaculos[p] = "arvore"
	obstaculos[Vector2i(7, 1)] = "bau"
	obstaculos[Vector2i(12, 1)] = "carroca"
	obstaculos[Vector2i(8, 6)] = "pedra"

	return {
		"nome": "Exploração: a trilha do riacho",
		"objetivo": "Recupere a carroça de sementes roubada da fazenda (canto de cima, à direita).",
		"vitoria_ao_derrotar_todos": false,
		"largura": 14, "altura": 10, "obstaculos": obstaculos,
		"unidades": Dados.herois_cfg(fichas, [Vector2i(1, 5), Vector2i(1, 4), Vector2i(2, 6), Vector2i(0, 5)]) + [
			Dados._inimigo("vigia", "Goblin Vigia", "goblin", Vector2i(12, 6), "covarde", {"alerta": false, "vigia": 3}),
			Dados._inimigo("atirador", "Goblin Atirador", "goblin_atirador", Vector2i(11, 8), "atirador",
				{"alerta": false, "vigia": 3, "vida": 8, "dano": 3, "atributo_dano": 2, "forca": 0, "destreza": 3,
				"a_distancia": true, "faixas_ideais": [Combate.Faixa.CURTO, Combate.Faixa.MEDIO]}),
			Dados._inimigo("dorminhoco", "Goblin Brigão", "goblin", Vector2i(13, 2), "bruto",
				{"alerta": false, "vigia": 1, "dormindo": true, "ataque_oportunidade": true, "reacao_por_turno": 1, "resistencia": 1, "forca": 3, "atributo_dano": 3}),
		],
		"interacoes": [_riacho(), _pedras(), _ponte(), _bau(), _rastros(), _fogueira(), _paredao(), _fenda(), _toca(), _carroca()],
	}


static func _riacho() -> Dictionary:
	return {"id": "riacho", "nome": "Riacho", "pos": Vector2i(4, 5), "alcance": 2,
		"texto": "A água desce rápida e gelada. O outro lado fica a uns quatro metros.",
		"opcoes": [
			{"id": "nadar", "texto": "Atravessar a nado", "travessia": true, "exige": {"Natação": 1},
				"teste": {"atributo": "forca", "pericia": "Natação", "movimento": true}, "custo": {"padrao": 1},
				"faixas": [[0, "arrastado"], [9, "volta"], [11, "atravessa"], [16, "folego"]],
				"resultados": {
					"arrastado": {"rotulo": "a correnteza te arrasta", "texto": "A correnteza te engole e te cospe de volta na margem, ralado nas pedras do fundo.",
						"efeitos": [_ef("dano", {"valor": 3}), _ef("molhar"), _ef("parar")]},
					"volta": {"rotulo": "não vence a correnteza", "texto": "Você bate as pernas, mas a água é mais forte. Volta para a margem, encharcado.", "efeitos": [_ef("molhar")]},
					"atravessa": {"rotulo": "atravessa", "texto": "Braçada a braçada, você chega ao outro lado, sem fôlego.", "sucesso": true,
						"efeitos": [_ef("atravessar"), _ef("molhar"), _ef("parar")]},
					"folego": {"rotulo": "atravessa e ainda anda", "texto": "Você corta a correnteza com braçadas firmes e sai da água pronto para seguir.",
						"efeitos": [_ef("atravessar"), _ef("molhar"), _ef("deslocamento", {"valor": 2})]},
				}},
			{"id": "vau", "texto": "Atravessar a pé, devagar, contra a água", "travessia": true,
				"teste": {"atributo": "constituicao", "pericia": "Atletismo", "movimento": true}, "custo": {"movimento": 2},
				"faixas": [[0, "escorrega"], ["muito_facil", "volta"], ["facil", "atravessa"]],
				"resultados": {
					"escorrega": {"rotulo": "escorrega", "texto": "O pé desliza numa pedra lisa e você cai de lado na água gelada.",
						"efeitos": [_ef("dano", {"valor": 2}), _ef("molhar"), _ef("parar")]},
					"volta": {"rotulo": "desiste no meio", "texto": "No meio do caminho a água bate no peito. Melhor voltar."},
					"atravessa": {"rotulo": "atravessa", "texto": "Firme como um poste, você atravessa com água pela cintura.",
						"efeitos": [_ef("atravessar"), _ef("molhar"), _ef("parar")]},
				}},
		]}


static func _pedras() -> Dictionary:
	return {"id": "pedras", "nome": "Pedras no riacho", "pos": Vector2i(4, 2), "alcance": 2,
		"texto": "Duas pedras grandes despontam da água, molhadas e cheias de limo.",
		"opcoes": [
			{"id": "saltar", "texto": "Saltar de pedra em pedra", "travessia": true,
				"teste": {"atributo": "forca", "pericia": "Atletismo", "movimento": true}, "custo": {"movimento": 2},
				"faixas": [[0, "cai"], [9, "curto"], [13, "salta"]],
				"resultados": {
					"cai": {"rotulo": "cai na água", "texto": "O limo trai seu pé no primeiro salto. Você cai no riacho e sai pela mesma margem.",
						"efeitos": [_ef("queda", {"quadrados": 1}), _ef("molhar"), _ef("parar")]},
					"curto": {"rotulo": "salto curto", "texto": "Você alcança a primeira pedra, mas a segunda está longe demais. Volta com cuidado."},
					"salta": {"rotulo": "atravessa", "texto": "Um, dois saltos, e você aterrissa seco do outro lado.",
						"efeitos": [_ef("atravessar")]},
				}},
			{"id": "correr", "texto": "Correr pelas pedras sem parar", "travessia": true,
				"teste": {"atributo": "destreza", "pericia": "Acrobacia", "movimento": true}, "custo": {"movimento": 2},
				"faixas": [[0, "cai"], ["muito_facil", "volta"], ["medio", "cruza"]],
				"resultados": {
					"cai": {"rotulo": "cai na água", "texto": "Você escorrega no meio da corrida e mergulha de mau jeito.",
						"efeitos": [_ef("queda", {"quadrados": 1}), _ef("molhar"), _ef("parar")]},
					"volta": {"rotulo": "perde o ritmo", "texto": "Você perde o ritmo e precisa recuar antes de cair."},
					"cruza": {"rotulo": "atravessa e segue", "texto": "Leve como um gato, você passa pelas pedras sem perder o passo.",
						"efeitos": [_ef("atravessar"), _ef("deslocamento", {"valor": 1})]},
				}},
		]}


static func _ponte() -> Dictionary:
	return {"id": "ponte", "nome": "Ponte quebrada", "pos": Vector2i(4, 8), "alcance": 2,
		"texto": "Da velha ponte sobraram duas tábuas podres e os cabos de apoio.",
		"opcoes": [
			{"id": "equilibrar", "texto": "Passar equilibrando-se nas tábuas", "travessia": true,
				"teste": {"atributo": "destreza", "pericia": "Acrobacia", "movimento": true}, "custo": {"movimento": 1},
				"faixas": [[0, "cai"], ["muito_facil", "recua"], ["facil", "cruza"]],
				"resultados": {
					"cai": {"rotulo": "a tábua cede", "texto": "Uma tábua estala e cede. Você cai no riacho e volta nadando para a margem.",
						"efeitos": [_ef("queda", {"quadrados": 1}), _ef("molhar"), _ef("parar")]},
					"recua": {"rotulo": "recua", "texto": "As tábuas balançam demais. Você volta antes que cedam."},
					"cruza": {"rotulo": "atravessa", "texto": "Passo a passo, você chega ao outro lado.",
						"efeitos": [_ef("atravessar")]},
				}},
			{"id": "consertar", "texto": "Amarrar a Corda e refazer a passagem (2 turnos)", "requer": "corda", "custo": {"turno": true, "turnos": 2},
				"resultado": "pronta",
				"resultados": {
					"pronta": {"texto": "Você amarra a corda nos cabos e firma as tábuas. Agora qualquer um passa por aqui (os goblins também).",
						"efeitos": [_ef("abrir_caminho", {"celulas": [Vector2i(4, 8), Vector2i(5, 8)], "chao": "ponte",
							"texto": "A ponte está firme: dá para andar por ela."}), _ef("desativar")]},
				}},
		]}


static func _bau() -> Dictionary:
	var abre := {"rotulo": "abre", "texto": "A tampa cede. Dentro, embrulhados num pano: o que algum viajante deixou para trás.",
		"efeitos": [_ef("item", {"item": "pocao_de_cura_pequena", "qtd": 2}), _ef("item", {"item": "antidoto"}),
			_ef("item", {"item": "racao_de_viagem"}), _ef("item", {"item": "gazua"}), _ef("desativar")]}
	return {"id": "bau", "nome": "Baú trancado", "pos": Vector2i(7, 1), "alcance": 1,
		"texto": "Um baú de viagem, meio enterrado na lama, com uma fechadura enferrujada.",
		"opcoes": [
			{"id": "forcar", "texto": "Forçar a tampa", "teste": {"atributo": "forca", "pericia": "Atletismo"},
				"custo": {"padrao": 1}, "vantagem_com": ["pe_de_cabra"],
				"faixas": [[0, "estrondo"], ["muito_facil", "emperrado"], ["medio", "abre"]], "tags": ["quebrar"],
				"resultados": {
					"estrondo": {"rotulo": "estrondo", "texto": "A tampa não cede, mas o metal range alto e ecoa pela trilha.",
						"efeitos": [_ef("alertar")]},
					"emperrado": {"rotulo": "não abre", "texto": "A ferrugem segura firme. Talvez com mais jeito."},
					"abre": abre,
				}},
			{"id": "gazua", "texto": "Abrir a fechadura com uma Gazua (ela quebra)", "consome": "gazua", "custo": {"padrao": 1},
				"resultado": "abre", "resultados": {"abre": abre}},
			{"id": "destrancar", "texto": "Mexer na fechadura com a ponta da faca", "teste": {"atributo": "destreza", "pericia": "Ladinagem"},
				"custo": {"padrao": 1}, "vantagem_com": ["ferramentas_de_ladrao", "vara_de_3_metros"],
				"faixas": [[0, "agulha"], ["muito_facil", "nada"], ["dificil", "abre"]], "tags": ["armadilha"],
				"resultados": {
					"agulha": {"rotulo": "agulha escondida", "texto": "Uma agulha escondida na fechadura fura seu dedo. Armadilha!",
						"efeitos": [_ef("dano", {"valor": 2})]},
					"nada": {"rotulo": "não abre", "texto": "Os pinos não cedem."},
					"abre": abre,
				}},
		]}


static func _rastros() -> Dictionary:
	var feito := [_ef("desativar_opcao", {"opcao": "examinar"})]
	return {"id": "rastros", "nome": "Rastros na lama", "pos": Vector2i(7, 7), "alcance": 1,
		"texto": "A lama está revirada: pegadas pequenas, marcas de roda e grãos espalhados.",
		"opcoes": [
			{"id": "examinar", "texto": "Ler os rastros", "custo": {"padrao": 1},
				"abordagens": [
					{"id": "sobrevivencia", "texto": "Sobrevivência", "teste": {"somar": ["Sobrevivência"]}, "nivel": "facil",
						"resultados": {
							"falha": {"rotulo": "nada claro", "texto": "As pegadas se misturam na lama.", "efeitos": feito},
							"sucesso": {"rotulo": "três goblins", "texto": "Três goblins, carregados. Um arrasta os pés: deve estar dormindo perto da carroça. Dois seguem para o sul, de vigia.",
								"efeitos": feito + [_ef("ficha", {"ficha": "Preparo"})]},
						}},
					{"id": "percepcao", "texto": "só Percepção", "teste": {"somar": ["percepcao"]}, "nivel": "dificil",
						"resultados": {
							"falha": {"rotulo": "nada claro", "texto": "Você só vê lama revirada.", "efeitos": feito},
							"sucesso": {"rotulo": "um brilho", "texto": "Entre as pegadas, uma gazua caída de algum bolso goblin.",
								"efeitos": feito + [_ef("item", {"item": "gazua"})]},
						}},
					{"id": "investigacao", "texto": "Investigação + Raciocínio", "teste": {"somar": ["Investigação", "raciocinio"]}, "nivel": "medio",
						"resultados": {
							"falha": {"rotulo": "sem conclusão", "texto": "Os rastros não fazem sentido para você.", "efeitos": feito},
							"sucesso": {"rotulo": "o caminho", "texto": "Os grãos derramados levam para trás do paredão de pedra: a carroça está lá, e dá para chegar por cima sem passar pelos vigias.",
								"efeitos": feito},
						}},
				]},
		]}


static func _fogueira() -> Dictionary:
	return {"id": "fogueira", "nome": "Acampamento abandonado", "pos": Vector2i(7, 4), "alcance": 1,
		"texto": "Uma fogueira apagada, um tronco para sentar e restos de uma refeição. Um bom lugar para descansar.",
		"opcoes": [
			{"id": "descansar", "texto": "Descanso curto (gasta o turno inteiro)", "custo": {"turno": true}, "sem_alerta": true,
				"resultado": "descanso",
				"resultados": {"descanso": {"texto": "Você recupera o fôlego, ajeita o equipamento e come alguma coisa.",
					"efeitos": [_ef("descanso_curto"), _ef("desativar_opcao", {"opcao": "descansar"})]}}},
			{"id": "cinzas", "texto": "Revirar as cinzas e as bolsas largadas", "teste": {"atributo": "percepcao", "pericia": "Investigação"},
				"custo": {"padrao": 1},
				"faixas": [[0, "nada"], ["facil", "racao"]], "tags": ["procurar"],
				"resultados": {
					"nada": {"rotulo": "nada", "texto": "Só cinzas e ossos roídos.", "efeitos": [_ef("desativar_opcao", {"opcao": "cinzas"})]},
					"racao": {"rotulo": "acha comida", "texto": "Numa bolsa rasgada, uma Ração de Viagem ainda boa.",
						"efeitos": [_ef("item", {"item": "racao_de_viagem"}), _ef("desativar_opcao", {"opcao": "cinzas"})]},
				}},
		]}


static func _paredao() -> Dictionary:
	return {"id": "paredao", "nome": "Paredão de pedra", "pos": Vector2i(9, 2), "alcance": 1,
		"texto": "Um paredão de uns quatro metros, com poucas saliências. Do outro lado, a carroça.",
		"opcoes": [
			{"id": "escalar", "texto": "Escalar o paredão", "travessia": true,
				"teste": {"atributo": "forca", "pericia": "Escalada", "movimento": true}, "custo": {"padrao": 1},
				"vantagem_com": ["corda"],
				"faixas": [[0, "cai"], [9, "nao_sobe"], [11, "metade"], [16, "sobe"]],
				"resultados": {
					"cai": {"rotulo": "despenca", "texto": "Perto do topo, uma pedra se solta na sua mão e você despenca de uns quatro metros.",
						"efeitos": [_ef("queda", {"quadrados": 3}), _ef("parar")]},
					"nao_sobe": {"rotulo": "não sobe", "texto": "Você não encontra onde apoiar o pé."},
					"metade": {"rotulo": "sobe até a metade", "texto": "Você chega até a metade, mas a pedra lisa acima não dá apoio. Desce com cuidado.", "sucesso": false},
					"sobe": {"rotulo": "passa por cima", "texto": "Você alcança o topo e desce do outro lado, sem fazer barulho.",
						"efeitos": [_ef("atravessar"), _ef("parar")]},
				}},
			{"id": "procurar", "texto": "Procurar um ponto mais fácil para subir", "teste": {"atributo": "percepcao", "pericia": "Investigação"},
				"custo": {"padrao": 1},
				"faixas": [[0, "nada"], ["medio", "fenda"]], "tags": ["procurar"],
				"resultados": {
					"nada": {"rotulo": "nada", "texto": "A pedra é igual em toda parte.", "efeitos": [_ef("desativar_opcao", {"opcao": "procurar"})]},
					"fenda": {"rotulo": "acha uma fenda", "texto": "Mais abaixo, uma fenda com apoios naturais. Parece bem mais fácil por ali.",
						"efeitos": [_ef("ativar", {"id": "fenda", "texto": "Novo ponto de interação: a fenda no paredão."}),
							_ef("desativar_opcao", {"opcao": "procurar"})]},
				}},
		]}


static func _fenda() -> Dictionary:
	return {"id": "fenda", "nome": "Fenda no paredão", "pos": Vector2i(9, 4), "alcance": 1, "ativa": false,
		"texto": "Uma rachadura larga, com pedras encaixadas como degraus.",
		"opcoes": [
			{"id": "escalar", "texto": "Subir pela fenda", "travessia": true,
				"teste": {"atributo": "forca", "pericia": "Escalada", "movimento": true}, "custo": {"padrao": 1},
				"vantagem_com": ["corda"],
				"faixas": [[0, "cai"], [9, "nao_sobe"], [11, "sobe"]],
				"resultados": {
					"cai": {"rotulo": "cai", "texto": "Você escorrega na fenda e cai lá de cima, de uns três metros.",
						"efeitos": [_ef("queda", {"quadrados": 2}), _ef("parar")]},
					"nao_sobe": {"rotulo": "não sobe", "texto": "Você entala o pé na fenda e precisa voltar."},
					"sobe": {"rotulo": "passa por cima", "texto": "Degrau por degrau, você passa para o outro lado.",
						"efeitos": [_ef("atravessar"), _ef("parar")]},
				}},
		]}


static func _toca() -> Dictionary:
	return {"id": "toca", "nome": "Toca escura", "pos": Vector2i(13, 9), "alcance": 1,
		"texto": "Um buraco entre raízes, escuro e fundo. Algo brilha lá dentro.",
		"opcoes": [
			{"id": "procurar", "texto": "Enfiar o braço e tatear", "teste": {"atributo": "percepcao", "pericia": "Investigação"},
				"custo": {"padrao": 1}, "vantagem_com": ["lanterna"],
				"faixas": [[0, "mordida"], ["muito_facil", "nada"], ["medio", "achou"]], "tags": ["procurar", "caverna"],
				"resultados": {
					"mordida": {"rotulo": "mordida", "texto": "Algo peludo morde sua mão e foge por outra saída!",
						"efeitos": [_ef("dano", {"valor": 2})]},
					"nada": {"rotulo": "só terra", "texto": "Só terra e raízes. O brilho era um caco de vidro.", "efeitos": [_ef("desativar")]},
					"achou": {"rotulo": "um esconderijo", "texto": "O esconderijo de algum goblin: frascos roubados!",
						"efeitos": [_ef("item", {"item": "veneno_acido"}), _ef("item", {"item": "pocao_de_mana_pequena"}), _ef("desativar")]},
				}},
		]}


static func _carroca() -> Dictionary:
	return {"id": "carroca", "nome": "Carroça de sementes", "pos": Vector2i(12, 1), "alcance": 1,
		"texto": "A carroça da fazenda, ainda carregada de sacos de sementes. Os goblins a esconderam aqui.",
		"opcoes": [
			{"id": "levar", "texto": "Pegar as rédeas e levar a carroça embora", "custo": {"padrao": 1}, "sem_alerta": true,
				"resultado": "leva",
				"resultados": {"leva": {"texto": "Você solta o freio e leva a carroça trilha abaixo. As sementes voltam para a fazenda.",
					"efeitos": [_ef("vitoria", {"texto": "A carroça de sementes voltou para a fazenda."})]}}},
		]}
