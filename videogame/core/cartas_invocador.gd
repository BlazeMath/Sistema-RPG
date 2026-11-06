extends RefCounted

const Unidade := preload("res://core/unidade.gd")
const Grade := preload("res://core/grade.gd")

const CURA_COMUM := "pocao_de_cura_pequena"
const SEM_CASA := Vector2i(-99, -99)


static func vinculo(u, c) -> Unidade:
	return u.invocacoes_aliadas.get(c.id) if u != null and c != null and c.tipo == "criatura" else null


static func criaturas(b, u) -> Array:
	return b.unidades.filter(func(o): return o.viva() and o.dono_invocacao == u.id)


static func pode_pagar_fadiga(u, c, qtd: int) -> bool:
	# Triturar abastece o descarte. A ficha seguinte pode então exilar essa carta.
	var excesso := maxi(qtd - maxi(c.espaco(), 0), 0)
	return qtd >= 0 and excesso <= u.baralho.descarte.size() + 2 * u.baralho.baralho.size()


static func pagar_fadiga(b, u, c, qtd: int) -> bool:
	if not pode_pagar_fadiga(u, c, qtd):
		return false
	var na_carta := mini(qtd, maxi(c.espaco(), 0))
	c.pagar(na_carta)
	for i in qtd - na_carta:
		if u.baralho.descarte.is_empty():
			u.baralho.descarte.append(u.baralho.puxar_topo())
			b._log("Fadiga excedente de %s: %s tritura 1 carta." % [c.nome(), u.nome])
		else:
			u.baralho.exilio.append(u.baralho.descarte.pop_back())
			b._log("Fadiga excedente de %s: %s exila 1 carta do descarte." % [c.nome(), u.nome])
	return true


static func casas_chamada(b, u) -> Array:
	var casas := []
	b.visao_dos_herois()
	for x in range(u.pos.x - 4, u.pos.x + 5):
		for y in range(u.pos.y - 4, u.pos.y + 5):
			var p := Vector2i(x, y)
			if b.grade.dentro(p) and not b.grade.bloqueado(p) and b.na_posicao(p) == null \
					and (not b.nevoa_de_guerra or b.explorado.has(p)):
				casas.append(p)
	return casas


static func motivo(b, u, c, acao: String) -> String:
	if not b.vez_do_heroi() or u == null or c == null or c.tipo != "criatura":
		return "carta de criatura indisponível"
	if u.acoes_padrao <= 0:
		return "sem ação Padrão"
	if u.efeitos.has("confuso"):
		return "confuso: só pode ir atrás do alvo e atacá-lo"
	var inv := vinculo(u, c)
	if inv != null and inv.efeitos.has("inv_banida"):
		return "a criatura está banida temporariamente"
	match acao:
		"chamar":
			if c.lado != 0:
				return "recupere o vínculo antes de chamar"
			if inv != null and inv in b.unidades:
				return "a criatura já está em campo"
			if not pode_pagar_fadiga(u, c, int(c.lados[0]["criatura"]["fadiga_criar"])):
				return "sem cartas para pagar o excesso de Fadiga"
		"recolher":
			if inv == null or not inv.viva() or not inv in b.unidades:
				return "a criatura não está em campo"
		"recuperar":
			if c.lado == 0:
				return "o vínculo já está disponível"
			if not CURA_COMUM in u.consumiveis:
				return "precisa de uma Poção de Cura Pequena (Comum)"
		_:
			return "ação desconhecida"
	return ""


static func chamar(b, u, c, pos: Vector2i) -> bool:
	if motivo(b, u, c, "chamar") != "" or not pos in casas_chamada(b, u):
		return false
	var p: Dictionary = c.lados[0]["criatura"]
	pagar_fadiga(b, u, c, int(p["fadiga_criar"]))
	u.acoes_padrao -= 1
	b._agiu(u)
	var inv := vinculo(u, c)
	if inv == null:
		var slug: String = c.lados[0]["slug"]
		var distancia: bool = str(p["ataque"]["tipo"]).begins_with("À distância")
		inv = Unidade.criar({"id": u.id + "/" + c.id, "nome": p["nome"], "lado": "criatura", "tipo": slug,
			"dono_invocacao": u.id, "carta_invocacao": c.id, "vida": int(p["vida"]), "velocidade": int(p["velocidade"]),
			"resistencia": int(p["resistencia"]), "dano": int(p["ataque"]["bonus_dano"]), "a_distancia": distancia,
			"tipo_dano": "Radiante" if slug == "espirito-lanterneiro" else "", "alerta": true,
			"ao_acertar": [{"ficha": "Sangramento"}] if slug == "lobo-atroz" else [],
			"mov_por_turno": 0, "padrao_por_turno": 0, "reacao_por_turno": 0}, b.rng)
		inv.baralho = u.baralho
		u.invocacoes_aliadas[c.id] = inv
	inv.pos = pos
	b.unidades.append(inv)
	if u.ativo("adestrador-arcano"):
		inv.deslocamento = b.passos_por_acao(inv)
		b._log("Entrada em Movimento: %s pode mover %d quadrado(s)." % [inv.nome, inv.deslocamento])
	b.eventos.append({"tipo": "surgir", "id": inv.id})
	b._log("%s chama %s." % [u.nome, inv.nome])
	b._verificar_queda_heroi(u)
	return true


static func recolher(b, u, c) -> bool:
	if motivo(b, u, c, "recolher") != "":
		return false
	var inv := vinculo(u, c)
	u.acoes_padrao -= 1
	b._agiu(u)
	inv.deslocamento = 0
	b.unidades.erase(inv)
	b.eventos.append({"tipo": "sumir", "id": inv.id})
	b._log("%s recolhe %s com %d/%d de Vida." % [u.nome, inv.nome, inv.vida, inv.vida_max])
	return true


static func recuperar(b, u, c) -> bool:
	if motivo(b, u, c, "recuperar") != "":
		return false
	u.acoes_padrao -= 1
	u.consumiveis.erase(CURA_COMUM)
	u.gastos.append(CURA_COMUM)
	b._agiu(u)
	var inv := vinculo(u, c)
	if inv != null:
		inv.vida = inv.vida_max
	c.virar()
	c.fichas.clear()
	b._log("%s usa uma Poção de Cura Pequena e recupera o vínculo de %s." % [u.nome, c.nome()])
	return true


static func sofreu_dano(b, inv, dano: int) -> void:
	if dano <= 0 or not inv.viva():
		return
	inv.vida = maxi(inv.vida - dano, 0)
	if inv.vida > 0:
		return
	var u: Unidade = b.unidade(inv.dono_invocacao)
	if u != null:
		for c in u.cartas:
			if c.id == inv.carta_invocacao and c.lado == 0:
				c.virar()
				c.fichas.clear()
				break
	inv.fichas.clear()
	inv.fontes_de_fichas.clear()
	inv.efeitos.clear()
	inv.deslocamento = 0
	b.unidades.erase(inv)
	b.eventos.append({"tipo": "morte", "id": inv.id})
	b._log("%s cai. Seu vínculo vira para a recuperação." % inv.nome)


static func critico(b, u) -> bool:
	if not u.ativo("adestrador-arcano"):
		return false
	var vivos := 0
	for inv in u.invocacoes_aliadas.values():
		if inv.vida > 0:
			inv.vida = inv.vida_max
			vivos += 1
	if vivos > 0:
		b._log("Renovar os Vínculos: %d invocação(ões) recupera(m) toda a Vida." % vivos)
	return true


static func inicio_turno(b, u) -> void:
	for inv in u.invocacoes_aliadas.values():
		inv.novo_turno()
		if inv.vida > 0:
			for ficha in ["Veneno", "Fogo"]:
				if inv.vida > 0:
					sofreu_dano(b, inv, inv.fichas_total(ficha))


static func fim_turno(b, u) -> void:
	for inv in u.invocacoes_aliadas.values():
		inv.deslocamento = 0
		if inv.vida > 0:
			sofreu_dano(b, inv, inv.fichas_total("Sangramento"))


static func ordem(u, inv) -> Dictionary:
	var o: Dictionary = u.efeitos.get("ordem_invocador", {})
	return o if o.get("criatura", "") == inv.id else {}


static func pode_comandar(b, u, inv) -> bool:
	return b.vez_do_heroi() and inv != null and inv.dono_invocacao == u.id and inv in b.unidades and inv.viva() \
		and not u.efeitos.has("confuso") and not inv.efeitos.has("atordoado")


static func carta(u, inv):
	for c in u.cartas:
		if c.id == inv.carta_invocacao:
			return c
	return null


static func especial(b, u, inv, alvo) -> String:
	if not inv.tipo in ["lobo-atroz", "aranha-de-ambar"]:
		return ""
	var c = carta(u, inv)
	if inv.tipo == "lobo-atroz":
		return "ferimento" if c != null and pode_pagar_fadiga(u, c, 2) and b.motivo_sem_ataque(inv, alvo, false) == "" else ""
	if c != null and pode_pagar_fadiga(u, c, 1) and Grade.distancia(inv.pos, alvo.pos) <= 4 \
			and b.grade.linha_de_visao(inv.pos, alvo.pos) and b.ve_de(inv, inv.pos, alvo.pos):
		return "teia"
	return ""
