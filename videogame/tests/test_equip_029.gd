extends RefCounted

const Batalha := preload("res://core/batalha.gd")
const Baralho := preload("res://core/baralho.gd")
const Teste21 := preload("res://core/teste21.gd")
const Prontos := preload("res://core/herois_prontos.gd")
const Base := preload("res://tests/test_025.gd")

const ORIGEM := Vector2i(8, 5)
const DESTINO := Vector2i(9, 5)


func _arena(arma: String, metade := "a-muralha") -> Batalha:
	var f := Prontos.ficha("Guerreiro")
	f["herois"][0] = "classe.guerreiro.heroi." + metade
	f["arma"] = arma
	f["arma2"] = "nenhuma"
	f["escudo"] = "nenhum"
	f["atributos"]["forca"] = 3
	var b := Base.new()._arena([f])
	var alvo := b.unidade("goblin1")
	alvo.pos = ORIGEM
	alvo.vida = 100
	alvo.vida_max = 100
	alvo.reacoes = []  # isola o deslocamento em teste da fuga que o goblin faz ao ser atacado
	return b


func _preparar_movimento(b: Batalha) -> void:
	b.perguntar_escolhas = true
	b.indice_vez = b.ordem.find("goblin1")
	b._comecar_turno()
	b.ativa().deslocamento = 2


func test_frenesi_compra_ate_21_com_ases_de_11(t) -> void:
	var b := Baralho.new()
	b.baralho.assign([35, 13, 0])
	b.mao.assign([11])
	var teste := Teste21.new(b, 0, 19, true, false, 1, true, true)
	t.igual(teste.resultado(), 22, "dois Ases valem 22")
	t.igual(teste.cartas, [0, 13], "para na primeira soma de pelo menos 21")
	t.igual(teste.limite, 21, "a compra obrigatória usa o limiar da arma")
	teste.ajustar_limite(-3)
	t.ok(teste.encerrado and not teste.estourou, "encerra sem estouro")
	t.ok(not teste.jogar_da_mao(11) and not teste.trocar_com_vantagem(0, 11), "nenhuma carta da mão entra")
	t.igual(b.descarte, [0, 13], "descarta somente as cartas compradas")
	b.baralho.assign([2, 4])
	var ultimo := Teste21.new(b, 0, 21, false, false, 2, false, true)
	t.igual(ultimo.resultado(), 8, "baralho esgotado encerra com o total disponível")
	t.ok(ultimo.encerrado and not ultimo.estourou, "esgotar o baralho não produz estouro")


func test_frenesi_paga_fadiga_e_exila_o_excesso(t) -> void:
	var b := _arena("montante_do_frenesi")
	var u := b.ativa()
	var alvo := b.unidade("goblin1")
	var arma = u.carta_com("arma")
	u.baralho.baralho.assign([35, 6, 5, 0])
	u.baralho.descarte.clear()
	u.baralho.exilio.clear()
	b.baralho_inimigos.baralho.assign([34, 4, 3])
	t.ok(b.heroi_atacar(alvo), "ataca a duas casas de distância")
	t.igual(b.fase, Batalha.Fase.IA_DEFENDENDO, "vai direto para a defesa do inimigo")
	t.igual(b.teste_ataque.resultado(), 24, "comprou Ás, 6 e 7")
	t.igual(arma.fadiga, 0, "a fadiga só é aplicada depois do ataque")
	b.teste_defesa.parar()
	b._resolver()
	t.igual(b.resultado["ataque"], 24, "resolve usando o valor acima de 21")
	t.igual(arma.fadiga, 2, "enche o limite da própria arma")
	t.igual(u.baralho.exilio, [6], "exila do descarte uma carta pelo excedente")
	t.igual(u.baralho.baralho, [35], "mantém as demais cartas do baralho")


func test_corrente_acerta_antes_do_primeiro_passo_sem_causar_dano(t) -> void:
	var b := _arena("corrente_de_caca")
	var u := b.ativa()
	var alvo := b.unidade("goblin1")
	var reacoes := u.acoes_reacao
	_preparar_movimento(b)
	u.baralho.baralho.assign([35, 22, 9])
	b.baralho_inimigos.baralho.assign([34, 4, 3])
	t.ok(b._mover(alvo, DESTINO), "o inimigo inicia o movimento")
	t.igual(b.pergunta.get("id"), "lacar-presa", "oferece a reação ao alcance de duas casas")
	t.igual(b.quem_decide(), u.id, "a escolha pertence ao portador da Corrente")
	t.igual(alvo.pos, ORIGEM, "o inimigo ainda não andou")
	t.ok(b.heroi_responder("sim"), "escolhe usar Laçar a Presa")
	t.igual(u.carta_com("arma").fadiga, 2, "paga a fadiga na arma")
	t.igual(u.acoes_reacao, reacoes - 1, "gasta a Reação")
	b.parar()
	b.teste_defesa.parar()
	b._resolver()
	t.ok(b.resultado["acertou"], "o ataque acerta")
	t.igual(alvo.vida, 100, "o acerto não causa dano")
	t.igual(alvo.fichas_total("Imobilizar"), 1, "o acerto dá um Imobilizar")
	t.ok(b.movimento_pendente.is_empty(), "descarta o caminho que estava em andamento")
	b.continuar()
	t.igual(alvo.pos, ORIGEM, "o deslocamento interrompido não continua")
	t.igual(alvo.deslocamento, 0, "encerrou o deslocamento atual")


func test_corrente_erro_e_recusa_deixam_o_inimigo_andar(t) -> void:
	var b := _arena("corrente_de_caca")
	var u := b.ativa()
	var alvo := b.unidade("goblin1")
	_preparar_movimento(b)
	u.baralho.baralho.assign([35, 2, 1])
	b.baralho_inimigos.baralho.assign([34, 22, 9])
	b._mover(alvo, DESTINO)
	b.heroi_responder("sim")
	b.parar()
	b.teste_defesa.parar()
	b._resolver()
	t.ok(not b.resultado["acertou"], "errou a tentativa de laçar")
	t.igual(alvo.fichas_total("Imobilizar"), 0, "sem Imobilizar no erro")
	t.igual(alvo.vida, 100, "sem dano residual de Força")
	b.continuar()
	t.igual(alvo.pos, DESTINO, "no erro o deslocamento continua")
	b = _arena("corrente_de_caca")
	u = b.ativa()
	alvo = b.unidade("goblin1")
	_preparar_movimento(b)
	b._mover(alvo, DESTINO)
	b.heroi_responder("nao")
	t.igual(alvo.pos, DESTINO, "ao recusar o deslocamento também continua")
	t.igual(u.carta_com("arma").fadiga, 0, "recusar não gasta fadiga")


func test_corrente_ignora_inimigo_maior_e_movimento_forcado(t) -> void:
	var b := _arena("corrente_de_caca")
	var alvo := b.unidade("goblin1")
	var origem := b.ativa().pos
	_preparar_movimento(b)
	alvo.tamanho = "grande"
	b._mover(alvo, DESTINO)
	t.igual(alvo.pos, DESTINO, "inimigo maior se move sem a pergunta")
	alvo.pos = ORIGEM
	alvo.tamanho = "pequeno"
	b._empurrar_sem_dano(alvo, origem, 1)
	t.igual(alvo.pos, DESTINO, "empurrão passa sem disparar a Corrente")
	t.ok(b.pergunta.is_empty(), "não ofereceu reação nos dois casos")


func test_corrente_respeita_o_custo_reduzido_do_foco_mortal(t) -> void:
	var b := _arena("corrente_de_caca", "foco-mortal")
	var arma = b.ativa().carta_com("arma")
	arma.fadiga = 1
	_preparar_movimento(b)
	b._mover(b.ativa(), DESTINO)
	t.igual(b.pergunta.get("id"), "lacar-presa", "o custo reduzido cabe na carta")
	t.ok(b.heroi_responder("sim"), "usa a reação com 1 de Fadiga disponível")
	t.igual(arma.fadiga, 2, "Foco Mortal reduz o custo de 2 para 1")
