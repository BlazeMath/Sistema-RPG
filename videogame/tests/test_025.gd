## 0.25: os 170 equipamentos, inventário por espaços, economia em moedas, efeitos dos itens,
## revisão das cartas de habilidade e a classe Bruxo.
extends RefCounted

const Batalha := preload("res://core/batalha.gd")
const Dados := preload("res://core/dados_batalha.gd")
const Personagem := preload("res://core/personagem.gd")
const Catalogo := preload("res://core/catalogo.gd")
const Itens := preload("res://core/itens.gd")
const ItensB := preload("res://core/itens_batalha.gd")
const Bruxo := preload("res://core/cartas_bruxo.gd")
const Campanha := preload("res://core/campanha.gd")
const Prontos := preload("res://core/herois_prontos.gd")
const Grade := preload("res://core/grade.gd")
const Teste21 := preload("res://core/teste21.gd")
const TC := preload("res://tests/test_classes.gd")


func _arena(fichas: Array) -> Batalha:
	var b := Batalha.new(Dados.arena(fichas, false), 11)
	b.iniciar()
	var u := b.unidade("heroi")
	u.pos = Vector2i(6, 5)
	if b.unidade("heroi2") != null:
		b.unidade("heroi2").pos = Vector2i(5, 5)
	b.unidade("goblin1").pos = Vector2i(7, 5)
	b.unidade("goblin2").pos = Vector2i(8, 7)
	b.unidade("goblin3").pos = Vector2i(9, 3)
	b.indice_vez = b.ordem.find("heroi")
	b._comecar_turno()
	return b


func _bruxo(patrono: String, cartas := []) -> Dictionary:
	var f := Prontos.ficha("Bruxo")
	f["nome"] = "Bruxo de Teste"
	f["herois"] = [Catalogo.pactos()[patrono]["heroi"], "raca.humano.heroi.incansavel"]
	if not cartas.is_empty():
		f["cartas"] = cartas
	return f


func _aliado() -> Dictionary:
	var f := Prontos.ficha("Guerreiro")
	f["nome"] = "Aliado"
	return f


# --- Catálogo -----------------------------------------------------------------------

func test_catalogo_dos_170(t) -> void:
	t.igual(Itens.CATALOGO.size(), 170, "170 itens no catálogo")
	t.igual(int(Itens.ARMAS["faca"]["dano"]), 3, "faca: 2 do PDF + 1 do ajuste de armas leves (0.13)")
	t.igual(int(Itens.ARMAS["espada_longa"]["dano"]), 4, "espada longa 4")
	t.igual(Itens.preco("espada_longa"), 300, "espada longa custa 30 pratas (300 cobres)")
	t.igual(int(Itens.ARMADURAS["arnes_de_placas"]["vida"]), 16, "arnês 16 de vida")
	t.igual(int(Itens.ESCUDOS["escudo_pesado"]["ocupa"]), 2, "escudo pesado ocupa 2")
	t.igual(int(Itens.CONSUMIVEIS["tocha"]["pacote"]), 3, "tochas: 3 por espaço")
	t.ok(Itens.eh_amuleto("amuleto_de_kanil"), "amuleto")
	t.igual(Itens.GRIMORIOS["grimorio_do_fogo"]["magias"].size(), 3, "Grimório do Fogo: 3 magias")
	t.igual(int(Itens.GRIMORIOS["grimorio_do_fogo"]["magias"][1]["fadiga"]), 5, "Bola de Fogo: 5 de fadiga")
	t.igual(Itens.ARMAS["arco_longo"]["ideais"].size(), 2, "arco longo: médio e longo")
	t.ok(Itens.ARMAS["besta_pesada"].get("ignora_resistencia", false), "besta ignora resistência")
	t.igual(Itens.nome("arco_de_guerra"), "Arco Longo", "id antigo do arco de guerra")


# --- Inventário ----------------------------------------------------------------------

func test_inventario_exemplos_do_documento(t) -> void:
	var f := Personagem.nova()
	f["arma"] = "maca"
	f["arma2"] = "faca"
	f["escudo"] = "escudo_pesado"
	f["atributos"]["forca"] = 3
	t.igual(int(Personagem.ocupacao(f)["armamentos"]), 4, "maça + faca + escudo pesado = 4")
	t.ok(Personagem.erros_de_inventario(f).is_empty(), "cabe")
	f["arma"] = "montante"
	f["arma2"] = "besta_pesada"
	f["escudo"] = "nenhum"
	t.igual(int(Personagem.ocupacao(f)["armamentos"]), 4, "montante + besta = 4")
	f["grimorios"] = ["grimorio_do_fogo"]
	t.ok(not Personagem.erros_de_inventario(f).is_empty(), "com um livro a mais, excede")
	f["grimorios"] = []
	f["consumiveis"] = ["pocao_de_cura_pequena", "pocao_de_cura_pequena", "pocao_de_cura_pequena", "pocao_de_cura_pequena",
		"pocao_de_mana_pequena", "pocao_de_mana_pequena", "pocao_de_mana_pequena", "tocha", "tocha", "tocha"]
	var o := Personagem.ocupacao(f)
	t.igual(int(o["consumiveis"]), 7, "4 curas + 3 manas = 7 cargas")
	t.ok(Personagem.erros_de_inventario(f).any(func(e): return e.contains("Consumíveis")), "excede as 6 cargas")
	f["consumiveis"] = ["tocha", "tocha", "tocha"]
	t.igual(int(Personagem.ocupacao(f)["mochila"]), 5 + 1, "mochila inicial (5) + 1 pacote de 3 tochas")
	f["acessorios"] = ["amuleto_de_kanil", "amuleto_de_kagen"]
	t.ok(Personagem.erros_de_inventario(f).any(func(e): return e.contains("Amuletos")), "dois amuletos: excede")
	f["acessorios"] = ["amuleto_de_kanil", "anel_do_iniciado"]
	t.ok(not Personagem.erros_de_inventario(f).any(func(e): return e.contains("Amuletos") or e.contains("Acessórios")), "amuleto + anel: cabe")
	f["armadura"] = "manto_do_vento"
	f["costas"] = "manto_camuflado"
	t.ok(Personagem.erros_de_inventario(f).any(func(e): return e.contains("Costas")), "Manto do Vento ocupa Armadura e Costas")


func test_prontos_validos_com_inventario(t) -> void:
	for f in Prontos.todas():
		t.igual(Personagem.validar(f), [] as Array[String], "%s válido" % f["nome"])
	var lis := Prontos.ficha("Ladino")
	t.ok("ferramentas_de_ladrao" in lis["mochila"], "Ladino: ferramentas de ladrão na mochila")
	var bruna := Prontos.ficha("Guerreiro")
	t.ok("bandoleira_de_armas" in bruna["acessorios"], "Guerreiro: bandoleira nos acessórios")


func test_migracao_de_heroi_antigo(t) -> void:
	var f := Personagem.nova()
	f.erase("mochila")
	f.erase("acessorios")
	f["arma2"] = "arco_de_guerra"
	f["classe"] = "Caçador"
	Personagem.migrar_inventario(f)
	t.igual(f["arma2"], "arco_longo", "arco de guerra vira arco longo")
	t.ok("corda_de_arco_da_penumbra" in f["acessorios"], "item de classe no espaço de acessório")
	t.igual(f["mochila"], Itens.MOCHILA_INICIAL, "mochila inicial")


# --- Economia ------------------------------------------------------------------------------

func test_moedas(t) -> void:
	t.igual(Campanha.moeda(1234), "1 PO 23 PP 4 PC", "1.234 cobres")
	t.igual(Campanha.moeda(50), "5 PP", "50 cobres = 5 pratas")
	t.igual(Campanha.moeda(0), "0 PC", "zero")
	Campanha.dados = {"ouro": 60, "feridas": {}, "concluidas": []}
	t.igual(Campanha.dinheiro(), 600, "campanha antiga: 60 'ouro' (escala da prata) = 600 cobres")
	t.igual(Campanha.preco_venda("espada_longa"), 120, "revenda da cidade: 40%")
	t.igual(Campanha.preco_venda("gema_do_pantano"), 300, "gema do pântano: 30 pratas")
	t.igual(Campanha.motivo_sem_venda("arnes_de_placas"), "só por encomenda", "arnês: encomenda")
	t.ok(Campanha.motivo_sem_venda("peitoral_de_dalpnor").contains("relíquia"), "relíquias não se compram")


func test_comprar_vender_e_encomendar(t) -> void:
	var f := Prontos.ficha("Guerreiro")
	f["nome"] = "Comprador 025"
	var todos := Personagem.carregar_todos().filter(func(x): return x["nome"] != f["nome"])
	todos.append(f)
	Personagem.salvar_todos(todos)
	Campanha.dados = Campanha._novos_dados()
	Campanha.dados["cobre"] = 10000
	t.igual(Campanha.comprar_item(f["nome"], "pocao_de_cura_pequena"), "", "compra uma poção")
	t.igual(Campanha.dinheiro(), 10000 - 120, "12 pratas")
	t.ok(Campanha.comprar_item(f["nome"], "arnes_de_placas").contains("encomenda"), "arnês só por encomenda")
	t.igual(Campanha.comprar_item(f["nome"], "arnes_de_placas", true), "Dinheiro insuficiente.", "encomenda cara demais")
	t.igual(Campanha.comprar_item(f["nome"], "espada_do_mestre_ferreiro"), "", "compra uma arma de especialista")
	var salvo: Dictionary = Personagem.carregar_todos().filter(func(x): return x["nome"] == f["nome"])[0]
	t.igual(salvo["arma2"], "espada_do_mestre_ferreiro", "vai para a segunda arma (a maça antiga é vendida)")
	var antes := Campanha.dinheiro()
	t.ok(Campanha.vender(f["nome"], "espada_do_mestre_ferreiro"), "vende")
	t.igual(Campanha.dinheiro(), antes + int(2200 * 0.35), "especialista: 35%")
	for k in 4:
		Campanha.comprar_item(f["nome"], "pocao_de_cura_pequena")
	t.ok(Campanha.comprar_item(f["nome"], "pocao_de_cura_pequena").contains("Inventário cheio"), "7ª carga não cabe")
	Personagem.salvar_todos(Personagem.carregar_todos().filter(func(x): return x["nome"] != f["nome"]))


func test_contrato_pago_em_pratas(t) -> void:
	var b := _arena([_aliado()])
	b.ouro_ganho = 0
	Campanha.dados = Campanha._novos_dados()
	var antes := Campanha.dinheiro()
	Campanha.registrar_fim(b, "fazenda", true)
	t.igual(Campanha.dinheiro(), antes + 100 * 10, "fazenda: 100 pratas")
	b._aplicar_efeito(b.unidade("heroi"), {"id": "x", "nome": "x"}, {"tipo": "ouro", "valor": 5})
	t.igual(b.ouro_ganho, 50, "5 pratas achadas = 50 cobres")


# --- Efeitos dos equipamentos ---------------------------------------------------------------

func _com_arma(id: String) -> Batalha:
	var f := _aliado()
	f["arma"] = id
	f["arma2"] = "nenhuma"
	f["escudo"] = "nenhum"
	f["atributos"] = {"forca": 3, "constituicao": 3, "destreza": 2, "sabedoria": 2, "percepcao": 1, "raciocinio": 1, "espirito": 1, "mentira": 0, "diplomacia": 0}
	return _arena([f])


func test_armas_ao_acertar(t) -> void:
	var b := _com_arma("maca_estrela")
	var u := b.unidade("heroi")
	var g := b.unidade("goblin1")
	ItensB.depois_do_ataque(b, u, g, true, 4)
	t.igual(g.fichas_total("Ferimento"), 1, "Maça-Estrela: Ferimento")
	b = _com_arma("alabarda")
	u = b.unidade("heroi")
	g = b.unidade("goblin1")
	var antes := g.pos
	ItensB.depois_do_ataque(b, u, g, true, 4)
	t.ok(g.pos != antes, "Alabarda: empurra")
	b = _com_arma("quebra_elmos")
	t.igual(ItensB.ignora_resistencia(b, b.unidade("heroi"), b.unidade("goblin1")), "Quebra-Elmos", "Quebra-Elmos ignora resistência")
	b = _com_arma("adaga_da_mao_vazia")
	u = b.unidade("heroi")
	u.baralho.mao.clear()
	var bonus := ItensB.bonus_de_dano(b, u, b.unidade("goblin1"), true)
	t.ok(bonus.any(func(x): return x[1] == 5), "Adaga da Mão Vazia: +5 com a mão vazia")


func test_troca_de_arma_grande_custa_duas_acoes(t) -> void:
	var b := _com_arma("montante")
	var u := b.unidade("heroi")
	u.arma_reserva = Itens.ARMAS["faca"].duplicate(true)
	u.vestidos.erase("bandoleira_de_armas")
	u.equipamentos.erase("bandoleira_de_armas")
	t.ok(not b.troca_com_movimento(u), "com arma grande, não é Movimento")
	t.igual(b.custo_troca(u), 2, "2 ações Padrão")


func test_consumiveis_novos(t) -> void:
	var b := _arena([_aliado(), _aliado()])
	var u := b.unidade("heroi")
	var h2 := b.unidade("heroi2")
	u.consumiveis.append("pocao_de_pele_de_pedra")
	t.ok(b.heroi_usar_item("pocao_de_pele_de_pedra"), "bebe a pele de pedra")
	t.ok(u.fichas_total("Guarda") >= 2, "fichas de Guarda")
	u.acoes_padrao = 2
	h2.baralho.sofrer_dano(5)
	var vida := h2.baralho.baralho.size()
	u.consumiveis.append("pocao_de_cura_pequena")
	t.ok(b.heroi_usar_item("pocao_de_cura_pequena", h2.id), "dá a poção ao aliado ao lado")
	t.ok(h2.baralho.baralho.size() > vida, "o aliado cura")
	u.acoes_padrao = 2
	u.consumiveis.append("runa_de_terra")
	t.ok(b.heroi_usar_item("runa_de_terra"), "runa de terra com goblin ao lado")
	t.igual(b.unidade("goblin1").fichas_total("Imobilizar"), 1, "goblin preso")


func test_amuleto_e_grimorio_viram_cartas(t) -> void:
	var f := TC.new()._ficha("Mago", "Maga", ["classe.mago.aprendiz-de-fogo"], ["classe.mago.heroi.controlador-do-arcano", "raca.humano.heroi.incansavel"])
	f["acessorios"] = ["amuleto_de_kagen"]
	f["grimorios"] = ["grimorio_do_fogo"]
	t.igual(Personagem.motivo_grimorio(f, "grimorio_do_fogo"), "", "Aprendiz de Fogo dá a tag Fogo")
	t.ok(Personagem.motivo_grimorio(f, "grimorio_da_agua") != "", "sem Água, não prepara o da Água")
	var b := _arena([f])
	var u := b.unidade("heroi")
	var livro = null
	var amuleto = null
	for c in u.cartas:
		if c.id == "item.livro.grimorio_do_fogo":
			livro = c
		if c.slug() == "amuleto-de-kagen":
			amuleto = c
	t.ok(livro != null, "o grimório vira carta com as magias")
	t.ok(amuleto != null, "o amuleto vira carta")
	var i := u.cartas.find(amuleto)
	t.ok(b.heroi_usar_carta(i), "usa o Amuleto de Kagen")
	t.ok(u.efeitos.has("kagen"), "ataques ignoram armadura até o fim do turno")
	var ops := b.opcoes_cartas(u).filter(func(o): return o["carta"] == livro)
	t.ok(not ops.is_empty(), "o livro aparece nas cartas")
	u.acoes_padrao = 2
	var k := u.cartas.find(livro)
	t.ok(b.heroi_usar_area(k, b.unidade("goblin1").pos, 0, "bola-de-fogo"), "conjura a Bola de Fogo")


# --- Revisão das cartas (27/10) -----------------------------------------------------------

func test_revisao_ombro_de_aco_so_adjacente(t) -> void:
	var b := TC.new()._grupo_com("Guerreiro", "classe.guerreiro.postura-da-tartaruga", "classe.guerreiro.heroi.foco-mortal")
	var u := b.unidade("heroi")
	var h2 := b.unidade("heroi2")
	u.cartas.filter(func(c): return c.slug() == "postura-da-tartaruga")[0].virar()
	var base := b._limite_defesa(h2)
	h2.pos = Vector2i(1, 9)
	t.igual(b._limite_defesa(h2), base - 1, "longe do Ombro de Aço: sem o +1")


func test_revisao_conjuracao_perfeita_custa_1(t) -> void:
	var f := TC.new()._ficha("Mago", "Testador", ["classe.mago.conjuracao-perfeita", "classe.mago.aprendiz-de-fogo"], ["classe.mago.heroi.controlador-do-arcano", "raca.humano.heroi.incansavel"])
	var b := _arena([f])
	var u := b.unidade("heroi")
	var ap = u.carta_com("aprendiz-de-fogo")
	ap.virar()   # Labareda Voraz: 2 de fadiga
	t.igual(ap.slug(), "labareda-voraz", "lado B")
	t.igual(b._custo_fadiga(u, ap), 1, "Conjuração Perfeita: a magia custa só 1")


func test_revisao_preparar_o_tiro_trava_o_movimento(t) -> void:
	var b := TC.new()._grupo_com("Caçador", "classe.cacador.preparar-o-tiro", "")
	var u := b.unidade("heroi")
	var i := u.cartas.find(u.carta_com("preparar-o-tiro"))
	t.ok(b.heroi_usar_carta(i), "prepara o tiro")
	t.ok(not b.pode_ganhar_deslocamento(u), "depois não anda")


# --- Bruxo ---------------------------------------------------------------------------------

func test_bruxo_ficha(t) -> void:
	t.igual(Catalogo.pactos().size(), 10, "10 pactos")
	t.igual(Catalogo.herois_de("Bruxo").size(), 10, "10 patronos")
	t.igual(Catalogo.habilidades_de("Bruxo").size(), 18, "18 cartas gerais")
	var f := Prontos.ficha("Bruxo")
	t.igual(Personagem.validar(f), [] as Array[String], "Vesna (Fênix) válida")
	t.igual(Catalogo.pacto_da_ficha(f), "fenix", "pacto da Fênix")
	t.ok("Fogo" in Personagem.tags_da_ficha(f), "a Fênix dá a tag Fogo (grimório do Fogo)")
	f["herois"] = [Catalogo.pactos()["fenix"]["heroi"], Catalogo.pactos()["abismo"]["heroi"]]
	t.ok(Personagem.validar(f).any(func(e): return e.contains("patrono")), "dois patronos: inválido")


func test_bruxo_reserva_e_ave_fenix(t) -> void:
	var b := _arena([_bruxo("fenix"), _aliado()])
	var u := b.unidade("heroi")
	t.igual(Bruxo.pactos(u), 2, "nível 1: 2 Pactos no começo da cena")
	var ini = Bruxo.carta_inicial(u)
	t.ok(ini != null and ini.nome() == "Ave Fênix", "habilidade inicial de graça")
	var i := u.cartas.find(ini)
	t.ok(b.heroi_usar_carta(i, b.unidade("goblin1"), "x1"), "Ave Fênix gastando 1 Pacto")
	t.igual(Bruxo.pactos(u), 1, "sobrou 1")
	t.igual(b.ctx.get("ave_fenix", -1), 1, "o ataque leva o X")


func test_fenix_dobra_o_fogo(t) -> void:
	var b := _arena([_bruxo("fenix"), _aliado()])
	t.igual(Bruxo.dano_do_fogo(b, 3), 6, "com a Fênix em campo, cada ficha de Fogo causa 2")


func test_abismo_cobranca_exila_a_carta_final(t) -> void:
	var b := _arena([_bruxo("abismo"), _aliado()])
	var u := b.unidade("heroi")
	var teste := Teste21.new(u.baralho)
	teste.estourou = true
	var rei := 12   # K de espadas: forte, sem intervenção
	u.baralho.baralho.erase(rei)
	u.baralho.descarte.append(rei)
	teste.carta_do_estouro = rei
	Bruxo.no_estouro(b, u, teste, false)
	t.ok(rei in u.baralho.exilio, "a carta final do estouro vai para o exílio")


func test_ultima_porta_reduz_o_dano_no_protegido(t) -> void:
	var b := _arena([_bruxo("ultima-porta"), _aliado()])
	var u := b.unidade("heroi")
	t.igual(u.protegido, "heroi2", "jura proteger o aliado")
	t.igual(Bruxo.reduzir_dano(b, b.unidade("heroi2"), 6), 0, "2 Pactos: −6")
	t.igual(Bruxo.pactos(u), 0, "gastou os 2")


func test_atormentado_vira_fadiga_no_inimigo(t) -> void:
	var b := _arena([_bruxo("mesa-vazia"), _aliado()])
	var g := b.unidade("goblin1")
	g.dar_ficha("Atormentado")
	Bruxo.inicio_turno_inimigo(b, g)
	t.igual(g.fichas_total("Fadiga"), 1, "+1 Fadiga por Atormentado")


func test_cartas_gerais_do_bruxo(t) -> void:
	var b := _arena([_bruxo("fenix", ["classe.bruxo.oferenda-selada", "classe.bruxo.concentrar-a-manifestacao"]), _aliado()])
	var u := b.unidade("heroi")
	u.baralho.sofrer_dano(4)
	var c = u.carta_com("oferenda-selada")
	t.ok(b.heroi_usar_carta(u.cartas.find(c)), "Oferenda Selada")
	t.igual(Bruxo.pactos(u), 4, "+2 Pactos")
	t.ok(not b.heroi_usar_carta(u.cartas.find(c)), "uma vez por cena")
	var c2 = u.carta_com("concentrar-a-manifestacao")
	t.ok(b.heroi_usar_carta(u.cartas.find(c2)), "Concentrar a Manifestação")
	t.ok(u.efeitos.has("concentrar"), "a próxima magia do pacto se concentra")


func test_bruxo_suspende_e_repara(t) -> void:
	var b := _arena([_bruxo("abismo"), _aliado()])
	var u := b.unidade("heroi")
	Bruxo.suspender(b, u, "teste")
	t.ok(not Bruxo.pode_gastar(u, 1), "suspenso: não gasta")
	var cp = Bruxo.carta_pacto(u)
	var i := u.cartas.find(cp)
	t.ok(b.heroi_usar_carta(i, null, "reparar"), "repara (exila 2 do topo)")
	t.ok(not Bruxo.suspenso(u), "pacto de volta")


# --- Varredura: usa cada lado do Bruxo e cada carta de item (pega erros de execução) -------------

func _preparar_alvos(b: Batalha, u) -> void:
	var g := b.unidade("goblin1")
	g.dar_ficha("Atormentado")
	g.efeitos["atormentado_de"] = {"id": u.id}
	g.dar_ficha("Fadiga", 3)
	g.dar_ficha("Imobilizar")
	g.efeitos["grilhao_de"] = {"id": u.id}
	g.dar_ficha("Marcado")
	g.efeitos["atacou_heroi2"] = {"ate": "inicio_turno"}
	g.dar_ficha("Fogo")
	var cp = Bruxo.carta_pacto(u)
	if cp != null:
		cp.fichas["Pacto"] = 8
	var cm = Bruxo.carta_menor(u)
	if cm != null:
		cm.fichas["Pacto"] = 4
	u.baralho.sofrer_dano(6)
	u.baralho.exilio.append(u.baralho.puxar_topo())


func _usar(t, b: Batalha, u, i: int, rotulo: String) -> bool:
	var c = u.cartas[i]
	var ok := false
	var spec := b.spec_area(c)
	if not spec.is_empty():
		ok = b.heroi_usar_area(i, TC.celula_de_area(b, u, spec))
	else:
		var alvos := b.alvos_de_habilidade(u, c)
		ok = b.heroi_usar_carta(i, alvos[0] if not alvos.is_empty() else null)
	if ok and b.fase == Batalha.Fase.PERGUNTA:
		b.heroi_responder(b.pergunta["opcoes"][0][0])
	t.ok(ok, "%s (%s)" % [rotulo, b.opcoes_cartas(u)[i]["motivo"] if i < u.cartas.size() else ""])
	TC.new()._terminar(b)
	return ok


func test_varredura_das_habilidades_iniciais(t) -> void:
	for pid in Catalogo.pactos():
		var ini: Dictionary = Catalogo.habilidade(Catalogo.pactos()[pid]["inicial"])
		for lado in 2:
			var slug := Catalogo.slug(ini["lados"][lado]["nome"])
			var reg: Dictionary = Bruxo.LADOS.get(slug, {})
			if reg.get("uso", "") != "ativada":
				continue
			var opcoes: Array = reg.get("opcoes", [{"id": ""}]).filter(func(o): return int(o.get("exilar", 0)) <= 3).map(func(o): return o["id"])
			for op in opcoes:
				var b := _arena([_bruxo(pid), _aliado()])
				var u := b.unidade("heroi")
				_preparar_alvos(b, u)
				var c = Bruxo.carta_inicial(u)
				c.lado = lado
				c.opcao = op
				_usar(t, b, u, u.cartas.find(c), "%s: %s %s" % [pid, ini["lados"][lado]["nome"], op])


func test_varredura_das_cartas_gerais_do_bruxo(t) -> void:
	for carta in Catalogo.habilidades_de("Bruxo"):
		for lado in 2:
			var l = carta["lados"][lado]
			if l == null:
				continue
			var slug := Catalogo.slug(l["nome"])
			var reg: Dictionary = Bruxo.LADOS.get(slug, {})
			if reg.get("uso", "") != "ativada" or slug in ["intercessao-do-patrono"]:
				continue
			var f := _bruxo("caminhos-roubados" if slug == "pacto-menor" else "fenix", [carta["id"]] if not carta["meia_carta"] else [])
			if carta["meia_carta"]:
				f["meias"] = [carta["id"], "classe.bruxo.ouvir-o-chamado" if carta["id"] != "classe.bruxo.ouvir-o-chamado" else "classe.bruxo.favor-de-ultima-hora"]
			f["escolhas"] = {"pacto-menor": ["caminhos-roubados" if slug == "pacto-menor" else "abismo"]}
			var b := _arena([f, _aliado()])
			var u := b.unidade("heroi")
			_preparar_alvos(b, u)
			var ini = Bruxo.carta_inicial(u)
			ini.fadiga = 1
			ini.fichas["Atormentado"] = 1
			var alvo_c = null
			for c in u.cartas:
				if c.lados.size() > lado and c.lados[lado] != null and str(c.lados[lado].get("slug", "")) == slug:
					alvo_c = c
					c.lado = lado
			if alvo_c == null:
				for c in u.cartas:
					if c.lados.any(func(x): return x != null and str(x.get("slug", "")) == slug):
						alvo_c = c
						c.lado = c.lados.find(c.lados.filter(func(x): return x != null and str(x.get("slug", "")) == slug)[0])
			t.ok(alvo_c != null, "carta %s em jogo" % slug)
			if alvo_c != null:
				_usar(t, b, u, u.cartas.find(alvo_c), "Bruxo: %s" % l["nome"])


func test_varredura_das_cartas_de_item(t) -> void:
	for id in ItensB.CARTAS:
		var f := _aliado()
		var d := Itens.item(id)
		if Itens.ARMAS.has(id):
			f["arma"] = id
			f["arma2"] = "nenhuma"
			f["escudo"] = "nenhum"
		elif d.get("espaco", "") == "pes":
			f["pes"] = id
		else:
			f["acessorios"] = [id]
		f["atributos"]["forca"] = 3
		var b := _arena([f, _aliado()])
		var u := b.unidade("heroi")
		u.dar_ficha("Sombra")
		u.baralho.sofrer_dano(3)
		u.cartas[0].fadiga = 1
		b.unidade("goblin1").dar_ficha("Fogo")
		var c = u.carta_com(ItensB.CARTAS[id])
		t.ok(c != null, "carta do item %s" % id)
		if c != null:
			_usar(t, b, u, u.cartas.find(c), "item %s" % id)


func test_varredura_dos_livros(t) -> void:
	for gid in Itens.GRIMORIOS:
		var g: Dictionary = Itens.GRIMORIOS[gid]
		var classe := "Clérigo" if g.get("sagrado", false) else "Mago"
		var cartas := []
		if not g.get("sagrado", false):
			cartas = ["classe.mago.aprendiz-de-" + {"Fogo": "fogo", "Água": "agua", "Terra": "terra", "Ar": "ar", "Luz": "luz", "Sombra": "sombra"}[str(g["requisito"]).split(" ")[0]]]
		var f := TC.new()._ficha(classe, "Leitor", cartas, [])
		f["herois"] = [Catalogo.herois_de(classe)[0]["id"], "raca.humano.heroi.incansavel"]
		f["grimorios"] = [gid]
		for m in Bruxo.LADOS.keys().slice(0, 0):
			pass
		for m in g["magias"]:
			var s := Catalogo.slug(m["nome"])
			if ItensB.MAGIAS.get(s, {}).get("fora", false):
				continue
			var b := _arena([f, _aliado()])
			var u := b.unidade("heroi")
			u.baralho.sofrer_dano(4)
			var g1 := b.unidade("goblin1")
			g1.dar_ficha("Fogo")
			g1.efeitos["feriu_heroi"] = {"ate": "inicio_turno"}
			b.unidade("heroi2").dar_ficha("Veneno")
			b.unidade("heroi2").pos = u.pos + Vector2i(0, 1)
			for c in u.cartas:
				c.fadiga = 0
			var livro = null
			for c in u.cartas:
				if c.id == "item.livro." + gid:
					livro = c
			livro.opcao = s
			_usar(t, b, u, u.cartas.find(livro), "%s: %s" % [g["nome"], m["nome"]])
