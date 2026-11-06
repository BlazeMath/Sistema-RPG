extends RefCounted

const Batalha := preload("res://core/batalha.gd")
const Catalogo := preload("res://core/catalogo.gd")
const Base := preload("res://tests/test_025.gd")
const ID := "classe.bruxo.arma-em-chamas"


func _arena() -> Batalha:
	var base := Base.new()
	var ficha := base._bruxo("fenix", [ID])
	ficha["comeca_com_foco"] = false
	var b := base._arena([ficha])
	var alvo := b.unidade("goblin1")
	alvo.vida = 100
	alvo.vida_max = 100
	return b


func _resolver_acerto(b: Batalha) -> void:
	b.teste_ataque.cartas.assign([9, 8])
	b.teste_defesa.cartas.assign([5, 6])
	b.teste_ataque.parar()
	b.teste_defesa.parar()
	b._resolver()


func test_arma_em_chamas_converte_dano_e_aplica_fogo(t) -> void:
	var b := _arena()
	var u := b.ativa()
	var alvo := b.unidade("goblin1")
	var c = u.carta_com("arma-em-chamas")
	t.igual(Catalogo.habilidade(ID)["xp"], 1, "uma carta de 1 XP")
	t.igual(c.limite(), 2, "limite de Fadiga da frente")
	t.ok(b.heroi_usar_carta(u.cartas.find(c)), "ativa a frente")
	t.igual(c.fadiga, 2, "paga 2 Fadigas")
	t.igual(u.acoes_padrao, 1, "paga uma ação")
	alvo.fraquezas["Fogo"] = 4
	t.ok(b.heroi_atacar(alvo), "ataca com a arma incendiada")
	t.igual(b.tipos_de_dano(u, b.ctx), ["Fogo"], "o ataque usa o tipo Fogo")
	_resolver_acerto(b)
	t.ok(["Arma em Chamas", 2] in b.resultado["partes"], "causa +2 no mesmo ataque")
	t.igual(alvo.fichas_total("Fogo"), 1, "o golpe aplica uma ficha de Fogo")
	t.igual(alvo.vida, 100 - int(b.resultado["dano"]), "o bônus entra no dano infligido")
	b._iniciar_cena(u)
	t.ok(not u.arma.has("arma_em_chamas"), "a nova cena apaga o encantamento")


func test_arma_em_chamas_fica_na_arma_e_exige_dano(t) -> void:
	var b := _arena()
	var u := b.ativa()
	var alvo := b.unidade("goblin1")
	var c = u.carta_com("arma-em-chamas")
	t.ok(b.heroi_usar_carta(u.cartas.find(c)), "incendeia a faca")
	t.ok(b.heroi_trocar_arma(), "guarda a faca e pega o foco")
	t.ok(u.arma_reserva.get("arma_em_chamas", false) and not u.arma.has("arma_em_chamas"), "o efeito fica na faca")
	u.acoes_padrao = 2
	t.ok(b.heroi_trocar_arma(), "volta a empunhar a faca")
	alvo.resistencia = 100
	t.ok(b.heroi_atacar(alvo), "ataca inimigo resistente")
	_resolver_acerto(b)
	t.igual(b.resultado["dano"], 0, "ataque sem dano não recebe os +2")
	t.igual(alvo.fichas_total("Fogo"), 0, "ataque sem dano não aplica Fogo")


func test_combustao_em_cadeia_verifica_depois_do_primeiro_ataque(t) -> void:
	var b := _arena()
	var u := b.ativa()
	var alvo := b.unidade("goblin1")
	var c = u.carta_com("arma-em-chamas")
	var i := u.cartas.find(c)
	t.ok(b.heroi_usar_carta(i), "incendeia a arma")
	t.ok(b.heroi_virar(i), "vira para Combustão em Cadeia")
	u.acoes_padrao = 1
	alvo.dar_ficha("Fogo", 2)
	t.igual(c.limite(), 3, "limite de Fadiga do verso")
	t.ok(b.heroi_usar_carta(i, alvo), "inicia o primeiro ataque")
	t.igual(c.fadiga, 2, "paga 2 Fadigas uma vez")
	_resolver_acerto(b)
	t.igual(alvo.fichas_total("Fogo"), 3, "o primeiro ataque completa a terceira ficha")
	t.ok(b.continuar(), "continua o ataque resolvido")
	t.igual(b.fase, Batalha.Fase.HEROI_ATACANDO, "abre o segundo ataque")
	t.igual(b.defensor, alvo, "mantém o defensor")
	t.igual(u.acoes_padrao, 0, "sem custo de ação para o segundo ataque")
	_resolver_acerto(b)
	b.continuar()
	t.igual(b.fase, Batalha.Fase.HEROI_ESCOLHE, "o segundo ataque não encadeia um terceiro")
	t.igual(c.fadiga, 2, "o segundo ataque não cobra outra Fadiga")


func test_combustao_em_cadeia_para_abaixo_do_limite_ou_sem_defensor(t) -> void:
	for letal in [false, true]:
		var b := _arena()
		var u := b.ativa()
		var alvo := b.unidade("goblin1")
		var c = u.carta_com("arma-em-chamas")
		c.virar()
		alvo.dar_ficha("Fogo", 3 if letal else 2)
		if letal:
			alvo.vida = 1
		t.ok(b.heroi_usar_carta(u.cartas.find(c), alvo), "executa o ataque")
		_resolver_acerto(b)
		b.continuar()
		t.igual(b.fase, Batalha.Fase.HEROI_ESCOLHE, "encerra sem ataque adicional")
