## Resolução de ataques e cálculo de dano.
##
## Dano = (ataque - defesa) + dano da arma + atributo do ataque - resistência.
## Só acerta se o ataque for MAIOR que a defesa (empate é erro).
extends RefCounted


static func acertou(ataque: int, defesa: int) -> bool:
	return ataque > defesa


static func calcular_dano(ataque: int, defesa: int, dano_arma: int, atributo: int, resistencia: int) -> int:
	if not acertou(ataque, defesa):
		return 0
	return maxi((ataque - defesa) + dano_arma + atributo - resistencia, 0)


## Faixa de distância entre dois quadrados (distância em quadrados, já calculada).
## Curto: até 4 · Médio: 5 a 8 · Longo: 9 a 12 · além de 12: fora de alcance.
enum Faixa { CURTO, MEDIO, LONGO, FORA }

static func faixa(distancia: int) -> Faixa:
	if distancia <= 4:
		return Faixa.CURTO
	if distancia <= 8:
		return Faixa.MEDIO
	if distancia <= 12:
		return Faixa.LONGO
	return Faixa.FORA
