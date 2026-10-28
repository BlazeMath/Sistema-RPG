## 0.6: distribuição do dano, interações no mapa, inventário e inimigos desatentos.
extends RefCounted

const Grade := preload("res://core/grade.gd")

const Batalha := preload("res://core/batalha.gd")
const Dados := preload("res://core/dados_batalha.gd")
const Exploracao := preload("res://core/dados_exploracao.gd")
const Personagem := preload("res://core/personagem.gd")
const Itens := preload("res://core/itens.gd")


func _arena(semente := 9) -> Batalha:
	var b := Batalha.new(Dados.arena(Personagem.nova(), false), semente)
	b.iniciar()
	b.indice_vez = b.ordem.find("heroi")
	b._comecar_turno()
	return b


func _trilha(pos := Vector2i(3, 5), semente := 5) -> Batalha:
	var b := Batalha.new(Exploracao.trilha(Personagem.nova()), semente)
	b.iniciar()
	b.indice_vez = b.ordem.find("heroi")
	b._comecar_turno()
	b.unidade("heroi").pos = pos
	return b


# --- Distribuição do dano ----------------------------------------------------

func test_distribuicao_escolhida_pelo_jogador(t) -> void:
	var b := _arena()
	b.distribuicao_automatica = false
	var u := b.unidade("heroi")
	var cartas := u.baralho.baralho.size()
	var escudo := u.vida_escudo
	var armadura := u.vida_armadura
	b._dano_no_heroi(u, 5, "teste", Batalha.Fase.HEROI_ESCOLHE)
	t.igual(b.fase, Batalha.Fase.DISTRIBUINDO_DANO, "espera a escolha do jogador")
	t.igual(b.limites_distribuicao()["escudo"], mini(escudo, 5), "escudo aceita até a vida que tem")
	t.ok(not b.heroi_distribuir_dano(escudo + 1, 0), "não passa da vida do escudo")
	t.ok(not b.heroi_distribuir_dano(3, 3), "não distribui mais que o dano")
	t.ok(b.heroi_distribuir_dano(3, 1), "3 no escudo, 1 na armadura, 1 no baralho")
	t.igual(u.vida_escudo, escudo - 3, "escudo")
	t.igual(u.vida_armadura, armadura - 1, "armadura")
	t.igual(u.baralho.baralho.size(), cartas - 1, "baralho")
	t.igual(b.fase, Batalha.Fase.HEROI_ESCOLHE, "volta para a fase de antes")


func test_tudo_no_baralho_e_permitido(t) -> void:
	var b := _arena()
	b.distribuicao_automatica = false
	var u := b.unidade("heroi")
	var cartas := u.baralho.baralho.size()
	b._dano_no_heroi(u, 4, "teste", Batalha.Fase.HEROI_ESCOLHE)
	t.ok(b.heroi_distribuir_dano(0, 0), "o jogador pode poupar escudo e armadura")
	t.igual(u.baralho.baralho.size(), cartas - 4, "4 cartas trituradas")


func test_cota_de_malha_aceita_o_dano_todo_uma_vez(t) -> void:
	# Lucas (0.20): a armadura recebe no máximo a vida que tem; a Cota só volta para 1 na 1ª vez.
	var b := _arena()
	b.distribuicao_automatica = false
	var u := b.unidade("heroi")
	u.vida_armadura = 2
	var cartas := u.baralho.baralho.size()
	b._dano_no_heroi(u, 6, "teste", Batalha.Fase.HEROI_ESCOLHE)
	t.igual(b.limites_distribuicao()["armadura"], 2, "só cabe a vida da armadura")
	t.ok(b.heroi_distribuir_dano(0, 2), "2 na armadura")
	t.igual(u.vida_armadura, 1, "fica com 1 em vez de quebrar")
	t.igual(u.baralho.baralho.size(), cartas - 4, "o resto vai para o baralho")
	b._dano_no_heroi(u, 6, "teste", Batalha.Fase.HEROI_ESCOLHE)
	t.igual(b.limites_distribuicao()["armadura"], 1, "na segunda vez, só a vida que sobrou")


func test_bloqueio_corta_antes_da_escolha(t) -> void:
	var b := _arena()
	b.distribuicao_automatica = false
	var u := b.unidade("heroi")
	u.cartas[0].dar_ficha("Bloqueio")
	b._dano_no_heroi(u, 7, "teste", Batalha.Fase.HEROI_ESCOLHE)
	t.igual(b.dano_pendente["dano"], 4, "7 pela metade, arredondado para cima")


func test_automatico_usa_a_sugestao(t) -> void:
	var b := _arena()
	var u := b.unidade("heroi")
	var escudo := u.vida_escudo
	b._dano_no_heroi(u, 3, "teste", Batalha.Fase.HEROI_ESCOLHE)
	t.igual(b.fase, Batalha.Fase.HEROI_ESCOLHE, "sem esperar")
	t.igual(u.vida_escudo, escudo - 3, "escudo primeiro")


func test_sem_armadura_vai_direto_ao_baralho(t) -> void:
	var b := _arena()
	b.distribuicao_automatica = false
	var u := b.unidade("heroi")
	u.vida_escudo = 0
	u.vida_armadura = 0
	var cartas := u.baralho.baralho.size()
	b._dano_no_heroi(u, 3, "teste", Batalha.Fase.HEROI_ESCOLHE)
	t.igual(b.fase, Batalha.Fase.HEROI_ESCOLHE, "nada a escolher")
	t.igual(u.baralho.baralho.size(), cartas - 3, "baralho")


func test_ataque_inimigo_espera_a_distribuicao(t) -> void:
	var achou := false
	for semente in 60:
		var b := _arena(semente)
		b.distribuicao_automatica = false
		b.defesa_automatica = true
		var h := b.unidade("heroi")
		var g := b.unidade("goblin2")
		g.pos = h.pos + Vector2i(1, 0)
		b.indice_vez = b.ordem.find("goblin2")
		b._comecar_turno()
		for passo in 40:
			if not b.fase_automatica():
				break
			b.passo_automatico()
		if b.fase == Batalha.Fase.DISTRIBUINDO_DANO:
			achou = true
			var s := b.sugestao_distribuicao()
			t.ok(b.heroi_distribuir_dano(s["escudo"], s["armadura"]), "distribui")
			t.igual(b.fase, Batalha.Fase.RESOLVIDO, "depois mostra o resultado")
			t.ok(b.resultado.has("distribuicao"), "o resultado guarda a distribuição")
			break
	t.ok(achou, "algum ataque acertou e pediu a distribuição")


# --- Interações ---------------------------------------------------------------

func test_heroi_tem_kit_inicial(t) -> void:
	var b := _trilha()
	var u := b.unidade("heroi")
	for item in Itens.KIT_INICIAL:
		t.ok(item in u.equipamentos, "kit: " + item)
	t.ok("bandoleira_de_armas" in u.equipamentos, "item de classe do Guerreiro")


func test_faixas_do_nado(t) -> void:
	var b := _trilha()
	var op := b.opcao_da_interacao(b.interacao("riacho"), "nadar")
	t.igual(b._faixa(op, 2), "arrastado", "2 a 8")
	t.igual(b._faixa(op, 10), "volta", "9 e 10")
	t.igual(b._faixa(op, 11), "atravessa", "11 a 15")
	t.igual(b._faixa(op, 22), "folego", "16 ou mais")
	t.igual(b.descricao_das_faixas(op), "2–8 a correnteza te arrasta · 9–10 não vence a correnteza · 11–15 atravessa · 16+ atravessa e ainda anda", "texto das faixas")


func test_travessia_e_alcance(t) -> void:
	var b := _trilha(Vector2i(3, 5))
	var u := b.unidade("heroi")
	var rio := b.interacao("riacho")
	t.igual(b.destino_travessia(u, rio), Vector2i(6, 5), "do outro lado do rio")
	u.pos = Vector2i(2, 5)
	t.ok(b.motivo_sem_opcao(u, rio, rio["opcoes"][0]) != "", "longe da margem não atravessa")
	u.pos = Vector2i(6, 5)
	t.igual(b.destino_travessia(u, rio), Vector2i(3, 5), "volta para a margem de cá")


func test_teste_de_nado_com_penalidade_de_armadura(t) -> void:
	var b := _trilha()
	var u := b.unidade("heroi")
	t.ok(b.heroi_interagir("riacho", "nadar"), "começa o teste")
	t.igual(b.fase, Batalha.Fase.INTERACAO_TESTE, "mesa de 21")
	t.igual(b.teste_pericia.limite, 19, "Cota de Malha (média): limite 19")
	t.igual(b.teste_pericia.modificador, u.forca + int(u.pericias["Natação"]), "Força + Natação entram como modificador")
	t.igual(u.acoes_padrao, 1, "gastou 1 ação Padrão")
	if b.fase == Batalha.Fase.INTERACAO_TESTE:
		b.parar()
	t.igual(b.fase, Batalha.Fase.INTERACAO_RESOLVIDA, "mostra o que aconteceu")
	t.ok(b.resultado_interacao["texto"] != "", "texto do resultado")
	var valor: int = b.resultado_interacao["valor"]
	b.continuar()
	if valor >= 11:
		t.igual(u.pos, Vector2i(6, 5), "atravessou")
	else:
		t.igual(u.pos, Vector2i(3, 5), "ficou na margem")
	t.ok(b.fase in [Batalha.Fase.HEROI_ESCOLHE, Batalha.Fase.DERROTA], "segue o turno")


func test_vantagem_com_a_corda(t) -> void:
	var b := _trilha(Vector2i(8, 2))
	var u := b.unidade("heroi")
	u.baralho.comprar_para_mao(1)
	t.ok(b.heroi_interagir("paredao", "escalar"), "escala")
	t.ok(b.teste_pericia.vantagem, "Corda dá vantagem")
	b.parar()
	if not b.teste_pericia.estourou:
		t.ok(b.vantagem_pendente(), "espera a troca ou a confirmação")
		t.ok(b.heroi_vantagem_confirmar(), "confirma sem trocar")
	t.igual(b.fase, Batalha.Fase.INTERACAO_RESOLVIDA, "resolvido")


func test_melhor_troca_de_vantagem(t) -> void:
	var b := _trilha(Vector2i(8, 2))
	var u := b.unidade("heroi")
	b.heroi_interagir("paredao", "escalar")
	var tp := b.teste_pericia
	tp.cartas = [0, 1] as Array[int]    # Ás e 2 de alguma naipe: valores baixos
	tp.encerrado = true
	tp.limite = 21
	u.baralho.mao.append(12)            # um Rei
	var usada := b.melhor_troca_vantagem(12)
	t.igual(usada, 1, "troca o 2 pelo Rei (Ás + Rei = 21)")


func test_bau_com_gazua_sem_teste(t) -> void:
	var b := _trilha(Vector2i(6, 1))
	var u := b.unidade("heroi")
	var bau := b.interacao("bau")
	u.consumiveis.erase("gazua")
	t.ok(b.motivo_sem_opcao(u, bau, b.opcao_da_interacao(bau, "gazua")) != "", "sem gazua não dá")
	u.consumiveis.append("gazua")
	var pocoes := u.quantidade("pocao_de_cura_pequena")
	t.ok(b.heroi_interagir("bau", "gazua"), "abre")
	t.igual(b.fase, Batalha.Fase.INTERACAO_RESOLVIDA, "sem teste: resultado direto")
	t.igual(u.quantidade("pocao_de_cura_pequena"), pocoes + 2, "duas poções")
	t.ok("antidoto" in u.consumiveis, "antídoto")
	t.ok(not bau["ativa"], "o baú some do mapa de interações")
	t.igual(u.quantidade("gazua"), 1, "gastou a gazua e achou outra")


func test_forcar_bau_falho_alerta_os_goblins(t) -> void:
	var b := _trilha(Vector2i(6, 1))
	b.interacao_atual = {"id": "bau", "opcao": "forcar", "dano": 0, "vitoria": ""}
	b._resolver_interacao(5)
	for o in b.inimigos_vivos():
		t.ok(o.alerta, o.nome + " ficou alerta")


func test_ponte_consertada_com_corda(t) -> void:
	var b := _trilha(Vector2i(3, 8))
	t.ok(b.heroi_interagir("ponte", "consertar"), "conserta")
	t.ok(b.grade.bloqueado(Vector2i(4, 8)), "leva 2 turnos: ainda não")
	t.igual(b.unidade("heroi").acoes_padrao, 0, "gastou o turno")
	b.acoes_longas_automaticas = false
	b._comecar_turno()
	t.igual(b.fase, Batalha.Fase.ACAO_LONGA, "no turno seguinte pergunta se continua")
	t.ok(b.heroi_acao_longa(true), "continua")
	t.ok(not b.grade.bloqueado(Vector2i(4, 8)), "dá para andar na ponte")
	t.igual(b.decoracao.get(Vector2i(5, 8), ""), "ponte", "chão de ponte")
	t.igual(b.unidade("heroi").acoes_padrao, 0, "gastou o turno")


func test_queda_pede_distribuicao_depois_do_dialogo(t) -> void:
	var b := _trilha(Vector2i(8, 2))
	b.distribuicao_automatica = false
	b.interacao_atual = {"id": "fenda", "opcao": "escalar", "dano": 0, "vitoria": ""}
	b._resolver_interacao(4)
	t.igual(b.fase, Batalha.Fase.INTERACAO_RESOLVIDA, "primeiro o texto")
	t.igual(b.queda_pendente(), 0, "2 quadrados: sem teste de amortecer")
	b.continuar()
	t.igual(b.fase, Batalha.Fase.DISTRIBUINDO_DANO, "depois a distribuição")
	t.igual(b.dano_pendente["dano"], 3, "queda de 2 quadrados: 3")
	var s := b.sugestao_distribuicao()
	b.heroi_distribuir_dano(s["escudo"], s["armadura"])
	t.igual(b.fase, Batalha.Fase.HEROI_ESCOLHE, "volta ao turno")


func test_fenda_aparece_ao_procurar(t) -> void:
	var b := _trilha(Vector2i(8, 2))
	t.ok(not b.interacao("fenda")["ativa"], "escondida no começo")
	b.interacao_atual = {"id": "paredao", "opcao": "procurar", "dano": 0, "vitoria": ""}
	b._resolver_interacao(22)
	t.ok(b.interacao("fenda")["ativa"], "achou a fenda")
	t.igual(b.opcoes_visiveis(b.interacao("paredao")).size(), 1, "a opção de procurar some")


func test_descanso_curto_na_fogueira(t) -> void:
	var b := _trilha(Vector2i(7, 3))
	var u := b.unidade("heroi")
	u.baralho.sofrer_dano(8)
	var antes := u.baralho.baralho.size()
	u.consumiveis.append("racao_de_viagem")
	u.cartas[0].fadiga = 2
	for o in b.inimigos_vivos():   # 0.19: descanso só sem inimigos por perto
		if b.inimigo_perto(o.pos, 0) and Grade.distancia(o.pos, b.interacoes.filter(func(i): return i.get("descanso", false))[0]["pos"]) <= b.RAIO_DESCANSO_SEGURO:
			o.pos = Vector2i(-50, -50)
	t.ok(b.heroi_interagir("fogueira", "descansar"), "descansa")
	t.igual(u.baralho.baralho.size(), antes + 7, "exila 1 e devolve as outras 7")
	t.ok(not "racao_de_viagem" in u.consumiveis, "comeu a ração")
	t.igual(u.cartas[0].fadiga, 0, "ração tira fadiga")
	t.igual(u.acoes_padrao, 0, "gastou o turno inteiro")


func test_inimigos_desatentos_nao_atacam(t) -> void:
	var b := _trilha(Vector2i(3, 5))
	var vigia := b.unidade("vigia")
	b.indice_vez = b.ordem.find("vigia")
	b._comecar_turno()
	b.passo_automatico()
	t.ok(not vigia.alerta, "não viu ninguém")
	t.igual(vigia.pos, Vector2i(12, 6), "ficou parado")
	b.unidade("heroi").pos = Vector2i(10, 6)
	b.indice_vez = b.ordem.find("vigia")
	b._comecar_turno()
	b.passo_automatico()
	t.ok(vigia.alerta, "viu o herói a 2 quadrados")
	t.ok(b.unidade("atirador").alerta, "e alertou os outros")


func test_ataque_surpresa(t) -> void:
	var b := _trilha(Vector2i(12, 3))
	var dorminhoco := b.unidade("dorminhoco")
	t.ok(b.heroi_atacar(dorminhoco), "ataca")
	t.ok(b.teste_defesa.desvantagem, "pego de surpresa: só 2 cartas")
	t.ok(dorminhoco.alerta, "agora acordou")


func test_carroca_da_vitoria(t) -> void:
	var b := _trilha(Vector2i(11, 1))
	t.ok(b.heroi_interagir("carroca", "levar"), "leva a carroça")
	b.continuar()
	t.igual(b.fase, Batalha.Fase.VITORIA, "missão cumprida")
	t.ok(b.mensagem_fim != "", "mensagem")


func test_carroca_exige_inimigos_desatentos(t) -> void:
	var b := _trilha(Vector2i(11, 1))
	b._alertar_inimigos()
	var it := b.interacao("carroca")
	t.igual(b.motivo_sem_opcao(b.unidade("heroi"), it, it["opcoes"][0]), "há inimigos em alerta", "precisa lidar com eles antes")


func test_derrotar_todos_nao_encerra_a_exploracao(t) -> void:
	var b := _trilha()
	for o in b.inimigos_vivos():
		o.vida = 0
	t.ok(not b._verificar_fim(), "ainda falta a carroça")


func test_antidoto(t) -> void:
	var b := _trilha()
	var u := b.unidade("heroi")
	u.consumiveis.append("antidoto")
	u.cartas[1].dar_ficha("Veneno")
	u.cartas[1].fadiga = 1
	t.ok(b.heroi_usar_item("antidoto"), "usa")
	t.ok(not u.cartas[1].tem_ficha("Veneno"), "sem veneno")
	t.igual(u.cartas[1].fadiga, 0, "−1 de fadiga")


# --- 0.7: queda e perícias ------------------------------------------------------

func test_dano_de_queda(t) -> void:
	t.igual(Batalha.dano_de_queda(1), 0, "1 quadrado: nada")
	t.igual(Batalha.dano_de_queda(2), 3, "2 quadrados: 3")
	t.igual(Batalha.dano_de_queda(3), 6, "3 quadrados: 6")
	t.igual(Batalha.dano_de_queda(5), 12, "5 quadrados: 12")


func test_queda_de_1_quadrado_nao_machuca(t) -> void:
	var b := _trilha(Vector2i(3, 8))
	b.interacao_atual = {"id": "ponte", "opcao": "equilibrar", "dano": 0, "vitoria": ""}
	b._resolver_interacao(3)
	t.igual(b.interacao_atual["dano"], 0, "sem dano")
	b.continuar()
	t.igual(b.fase, Batalha.Fase.HEROI_ESCOLHE, "sem distribuição")


func test_queda_alta_aceitando_o_dano(t) -> void:
	var b := _trilha(Vector2i(8, 2))
	b.distribuicao_automatica = false
	b.interacao_atual = {"id": "paredao", "opcao": "escalar", "dano": 0, "vitoria": ""}
	b._resolver_interacao(4)
	t.igual(b.queda_pendente(), 3, "3 quadrados: oferece amortecer")
	t.ok(b.heroi_amortecer_queda(false), "aceita")
	t.igual(b.fase, Batalha.Fase.DISTRIBUINDO_DANO, "distribui")
	t.igual(b.dano_pendente["dano"], 6, "3 × (3 − 1)")


func test_amortecer_a_queda(t) -> void:
	var b := _trilha(Vector2i(8, 2))
	var u := b.unidade("heroi")
	b.interacao_atual = {"id": "paredao", "opcao": "escalar", "dano": 0, "vitoria": ""}
	b._resolver_interacao(4)
	t.ok(b.heroi_amortecer_queda(true), "testa")
	t.igual(b.fase, Batalha.Fase.INTERACAO_TESTE, "mesa de 21")
	t.igual(b.teste_pericia.modificador, u.destreza + int(u.pericias.get("Acrobacia", 0)), "Destreza + Acrobacia")
	var op := b.opcao_atual()
	t.igual(op["dificuldade"], 18, "15 + 3")
	t.igual(b._faixa(op, 17), "falha", "17 não chega a 18")
	t.igual(b._faixa(op, 18), "amortece", "18 atinge a dificuldade")
	b.parar()
	t.igual(b.fase, Batalha.Fase.INTERACAO_RESOLVIDA, "resultado")
	var esperado := 3 if b.resultado_interacao["valor"] >= 18 else 6
	t.igual(b.interacao_atual["dano"], esperado, "metade se passou (arredonda para cima)")


func test_pericia_soma_no_teste(t) -> void:
	var b := _trilha()
	var u := b.unidade("heroi")
	var op := b.opcao_da_interacao(b.interacao("riacho"), "nadar")
	t.igual(b.modificador_do_teste(u, op), u.forca + 2, "Força 3 + Natação 2")
	t.ok(b.descricao_do_teste(u, op).begins_with("Força 3 + Natação 2 = +5"), "texto do teste")


func test_validacao_de_pericias(t) -> void:
	var f := Personagem.nova()
	t.ok(Personagem.validar(f).is_empty(), "ficha padrão válida")
	f["pericias"].erase("Luta")
	t.ok(not Personagem.validar(f).is_empty(), "faltando uma com 3")
	f["pericias"]["Arte"] = 3
	t.ok(Personagem.validar(f).is_empty(), "trocou Luta por Arte")
	f["pericias"]["Política"] = 2
	t.ok(not Personagem.validar(f).is_empty(), "sete com 2 não vale")


func test_iniciativa_vem_da_pericia(t) -> void:
	var cfg := Personagem.para_unidade(Personagem.nova(), "heroi", Vector2i.ZERO)
	t.igual(cfg["iniciativa"], 1, "perícia Iniciativa 1")


# --- 0.8: abordagens e componentes -------------------------------------------------

func test_abordagens_dos_rastros(t) -> void:
	var b := _trilha(Vector2i(7, 6))
	var u := b.unidade("heroi")
	var op := b.opcao_da_interacao(b.interacao("rastros"), "examinar")
	var sob := b.opcao_com_abordagem(op, "sobrevivencia")
	var per := b.opcao_com_abordagem(op, "percepcao")
	var inv := b.opcao_com_abordagem(op, "investigacao")
	t.igual(b.modificador_do_teste(u, sob), 3, "só a perícia Sobrevivência")
	t.igual(b.modificador_do_teste(u, per), u.percepcao, "só o atributo Percepção")
	t.igual(b.modificador_do_teste(u, inv), u.raciocinio, "Investigação 0 + Raciocínio")
	t.igual(b._faixa(sob, 17), "sucesso", "atingir a dificuldade basta (fácil com 1 componente: 17)")
	t.igual(b._faixa(sob, 16), "falha", "abaixo falha")
	t.ok(b.heroi_interagir("rastros", "examinar", "percepcao"), "tenta com Percepção")
	t.igual(b.opcao_atual()["dificuldade"], 21, "difícil com 1 componente: 18 + 3")
	b.parar()
	t.igual(b.fase, Batalha.Fase.INTERACAO_RESOLVIDA, "resolvido")
	t.ok(b.resultado_interacao["titulo"].contains("Percepção"), "título com a abordagem")
	b.continuar()
	t.igual(b.opcoes_visiveis(b.interacao("rastros")).size(), 0, "uma tentativa por rastro")


func test_nadar_exige_natacao(t) -> void:
	var b := _trilha()
	var u := b.unidade("heroi")
	var rio := b.interacao("riacho")
	u.pericias.erase("Natação")
	t.igual(b.motivo_sem_opcao(u, rio, rio["opcoes"][0]), "precisa de Natação 1", "sem Natação afunda")


# --- 0.9: escala de dificuldade, fichas persistentes, focos -----------------------

func test_escala_de_dificuldade(t) -> void:
	t.igual(Batalha.dificuldade_do_nivel("muito_facil", 0), 12, "a seco, muito fácil")
	t.igual(Batalha.dificuldade_do_nivel("muito_dificil", 0), 20, "a seco, muito difícil")
	t.igual(Batalha.dificuldade_do_nivel("muito_facil", 1), 15, "1 componente, muito fácil")
	t.igual(Batalha.dificuldade_do_nivel("medio", 1), 19, "1 componente, médio")
	t.igual(Batalha.dificuldade_do_nivel("muito_facil", 2), 18, "atributo + perícia, muito fácil")
	t.igual(Batalha.dificuldade_do_nivel("muito_dificil", 2), 26, "atributo + perícia, muito difícil")


func test_veneno_e_sangramento_nao_somem(t) -> void:
	var b := _trilha()
	var g := b.unidade("vigia")
	g.dar_ficha("Veneno", 2)
	g.dar_ficha("Sangramento", 1)
	var vida := g.vida
	for i in 3:
		b.indice_vez = b.ordem.find("vigia")
		b._comecar_turno()
		b._proximo_turno()
	t.igual(g.fichas_total("Veneno"), 2, "Veneno continua")
	t.igual(g.fichas_total("Sangramento"), 1, "Sangramento continua")
	t.igual(g.vida, vida - 9, "3 turnos × (2 de Veneno + 1 de Sangramento)")


func test_fogo_se_espalha_e_sai_ao_virar(t) -> void:
	var b := _trilha()
	var u := b.unidade("heroi")
	var k := 0
	for i in u.cartas.size():
		if u.cartas[i].tipo == "habilidade" and u.cartas[i].lados.size() > 1:
			k = i
	u.cartas[k].dar_ficha("Fogo")
	b.unidade("vigia").pos = u.pos + Vector2i(1, 0)
	b.indice_vez = b.ordem.find("heroi")
	b._comecar_turno()
	t.igual(u.fichas_total("Fogo"), 2, "passou para outra carta")
	t.igual(b.unidade("vigia").fichas_total("Fogo"), 1, "pegou no goblin ao lado")
	var c = u.cartas[k]
	b.heroi_virar(k)
	t.ok(not c.tem_ficha("Fogo"), "virar a carta apaga o fogo dela")


func test_agua_apaga_o_fogo(t) -> void:
	var b := _trilha(Vector2i(3, 5))
	var u := b.unidade("heroi")
	u.dar_ficha("Fogo")
	b.interacao_atual = {"id": "riacho", "opcao": "nadar", "dano": 0, "vitoria": ""}
	b._resolver_interacao(12)
	t.igual(u.fichas_total("Fogo"), 0, "nadar apaga o fogo")


func test_tratar_sangramento(t) -> void:
	var b := _trilha()
	var u := b.unidade("heroi")
	u.cartas[0].fichas["Sangramento"] = 5   # (direto: o herói de teste tem poucas cartas)
	t.ok(b.heroi_tratar(u), "começa o teste de Medicina")
	b.teste_pericia.parar()
	b.teste_pericia.confirmar()
	b._resolver_interacao(20)
	t.igual(u.fichas_total("Sangramento"), 4, "19-20: tira 1")
	b.continuar()
	b.unidade("heroi").acoes_padrao = 2
	b.heroi_tratar(u)
	b.teste_pericia.parar()
	b.teste_pericia.confirmar()
	b._resolver_interacao(21)
	t.igual(u.fichas_total("Sangramento"), 2, "21-22: tira 2")
	b.continuar()
	b.heroi_tratar(u)
	b.teste_pericia.parar()
	b.teste_pericia.confirmar()
	b._resolver_interacao(23)
	t.igual(u.fichas_total("Sangramento"), 0, "23 ou mais: tira todas")


func test_kit_medico(t) -> void:
	var b := _trilha()
	var u := b.unidade("heroi")
	u.dar_ficha("Sangramento", 2)
	u.baralho.sofrer_dano(5)
	var vida := u.baralho.baralho.size()
	u.consumiveis.append("kit_medico")
	t.ok(b.heroi_usar_item("kit_medico"), "usa o kit")
	t.igual(u.fichas_total("Sangramento"), 0, "estancou")
	t.igual(u.baralho.baralho.size(), vida + 2, "cura 2 (duas cartas voltam ao baralho)")
