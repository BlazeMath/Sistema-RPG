## A vila de Pedravelha como lugar para andar (0.23).
## O primeiro herói do grupo anda livre (sem inimigos, o deslocamento não acaba).
## O mural da guilda abre os contratos; o mercador, o ferreiro e a estalagem abrem as
## lojas (efeito "abrir_vila"); os moradores conversam e soltam boatos.
extends RefCounted

const Dados := preload("res://core/dados_batalha.gd")
const Exploracao := preload("res://core/dados_exploracao.gd")

const LARGURA := 34
const ALTURA := 22


static func _ef(tipo: String, extra := {}) -> Dictionary:
	return Exploracao._ef(tipo, extra)


static func _conversa(id: String, nome: String, pos: Vector2i, texto: String, falas: Array) -> Dictionary:
	var ops := []
	for f in falas:
		var op := {"id": f[0], "texto": f[1]}
		if f.size() > 3:
			op["teste"] = {"somar": f[3]}
			op["nivel"] = f[4]
			op["resultados"] = {
				"falha": {"rotulo": "não conta", "texto": f[5], "efeitos": [_ef("desativar_opcao", {"opcao": f[0]})]},
				"sucesso": {"rotulo": "conta", "texto": f[2], "efeitos": [_ef("desativar_opcao", {"opcao": f[0]})] + (f[6] if f.size() > 6 else [])},
			}
		else:
			op["resultado"] = "fala"
			op["resultados"] = {"fala": {"texto": f[2]}}
		ops.append(op)
	return {"id": id, "nome": nome, "pos": pos, "alcance": 1, "texto": texto, "opcoes": ops}


static func _loja(id: String, nome: String, pos: Vector2i, texto: String, aba: String, rotulo: String) -> Dictionary:
	return {"id": id, "nome": nome, "pos": pos, "alcance": 1, "texto": texto,
		"opcoes": [{"id": "abrir", "texto": rotulo, "resultado": "abre", "resultados": {"abre": {"texto": "", "efeitos": [_ef("abrir_vila", {"aba": aba})]}}}]}


static func cenario(fichas) -> Dictionary:
	var lista: Array = fichas if fichas is Array else [fichas]
	var o := {}
	for x in LARGURA:
		o[Vector2i(x, 0)] = "cerca"
		o[Vector2i(x, ALTURA - 1)] = "cerca"
	for y in ALTURA:
		if y != 11:
			o[Vector2i(0, y)] = "cerca"
		o[Vector2i(LARGURA - 1, y)] = "cerca"
	for x in range(6, 10):
		for y in range(2, 5):
			o[Vector2i(x, y)] = "casa"      # salão da guilda
	o[Vector2i(8, 5)] = "estante"           # mural
	for x in range(14, 16):
		for y in range(3, 5):
			o[Vector2i(x, y)] = "tenda"     # barraca do mercador
	o[Vector2i(13, 5)] = "npc"
	for x in range(20, 23):
		for y in range(2, 5):
			o[Vector2i(x, y)] = "casa"      # forja
	o[Vector2i(23, 5)] = "npc"
	o[Vector2i(22, 6)] = "barril"
	o[Vector2i(24, 4)] = "caixa"
	for x in range(24, 29):
		for y in range(12, 16):
			o[Vector2i(x, y)] = "celeiro"   # estalagem do Corvo
	o[Vector2i(26, 16)] = "npc"
	for x in range(29, 32):
		for y in range(2, 5):
			o[Vector2i(x, y)] = "casa"      # capela
	o[Vector2i(30, 5)] = "npc"
	o[Vector2i(16, 11)] = "poco"
	o[Vector2i(11, 14)] = "npc"
	o[Vector2i(19, 17)] = "npc"
	o[Vector2i(5, 16)] = "npc"
	for x in range(3, 6):
		for y in range(7, 9):
			o[Vector2i(x, y)] = "casa"
	for x in range(8, 11):
		for y in range(17, 20):
			o[Vector2i(x, y)] = "casa"
	for p in [Vector2i(2, 3), Vector2i(12, 8), Vector2i(19, 8), Vector2i(31, 9), Vector2i(31, 18), Vector2i(2, 19), Vector2i(14, 19), Vector2i(22, 19)]:
		o[p] = "arvore"
	for p in [Vector2i(12, 2), Vector2i(17, 14)]:
		o[p] = "saco"
	return {
		"nome": "Vila de Pedravelha",
		"objetivo": "Ande pela vila. O mural da guilda (ao norte) tem os contratos; o mercador, o ferreiro e a estalagem ficam em volta da praça.",
		"vitoria_ao_derrotar_todos": false,
		"exploracao_livre": true,
		"largura": LARGURA, "altura": ALTURA, "obstaculos": o,
		"abertura": {"titulo": "Pedravelha", "texto": "A vila acorda devagar. Fumaça sobe da forja, o mercador arruma a barraca na praça e, na porta da guilda, o mural está cheio de papéis pregados."},
		"unidades": Dados.herois_cfg([lista[0]], [Vector2i(1, 11)]),
		"interacoes": [
			_loja("mural", "Mural da guilda", Vector2i(8, 5), "Papéis pregados uns sobre os outros: pedidos de ajuda, recompensas, avisos. O selo da guilda marca os contratos aceitos.", "missoes", "Ler os contratos"),
			_loja("mercador", "Doroteia, a mercadora", Vector2i(13, 5), "\"Poções, cordas, tochas... e eu compro o que vocês trouxerem lá de baixo, se valer alguma coisa.\"", "mercado", "Ver as mercadorias (comprar e vender)"),
			_loja("ferreiro", "Bruno, o ferreiro", Vector2i(23, 5), "O ferreiro limpa o suor da testa. \"Arma nova? Armadura? Diga o que precisa.\"", "ferreiro", "Ver armas, armaduras e escudos"),
			_loja("estalagem", "Marta, da estalagem do Corvo", Vector2i(26, 16), "\"Cama quente, sopa e ninguém pergunta onde vocês se machucaram. O preço é justo.\"", "estalagem", "Pedir um quarto (descanso longo)"),
			_conversa("berta", "Velha Berta", Vector2i(11, 14), "Uma senhora sentada num banquinho, descascando batatas.",
				[["boato", "Perguntar as novidades", "\"O pão de Rio Raso tá vindo podre, meu filho. Saco inteiro, de uma vez. Isso não é coisa de bicho, não.\""],
				["passado", "Perguntar sobre a capela velha (Diplomacia)", "\"Minha avó dizia que o cavaleiro enterrado lá jurou guardar a vila depois de morto. Bonito, né? Só que juramento de morto não acaba.\"", ["diplomacia"], "facil",
					"\"Coisa de velha, esquece.\" Ela volta para as batatas."]]),
			_conversa("crianca", "Pipo, o menino", Vector2i(19, 17), "Um menino com uma espada de pau.",
				[["brincar", "Perguntar o que ele viu", "\"Eu vi um homem de capuz comprando todo o trigo do moinho! Pagou com moeda de ouro, mas a moeda era fria que nem gelo.\""]]),
			_conversa("guarda", "Rui, o guarda", Vector2i(5, 16), "O guarda da vila, de olho no portão.",
				[["estradas", "Perguntar sobre as estradas", "\"Goblins na estrada do sul, mortos andando perto da capela, e agora sumiço de gente perto das colinas. A guilda é a única coisa que segura isso aqui.\""],
				["catacumbas", "Perguntar sobre as catacumbas (Intimidação ou lábia)", "\"Tá bom, tá bom. As catacumbas de Vel-Dorath ficam sob a colina leste. Quem desceu e voltou falou de cristais azuis e de um cavaleiro que não cai.\"", ["Intimidação"], "medio",
					"\"Não sei de nada, e se soubesse não ia contar.\""]]),
			_conversa("padre", "Padre Anselmo", Vector2i(30, 5), "O padre da capela nova, de batina remendada.",
				[["bencao", "Pedir uma bênção", "Ele traça um sinal na testa de cada um. \"Que a luz vá com vocês. E voltem: a vila precisa de vocês vivos.\""],
				["mortos", "Perguntar sobre os mortos que andam (Religião)", "\"Mortos não se levantam sozinhos. Alguém paga por isso, com alguma moeda que não é ouro. Procurem quem ganha com o medo.\"", ["Religião"], "medio",
					"Ele desconversa e volta para as orações."]]),
			{"id": "poco", "nome": "Poço da praça", "pos": Vector2i(16, 11), "alcance": 1,
				"texto": "Um poço velho de pedra. Dizem que uma moeda jogada aqui traz sorte.",
				"opcoes": [{"id": "olhar", "texto": "Olhar lá dentro (Percepção)", "teste": {"somar": ["percepcao"]}, "nivel": "medio",
					"resultados": {"falha": {"rotulo": "escuro", "texto": "Só água escura lá embaixo."},
						"sucesso": {"rotulo": "brilho", "texto": "Algo brilha preso numa pedra, perto da água. Com cuidado, você pesca uma bolsinha com moedas.",
							"efeitos": [_ef("ouro", {"valor": 10}), _ef("desativar_opcao", {"opcao": "olhar"})]}}}]},
		],
	}
