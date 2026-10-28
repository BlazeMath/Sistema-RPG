extends RefCounted

const Baralho := preload("res://core/baralho.gd")
const Carta := preload("res://core/carta.gd")


func _novo(semente := 1) -> Baralho:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	return Baralho.new(rng)


func test_baralho_tem_52_cartas_unicas(t) -> void:
	var b := _novo()
	t.igual(b.baralho.size(), 52, "tamanho")
	var unicas := {}
	for c in b.baralho:
		unicas[c] = true
	t.igual(unicas.size(), 52, "cartas únicas")


func test_mesma_semente_mesmo_embaralhamento(t) -> void:
	t.igual(_novo(7).baralho, _novo(7).baralho, "semente reproduzível")
	t.ok(_novo(7).baralho != _novo(8).baralho, "sementes diferentes embaralham diferente")


func test_valores_das_cartas(t) -> void:
	t.igual(Carta.valor(0), 1, "Ás vale 1 no cálculo base")
	t.igual(Carta.valor(9), 10, "10")
	t.igual(Carta.valor(12), 10, "Rei vale 10")
	var dez := 0
	for c in Carta.baralho_completo():
		if Carta.vale_dez(c):
			dez += 1
	t.igual(dez, 16, "16 cartas de valor 10 no baralho")


func test_inicio_de_cena_compra_2_mais_sabedoria(t) -> void:
	var b := _novo()
	b.iniciar_cena(3)
	t.igual(b.mao.size(), 5, "mão")
	t.igual(b.baralho.size(), 47, "baralho")


func test_nova_cena_embaralha_a_mao_antiga(t) -> void:
	var b := _novo()
	b.iniciar_cena(2)
	var antiga := b.mao.duplicate()
	b.iniciar_cena(1)
	t.igual(b.mao.size(), 3, "mão nova de 2 + 1")
	t.igual(b.baralho.size(), 49, "mão antiga voltou ao baralho")
	t.igual(b.total_cartas(), 52, "nenhuma carta some")
	t.ok(antiga != b.mao, "mão nova é outra")


func test_dano_move_do_topo_para_o_descarte(t) -> void:
	var b := _novo()
	var topo := b.baralho.slice(-3)
	b.sofrer_dano(3)
	t.igual(b.baralho.size(), 49, "baralho")
	t.igual(b.descarte.size(), 3, "descarte")
	for c in topo:
		t.ok(c in b.descarte, "carta do topo foi ao descarte")
	t.igual(b.total_cartas(), 52, "nenhuma carta some")


func test_baralho_vazio_deixa_inconsciente(t) -> void:
	var b := _novo()
	b.sofrer_dano(52)
	t.igual(b.estado, Baralho.Estado.INCONSCIENTE, "inconsciente")


func test_dano_em_inconsciente_vai_do_descarte_ao_exilio(t) -> void:
	var b := _novo()
	b.sofrer_dano(52)
	b.sofrer_dano(5)
	t.igual(b.descarte.size(), 47, "descarte")
	t.igual(b.exilio.size(), 5, "exílio")
	t.igual(b.estado, Baralho.Estado.INCONSCIENTE, "ainda inconsciente")


func test_perder_todo_o_descarte_mata(t) -> void:
	var b := _novo()
	b.sofrer_dano(52)
	b.sofrer_dano(52)
	t.igual(b.estado, Baralho.Estado.MORTO, "morto")
	t.igual(b.exilio.size(), 52, "tudo no exílio")


func test_cura_exila_uma_e_devolve_ao_fundo(t) -> void:
	var b := _novo()
	b.sofrer_dano(10)
	var fundo_antes := b.baralho[0]
	var devolvidas := b.curar(4)
	t.igual(devolvidas, 4, "devolvidas")
	t.igual(b.exilio.size(), 1, "exilou 1")
	t.igual(b.descarte.size(), 5, "descarte")
	t.igual(b.baralho.size(), 46, "baralho")
	t.ok(b.baralho.find(fundo_antes) == 4, "cartas entraram pelo fundo")


func test_cura_sem_descarte_nao_faz_nada(t) -> void:
	var b := _novo()
	t.igual(b.curar(5), 0, "sem descarte")
	t.igual(b.exilio.size(), 0, "nada exilado")


func test_cura_levanta_inconsciente(t) -> void:
	var b := _novo()
	b.sofrer_dano(52)
	b.curar(3)
	t.igual(b.estado, Baralho.Estado.ATIVO, "de pé de novo")
	t.igual(b.baralho.size(), 3, "3 cartas de vida")


func test_descanso_curto_exila_1_e_devolve_ate_10(t) -> void:
	var b := _novo()
	b.sofrer_dano(20)
	t.igual(b.descanso_curto(), 10, "devolveu 10")
	t.igual(b.exilio.size(), 1, "exilou 1")
	t.igual(b.descarte.size(), 9, "sobrou no descarte")
	t.igual(b.baralho.size(), 42, "baralho")


func test_descanso_curto_com_pouco_descarte(t) -> void:
	var b := _novo()
	b.sofrer_dano(4)
	t.igual(b.descanso_curto(), 3, "devolveu o que restou após exilar 1")
	t.igual(b.descarte.size(), 0, "descarte vazio")


func test_descanso_longo_recompoe_tudo(t) -> void:
	var b := _novo()
	b.iniciar_cena(2)
	b.sofrer_dano(52)
	b.sofrer_dano(10)
	b.descanso_longo()
	t.igual(b.baralho.size(), 52, "baralho completo")
	t.igual(b.mao.size() + b.descarte.size() + b.exilio.size(), 0, "zonas vazias")
	t.igual(b.estado, Baralho.Estado.ATIVO, "ativo")


func test_morto_nao_descansa(t) -> void:
	var b := _novo()
	b.sofrer_dano(104)
	b.descanso_longo()
	t.igual(b.estado, Baralho.Estado.MORTO, "continua morto")
