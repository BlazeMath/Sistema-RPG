## O baralho do personagem: ao mesmo tempo a fonte de sorte e a vida.
##
## Zonas: baralho (de onde se compra; é a energia), mão, descarte (recuperável)
## e exílio. O topo do baralho é o FIM do array; o fundo é o índice 0.
##
## Regras do Sistema 21 digital implementadas aqui:
## - Dano move cartas do topo do baralho para o descarte, 1 por ponto.
## - Baralho vazio = inconsciente. Dano em inconsciente move cartas do descarte
##   para o exílio. Perder todo o descarte assim = morte.
## - Cura: exila ao menos 1 carta do descarte e devolve ao fundo do baralho
##   tantas cartas do descarte quanto a cura.
## - Início de cena: a mão antiga é embaralhada de volta no baralho e o
##   personagem compra uma mão nova de 2 + Sabedoria.
## - Descanso curto: exila 1 carta do descarte e devolve até 10 do descarte.
## - Descanso longo: todas as cartas voltam e o baralho é embaralhado.
extends RefCounted

const Carta := preload("res://core/carta.gd")

enum Estado { ATIVO, INCONSCIENTE, MORTO }

const RECUPERACAO_DESCANSO_CURTO := 10

var baralho: Array[int] = []
var mao: Array[int] = []
var descarte: Array[int] = []
var exilio: Array[int] = []
var estado: Estado = Estado.ATIVO
var rng: RandomNumberGenerator


func _init(gerador: RandomNumberGenerator = null) -> void:
	rng = gerador if gerador != null else RandomNumberGenerator.new()
	baralho = Carta.baralho_completo()
	embaralhar()


func embaralhar() -> void:
	# Fisher-Yates com o gerador do jogo, para partidas reproduzíveis por semente.
	for i in range(baralho.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := baralho[i]
		baralho[i] = baralho[j]
		baralho[j] = tmp


func total_cartas() -> int:
	return baralho.size() + mao.size() + descarte.size() + exilio.size()


func vazio() -> bool:
	return baralho.is_empty()


## Tira a carta do topo do baralho. Retorna -1 se o baralho está vazio.
func puxar_topo() -> int:
	if baralho.is_empty():
		return -1
	var carta: int = baralho.pop_back()
	_verificar_queda()
	return carta


## Início de cena: embaralha a mão antiga no baralho e compra 2 + Sabedoria.
func iniciar_cena(sabedoria: int) -> void:
	if estado != Estado.ATIVO:
		return
	if not mao.is_empty():
		baralho.append_array(mao)
		mao.clear()
		embaralhar()
	comprar_para_mao(2 + sabedoria)


func comprar_para_mao(quantidade: int) -> int:
	var compradas := 0
	for i in quantidade:
		var carta := puxar_topo()
		if carta < 0:
			break
		mao.append(carta)
		compradas += 1
	return compradas


## Remove uma carta da mão (para jogar num teste). Retorna false se não estava lá.
func tirar_da_mao(carta: int) -> bool:
	var i := mao.find(carta)
	if i < 0:
		return false
	mao.remove_at(i)
	return true


func descartar(cartas: Array[int]) -> void:
	descarte.append_array(cartas)


## Aplica dano. Retorna quantas cartas foram perdidas.
func sofrer_dano(pontos: int) -> int:
	var perdidas := 0
	for i in maxi(pontos, 0):
		if estado == Estado.MORTO:
			break
		if estado == Estado.ATIVO:
			var carta := puxar_topo()
			if carta < 0:
				break
			descarte.append(carta)
		else:
			# Inconsciente: o dano corrói o descarte, mandando cartas ao exílio.
			if descarte.is_empty():
				estado = Estado.MORTO
				break
			exilio.append(descarte.pop_back())
			if descarte.is_empty():
				estado = Estado.MORTO
		perdidas += 1
	return perdidas


## Cura: exila ao menos 1 carta do descarte, depois devolve ao fundo do baralho.
## Retorna quantas cartas voltaram ao baralho.
func curar(pontos: int) -> int:
	if pontos <= 0 or descarte.is_empty() or estado == Estado.MORTO:
		return 0
	exilio.append(descarte.pop_back())
	return _devolver_do_descarte(pontos)


func descanso_curto() -> int:
	if estado == Estado.MORTO or descarte.is_empty():
		return 0
	exilio.append(descarte.pop_back())
	return _devolver_do_descarte(RECUPERACAO_DESCANSO_CURTO)


func descanso_longo() -> void:
	if estado == Estado.MORTO:
		return
	baralho.append_array(mao)
	baralho.append_array(descarte)
	baralho.append_array(exilio)
	mao.clear()
	descarte.clear()
	exilio.clear()
	embaralhar()
	estado = Estado.ATIVO


func _devolver_do_descarte(quantidade: int) -> int:
	var devolvidas := 0
	while devolvidas < quantidade and not descarte.is_empty():
		baralho.insert(0, descarte.pop_back())
		devolvidas += 1
	if devolvidas > 0 and estado == Estado.INCONSCIENTE:
		estado = Estado.ATIVO
	return devolvidas


func _verificar_queda() -> void:
	if baralho.is_empty() and estado == Estado.ATIVO:
		estado = Estado.INCONSCIENTE
