## Cartas de baralho comum (52 cartas, sem efeitos).
##
## Uma carta é um inteiro de 0 a 51: posto = id % 13 + 1 (1 = Ás, 11 = Valete,
## 12 = Dama, 13 = Rei) e naipe = id / 13. O naipe não tem efeito mecânico;
## existe só para exibição.
extends RefCounted

const NOMES_POSTO := ["", "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
const NAIPES := ["♠", "♥", "♦", "♣"]


static func posto(carta: int) -> int:
	return carta % 13 + 1


static func naipe(carta: int) -> int:
	return carta / 13


static func eh_as(carta: int) -> bool:
	return posto(carta) == 1


## Valor para o vinte-e-um com o Ás contando 1. Valete, Dama e Rei valem 10.
static func valor(carta: int) -> int:
	return mini(posto(carta), 10)


static func vale_dez(carta: int) -> bool:
	return valor(carta) == 10


static func nome(carta: int) -> String:
	return NOMES_POSTO[posto(carta)] + NAIPES[naipe(carta)]


static func baralho_completo() -> Array[int]:
	var cartas: Array[int] = []
	for i in 52:
		cartas.append(i)
	return cartas
