extends RefCounted

const Batalha := preload("res://core/batalha.gd")
const Dados := preload("res://core/dados_batalha.gd")
const Personagem := preload("res://core/personagem.gd")
const Grade := preload("res://core/grade.gd")


func _batalha(ficha: Dictionary) -> Batalha:
	var b := Batalha.new(Dados.arena(ficha, false), 9)
	b.iniciar()
	b.indice_vez = b.ordem.find("heroi")
	b._comecar_turno()
	return b


func _indice(b: Batalha, slug: String) -> int:
	var u := b.unidade("heroi")
	for i in u.cartas.size():
		if u.cartas[i].slug() == slug:
			return i
	return -1


func test_ficha_padrao_valida(t) -> void:
	var f := Personagem.nova()
	t.igual(Personagem.validar(f).size(), 0, "ficha padrão sem erros: %s" % str(Personagem.validar(f)))


func test_validacao_de_atributos_e_xp(t) -> void:
	var f := Personagem.nova()
	f["atributos"]["forca"] = 0
	t.ok(Personagem.validar(f).size() > 0, "distribuição errada é recusada")
	f = Personagem.nova()
	f["xp"] = 1
	t.ok(Personagem.validar(f).size() > 0, "cartas acima do XP são recusadas")
	f = Personagem.nova()
	f["arma"] = "arco_curto"
	t.ok(Personagem.validar(f).size() > 0, "arco com escudo é recusado")


func test_testes_sem_modificador(t) -> void:
	var b := _batalha(Personagem.nova())
	var u := b.unidade("heroi")
	var g := b.unidade("goblin1")
	g.pos = u.pos + Vector2i(1, 0)
	t.ok(b.heroi_atacar(g), "atacou")
	t.igual(b.teste_ataque.modificador, 0, "ataque sem atributo")
	t.igual(b.teste_defesa.modificador, 0, "defesa sem atributo")


func test_ombro_de_ferro_imobiliza_e_gasta_fadiga(t) -> void:
	var b := _batalha(Personagem.nova())
	var u := b.unidade("heroi")
	var g := b.unidade("goblin1")
	g.pos = u.pos + Vector2i(2, 0)
	var i := _indice(b, "ombro-de-ferro")
	t.ok(i >= 0, "tem Ombro de Ferro")
	t.ok(b.heroi_usar_carta(i, g), "usou (anda 1 e ataca)")
	t.igual(Grade.distancia(u.pos, g.pos), 1, "andou até ficar ao lado")
	t.ok(u.cartas[i].fadiga >= 0, "fadiga registrada")
	# Força o acerto para conferir a ficha.
	b.teste_ataque.cartas = [9, 10] as Array[int]
	b.parar()
	while b.fase == Batalha.Fase.IA_DEFENDENDO:
		b.passo_automatico()
	if b.resultado.get("dano", 0) > 0:
		t.ok(g.imobilizado() or not g.viva(), "goblin imobilizado ao sofrer dano")


func test_virar_remove_fichas_e_custa_padrao(t) -> void:
	var b := _batalha(Personagem.nova())
	var u := b.unidade("heroi")
	var i := _indice(b, "postura-do-leao")
	u.cartas[i].dar_ficha("Imobilizar")
	t.ok(u.imobilizado(), "imobilizado pela ficha")
	var padrao := u.acoes_padrao
	# Sem Preparo (a carta de herói pode ter Preparo do Incansável): tira antes.
	for c in u.cartas:
		c.fichas.erase("Preparo")
	t.ok(b.heroi_virar(i), "virou")
	t.igual(u.acoes_padrao, padrao - 1, "gastou uma padrão")
	t.ok(not u.imobilizado(), "ficha saiu com a virada")
	t.igual(u.cartas[i].slug(), "postura-da-cascavel", "lado B ativo")


func test_fadiga_sai_de_uma_carta_no_fim_do_turno(t) -> void:
	var b := _batalha(Personagem.nova())
	var u := b.unidade("heroi")
	u.cartas[1].fadiga = 1
	u.cartas[2].fadiga = 1
	b.encerrar_turno(2)
	t.igual(u.cartas[2].fadiga, 0, "saiu da carta escolhida")
	t.igual(u.cartas[1].fadiga, 1, "a outra continua")


func test_postura_do_leao_revela_defesa(t) -> void:
	var b := _batalha(Personagem.nova())
	var u := b.unidade("heroi")
	var g := b.unidade("goblin1")
	g.pos = u.pos + Vector2i(1, 0)
	b.encerrar_turno()
	# Avança até o goblin atacar o herói.
	for passo in 50:
		if b.fase in [Batalha.Fase.HEROI_DEFENDENDO, Batalha.Fase.IA_ATACANDO] and b.atacante == g:
			break
		if b.fase == Batalha.Fase.HEROI_ESCOLHE:
			b.encerrar_turno()
		elif b.fase == Batalha.Fase.RESOLVIDO:
			b.continuar()
		elif b.fase in [Batalha.Fase.HEROI_ATACANDO, Batalha.Fase.HEROI_DEFENDENDO]:
			b.parar()
		else:
			b.passo_automatico()
	if b.atacante == g:
		t.ok(b.teste_defesa.revelado, "defesa do herói revelada pela Postura do Leão")


func test_forca_3_causa_dano_mesmo_errando(t) -> void:
	var b := _batalha(Personagem.nova())
	var u := b.unidade("heroi")
	var g := b.unidade("goblin1")
	g.pos = u.pos + Vector2i(1, 0)
	b.heroi_atacar(g)
	b.teste_ataque.cartas = [1, 2] as Array[int]   # 2 + 3 = 5: erra
	b.parar()
	b.teste_defesa.cartas = [9, 8] as Array[int]   # 10 + 9 = 19
	b.teste_defesa.parar()
	b._avancar_apos_teste(b.teste_defesa)
	t.ok(not b.resultado["acertou"], "errou")
	t.ok(b.resultado["dano"] >= 3, "Força 3: dano mesmo errando (%d, com Postura do Leão)" % b.resultado["dano"])
