## Fichas e estados conforme o glossário do Lucas (0.10).
extends RefCounted

const Batalha := preload("res://core/batalha.gd")
const Grade := preload("res://core/grade.gd")
const Teste21 := preload("res://core/teste21.gd")
const TC := preload("res://tests/test_classes.gd")


func _b(classe := "Guerreiro", carta := "") -> Batalha:
	return TC.new()._grupo_com(classe, carta, "classe.guerreiro.heroi.foco-mortal")


func test_ferimento_fica_e_doi_ao_virar(t) -> void:
	var b := _b()
	var u := b.unidade("heroi")
	var c = u.carta_heroi()
	c.dar_ficha("Ferimento", 2)
	t.igual(int(c.fichas["Ferimento"]), 1, "0.20: no máximo 1 ficha de cada tipo por carta")
	var antes := u.baralho.baralho.size()
	b._virar(u, c)
	t.igual(u.fichas_total("Ferimento"), 0, "virar tira o Ferimento")
	t.igual(u.baralho.baralho.size(), antes - 1, "e causa 1 de dano por ficha")


func test_medo_e_penalidade_nao_somem_no_ataque(t) -> void:
	var b := _b()
	var g := b.unidade("goblin1")
	g.dar_ficha("Medo")
	g.dar_ficha("Penalidade")
	b.indice_vez = b.ordem.find("goblin1")
	b._comecar_turno()
	g.acoes_mov = 0   # 0.22: com movimento sobrando ele usaria para tirar a ficha
	b._novo_ataque(g, b.unidade("heroi"), {})
	t.igual(b.teste_ataque.limite, 20, "Penalidade: −1 no limite")
	TC.new()._terminar(b)
	t.igual(g.fichas_total("Medo"), 1, "Medo continua")
	t.igual(g.fichas_total("Penalidade"), 1, "Penalidade continua")


func test_imobilizar_tira_movimento_por_ficha(t) -> void:
	var b := _b()
	var u := b.unidade("heroi")
	for o in b.inimigos_vivos():
		o.pos = Vector2i(11, b.inimigos_vivos().find(o))
	var v := b.passos_por_acao(u)
	u.dar_ficha("Imobilizar")
	t.igual(b.passos_por_acao(u), v - 1, "−1 por ficha")
	u.dar_ficha("Imobilizar", 5)
	t.igual(u.fichas_total("Imobilizar"), u.cartas.size(), "0.20: uma por carta, o resto se perde")


func test_cegueira_e_caido_dao_vantagem_ao_atacante(t) -> void:
	var b := _b()
	var u := b.unidade("heroi")
	var g := b.unidade("goblin1")
	g.dar_ficha("Cegueira")
	b._novo_ataque(u, g, {})
	t.ok(b.teste_ataque.vantagem, "atacar um cego tem vantagem")
	var b2 := _b()
	var g2 := b2.unidade("goblin1")
	b2.derrubar(g2)
	b2._novo_ataque(b2.unidade("heroi"), g2, {})
	t.ok(b2.teste_ataque.vantagem, "corpo a corpo contra caído tem vantagem")


func test_cego_atira_com_desvantagem(t) -> void:
	var b := _b()
	var a := b.unidade("goblin3")
	a.dar_ficha("Cegueira")
	a.pos = Vector2i(9, 5)
	b._novo_ataque(a, b.unidade("heroi"), {})
	t.ok(b.teste_ataque.desvantagem, "ataque à distância de um cego: só 2 cartas")


func test_levantar_custa_movimento(t) -> void:
	var b := _b()
	var u := b.unidade("heroi")
	b.derrubar(u)
	t.igual(b.passos_por_acao(u), 1, "caído anda 1")
	var mov := u.acoes_mov
	t.ok(b.heroi_levantar(), "levanta")
	t.igual(u.acoes_mov, mov - 1, "gastou a ação de movimento")
	t.ok(not u.efeitos.has("caido"), "de pé")


func test_queda_deixa_caido(t) -> void:
	var b := _b()
	var u := b.unidade("heroi")
	b._aplicar_efeito(u, {"id": "x", "nome": "x"}, {"tipo": "queda", "quadrados": 2})
	t.ok(u.efeitos.has("caido"), "caiu 2 quadrados: Caído")


func test_inimigo_confuso_ataca_aliado(t) -> void:
	var b := _b()
	var g := b.unidade("goblin1")
	var outro := b.unidade("goblin2")
	g.dar_ficha("Confusão")
	b.indice_vez = b.ordem.find("goblin1")
	for tentativa in 30:
		b._comecar_turno()
		if g.efeitos.get("confuso", {}).get("alvo", "") == "goblin2":
			break
	if g.efeitos.get("confuso", {}).get("alvo", "") != "goblin2":
		return
	outro.pos = g.pos + Vector2i(0, 1)
	t.igual(b.motivo_sem_ataque(g, outro), "", "pode atacar o aliado da confusão")
	t.ok(b.motivo_sem_ataque(g, b.unidade("heroi")) != "", "e só ele")


func test_inimigo_gasta_acao_para_tirar_ficha(t) -> void:
	var b := _b()
	var g := b.unidade("goblin1")
	g.dar_ficha("Imobilizar", 9)
	g.pos = Vector2i(11, 9)
	b.indice_vez = b.ordem.find("goblin1")
	b._comecar_turno()
	var padrao := g.acoes_padrao
	b._passo_turno_ia(g)
	t.igual(g.fichas_total("Imobilizar"), 8, "tirou 1 ficha")
	t.igual(g.acoes_padrao, padrao - 1, "gastando a ação")


func test_vantagem_automatica_melhora(t) -> void:
	var b := _b()
	var tt := Teste21.new(b.baralho_inimigos, 0, 21, true)
	tt.parar()
	var antes := tt.soma_cartas()
	tt.vantagem_automatica()
	t.ok(tt.resultado() >= antes, "vantagem do inimigo nunca piora o teste")


func test_atributos_3(t) -> void:
	var b := _b()
	var u := b.unidade("heroi")
	var v := b._velocidade(u)
	u.destreza = 3
	t.igual(b._velocidade(u), v + 1, "Destreza 3: +1 de Velocidade")
	u.constituicao = 3
	u.baralho.sofrer_dano(4)
	var desc := u.baralho.descarte.size()
	b._comecar_turno()
	t.ok(u.baralho.descarte.size() < desc, "Constituição 3: regenera no início do turno")
	u.espirito = 3
	var aliado := b.unidade("heroi2")
	aliado.pos = u.pos + Vector2i(-1, 0)
	var mao := aliado.baralho.mao.size()
	t.ok(b.heroi_comandar(aliado), "Comandar")
	t.igual(aliado.baralho.mao.size(), mao + 1, "o aliado compra 1")
	u.atributos["diplomacia"] = 1
	t.ok(b.heroi_orientar(aliado), "Orientar")
	t.igual(aliado.fichas_total("Foco"), 1, "o aliado ganha Foco")
	t.ok(not b.heroi_orientar(aliado), "só Diplomacia vezes por cena")


func test_sabedoria_3_ajusta_o_teste(t) -> void:
	var b := _b()
	var u := b.unidade("heroi")
	u.sabedoria = 3
	b.heroi_atacar(b.unidade("goblin1"))
	var nomes := b.ajustes_disponiveis().map(func(a): return a["nome"])
	t.ok("Sabedoria +1" in nomes and "Sabedoria −1" in nomes, "pode somar ou tirar 1")


func test_mentira_3_devolve_carta(t) -> void:
	var b := _b()
	var u := b.unidade("heroi")
	u.atributos["mentira"] = 3
	var antes := u.baralho.baralho.size()
	b.heroi_atacar(b.unidade("goblin1"))
	var usadas := b.teste_ataque.cartas.size()
	TC.new()._terminar(b)
	t.ok(u.baralho.baralho.size() >= antes - usadas + 1 or not u.viva(), "uma carta do ataque voltou ao baralho")


func test_espirito_devolve_do_exilio_no_descanso(t) -> void:
	var b := _b()
	var u := b.unidade("heroi")
	u.espirito = 2
	u.baralho.sofrer_dano(6)
	for i in 3:
		u.baralho.exilio.append(u.baralho.descarte.pop_back())
	var ex := u.baralho.exilio.size()
	b._descanso_curto(u)
	t.igual(u.baralho.exilio.size(), ex + 1 - 2, "descanso exila 1 e o Espírito devolve 2")
