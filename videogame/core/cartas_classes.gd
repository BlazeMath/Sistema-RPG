## Efeitos das cartas de Ladino, Clérigo, Caçador e Mago (e das metades de herói
## dessas classes). A batalha (core/batalha.gd) chama estas funções; elas usam
## os ajudantes da batalha (_novo_ataque, _curar, _dano_direto...).
##
## O que cada lado faz e como é usado está registrado em core/efeitos.gd.
extends RefCounted

const Grade := preload("res://core/grade.gd")
const Carta := preload("res://core/carta.gd")

## Metades de herói com ativada programada (as outras aparecem como passivas).
const ATIVADAS_DE_HEROI := {
	"foco-mortal": {"uso": "ativada", "alvo": "nenhum"},
	"incansavel": {"uso": "ativada", "alvo": "nenhum"},
	"tomar-a-posicao": {"uso": "ativada", "alvo": "inimigo_investida"},
	"estrela-do-amanhecer": {"uso": "ativada", "alvo": "aliado", "alcance": 1, "sem_si": true},
	"o-martelo-da-luz": {"uso": "ativada", "alvo": "nenhum"},
	# Duas ativadas no mesmo lado (Lucas, 0.20): um botão para cada uma.
	"folha-de-carvalho": {"uso": "ativada", "alvo": "nenhum", "opcoes": [
		{"id": "imobilizar", "nome": "Imobilizar o alvo do próximo ataque", "custo": {"fadiga": 1, "acao": null}},
		{"id": "ferimento", "nome": "Ferimento no alvo do próximo ataque", "custo": {"fadiga": 1, "acao": null}}]},
	"controlador-do-arcano": {"uso": "ativada", "alvo": "aliado", "alcance": 4, "sem_si": true},
	"larapio": {"uso": "reacao", "nota": "o jogo pergunta quando um ataque em área vai causar dano (0.20)"},
}

## Fichas ruins que curas e bênçãos podem tirar, na ordem de prioridade.
const FICHAS_RUINS := ["Imobilizar", "Veneno", "Sangramento", "Fogo", "Ferimento", "Atordoamento", "Cegueira", "Confusão", "Medo", "Penalidade"]
## Fichas ruins que saem com "remova uma ficha" (as persistentes Sangramento,
## Veneno e Fogo só saem por efeitos que digam isso).
const FICHAS_LEVES := ["Imobilizar", "Ferimento", "Atordoamento", "Cegueira", "Confusão", "Medo", "Penalidade", "Atormentado"]

## Lados que fazem um ataque com a arma sem gastar ação própria: o ataque usa a ação Padrão.
## (0.14) As cartas "como parte de um ataque" agora são usadas durante o ataque, na mesa
## (Batalha.cartas_durante_ataque); nenhuma gasta ação própria.
const ATAQUE_COMO_PARTE := []


static func motivo_extra(b, u, c) -> String:
	var s: String = c.slug()
	if s in ATAQUE_COMO_PARTE and u.acoes_padrao <= 0:
		return "sem ação padrão (o ataque usa a ação)"
	match s:
		"chuva-de-flechas":
			if not u.a_distancia:
				return "precisa de arma de tiro"
		"larapio":
			if u.efeitos.has("metade_area"):
				return "já preparado"
		"bencao-persistente":
			if u.efeitos.has("bencao_usada"):
				return "já usada neste turno"
		"sempre-um-plano":
			if c.opcao in ["", "recuperar"]:
				if u.efeitos.has("plano_usado"):
					return "só uma vez por cena"
				if u.gastos.is_empty():
					return "nenhum consumível gasto"
			elif u.baralho.baralho.is_empty():
				return "baralho vazio"
		"oleos-e-iscas":
			if c.opcao == "isca" and not b.inimigos_vivos().any(func(o): return b.eh_fera(o) and Grade.distancia(o.pos, u.pos) <= 8):
				return "nenhuma fera ao alcance médio"
		"mente-belica":
			if u.baralho.mao.is_empty():
				return "precisa de uma carta na mão para descartar"
		"camuflagem":
			if u.atacou_nesta_rodada or u.fichas_total("Sombra") > 0:
				return "só sem ter atacado neste turno e sem ficha de Sombra"
		"torcer-a-lamina":
			if u.a_distancia:
				return "precisa de arma corpo a corpo"
		"fe-inabalavel":
			if u.efeitos.has("fe_inabalavel"):
				return "já ativa neste turno"
		"lanterna-da-fe":
			if u.efeitos.has("lanterna_da_fe"):
				return "já acesa nesta cena"
			if b.maos_livres(u) <= 0:
				return "precisa de uma mão livre"
		"o-martelo-da-luz":
			if u.efeitos.has("martelo_da_luz"):
				return "já ativa nesta cena"
		"folha-de-carvalho":
			if u.efeitos.has("folha_" + (c.opcao if c.opcao != "" else "imobilizar")):
				return "já preparada"
		"sobrecarga-arcana":
			if u.efeitos.has("sobrecarga"):
				return "já preparada"
	var info: Dictionary = b._info_lado(c)
	if info.get("ataque_magico", false) and int(u.foco.get("maos", 0)) == 0:
		return "precisa de um foco (varinha, orbe, cajado ou símbolo)"
	return preload("res://core/cartas_origens.gd").motivo_extra(b, u, c)


static func usar(b, u, c, alvo) -> void:
	var nome: String = c.nome()
	var s: String = c.slug()
	if s in ATAQUE_COMO_PARTE:
		u.acoes_padrao -= 1
	match s:
		# --- Áreas e zonas (0.11) --------------------------------------------
		"nevoa-ilusoria":
			b.criar_zona("nevoa", nome, b.area_atual["celulas"], u, {"rodadas": -1, "cobertura": 1})
		"zona-da-penitencia":
			b.criar_zona("penitencia", nome, b.area_atual["celulas"], u, {"rodadas": -1, "sustentar": 1, "carta": s})
		"terra-do-louvor":
			b.criar_zona("louvor", nome, b.area_atual["celulas"], u, {"rodadas": -1, "sustentar": 1, "carta": s})
		"halo-do-conduite":
			b.criar_zona("conduite", nome, b.area_atual["celulas"], u)
		"halo-da-justica":
			b.criar_zona("justica", nome, b.area_atual["celulas"], u)
		"covil-do-arqueiro":
			b.criar_zona("covil", nome, b.area_atual["celulas"], u, {"rodadas": -1})
		"armadilha-de-caca":
			b.criar_zona("armadilha", nome, b.area_atual["celulas"], u, {"rodadas": -1, "vinculada": false})
		"chuva-de-flechas":
			b._ataque_em_area(u, b.unidades_em(b.area_atual["celulas"], u), {"habilidade": nome})
		"labareda-voraz":
			b._ataque_em_area(u, b.unidades_em(b.area_atual["celulas"]), {"habilidade": nome, "magico": true,
				"bonus_dano": 2 + u.sabedoria, "rotulo_bonus": "Labareda Voraz (+2 + Sabedoria)", "labareda": true})
		"onda":
			b._ataque_em_area(u, b.unidades_em(b.area_atual["celulas"]), {"habilidade": nome, "magico": true,
				"ao_dano_inimigo": {"dano": u.sabedoria, "empurrar": 3, "rotulo": "Onda"}})
		"ciclone":
			b._ciclone(u, b.area_atual["celulas"])
		"larapio":
			u.efeitos["metade_area"] = {}
			b._log("Larápio: %s vai sofrer só metade do próximo ataque em área." % u.nome)
		"varinha-eletrizante":
			b._dano_direto(alvo, 3, "Varinha Eletrizante (ignora resistência)")
			b._verificar_fim()
		"varinha-de-cristal":
			u.efeitos["varinha_de_cristal"] = {"ate": "inicio_turno"}
			b._log("Varinha de Cristal: até o fim do turno, os ataques mágicos de %s causam +%d." % [u.nome, maxi(u.raciocinio, u.sabedoria)])
		"cajado-do-aprendiz":
			for outra in u.cartas:
				if outra.slug().begins_with("aprendiz-de") or outra.lados.any(func(l): return str(l.get("slug", "")).begins_with("aprendiz-de")):
					b._virar(u, outra)
					b._log("Cajado do Aprendiz: %s vira a carta de Aprendiz." % u.nome)
					break
		"cajado-de-batalha":
			for o in b.inimigos_vivos():
				if Grade.adjacentes(o.pos, u.pos):
					b._empurrar(o, u.pos, 2)
			b._log("Cajado de Batalha: Onda de força.")
		"orbe-de-concentracao":
			u.efeitos["concentrar_extra"] = {"ate": "inicio_turno"}
			b._log("Orbe de Concentração: o próximo Concentrar compra 1 carta a mais.")
		"orbe-de-protecao":
			alvo.efeitos["resistencia_extra"] = {"valor": 2, "ate_turno_de": u.id}
			b._log("Orbe de Proteção: %s ganha resistência 2 até o próximo turno de %s." % [alvo.nome, u.nome])
		"relicario-do-guardiao":
			alvo.dar_ficha("Guarda")
			b._log("Relicário do Guardião: %s ganha 1 ficha de Guarda." % alvo.nome)
		"escrituras-scry":
			b.comecar_scry(alvo)
		"escrituras-espirito":
			u.efeitos["escrituras_espirito"] = {}
			b._log("Escrituras de Maftoné: a próxima magia de %s soma o Espírito (%d) ao dano." % [u.nome, u.espirito])
		"rosario-da-devocao":
			u.tirar_fichas("Ferimento", 1)
			u.dar_ficha("Foco")
			b._log("Rosário da Devoção: 1 Ferimento vira 1 Foco.")
		"lamina-rapida":
			u.efeitos["sem_reacao_inimiga"] = {"nome": "Lâmina Rápida", "ate": "inicio_turno"}
			b._log("Lâmina Rápida: o próximo ataque de %s neste turno não gera reações dos inimigos." % u.nome)
		"tiro-rapido":
			u.efeitos["sem_reacao_inimiga"] = {"nome": "Tiro Rápido", "so_distancia": true, "ate": "inicio_turno"}
			b._log("Tiro Rápido: o próximo ataque à distância de %s neste turno não gera reações dos inimigos." % u.nome)
		# --- Ladino ---------------------------------------------------------
		"por-um-triz":
			c.dar_ficha("Confusão")
			if u.carta_heroi() != null and u.carta_heroi() != c:
				u.carta_heroi().dar_ficha("Confusão")
			c.dar_ficha("Bloqueio")
			b._log("Por um Triz: %s ganha 1 ficha de Bloqueio (e Confusão nas cartas)." % u.nome)
		"bomba-de-fumaca":
			if not u.atacou_nesta_rodada:
				u.dar_ficha("Sombra")
				b._log("Bomba de Fumaça: %s ganha 1 ficha de Sombra." % u.nome)
			b._virar(u, c)
		"passo-de-sombra":
			u.tirar_fichas("Sombra", 2)
			b._gastou_sombra(u)
			u.efeitos["oculto"] = {}
			u.efeitos["desengajar"] = {"ate": "inicio_turno"}
			u.deslocamento += 4
			u.ignora_impedimento = true
			b._log("Passo de Sombra: %s fica oculto e pode se mover 4 sem ser travado." % u.nome)
		"mancha-sombria":
			u.tirar_fichas("Sombra", 1)
			b._gastou_sombra(u)
			alvo.dar_ficha("Cegueira")
			b._log("Mancha Sombria: %s fica cego (o próximo ataque dele usa só 2 cartas)." % alvo.nome)
		"pe-ligeiro":
			u.deslocamento += 1
			u.ignora_impedimento = true
			u.efeitos["desengajar"] = {"ate": "inicio_turno"}
		"torcer-a-lamina":
			u.efeitos["torcer_a_lamina"] = {"ate": "inicio_turno"}
			b._log("O próximo ataque corpo a corpo de %s neste turno aplica Sangramento." % u.nome)
		"sumico":
			u.dar_ficha("Sombra")
		"sempre-um-plano", "oleos-e-iscas", "bencao-dos-salmos", "salmos-da-ira", "mente-belica", "misseis-magicos":
			b.usar_repertorio(u, c, alvo)
		# --- Clérigo --------------------------------------------------------
		"toque-restaurador":
			b._curar(alvo, 3 + u.sabedoria, "recebe o Toque Restaurador")
		"bencao-persistente":
			u.efeitos["bencao_usada"] = {"ate": "inicio_turno"}
			for h in b.herois():
				if h.viva() and h.baralho.descarte.size() > 0 and Grade.distancia(h.pos, u.pos) <= 4:
					h.baralho.exilio.append(h.baralho.descarte.pop_back())
					b._log("Bênção Persistente: %s exila 1 carta do descarte." % h.nome)
					b._curar(h, 1, "recebe a Bênção Persistente")
		"feixe-de-luz":
			b._novo_ataque(u, alvo, {"habilidade": nome, "magico": true, "tipo_dano": "Radiante",
				"bonus_contra": [{"cats": ["morto-vivo"], "valor": 2, "rotulo": "Feixe de Luz (morto-vivo)"}]})
		"palavra-de-banimento":
			b._novo_ataque(u, alvo, {"habilidade": nome, "magico": true, "tipo_dano": "Radiante", "ignora_res_contra": ["morto-vivo", "demonio"]})
		"raio-radiante":
			b._novo_ataque(u, alvo, {"habilidade": nome, "magico": true,
				"bonus_contra": [{"cats": ["morto-vivo", "demonio"], "valor": u.sabedoria, "rotulo": "Raio Radiante (Sabedoria)"}]})
		"golpe-da-punicao":
			b._novo_ataque(u, alvo, {"habilidade": nome, "tipos_extra": ["Radiante"], "sem_cura_ao_acertar": true})
		"lanterna-da-fe":
			u.efeitos["lanterna_da_fe"] = {}
			b._log("Lanterna da Fé: a mão livre de %s ilumina ao alcance curto até o fim da cena." % u.nome)
		"circulo-de-protecao":
			for h in b.herois_ativos():
				if Grade.distancia(h.pos, u.pos) <= 4:
					h.efeitos["circulo_de_protecao"] = {"ate_turno_de": u.id}
			b._log("Círculo de Proteção: resistência 2 contra mortos-vivos e demônios até o próximo turno de %s." % u.nome)
		"expulsar":
			var meu: int = b._teste_automatico(u, u.espirito)
			var dele: int = b.valor_resistido(alvo, "espirito")
			if meu >= dele:
				b._empurrar(alvo, u.pos, 2)
				alvo.efeitos["expulso"] = {"por": u.id, "ate_turno_de": u.id}
				b._log("Expulsar (%d contra %d): %s é empurrado e não pode se aproximar de %s no próximo turno." % [meu, dele, alvo.nome, u.nome])
			else:
				b._log("Expulsar (%d contra %d): %s resiste." % [meu, dele, alvo.nome])
		"rito-de-purificacao":
			b.criar_zona("rito", "Rito de Purificação", b.celulas_ao_redor(u.pos, 4), u, {"sustentar": 1, "carta": s, "segue": u.id, "raio": 4})
		"clarao-divino":
			for o in b.inimigos_vivos():
				if Grade.adjacentes(o.pos, u.pos):
					o.dar_ficha("Cegueira")
					b._log("Clarão Divino: %s fica cego." % o.nome)
		"agua-benta", "luz-da-verdade":
			b.usar_opcao(u, c, alvo)
		"primeiros-socorros":
			if s == "primeiros-socorros":
				b._curar(alvo, 1, "recebe Primeiros Socorros")
			for f in FICHAS_RUINS:
				if alvo.tirar_fichas(f, 1) > 0:
					b._log("%s: %s perde 1 ficha de %s." % [nome, alvo.nome, f])
					break
		"condenar":
			if alvo.fichas_total("Marcado") > 0:
				b._novo_ataque(u, alvo, {"habilidade": nome, "magico": true, "bonus_dano": u.sabedoria, "rotulo_bonus": "Condenar (marcado)"})
			else:
				b._novo_ataque(u, alvo, {"habilidade": nome, "magico": true, "marcar_depois": true})
		"juizo":
			var dano: int = u.sabedoria + 2
			for h in b.herois_ativos():
				if Grade.adjacentes(h.pos, alvo.pos):
					dano += 1
			b._dano_direto(alvo, dano, "Juízo")
		"fe-inabalavel":
			u.efeitos["fe_inabalavel"] = {"ate": "inicio_turno"}
		"mao-angelical":
			var t: int = b._tirar_fadiga(alvo, 1)
			b._log("Mão Angelical: %s recupera %d de fadiga." % [alvo.nome, t])
		"ressurgir":
			var metade: int = alvo.baralho.descarte.size() / 2
			for i in metade:
				alvo.baralho.exilio.append(alvo.baralho.descarte.pop_back())
			b._log("Ressurgir: metade do descarte de %s (%d cartas) vai para o exílio." % [alvo.nome, metade])
			b._curar(alvo, u.sabedoria, "recobra a consciência")
		# --- Caçador --------------------------------------------------------
		"preparar-o-tiro":
			var n := 2 if u.moveu_no_turno else 3
			u.dar_ficha("Mira", n)
			b._log("Preparar o Tiro: %s ganha %d fichas de Mira." % [u.nome, n])
		"marca-do-cacador":
			alvo.dar_ficha("Marcado")
			b._log("%s marca %s: a carta fechada da defesa dele fica à vista." % [u.nome, alvo.nome])
		"flecha-aleijadora":
			b._novo_ataque(u, alvo, {"habilidade": nome, "ao_acertar": [{"ficha": "Imobilizar"}, {"ficha": "Ferimento"}]})
		"flecha-envenenada":
			b._novo_ataque(u, alvo, {"habilidade": nome, "ao_acertar": [{"ficha": "Veneno"}]})
		"flecha-de-rede":
			b._novo_ataque(u, alvo, {"habilidade": nome, "metade": true, "ao_acertar": [{"ficha": "Imobilizar", "qtd": 2}]})
		"funda-certeira":
			b._novo_ataque(u, alvo, {"habilidade": nome, "ao_acertar": [{"ficha": "Confusão"}]})
		"pedra-atordoante":
			var ja: bool = alvo.fichas_total("Marcado") > 0 or alvo.fichas_total("Confusão") > 0
			b._novo_ataque(u, alvo, {"habilidade": nome, "atordoa_no_critico": true,
				"ao_acertar": [{"ficha": "Atordoamento"}] if ja else []})
		"camuflagem":
			u.dar_ficha("Sombra")
		"salto-de-recuo":
			u.deslocamento += 2
			u.ignora_impedimento = true
			u.efeitos["desengajar"] = {"ate": "inicio_turno"}
		"preparar-emboscada":
			u.dar_ficha("Mira")
		"tiro-perfeito":
			u.tirar_fichas("Mira", 3)
			b._novo_ataque(u, alvo, {"habilidade": nome, "resultado_fixo": 21, "virar_depois": c})
		"tiro-mortal":
			b._novo_ataque(u, alvo, {"habilidade": nome, "ignora_resistencia": true, "ao_matar": {"padrao": 1, "ficha": "Mira"}})
		# --- Mago -----------------------------------------------------------
		"sobrecarga-arcana":
			u.efeitos["sobrecarga"] = {"ate": "inicio_turno"}
			b._log("A próxima magia de %s neste turno causa o dobro de dano." % u.nome)
		"armadura-arcana":
			alvo.dar_ficha("Bloqueio")
			b._log("Armadura Arcana: %s ganha 1 ficha de Bloqueio." % alvo.nome)
		"aprendiz-de-fogo", "aprendiz-de-agua", "aprendiz-de-terra", "aprendiz-de-ar", "aprendiz-de-luz", "aprendiz-de-sombra":
			b.usar_repertorio(u, c, alvo)
		"missil-de-rocha":
			b._novo_ataque(u, alvo, {"habilidade": nome, "magico": true, "bonus_dano": 5, "rotulo_bonus": "Míssil de Rocha", "ao_acertar": [{"empurrar": 2}, {"derrubar": true}]})
		# --- Metades de herói -------------------------------------------------
		"estrela-do-amanhecer":
			b._curar(alvo, u.sabedoria, "recebe a luz da Estrela do Amanhecer")
		"o-martelo-da-luz":
			u.efeitos["martelo_da_luz"] = {}
			u.efeitos["vantagem_na_arma"] = {}
			b._log("O Martelo da Luz: as armas de %s ficam abençoadas até o fim da cena; 1 ficha de Vantagem na arma." % u.nome)
		"folha-de-carvalho":
			if c.opcao == "ferimento":
				u.efeitos["folha_ferimento"] = {}
				b._log("Folha de Carvalho: o próximo ataque de %s que causar dano põe 1 Ferimento no alvo." % u.nome)
			else:
				u.efeitos["folha_imobilizar"] = {}
				b._log("Folha de Carvalho: o próximo ataque de %s que causar dano imobiliza o alvo." % u.nome)
		"controlador-do-arcano":
			alvo.efeitos["arma_encantada"] = {"valor": u.raciocinio}
			b._log("Controlador do Arcano: a arma de %s causa +%d de dano até o fim da cena." % [alvo.nome, u.raciocinio])
		_:
			preload("res://core/cartas_origens.gd").usar(b, u, c, alvo)


## Passivas e desencadeadas do início do turno de um herói.
static func inicio_do_turno(b, u) -> void:
	if u.ativo("nunca-visto"):
		u.dar_ficha("Sombra")
		b._log("Nunca Visto: %s ganha 1 ficha de Sombra." % u.nome)
	if u.ativo("olho-que-tudo-ve"):
		u.dar_ficha("Mira")
		b._log("Olho que Tudo Vê: %s ganha 1 ficha de Mira." % u.nome)
	if u.ativo("mente-afiada"):
		for h in b.herois_ativos():
			h.dar_ficha("Foco")
		b._log("Mente Afiada: %s e os aliados ganham 1 ficha de Foco." % u.nome)
	if u.ativo("estrategia-arcana"):
		u.baralho.comprar_para_mao(1)
		b._log("Estratégia Arcana: %s compra 1 carta." % u.nome)
	if u.ativo("estrela-do-amanhecer"):
		# Lucas (0.20): o jogador escolhe o aliado (a até 3, com fadiga); o dono escolhe a carta.
		var aliados: Array = b.herois_ativos().filter(func(h): return h != u and Grade.distancia(h.pos, u.pos) <= 3 and not b.cartas_com_fadiga(h).is_empty())
		if aliados.size() == 1 or (not aliados.is_empty() and not b.perguntar_escolhas):
			b._estrela_aliado(aliados[0])
		elif aliados.size() > 1:
			b.perguntar("estrela_aliado", "Estrela do Amanhecer: qual aliado recupera 1 de fadiga?",
				aliados.map(func(h): return [h.id, "%s (fadiga em %d carta(s))" % [h.nome, b.cartas_com_fadiga(h).size()]]))
	if u.ativo("predador-da-selva"):
		for h in b.herois_ativos():
			if Grade.distancia(h.pos, u.pos) <= 4 and h.fichas_total("Preparo") == 0:
				h.dar_ficha("Preparo")
		b._log("Predador da Selva: %s e os aliados próximos ganham Preparo." % u.nome)


## Crítico (21 natural) das metades de herói destas classes.
static func critico(b, u, slug: String) -> void:
	match slug:
		"larapio":
			u.acoes_mov += 1
			b._log("Larápio: %s ganha uma ação de movimento." % u.nome)
		"folha-de-carvalho":
			u.baralho.comprar_para_mao(1)
			u.dar_ficha("Mira")
			b._log("Folha de Carvalho: %s compra 1 carta e ganha 1 Mira." % u.nome)
		"estrela-do-amanhecer":
			for h in b.herois_ativos():
				for f in FICHAS_RUINS:
					h.tirar_fichas(f)
			b._log("Estrela do Amanhecer: todos os heróis perdem as fichas ruins.")
		"o-martelo-da-luz":
			u.baralho.comprar_para_mao(2)
			if not u.baralho.mao.is_empty():
				var menor: int = u.baralho.mao[0]
				for carta in u.baralho.mao:
					if Carta.valor(carta) < Carta.valor(menor):
						menor = carta
				u.baralho.tirar_da_mao(menor)
				u.baralho.baralho.insert(0, menor)
			b._log("O Martelo da Luz: %s compra 2 cartas e põe a menor no fundo do baralho." % u.nome)
		"controlador-do-arcano":
			var maior = null
			for carta in u.cartas:
				if maior == null or carta.fadiga > maior.fadiga:
					maior = carta
			if maior != null:
				maior.fadiga = 0
				b._log("Controlador do Arcano: toda a fadiga de %s sai." % maior.nome())
		"devorador-de-grimorios":
			if not u.baralho.exilio.is_empty():
				u.baralho.mao.append(u.baralho.exilio.pop_back())
				b._log("Devorador de Grimórios: uma carta do exílio volta para a mão de %s." % u.nome)
		_:
			preload("res://core/cartas_origens.gd").critico(b, u, slug)
