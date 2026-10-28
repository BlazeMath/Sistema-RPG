## Cenários PROVISÓRIOS de teste. Ajuste aqui para mudar os combates.
##
## Regra nova: os testes de ataque e defesa são só cartas. A força dos
## inimigos vem do dano, da Força (com Força 3, causam dano mesmo errando)
## e da resistência.
extends RefCounted

const IA := preload("res://core/ia_inimigo.gd")
const Combate := preload("res://core/combate.gd")
const Personagem := preload("res://core/personagem.gd")
const Encontros := preload("res://core/encontros.gd")
const Reacoes := preload("res://core/reacoes_monstros.gd")

## Reação do Goblin Desordeiro (covarde): ao ser atacado, foge 1 quadrado.
const FUGA_COVARDE := {"reacao_por_turno": 1, "reacoes": [{"gatilho": "ao_ser_atacado", "efeito": "mover", "valor": 1, "texto": "foge 1 quadrado"}]}


static func _inimigo(id: String, nome: String, tipo: String, pos: Vector2i, perfil_id: String, extra: Dictionary) -> Dictionary:
	var perfil: Dictionary = IA.PERFIS[perfil_id]
	var cfg := {
		"id": id, "nome": nome, "lado": "inimigo", "tipo": tipo, "pos": pos,
		"vida": 12, "dano": 4, "atributo_dano": 2, "forca": 2, "resistencia": 0, "velocidade": 3,
		"destreza": 2, "iniciativa": 0, "perfil": perfil["nome"],
		"parada_ataque": perfil["parada_ataque"], "parada_defesa": perfil["parada_defesa"], "risco": perfil["risco"],
		"mov_por_turno": 1, "padrao_por_turno": 1, "reacao_por_turno": 0,
	}
	if tipo.begins_with("goblin") and tipo != "goblin_chefe":
		cfg["tamanho"] = "pequeno"
	# Categoria (devoções) e visão no escuro: goblins e toupeiras vivem no subterrâneo.
	if tipo.begins_with("goblin"):
		cfg["categoria"] = "goblinoide"
		cfg["visao_no_escuro"] = true
	elif tipo == "toupeira":
		cfg["categoria"] = "fera"
		cfg["visao_no_escuro"] = true
	cfg.merge(extra, true)
	return cfg


## Inimigo pelo patamar e pelo papel (core/encontros.gd). "extra" sobrescreve
## (aparência, alcance, vigia...). "perfil_id" escolhe o jeito da IA puxar cartas.
static func inimigo_de(id: String, nome: String, tipo: String, pos: Vector2i, patamar: String, papel: String,
		herois: int, extra := {}) -> Dictionary:
	var e: Dictionary = extra.duplicate(true)
	var perfil_id: String = e.get("perfil_id", Encontros.PAPEIS[papel].get("perfil", "bruto"))
	e.erase("perfil_id")
	var st := Encontros.status(patamar, papel, herois)
	if e.has("reacoes") and not st.has("reacao_por_turno"):
		st["reacao_por_turno"] = 1
	st.merge(e, true)
	# Aggro (Lucas): corpo a corpo anda +1; à distância tem +1 no limite do 21 para atacar.
	if papel == "aggro":
		if st.get("a_distancia", false):
			st["bonus_limite_ataque"] = int(st.get("bonus_limite_ataque", 0)) + 1
		else:
			st["velocidade"] = int(st.get("velocidade", 3)) + 1
	return Reacoes.aplicar(_inimigo(id, nome, tipo, pos, perfil_id, st))


## Heróis do grupo: "fichas" pode ser uma ficha só ou uma lista (até 4).
## O primeiro herói tem o id "heroi"; os outros, "heroi2", "heroi3"...
static func herois_cfg(fichas, posicoes: Array) -> Array:
	var lista: Array = fichas if fichas is Array else [fichas]
	var cfgs := []
	for i in mini(lista.size(), posicoes.size()):
		cfgs.append(Personagem.para_unidade(lista[i], "heroi" if i == 0 else "heroi%d" % (i + 1), posicoes[i]))
	return cfgs


## Vida dos inimigos com o tamanho do grupo (regra do Lucas): a base é um grupo
## de 4; cada herói a mais ou a menos muda a vida em 30%.
## "vida_4" é a vida para 4 heróis. Sem ela, "vida" é a base antiga de 1 herói,
## convertida com "por_heroi" (o fator das versões anteriores).
static func escalar(cfg: Dictionary, herois: int, por_heroi := 0.6) -> Dictionary:
	var base4: float = cfg.get("vida_4", cfg["vida"] * (1.0 + por_heroi * 3))
	cfg["vida"] = maxi(int(round(base4 * maxf(1.0 + 0.3 * (herois - 4), 0.1))), 1)
	return cfg


static func _lacaios(ajustar: bool, herois: int, unidades: Array) -> Array:
	return ajustar_lacaios(unidades, herois) if ajustar else unidades


## Lacaios a mais ou a menos: a cada 2 heróis de diferença do grupo de 4, um a
## mais ou um a menos (os marcados com "lacaio").
static func ajustar_lacaios(unidades: Array, herois: int) -> Array:
	var delta := int((herois - 4) / 2.0)
	var lacaios := unidades.filter(func(u): return u.get("lacaio", false))
	if lacaios.is_empty():
		return unidades
	if delta < 0:
		for i in mini(-delta, lacaios.size()):
			unidades.erase(lacaios[lacaios.size() - 1 - i])
	for i in maxi(delta, 0):
		var novo: Dictionary = lacaios[0].duplicate(true)
		novo["id"] = "%s_extra%d" % [novo["id"], i + 1]
		novo["pos"] = novo["pos"] + Vector2i(0, i + 1)
		unidades.append(novo)
	return unidades


static func _quantos(fichas) -> int:
	return fichas.size() if fichas is Array else 1


## Arena: os heróis contra três goblins num pedaço de fazenda.
## Arena (combate simples, regra do Lucas): um lacaio e um médio por herói.
## Com "encontro" = false, monta a arena antiga de 3 goblins (usada pelos testes).
static func arena(fichas, encontro := true) -> Dictionary:
	if not encontro:
		return _arena_classica(fichas)
	var c := _arena_classica(fichas)
	var n := _quantos(fichas)
	var herois_u: Array = c["unidades"].filter(func(u): return u["lado"] == "heroi")
	var casas_l := [Vector2i(9, 3), Vector2i(9, 5), Vector2i(10, 2), Vector2i(9, 7), Vector2i(8, 4), Vector2i(9, 1)]
	var casas_m := [Vector2i(10, 6), Vector2i(11, 8), Vector2i(11, 4), Vector2i(10, 8), Vector2i(11, 1), Vector2i(11, 6)]
	var inimigos := []
	for i in mini(n, casas_l.size()):
		inimigos.append(inimigo_de("goblin%d" % (i * 2 + 1), "Goblin Desordeiro", "goblin", casas_l[i], "lacaio", "aggro", n, FUGA_COVARDE))
	for i in mini(n, casas_m.size()):
		if i % 2 == 0:
			inimigos.append(inimigo_de("goblin%d" % (i * 2 + 2), "Goblin Brigão", "goblin", casas_m[i], "medio", "tank", n, {}))
		else:
			inimigos.append(inimigo_de("goblin%d" % (i * 2 + 2), "Goblin Atirador", "goblin_atirador", casas_m[i], "medio", "aggro", n,
				{"a_distancia": true, "faixas_ideais": [Combate.Faixa.CURTO, Combate.Faixa.MEDIO], "perfil_id": "atirador"}))
	c["unidades"] = herois_u + inimigos.map(func(e): return Encontros.para_combate(e, "simples"))
	c["nome"] = "Arena: a fazenda dos goblins (combate simples)"
	return c


## Encontro genérico na arena, por tipo de combate (para a simulação e testes).
static func encontro_na_arena(fichas, tipo: String) -> Dictionary:
	var c := _arena_classica(fichas)
	var n := _quantos(fichas)
	var herois_u: Array = c["unidades"].filter(func(u): return u["lado"] == "heroi")
	var comp := Encontros.composicao(tipo, n)
	var livres := []
	for x in range(7, 12):
		for y in range(1, 9):
			var p := Vector2i(x, y)
			if not c["obstaculos"].has(p):
				livres.append(p)
	var inimigos := []
	var k := 0
	for patamar in ["chefe", "elite", "elite_escoltado", "medio", "lacaio"]:
		for i in int(comp.get(patamar, 0)):
			var papel := "neutro"
			if patamar == "lacaio":
				papel = ["aggro", "control"][i % 2]
			elif patamar == "medio":
				papel = ["tank", "aggro"][i % 2]
			var visual: String = {"chefe": "goblin_chefe", "elite": "toupeira", "elite_escoltado": "toupeira", "medio": "goblin", "lacaio": "goblin"}[patamar]
			var extra := {"tamanho": "grande"} if patamar in ["elite", "elite_escoltado", "chefe"] else {}
			inimigos.append(inimigo_de("%s%d" % [patamar, i + 1], "%s %d" % [patamar.capitalize(), i + 1], visual, livres[k], patamar, papel, n, extra))
			k += 1
	c["unidades"] = herois_u + inimigos.map(func(e): return Encontros.para_combate(e, tipo))
	c["nome"] = "Encontro: " + tipo
	return c


static func _arena_classica(fichas) -> Dictionary:
	var obstaculos := {}
	for p in [Vector2i(4, 1), Vector2i(4, 2), Vector2i(7, 6), Vector2i(8, 6)]:
		obstaculos[p] = "feno"
	for p in [Vector2i(6, 3), Vector2i(2, 7)]:
		obstaculos[p] = "pedra"
	for x in range(0, 4):
		obstaculos[Vector2i(x, 9)] = "cerca"
	for x in range(8, 12):
		obstaculos[Vector2i(x, 0)] = "cerca"
	return {
		"nome": "Arena: a fazenda dos goblins",
		"largura": 12, "altura": 10, "obstaculos": obstaculos,
		"unidades": (herois_cfg(fichas, [Vector2i(1, 5), Vector2i(1, 4), Vector2i(2, 6), Vector2i(0, 3)]) + [
			escalar(_inimigo("goblin1", "Goblin Desordeiro", "goblin", Vector2i(9, 3), "covarde", FUGA_COVARDE.merged({"lacaio": true}, true)), _quantos(fichas)),
			escalar(_inimigo("goblin2", "Goblin Brigão", "goblin", Vector2i(10, 6), "bruto", {"resistencia": 1, "forca": 3, "atributo_dano": 3, "ataque_oportunidade": true, "reacao_por_turno": 1}), _quantos(fichas)),
			escalar(_inimigo("goblin3", "Goblin Atirador", "goblin_atirador", Vector2i(11, 8), "atirador",
				{"vida": 8, "dano": 3, "atributo_dano": 2, "forca": 0, "destreza": 3, "a_distancia": true,
				"faixas_ideais": [Combate.Faixa.CURTO, Combate.Faixa.MEDIO]}), _quantos(fichas)),
		]),
	}


## X1: o primeiro herói contra o Chefe Goblin num terreiro pequeno.
static func x1(fichas) -> Dictionary:
	var ficha: Dictionary = fichas[0] if fichas is Array else fichas
	var obstaculos := {}
	for p in [Vector2i(3, 2), Vector2i(4, 5)]:
		obstaculos[p] = "feno"
	obstaculos[Vector2i(6, 1)] = "pedra"
	return {
		"nome": "X1: o Chefe Goblin",
		"largura": 8, "altura": 8, "obstaculos": obstaculos,
		"unidades": [
			Personagem.para_unidade(ficha, "heroi", Vector2i(1, 4)),
			inimigo_de("chefe", "Chefe Goblin", "goblin_chefe", Vector2i(6, 4), "elite", "neutro", 1, {"tamanho": "medio"}),
		],
	}


## Compatibilidade com a 0.4: arena com o herói padrão.
static func cenario() -> Dictionary:
	return arena(Personagem.nova(), false)
