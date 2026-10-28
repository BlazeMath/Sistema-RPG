## Inteligência dos inimigos nos testes de 21 ("nível 2: lê a mesa").
##
## O inimigo conhece a composição do baralho compartilhado dos inimigos (não a
## ordem), então calcula a chance REAL de estourar com a próxima carta. Cada
## perfil tem um apetite de risco. Ele também lê o que está à vista:
## - Atacando (joga primeiro): se a defesa do herói está revelada (ex.: Postura
##   do Leão), tenta pelo menos passar o valor revelado.
## - Defendendo (joga segundo): vê as cartas do atacante, menos a fechada.
##   Estima a fechada em 7 (média) e tenta empatar ou passar (empate é da defesa).
##   Se o atacante estourou, sabe o valor exato e para assim que alcançar.
## Ele nunca espia a carta fechada escondida do jogador.
extends RefCounted

const Carta := preload("res://core/carta.gd")

const PERFIS := {
	"bruto": {"nome": "Bruto", "parada_ataque": 18, "parada_defesa": 15, "risco": 0.55},
	"covarde": {"nome": "Covarde", "parada_ataque": 14, "parada_defesa": 17, "risco": 0.25},
	"atirador": {"nome": "Atirador", "parada_ataque": 16, "parada_defesa": 16, "risco": 0.40},
	"oportunista": {"nome": "Oportunista", "parada_ataque": 16, "parada_defesa": 16, "risco": 0.45},
	"protetor": {"nome": "Protetor", "parada_ataque": 15, "parada_defesa": 18, "risco": 0.35},
}

const ESTIMATIVA_FECHADA := 7


## Chance de estourar puxando 1 carta, dado o que pode vir do baralho.
static func chance_de_estouro(teste, restantes: Array) -> float:
	if restantes.is_empty():
		return 0.0
	var estoura := 0
	for c in restantes:
		teste.cartas.append(c)
		if teste.soma_cartas() > teste.limite:
			estoura += 1
		teste.cartas.pop_back()
	return float(estoura) / restantes.size()


## Valor que a IA quer alcançar neste teste.
## "proprio": o teste da IA · "oponente": o teste do outro lado · "ataca": a IA é o atacante.
static func alvo(proprio, oponente, ataca: bool, parada: int) -> int:
	if oponente == null:
		return parada
	if ataca:
		# Joga primeiro. Só sabe da defesa o que está à vista.
		if oponente.revelado:
			return clampi(maxi(parada, oponente.soma_cartas() + 1), 0, proprio.limite)
		return parada
	# Defende: o atacante já jogou.
	if oponente.estourou:
		return oponente.resultado()
	var visivel := 0
	for i in oponente.cartas.size():
		if i == 1 and not oponente.revelado:
			continue
		visivel += 11 if Carta.eh_as(oponente.cartas[i]) else Carta.valor(oponente.cartas[i])
	var estimado: int = visivel + (0 if oponente.revelado else ESTIMATIVA_FECHADA) + oponente.ajuste
	return clampi(maxi(estimado, mini(parada, 14)), 0, proprio.limite)


static func quer_puxar(proprio, oponente, ataca: bool, parada: int, risco: float, restantes: Array) -> bool:
	if not proprio.pode_puxar():
		return false
	if proprio.soma_cartas() >= alvo(proprio, oponente, ataca, parada):
		return false
	return chance_de_estouro(proprio, restantes) <= risco
