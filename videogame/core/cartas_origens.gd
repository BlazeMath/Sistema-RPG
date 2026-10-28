## Efeitos das cartas de raça e background (e das metades de herói delas), e
## das cartas do Guerreiro que dependem de aliados. A batalha chama estas
## funções pelo mesmo caminho das cartas de classe (core/cartas_classes.gd).
extends RefCounted

const Grade := preload("res://core/grade.gd")
const Carta := preload("res://core/carta.gd")

const ATIVADAS_DE_HEROI := {
	"o-atemporal": {"uso": "ativada", "alvo": "nenhum"},
	"o-inabalavel": {"uso": "ativada", "alvo": "nenhum"},
	"palavra-de-aco": {"uso": "ativada", "alvo": "inimigo_visivel"},
	"a-boa-estrela": {"uso": "ativada", "alvo": "nenhum"},
	"matador-de-gigante": {"uso": "ativada", "alvo": "inimigo_magico", "alcance": 1, "so_grandes": true},
	"furia-crescente": {"uso": "ativada", "alvo": "inimigo_arma", "exige_fichas": {"Fúria": 1}},
	"o-oportunista": {"uso": "ativada", "alvo": "inimigo_magico", "alcance": 4},
	"sempre-uma-saida": {"uso": "ativada", "alvo": "nenhum"},
	"o-sobrevivente": {"uso": "ativada", "alvo": "nenhum", "exige_fichas": {"Ferimento": 1}},
	"trabalhador": {"uso": "ativada", "alvo": "nenhum"},
	"conhecedor-do-terreno": {"uso": "ativada", "alvo": "nenhum"},
	"mestre-das-cavernas": {"uso": "ativada", "alvo": "nenhum"},
	"seguidor-da-chama": {"uso": "ativada", "alvo": "aliado", "alcance": 4},
}

const TAMANHO := {"pequeno": 0, "medio": 1, "grande": 2, "enorme": 3}


static func maior(a, b) -> bool:
	return int(TAMANHO.get(a.tamanho, 1)) > int(TAMANHO.get(b.tamanho, 1))


static func motivo_extra(b, u, c) -> String:
	match c.slug():
		"furia-crescente", "golpe-selvagem":
			if u.acoes_padrao <= 0 and c.slug() == "furia-crescente":
				return "sem ação padrão (o ataque usa a ação)"
		"couro-grosso":
			if u.efeitos.has("couro_grosso"):
				return "já ativo"
		"pes-no-telhado":
			if u.efeitos.has("pes_no_telhado"):
				return "já ativo neste turno"
		"mestre-das-cavernas":
			if u.efeitos.has("mestre_usado"):
				return "uma vez por descanso longo"
		"espirito-inquebravel":
			if u.fichas_total("Ferimento") + u.fichas_total("Medo") == 0:
				return "sem Ferimento nem Medo"
		"seguidor-da-chama":
			if not b.herois_ativos().any(func(h): return h.fichas_total("Fogo") > 0 and Grade.distancia(h.pos, u.pos) <= 4):
				return "nenhum aliado em chamas"
		"o-inabalavel":
			if not u.cartas.any(func(x): return x.fadiga > 0 and x != c):
				return "nenhuma carta com fadiga"
	return ""


static func usar(b, u, c, alvo) -> void:
	var nome: String = c.nome()
	match c.slug():
		# --- Raças ------------------------------------------------------------
		"saber-natural":
			var n: int = alvo.tirar_fichas("Sangramento", 1) + alvo.tirar_fichas("Ferimento", 1)
			b._log("Emplastro: %s perde %d ficha(s) (Sangramento e Ferimento)." % [alvo.nome, n])
		"golpe-selvagem":
			b._novo_ataque(u, alvo, {"habilidade": nome, "ao_acertar": [{"ficha": "Ferimento"}, {"empurrar": 1}]})
		"folego-feroz":
			for i in 3:
				if not u.baralho.descarte.is_empty():
					b._curar(u, u.constituicao, "recupera o fôlego (Fôlego Feroz)")
			if not u.baralho.mao.is_empty():
				var menor: int = u.baralho.mao[0]
				for carta in u.baralho.mao:
					if Carta.valor(carta) < Carta.valor(menor):
						menor = carta
				u.baralho.tirar_da_mao(menor)
				u.baralho.descarte.append(menor)
			else:
				var topo: int = u.baralho.puxar_topo()
				if topo >= 0:
					u.baralho.descarte.append(topo)
			b._log("Fôlego Feroz: depois, %s descarta uma carta." % u.nome)
		"presenca-aterradora":
			var dif: int = b.valor_resistido(alvo, "espirito")
			b.teste_de_acao(u, {"titulo": "Presença Aterradora contra %s" % alvo.nome, "texto": "Intimidar",
				"teste": {"somar": ["Intimidação"]}, "dificuldade": dif,
				"resultados": {
					"falha": {"rotulo": "não se abala", "texto": "%s encara você de volta." % alvo.nome},
					"sucesso": {"rotulo": "apavorado", "texto": "%s recua, com medo." % alvo.nome,
						"efeitos": [{"tipo": "fichas_alvo", "ficha": "Medo"}]},
				}}, alvo)
		"couro-grosso":
			u.efeitos["couro_grosso"] = {"ate": "inicio_turno"}
			b._log("Couro Grosso: %s ganha resistência 1 até o próximo turno." % u.nome)
		# --- Backgrounds ------------------------------------------------------
		"pes-no-telhado":
			u.efeitos["pes_no_telhado"] = {"ate": "inicio_turno"}
			b._log("Pés no Telhado: +1 de velocidade até o fim do turno.")
		"astucia-de-rua":
			u.efeitos["astucia_de_rua"] = {"ate": "inicio_turno"}
			b._log("Astúcia de Rua: +1 em testes de armadilha até o fim do turno.")
		"espirito-inquebravel":
			var n: int = u.tirar_fichas("Ferimento") + u.tirar_fichas("Medo")
			b._log("Espírito Inquebrável: %s tira %d ficha(s) de Ferimento e Medo." % [u.nome, n])
		"senso-de-direcao":
			u.dar_ficha("Foco")
		"palavra-que-conforta":
			var n: int = alvo.tirar_fichas("Medo", 1)
			if n == 0:
				n = alvo.tirar_fichas("Atormentado", 1)
			b._log("Palavra que Conforta: %s se acalma (%d ficha retirada)." % [alvo.nome, n])
		# --- Guerreiro com aliados -------------------------------------------
		"provocar":
			var dif: int = b.valor_resistido(alvo, "sabedoria")
			var comp := "Irritar"
			b.teste_de_acao(u, {"titulo": "Provocar %s" % alvo.nome, "texto": "Provocar",
				"teste": {"somar": [comp]}, "dificuldade": dif,
				"resultados": {
					"falha": {"rotulo": "ignorado", "texto": "%s não morde a isca." % alvo.nome},
					"sucesso": {"rotulo": "provocado", "texto": "%s fica furioso com você." % alvo.nome,
						"efeitos": [{"tipo": "provocar_alvo"}]},
				}}, alvo)
		"aguentem-recrutas":
			for h in b.herois_ativos():
				if h != u and Grade.adjacentes(h.pos, u.pos):
					b._tirar_fadiga(h, 1)
					h.efeitos["aguentem"] = {"ate": "inicio_turno"}
			b._log("Aguentem, Recrutas!: aliados adjacentes recuperam 1 de fadiga e ganham +1 de resistência.")
		# --- Metades de herói -------------------------------------------------
		"o-atemporal":
			u.acoes_reacao += 1
			b._log("O Atemporal: %s ganha uma Reação." % u.nome)
		"o-inabalavel":
			var maior_c = null
			for x in u.cartas:
				if x != c and x.fadiga > 0 and (maior_c == null or x.fadiga > maior_c.fadiga):
					maior_c = x
			if maior_c != null:
				maior_c.fadiga -= 1
				b._log("O Inabalável: −1 de fadiga em %s." % maior_c.nome())
		"palavra-de-aco":
			u.efeitos["juramento"] = {"alvo": alvo.id}
			b._log("Palavra de Aço: %s jura por %s até o fim da cena." % [u.nome, alvo.nome])
		"a-boa-estrela":
			var alvos: Array = b.inimigos_vivos().filter(func(o): return Grade.distancia(o.pos, u.pos) <= 12 and b.grade.linha_de_visao(u.pos, o.pos))
			alvos.sort_custom(func(x, y): return Grade.distancia(x.pos, u.pos) < Grade.distancia(y.pos, u.pos))
			for o in alvos.slice(0, 2):
				o.dar_ficha("Penalidade", 2)
				b._log("A Boa Estrela: %s recebe 2 fichas de Penalidade (1 + 1 da desencadeada)." % o.nome)
		"matador-de-gigante":
			var dif: int = b.valor_resistido(alvo, "forca")
			b.teste_de_acao(u, {"titulo": "Matador de Gigante contra %s" % alvo.nome, "texto": "Derrubar o gigante",
				"teste": {"somar": ["espirito"]}, "dificuldade": dif,
				"resultados": {
					"falha": {"rotulo": "não cede", "texto": "%s não se mexe." % alvo.nome},
					"sucesso": {"rotulo": "empurrado", "texto": "Você joga %s para trás e o derruba." % alvo.nome,
						"efeitos": [{"tipo": "empurrar_alvo", "valor": 3}, {"tipo": "derrubar_alvo"}]},
				}}, alvo)
		"furia-crescente":
			u.acoes_padrao -= 1
			var n: int = c.fichas.get("Fúria", 0)
			c.fichas.erase("Fúria")
			b._novo_ataque(u, alvo, {"habilidade": nome, "bonus_dano": 2 * n, "rotulo_bonus": "Fúria (%d)" % n})
		"o-oportunista":
			alvo.dar_ficha("Penalidade")
			b._log("O Oportunista: %s recebe 1 ficha de Penalidade." % alvo.nome)
		"sempre-uma-saida":
			b.teste_de_acao(u, {"titulo": "Sempre uma Saída", "texto": "Escapar",
				"teste": {"somar": ["Acrobacia", "destreza"], "movimento": true}, "dificuldade": 18,
				"resultados": {
					"falha": {"rotulo": "não sai", "texto": "Não dá para escapar agora."},
					"sucesso": {"rotulo": "escapa", "texto": "Você salta por cima e escapa.",
						"efeitos": [{"tipo": "deslocamento", "valor": 3}, {"tipo": "desengajar"}]},
				}})
		"o-sobrevivente":
			u.tirar_fichas("Ferimento", 1)
			u.dar_ficha("Foco")
			b._log("O Sobrevivente: um Ferimento vira Foco.")
		"trabalhador":
			u.efeitos["trabalhador"] = {"ate": "inicio_turno"}
			b._log("Trabalhador: sem penalidade de arma e armadura pesadas até o fim do turno.")
		"conhecedor-do-terreno":
			u.efeitos["interacoes_gratis"] = {"valor": 2, "ate": "inicio_turno"}
			b._log("Conhecedor do Terreno: as próximas duas interações deste turno não gastam ação Padrão.")
		"mestre-das-cavernas":
			u.efeitos["mestre_usado"] = {}
			u.consumiveis.append("tocha")
			if not "corda" in u.equipamentos:
				u.equipamentos.append("corda")
			b._log("Mestre das Cavernas: %s improvisa corda, tocha e faca." % u.nome)
		"seguidor-da-chama":
			var n: int = alvo.tirar_fichas("Fogo")
			b._log("Seguidor da Chama: o fogo de %s se apaga (%d ficha(s))." % [alvo.nome, n])
		_:
			preload("res://core/cartas_extras.gd").usar(b, u, c, alvo)


## Ao virar para estes lados.
static func ao_virar(b, u, c) -> void:
	match c.slug():
		"movimento-guiado":
			for h in b.herois_ativos():
				if h != u and Grade.distancia(h.pos, u.pos) <= 3:
					h.efeitos["movimento_guiado"] = {}
			b._log("Movimento Guiado: aliados por perto podem andar 1 sem provocar reações no próximo turno deles.")
		"braco-de-labuta":
			b._ajustar_forca(u, 1)
	if c.lados.size() > 1 and Catalogo_slug(c.lados[1 - c.lado]["nome"]) == "braco-de-labuta":
		b._ajustar_forca(u, -1)


static func Catalogo_slug(nome: String) -> String:
	return preload("res://core/catalogo.gd").slug(nome)


static func inicio_do_turno(b, u) -> void:
	if u.ativo("couro-duro") and u.baralho.descarte.size() >= 10 and not u.efeitos.has("couro_duro_usado"):
		u.efeitos["couro_duro_usado"] = {}
		var i: int = b.rng.randi_range(0, u.baralho.descarte.size() - 1)
		u.baralho.exilio.append(u.baralho.descarte[i])
		u.baralho.descarte.remove_at(i)
		var n := 0
		while n < 10 and not u.baralho.descarte.is_empty():
			u.baralho.baralho.append(u.baralho.descarte.pop_back())
			n += 1
		u.baralho.embaralhar()
		b._log("Couro Duro: %s exila 1 carta do descarte e embaralha %d de volta no baralho." % [u.nome, n])
	if u.efeitos.has("movimento_guiado"):
		u.efeitos.erase("movimento_guiado")
		u.deslocamento += 1
		u.efeitos["desengajar"] = {"ate": "inicio_turno"}
	if u.ativo("seguidor-da-noite") and b.sombra_usada:
		u.efeitos["seguidor_da_noite"] = {"ate": "inicio_turno"}
		b._log("Seguidor da Noite: um aliado usou Sombra; %s tem +2 nos testes neste turno." % u.nome)
	if u.ativo("seguidor-da-noite"):
		b.sombra_usada = false


## Fim do turno de um herói: Fôlego de Viajante e Aconchego.
static func fim_do_turno(b, u) -> void:
	# Fôlego de Viajante: agora é um ponto a mais na tela de fim do turno (Batalha.opcoes_fim_de_turno).
	for h in b.herois_ativos():
		if h != u and h.ativo("aconchego") and Grade.adjacentes(h.pos, u.pos):
			var usados: Array = u.efeitos.get("aconchego", {}).get("usados", [])
			var feito := ""
			if not "medo" in usados and u.tirar_fichas("Medo", 1) > 0:
				feito = "medo"
			elif not "atormentado" in usados and u.tirar_fichas("Atormentado", 1) > 0:
				feito = "atormentado"
			elif not "fadiga" in usados and b._tirar_fadiga(u, 1) > 0:
				feito = "fadiga"
			if feito != "":
				usados.append(feito)
				u.efeitos["aconchego"] = {"usados": usados}
				b._log("Aconchego de %s: %s se sente melhor (%s)." % [h.nome, u.nome, feito])
			break


static func critico(b, u, slug: String) -> void:
	match slug:
		"o-atemporal":
			u.acoes_padrao += 1
			b._log("O Atemporal: %s ganha uma ação Padrão." % u.nome)
			b._virar(u, u.carta_heroi())
		"o-inabalavel":
			u.dar_ficha("Bloqueio", maxi(u.espirito, 1))
			b._log("O Inabalável: %s ganha %d ficha(s) de Bloqueio." % [u.nome, maxi(u.espirito, 1)])
		"a-boa-estrela", "mestre-das-cavernas":
			if not u.gastos.is_empty():
				var item: String = u.gastos.pop_back()
				u.consumiveis.append(item)
				b._log("%s recupera %s." % [u.nome, b._nome_item(item)])
		"matador-de-gigante":
			b.fadiga_dupla = true
			b._log("Matador de Gigante: até o fim da cena, todos recuperam 2 de fadiga no fim do turno.")
		"furia-crescente":
			u.carta_com("furia-crescente").dar_ficha("Fúria", 3)
			b._log("Fúria Crescente: +3 fichas de Fúria.")
		"brado-da-horda":
			for h in b.herois_ativos():
				b._tirar_fadiga(h, maxi(h.espirito, h.forca))
			b._log("Brado da Horda: cada aliado descarta fadiga igual ao Espírito ou à Força.")
		"sempre-uma-saida":
			u.dar_ficha("Sombra", maxi(u.destreza, 1))
		"o-sobrevivente":
			var viradas := 0
			for x in u.cartas:
				if viradas < 2 and x.tipo != "heroi" and x.lados.size() > 1 and x.fadiga > 0:
					b._virar(u, x)
					viradas += 1
		"trabalhador":
			u.baralho.descarte.append_array(u.baralho.exilio)
			u.baralho.exilio.clear()
			b._log("Trabalhador: o exílio de %s volta para o descarte." % u.nome)
		"conhecedor-do-terreno":
			for x in u.cartas:
				var n: int = x.fichas.get("Foco", 0)
				if n > 0:
					x.fichas.erase("Foco")
					x.dar_ficha("Preparo", n)
		"seguidor-da-chama":
			var alvo = null
			for o in b.inimigos_vivos():
				if Grade.distancia(o.pos, u.pos) <= 4:
					alvo = o
			if alvo != null:
				alvo.dar_ficha("Fogo")
				b._log("Seguidor da Chama: %s pega fogo." % alvo.nome)
			else:
				b._curar(u, 1, "sente o calor da chama")
		"seguidor-da-noite":
			b.sem_reacoes_ate = u.id
			b._log("Seguidor da Noite: até o próximo turno de %s, os inimigos não fazem reações." % u.nome)
		"palavra-de-aco":
			var jur = u.efeitos.get("juramento", {}).get("alvo", "")
			if jur != "" and b.defensor != null and b.defensor.id == jur:
				u.baralho.comprar_para_mao(3)
				b._log("Palavra de Aço: o crítico foi contra o alvo do juramento; %s compra 3 cartas." % u.nome)
		"mil-oficios":
			var topo: Array = u.baralho.baralho.slice(-4)
			topo.reverse()
			b.eventos.append({"tipo": "espiar", "id": u.id, "titulo": "Mil Ofícios:\nas 4 do topo", "cartas": topo})
