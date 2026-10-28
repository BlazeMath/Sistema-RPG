## Missão longa (0.23): as Catacumbas de Vel-Dorath.
##
## Onze salas de formatos diferentes, ligadas por portas: corredor 2×6, porta dupla,
## salão em U com um braço elevado (escada), capela, galeria no alto com uma beirada
## que cai no ossuário, cripta em L, ponte sobre o rio subterrâneo, antecâmara e o
## santuário do Guardião, num estrado elevado. Uma câmara secreta.
## Cada sala tem um texto ao entrar (gatilho) e oferece procurar armadilhas.
## O primeiro descanso (sala 5) só abre depois de 3 combates vencidos.
## O chefe fica em guarda turno sim, turno não, marca o chão antes de golpear e sofre
## metade do dano enquanto os dois Cristais de Ligação estiverem inteiros.
extends RefCounted

const Combate := preload("res://core/combate.gd")
const Dados := preload("res://core/dados_batalha.gd")
const Exploracao := preload("res://core/dados_exploracao.gd")

const LARGURA := 48
const ALTURA := 32

const ESQUELETO := {"categoria": "morto-vivo", "visao_no_escuro": true, "tipo_dano": "Corte",
	"fraquezas": {"Concussão": 2, "Radiante": 2}, "resiste_tipo": {"Perfuração": 2}, "alerta": false, "vigia": 4}
const ATIRADOR := {"a_distancia": true, "faixas_ideais": [Combate.Faixa.CURTO, Combate.Faixa.MEDIO], "perfil_id": "atirador", "tipo_dano": "Perfuração"}


static func _ef(tipo: String, extra := {}) -> Dictionary:
	return Exploracao._ef(tipo, extra)


static func _ret(x1: int, y1: int, x2: int, y2: int) -> Array:
	var l := []
	for x in range(x1, x2 + 1):
		for y in range(y1, y2 + 1):
			l.append(Vector2i(x, y))
	return l


static func _com(a: Dictionary, b: Dictionary) -> Dictionary:
	var d := a.duplicate(true)
	d.merge(b, true)
	return d


## As salas (casas de chão). A ordem é a numeração do mapa.
static func salas() -> Dictionary:
	var u_salao: Array = _ret(14, 8, 17, 23) + _ret(18, 20, 22, 23) + _ret(23, 8, 26, 23)
	var capela: Array = _ret(13, 1, 18, 6).filter(func(p): return not p in [Vector2i(13, 1), Vector2i(18, 1), Vector2i(13, 6), Vector2i(18, 6)])
	var cripta: Array = _ret(31, 11, 38, 16) + _ret(35, 17, 38, 22)
	var santuario: Array = _ret(30, 25, 46, 30).filter(func(p): return not (p.x <= 32 and p.y >= 29)) + _ret(40, 24, 44, 24)
	return {
		"entrada": _ret(2, 13, 6, 18),
		"corredor": _ret(7, 15, 12, 16),
		"salao": u_salao,
		"capela": capela,
		"galeria": _ret(21, 1, 30, 6),
		"ossuario": _ret(32, 1, 38, 8),
		"cripta": cripta,
		"ponte": _ret(40, 11, 45, 15),
		"antecamara": _ret(39, 17, 46, 22),
		"santuario": santuario,
		"tesouro": _ret(3, 1, 9, 6),
	}


static func missao(fichas) -> Dictionary:
	var n: int = Dados._quantos(fichas)
	var o := {}
	for x in LARGURA:
		for y in ALTURA:
			o[Vector2i(x, y)] = "parede"
	var sl := salas()
	for nome in sl:
		for p in sl[nome]:
			o.erase(p)
	# Passagens (sem porta) e portas (obstáculo "porta" até abrir)
	for p in [Vector2i(35, 9), Vector2i(35, 10), Vector2i(31, 3)] + _ret(27, 21, 34, 22):
		o.erase(p)
	for p in _ret(27, 21, 27, 22):
		o[p] = "parede"   # parede rachada (sala 3 → passagem da cripta)
	for p in [Vector2i(10, 3), Vector2i(11, 3), Vector2i(12, 3)]:
		o[p] = "parede"   # passagem secreta da capela para a câmara do tesouro
	var portas := {"porta_dupla": [Vector2i(13, 15), Vector2i(13, 16)], "porta_capela": [Vector2i(15, 7)],
		"porta_galeria": [Vector2i(24, 7)], "porta_cripta": [Vector2i(35, 10)], "porta_ponte": [Vector2i(39, 13)],
		"porta_antecamara": [Vector2i(45, 16)], "porta_santuario": [Vector2i(42, 23), Vector2i(43, 23)]}
	for id in portas:
		for p in portas[id]:
			o[p] = "porta"
	# Rio subterrâneo na sala da ponte: só a fileira do meio é chão
	for p in sl["ponte"]:
		if p.x >= 41 and p.x <= 44 and p.y != 13:
			o[p] = "agua"
	# Mobília
	for p in [Vector2i(15, 11), Vector2i(15, 18), Vector2i(25, 11), Vector2i(25, 15)]:
		o[p] = "pilar"
	for p in [Vector2i(33, 12), Vector2i(36, 12), Vector2i(33, 15), Vector2i(36, 19)]:
		o[p] = "sarcofago"
	o[Vector2i(16, 2)] = "altar"
	o[Vector2i(18, 4)] = "npc"
	o[Vector2i(4, 2)] = "bau"
	o[Vector2i(8, 2)] = "bau"
	o[Vector2i(27, 2)] = "estante"
	o[Vector2i(34, 17)] = "estante"
	for p in [Vector2i(32, 26), Vector2i(44, 26), Vector2i(32, 28), Vector2i(44, 30)]:
		o[p] = "pilar"
	# Níveis: braço direito do U, galeria e estrado do santuário ficam no alto
	var niveis := {}
	for p in _ret(23, 8, 26, 18) + sl["galeria"] + [Vector2i(24, 7), Vector2i(31, 3)] + _ret(36, 28, 40, 30):
		niveis[p] = 1
	var escadas := {}
	for p in _ret(23, 19, 26, 19) + _ret(36, 27, 40, 27):
		escadas[p] = true

	var unidades := Dados.herois_cfg(fichas, [Vector2i(3, 15), Vector2i(4, 15), Vector2i(3, 16), Vector2i(4, 16)])
	var ini := []
	# Sala 3 (salão em U): esqueletos e um arqueiro no braço elevado
	for k in 3:
		ini.append(Dados.inimigo_de("salao%d" % (k + 1), "Esqueleto", "esqueleto", [Vector2i(19, 21), Vector2i(21, 22), Vector2i(16, 21)][k],
			"lacaio", "aggro", n, _com(ESQUELETO, {"grupo": "salao"})))
	ini.append(Dados.inimigo_de("salao_arq", "Esqueleto Arqueiro", "esqueleto_arqueiro", Vector2i(24, 12), "medio", "aggro", n,
		_com(_com(ESQUELETO, ATIRADOR), {"grupo": "salao"})))
	# Sala 4 (capela): carniçais
	for k in 2:
		ini.append(Dados.inimigo_de("carnical%d" % (k + 1), "Carniçal", "afogado", [Vector2i(14, 3), Vector2i(17, 2)][k], "medio", "aggro", n,
			{"categoria": "morto-vivo", "visao_no_escuro": true, "tipo_dano": "Corte", "fraquezas": {"Fogo": 2, "Radiante": 2},
				"ao_acertar": [{"ficha": "Sangramento", "max": 1}], "grupo": "capela", "alerta": false, "vigia": 3}))
	# Sala 5 (galeria, no alto): arqueiros e um guarda que se remonta
	for k in 2:
		ini.append(Dados.inimigo_de("galeria_arq%d" % (k + 1), "Esqueleto Arqueiro", "esqueleto_arqueiro", [Vector2i(28, 2), Vector2i(29, 5)][k],
			"lacaio", "aggro", n, _com(_com(ESQUELETO, ATIRADOR), {"grupo": "galeria"})))
	ini.append(Dados.inimigo_de("galeria_guarda", "Guarda de Ossos", "esqueleto", Vector2i(26, 4), "medio", "tank", n, _com(ESQUELETO, {"grupo": "galeria"})))
	# Sala 6 (ossuário): enxame de ossos
	for k in 4:
		ini.append(Dados.inimigo_de("ossos%d" % (k + 1), "Esqueleto", "esqueleto", [Vector2i(34, 5), Vector2i(36, 6), Vector2i(37, 3), Vector2i(33, 7)][k],
			"lacaio", "aggro", n, _com(ESQUELETO, {"grupo": "ossuario", "dormindo": true, "vigia": 2})))
	# Sala 9 (antecâmara): guardas e um fantasma
	for k in 2:
		ini.append(Dados.inimigo_de("ante_guarda%d" % (k + 1), "Guarda de Ossos", "esqueleto", [Vector2i(41, 20), Vector2i(44, 20)][k], "medio", "tank", n,
			_com(ESQUELETO, {"grupo": "antecamara"})))
	ini.append(Dados.inimigo_de("ante_fantasma", "Fantasma Afogado", "fantasma", Vector2i(45, 18), "medio", "control", n,
		{"categoria": "morto-vivo", "visao_no_escuro": true, "tipo_dano": "Necrótico", "flutua": true, "fraquezas": {"Radiante": 3, "Fogo": 1},
			"resiste_tipo": {"Corte": 2, "Perfuração": 2, "Concussão": 2}, "ao_acertar": [{"ficha": "Medo"}], "grupo": "antecamara", "alerta": false, "vigia": 4,
			"habilidades": [{"tipo": "teleporte", "a_cada": 2, "texto": "O fantasma atravessa a parede e reaparece do outro lado da sala."}]}))
	# Sala 10 (santuário): o Guardião, dois cristais e a escolta
	var guardiao := Dados.inimigo_de("guardiao", "Vel-Dorath, o Guardião Sepulto", "cavaleiro_ossudo", Vector2i(38, 29), "chefe", "neutro", n,
		_com(ESQUELETO, {"grupo": "santuario", "tamanho": "grande", "ataque_oportunidade": true, "vigia": 6, "fraquezas": {"Concussão": 2, "Radiante": 3},
			"protegido_por": ["cristal1", "cristal2"],
			"habilidades": [{"tipo": "defensivo", "regen": 8,
					"texto": "Vel-Dorath cruza o escudo diante do peito e os cristais pulsam: neste turno ele não ataca, se recompõe e sofre só metade do dano. No próximo, ele volta com tudo."},
				{"tipo": "marcar_area", "nome": "Martelo do Sepulcro", "raio": 1, "dano": 9, "derrubar": true, "a_cada": 2, "tipo_dano": "Concussão",
					"aviso": "Vel-Dorath ergue o martelo e aponta: o chão em volta do alvo racha em vermelho. No próximo turno dele, o golpe cai ali."}]}))
	ini.append(guardiao)
	for k in 2:
		ini.append({"id": "cristal%d" % (k + 1), "nome": "Cristal de Ligação", "lado": "inimigo", "tipo": "cristal", "pos": [Vector2i(33, 26), Vector2i(43, 29)][k],
			"vida": 16 + 4 * n, "dano": 0, "atributo_dano": 0, "forca": 0, "destreza": 0, "resistencia": 0, "velocidade": 0,
			"mov_por_turno": 0, "padrao_por_turno": 0, "reacao_por_turno": 0, "alerta": false, "vigia": 0, "grupo": "cristais",
			"categoria": "construto", "fraquezas": {"Concussão": 2}, "perfil": "Bruto", "parada_ataque": 15, "parada_defesa": 15, "risco": 0.3})
	for k in 2:
		ini.append(Dados.inimigo_de("santuario_ossos%d" % (k + 1), "Esqueleto", "esqueleto", [Vector2i(39, 26), Vector2i(41, 30)][k], "lacaio", "aggro", n,
			_com(ESQUELETO, {"grupo": "santuario", "escolta": "guardiao"})))
	unidades.append_array(ini)

	return {
		"nome": "Missão: as Catacumbas de Vel-Dorath",
		"objetivo": "Atravesse as catacumbas e derrube o Guardião Sepulto.",
		"vitoria_ao_derrotar_todos": false,
		"vitoria_se_morrer": ["guardiao"],
		"mensagem_vitoria": "Vel-Dorath desaba sobre o estrado e os cristais se apagam. As catacumbas ficam em silêncio pela primeira vez em séculos.",
		"largura": LARGURA, "altura": ALTURA, "obstaculos": o, "niveis": niveis, "escadas": escadas,
		"escuro": true, "piso": "pedra", "recompensa": 200,
		"abertura": {"titulo": "As Catacumbas de Vel-Dorath", "texto": "A escadaria termina numa câmara de pedra úmida. O ar cheira a cera velha e a terra revirada. À frente, um corredor estreito some no escuro; lá no fundo, uma porta dupla com o selo de um cavaleiro."},
		"luzes": [{"pos": Vector2i(4, 14), "claro": 1, "penumbra": 3, "nome": "lamparina da entrada"},
			{"pos": Vector2i(20, 22), "claro": 2, "penumbra": 4, "nome": "braseiro do salão"},
			{"pos": Vector2i(16, 3), "claro": 1, "penumbra": 3, "nome": "velas do altar"},
			{"pos": Vector2i(25, 2), "claro": 2, "penumbra": 4, "nome": "braseiros da galeria"},
			{"pos": Vector2i(36, 14), "claro": 1, "penumbra": 3, "nome": "lâmpada votiva"},
			{"pos": Vector2i(42, 19), "claro": 1, "penumbra": 3, "nome": "runas da antecâmara"},
			{"pos": Vector2i(38, 27), "claro": 3, "penumbra": 5, "nome": "cristais do santuário"}],
		"unidades": unidades,
		"gatilhos": _gatilhos(sl),
		"grupos": _grupos(),
		"armadilhas": _armadilhas(),
		"interacoes": _interacoes(portas),
	}


static func _gatilhos(sl: Dictionary) -> Array:
	var textos := {
		"corredor": ["2. O corredor estreito", "Duas pessoas lado a lado, no máximo. As paredes têm buracos pequenos, alinhados, na altura do peito. No fim, a porta dupla com o selo de um cavaleiro."],
		"salao": ["3. O salão em U", "Um salão em forma de U, com pilares rachados. O braço direito é mais alto: uma escada sobe até lá. No fundo, ossos espalhados... e alguns deles se mexem."],
		"capela": ["4. A capela profanada", "Bancos quebrados e um altar coberto de sangue seco. Alguém geme no canto: um aventureiro, encostado na parede, segurando a barriga."],
		"galeria": ["5. A galeria das urnas", "Uma galeria no alto, cheia de urnas funerárias em nichos. Do lado leste, a beirada dá para um poço de ossos lá embaixo. Há um canto seco, protegido, onde dá para descansar quando a área estiver segura."],
		"ossuario": ["6. O ossuário", "Ossos até a altura do joelho. Crânios empilhados formam paredes. O silêncio aqui é pesado demais."],
		"cripta": ["7. A cripta dos nomes", "Sarcófagos de pedra com nomes raspados. Uma estante guarda livros de registro. No canto sul, a parede é diferente das outras."],
		"ponte": ["8. A ponte sobre o rio", "Um rio subterrâneo corre rápido lá embaixo. Uma ponte estreita de pedra liga as duas margens. As pedras parecem velhas."],
		"antecamara": ["9. A antecâmara", "Runas no chão brilham fraco. As paredes têm marcas de queimado. A porta dupla do outro lado pulsa com uma luz azulada."],
		"santuario": ["10. O santuário do Guardião", "Um salão enorme. No estrado elevado, um cavaleiro de ossos com um martelo do tamanho de um homem. Dois cristais azuis brilham nas pontas do salão, ligados a ele por fios de luz."],
		"tesouro": ["11. A câmara do tesouro", "Uma sala pequena e seca, esquecida. Dois baús, cobertos de pó."],
	}
	var l := []
	for id in textos:
		l.append({"id": "g_" + id, "sala": id, "celulas": sl[id], "titulo": textos[id][0], "texto": textos[id][1], "procurar": id != "santuario"})
	return l


static func _grupos() -> Dictionary:
	return {
		"salao": {"titulo": "Os ossos se levantam", "texto": "Os ossos do fundo do salão se juntam com um estalo seco. Três esqueletos se levantam, e lá no braço elevado um arqueiro encaixa a flecha."},
		"capela": {"titulo": "Carniçais!", "texto": "Duas figuras curvadas largam o que estavam comendo atrás do altar. Têm unhas longas e olhos que brilham no escuro."},
		"galeria": {"titulo": "Os guardiões da galeria", "texto": "Entre as urnas, dois arqueiros de ossos se viram ao mesmo tempo. Um guarda de armadura enferrujada bate a lança no chão."},
		"ossuario": {"titulo": "O ossuário acorda", "texto": "Os montes de ossos tremem. Esqueletos se levantam um por um, ainda incompletos, e avançam em silêncio."},
		"antecamara": {"titulo": "A guarda da antecâmara", "texto": "Dois guardas de ossos se levantam diante da porta azul. Uma figura translúcida atravessa a parede, rindo baixo."},
		"santuario": {"titulo": "Vel-Dorath", "texto": "O cavaleiro no estrado vira a cabeça devagar. \"Ninguém passa do santuário.\" Os cristais brilham mais forte, e os ossos do chão se levantam para protegê-lo."},
	}


static func _armadilhas() -> Array:
	return [
		{"id": "dardos", "sala": "corredor", "nome": "Placa de pressão com dardos", "celulas": [Vector2i(10, 15)], "dif_achar": 15, "dif_evitar": 16, "dif_desarmar": 15,
			"dano": 5, "texto": "Uma placa solta no chão do corredor, ligada aos buracos da parede.", "texto_disparo": "Clique. Dardos saem da parede e acertam você."},
		{"id": "fosso_capela", "sala": "capela", "nome": "Fosso coberto", "celulas": [Vector2i(15, 4)], "dif_achar": 16, "dif_evitar": 17, "dif_desarmar": 16,
			"dano": 6, "ficha": "Imobilizar", "texto": "Um tapete podre cobre um buraco fundo, cheio de estacas.", "texto_disparo": "O chão cede e você cai nas estacas."},
		{"id": "urnas", "sala": "galeria", "nome": "Urnas presas por um fio", "celulas": [Vector2i(23, 3), Vector2i(23, 4)], "dif_achar": 17, "dif_evitar": 16, "dif_desarmar": 16,
			"dano": 5, "texto": "Um fio fino na altura do tornozelo segura urnas pesadas lá em cima.", "texto_disparo": "O fio arrebenta e as urnas despencam."},
		{"id": "laminas", "sala": "cripta", "nome": "Lâminas na parede", "celulas": [Vector2i(35, 18), Vector2i(36, 18)], "dif_achar": 17, "dif_evitar": 17, "dif_desarmar": 17,
			"dano": 6, "ficha": "Sangramento", "texto": "Fendas na parede, com lâminas escondidas.", "texto_disparo": "Lâminas saem da parede num chiado."},
		{"id": "ponte_solta", "sala": "ponte", "nome": "Pedras soltas na ponte", "celulas": [Vector2i(43, 13)], "dif_achar": 16, "dif_evitar": 16, "dif_desarmar": 18,
			"dano": 5, "texto": "Algumas pedras da ponte estão soltas, prontas para virar.", "texto_disparo": "A pedra vira sob o seu pé e você bate feio na borda."},
		{"id": "runa_fogo", "sala": "antecamara", "nome": "Runa de fogo", "celulas": [Vector2i(40, 18)], "dif_achar": 18, "dif_evitar": 17, "dif_desarmar": 18,
			"dano": 4, "ficha": "Fogo", "texto": "Uma runa riscada no chão, quente ao toque.", "texto_disparo": "A runa explode em chamas."},
		{"id": "placa_ante", "sala": "antecamara", "nome": "Placa de pressão", "celulas": [Vector2i(43, 21)], "dif_achar": 16, "dif_evitar": 16, "dif_desarmar": 15,
			"dano": 5, "texto": "Outra placa de pressão, bem gasta.", "texto_disparo": "Um bloco de pedra desce do teto."},
	]


static func _porta(id: String, nome: String, cels: Array, texto: String, abre_texto: String) -> Dictionary:
	return {"id": id, "nome": nome, "pos": cels[0], "alcance": 1, "texto": texto,
		"opcoes": [{"id": "abrir", "texto": "Abrir (ação livre)", "resultado": "aberta",
			"resultados": {"aberta": {"texto": abre_texto, "efeitos": [_ef("abrir_caminho", {"celulas": cels}), _ef("desativar")]}}}]}


static func _interacoes(portas: Dictionary) -> Array:
	var l := [
		_porta("porta_dupla", "Porta dupla com selo", portas["porta_dupla"], "Duas folhas de carvalho com o selo de um cavaleiro: um martelo sobre um escudo.", "As duas folhas se abrem, rangendo."),
		_porta("porta_capela", "Porta da capela", portas["porta_capela"], "Uma porta estreita. Do outro lado, alguém geme.", "A porta abre para a capela."),
		_porta("porta_galeria", "Porta da galeria", portas["porta_galeria"], "No alto do braço do salão, uma porta baixa.", "A porta dá para uma galeria cheia de urnas."),
		_porta("porta_cripta", "Grade da cripta", portas["porta_cripta"], "Uma grade de ferro, sem cadeado.", "A grade sobe com um chiado."),
		_porta("porta_antecamara", "Porta da antecâmara", portas["porta_antecamara"], "Uma porta de pedra com runas apagadas.", "A pedra desliza para o lado."),
		_porta("porta_santuario", "Porta azul do santuário", portas["porta_santuario"], "Uma porta dupla que pulsa com luz azul. Do outro lado, um coração de pedra bate devagar.", "As portas se abrem sozinhas. A luz azul inunda o corredor."),
		# Porta trancada da ponte: fechadura, força ou Fechadura Fantasma de longe
		{"id": "porta_ponte", "nome": "Porta trancada", "pos": portas["porta_ponte"][0], "alcance": 3,
			"texto": "Uma porta de ferro com um cadeado grosso. Do outro lado, barulho de água correndo.",
			"opcoes": [
				{"id": "fechadura", "texto": "Abrir o cadeado (Ladinagem + Destreza)", "alcance": 1, "custo": {"padrao": 1}, "teste": {"somar": ["Ladinagem", "destreza"]}, "nivel": "medio",
					"vantagem_com": ["ferramentas_de_ladrao"],
					"resultados": {"falha": {"rotulo": "emperra", "texto": "O cadeado não cede. Dá para tentar de novo."},
						"sucesso": {"rotulo": "aberta", "texto": "Clique. O cadeado cai.", "efeitos": [_ef("abrir_caminho", {"celulas": portas["porta_ponte"]}), _ef("desativar")]}}},
				{"id": "arrombar", "texto": "Arrombar (Atletismo + Força)", "alcance": 1, "custo": {"padrao": 1}, "teste": {"somar": ["Atletismo", "forca"]}, "nivel": "dificil",
					"vantagem_com": ["pe_de_cabra"],
					"resultados": {"falha": {"rotulo": "aguenta", "texto": "A porta treme, mas aguenta. O ombro dói.", "efeitos": [_ef("dano", {"valor": 2})]},
						"sucesso": {"rotulo": "arrombada", "texto": "A porta voa das dobradiças.", "efeitos": [_ef("abrir_caminho", {"celulas": portas["porta_ponte"]}), _ef("desativar")]}}},
				{"id": "fantasma", "texto": "Fechadura Fantasma (de até 3 casas, Ladinagem fácil)", "requer_carta": ["fechadura-fantasma"], "custo": {"padrao": 1},
					"teste": {"somar": ["Ladinagem"]}, "nivel": "facil",
					"resultados": {"falha": {"rotulo": "escapa", "texto": "A mão fantasma escorrega no ferro."},
						"sucesso": {"rotulo": "aberta", "texto": "Uma mão translúcida gira a chave por dentro.", "efeitos": [_ef("abrir_caminho", {"celulas": portas["porta_ponte"]}), _ef("desativar")]}}},
			]},
		# Parede rachada: a Avalanche derruba; os outros, na força
		{"id": "parede_rachada", "nome": "Parede rachada", "pos": Vector2i(27, 21), "alcance": 1,
			"texto": "As pedras aqui estão soltas e rachadas. Atrás, um vento frio passa pelas frestas: há uma passagem.",
			"opcoes": [
				{"id": "avalanche", "texto": "Derrubar com a Avalanche (sem teste)", "requer_carta": ["avalanche"], "custo": {"padrao": 1}, "resultado": "cai",
					"resultados": {"cai": {"texto": "Um golpe só. A parede desaba e abre uma passagem para o leste.",
						"efeitos": [_ef("abrir_caminho", {"celulas": _ret(27, 21, 27, 22)}), _ef("desativar")]}}},
				{"id": "forca", "texto": "Derrubar na força (Atletismo + Força)", "custo": {"padrao": 1}, "teste": {"somar": ["Atletismo", "forca"]}, "nivel": "dificil",
					"vantagem_com": ["pe_de_cabra"],
					"resultados": {"falha": {"rotulo": "resiste", "texto": "Pedaços caem, mas a parede aguenta. O barulho ecoa.", "efeitos": [_ef("dano", {"valor": 2})]},
						"sucesso": {"rotulo": "cai", "texto": "A parede desaba numa nuvem de pó.", "efeitos": [_ef("abrir_caminho", {"celulas": _ret(27, 21, 27, 22)}), _ef("desativar")]}}},
				{"id": "magia", "texto": "Explodir com magia de terra (Arcanismo + Raciocínio)", "requer_classe": ["Mago"], "custo": {"padrao": 1},
					"teste": {"somar": ["Arcanismo", "raciocinio"]}, "nivel": "medio",
					"resultados": {"falha": {"rotulo": "racha mais", "texto": "A pedra racha um pouco mais."},
						"sucesso": {"rotulo": "explode", "texto": "A parede vira pó.", "efeitos": [_ef("abrir_caminho", {"celulas": _ret(27, 21, 27, 22)}), _ef("desativar")]}}},
			]},
		# Aventureiro ferido: Medicina para todos; o Clérigo cura mais fácil
		{"id": "ferido", "nome": "Tomás, aventureiro ferido", "pos": Vector2i(18, 4), "alcance": 1,
			"texto": "Um homem jovem, pálido, com a barriga enfaixada de qualquer jeito. \"Vocês... vieram atrás do Guardião também? Não cheguem perto dele enquanto os cristais brilharem.\"",
			"opcoes": [
				{"id": "tratar", "texto": "Tratar os ferimentos (Medicina + Sabedoria)", "custo": {"padrao": 1}, "teste": {"somar": ["Medicina", "sabedoria"]}, "nivel": "dificil",
					"resultados": {
						"falha": {"rotulo": "piora", "texto": "Você aperta a ferida, mas ele desmaia de dor. Antes, murmura: \"os cristais...\"",
							"efeitos": [_ef("desativar")]},
						"sucesso": {"rotulo": "salvo", "texto": "Você limpa e costura a ferida. Ele respira melhor. \"O Guardião sofre metade de tudo enquanto os dois cristais estiverem inteiros. Quebrem os cristais primeiro. E ele fica em guarda um turno sim, um não: ataquem quando ele baixar o escudo.\" Ele entrega o que tem.",
							"efeitos": [_ef("item", {"item": "pocao_de_cura_pequena"}), _ef("desativar")]}}},
				{"id": "curar", "texto": "Curar com a fé (Religião + Sabedoria, fácil)", "requer_carta": ["toque-restaurador", "primeiros-socorros", "ressurgir"], "custo": {"padrao": 1},
					"teste": {"somar": ["Religião", "sabedoria"]}, "nivel": "facil",
					"resultados": {
						"falha": {"rotulo": "fraco", "texto": "A luz vacila. Ele continua consciente, mas fraco. \"Os cristais... quebrem os cristais.\""},
						"sucesso": {"rotulo": "curado", "texto": "A ferida fecha sob a luz. Tomás se levanta. \"Quebrem os cristais primeiro: enquanto brilham, ele sofre metade. E ele se fecha em guarda turno sim, turno não.\" Ele dá a vocês o que tem e volta pela entrada.",
							"efeitos": [_ef("item", {"item": "pocao_de_cura_pequena", "qtd": 2}), _ef("ouro", {"valor": 20}), _ef("fichas_grupo", {"ficha": "Foco"}), _ef("desativar")]}}},
			]},
		Exploracao.estante_lore("registros_cripta", Vector2i(34, 17), "Livros de registro",
			"Livros de couro, inchados de umidade.",
			"Os registros contam de Vel-Dorath, cavaleiro que jurou guardar o santuário depois da morte. Os cristais de ligação prendem a alma dele ao corpo: \"enquanto brilharem, metade de toda ferida volta para a pedra\".",
			[], "História"),
		Exploracao.estante_lore("urnas_galeria", Vector2i(27, 2), "Nichos das urnas",
			"Urnas com nomes de famílias da região.",
			"Uma urna tem o selo do martelo, igual ao da porta dupla. Dentro, só cinzas e um bilhete: \"Ele ainda guarda. Ele sempre vai guardar.\"",
			[], "Religião"),
		# Descanso: só na sala 5, e só depois de vencer 3 combates
		_descanso_galeria(),
		# Beirada da galeria: pular no ossuário
		{"id": "beirada", "nome": "Beirada do ossuário", "pos": Vector2i(31, 3), "alcance": 1,
			"texto": "A beirada dá para o ossuário, uns três metros abaixo. Não há escada deste lado.",
			"opcoes": [
				{"id": "descer", "texto": "Descer pela parede (Escalada + Força)", "custo": {"movimento": 1}, "teste": {"somar": ["Escalada", "forca"], "movimento": true}, "nivel": "medio",
					"vantagem_com": ["corda"],
					"resultados": {
						"falha": {"rotulo": "escorrega", "texto": "A mão escorrega na pedra e você cai no meio dos ossos.",
							"efeitos": [_ef("mover", {"para": Vector2i(33, 3)}), _ef("queda", {"quadrados": 2})]},
						"sucesso": {"rotulo": "desce", "texto": "Você desce devagar até o ossuário.", "efeitos": [_ef("mover", {"para": Vector2i(33, 3)})]}}},
				{"id": "pular", "texto": "Pular (sem teste: cai 2 quadrados)", "custo": {"movimento": 1}, "resultado": "pula",
					"resultados": {"pula": {"texto": "Você pula no ossuário.", "efeitos": [_ef("mover", {"para": Vector2i(33, 3)}), _ef("queda", {"quadrados": 2})]}}},
			]},
		# Escondidos: acha quem procurar
		{"id": "alavanca", "nome": "Alavanca atrás do altar", "pos": Vector2i(16, 1), "alcance": 1, "oculta": true, "ativa": false, "dif_achar": 17, "sala": "capela",
			"texto": "Uma alavanca de ferro, escondida atrás do altar.",
			"opcoes": [{"id": "puxar", "texto": "Puxar a alavanca", "custo": {"padrao": 1}, "resultado": "abre",
				"resultados": {"abre": {"texto": "Um bloco de pedra desliza na parede oeste: há uma passagem secreta.",
					"efeitos": [_ef("abrir_caminho", {"celulas": [Vector2i(10, 3), Vector2i(11, 3), Vector2i(12, 3)]}), _ef("desativar")]}}}]},
		{"id": "gaveta", "nome": "Gaveta na lápide", "pos": Vector2i(33, 12), "alcance": 1, "oculta": true, "ativa": false, "dif_achar": 16, "sala": "cripta",
			"texto": "Uma lápide com uma gaveta escondida no pé.",
			"opcoes": [{"id": "abrir", "texto": "Abrir a gaveta", "custo": {"padrao": 1}, "resultado": "acha",
				"resultados": {"acha": {"texto": "Dentro, oferendas esquecidas.", "efeitos": [_ef("item", {"item": "pocao_de_cura_pequena", "qtd": 2}), _ef("ouro", {"valor": 20}), _ef("desativar")]}}}]},
		Exploracao.movel_com_itens("bau_tesouro1", Vector2i(4, 2), "Baú antigo", "Um baú de ferro, sem fechadura.", ["pocao_de_cura_pequena", "pocao_de_mana_pequena"], 40),
		Exploracao.movel_com_itens("bau_tesouro2", Vector2i(8, 2), "Baú pequeno", "Um baú de madeira escura.", ["antidoto", "oleo_antiespectral"], 30),
		# Cristais: atacar ou drenar (Arcanismo)
		_cristal("cristal1", Vector2i(33, 26)),
		_cristal("cristal2", Vector2i(43, 29)),
	]
	return l


static func _descanso_galeria() -> Dictionary:
	var d := Exploracao.ponto_de_descanso("descanso_galeria", Vector2i(22, 5), "Canto seco da galeria",
		"Um canto seco e protegido, longe das urnas. Só é seguro depois que as salas em volta estiverem limpas.")
	d["opcoes"][0]["requer_combates"] = 3
	return d


static func _cristal(id: String, pos: Vector2i) -> Dictionary:
	return {"id": "it_" + id, "nome": "Cristal de Ligação", "pos": pos, "alcance": 1, "unidade": id,
		"texto": "Um cristal azul do tamanho de um homem, ligado ao Guardião por um fio de luz. Atacar quebra (Concussão é melhor). Quem conhece magia pode tentar drenar o cristal.",
		"opcoes": [{"id": "drenar", "texto": "Drenar a magia (Arcanismo + Raciocínio)", "custo": {"padrao": 1}, "teste": {"somar": ["Arcanismo", "raciocinio"]}, "nivel": "medio",
			"resultados": {
				"falha": {"rotulo": "choque", "texto": "A magia volta em você num choque.", "efeitos": [_ef("dano", {"valor": 3})]},
				"sucesso": {"rotulo": "apagado", "texto": "A luz escorre do cristal para as suas mãos e ele racha. Sobra uma lasca valiosa.",
					"efeitos": [_ef("matar_unidade", {"id": id}), _ef("item", {"item": "cristal_de_ligacao"}), _ef("desativar")]}}}]}
