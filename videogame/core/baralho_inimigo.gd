## Baralho compartilhado dos inimigos: só valores, sem efeitos, e NÃO é a vida
## deles (a vida dos inimigos é um número à parte). Quando acaba, o descarte é
## embaralhado e vira o novo baralho.
extends "res://core/baralho.gd"


func puxar_topo() -> int:
	if baralho.is_empty():
		if descarte.is_empty():
			return -1
		baralho = descarte.duplicate()
		descarte.clear()
		embaralhar()
	return baralho.pop_back()


func sofrer_dano(_pontos: int) -> int:
	return 0
