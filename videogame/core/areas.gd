## Áreas e zonas (regras do Lucas, 0.11).
##
## Formas de área ("forma" no registro da carta, em core/efeitos.gd → "area"):
##   "quadrado"   — N×N num ponto escolhido ("alcance" a partir do personagem, com linha de visão).
##                  N ímpar: centrado no ponto. N par: o ponto é um canto; "rotacao" escolhe o lado.
##   "ao_redor"   — N×N centrado no próprio personagem.
##   "adjacente"  — largura × profundidade colada ao personagem, na direção escolhida (8 direções).
##   "linha"      — "comprimento" quadrados a partir do personagem, numa das 8 direções. Para na
##                  primeira parede (obstáculo que bloqueia a visão) e atravessa personagens.
##   "aglomerado" — um inimigo escolhido e até "maximo" − 1 inimigos encadeados adjacentes a ele.
##   "casa"       — um quadrado só (armadilha), a até "alcance".
##   "cone"       — "tamanho" quadrados a partir do personagem, abrindo até 3 de largura, numa das 8 direções.
## A altura (o terceiro número de 3x3x3) é ignorada por enquanto: o mapa é plano.
extends RefCounted

const Grade := preload("res://core/grade.gd")


## Direção (uma das 8) de "de" para "para".
static func direcao(de: Vector2i, para: Vector2i) -> Vector2i:
	var d := para - de
	var dir := Vector2i(signi(d.x), signi(d.y))
	if dir == Vector2i.ZERO:
		return Vector2i(1, 0)
	# Aproxima para a direção de 8 mais próxima do ângulo.
	var ang := atan2(float(d.y), float(d.x))
	var oit := int(round(ang / (PI / 4.0))) % 8
	var tabela := [Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)]
	return tabela[(oit + 8) % 8]


## Quadrados de uma área. "origem" = quem usa; "alvo" = quadrado apontado pelo jogador.
static func celulas(spec: Dictionary, origem: Vector2i, alvo: Vector2i, rotacao: int, grade) -> Array:
	var lista := []
	match spec.get("forma", "quadrado"):
		"quadrado":
			lista = _quadrado(alvo, int(spec.get("tamanho", 3)), rotacao)
		"ao_redor":
			lista = _quadrado(origem, int(spec.get("tamanho", 3)), 0)
		"casa":
			lista = [alvo]
		"adjacente":
			var d := direcao(origem, alvo)
			var larg := int(spec.get("largura", spec.get("tamanho", 3)))
			var prof := int(spec.get("profundidade", spec.get("tamanho", 3)))
			var xs := []
			var ys := []
			if d.x != 0:
				for i in prof:
					xs.append(origem.x + d.x * (i + 1))
			else:
				for i in larg:
					xs.append(origem.x - int((larg - 1) / 2) + i)
			if d.y != 0:
				for i in (prof if d.x == 0 else larg):
					ys.append(origem.y + d.y * (i + 1))
			else:
				for i in larg:
					ys.append(origem.y - int((larg - 1) / 2) + i)
			for x in xs:
				for y in ys:
					lista.append(Vector2i(x, y))
		"cone":
			# Cone de tamanho N: quadrados a até N, a no máximo ~26,6° da direção
			# (3 de largura no fim: 7 quadrados reto, 9 na diagonal). Paredes tapam.
			var d := direcao(origem, alvo)
			var n := int(spec.get("tamanho", 3))
			var dv := Vector2(d).normalized()
			for x in range(-n, n + 1):
				for y in range(-n, n + 1):
					var off := Vector2i(x, y)
					if off == Vector2i.ZERO:
						continue
					if Vector2(off).normalized().dot(dv) >= 0.894 and grade.linha_de_visao(origem, origem + off):
						lista.append(origem + off)
		"linha":
			var d := direcao(origem, alvo)
			var p := origem
			for i in int(spec.get("comprimento", 4)):
				p += d
				if not grade.dentro(p) or (grade.obstaculos.has(p) and not grade.obstaculos[p] in Grade.BAIXOS):
					break
				lista.append(p)
	return lista.filter(func(c): return grade.dentro(c))


static func _quadrado(p: Vector2i, n: int, rotacao: int) -> Array:
	var lista := []
	if n % 2 == 1:
		var r := int((n - 1) / 2)
		for x in range(-r, r + 1):
			for y in range(-r, r + 1):
				lista.append(p + Vector2i(x, y))
		return lista
	var sx: int = [1, -1, -1, 1][rotacao % 4]
	var sy: int = [1, 1, -1, -1][rotacao % 4]
	for i in n:
		for j in n:
			lista.append(p + Vector2i(sx * i, sy * j))
	return lista


## A forma muda com "rotacao"? (o jogador gira com R)
static func gira(spec: Dictionary) -> bool:
	return spec.get("forma", "") == "quadrado" and int(spec.get("tamanho", 3)) % 2 == 0


## O jogador aponta uma direção (não um ponto)?
static func por_direcao(spec: Dictionary) -> bool:
	return spec.get("forma", "") in ["adjacente", "linha", "cone"]


## Centro (em números reais) de um conjunto de quadrados: para empurrar "para fora da área".
static func centro(cels: Array) -> Vector2:
	var s := Vector2.ZERO
	for c in cels:
		s += Vector2(c)
	return s / maxf(cels.size(), 1)


## Direção para fora da área a partir de "p".
static func para_fora(cels: Array, p: Vector2i) -> Vector2i:
	var c := centro(cels)
	var d := Vector2(p) - c
	var dir := Vector2i(signi(roundi(d.x * 10)), signi(roundi(d.y * 10)))
	return dir if dir != Vector2i.ZERO else Vector2i(1, 0)
