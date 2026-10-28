## O campo de batalha em quadrados.
##
## Decisões provisórias (confirmar com o Lucas):
## - Movimento em 8 direções; diagonal custa 1 quadrado, como as retas.
## - Não se corta canto: a diagonal exige as duas retas vizinhas livres de obstáculo.
## - Distância entre quadrados = maior diferença entre colunas ou linhas.
## - Adjacente = qualquer um dos 8 vizinhos.
## - Linha de visão: a linha entre os centros não pode passar por obstáculo.
extends RefCounted

const DIRECOES: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]

var largura: int
var altura: int
var obstaculos := {}  # Vector2i -> tipo ("pedra", "feno", "cerca")
var niveis := {}            # 0.23: Vector2i -> nível (0 = chão; 1 = andar de cima; -1 = fosso)
var escadas := {}           # 0.23: casas de escada/rampa: ligam níveis vizinhos
var custo_extra := {}       # Vector2i -> custo a mais para entrar (terreno difícil: 1, ou seja, vale 2)
var visao_bloqueada := {}   # Vector2i -> true (objetos criados por zonas que tapam a visão)
var bloqueio_extra := {}    # Vector2i -> true (objetos criados por zonas que fecham a passagem: Muro)

## Obstáculos baixos: bloqueiam o caminho, mas não a linha de visão.
const BAIXOS := ["agua", "agua_pedras", "ponte_quebrada", "tronco", "fogueira", "fogueira_apagada", "saco", "poco", "cerca",
	"sarcofago", "mesa", "fonte", "altar"]


func _init(l: int, a: int) -> void:
	largura = l
	altura = a


func dentro(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < largura and p.y < altura


func nivel(p: Vector2i) -> int:
	return int(niveis.get(p, 0))


func bloqueado(p: Vector2i, nada := false) -> bool:
	if nada and obstaculos.get(p, "") in AGUA:
		return bloqueio_extra.has(p)
	return obstaculos.has(p) or bloqueio_extra.has(p) or not dentro(p)


## Água que quem nada (Nado Avançado) atravessa.
const AGUA := ["agua", "agua_pedras"]


static func distancia(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


static func adjacentes(a: Vector2i, b: Vector2i) -> bool:
	return distancia(a, b) == 1


## Quadrados vizinhos para onde se pode dar um passo (ignora unidades).
func vizinhos(p: Vector2i, nada := false, escalar := false) -> Array[Vector2i]:
	var lista: Array[Vector2i] = []
	for d in DIRECOES:
		var n := p + d
		if bloqueado(n, nada):
			continue
		if d.x != 0 and d.y != 0:
			if bloqueado(p + Vector2i(d.x, 0), nada) or bloqueado(p + Vector2i(0, d.y), nada):
				continue
		# Níveis (0.23): só se troca de nível por uma escada (um nível por passo).
		var dh := absi(nivel(n) - nivel(p))
		if not escalar and (dh > 1 or (dh == 1 and not (escadas.has(n) or escadas.has(p)))):
			continue
		lista.append(n)
	return lista


## Quadrados alcançáveis a partir de "origem" com até "passos" de deslocamento.
## "ocupadas": quadrados com unidades (não se entra neles).
## "perigos": quadrados vizinhos a inimigos. Entrar num deles impede o personagem
## (a velocidade cai a zero), então dali não se continua andando.
## Retorna Dictionary: quadrado -> {"custo": int, "anterior": Vector2i}.
## "modo": {"nada": true} atravessa água; {"sem_terreno": true} ignora terreno difícil.
func alcance(origem: Vector2i, passos: int, ocupadas: Dictionary, perigos: Dictionary, modo := {}) -> Dictionary:
	var nada: bool = modo.get("nada", false)
	var sem_terreno: bool = modo.get("sem_terreno", false)
	# Lucas (0.20): heróis atravessam aliados (sem parar na casa deles): "passa" no mapa.
	var aliados: Dictionary = modo.get("aliados", {})
	var mapa := {origem: {"custo": 0, "anterior": origem}}
	var abertos: Array[Vector2i] = [origem]
	while not abertos.is_empty():
		# o de menor custo primeiro (terreno difícil custa 2)
		var mi := 0
		for i in abertos.size():
			if mapa[abertos[i]]["custo"] < mapa[abertos[mi]]["custo"]:
				mi = i
		var p: Vector2i = abertos[mi]
		abertos.remove_at(mi)
		var custo: int = mapa[p]["custo"]
		if p != origem and perigos.has(p):
			continue
		if custo >= passos:
			continue
		for n in vizinhos(p, nada, modo.get("escalar", false)):
			if ocupadas.has(n) and not aliados.has(n):
				continue
			var c2: int = custo + 1 + (0 if sem_terreno else int(custo_extra.get(n, 0)))
			if c2 > passos or (mapa.has(n) and mapa[n]["custo"] <= c2):
				continue
			mapa[n] = {"custo": c2, "anterior": p}
			if aliados.has(n):
				mapa[n]["passa"] = true
			abertos.append(n)
	return mapa


## Caminho (sem a origem) até "destino" num mapa devolvido por alcance().
static func caminho(mapa: Dictionary, destino: Vector2i) -> Array[Vector2i]:
	var lista: Array[Vector2i] = []
	if not mapa.has(destino):
		return lista
	var p := destino
	while mapa.has(p) and mapa[p]["anterior"] != p:
		lista.push_front(p)
		p = mapa[p]["anterior"]
	return lista


## Linha de visão entre os centros de dois quadrados.
func linha_de_visao(a: Vector2i, b: Vector2i) -> bool:
	var passos := maxi(absi(b.x - a.x), absi(b.y - a.y)) * 4
	if passos == 0:
		return true
	for i in range(1, passos):
		var t := float(i) / passos
		var x := lerpf(a.x, b.x, t)
		var y := lerpf(a.y, b.y, t)
		var celula := Vector2i(roundi(x), roundi(y))
		if celula != a and celula != b and ((obstaculos.has(celula) and not obstaculos[celula] in BAIXOS) or visao_bloqueada.has(celula)):
			return false
	return true
