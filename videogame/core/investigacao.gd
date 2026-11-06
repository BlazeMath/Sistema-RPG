## Interações de investigação: as evidências do caso são distintas das fichas pessoais.
extends RefCounted

const Investigador := preload("res://core/cartas_investigador.gd")
const Catalogo := preload("res://core/catalogo.gd")
const Carta := preload("res://core/carta.gd")

const PASSIVAS := {
	"detetive-analitico": "",
	"investigador-de-campo": "cenario",
	"perfilador": "intencao",
	"decifrador": "mecanismo",
}
const PREPAROS := ["coleta-metodica", "explorar-a-descoberta", "orientar-a-verificacao"]


static func motivo(b, u, op: Dictionary) -> String:
	var dados: Dictionary = op.get("investigador", {})
	var slug := str(dados.get("carta", ""))
	if slug == "":
		return ""
	var c = u.carta_com(slug)
	if c == null:
		return "requer %s na face ativa" % Catalogo.habilidade_por_slug(slug)
	if dados.get("evidencias", []).any(func(nome): return not b.pistas.has(nome)):
		return "ainda faltam evidências para esta dedução"
	var deducao: Dictionary = dados.get("deducao", {})
	if not deducao.is_empty() and b.deducoes.has(deducao["id"]):
		return "dedução já registrada"
	if dados.has("hipotese") and u.efeitos.get("iv_hipotese", {}).get("teste") == dados["hipotese"]:
		return "essa verificação já está preparada"
	if slug in ["entrevista-breve", "maos-ao-caso"] and u.efeitos.has("iv_" + slug):
		return "uma vez por turno"
	return _motivo_custo(b, u, c)


static func _motivo_custo(b, u, c) -> String:
	var custo: Dictionary = c.lado_ativo().get("custo", {})
	if not b.pode_pagar_fadiga(u, c, int(custo.get("fadiga", 0))):
		return "a carta está sem espaço para Fadiga"
	var pistas := int(custo.get("pistas", 0))
	if Investigador.pistas(u) < pistas:
		return "precisa de %d ficha(s) de Pista" % pistas
	if custo.get("acao") == "reacao" and u.acoes_reacao <= 0:
		return "sem Reação"
	return ""


static func _pagar(b, u, c) -> int:
	var custo: Dictionary = c.lado_ativo().get("custo", {})
	var n := int(custo.get("pistas", 0))
	b.pagar_fadiga(u, c, int(custo.get("fadiga", 0)))
	if n > 0:
		Investigador.gastar(b, u, n)
	if custo.get("acao") == "reacao":
		u.acoes_reacao -= 1
	return n


static func pagar_interacao(b, u, op: Dictionary) -> int:
	var slug := str(op.get("investigador", {}).get("carta", ""))
	if slug == "":
		return 0
	if slug in ["entrevista-breve", "maos-ao-caso"]:
		u.efeitos["iv_" + slug] = {"ate": "inicio_turno"}
	return _pagar(b, u, u.carta_com(slug))


static func _uma_vez_na_rodada(b, u, chave: String) -> bool:
	if u.efeitos.get(chave, {}).get("rodada", -1) == b.rodada:
		return false
	u.efeitos[chave] = {"rodada": b.rodada}
	return true


static func descobrir(b, u, categoria: String, comps: Array, padrao := false) -> void:
	for slug in PASSIVAS:
		if u.ativo(slug) and (PASSIVAS[slug] == "" or PASSIVAS[slug] == categoria) \
				and _uma_vez_na_rodada(b, u, "iv_passiva_" + slug):
			Investigador.ganhar(b, u, 1)
	if b.interacao_atual.get("iv_coleta", false):
		b.interacao_atual.erase("iv_coleta")
		Investigador.ganhar(b, u, 1)
	if u.ativo("olhar-atento") and "percepcao" in comps and not u.efeitos.has("iv_olhar_atento"):
		u.efeitos["iv_olhar_atento"] = {}
		Investigador.ganhar(b, u, 1)
	if padrao and u.ativo("identificar-o-padrao") and not u.efeitos.has("iv_identificar_padrao"):
		u.efeitos["iv_identificar_padrao"] = {}
		Investigador.ganhar(b, u, 1)


static func efeitos_opcao(b, u, op: Dictionary, sucesso: bool) -> PackedStringArray:
	var linhas := PackedStringArray()
	if not sucesso:
		return linhas
	var dados: Dictionary = op.get("investigador", {})
	if dados.has("hipotese"):
		u.efeitos["iv_hipotese"] = {"ate": "inicio_turno", "teste": dados["hipotese"]}
		linhas.append("Hipótese preparada: scry 3 antes da verificação indicada neste turno.")
	var deducao: Dictionary = dados.get("deducao", {})
	if not deducao.is_empty() and not b.deducoes.has(deducao["id"]):
		b.deducoes[deducao["id"]] = deducao["texto"]
		linhas.append(deducao["texto"])
		b._log("Dedução: " + str(deducao["texto"]))
		descobrir(b, u, str(deducao.get("categoria", "geral")), [], bool(deducao.get("padrao", false)))
	if dados.get("preparo", false):
		u.dar_ficha("Preparo")
		linhas.append("Conclusão Fundamentada: +1 Preparo.")
	return linhas


static func _comps(b, op: Dictionary) -> Array:
	return b.componentes_do_teste(op.get("teste", {})) if op.has("teste") else []


static func _investigativo(b, op: Dictionary) -> bool:
	return not str(op.get("investigador", {}).get("dica_falha", "")).is_empty() \
		or _comps(b, op).any(func(c): return c in ["Investigação", "Intuição"])


static func _mental(b, op: Dictionary) -> bool:
	return _comps(b, op).any(func(c): return b.tipo_componente(c) == "mental")


static func antes_do_teste(b, u, op: Dictionary) -> bool:
	if b.interacao_atual.get("id", "") == "":
		return false
	var h: Dictionary = u.efeitos.get("iv_hipotese", {}).get("teste", {})
	if h.get("interacao", "") == b.interacao_atual["id"] and h.get("opcao", "") == b.interacao_atual["opcao"]:
		u.efeitos.erase("iv_hipotese")
		b._log("Hipótese de Trabalho: scry 3 antes da verificação.")
		b.scry(u, 3, true)
		return true
	if not b.perguntar_escolhas:
		return false
	var oferecidos: Array = b.interacao_atual.get("iv_preparos_oferecidos", [])
	for slug in PREPAROS:
		if b.interacao_atual.get("iv_" + slug, false):
			continue
		for aliado in b.herois_ativos():
			var c = aliado.carta_com(slug)
			var chave: String = aliado.id + ":" + slug
			if chave in oferecidos or c == null or not _pode_preparar(b, u, aliado, c, op):
				continue
			oferecidos.append(chave)
			b.interacao_atual["iv_preparos_oferecidos"] = oferecidos
			b.perguntar("iv_preparar_teste", "%s: usar %s antes das cartas iniciais de %s?" % [aliado.nome, c.nome(), u.nome],
				[["sim", "Usar %s" % c.nome()], ["nao", "Seguir sem usar"]], {"quem": aliado.id, "slug": slug})
			return true
	return false


static func _pode_preparar(b, u, aliado, c, op: Dictionary) -> bool:
	if _motivo_custo(b, aliado, c) != "" or not Investigador.curto(b, aliado, u):
		return false
	match c.slug():
		"coleta-metodica":
			return aliado == u and "Investigação" in _comps(b, op) and aliado.efeitos.get("iv_rodada_coleta", {}).get("rodada", -1) != b.rodada
		"explorar-a-descoberta":
			return true  # aqui a opção é uma interação do mapa, não um ataque ou defesa
		"orientar-a-verificacao":
			return aliado != u and (_investigativo(b, op) or _mental(b, op))
	return false


static func responder_preparo(b, opcao: String, dados: Dictionary) -> void:
	var u = b.ativa()
	var op: Dictionary = b.opcao_atual()
	var h = b.unidade(dados["quem"])
	var slug := str(dados["slug"])
	var c = h.carta_com(slug) if h != null else null
	if opcao == "sim" and c != null and _pode_preparar(b, u, h, c, op):
		var gastas := _pagar(b, h, c)
		b.interacao_atual["iv_" + slug] = true
		match slug:
			"coleta-metodica":
				_uma_vez_na_rodada(b, h, "iv_rodada_coleta")
				b.interacao_atual["iv_coleta"] = true
			"explorar-a-descoberta":
				b.interacao_atual["iv_limite"] = 2
			"orientar-a-verificacao":
				b.interacao_atual["iv_modificador"] = h.raciocinio
		if gastas > 0:
			_registrar_gasto(b, h)
		b._log("%s usa %s." % [h.nome, c.nome()])
	b._comecar_teste_pericia(u, op)


static func limpar_tentativa(b) -> void:
	for chave in ["iv_coleta", "iv_limite", "iv_modificador", "iv_autores", "iv_preparos_oferecidos"]:
		b.interacao_atual.erase(chave)
	for slug in PREPAROS:
		b.interacao_atual.erase("iv_" + slug)


static func _registrar_gasto(b, h) -> void:
	for chave in ["iv_autores", "iv_autores_pagos"]:
		var autores: Array = b.interacao_atual.get(chave, [])
		if not h.id in autores:
			autores.append(h.id)
		b.interacao_atual[chave] = autores


static func antes_da_falha(b, u, op: Dictionary, valor: int) -> bool:
	if not b.perguntar_escolhas or b.interacao_atual.get("id", "") == "" or not u.viva():
		return false
	var oferecidos: Array = b.interacao_atual.get("iv_falha_oferecidos", [])
	for slug in ["decifrador", "segundo-caminho"]:
		if not _pode_corrigir(b, u, op, slug):
			continue
		for h in b.herois_ativos():
			var c = h.carta_com(slug)
			var chave: String = h.id + ":" + slug
			if c == null or chave in oferecidos or _motivo_custo(b, h, c) != "" or not Investigador.curto(b, h, u):
				continue
			oferecidos.append(chave)
			b.interacao_atual["iv_falha_oferecidos"] = oferecidos
			var nome := "Corrigir a Hipótese" if slug == "decifrador" else "Segundo Caminho"
			b.perguntar("iv_reagir_falha", "%s tirou %d e falhou. %s pode usar %s antes das consequências." % [u.nome, valor, h.nome, nome],
				[["sim", "Usar %s" % nome], ["nao", "Não usar"]], {"quem": h.id, "slug": slug})
			return true
	return false


static func _pode_corrigir(b, u, op: Dictionary, slug: String) -> bool:
	if slug == "decifrador":
		return not b.interacao_atual.get("iv_corrigida", false) and _investigativo(b, op) \
			and not b.teste_pericia.estourou and not u.baralho.mao.is_empty()
	return not b.interacao_atual.get("refeito", false) and (not op.has("consome") or u.tem_item(op["consome"]))


static func responder_falha(b, opcao: String, dados: Dictionary) -> void:
	var u = b.ativa()
	var op: Dictionary = b.opcao_atual()
	var h = b.unidade(dados["quem"])
	var slug := str(dados["slug"])
	var c = h.carta_com(slug) if h != null else null
	if opcao != "sim" or c == null or _motivo_custo(b, h, c) != "" or not _pode_corrigir(b, u, op, slug):
		b._resolver_interacao(b.teste_pericia.resultado())
		return
	if slug == "decifrador":
		var opcoes: Array = u.baralho.mao.map(func(carta): return [str(carta), Carta.nome(carta)])
		opcoes.append(["nao", "Manter o resultado"])
		b.perguntar("iv_corrigir_carta", "Corrigir a Hipótese: qual carta da mão você quer acrescentar ao teste?", opcoes,
			{"quem": u.id, "origem": h.id})
		return
	_pagar(b, h, c)
	if op.has("consome"):
		u.consumiveis.erase(op["consome"])
		u.gastos.append(op["consome"])
	limpar_tentativa(b)
	_registrar_gasto(b, h)
	b.interacao_atual["refeito"] = true
	b.interacao_atual["op_teste"] = op
	b._log("Segundo Caminho: %s refaz o teste. As cartas da primeira tentativa permanecem gastas." % u.nome)
	b._comecar_teste_pericia(u, op)


static func responder_carta(b, opcao: String, dados: Dictionary) -> void:
	var h = b.unidade(dados["origem"])
	var c = h.carta_com("decifrador") if h != null else null
	if opcao.is_valid_int() and c != null and _motivo_custo(b, h, c) == "" \
			and b.teste_pericia.acrescentar_apos_falha(int(opcao)):
		_pagar(b, h, c)
		_registrar_gasto(b, h)
		b.interacao_atual["iv_corrigida"] = true
		b._log("Corrigir a Hipótese acrescenta %s ao teste." % Carta.nome(int(opcao)))
		b._ajustes_no_estouro(b.teste_pericia)
	b._resolver_interacao(b.teste_pericia.resultado())


static func depois_da_interacao(b, u, op: Dictionary, valor: int, sucesso: bool) -> void:
	var autores: Array = b.interacao_atual.get("iv_autores", [])
	if valor >= 0 and sucesso:
		for id in autores:
			var h = b.unidade(id)
			if h != null and h.ativo("decifrador") and _uma_vez_na_rodada(b, h, "iv_leitura_confirmada"):
				u.dar_ficha("Foco")
				b._log("Leitura Confirmada: %s ganha 1 Foco." % u.nome)
	var pagaram: Array = b.interacao_atual.get("iv_autores_pagos", [])
	if b.interacao_atual.get("iv_pistas_pagas", 0) > 0 and not u.id in pagaram:
		pagaram = pagaram + [u.id]
	for id in pagaram:
		var h = b.unidade(id)
		if h != null:
			Investigador.apos_gasto(b, h)
	if valor >= 0 and not sucesso:
		if u.ativo("rever-o-raciocinio") and _comps(b, op).any(func(c): return c in ["Investigação", "Intuição"]) \
				and _uma_vez_na_rodada(b, u, "iv_rever"):
			u.dar_ficha("Foco")
			b._log("Rever o Raciocínio: %s ganha 1 Foco após a falha definitiva." % u.nome)
		_oferecer_contraprova(b, u, op)


static func _oferecer_contraprova(b, u, op: Dictionary) -> void:
	var dica := str(op.get("investigador", {}).get("dica_falha", ""))
	var chave := "contraprova:" + dica
	if dica == "" or b.deducoes.has(chave) or not b.perguntar_escolhas:
		return
	var recusaram: Array = b.interacao_atual.get("iv_contraprova_oferecida", [])
	for h in b.herois_ativos():
		var c = h.carta_com("contraprova")
		if h.id in recusaram or c == null or not Investigador.curto(b, h, u) or _motivo_custo(b, h, c) != "":
			continue
		recusaram.append(h.id)
		b.interacao_atual["iv_contraprova_oferecida"] = recusaram
		b.perguntar("iv_contraprova", "%s pode usar Contraprova para descobrir outra forma de verificar a pista." % h.nome,
			[["sim", "Gastar 1 Pista e Reação"], ["nao", "Aceitar a falha"]], {"quem": h.id, "dica": dica})
		return


static func responder_contraprova(b, opcao: String, dados: Dictionary) -> void:
	var h = b.unidade(dados["quem"])
	var c = h.carta_com("contraprova") if h != null else null
	if opcao != "sim" or c == null or _motivo_custo(b, h, c) != "":
		_oferecer_contraprova(b, b.ativa(), b.opcao_atual())
		return
	_pagar(b, h, c)
	var dica := str(dados["dica"])
	b.deducoes["contraprova:" + dica] = dica
	b.resultado_interacao["efeitos"].append(dica)
	b._log("Contraprova: " + dica)
	Investigador.apos_gasto(b, h)
