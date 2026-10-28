## Primeira missão (PROVISÓRIA): o contrato da fazenda Vale Seco.
##
## A guilda foi contratada porque "goblins" atacam a fazenda. Os goblins roubam
## comida, mas fugiram da sua toca antiga: a Toupeira Atroz tomou o lugar e cava
## por baixo dos campos. O grupo pode conversar ou lutar com os goblins e precisa
## matar a Toupeira para cumprir o contrato.
##
## Mapa grande (30 × 20) em quatro áreas: a fazenda (conversa e investigação), o
## rio (travessias), o acampamento goblin (conversa, intimidação, furtividade
## ou luta) e o covil da Toupeira (descanso, emboscada e a luta final).
## Formato das interações: ver core/dados_exploracao.gd. "abordagens" são jeitos
## diferentes de fazer a mesma ação, cada um com o seu teste e a sua dificuldade.
extends RefCounted

const Combate := preload("res://core/combate.gd")
const Dados := preload("res://core/dados_batalha.gd")
const Encontros := preload("res://core/encontros.gd")
const Exploracao := preload("res://core/dados_exploracao.gd")

const GOBLINS := ["rokk", "brigao", "desordeiro", "atirador"]


static func _com(base: Dictionary, extra: Dictionary) -> Dictionary:
	var d := base.duplicate()
	d.merge(extra, true)
	return d


static func _ef(tipo: String, extra := {}) -> Dictionary:
	return Exploracao._ef(tipo, extra)


static func missao(fichas) -> Dictionary:
	var n := Dados._quantos(fichas)
	var o := {}
	# Fazenda
	for x in range(1, 4):
		for y in range(1, 4):
			o[Vector2i(x, y)] = "casa"
	for x in range(5, 8):
		for y in range(1, 3):
			o[Vector2i(x, y)] = "celeiro"
	o[Vector2i(3, 6)] = "npc"
	o[Vector2i(5, 9)] = "poco"
	for x in range(0, 7):
		o[Vector2i(x, 13)] = "cerca"
	for p in [Vector2i(6, 6), Vector2i(7, 7)]:
		o[p] = "feno"
	# Rio
	for y in 20:
		o[Vector2i(9, y)] = "agua"
		o[Vector2i(10, y)] = "agua"
	o[Vector2i(9, 4)] = "ponte_quebrada"
	o[Vector2i(10, 4)] = "ponte_quebrada"
	o[Vector2i(9, 12)] = "tronco"
	o[Vector2i(10, 12)] = "tronco"
	# Acampamento goblin
	for p in [Vector2i(14, 3), Vector2i(18, 3), Vector2i(19, 7), Vector2i(14, 9)]:
		o[p] = "tenda"
	o[Vector2i(16, 6)] = "fogueira"
	o[Vector2i(17, 2)] = "saco"
	# Covil da Toupeira
	for y in range(10, 20):
		if y != 14 and y != 15:
			o[Vector2i(22, y)] = "rocha"
	for x in range(23, 30):
		o[Vector2i(x, 10)] = "rocha"
	for p in [Vector2i(25, 13), Vector2i(27, 17), Vector2i(24, 17)]:
		o[p] = "monte_terra"
	o[Vector2i(20, 16)] = "fogueira_apagada"
	# Árvores
	for p in [Vector2i(0, 17), Vector2i(2, 18), Vector2i(6, 17), Vector2i(12, 1), Vector2i(12, 15), Vector2i(20, 1),
			Vector2i(21, 6), Vector2i(13, 18), Vector2i(17, 17), Vector2i(29, 2), Vector2i(26, 5)]:
		o[p] = "arvore"

	var goblin := {"alerta": false, "vigia": 1, "grupo": "goblins", "tamanho": "pequeno"}
	var unidades := Dados.herois_cfg(fichas, [Vector2i(1, 8), Vector2i(2, 9), Vector2i(1, 10), Vector2i(2, 7)])
	# Acampamento goblin: combate simples (lacaios = heróis, médios = heróis).
	var casas := [Vector2i(15, 7), Vector2i(16, 9), Vector2i(14, 5), Vector2i(17, 4), Vector2i(15, 10), Vector2i(18, 6)]
	var medios := [
		["rokk", "Rokk, chefe goblin", "goblin_chefe", Vector2i(16, 5), "tank", {"tamanho": "medio"}],
		["atirador", "Goblin Atirador", "goblin_atirador", Vector2i(18, 9), "aggro",
			{"a_distancia": true, "faixas_ideais": [Combate.Faixa.CURTO, Combate.Faixa.MEDIO], "perfil_id": "atirador"}],
		["brigao", "Goblin Brigão", "goblin", Vector2i(17, 7), "tank", {}],
		["atirador2", "Goblin Atirador", "goblin_atirador", Vector2i(20, 8), "aggro",
			{"a_distancia": true, "faixas_ideais": [Combate.Faixa.CURTO, Combate.Faixa.MEDIO], "perfil_id": "atirador"}],
		["brigao2", "Goblin Brigão", "goblin", Vector2i(18, 5), "tank", {}],
		["atirador3", "Goblin Atirador", "goblin_atirador", Vector2i(19, 9), "aggro",
			{"a_distancia": true, "faixas_ideais": [Combate.Faixa.CURTO, Combate.Faixa.MEDIO], "perfil_id": "atirador"}],
	]
	for k2 in mini(n, medios.size()):
		var m: Array = medios[k2]
		unidades.append(Encontros.para_combate(Dados.inimigo_de(m[0], m[1], m[2], m[3], "medio", m[4], n, _com(goblin, m[5])), "simples"))
	for k2 in mini(n, casas.size()):
		unidades.append(Encontros.para_combate(Dados.inimigo_de("desordeiro" if k2 == 0 else "desordeiro%d" % (k2 + 1), "Goblin Desordeiro", "goblin", casas[k2],
			"lacaio", "aggro", n, _com(goblin, Dados.FUGA_COVARDE)), "simples"))
	# Covil: a Toupeira Atroz é um combate de elite (sozinha).
	unidades.append(Dados.inimigo_de("toupeira", "Toupeira Atroz", "toupeira", Vector2i(26, 15), "elite", "neutro", n,
		{"alerta": false, "vigia": 2, "grupo": "toupeira", "dormindo": true, "tamanho": "grande", "velocidade": 3,
			"habilidades": [{"tipo": "cavar", "a_cada": 3},
				{"tipo": "marcar_area", "nome": "Desmoronamento", "raio": 1, "dano": 6, "derrubar": true, "a_cada": 2,
					"aviso": "A Toupeira crava as garras no teto da toca: terra começa a escorrer sobre as casas marcadas. No próximo turno dela, desaba tudo!"}]}))
	# Cenário interativo (0.19)
	o[Vector2i(13, 11)] = "pedra_alta"
	o[Vector2i(4, 1)] = "caixa"
	return {
		"nome": "Missão: a fazenda Vale Seco",
		"objetivo": "Descubra o que ataca a fazenda Vale Seco e acabe com a ameaça.",
		"vitoria_ao_derrotar_todos": false,
		"vitoria_se_morrer": ["toupeira"],
		"mensagem_vitoria": "A Toupeira Atroz está morta. A fazenda Vale Seco pode plantar de novo, e a guilda recebe o pagamento.",
		"largura": 30, "altura": 20, "obstaculos": o,
		"grupos": {"goblins": {"titulo": "O acampamento goblin", "texto": "Fumaça de uma fogueira mal apagada, tendas remendadas e goblins discutindo aos gritos. Um deles aponta para vocês e berra."},
			"toupeira": {"titulo": "A Toupeira Atroz", "texto": "O chão da toca treme. Uma toupeira do tamanho de uma carroça sai da terra, cega e furiosa, farejando o ar."}},
		"unidades": unidades,
		"interacoes": [_fazendeiro(), _celeiro(), _poco(), _rio(), _ponte(), _tronco(), _vau(),
			_acampamento(), _espiar(), _mantimentos(), _cabana(), _entrada(), _barranco(),
			Exploracao.arvore_frutifera("macieira", Vector2i(12, 1), "Macieira do pomar", "racao_de_viagem"),
			Exploracao.pedra_alta("pedra_vigia", Vector2i(13, 11), "Pedra do vigia"),
			Exploracao.movel_com_itens("caixote", Vector2i(4, 1), "Caixote da varanda",
				"Um caixote com a tampa solta, encostado na casa.", ["tocha", "racao_de_viagem"]),
			Exploracao.estante_lore("rabiscos", Vector2i(21, 6), "Rabiscos no tronco",
				"Alguém riscou desenhos no tronco com uma faca: bonecos de traço, uma capela, e algo saindo do chão.",
				"Os desenhos são dos goblins: a capela velha de Pedravelha, e esqueletos saindo da terra. Os goblins não vieram atacar a fazenda: vieram fugindo do que acordou debaixo da capela.",
				[], "Monstros"),
			Exploracao.ponto_de_descanso("descanso_salgueiro", Vector2i(4, 16), "Sombra do salgueiro")],
	}


# --- Fazenda -----------------------------------------------------------------

static func _fazendeiro() -> Dictionary:
	return {"id": "fazendeiro", "nome": "Otávio, o fazendeiro", "pos": Vector2i(3, 6), "alcance": 1,
		"texto": "Um homem magro, de mãos calejadas, segura um forcado como se fosse uma lança. \"Foram os goblins. Roubam tudo e cavam buracos no meu milho.\"",
		"opcoes": [
			{"id": "conversar", "texto": "Conversar sobre os ataques", "custo": {"padrao": 1}, "tags": ["novo_local"],
				"abordagens": [
					{"id": "diplomacia", "texto": "com calma (Diplomacia)", "teste": {"somar": ["diplomacia"]}, "nivel": "facil",
						"resultados": {
							"falha": {"rotulo": "ele se fecha", "texto": "\"Vocês são pagos para resolver, não para perguntar.\" Ele volta para dentro de casa.",
								"efeitos": [_ef("desativar_opcao", {"opcao": "conversar"})]},
							"sucesso": {"rotulo": "ele confia", "texto": "\"Os goblins acampam do outro lado do rio. Mas o estranho são os buracos: vêm de baixo da terra, e são grandes demais.\" Ele entrega duas poções guardadas para a colheita.",
								"efeitos": [_ef("item", {"item": "pocao_de_cura_pequena", "qtd": 2}), _ef("desativar_opcao", {"opcao": "conversar"})]},
						}},
					{"id": "intuicao", "texto": "lendo o que ele não diz (Intuição + Sabedoria)", "teste": {"somar": ["Intuição", "sabedoria"]}, "nivel": "medio",
						"resultados": {
							"falha": {"rotulo": "nada estranho", "texto": "Ele parece só um homem cansado e com medo.",
								"efeitos": [_ef("desativar_opcao", {"opcao": "conversar"})]},
							"sucesso": {"rotulo": "ele esconde algo", "texto": "Ele desvia o olhar ao falar do celeiro. Admite: \"Uma noite, vi a terra se mexer lá dentro. Não era goblin.\" Vocês chegam à toca já preparados.",
								"efeitos": [_ef("fichas_grupo", {"ficha": "Preparo"}), _ef("desativar_opcao", {"opcao": "conversar"})]},
						}},
					{"id": "negociar", "texto": "pedindo mais pelo serviço (Negociação + Diplomacia)", "teste": {"somar": ["Negociação", "diplomacia"]}, "nivel": "dificil",
						"resultados": {
							"falha": {"rotulo": "ofendido", "texto": "\"Mais? Eu mal tenho o que comer!\" A conversa acaba aí.",
								"efeitos": [_ef("desativar_opcao", {"opcao": "conversar"})]},
							"sucesso": {"rotulo": "acordo", "texto": "Ele cede: além do pagamento, entrega o que tem de valor na despensa.",
								"efeitos": [_ef("item", {"item": "pocao_de_mana_pequena"}), _ef("item", {"item": "antidoto"}),
									_ef("item", {"item": "racao_de_viagem", "qtd": 2}), _ef("desativar_opcao", {"opcao": "conversar"})]},
						}},
				]},
		]}


static func _celeiro() -> Dictionary:
	return {"id": "celeiro", "nome": "Celeiro arrombado", "pos": Vector2i(6, 3), "alcance": 1,
		"texto": "A porta do celeiro está arrancada. O chão de terra batida tem um buraco largo, já meio desmoronado.",
		"opcoes": [
			{"id": "examinar", "texto": "Examinar o buraco", "custo": {"padrao": 1}, "tags": ["procurar"],
				"abordagens": [
					{"id": "percepcao", "texto": "olhando com atenção (Percepção)", "teste": {"somar": ["percepcao"]}, "nivel": "facil",
						"resultados": {
							"falha": {"rotulo": "só terra", "texto": "Terra revirada, palha e um cheiro forte.", "efeitos": [_ef("desativar_opcao", {"opcao": "examinar"})]},
							"sucesso": {"rotulo": "garras", "texto": "Marcas de garras do tamanho de um braço. Goblins não fazem isso.", "efeitos": [_ef("desativar_opcao", {"opcao": "examinar"})]},
						}},
					{"id": "sobrevivencia", "texto": "seguindo o túnel (Sobrevivência + Sabedoria)", "teste": {"somar": ["Sobrevivência", "sabedoria"]}, "nivel": "medio",
						"resultados": {
							"falha": {"rotulo": "túnel desmoronado", "texto": "O túnel desmoronou logo adiante.", "efeitos": [_ef("desativar_opcao", {"opcao": "examinar"})]},
							"sucesso": {"rotulo": "o caminho", "texto": "O túnel segue para o leste, por baixo do rio, até um morro de pedra além do acampamento goblin.",
								"efeitos": [_ef("marcar", {"id": "toupeira"}), _ef("desativar_opcao", {"opcao": "examinar"})]},
						}},
					{"id": "monstros", "texto": "lembrando de bestiários (Monstros + Raciocínio)", "teste": {"somar": ["Monstros", "raciocinio"]}, "nivel": "medio",
						"resultados": {
							"falha": {"rotulo": "não reconhece", "texto": "Você não reconhece o bicho.", "efeitos": [_ef("desativar_opcao", {"opcao": "examinar"})]},
							"sucesso": {"rotulo": "Toupeira Atroz", "texto": "Uma Toupeira Atroz: cega, enorme, com couro grosso. Dorme de dia e ouve muito bem. Pegá-la dormindo é a melhor chance.",
								"efeitos": [_ef("fichas_grupo", {"ficha": "Foco"}), _ef("desativar_opcao", {"opcao": "examinar"})]},
						}},
				]},
		]}


static func _poco() -> Dictionary:
	return {"id": "poco", "nome": "Poço velho", "pos": Vector2i(5, 9), "alcance": 1,
		"texto": "No fundo do poço seco, a uns seis metros, algo brilha entre as pedras.",
		"opcoes": [
			{"id": "descer", "texto": "Descer pelas pedras da parede", "teste": {"somar": ["forca", "Escalada"], "movimento": true},
				"custo": {"padrao": 1}, "vantagem_com": ["corda"],
				"faixas": [[0, "despenca"], ["muito_facil", "desiste"], ["facil", "pega"]],
				"resultados": {
					"despenca": {"rotulo": "despenca", "texto": "Uma pedra se solta e você despenca até o fundo do poço.",
						"efeitos": [_ef("queda", {"quadrados": 4}), _ef("item", {"item": "gazua"}), _ef("parar"), _ef("desativar")]},
					"desiste": {"rotulo": "volta", "texto": "As pedras estão soltas demais. Você sobe de volta antes de cair."},
					"pega": {"rotulo": "pega e volta", "texto": "Você desce, pega o brilho (uma gazua e uma poção perdidas) e sobe de volta.",
						"efeitos": [_ef("item", {"item": "gazua"}), _ef("item", {"item": "pocao_de_cura_pequena"}), _ef("desativar")]},
				}},
		]}


# --- Rio ----------------------------------------------------------------------

static func _rio() -> Dictionary:
	return {"id": "rio", "nome": "Rio", "pos": Vector2i(9, 8), "alcance": 2,
		"texto": "Águas escuras e frias. O outro lado fica a uns quatro metros.",
		"opcoes": [
			{"id": "nadar", "texto": "Atravessar a nado", "travessia": true, "exige": {"Natação": 1},
				"teste": {"somar": ["forca", "Natação"], "movimento": true}, "custo": {"padrao": 1},
				"faixas": [[0, "arrastado"], [9, "volta"], [11, "atravessa"]],
				"resultados": {
					"arrastado": {"rotulo": "arrastado", "texto": "A correnteza te arrasta e te joga de volta na margem.", "efeitos": [_ef("dano", {"valor": 3}), _ef("molhar"), _ef("parar")]},
					"volta": {"rotulo": "volta", "texto": "Você não vence a água e volta para a margem.", "efeitos": [_ef("molhar")]},
					"atravessa": {"rotulo": "atravessa", "texto": "Você atravessa, encharcado.", "efeitos": [_ef("atravessar"), _ef("molhar"), _ef("parar")]},
				}},
		]}


static func _ponte() -> Dictionary:
	return {"id": "ponte", "nome": "Ponte caída", "pos": Vector2i(9, 4), "alcance": 2,
		"texto": "A ponte da fazenda caiu: sobraram os pilares e os cabos.",
		"opcoes": [
			{"id": "consertar", "texto": "Refazer a passagem com a Corda (2 turnos)", "requer": "corda", "custo": {"turno": true, "turnos": 2},
				"resultado": "pronta",
				"resultados": {"pronta": {"texto": "Vocês amarram a corda nos pilares e firmam tábuas soltas. O grupo inteiro pode passar.",
					"efeitos": [_ef("abrir_caminho", {"celulas": [Vector2i(9, 4), Vector2i(10, 4)], "chao": "ponte"}), _ef("desativar")]}}},
			{"id": "pular", "texto": "Pular de pilar em pilar", "travessia": true, "teste": {"somar": ["Atletismo"], "movimento": true},
				"custo": {"movimento": 2}, "nivel": "facil",
				"resultados": {
					"falha": {"rotulo": "cai na água", "texto": "Você erra o pilar e cai no rio, voltando molhado para a margem.", "efeitos": [_ef("queda", {"quadrados": 1}), _ef("molhar"), _ef("parar")]},
					"sucesso": {"rotulo": "atravessa", "texto": "Dois saltos e você está do outro lado.", "efeitos": [_ef("atravessar")]},
				}},
		]}


static func _tronco() -> Dictionary:
	return {"id": "tronco", "nome": "Tronco sobre o rio", "pos": Vector2i(9, 12), "alcance": 2,
		"texto": "Uma árvore caída atravessa o rio, coberta de musgo.",
		"opcoes": [
			{"id": "equilibrar", "texto": "Passar equilibrando-se", "travessia": true, "custo": {"movimento": 1},
				"abordagens": [
					{"id": "destreza", "texto": "só com o corpo (Destreza)", "teste": {"somar": ["destreza"], "movimento": true}, "nivel": "facil",
						"resultados": {
							"falha": {"rotulo": "escorrega", "texto": "O musgo trai seu pé e você cai no rio.", "efeitos": [_ef("queda", {"quadrados": 1}), _ef("molhar"), _ef("parar")]},
							"sucesso": {"rotulo": "atravessa", "texto": "Passo a passo, você chega do outro lado.", "efeitos": [_ef("atravessar")]},
						}},
					{"id": "acrobacia", "texto": "com técnica (Acrobacia + Destreza)", "teste": {"somar": ["Acrobacia", "destreza"], "movimento": true}, "nivel": "medio",
						"resultados": {
							"falha": {"rotulo": "escorrega", "texto": "Você tenta correr e escorrega no meio.", "efeitos": [_ef("queda", {"quadrados": 1}), _ef("molhar"), _ef("parar")]},
							"sucesso": {"rotulo": "atravessa e segue", "texto": "Você passa correndo, leve, e ainda tem fôlego para seguir.",
								"efeitos": [_ef("atravessar"), _ef("deslocamento", {"valor": 2})]},
						}},
				]},
		]}


static func _vau() -> Dictionary:
	return {"id": "vau", "nome": "Vau raso", "pos": Vector2i(9, 17), "alcance": 2,
		"texto": "Aqui o rio é mais raso, mas a correnteza puxa forte.",
		"opcoes": [
			{"id": "atravessar", "texto": "Atravessar a pé", "travessia": true, "custo": {"movimento": 2},
				"teste": {"somar": ["constituicao", "Atletismo"], "movimento": true},
				"faixas": [[0, "escorrega"], ["muito_facil", "atravessa"]],
				"resultados": {
					"escorrega": {"rotulo": "escorrega", "texto": "Você escorrega nas pedras lisas e volta machucado.", "efeitos": [_ef("dano", {"valor": 2}), _ef("molhar"), _ef("parar")]},
					"atravessa": {"rotulo": "atravessa", "texto": "Firme, com água na cintura, você chega ao outro lado.", "efeitos": [_ef("atravessar"), _ef("molhar"), _ef("parar")]},
				}},
		]}


# --- Acampamento goblin -------------------------------------------------------------

static func _acampamento() -> Dictionary:
	var vao_embora := _ef("retirar", {"grupo": "goblins", "texto": "Os goblins juntam as coisas e somem na mata."})
	var briga := _ef("alertar", {"grupo": "goblins", "texto": "Os goblins sacam as armas!"})
	var fim := _ef("desativar")
	return {"id": "acampamento", "nome": "Fogueira dos goblins", "pos": Vector2i(16, 6), "alcance": 2,
		"texto": "Quatro goblins magros em volta de uma fogueira. O maior, de elmo amassado, se levanta: \"Rokk não quer briga. Rokk quer comer.\" Os outros seguram as armas, nervosos.",
		"opcoes": [
			{"id": "falar", "texto": "Falar com Rokk", "custo": {"padrao": 1}, "sem_alerta": "goblins", "tags": ["criminosos", "novo_local"],
				"abordagens": [
					{"id": "diplomacia", "texto": "propor um acordo (Diplomacia)", "teste": {"somar": ["diplomacia"]}, "nivel": "medio",
						"resultados": {
							"falha": {"rotulo": "desconfiança", "texto": "Rokk cospe no fogo. \"Humano mente.\"", "efeitos": [briga, fim]},
							"sucesso": {"rotulo": "acordo", "texto": "Rokk conta tudo: uma Toupeira Atroz tomou a toca deles, no morro de pedra a leste. \"Mata bicho, goblins vão embora.\" Eles partem e deixam a comida roubada.",
								"efeitos": [vao_embora, _ef("marcar", {"id": "toupeira"}), fim]},
						}},
					{"id": "intimidar", "texto": "ameaçar (Intimidação + Força)", "teste": {"somar": ["Intimidação", "forca"]}, "nivel": "medio",
						"resultados": {
							"falha": {"rotulo": "eles reagem", "texto": "Rokk ri e bate o tacape no chão. Os goblins avançam!", "efeitos": [briga, fim]},
							"sucesso": {"rotulo": "fogem", "texto": "Os goblins trocam olhares e fogem correndo, largando tudo para trás.", "efeitos": [vao_embora, fim]},
						}},
					{"id": "mentir", "texto": "mentir que a milícia vem aí (Mentira)", "teste": {"somar": ["mentira"]}, "nivel": "facil",
						"resultados": {
							"falha": {"rotulo": "não acreditam", "texto": "\"Milícia não vem pra cá. Ninguém vem pra cá.\" Rokk ergue o tacape.", "efeitos": [briga, fim]},
							"sucesso": {"rotulo": "acreditam", "texto": "O medo vence. Os goblins pegam o que podem e somem.", "efeitos": [vao_embora, fim]},
						}},
				]},
		]}


static func _espiar() -> Dictionary:
	return {"id": "espiar", "nome": "Moita perto do acampamento", "pos": Vector2i(13, 5), "alcance": 1,
		"texto": "Uma moita alta, a poucos metros da fogueira dos goblins.",
		"opcoes": [
			{"id": "espiar", "texto": "Esgueirar-se e observar", "custo": {"padrao": 1}, "sem_alerta": "goblins",
				"teste": {"somar": ["Furtividade", "destreza"]}, "nivel": "facil",
				"resultados": {
					"falha": {"rotulo": "visto", "texto": "Um galho estala. \"Intruso!\"", "efeitos": [_ef("alertar", {"grupo": "goblins", "texto": "Os goblins sacam as armas!"}), _ef("desativar")]},
					"sucesso": {"rotulo": "observa", "texto": "Você vê que Rokk está ferido e que o arqueiro dorme de olho aberto. Dá para atacar primeiro.",
						"efeitos": [_ef("marcar", {"id": "rokk"}), _ef("marcar", {"id": "atirador"}), _ef("desativar")]},
				}},
		]}


static func _mantimentos() -> Dictionary:
	return {"id": "mantimentos", "nome": "Saco de mantimentos", "pos": Vector2i(17, 2), "alcance": 1,
		"texto": "Um saco cheio de milho, pão duro e frascos: o que os goblins roubaram da fazenda.",
		"opcoes": [
			{"id": "pegar", "texto": "Pegar os mantimentos", "custo": {"padrao": 1}, "sem_alerta": "goblins", "resultado": "pega",
				"resultados": {"pega": {"texto": "Vocês recuperam parte do que foi roubado.",
					"efeitos": [_ef("item", {"item": "racao_de_viagem", "qtd": 2}), _ef("item", {"item": "pocao_de_cura_pequena"}), _ef("desativar")]}}},
		]}


# --- Covil da Toupeira -------------------------------------------------------------

static func _cabana() -> Dictionary:
	return {"id": "cabana", "nome": "Acampamento de caçador", "pos": Vector2i(20, 16), "alcance": 1,
		"texto": "Uma fogueira fria, um abrigo de galhos e uma mochila rasgada. Bom lugar para recuperar o fôlego antes do covil.",
		"opcoes": [
			{"id": "descansar", "texto": "Descanso curto do grupo (o turno inteiro)", "custo": {"turno": true}, "sem_alerta": true, "resultado": "descanso",
				"resultados": {"descanso": {"texto": "O grupo descansa em volta da fogueira (todos a até 4 quadrados).",
					"efeitos": [_ef("descanso_curto"), _ef("desativar_opcao", {"opcao": "descansar"})]}}},
			{"id": "revirar", "texto": "Revirar a mochila", "custo": {"padrao": 1}, "teste": {"somar": ["percepcao"]}, "nivel": "facil", "tags": ["procurar"],
				"resultados": {
					"falha": {"rotulo": "nada", "texto": "Só trapos.", "efeitos": [_ef("desativar_opcao", {"opcao": "revirar"})]},
					"sucesso": {"rotulo": "frascos", "texto": "Dois frascos intactos no fundo da mochila.",
						"efeitos": [_ef("item", {"item": "veneno_acido"}), _ef("item", {"item": "antidoto"}), _ef("desativar_opcao", {"opcao": "revirar"})]},
				}},
		]}


static func _entrada() -> Dictionary:
	return {"id": "entrada", "nome": "Entrada do covil", "pos": Vector2i(22, 13), "alcance": 1,
		"texto": "Uma abertura escura entre as pedras. De dentro vem um ronco grave e o cheiro de terra molhada.",
		"opcoes": [
			{"id": "escutar", "texto": "Escutar", "custo": {"padrao": 1}, "tags": ["caverna"],
				"abordagens": [
					{"id": "percepcao", "texto": "prestando atenção (Percepção)", "teste": {"somar": ["percepcao"]}, "nivel": "muito_facil",
						"resultados": {
							"falha": {"rotulo": "só o vento", "texto": "Só o vento nas pedras.", "efeitos": [_ef("desativar_opcao", {"opcao": "escutar"})]},
							"sucesso": {"rotulo": "ela dorme", "texto": "Um ronco enorme, compassado. Ela dorme lá no fundo.",
								"efeitos": [_ef("marcar", {"id": "toupeira"}), _ef("desativar_opcao", {"opcao": "escutar"})]},
						}},
					{"id": "natureza", "texto": "pelo comportamento do bicho (Natureza + Sabedoria)", "teste": {"somar": ["Natureza", "sabedoria"]}, "nivel": "medio",
						"resultados": {
							"falha": {"rotulo": "nada útil", "texto": "Você não tira conclusão nenhuma.", "efeitos": [_ef("desativar_opcao", {"opcao": "escutar"})]},
							"sucesso": {"rotulo": "o ponto fraco", "texto": "Ela ouve vibrações no chão: quem chegar devagar pega a Toupeira dormindo.",
								"efeitos": [_ef("fichas_grupo", {"ficha": "Foco"}), _ef("desativar_opcao", {"opcao": "escutar"})]},
						}},
				]},
			{"id": "emboscada", "texto": "Preparar uma emboscada", "custo": {"padrao": 1}, "sem_alerta": "toupeira", "tags": ["caverna"],
				"teste": {"somar": ["Sobrevivência", "sabedoria"]}, "nivel": "facil",
				"resultados": {
					"falha": {"rotulo": "barulho", "texto": "Uma pedra rola para dentro do covil. O ronco para.",
						"efeitos": [_ef("alertar", {"grupo": "toupeira", "texto": "A Toupeira Atroz acorda!"}), _ef("desativar_opcao", {"opcao": "emboscada"})]},
					"sucesso": {"rotulo": "pronto", "texto": "O grupo se posiciona nas sombras da entrada.",
						"efeitos": [_ef("fichas_grupo", {"ficha": "Preparo"}), _ef("desativar_opcao", {"opcao": "emboscada"})]},
				}},
		]}


static func _barranco() -> Dictionary:
	return {"id": "barranco", "nome": "Barranco sobre o covil", "pos": Vector2i(25, 10), "alcance": 1,
		"texto": "Do alto das pedras dá para ver o covil lá embaixo, uns quatro metros abaixo.",
		"opcoes": [
			{"id": "pular", "texto": "Pular para dentro do covil", "travessia": true, "custo": {"movimento": 1}, "resultado": "pula",
				"resultados": {"pula": {"texto": "Você salta lá de cima. O chão vem rápido.",
					"efeitos": [_ef("atravessar"), _ef("queda", {"quadrados": 3}), _ef("alertar", {"grupo": "toupeira", "texto": "O baque acorda a Toupeira Atroz!"})]}}},
			{"id": "descer", "texto": "Descer escalando", "travessia": true, "custo": {"padrao": 1}, "vantagem_com": ["corda"], "tags": ["caverna", "escalar"],
				"teste": {"somar": ["forca", "Escalada"], "movimento": true},
				"faixas": [[0, "cai"], ["muito_facil", "nao_desce"], ["facil", "desce"]],
				"resultados": {
					"cai": {"rotulo": "cai", "texto": "No meio da descida, a pedra cede.", "efeitos": [_ef("atravessar"), _ef("queda", {"quadrados": 2}), _ef("parar")]},
					"nao_desce": {"rotulo": "não desce", "texto": "Você não acha apoio e volta para cima."},
					"desce": {"rotulo": "desce em silêncio", "texto": "Você desce sem um ruído.", "efeitos": [_ef("atravessar"), _ef("parar")]},
				}},
		]}
