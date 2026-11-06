## Ordens e habilidades gerais do Invocador, separadas do ciclo de vida da criatura.
extends RefCounted

const Grade := preload("res://core/grade.gd")

const LADOS := {
	"adestrador-arcano": {"uso": "ativada", "alvo": "invocacao_propria", "custo": {"fadiga": 0, "acao": "padrao"}},
	"ataque-guiado": {"uso": "ativada", "alvo": "invocacao_propria", "alcance": 8},
	"vinculo-restaurador": {"uso": "ativada", "alvo": "invocacao_propria", "alcance": 4},
	"forma-exaltada": {"uso": "ativada", "alvo": "invocacao_propria", "alcance": 8},
	"passagem-do-vinculo": {"uso": "ativada", "alvo": "invocacao_propria", "alcance": 8},
	"banimento-temporario": {"uso": "ativada", "alvo": "inimigo_invocado", "alcance": 4},
}


static func registro(c) -> Dictionary:
	if str(c.id).begins_with("classe.invocador.") or (c.tipo == "heroi" and c.slug() == "adestrador-arcano"):
		return LADOS.get(c.slug(), {})
	return {}


static func alvos(b, u, c, info: Dictionary) -> Array:
	var alcance := int(info.get("alcance", -1))
	var lista := []
	for o in b.unidades:
		if not o.viva():
			continue
		if alcance >= 0 and Grade.distancia(u.pos, o.pos) > alcance:
			continue
		if info["alvo"] == "inimigo_invocado":
			var controlador = b.unidade(o.efeitos.get("invocado_por", {}).get("id", ""))
			if controlador != null and controlador.viva() and not o.eh_aliado() \
					and b.grade.linha_de_visao(u.pos, o.pos) and b.ve_de(u, u.pos, o.pos):
				lista.append(o)
			continue
		if o.dono_invocacao != u.id:
			continue
		match c.slug():
			"vinculo-restaurador":
				if o.vida == o.vida_max:
					continue
			"passagem-do-vinculo":
				if b.preso(u) or b.preso(o) or not b.grade.linha_de_visao(u.pos, o.pos) or not b.ve_de(u, u.pos, o.pos):
					continue
				if b.grade.bloqueado(o.pos) or b.grade.bloqueado(u.pos):
					continue
		lista.append(o)
	return lista


static func motivo(u, c) -> String:
	match c.slug():
		"adestrador-arcano", "ataque-guiado":
			if u.efeitos.has("ordem_invocador"):
				return "já há uma ordem a resolver neste turno"
		"vinculo-restaurador":
			if u.baralho.descarte.is_empty():
				return "precisa de uma carta no descarte para exilar"
	return ""


static func usar(b, u, c, alvo) -> void:
	match c.slug():
		"adestrador-arcano", "ataque-guiado":
			var nome: String = "Ordem de Assalto" if c.slug() == "adestrador-arcano" else c.nome()
			u.efeitos["ordem_invocador"] = {"criatura": alvo.id, "movimento": 2, "ataque": true,
				"bonus_dano": 2 if c.slug() == "ataque-guiado" else 0, "ate": "inicio_turno"}
			b._log("%s: %s pode se mover até 2 quadrados e atacar neste turno." % [nome, alvo.nome])
		"vinculo-restaurador":
			u.baralho.exilio.append(u.baralho.descarte.pop_back())
			var cura := mini(6, alvo.vida_max - alvo.vida)
			alvo.vida += cura
			b.eventos.append({"tipo": "cura", "id": alvo.id, "valor": cura})
			b._log("Vínculo Restaurador: %s recupera %d de Vida." % [alvo.nome, cura])
		"forma-exaltada":
			for o in u.invocacoes_aliadas.values():
				o.efeitos.erase("forma_exaltada")
			alvo.efeitos["forma_exaltada"] = {}
			b._log("Forma Exaltada: %s recebe +4 de dano e +2 de Resistência até o fim da cena." % alvo.nome)
		"passagem-do-vinculo":
			var origem: Vector2i = u.pos
			u.pos = alvo.pos
			alvo.pos = origem
			b.eventos.append({"tipo": "teleporte", "id": u.id})
			b.eventos.append({"tipo": "teleporte", "id": alvo.id})
			b._verificar_avistamentos()
			b._log("Passagem do Vínculo: %s troca de posição com %s." % [u.nome, alvo.nome])
		"banimento-temporario":
			_testar_banimento(b, u, alvo)


static func _testar_banimento(b, u, alvo) -> void:
	var controlador = b.unidade(alvo.efeitos["invocado_por"]["id"])
	var oposicao: int = b.valor_resistido(controlador, "espirito") + b.valor_componente(controlador, "Arcanismo")
	b._log("Banimento Temporário: vença %d no teste contestado contra %s." % [oposicao, controlador.nome])
	b.teste_de_acao(u, {"titulo": "Banimento Temporário", "texto": alvo.nome,
		"teste": {"somar": ["espirito", "Arcanismo"]}, "faixas": [[0, "falha"], [oposicao + 1, "sucesso"]],
		"resultados": {"falha": {"rotulo": "falha", "texto": "O vínculo do adversário resiste."},
			"sucesso": {"rotulo": "sucesso", "texto": "A invocação desaparece temporariamente.",
				"efeitos": [{"tipo": "invocador_banir"}]}}}, alvo)


static func banir(b, u, alvo) -> String:
	if alvo == null or not alvo.viva():
		return "O alvo já não está em campo."
	alvo.efeitos["inv_banida"] = {"responsavel": u.id}
	b.eventos.append({"tipo": "sumir", "id": alvo.id})
	b._log("Banimento Temporário: %s sai do campo com %d de Vida." % [alvo.nome, alvo.vida])
	return "A invocação volta no próximo turno de %s." % u.nome


static func retornar_banidas(b, u) -> void:
	for alvo in b.unidades:
		var estado: Dictionary = alvo.efeitos.get("inv_banida", {})
		if estado.is_empty():
			continue
		var responsavel = b.unidade(estado["responsavel"])
		if responsavel != u and responsavel != null and responsavel.viva():
			continue
		var destino := _retorno(b, alvo.pos)
		if destino == Vector2i(-1, -1):
			continue
		alvo.pos = destino
		alvo.efeitos.erase("inv_banida")
		b.eventos.append({"tipo": "surgir", "id": alvo.id})
		b._log("Banimento Temporário: %s volta com %d de Vida." % [alvo.nome, alvo.vida])


static func _retorno(b, origem: Vector2i) -> Vector2i:
	if not b.grade.bloqueado(origem) and b.na_posicao(origem) == null:
		return origem
	var melhor := Vector2i(-1, -1)
	var distancia := maxi(b.grade.largura, b.grade.altura)
	for y in b.grade.altura:
		for x in b.grade.largura:
			var p := Vector2i(x, y)
			var d := Grade.distancia(origem, p)
			if d < distancia and not b.grade.bloqueado(p) and b.na_posicao(p) == null:
				melhor = p
				distancia = d
	return melhor
