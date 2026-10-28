extends RefCounted

const Baralho := preload("res://core/baralho.gd")
const Teste21 := preload("res://core/teste21.gd")


## Monta um baralho com cartas escolhidas no topo. "postos" em ordem de compra:
## o primeiro da lista é a primeira carta puxada. Posto 1 = Ás, 13 = Rei.
func _baralho_com(postos: Array) -> Baralho:
	var b := Baralho.new()
	var topo: Array[int] = []
	for p in postos:
		# Usa naipes diferentes para não repetir a mesma carta.
		var naipe := 0
		while (naipe * 13 + p - 1) in topo:
			naipe += 1
		topo.append(naipe * 13 + p - 1)
	var resto: Array[int] = []
	for c in b.baralho:
		if not c in topo:
			resto.append(c)
	topo.reverse()
	b.baralho = resto + topo  # o topo é o fim do array
	return b


func test_duas_cartas_somadas_ao_modificador(t) -> void:
	var b := _baralho_com([7, 5])
	var teste := Teste21.new(b, 5)
	teste.parar()
	t.igual(teste.resultado(), 17, "7 + 5 + 5")


func test_exemplo_do_livro_puxar_mais_uma(t) -> void:
	# Tarso: 7 e 5, puxa um 6 -> cartas 18, teste 23.
	var b := _baralho_com([7, 5, 6])
	var teste := Teste21.new(b, 5)
	teste.puxar()
	teste.parar()
	t.igual(teste.resultado(), 23, "18 + 5")


func test_exemplo_do_livro_estouro(t) -> void:
	# 7 e 5, puxa um 10 -> 22, estoura; a última carta é um 4 -> 4 + 5 = 9.
	var b := _baralho_com([7, 5, 10, 4])
	var teste := Teste21.new(b, 5)
	teste.puxar()
	t.ok(teste.estourou, "estourou")
	t.igual(teste.resultado(), 9, "última carta + modificador")
	t.ok(not teste.puxar(), "não puxa depois de estourar")


func test_modificador_nao_estoura(t) -> void:
	var b := _baralho_com([10, 10])
	var teste := Teste21.new(b, 8)
	teste.parar()
	t.ok(not teste.estourou, "20 nas cartas não estoura")
	t.igual(teste.resultado(), 28, "20 + 8")


func test_as_vale_11_quando_nao_estoura(t) -> void:
	var b := _baralho_com([1, 6, 9])
	var teste := Teste21.new(b, 0)
	t.igual(teste.soma_cartas(), 17, "A + 6 = 17")
	teste.puxar()
	t.igual(teste.soma_cartas(), 16, "A + 6 + 9 = 16 com o Ás valendo 1")
	t.ok(not teste.estourou, "não estourou")


func test_critico_21_natural(t) -> void:
	var b := _baralho_com([1, 13])
	var teste := Teste21.new(b, 0)
	t.ok(teste.critico(), "Ás + Rei é crítico")
	var b2 := _baralho_com([7, 4, 10])
	var teste2 := Teste21.new(b2, 0)
	teste2.puxar()
	t.ok(not teste2.critico(), "21 com três cartas não é crítico")


func test_carta_aberta_e_fechada(t) -> void:
	var b := _baralho_com([9, 3])
	var teste := Teste21.new(b, 0)
	t.igual(teste.carta_aberta() % 13 + 1, 9, "aberta é a primeira")
	t.igual(teste.carta_fechada() % 13 + 1, 3, "fechada é a segunda")


func test_carta_da_mao_conta_para_estourar(t) -> void:
	var b := _baralho_com([10, 6, 8])
	b.comprar_para_mao(1)  # a mão recebe o 10 do topo
	var carta_mao := b.mao[0]
	var teste := Teste21.new(b, 0)  # puxa 6 e 8 = 14
	t.ok(teste.jogar_da_mao(carta_mao), "jogou da mão")
	t.ok(teste.estourou, "14 + 10 estoura")
	t.igual(b.mao.size(), 0, "carta saiu da mão")


func test_limite_reduzido_pela_armadura(t) -> void:
	var b := _baralho_com([10, 10])
	var teste := Teste21.new(b, 0, 19)
	t.ok(teste.estourou, "20 estoura com limite 19")


func test_desvantagem_impede_puxar(t) -> void:
	var b := _baralho_com([5, 4])
	var teste := Teste21.new(b, 0, 21, false, true)
	t.ok(not teste.puxar(), "não puxa com desvantagem")


func test_vantagem_troca_carta_com_a_mao(t) -> void:
	var b := _baralho_com([9, 4, 6])
	b.comprar_para_mao(1)  # 9 vai para a mão
	var nove := b.mao[0]
	var teste := Teste21.new(b, 0, 21, true)  # 4 e 6 = 10
	teste.parar()
	var quatro := teste.cartas[0]
	t.ok(teste.trocar_com_vantagem(quatro, nove), "trocou")
	teste.confirmar()
	t.igual(teste.resultado(), 15, "9 + 6")
	t.ok(quatro in b.mao, "carta trocada volta para a mão")


func test_cartas_usadas_vao_para_o_descarte(t) -> void:
	var b := _baralho_com([7, 5, 10, 4])
	var teste := Teste21.new(b, 0)
	teste.puxar()  # estoura
	t.igual(b.descarte.size(), 4, "três cartas + a do estouro")
	t.igual(b.baralho.size(), 48, "baralho perdeu 4")
