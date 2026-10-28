## Um teste de vinte-e-um, jogado carta a carta.
##
## Uso:
##   var t = Teste21.new(baralho, modificador)  # compra as 2 cartas iniciais
##   t.puxar()                  # puxa mais uma do baralho
##   t.jogar_da_mao(carta)      # joga uma carta da mão (conta para estourar)
##   t.parar()                  # encerra; t.resultado() dá o valor final
##
## Regras:
## - As duas primeiras cartas: a 1ª é a Aberta (todos veem), a 2ª é a Fechada.
## - O estouro se mede nas cartas, contra o limite (21 por padrão; armadura e
##   habilidades mudam o limite). Em testes de perícia, atributo + perícia
##   entram depois (modificador) e não estouram.
## - Em ataque e defesa NÃO há modificador: só as cartas e os ajustes de
##   habilidades ("some +1 no ataque", "+2 na defesa"), que contam para estourar.
## - Ás vale 1 ou 11: o jogo escolhe o melhor valor que não estoura.
## - Ao estourar, puxa-se uma última carta: o teste vale essa carta + modificador.
## - 21 natural de duas cartas (um Ás e uma carta de valor 10) é crítico.
## - Desvantagem: joga só com as duas cartas iniciais, sem puxar nem jogar da mão.
## - Vantagem: depois de parar, pode trocar uma carta usada por uma da mão.
## - Ao fim, todas as cartas usadas vão para o descarte (testes gastam vida).
extends RefCounted

const Carta := preload("res://core/carta.gd")
const Baralho := preload("res://core/baralho.gd")

var baralho: Baralho
var modificador: int
var limite: int
var vantagem: bool
var desvantagem: bool

var cartas: Array[int] = []        # cartas em jogo, na ordem em que entraram
var da_mao: Array[int] = []        # cartas que vieram da mão do jogador
var carta_do_estouro: int = -1     # a última carta puxada após estourar
var estourou := false
var encerrado := false
var vantagem_usada := false
var ajuste := 0                    # soma de ajustes de habilidade (conta para estourar)
var ajustes_usados: Array[String] = []
var revelado := false              # a carta fechada está à vista do oponente
var sem_puxar := false             # fora da distância ideal ou com cobertura: não puxa do baralho, mas joga da mão
var resultado_forcado := -1        # cartas que mudam o resultado (ex.: Sorte dos Pequenos: 21)
## Lucas (0.20): entre a 1ª carta (aberta) e a 2ª (fechada) o herói pode gastar uma
## ficha de Foco (scry 1). Com "adiar_fechada", a 2ª só chega com receber_fechada()
## (ou sozinha na primeira ação do teste).
var fechada_pendente := false


func _init(b: Baralho, mod: int = 0, lim: int = 21, com_vantagem := false, com_desvantagem := false, iniciais := 2, adiar_fechada := false) -> void:
	baralho = b
	modificador = mod
	limite = lim
	vantagem = com_vantagem and not com_desvantagem
	desvantagem = com_desvantagem and not com_vantagem
	sem_puxar = iniciais < 2
	if adiar_fechada and iniciais == 2:
		iniciais = 1
		fechada_pendente = true
	for i in iniciais:
		var c := baralho.puxar_topo()
		if c >= 0:
			cartas.append(c)
	if soma_cartas() > limite:
		_estourar()


func receber_fechada() -> void:
	if not fechada_pendente:
		return
	fechada_pendente = false
	var c := baralho.puxar_topo()
	if c >= 0:
		cartas.append(c)
	if soma_cartas() > limite:
		_estourar()


func carta_aberta() -> int:
	return cartas[0] if cartas.size() > 0 else -1


func carta_fechada() -> int:
	return cartas[1] if cartas.size() > 1 else -1


## Soma das cartas com o Ás valendo 11 quando isso não estoura.
func soma_cartas() -> int:
	var soma := 0
	var tem_as := false
	for c in cartas:
		soma += Carta.valor(c)
		tem_as = tem_as or Carta.eh_as(c)
	if tem_as and soma + 10 + ajuste <= limite:
		soma += 10
	return soma + ajuste


## Aplica um ajuste de habilidade (ex.: +1 da Destreza). Conta para estourar.
func aplicar_ajuste(nome: String, valor: int) -> bool:
	receber_fechada()
	if encerrado or nome in ajustes_usados:
		return false
	ajustes_usados.append(nome)
	ajuste += valor
	if soma_cartas() > limite:
		_estourar()
	return true


## Muda o limite no meio do teste (ex.: Tiro Certeiro no defensor). Se as cartas já
## passarem do novo limite, estoura.
func ajustar_limite(delta: int) -> void:
	limite += delta
	if not estourou and soma_cartas() > limite:
		_estourar()


func pode_puxar() -> bool:
	return not encerrado and not desvantagem and not sem_puxar


func pode_jogar_da_mao() -> bool:
	return not encerrado and not desvantagem


func puxar() -> bool:
	if fechada_pendente:
		receber_fechada()   # o primeiro "puxar" entrega a carta fechada
		return true
	if not pode_puxar():
		return false
	var c := baralho.puxar_topo()
	if c < 0:
		return false
	cartas.append(c)
	if soma_cartas() > limite:
		_estourar()
	return true


func jogar_da_mao(carta: int) -> bool:
	receber_fechada()
	if not pode_jogar_da_mao() or not baralho.tirar_da_mao(carta):
		return false
	cartas.append(carta)
	da_mao.append(carta)
	if soma_cartas() > limite:
		_estourar()
	return true


func parar() -> void:
	receber_fechada()
	if encerrado:
		return
	encerrado = true
	if not vantagem:
		_finalizar()


## Vantagem: troca uma carta usada por uma carta da mão, depois de parar.
## A carta trocada volta para a mão.
func trocar_com_vantagem(carta_usada: int, carta_da_mao: int) -> bool:
	if not (vantagem and encerrado and not estourou and not vantagem_usada):
		return false
	var i := cartas.find(carta_usada)
	if i < 0 or not baralho.tirar_da_mao(carta_da_mao):
		return false
	cartas[i] = carta_da_mao
	baralho.mao.append(carta_usada)
	vantagem_usada = true
	return true


## Vantagem de quem não tem mão (inimigos): revela a carta do topo e troca
## pela carta usada que mais melhora o resultado sem estourar.
func vantagem_automatica() -> void:
	if not (vantagem and encerrado and not estourou and not vantagem_usada):
		confirmar()
		return
	var nova := baralho.puxar_topo()
	if nova < 0:
		confirmar()
		return
	var melhor := -1
	var melhor_soma := soma_cartas()
	for i in cartas.size():
		var velha := cartas[i]
		cartas[i] = nova
		var soma := soma_cartas()
		cartas[i] = velha
		if soma <= limite and soma > melhor_soma:
			melhor_soma = soma
			melhor = i
	if melhor >= 0:
		baralho.descartar([cartas[melhor]] as Array[int])
		cartas[melhor] = nova
	else:
		baralho.descartar([nova] as Array[int])
	vantagem_usada = true
	confirmar()


## Encerra a fase de vantagem (o jogador escolheu não trocar ou já trocou).
func confirmar() -> void:
	if encerrado and vantagem:
		_finalizar()
		vantagem = false


func critico() -> bool:
	if cartas.size() != 2 or estourou:
		return false
	var a := cartas[0]
	var b := cartas[1]
	return (Carta.eh_as(a) and Carta.vale_dez(b)) or (Carta.eh_as(b) and Carta.vale_dez(a))


func resultado() -> int:
	if resultado_forcado >= 0:
		return resultado_forcado
	if estourou:
		if carta_do_estouro < 0:
			return modificador
		var v := 11 if Carta.eh_as(carta_do_estouro) else Carta.valor(carta_do_estouro)
		return v + modificador
	return soma_cartas() + modificador


func _estourar() -> void:
	estourou = true
	encerrado = true
	carta_do_estouro = baralho.puxar_topo()
	_finalizar()


var _finalizado := false

func _finalizar() -> void:
	if _finalizado:
		return
	_finalizado = true
	baralho.descartar(cartas)
	if carta_do_estouro >= 0:
		baralho.descartar([carta_do_estouro] as Array[int])
