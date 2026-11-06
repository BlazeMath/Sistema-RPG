## Exercita as criaturas do jogador e as de Vaelor na fase real da Torre.
extends RefCounted

const Batalha := preload("res://core/batalha.gd")
const Fase := preload("res://core/fase.gd")
const Prontos := preload("res://core/herois_prontos.gd")
const Invocador := preload("res://core/cartas_invocador.gd")
const Instantaneo := preload("res://core/instantaneo.gd")

const GAEL := Vector2i(29, 21)
const LOBO := Vector2i(32, 22)
const AVE := Vector2i(30, 22)


func _torre(extra := "", cartas := []) -> Batalha:
	var f := Prontos.ficha("Invocador")
	if not cartas.is_empty():
		f["cartas"] = cartas
	if extra != "":
		f["cartas"].append("classe.invocador." + extra)
		f["xp"] = 4
	var b := Batalha.new(Fase.para_cenario(Fase.carregar("torre_vaelor"), [f]), 31)
	b.iniciar()
	b.unidade("heroi").pos = GAEL
	_vez(b, "heroi")
	return b


func _vez(b: Batalha, id: String) -> void:
	b.indice_vez = b.ordem.find(id)
	b._comecar_turno()


func _chamar(b: Batalha, slug: String, p: Vector2i):
	var u := b.ativa()
	var c = u.carta_com(slug)
	b.heroi_chamar_invocacao(u.cartas.find(c), p)
	return Invocador.vinculo(u, c)


func _topo(baralho, cartas: Array[int]) -> void:
	for carta in cartas:
		baralho.baralho.erase(carta)
		baralho.mao.erase(carta)
		baralho.descarte.erase(carta)
		baralho.baralho.append(carta)


func _acertar(b: Batalha) -> void:
	b.teste_ataque.cartas.assign([9, 22])
	b.teste_defesa.cartas.assign([1, 2])
	b.teste_ataque.parar()
	b.teste_defesa.parar()
	b._resolver()


func test_lobo_invocado_no_observatorio_ataca_vaelor_com_baralho_de_gael(t) -> void:
	var b := _torre()
	var u := b.ativa()
	var vaelor := b.unidade("vaelor")
	var c = u.carta_com("lobo-atroz")
	var i := u.cartas.find(c)
	t.igual(b.grade.nivel(vaelor.pos), 3, "usa o observatório da fase original")
	t.ok(LOBO in b.casas_chamada_invocacao(i), "casa livre e conhecida em alcance curto")
	t.ok(not b.heroi_chamar_invocacao(i, vaelor.pos), "não chama sobre Vaelor")
	t.ok(b.heroi_chamar_invocacao(i, LOBO), "chama o Lobo pela carta")
	var lobo := Invocador.vinculo(u, c)
	t.ok(lobo != null, "o vínculo está em campo")
	if lobo == null:
		return
	t.igual(lobo.vida, 25, "Vida numérica do catálogo")
	t.igual(c.fadiga, 3, "custo de criação na carta")
	t.igual(u.acoes_padrao, 1, "chamar gasta uma Padrão de Gael")
	t.ok(lobo.eh_aliado() and not lobo.id in b.ordem, "aliado sem turno próprio")
	t.igual(b.herois().size(), 1, "criatura não ocupa vaga de herói")
	t.ok(not b.heroi_chamar_invocacao(i, AVE), "a mesma carta não cria duas cópias")
	_topo(u.baralho, [9, 22])
	t.ok(b.heroi_atacar_invocacao(lobo, vaelor), "comanda o ataque contra Vaelor")
	t.igual(b.teste_ataque.baralho, u.baralho, "o ataque compra do baralho de Gael")
	t.igual(b.quem_decide(), u.id, "Gael controla o teste também em rede")
	_acertar(b)
	t.ok(["dano", 3] in b.resultado["partes"], "usa +3 do Lobo")
	t.igual(vaelor.fichas_total("Sangramento"), 1, "o golpe básico do Lobo aplica Sangramento")
	t.igual(u.acoes_padrao, 0, "o ataque gastou a segunda Padrão")


func test_recolher_e_recuperar_criatura_na_torre(t) -> void:
	var b := _torre()
	var u := b.ativa()
	var c = u.carta_com("ave-de-rapina")
	var i := u.cartas.find(c)
	var ave = _chamar(b, "ave-de-rapina", AVE)
	t.ok(ave != null, "chama Ave de Rapina no observatório")
	if ave == null:
		return
	t.igual(ave.vida_max, 14, "Vida da Ave")
	t.igual(ave.deslocamento, 6, "Adestrador concede a Velocidade da Ave na entrada")
	b._dano_direto(ave, 5, "teste de dano")
	ave.dar_ficha("Penalidade")
	t.ok(b.heroi_recolher_invocacao(i), "recolhe com uma Padrão")
	t.igual(ave.vida, 9, "recolher não cura")
	t.igual(ave.fichas_total("Penalidade"), 1, "recolher preserva fichas")
	t.ok(b.na_posicao(AVE) == null, "recolher libera o quadrado")
	_vez(b, u.id)
	t.ok(b.heroi_chamar_invocacao(i, AVE), "chama o mesmo vínculo de volta")
	t.igual(Invocador.vinculo(u, c), ave, "preserva a identidade do vínculo")
	t.igual(ave.vida, 9, "continua ferida ao retornar")
	b._dano_direto(ave, 99, "teste de queda")
	t.igual(c.lado, 1, "a derrota vira para Recuperar o Vínculo")
	t.ok(not ave.viva() and not ave in b.unidades, "a criatura sai do campo")
	t.ok(not b.heroi_virar(i), "não vira por Ação Padrão")
	c.dar_ficha("Preparo")
	t.ok(not b.heroi_virar(i, "preparo"), "Preparo não recupera a criatura")
	var potes := u.consumiveis.count("pocao_de_cura_pequena")
	t.ok(b.heroi_recuperar_invocacao(i), "Poção de Cura Pequena recupera o vínculo")
	t.igual(u.consumiveis.count("pocao_de_cura_pequena"), potes - 1, "consome exatamente uma poção comum")
	t.igual(c.lado, 0, "recuperação devolve a face A")
	t.ok(not ave in b.unidades, "recuperação não chama a criatura")
	_vez(b, u.id)
	t.ok(b.heroi_chamar_invocacao(i, AVE), "pode chamar novamente")
	t.igual(ave.vida, 14, "o vínculo recuperado retorna com Vida máxima")


func test_ordem_de_assalto_combina_movimento_e_ataque_na_torre(t) -> void:
	var b := _torre()
	var u := b.ativa()
	var lobo = _chamar(b, "lobo-atroz", Vector2i(31, 22))
	t.ok(lobo != null, "chama a criatura que receberá a ordem")
	if lobo == null:
		return
	_vez(b, u.id)
	var i := u.cartas.find(u.carta_com("adestrador-arcano"))
	t.ok(b.heroi_usar_carta(i, lobo), "Adestrador ordena a criatura")
	t.igual(u.acoes_padrao, 1, "a ordem gasta uma única Padrão")
	t.ok(b.heroi_mover_invocacao(lobo, LOBO), "Lobo avança uma casa no observatório")
	t.igual(u.acoes_mov, 1, "a ordem cobre o movimento")
	t.ok(b.heroi_atacar_invocacao(lobo, b.unidade("vaelor")), "Lobo usa o ataque concedido")
	t.igual(u.acoes_padrao, 1, "ataque da ordem não cobra outra Padrão")
	t.ok(not u.efeitos.has("ordem_invocador"), "a ordem é consumida pelo ataque")


func _invocar_vaelor(b: Batalha):
	var m := b.unidade("vaelor")
	_vez(b, m.id)
	b._ia_habilidades(m)
	return b.unidades.filter(func(o): return o.efeitos.get("invocado_por", {}).get("id") == m.id)


func test_banimento_resolve_contra_invocacao_de_vaelor_e_preserva_vida(t) -> void:
	var b := _torre("circulo-de-ancoragem")
	var u := b.ativa()
	var inimigas = _invocar_vaelor(b)
	t.igual(inimigas.size(), 1, "Vaelor chama uma criatura pela rotina real")
	if inimigas.is_empty():
		return
	var alvo = inimigas[0]
	var vida: int = alvo.vida
	var casa: Vector2i = alvo.pos
	_vez(b, u.id)
	var c = u.carta_com("circulo-de-ancoragem")
	c.virar()
	var i := u.cartas.find(c)
	t.ok(alvo in b.alvos_de_habilidade(u, c), "seleciona a invocação real")
	t.ok(not b.unidade("elem_fogo") in b.alvos_de_habilidade(u, c), "um inimigo comum do laboratório não é alvo")
	_topo(b.baralho_inimigos, [1, 2])
	_topo(u.baralho, [9, 22])
	t.ok(b.heroi_usar_carta(i, alvo), "faz o teste contestado contra Vaelor")
	t.ok(b.parar(), "conclui o teste de Espírito e Arcanismo")
	t.ok(not alvo.viva() and alvo.efeitos.has("inv_banida"), "sai do mapa temporariamente")
	t.igual(alvo.vida, vida, "o banimento mantém a Vida")
	t.igual(b.na_posicao(casa), null, "deixa a casa livre durante o banimento")
	b.continuar()
	_vez(b, u.id)
	t.ok(alvo.viva(), "retorna no próximo turno do Invocador")
	t.igual(alvo.pos, casa, "retorna ao quadrado anterior se estiver livre")
	t.igual(alvo.vida, vida, "retorna com a mesma Vida")


func test_retrato_preserva_vinculo_e_baralho_da_invocacao_na_torre(t) -> void:
	var b := _torre()
	var lobo = _chamar(b, "lobo-atroz", LOBO)
	t.ok(lobo != null, "chama Lobo antes de salvar")
	if lobo == null:
		return
	b._dano_direto(lobo, 3, "teste de retrato")
	var restaurada := _torre()
	t.ok(Instantaneo.aplicar_texto(restaurada, Instantaneo.para_texto(b)), "restaura o retrato compartilhado")
	var u := restaurada.unidade("heroi")
	var c = u.carta_com("lobo-atroz")
	var inv := Invocador.vinculo(u, c)
	t.ok(inv != null and inv in restaurada.unidades, "mapa e carta apontam para a mesma criatura")
	if inv == null:
		return
	t.igual(inv.vida, 22, "guarda a Vida da criatura")
	t.igual(inv.baralho, u.baralho, "restaura a referência compartilhada do baralho")


func test_seis_perfis_podem_ser_chamados_no_observatorio(t) -> void:
	var perfis := {
		"lobo-atroz": [25, 4, 0, 3], "guardiao-quelonio": [28, 2, 2, 2],
		"aranha-de-ambar": [16, 4, 0, 1], "salamandra-de-cinzas": [18, 3, 1, 2],
		"ave-de-rapina": [14, 6, 2, 2], "espirito-lanterneiro": [12, 4, 1, 1],
	}
	for slug in perfis:
		var b := _torre("", ["classe.invocador." + slug])
		var inv = _chamar(b, slug, LOBO)
		t.ok(inv != null, "chama " + slug)
		if inv != null:
			t.igual([inv.vida, inv.velocidade, inv.resistencia, inv.dano], perfis[slug], "perfil de " + slug)
			t.ok(inv not in b.inimigos_vivos() and inv.id not in b.ordem, "aliada sem iniciativa: " + slug)


func test_vaelor_ataca_lobo_e_dano_afeta_vida_da_criatura(t) -> void:
	var b := _torre()
	var u := b.ativa()
	var lobo = _chamar(b, "lobo-atroz", LOBO)
	t.ok(lobo != null, "chama o alvo aliado")
	if lobo == null:
		return
	_vez(b, "vaelor")
	b._novo_ataque(b.unidade("vaelor"), lobo, {})
	t.igual(b.teste_defesa.baralho, u.baralho, "a defesa também usa o baralho do dono")
	var antes := u.baralho.baralho.size()
	_acertar(b)
	t.ok(int(b.resultado["dano"]) > 0, "Vaelor causa dano")
	t.igual(lobo.vida, 25 - int(b.resultado["dano"]), "a perda é numérica na criatura")
	t.igual(u.baralho.baralho.size(), antes, "o dano não tritura cartas de Gael")


func test_banida_ocupa_vaga_e_some_quando_vaelor_cai(t) -> void:
	var b := _torre("circulo-de-ancoragem")
	var u := b.ativa()
	var m := b.unidade("vaelor")
	var inimigas = _invocar_vaelor(b)
	t.igual(inimigas.size(), 1, "Vaelor chama sua primeira criatura")
	if inimigas.is_empty():
		return
	var alvo = inimigas[0]
	_vez(b, u.id)
	var c = u.carta_com("circulo-de-ancoragem")
	c.virar()
	_topo(b.baralho_inimigos, [1, 2])
	_topo(u.baralho, [9, 22])
	t.ok(b.heroi_usar_carta(u.cartas.find(c), alvo) and b.parar(), "baniu a primeira criatura")
	t.ok(alvo.efeitos.has("inv_banida"), "alvo ainda possui o vínculo")
	m.efeitos["turnos_ia"] = {"n": 3}
	t.igual(_invocar_vaelor(b).size(), 2, "Vaelor pode chamar a segunda criatura")
	m.efeitos["turnos_ia"] = {"n": 6}
	t.igual(_invocar_vaelor(b).size(), 2, "a banida conta para o limite de duas")
	b._dano_direto(m, m.vida, "teste de derrota")
	t.igual(alvo.vida, 0, "derrota do conjurador remove o vínculo banido")
	t.ok(not alvo.efeitos.has("inv_banida"), "não há retorno agendado após a derrota")
	_vez(b, u.id)
	t.ok(not alvo.viva(), "não reaparece depois da morte de Vaelor")
