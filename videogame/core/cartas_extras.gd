## Lados de carta que faltavam (0.23). Registro (como em core/efeitos.gd) e efeitos.
## Chamado por Batalha._registro_do_lado (LADOS), Batalha.motivo_sem_carta (motivo),
## Origens.usar (usar), Batalha._virar (ao_virar) e o ataque do herói (antes/depois).
extends RefCounted

const Grade := preload("res://core/grade.gd")

const LADOS := {
	"escudo-agil": {"uso": "ativada", "alvo": "nenhum"},
	"avanco-combinado": {"uso": "ativada", "alvo": "aliado", "alcance": 4, "sem_si": true, "nota": "os dois avançam na direção do inimigo mais perto"},
	"instruir-armamento": {"uso": "ativada", "alvo": "nenhum", "nota": "aliados ao lado trocam de arma de graça uma vez"},
	"assalto-do-gatuno": {"uso": "ativada", "alvo": "inimigo_corpo"},
	"olha-la": {"uso": "ativada", "alvo": "nenhum"},
	"finta": {"uso": "ativada", "alvo": "nenhum", "exige_fichas": {"Sombra": 1}, "custo": {"fadiga": 0, "acao": null}},
	"fechadura-fantasma": {"uso": "fora", "nota": "aparece como opção nas fechaduras do mapa, a até 3 casas"},
	"gancho-fantasma": {"uso": "ativada", "alvo": "inimigo_magico", "alcance": 4, "custo": {"fadiga": 2, "acao": "movimento"}, "nota": "só a primeira ativada (puxar o alvo)"},
	"adaga-fantasma": {"uso": "ativada", "alvo": "nenhum", "custo": {"fadiga": 0, "acao": null}},
	"empurrao-mistico": {"uso": "ativada", "alvo": "inimigo_magico", "alcance": 4, "custo": {"fadiga": 1, "acao": "padrao"}, "nota": "a parte do objeto pequeno ainda não"},
	"adaptavel": {"uso": "ativada", "alvo": "nenhum", "custo": {"fadiga": 0, "acao": null}, "opcoes": [
		{"id": "heroi", "nome": "Virar a carta de herói"}, {"id": "arma", "nome": "Virar a carta de arma"}]},
	"passo-espectral": {"uso": "ativada", "alvo": "nenhum", "custo": {"fadiga": 0, "acao": "movimento"}, "nota": "a reação (metade do dano à distância) ainda não"},
	"voz-do-exorcista": {"uso": "reacao", "nota": "automática: anula reações de mortos-vivos e demônios"},
	"hino-de-coragem": {"uso": "ativada", "alvo": "nenhum"},
	"prece-rapida": {"uso": "ativada", "alvo": "nenhum", "custo": {"fadiga": 1, "acao": null}},
	"intervencao-divina": {"uso": "ao_virar"},
	"estudar-a-presa": {"uso": "ativada", "alvo": "inimigo_visivel"},
	"cabra-da-montanha": {"uso": "ativada", "alvo": "nenhum", "custo": {"fadiga": 1, "acao": "movimento"}},
	"ponto-de-vantagem": {"uso": "ativada", "alvo": "nenhum", "custo": {"fadiga": 1, "acao": null}},
	"olho-de-aguia": {"uso": "ativada", "alvo": "nenhum", "custo": {"fadiga": 1, "acao": null}},
	"nada-escapa": {"uso": "passiva", "nota": "inimigos não viram cartas: a Marcação já não sai; a reação ainda não"},
	"tecer-com-maestria": {"uso": "ativada", "alvo": "nenhum", "custo": {"fadiga": 1, "acao": null}},
	"reflexo-arcano": {"uso": "ativada", "alvo": "nenhum", "custo": {"fadiga": 1, "acao": null}, "nota": "só a segunda ativada (ganhar Reação)"},
	"servo-sombrio": {"uso": "ativada", "alvo": "inimigo_visivel", "custo": {"fadiga": 3, "acao": "padrao"}},
	"resistencia-do-corredor": {"uso": "passiva"},
	"olho-de-veterano": {"uso": "passiva"},
	"maos-leves": {"uso": "ativada", "alvo": "inimigo_corpo", "custo": {"fadiga": 1, "acao": null}, "nota": "vantagem em Furtividade e Ladinagem sempre"},
}


static func motivo(b, u, c) -> String:
	match c.slug():
		"adaga-fantasma":
			if c.tem_ficha("Atormentado"):
				return "já tem Atormentado (vire a carta)"
			if u.efeitos.has("adaga_fantasma"):
				return "já preparada"
		"finta":
			if u.efeitos.has("finta"):
				return "já preparada"
		"adaptavel":
			if u.baralho.mao.is_empty():
				return "sem carta na mão"
		"tecer-com-maestria":
			if u.efeitos.has("tecer"):
				return "já preparada"
		"maos-leves":
			if not b.unidades.any(func(o): return o.efeitos.get("agarrado", {}).get("por", "") == u.id):
				return "precisa estar agarrando alguém"
	return ""


static func usar(b, u, c, alvo) -> void:
	var nome: String = c.nome()
	match c.slug():
		"escudo-agil":
			u.efeitos["escudo_agil"] = {"ate": "inicio_turno"}
			b._log("%s: aliados ao lado de %s têm cobertura parcial até o próximo turno dele." % [nome, u.nome])
		"avanco-combinado":
			var perto: Array = b.inimigos_vivos().filter(func(o): return b.unidade_visivel(o))
			if perto.is_empty():
				return
			perto.sort_custom(func(a, x): return Grade.distancia(a.pos, u.pos) < Grade.distancia(x.pos, u.pos))
			var destino: Vector2i = perto[0].pos
			for quem in [u, alvo]:
				b._andar_na_direcao(quem, destino, b._velocidade(u))
			b._log("%s: %s e %s avançam juntos." % [nome, u.nome, alvo.nome])
		"instruir-armamento":
			for h in b.herois_ativos():
				if h != u and Grade.adjacentes(h.pos, u.pos):
					h.efeitos["troca_livre"] = {}
			b._log("%s: os aliados ao lado podem trocar de arma uma vez sem gastar ação." % nome)
		"assalto-do-gatuno":
			if u.efeitos.has("oculto") or alvo.efeitos.has("caido"):
				u.dar_ficha("Foco", 2)
				b._log("%s: %s ganha 2 Foco." % [nome, u.nome])
			var meu: int = b._teste_automatico(u, b.valor_componente(u, "Ladinagem") + u.destreza)
			var dele: int = b.valor_resistido(alvo, "percepcao")
			if meu > dele:
				b.desarmar(alvo)
				b._log("%s: %d contra %d, %s fica sem a arma." % [nome, meu, dele, alvo.nome])
			else:
				b._log("%s: %d contra %d, %s percebe a mão leve." % [nome, meu, dele, alvo.nome])
		"olha-la":
			u.tirar_fichas("Marcado", 1)
			u.tirar_fichas("Penalidade", 1)
			u.efeitos["olha_la"] = {"ate": "inicio_turno"}
			b._log("%s: neste turno, ninguém tem vantagem contra %s." % [nome, u.nome])
		"finta":
			u.tirar_fichas("Sombra", 1)
			b._gastou_sombra(u)
			u.efeitos["finta"] = {}
			b._log("%s: o próximo ataque de %s tem vantagem." % [nome, u.nome])
		"gancho-fantasma":
			if Origens_maior_que_medio(alvo):
				b._log("%s: %s é grande demais para ser puxado." % [nome, alvo.nome])
				return
			var r: int = b.valor_resistido(alvo, "forca")
			if r >= 18:
				b._log("%s: %s resiste ao puxão (%d)." % [nome, alvo.nome, r])
			else:
				b._andar_na_direcao(alvo, u.pos, 3)
				b._log("%s: %s é puxado na direção de %s (%d)." % [nome, alvo.nome, u.nome, r])
		"adaga-fantasma":
			c.dar_ficha("Atormentado")
			u.efeitos["adaga_fantasma"] = {}
			b._log("%s: o próximo ataque que acertar põe 1 Ferimento no alvo." % nome)
		"empurrao-mistico":
			if alvo.fichas_total("Confusão") <= 0:
				b._log("%s: %s não está confuso, o empurrão não derruba." % [nome, alvo.nome])
				return
			b.derrubar(alvo)
		"adaptavel":
			var menor: int = u.baralho.mao[0]
			for carta in u.baralho.mao:
				if preload("res://core/carta.gd").valor(carta) < preload("res://core/carta.gd").valor(menor):
					menor = carta
			u.baralho.tirar_da_mao(menor)
			u.baralho.descarte.append(menor)
			for ca in u.cartas:
				if (c.opcao == "arma" and ca.tipo == "arma") or (c.opcao != "arma" and ca.tipo == "heroi"):
					if ca.tipo == "arma":
						u.efeitos["troca_livre"] = {}
						b.heroi_trocar_arma()
					else:
						b._virar(u, ca)
					break
			b._log("%s: %s descarta uma carta da mão e vira a carta." % [nome, u.nome])
		"passo-espectral":
			u.deslocamento += 2
			u.ignora_impedimento = true
			u.efeitos["desengajar"] = {"ate": "inicio_turno"}
			u.efeitos["passo_leve"] = {"ate": "inicio_turno"}
			b._log("%s: %s some e reaparece até 2 casas adiante, sem provocar reações." % [nome, u.nome])
		"hino-de-coragem":
			for h in b.herois_ativos():
				if h != u and Grade.distancia(h.pos, u.pos) <= 2:
					h.efeitos["hino"] = {"ate_turno_de": u.id}
			b._log("%s: aliados a até 2 casas não recebem fichas de inimigos até o próximo turno de %s." % [nome, u.nome])
		"prece-rapida", "olho-de-aguia":
			b.comecar_scry(u)
		"estudar-a-presa":
			for t in alvo.fraquezas:
				b._descobrir(alvo, "fraquezas", t, int(alvo.fraquezas[t]))
			for t in alvo.resiste_tipo:
				b._descobrir(alvo, "resistencias", t, int(alvo.resiste_tipo[t]))
			var v: int = b._teste_automatico(u, u.sabedoria)
			if v >= 20:
				var tipo: String = str(u.arma.get("tipo_dano", "Perfuração"))
				if alvo.resiste_tipo.has(tipo):
					alvo.resiste_tipo.erase(tipo)
				else:
					alvo.fraquezas[tipo] = int(alvo.fraquezas.get(tipo, 0)) + 2
					b._descobrir(alvo, "fraquezas", tipo, int(alvo.fraquezas[tipo]))
				b._log("%s: %d! %s fica vulnerável a %s até o fim da cena." % [nome, v, alvo.nome, tipo])
			else:
				b._log("%s: fraquezas e resistências de %s anotadas (teste %d, sem brecha extra)." % [nome, alvo.nome, v])
		"cabra-da-montanha":
			u.deslocamento += b._velocidade(u)
			u.efeitos["passo_leve"] = {"ate": "inicio_turno"}
			u.efeitos["escalando"] = {"ate": "inicio_turno", "nivel": b.grade.nivel(u.pos)}
			b._log("%s: %s escala e salta %d casas sem teste." % [nome, u.nome, b._velocidade(u)])
		"ponto-de-vantagem":
			u.efeitos["ponto_de_vantagem"] = {"turnos": 1}
			b._log("%s: neste turno, quem estiver abaixo defende com desvantagem contra os tiros de %s." % [nome, u.nome])
		"tecer-com-maestria":
			u.efeitos["tecer"] = {}
			b._log("%s: a próxima magia de %s alcança mais longe." % [nome, u.nome])
		"reflexo-arcano":
			u.acoes_reacao += 1
			b._log("%s: %s ganha 1 Reação." % [nome, u.nome])
		"servo-sombrio":
			if alvo.fichas_total("Medo") <= 0:
				b._log("%s: %s não está com medo." % [nome, alvo.nome])
				return
			var outros: Array = b.inimigos_vivos().filter(func(o): return o != alvo)
			if outros.is_empty():
				return
			outros.sort_custom(func(a, x): return Grade.distancia(a.pos, alvo.pos) < Grade.distancia(x.pos, alvo.pos))
			var vitima = outros[0]
			b._andar_na_direcao(alvo, vitima.pos, 2)
			b._log("%s: com medo, %s obedece e ataca %s." % [nome, alvo.nome, vitima.nome])
			if Grade.distancia(alvo.pos, vitima.pos) <= alvo.alcance_corpo or alvo.a_distancia:
				alvo.efeitos["confuso"] = {"alvo": vitima.id}
				b._novo_ataque(alvo, vitima, {})
		"maos-leves":
			if alvo.efeitos.get("agarrado", {}).get("por", "") == u.id:
				b.desarmar(alvo)


static func Origens_maior_que_medio(o) -> bool:
	return o.tamanho in ["grande", "enorme"]


static func ao_virar(b, u, c) -> void:
	match c.slug():
		"intervencao-divina":
			for h in b.herois_ativos():
				if h == u or not Grade.adjacentes(h.pos, u.pos):
					continue
				var pior = null
				for ca in h.cartas:
					if ca.tipo != "arma" and ca.fadiga > 0 and (pior == null or ca.fadiga > pior.fadiga):
						pior = ca
				if pior != null:
					b._virar(h, pior)
					b._log("Intervenção Divina: %s vira %s." % [h.nome, pior.nome()])


## Depois do ataque do herói: Finta (errou: Sombra e Penalidade) e Adaga Fantasma.
static func depois_do_ataque(b, u, alvo, acerto: bool) -> void:
	if u.efeitos.has("finta"):
		u.efeitos.erase("finta")
		if not acerto:
			u.dar_ficha("Sombra")
			u.dar_ficha("Penalidade")
			b._log("Finta: errou, %s ganha 1 Sombra e 1 Penalidade." % u.nome)
	if u.efeitos.has("adaga_fantasma") and acerto and alvo.viva():
		u.efeitos.erase("adaga_fantasma")
		alvo.dar_ficha("Ferimento")
		b._log("Adaga Fantasma: %s recebe 1 Ferimento." % alvo.nome)
