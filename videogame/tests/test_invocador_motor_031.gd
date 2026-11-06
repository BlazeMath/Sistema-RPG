extends RefCounted

const Batalha := preload("res://core/batalha.gd")
const Dados := preload("res://core/dados_batalha.gd")
const Instantaneo := preload("res://core/instantaneo.gd")
const Prontos := preload("res://core/herois_prontos.gd")


func _arena(cartas := []) -> Batalha:
	var ficha := Prontos.ficha("Invocador")
	if not cartas.is_empty():
		ficha["cartas"] = cartas.map(func(s): return "classe.invocador." + s)
	var b := Batalha.new(Dados.arena([ficha], false), 11)
	b.iniciar()
	b.indice_vez = b.ordem.find("heroi")
	b._comecar_turno()
	b.ativa().pos = Vector2i(6, 5)
	var inimigo := b.unidade("goblin1")
	inimigo.pos = Vector2i(7, 5)
	inimigo.reacoes = []
	inimigo.resistencia = 0
	inimigo.vida = 100
	return b


func test_chamar_recolher_e_rechamar_conservam_vinculo_e_fadiga(t) -> void:
	var b := _arena()
	var u := b.ativa()
	var c = u.carta_com("lobo-atroz")
	var idx := u.cartas.find(c)
	var padrao := u.acoes_padrao
	t.ok(b.heroi_chamar_invocacao(idx, Vector2i(6, 4)), "chama em espaço conhecido no alcance curto")
	var lobo := b.invocacao_da_carta(u, c)
	t.igual(lobo.vida, 25, "Vida numérica do perfil")
	t.igual(c.fadiga, 3, "paga Fadiga da criação na carta")
	t.igual(u.acoes_padrao, padrao - 1, "gasta uma Padrão")
	t.ok(lobo.eh_aliado() and not lobo.eh_heroi() and not lobo.id in b.ordem, "aliado sem turno nem Vida de herói")
	t.ok(not lobo in b.inimigos_vivos() and not lobo in b.oponentes(u), "não é tratado como alvo hostil")
	t.ok(not b.heroi_chamar_invocacao(idx, Vector2i(5, 4)), "a mesma carta não cria uma cópia")
	b._aplicar_dano_inimigo(lobo, 4)
	lobo.dar_ficha("Imobilizar")
	t.ok(b.heroi_recolher_invocacao(idx), "recolhe com uma Padrão")
	t.ok(not lobo in b.unidades and b.invocacao_da_carta(u, c) == lobo, "preserva vínculo fora do mapa")
	t.igual(c.fadiga, 3, "recolher não cobra outra Fadiga nem recupera a atual")
	t.igual(lobo.vida, 21, "recolher não cura")
	u.acoes_padrao = 1
	u.baralho.descarte.assign([8, 9])
	u.baralho.exilio.clear()
	t.ok(b.heroi_chamar_invocacao(idx, Vector2i(6, 4)), "chama de novo a mesma criatura")
	t.igual(c.fadiga, 4, "Fadiga chega à capacidade")
	t.igual(u.baralho.exilio, [9, 8], "exila do descarte por Fadiga excedente")
	t.igual(lobo.fichas_total("Imobilizar"), 1, "recolher não limpa condições")


func test_ataque_usa_o_baralho_do_dono_e_dano_da_criatura(t) -> void:
	var b := _arena()
	var u := b.ativa()
	var c = u.carta_com("lobo-atroz")
	var alvo := b.unidade("goblin1")
	b.heroi_chamar_invocacao(u.cartas.find(c), Vector2i(6, 4))
	var lobo := b.invocacao_da_carta(u, c)
	u.forca = 5
	u.baralho.baralho.assign([35, 22, 9])
	b.baralho_inimigos.baralho.assign([34, 4, 3])
	t.ok(b.heroi_atacar_invocacao(lobo, alvo), "dono gasta sua Padrão para ordenar o ataque")
	t.igual(b.quem_decide(), u.id, "o dono toma decisões na mesa")
	t.ok(b.teste_ataque.baralho == u.baralho, "usa as cartas do dono")
	t.igual(u.baralho.baralho, [35], "as cartas da invocação vêm do baralho compartilhado")
	b.parar()
	b.teste_defesa.parar()
	b._resolver()
	t.igual(b.resultado["dano"], 14, "diferença 11 +3 do Lobo, sem Força do Invocador")
	t.igual(alvo.fichas_total("Sangramento"), 1, "a mordida aplica Sangramento no acerto")
	t.igual(u.acoes_padrao, 0, "não sobra uma Padrão extra da criatura")


func test_defesa_inimigo_alvo_vira_carta_e_pocao_recupera(t) -> void:
	var b := _arena()
	var u := b.ativa()
	var c = u.carta_com("lobo-atroz")
	var idx := u.cartas.find(c)
	var inimigo := b.unidade("goblin1")
	b.heroi_chamar_invocacao(idx, Vector2i(6, 4))
	var lobo := b.invocacao_da_carta(u, c)
	lobo.vida = 1
	c.dar_ficha("Preparo")
	t.ok(not b.heroi_virar(idx, "preparo") and not b.heroi_virar(idx, "acao"), "não vira normalmente")
	t.ok(lobo in b.oponentes(inimigo), "os inimigos podem mirar a criatura")
	b.indice_vez = b.ordem.find(inimigo.id)
	b._comecar_turno()
	u.baralho.baralho.assign([35, 5, 4])
	b.baralho_inimigos.baralho.assign([34, 22, 9])
	b._novo_ataque(inimigo, lobo, {})
	t.ok(b.teste_defesa.baralho == u.baralho, "a defesa usa cartas do dono")
	b.teste_ataque.parar()
	b._avancar_apos_teste(b.teste_ataque)
	t.igual(b.quem_decide(), u.id, "o controlador também decide a defesa")
	b.parar()
	t.igual(c.lado, 1, "morte vira o vínculo para recuperação")
	t.ok(not lobo in b.unidades and not c.tem_ficha("Preparo"), "retira a criatura e limpa fichas")
	t.igual(u.baralho.baralho, [35], "o dano vai para a Vida da criatura")
	b.indice_vez = b.ordem.find(u.id)
	b._comecar_turno()
	var pocoes := u.consumiveis.count("pocao_de_cura_pequena")
	t.ok(b.heroi_recuperar_invocacao(idx), "o verso pode usar a poção comum")
	t.igual(u.consumiveis.count("pocao_de_cura_pequena"), pocoes - 1, "consome a poção")
	t.ok(c.lado == 0 and lobo.vida == lobo.vida_max and not lobo in b.unidades, "recupera e volta a ficar disponível na reserva")


func test_ave_atravessa_obstaculo_sem_gastar_movimento_do_dono(t) -> void:
	var b := _arena()
	var u := b.ativa()
	var c = u.carta_com("ave-de-rapina")
	for x in b.grade.largura:
		b.grade.obstaculos[Vector2i(x, 6)] = "pedra"
	var mov := u.acoes_mov
	b.heroi_chamar_invocacao(u.cartas.find(c), Vector2i(6, 4))
	var ave := b.invocacao_da_carta(u, c)
	t.ok(not b.alcance_invocacao(ave)["mapa"].has(Vector2i(6, 6)), "voa sobre a pedra sem terminar sobre ela")
	t.ok(b.heroi_mover_invocacao(ave, Vector2i(6, 7)), "atravessa a parede usando Entrada em Movimento")
	t.igual(ave.pos, Vector2i(6, 7), "chega ao outro lado")
	t.igual(ave.deslocamento, 3, "percorreu as três casas, mesmo através de obstáculo")
	t.igual(u.acoes_mov, mov, "entrada não gasta o Movimento do Invocador")


func test_snapshot_preserva_vinculo_recolhido_e_baralho_compartilhado(t) -> void:
	var b := _arena()
	var u := b.ativa()
	var c = u.carta_com("lobo-atroz")
	var idx := u.cartas.find(c)
	b.heroi_chamar_invocacao(idx, Vector2i(6, 4))
	var lobo := b.invocacao_da_carta(u, c)
	b._aplicar_dano_inimigo(lobo, 5)
	b.heroi_recolher_invocacao(idx)
	var salvo := Instantaneo.para_texto(b)
	var novo := _arena()
	t.ok(Instantaneo.aplicar_texto(novo, salvo), "restaura o retrato da batalha")
	var dono := novo.ativa()
	var criatura := novo.invocacao_da_carta(dono, dono.carta_com("lobo-atroz"))
	t.igual(criatura.vida, 20, "persiste Vida na reserva")
	t.ok(criatura.baralho == dono.baralho and not criatura in novo.unidades, "persiste a referência do baralho e a reserva")


func test_ferimento_do_lobo_acontece_antes_do_teste_mesmo_no_erro(t) -> void:
	var b := _arena()
	var u := b.ativa()
	var alvo := b.unidade("goblin1")
	var c = u.carta_com("lobo-atroz")
	b.heroi_chamar_invocacao(u.cartas.find(c), Vector2i(6, 4))
	var lobo := b.invocacao_da_carta(u, c)
	b.perguntar_escolhas = true
	u.baralho.baralho.assign([35, 2, 1])
	u.baralho.descarte.assign([7])
	b.baralho_inimigos.baralho.assign([34, 22, 9])
	t.ok(b.heroi_atacar_invocacao(lobo, alvo), "oferece Ferimento para o ataque do Lobo")
	t.ok(b.teste_ataque == null, "a escolha acontece antes de puxar as cartas")
	t.ok(b.heroi_responder("ferimento"), "paga o efeito próprio")
	t.igual(alvo.fichas_total("Ferimento"), 1, "Ferimento já está no alvo")
	t.igual(u.baralho.exilio, [7], "o segundo ponto de Fadiga excede a capacidade")
	b.parar()
	b.teste_defesa.parar()
	b._resolver()
	t.ok(not b.resultado["acertou"], "o ataque erra")
	t.igual(alvo.fichas_total("Ferimento"), 1, "o erro não remove o Ferimento")
	t.igual(alvo.fichas_total("Sangramento"), 0, "Sangramento continua exigindo acerto")


func test_teia_substitui_o_ataque_e_nao_causa_dano(t) -> void:
	var b := _arena(["aranha-de-ambar"])
	var u := b.ativa()
	var alvo := b.unidade("goblin1")
	alvo.pos = Vector2i(9, 4)
	var c = u.carta_com("aranha-de-ambar")
	b.heroi_chamar_invocacao(u.cartas.find(c), Vector2i(6, 4))
	var aranha := b.invocacao_da_carta(u, c)
	b.perguntar_escolhas = true
	u.baralho.baralho.assign([35, 22, 9])
	b.baralho_inimigos.baralho.assign([34, 4, 3])
	t.ok(b.heroi_atacar_invocacao(aranha, alvo), "Teia pode mirar em alcance curto fora do corpo a corpo")
	t.ok(b.heroi_responder("teia"), "seleciona a Teia")
	b.parar()
	b.teste_defesa.parar()
	b._resolver()
	t.igual(c.fadiga, 3, "Teia custa uma Fadiga na criatura")
	t.igual(u.acoes_padrao, 0, "é o mesmo ataque, com uma única Padrão")
	t.ok(b.resultado["acertou"], "o ataque acertou")
	t.igual(b.resultado["dano"], 0, "Teia não causa dano")
	t.igual(alvo.fichas_total("Imobilizar"), 1, "Teia aplica Imobilizar no acerto")
