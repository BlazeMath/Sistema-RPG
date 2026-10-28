## Regras de combate da 0.10: distância, cobertura, empurrão, reações, Sombra, arremesso.
extends RefCounted

const Batalha := preload("res://core/batalha.gd")
const Dados := preload("res://core/dados_batalha.gd")
const Personagem := preload("res://core/personagem.gd")
const TC := preload("res://tests/test_classes.gd")


func _b() -> Batalha:
	return TC.new()._grupo_com("Guerreiro", "", "classe.guerreiro.heroi.foco-mortal")


func _com_arma(arma: String) -> Batalha:
	var f: Dictionary = TC.new()._ficha("Guerreiro", "Arremessador", [], ["classe.guerreiro.heroi.foco-mortal"])
	f["arma"] = arma
	f["escudo"] = "nenhum"
	var b := Batalha.new(Dados.arena([f], false), 5)
	b.iniciar()
	b.indice_vez = b.ordem.find("heroi")
	b._comecar_turno()
	return b


func test_distancia_errada_usa_menos_cartas(t) -> void:
	var b := _com_arma("arco_curto")   # ideal curto e médio
	var u := b.unidade("heroi")
	var g := b.unidade("goblin1")
	u.pos = Vector2i(0, 5)
	g.pos = Vector2i(10, 5)              # longo: 1 faixa fora
	t.igual(b.niveis_fora_da_distancia(u, g), 1, "uma faixa fora")
	b._novo_ataque(u, g, {})
	t.ok(b.teste_ataque.sem_puxar and not b.teste_ataque.pode_puxar(), "só as 2 cartas, sem puxar")
	t.igual(b.teste_ataque.cartas.size(), 2, "2 cartas")
	t.ok(b.teste_ataque.pode_jogar_da_mao(), "mas pode jogar da mão")
	var b2 := _com_arma("javelin")       # ideal longo
	var u2 := b2.unidade("heroi")
	var g2 := b2.unidade("goblin1")
	u2.pos = Vector2i(0, 0)
	g2.pos = Vector2i(3, 0)              # curto: 2 faixas fora
	b2._novo_ataque(u2, g2, {})
	t.igual(b2.teste_ataque.cartas.size(), 1, "duas faixas fora: 1 carta")


func test_cobertura_parcial(t) -> void:
	var b := _com_arma("arco_curto")
	var u := b.unidade("heroi")
	var g := b.unidade("goblin1")
	u.pos = Vector2i(0, 5)
	g.pos = Vector2i(5, 5)
	b.grade.obstaculos[Vector2i(4, 5)] = "cerca"
	t.igual(b.cobertura_de(u, g), 1, "atrás da cerca")
	b._novo_ataque(u, g, {})
	t.ok(b.teste_ataque.sem_puxar, "cobertura parcial: como uma faixa fora")


func test_empurrao_bate_e_machuca(t) -> void:
	var b := _b()
	var g := b.unidade("goblin1")
	var outro := b.unidade("goblin2")
	g.pos = Vector2i(5, 8)
	outro.pos = Vector2i(7, 8)
	var vg := g.vida
	var vo := outro.vida
	b._empurrar(g, Vector2i(4, 8), 3)
	t.igual(g.pos, Vector2i(6, 8), "andou 1")
	t.igual(g.vida, vg - 4, "faltaram 2 quadrados: 4 de dano")
	t.igual(outro.vida, vo - 4, "quem levou a batida também")


func test_reacao_do_inimigo_e_lamina_rapida(t) -> void:
	var b := _b()
	var u := b.unidade("heroi")
	var g := b.unidade("goblin1")        # Desordeiro: foge 1 ao ser atacado
	g.pos = u.pos + Vector2i(1, 0)
	g.novo_turno()
	b._novo_ataque(u, g, {})
	TC.new()._terminar(b)
	if g.viva():
		t.ok(g.pos != u.pos + Vector2i(1, 0) or g.acoes_reacao == 0, "reagiu fugindo")
	var b2 := _b()
	var u2 := b2.unidade("heroi")
	var g2 := b2.unidade("goblin1")
	g2.pos = u2.pos + Vector2i(1, 0)
	g2.novo_turno()
	u2.efeitos["sem_reacao_inimiga"] = {"nome": "Lâmina Rápida"}
	b2._novo_ataque(u2, g2, {})
	TC.new()._terminar(b2)
	t.igual(g2.acoes_reacao, 1, "Lâmina Rápida: sem reação")


func test_sombra_ao_ser_escolhido(t) -> void:
	var b := _b()
	b.perguntar_sombra = true
	var h1 := b.unidade("heroi")
	var h2 := b.unidade("heroi2")
	var g := b.unidade("goblin2")
	for o in b.inimigos_vivos():
		o.pos = Vector2i(11, b.inimigos_vivos().find(o))
	g.pos = h1.pos + Vector2i(1, 0)
	h1.dar_ficha("Sombra")
	b.indice_vez = b.ordem.find("goblin2")
	b._comecar_turno()
	b._passo_turno_ia(g)
	t.igual(b.fase, Batalha.Fase.SOMBRA_ESCOLHA, "pergunta se gasta Sombra")
	t.ok(b.heroi_sombra(true), "gasta")
	t.igual(h1.fichas_total("Sombra"), 0, "a ficha saiu")
	t.igual(g.efeitos.get("alvo_turno", {}).get("id", ""), h2.id, "o goblin escolhe outro")


func test_todos_com_sombra_e_como_nenhum(t) -> void:
	var b := _b()
	b.perguntar_sombra = true
	var h1 := b.unidade("heroi")
	var h2 := b.unidade("heroi2")
	var g := b.unidade("goblin2")
	g.pos = h1.pos + Vector2i(1, 0)
	h1.dar_ficha("Sombra")
	h2.dar_ficha("Sombra")
	b.indice_vez = b.ordem.find("goblin2")
	b._comecar_turno()
	b._passo_turno_ia(g)
	var primeiro: String = b.sombra_pendente["heroi"]
	b.heroi_sombra(true)
	b.heroi_sombra(true)
	t.igual(g.efeitos.get("alvo_turno", {}).get("id", ""), primeiro, "todos gastaram: vale a primeira escolha")


func test_javelin_fica_no_alvo(t) -> void:
	var b := _com_arma("javelin")
	var u := b.unidade("heroi")
	var g := b.unidade("goblin1")
	u.pos = Vector2i(0, 0)
	g.pos = Vector2i(10, 0)
	b.heroi_atacar(g)
	TC.new()._terminar(b)
	t.ok(u.efeitos.has("sem_arma"), "arremessou: está sem a arma")
	t.igual(b.arma_no_chao_de(u), Vector2i(10, 0), "a javelin ficou no quadrado do alvo")
	b.indice_vez = b.ordem.find("heroi")
	b._comecar_turno()
	u.pos = Vector2i(9, 1)
	g.pos = Vector2i(11, 9)
	t.ok(b.heroi_pegar_arma(), "pega de volta")
	t.igual(u.arma["nome"], "Javelin", "armado de novo")


func test_besta_precisa_recarregar(t) -> void:
	var b := _com_arma("besta_pesada")
	var u := b.unidade("heroi")
	var g := b.unidade("goblin1")
	u.pos = Vector2i(0, 0)
	g.pos = Vector2i(6, 0)
	b.heroi_atacar(g)
	TC.new()._terminar(b)
	b.indice_vez = b.ordem.find("heroi")
	b._comecar_turno()
	if g.viva():
		t.ok(b.motivo_sem_ataque(u, g).contains("recarreg"), "precisa recarregar")
		t.ok(b.heroi_recarregar(), "recarrega")
		t.igual(b.motivo_sem_ataque(u, g), "", "pode atirar de novo")


func test_varinha_eletrizante(t) -> void:
	var b := TC.new()._grupo_com("Mago", "", "")
	var u := b.unidade("heroi")
	var i := -1
	for k in u.cartas.size():
		if u.cartas[k].slug() == "varinha-eletrizante":
			i = k
	t.ok(i >= 0, "o Mago tem a carta da varinha")
	var g := b.unidade("goblin1")
	var vida := g.vida
	t.ok(b.heroi_usar_carta(i, g), "usa a varinha")
	t.igual(g.vida, vida - 3, "3 de dano, ignorando resistência")


func test_diplomacia_5_inconsciente(t) -> void:
	var b := _b()
	var u := b.unidade("heroi")
	u.atributos["diplomacia"] = 5
	u.baralho.sofrer_dano(60)
	var desc := u.baralho.descarte.size()
	b._dano_no_baralho(u, 4)
	t.igual(u.baralho.descarte.size(), desc - 2, "inconsciente com Diplomacia 5: exila só metade")


func test_empurrao_no_heroi_passa_pelo_escudo(t) -> void:
	var b := _b()
	var u := b.unidade("heroi")
	var esc := u.vida_escudo
	b._dano_de_impacto(u, 2, "teste")
	t.igual(u.vida_escudo, maxi(esc - 2, 0), "o escudo segura o impacto")


func test_migrar_pericias_cortadas(t) -> void:
	var f := Personagem.nova()
	f["pericias"]["Fortitude"] = 3
	Personagem._migrar_pericias(f)
	t.ok(not f["pericias"].has("Fortitude"), "Fortitude saiu")
	t.igual(Personagem.contagem_pericias(f)[3], 5, "o valor foi para outra perícia")


func _com_foco(classe: String, foco: String) -> Batalha:
	var f: Dictionary = TC.new()._ficha(classe, "Conjurador", [], [])
	f["foco"] = foco
	var b := Batalha.new(Dados.arena([f, TC.new()._ficha("Guerreiro", "Aliado", [], ["classe.guerreiro.heroi.foco-mortal"])], false), 4)
	b.iniciar()
	b.indice_vez = b.ordem.find("heroi")
	b._comecar_turno()
	return b


func _carta(u, slug: String) -> int:
	for k in u.cartas.size():
		if u.cartas[k].slug() == slug:
			return k
	return -1


func test_focos_do_pdf(t) -> void:
	for id in ["varinha_de_cristal", "cajado_do_aprendiz", "cajado_de_batalha", "orbe_de_concentracao", "orbe_de_protecao"]:
		var b := _com_foco("Mago", id)
		var u := b.unidade("heroi")
		for fc in preload("res://core/itens.gd").FOCOS[id]["cartas"]:
			var i := _carta(u, fc["slug"])
			t.ok(i >= 0, "%s vira carta" % fc["nome"])
			var alvos := b.alvos_de_habilidade(u, u.cartas[i])
			t.ok(b.heroi_usar_carta(i, alvos[0] if not alvos.is_empty() else null), "usa %s (%s)" % [fc["nome"], b.opcoes_cartas(u)[i]["motivo"]])
	for id in ["relicario_do_guardiao", "escrituras_de_maftone", "rosario_da_devocao"]:
		var b := _com_foco("Clérigo", id)
		var u := b.unidade("heroi")
		u.dar_ficha("Ferimento")
		b.unidade("heroi2").pos = u.pos + Vector2i(-1, 0)
		for fc in preload("res://core/itens.gd").FOCOS[id]["cartas"]:
			var i := _carta(u, fc["slug"])
			var alvos := b.alvos_de_habilidade(u, u.cartas[i])
			t.ok(b.heroi_usar_carta(i, alvos[0] if not alvos.is_empty() else null), "usa %s (%s)" % [fc["nome"], b.opcoes_cartas(u)[i]["motivo"]])


func test_auxilios_dos_focos(t) -> void:
	var b := _com_foco("Clérigo", "rosario_da_devocao")
	var u := b.unidade("heroi")
	t.igual(b._resistencia_de(u), u.resistencia_total() + 1, "Rosário: +1 de resistência")
	var b2 := _com_foco("Mago", "cajado_de_batalha")
	var m := b2.unidade("heroi")
	b2._novo_ataque(m, b2.unidade("goblin1"), {"magico": true})
	t.igual(b2.teste_ataque.limite, 22, "Cajado de Batalha: +1 no limite do ataque mágico")
	var b3 := _com_foco("Clérigo", "simbolo_sagrado")
	var c := b3.unidade("heroi")
	var simb = c.cartas[_carta(c, "simbolo-sagrado")]
	simb.fadiga = 2
	b3._comecar_turno()
	t.igual(simb.fadiga, 1, "Símbolo Sagrado: −1 de fadiga no início do turno")
