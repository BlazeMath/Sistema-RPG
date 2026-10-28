## Iniciativa simulada: define a ordem dos turnos sem mostrar o teste.
##
## Decisões (Lucas, 20/10/2026):
## - Rodada no início de cada cena; quem entra depois faz a própria e é inserido.
## - Usa um baralho à parte, embaralhado para cada participante: não gasta vida.
## - Puxa apenas 2 cartas, soma (Ás vale 11, ou 1 se fossem dois Ases) e soma
##   Destreza + Iniciativa. Não há risco de estouro.
## Empate: maior modificador; depois, sorteio.
extends RefCounted

const Carta := preload("res://core/carta.gd")

## participantes: Array de Dictionary com "id", "destreza" e "iniciativa".
## Retorna os ids em ordem de ação (primeiro a agir no índice 0).
static func ordenar(participantes: Array, rng: RandomNumberGenerator) -> Array:
	var rolagens := []
	for p in participantes:
		var mod: int = p.get("destreza", 0) + p.get("iniciativa", 0)
		rolagens.append({
			"id": p["id"],
			"valor": simular_teste(mod, rng),
			"mod": mod,
			"sorteio": rng.randi(),
		})
	rolagens.sort_custom(_vem_antes)
	return rolagens.map(func(r): return r["id"])


static func inserir(ordem: Array, participante: Dictionary, valores: Dictionary, rng: RandomNumberGenerator) -> Array:
	## Insere quem entrou depois. "valores" mapeia id -> valor de iniciativa dos
	## que já estão na ordem (guardado pelo chamador). Retorna a nova ordem.
	var mod: int = participante.get("destreza", 0) + participante.get("iniciativa", 0)
	var v := simular_teste(mod, rng)
	valores[participante["id"]] = v
	var nova := ordem.duplicate()
	var pos := nova.size()
	for i in nova.size():
		if v > valores.get(nova[i], 0):
			pos = i
			break
	nova.insert(pos, participante["id"])
	return nova


static func simular_teste(mod: int, rng: RandomNumberGenerator) -> int:
	var cartas := Carta.baralho_completo()
	# Embaralha uma cópia só para esta simulação.
	for i in range(cartas.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := cartas[i]
		cartas[i] = cartas[j]
		cartas[j] = tmp
	var mao: Array[int] = [cartas.pop_back(), cartas.pop_back()]
	return _soma(mao) + mod


static func _soma(mao: Array[int]) -> int:
	var soma := 0
	var tem_as := false
	for c in mao:
		soma += Carta.valor(c)
		tem_as = tem_as or Carta.eh_as(c)
	if tem_as and soma + 10 <= 21:
		soma += 10
	return soma


static func _vem_antes(a: Dictionary, b: Dictionary) -> bool:
	if a["valor"] != b["valor"]:
		return a["valor"] > b["valor"]
	if a["mod"] != b["mod"]:
		return a["mod"] > b["mod"]
	return a["sorteio"] > b["sorteio"]
