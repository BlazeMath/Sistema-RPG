extends RefCounted

const Combate := preload("res://core/combate.gd")
const Teste21 := preload("res://core/teste21.gd")
const Carta := preload("res://core/carta.gd")

const LADOS := {
	"perfilador": {"uso": "ativada", "alvo": "inimigo_inquerito", "custo": {"fadiga": 1, "acao": "movimento", "pistas": 1}},
	"pressao-calculada": {"uso": "ativada", "alvo": "inimigo_inquerito", "custo": {"fadiga": 1, "acao": "movimento", "pistas": 1}, "uma_vez_turno": true},
	"desmontar-a-versao": {"uso": "ativada", "alvo": "inimigo_inquerito", "custo": {"fadiga": 2, "acao": "padrao", "pistas": 2}},
	"dar-contexto": {"uso": "ativada", "alvo": "aliado_contexto", "custo": {"fadiga": 1, "acao": "movimento", "pistas": 1}},
	"percurso-seguro": {"uso": "ativada", "alvo": "aliado_percurso", "custo": {"fadiga": 1, "acao": "movimento", "pistas": 1}, "uma_vez_turno": true},
	"compartilhar-o-dossie": {"uso": "ativada", "alvo": "aliado_dossie", "custo": {"fadiga": 0, "acao": "movimento"}, "uma_vez_turno": true, "pistas_min": 1},
	"conferir-anotacoes": {"uso": "ativada", "custo": {"fadiga": 0, "acao": "movimento", "pistas": 1}, "uma_vez_turno": true},
	"antecipar-o-gesto": {"uso": "reacao", "custo": {"fadiga": 0, "acao": "reacao", "pistas": 1}},
	"ler-a-reacao": {"uso": "reacao", "custo": {"fadiga": 0, "acao": "reacao", "pistas": 1}},
	"decifrador": {"uso": "reacao"},
	"coleta-metodica": {"uso": "reacao"},
	"explorar-a-descoberta": {"uso": "reacao"},
	"orientar-a-verificacao": {"uso": "reacao"},
	"contraprova": {"uso": "reacao"},
	"segundo-caminho": {"uso": "reacao"},
	"olhar-atento": {"uso": "passiva"},
	"rever-o-raciocinio": {"uso": "passiva"},
	"identificar-o-padrao": {"uso": "passiva"},
}

const NA_INTERACAO := ["detetive-analitico", "ligar-os-pontos",
	"hipotese-de-trabalho", "conclusao-fundamentada", "entrevista-breve", "maos-ao-caso"]


static func registro(c) -> Dictionary:
	var s: String = c.slug()
	if not c.tipo in ["heroi", "habilidade"]:
		return {}
	if s in NA_INTERACAO:
		return {"uso": "fora", "nota": "Use na interação com uma evidência em Vau-Cinzento."}
	if s == "investigador-de-campo":
		return {"uso": "fora", "nota": "Passiva e crítico disponíveis. Sequência Calculada e Encontrar uma Abertura ainda não disponíveis."}
	return LADOS.get(s, {})


static func pistas(u) -> int:
	return u.fichas_total("Pista")


static func ganhar(b, u, n: int) -> void:
	if n > 0 and u.viva():
		u.dar_ficha("Pista", n)
		b._log("%s ganha %d Pista(s)." % [u.nome, n])


static func gastar(_b, u, n: int) -> bool:
	if n < 0 or pistas(u) < n:
		return false
	return u.tirar_fichas("Pista", n) == n


static func curto(b, u, alvo) -> bool:
	return alvo != null and alvo.viva() and (u == alvo or (b.faixa_entre(u, alvo) == Combate.Faixa.CURTO
		and b.grade.linha_de_visao(u.pos, alvo.pos) and b.ve_de(u, u.pos, alvo.pos)))


static func comunicacao(b, u, alvo) -> bool:
	return curto(b, u, alvo) and curto(b, alvo, u) and (alvo.eh_heroi() or alvo.categoria in ["humanoide", "goblinoide"])


static func alvos(b, u, tipo: String) -> Array:
	match tipo:
		"inimigo_inquerito":
			return b.oponentes(u).filter(func(o): return comunicacao(b, u, o))
		"aliado_contexto":
			return b.herois_ativos().filter(func(o): return comunicacao(b, u, o) and (o.fichas_total("Medo") > 0 or o.fichas_total("Confusão") > 0))
		"aliado_dossie":
			return b.herois_ativos().filter(func(o): return o != u and comunicacao(b, u, o) and not o.cartas.is_empty())
		"aliado_percurso":
			return b.herois_ativos().filter(func(o): return comunicacao(b, u, o) and not b.casas_ajustar(o).is_empty())
	return []


static func motivo(u, c, info: Dictionary) -> String:
	var custo: Dictionary = info.get("custo", {})
	var n := int(info.get("pistas_min", custo.get("pistas", 0)))
	if n > pistas(u):
		return "precisa de %d Pista(s)" % n
	if info.get("uma_vez_turno", false) and u.efeitos.has("inv_" + c.slug()):
		return "já usada neste turno"
	if c.slug() == "conferir-anotacoes" and u.baralho.vazio():
		return "baralho vazio"
	return ""


static func _uma_vez_rodada(b, u, efeito: String) -> bool:
	var chave := "inv_" + efeito
	if int(u.efeitos.get(chave, {}).get("rodada", -1)) == b.rodada:
		return false
	u.efeitos[chave] = {"rodada": b.rodada}
	return true


static func apos_gasto(b, u) -> void:
	if not u.viva() or not u.ativo("detetive-analitico"):
		return
	var alvos_scry: Array = b.herois_ativos().filter(func(h): return comunicacao(b, u, h) and not h.baralho.vazio())
	if alvos_scry.is_empty() or not _uma_vez_rodada(b, u, "compartilhar_deducao"):
		return
	if not b.perguntar_escolhas:
		b.scry(alvos_scry[0], 1)
		return
	var opcoes := alvos_scry.map(func(h): return [h.id, "Scry 1: " + h.nome])
	opcoes.append(["nao", "Dispensar"])
	b.perguntar("investigador-deducao", "Compartilhar a Dedução: quem faz scry 1?", opcoes, {"quem": u.id})


static func usar(b, u, c, info: Dictionary, alvo) -> void:
	var s: String = c.slug()
	var n := int(info.get("custo", {}).get("pistas", 0))
	if n > 0 and not gastar(b, u, n):
		return
	if info.get("uma_vez_turno", false):
		u.efeitos["inv_" + s] = {"ate": "inicio_turno"}
	match s:
		"pressao-calculada":
			alvo.dar_ficha("Medo", 1, u.id)
			b._log("Pressão Calculada: %s recebe 1 Medo." % alvo.nome)
		"perfilador", "desmontar-a-versao":
			_contestar(b, u, alvo, s)
		"dar-contexto":
			_contexto(b, u, alvo)
			return
		"percurso-seguro":
			_percurso(b, u, alvo, 2)
			return
		"compartilhar-o-dossie":
			_dossie(b, u, alvo)
		"conferir-anotacoes":
			b.scry(u, 3)
	if n > 0:
		apos_gasto(b, u)
	apos_resolucao(b, u)


static func _contestar(b, u, alvo, efeito: String) -> void:
	var oposicao: int = b.valor_resistido(alvo, "espirito")
	var teste := Teste21.new(u.baralho, u.raciocinio + int(u.pericias.get("Investigação", 0)))
	while not teste.encerrado and teste.resultado() <= oposicao and teste.soma_cartas() < 17 and teste.puxar():
		pass
	teste.parar()
	var nome := "Expor o Perfil" if efeito == "perfilador" else "Desmontar a Versão"
	b._log("%s: %s tira %d contra %d de %s." % [nome, u.nome, teste.resultado(), oposicao, alvo.nome])
	if teste.resultado() > oposicao:
		# Os inimigos do bestiário não possuem cartas de habilidade com duas faces.
		var qtd := 1 if efeito == "perfilador" else 2
		alvo.dar_ficha("Penalidade", qtd, u.id)
		b._log("%s recebe %d Penalidade(s)." % [alvo.nome, qtd])
	if teste.critico():
		b._critico(u)
	b._verificar_queda_heroi(u)


static func _contexto(b, u, alvo) -> void:
	var opcoes := []
	for i in alvo.cartas.size():
		var c = alvo.cartas[i]
		for f in ["Medo", "Confusão"]:
			if c.tem_ficha(f):
				opcoes.append(["%d/%s" % [i, f], "%s: %s" % [c.nome(), f]])
	if opcoes.size() == 1 or not b.perguntar_escolhas:
		responder(b, "investigador-contexto", opcoes[0][0], {"quem": alvo.id, "origem": u.id})
	else:
		b.perguntar("investigador-contexto", "Dar Contexto: qual ficha remover?", opcoes, {"quem": alvo.id, "origem": u.id})


static func _dossie(b, u, alvo) -> void:
	if pistas(u) == 1 or not b.perguntar_escolhas:
		_transferir(b, u, alvo, mini(pistas(u), 2))
		return
	var opcoes := [["1", "1 Pista para " + alvo.nome], ["2", "2 Pistas para " + alvo.nome]]
	for outro in alvos(b, u, "aliado_dossie"):
		if outro != alvo:
			opcoes.append(["1/" + outro.id, "1 para %s e 1 para %s" % [alvo.nome, outro.nome]])
	b.perguntar("investigador-dossie", "Compartilhar o Dossiê: quantas Pistas?", opcoes, {"quem": u.id, "alvo": alvo.id})


static func _percurso(b, u, alvo, passos: int) -> void:
	var casas: Array = b.casas_ajustar(alvo) if passos > 0 else []
	if casas.is_empty():
		apos_gasto(b, u)
		return
	if not b.perguntar_escolhas:
		var fase_antes: int = b.fase
		b.ajustar_uma_casa(alvo, casas[0])
		_percurso(b, u, alvo, passos - 1 if b.fase == fase_antes else 0)
		return
	var opcoes := casas.map(func(p): return ["%d/%d" % [p.x, p.y], "Casa %d, %d" % [p.x + 1, p.y + 1]])
	opcoes.append(["nao", "Encerrar percurso"])
	b.perguntar("investigador-percurso", "Percurso Seguro: %s pode Ajustar 1. Restam %d passo(s)." % [alvo.nome, passos],
		opcoes, {"quem": alvo.id, "origem": u.id, "passos": passos})


static func _transferir(b, u, alvo, n: int) -> void:
	if alvo != null and alvo != u and comunicacao(b, u, alvo) and gastar(b, u, n):
		alvo.dar_ficha("Pista", n)
		b._log("%s transfere %d Pista(s) para %s." % [u.nome, n, alvo.nome])


static func critico(b, u) -> bool:
	var c = u.carta_heroi()
	if c == null:
		return false
	match c.slug():
		"detetive-analitico":
			ganhar(b, u, 2)
		"investigador-de-campo":
			ganhar(b, u, 1)
			c.fadiga = maxi(0, c.fadiga - 1)
		"perfilador":
			ganhar(b, u, 1)
			var candidatos: Array = b.oponentes(u).filter(func(o): return curto(b, u, o))
			if not candidatos.is_empty():
				u.efeitos["inv_marcacao_critico"] = {"alvos": candidatos.map(func(o): return o.id)}
		"decifrador":
			ganhar(b, u, 1)
			u.efeitos["inv_scry_critico"] = {}
		_:
			return false
	return true


static func apos_resolucao(b, u) -> void:
	if not u.viva():
		return
	if u.efeitos.erase("inv_scry_critico") and not u.baralho.vazio():
		b.scry(u, 3)
	var marcacao: Dictionary = u.efeitos.get("inv_marcacao_critico", {})
	u.efeitos.erase("inv_marcacao_critico")
	var opcoes := []
	for id in marcacao.get("alvos", []):
		var alvo = b.unidade(id)
		if curto(b, u, alvo):
			opcoes.append([id, alvo.nome])
	if opcoes.size() == 1 or (not b.perguntar_escolhas and not opcoes.is_empty()):
		responder(b, "investigador-marcar", opcoes[0][0], {"quem": u.id})
	elif not opcoes.is_empty():
		b.perguntar("investigador-marcar", "Previsível: qual adversário recebe 1 Marcação?", opcoes, {"quem": u.id})


static func inimigo_estourou(b, alvo, teste: Teste21) -> void:
	if alvo.eh_heroi() or not teste.estourou:
		return
	var autores: Array = alvo.fontes_de_fichas.get("Penalidade", [])
	for h in b.herois_ativos():
		if h.id in autores and h.ativo("perfilador") and _uma_vez_rodada(b, h, "mascara"):
			ganhar(b, h, 1)
			b._log("A Máscara Cai: %s estourou sob a Penalidade de %s." % [alvo.nome, h.nome])


static func _reacao(u, slug: String):
	var c = u.carta_com(slug)
	var custo: Dictionary = LADOS[slug]["custo"]
	return c if c != null and u.acoes_reacao > 0 and pistas(u) >= int(custo["pistas"]) and c.pode_pagar(int(custo["fadiga"])) else null


static func oferecer_leitura(b, inimigo, aliado, teste: Teste21) -> void:
	if teste.revelado or teste.cartas.size() < 2 or not aliado.eh_heroi() or inimigo.eh_heroi() or not b.perguntar_escolhas:
		return
	for h in b.herois_ativos():
		if comunicacao(b, h, aliado) and curto(b, h, inimigo) and _reacao(h, "ler-a-reacao") != null:
			b.perguntar("investigador-leitura", "%s pode gastar 1 Pista e uma Reação para revelar a carta fechada de %s." % [h.nome, inimigo.nome],
				[["sim", "Ler a Reação"], ["nao", "Deixar fechada"]], {"reator": h.id, "alvo": inimigo.id})
			return


static func oferecer_gesto(b, inimigo, alvo, dano: int, volta: int) -> bool:
	if inimigo == null or inimigo.eh_heroi() or not b.perguntar_escolhas or not b.resultado.get("acertou", false) \
			or b.ctx.get("inv_gesto_usado", false) or dano <= 1:
		return false
	for h in b.herois_ativos():
		if not curto(b, h, inimigo) or not curto(b, h, alvo) or _reacao(h, "antecipar-o-gesto") == null:
			continue
		var opcoes := []
		for f in ["Medo", "Penalidade"]:
			if h.id in inimigo.fontes_de_fichas.get(f, []):
				opcoes.append([f, "Antecipar o Gesto: remover " + f])
		if opcoes.is_empty():
			continue
		opcoes.append(["nao", "Receber o dano normalmente"])
		b.perguntar("investigador-gesto", "%s pode gastar 1 Pista e uma Reação para reduzir o dano em %s de %d para %d." % [h.nome, alvo.nome, dano, ceili(dano / 2.0)],
			opcoes, {"reator": h.id, "alvo": alvo.id, "inimigo": inimigo.id, "dano": dano, "volta": volta})
		return true
	return false


static func responder(b, id: String, opcao: String, dados: Dictionary) -> void:
	var u = b.unidade(dados.get("quem", dados.get("reator", "")))
	match id:
		"investigador-deducao":
			var alvo = b.unidade(opcao)
			if alvo != null and comunicacao(b, u, alvo):
				b.scry(alvo, 1)
		"investigador-marcar":
			var alvo = b.unidade(opcao)
			if alvo != null and not alvo.eh_heroi() and curto(b, u, alvo):
				alvo.dar_ficha("Marcado")
				b._log("Previsível: %s recebe 1 Marcação." % alvo.nome)
		"investigador-contexto":
			var indice := int(opcao.get_slice("/", 0))
			var ficha := opcao.get_slice("/", 1)
			if indice >= 0 and indice < u.cartas.size() and ficha in ["Medo", "Confusão"]:
				u.cartas[indice].tirar_ficha(ficha)
				if u.fichas_total("Confusão") == 0:
					u.efeitos.erase("confuso")
				b._log("Dar Contexto: %s remove 1 %s." % [u.nome, ficha])
			apos_gasto(b, b.unidade(dados["origem"]))
		"investigador-percurso":
			var origem = b.unidade(dados["origem"])
			var x := opcao.get_slice("/", 0)
			var y := opcao.get_slice("/", 1)
			var fase_antes: int = b.fase
			var andou: bool = x.is_valid_int() and y.is_valid_int() and b.ajustar_uma_casa(u, Vector2i(int(x), int(y)))
			_percurso(b, origem, u, int(dados["passos"]) - 1 if andou and b.fase == fase_antes else 0)
		"investigador-dossie":
			var n := int(opcao.get_slice("/", 0))
			if n in [1, 2]:
				_transferir(b, u, b.unidade(dados["alvo"]), n)
				if n == 1 and opcao.contains("/"):
					var outro = b.unidade(opcao.get_slice("/", 1))
					if outro != null and outro.id != dados["alvo"]:
						_transferir(b, u, outro, 1)
		"investigador-leitura":
			if opcao == "sim" and _reacao(u, "ler-a-reacao") != null and gastar(b, u, 1):
				var teste: Teste21 = b.teste_ataque if b.atacante.id == dados["alvo"] else b.teste_defesa
				u.acoes_reacao -= 1
				teste.revelado = true
				b._log("Ler a Reação: a carta fechada de %s fica à vista." % b.unidade(dados["alvo"]).nome)
				apos_gasto(b, u)
		"investigador-gesto":
			var dano: int = dados["dano"]
			var inimigo = b.unidade(dados["inimigo"])
			var usou: bool = opcao in ["Medo", "Penalidade"] and _reacao(u, "antecipar-o-gesto") != null \
				and inimigo.tirar_fichas(opcao, 1, u.id) == 1 and gastar(b, u, 1)
			if usou:
				u.acoes_reacao -= 1
				b.ctx["inv_gesto_usado"] = true
				b.resultado["inv_gesto"] = true
				dano = ceili(dano / 2.0)
				b.resultado["dano"] = dano
				b._log("Antecipar o Gesto: o dano cai para %d." % dano)
			b._dano_no_heroi_apos_gesto(b.unidade(dados["alvo"]), dano, "ataque", dados["volta"])
			if usou:
				apos_gasto(b, u)
