## Missão tutorial (0.22): o pátio de treino da guilda de Pedravelha.
##
## Um herói só (o primeiro do grupo). O treino vai por etapas, cada uma com um
## texto que explica a regra e uma tarefa (Batalha.tutorial): andar, atacar e o
## teste de 21, habilidades e fadiga, ações básicas, fim do turno, teste de perícia
## (escalar a pedra), Saltar/Correr, manobras e, no fim, uma luta de verdade com
## dois goblins de treino (defesa, distribuição do dano, intenções dos inimigos).
extends RefCounted

const Dados := preload("res://core/dados_batalha.gd")
const Exploracao := preload("res://core/dados_exploracao.gd")

const LARGURA := 18
const ALTURA := 12
const PORTAO := [Vector2i(13, 5), Vector2i(13, 6), Vector2i(13, 7)]


static func _ef(tipo: String, extra := {}) -> Dictionary:
	return Exploracao._ef(tipo, extra)


static func missao(fichas) -> Dictionary:
	var lista: Array = fichas if fichas is Array else [fichas]
	var o := {}
	# Cerca em volta do pátio
	for x in LARGURA:
		o[Vector2i(x, 0)] = "cerca"
		o[Vector2i(x, ALTURA - 1)] = "cerca"
	for y in ALTURA:
		o[Vector2i(0, y)] = "cerca"
		o[Vector2i(LARGURA - 1, y)] = "cerca"
	# Curral dos goblins de treino, com o portão fechado
	for y in range(1, ALTURA - 1):
		o[Vector2i(13, y)] = "cerca"
	for p in [Vector2i(3, 2), Vector2i(3, 9), Vector2i(10, 1), Vector2i(10, 10)]:
		o[p] = "feno"
	o[Vector2i(6, 9)] = "caixa"
	o[Vector2i(11, 9)] = "mesa"
	o[Vector2i(5, 2)] = "pedra_alta"
	var unidades := Dados.herois_cfg([lista[0]], [Vector2i(2, 6)])
	unidades.append(Dados._inimigo("boneco", "Boneco de Palha", "boneco", Vector2i(7, 6), "bruto",
		{"vida": 60, "dano": 0, "atributo_dano": 0, "forca": 0, "destreza": 0, "resistencia": 0,
			"mov_por_turno": 0, "padrao_por_turno": 0, "reacao_por_turno": 0, "alerta": false, "vigia": 0,
			"grupo": "boneco", "categoria": "construto"}))
	for i in 2:
		var g := Dados.inimigo_de("goblin_treino%d" % (i + 1), "Goblin de Treino", "goblin", [Vector2i(15, 4), Vector2i(15, 8)][i],
			"lacaio", "aggro", 1, (Dados.FUGA_COVARDE if i == 0 else {}).merged({"alerta": false, "vigia": 0, "grupo": "treino", "tamanho": "pequeno"}, true))
		g["dano"] = 2
		unidades.append(g)
	return {
		"nome": "Treino: o pátio da guilda",
		"objetivo": "Siga o sargento da guilda, passo a passo.",
		"vitoria_ao_derrotar_todos": false,
		"vitoria_se_morrer": ["goblin_treino1", "goblin_treino2"],
		"mensagem_vitoria": "O sargento bate palmas: \"Agora sim. A guilda tem trabalho para você.\" Treino concluído.",
		"largura": LARGURA, "altura": ALTURA, "obstaculos": o,
		"unidades": unidades,
		"interacoes": [Exploracao.pedra_alta("pedra_treino", Vector2i(5, 2), "Pedra do treino")],
		"tutorial": etapas(),
	}


static func etapas() -> Array:
	return [
		{"titulo": "Bem-vindo ao pátio da guilda", "cond": {"tipo": "botao"},
			"texto": "Aqui você aprende o básico do Sistema 21.\n\nO seu baralho é a sua vida: cada ponto de dano manda cartas do baralho embora. A barra embaixo do retrato mostra o baralho (verde), o descarte (vermelho, dá para curar) e o exílio (preto, perdido).\n\nTudo no jogo se resolve com cartas, como no 21: em vez de dados, você abre cartas do seu baralho."},
		{"titulo": "1. Andar", "cond": {"tipo": "perto", "id": "boneco"},
			"texto": "Na sua vez você tem 1 ação de Movimento, 2 ações Padrão e 1 Reação.\n\nAs casas marcadas mostram até onde você anda com uma ação de movimento (a sua velocidade). Uma ação Padrão pode virar movimento, mas não o contrário.\n\nTarefa: ande até ficar ao lado do Boneco de Palha. Arraste a câmera com WASD; a roda do mouse aproxima."},
		{"titulo": "2. Atacar e o teste de 21", "cond": {"tipo": "flag", "flags": ["atacou"]},
			"texto": "Ao lado de um inimigo você fica impedido: a próxima ação de movimento rende só 1 casa.\n\nTarefa: clique no boneco para atacar (1 ação Padrão). Abre a mesa do teste:\n• você recebe uma carta aberta e uma fechada;\n• puxe mais cartas para chegar perto de 21 sem passar (se passar, o resultado vira o valor da última carta);\n• pare quando achar bom. Ás vale 1 ou 11; 21 natural é crítico.\nO defensor faz o mesmo. O dano é a diferença + o dano da arma − a resistência."},
		{"titulo": "3. Habilidades e fadiga", "cond": {"tipo": "flag", "flags": ["carta"]},
			"texto": "Passe o mouse em Habilidades: são as suas cartas de habilidade.\n\nCada carta mostra o custo em fadiga (as gotas) e o tipo de ação. A fadiga fica na carta; quando ela chega ao limite, você precisa virar a carta para o outro lado (e perde as fichas que estavam nela).\n\nTarefa: use uma habilidade que você possa pagar. Se acabaram as ações, encerre o turno (E) e use no próximo."},
		{"titulo": "4. Ações básicas", "cond": {"tipo": "flag", "flags": ["acao"]},
			"texto": "Passe o mouse em Ações. Algumas que qualquer herói tem:\n• Concentrar (Padrão): compra 1 carta para a mão. Cartas da mão podem entrar nos testes no lugar de puxar do baralho.\n• Recuperar o fôlego (Padrão): cura igual à Constituição.\n• Planejar (Padrão): olha as cartas do topo do baralho.\n\nTarefa: use uma delas."},
		{"titulo": "5. Fim do turno", "cond": {"tipo": "flag", "flags": ["encerrou"]},
			"texto": "Quando não quiser fazer mais nada, encerre o turno (E ou o botão Encerrar).\n\nNo fim do turno sai 1 de fadiga de uma carta. Se houver mais de uma carta com fadiga, abre uma tela para você escolher de qual.\n\nTarefa: encerre o turno."},
		{"titulo": "6. Testes de perícia", "cond": {"tipo": "flag", "flags": ["subiu"]},
			"texto": "Fora do combate, quase tudo é um teste: o mesmo 21, somando atributo e perícia no fim, contra uma dificuldade. Armadura média ou pesada baixa o limite em testes de movimento.\n\nTarefa: vá até a Pedra do treino (em cima, à esquerda) e clique nela para escalar (Escalada + Força). Lá de cima, seus ataques têm vantagem contra quem está embaixo. Se escorregar, tente de novo."},
		{"titulo": "7. Saltar e correr", "cond": {"tipo": "flag", "flags": ["saltou"]},
			"texto": "Duas ações de movimento do livro, em Ações:\n• Saltar (2 ações de movimento): ignora o impedimento e o terreno difícil. É o jeito de sair de um cerco.\n• Correr (as 3 ações): multiplica a velocidade, mas até o seu próximo turno os inimigos têm vantagem contra você.\nAs duas pedem Atletismo + Força; se der muito errado, você avança 1 e cai.\n\nTarefa: use Saltar ou Correr."},
		{"titulo": "8. Manobras de luta", "cond": {"tipo": "flag", "flags": ["manobra"]},
			"texto": "Ao lado de um inimigo, uma ação Padrão pode virar uma manobra: Derrubar, Empurrar, Atrapalhar, Desarmar ou Agarrar. É Luta + Força contra a Força dele (inimigo maior: −5 no limite).\n\nTarefa: volte ao boneco e tente derrubá-lo (Ações → Derrubar, depois clique nele)."},
		{"titulo": "9. Luta de verdade", "cond": {"tipo": "nunca"},
			"ao_comecar": [_ef("abrir_caminho", {"celulas": PORTAO, "texto": "O sargento abre o portão do curral."}),
				_ef("alertar", {"grupo": "treino", "texto": "\"Agora é sério!\" O sargento solta dois goblins de treino."})],
			"texto": "O sargento soltou dois goblins de treino! Derrote os dois.\n\n• Quando um inimigo ataca, você defende com cartas. O dano que passa você divide entre escudo, armadura e baralho.\n• No fim do turno dos inimigos, aparece o que cada um pretende fazer.\n• Monstros têm reações: este goblin foge 1 casa quando é atacado.\n• Botão direito num inimigo abre a ficha dele (vida, ações, reações). C abre a sua ficha; I, o inventário."},
	]
