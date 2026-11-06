extends RefCounted

const Batalha := preload("res://core/batalha.gd")
const Fase := preload("res://core/fase.gd")
const Prontos := preload("res://core/herois_prontos.gd")
const Investigador := preload("res://core/cartas_investigador.gd")


func _vau(heroi := "detetive-analitico", cartas := []) -> Batalha:
	var ficha := Prontos.ficha("Investigador")
	ficha["herois"][0] = "classe.investigador.heroi." + heroi
	if not cartas.is_empty():
		ficha["cartas"] = cartas
	var b := Batalha.new(Fase.para_cenario(Fase.carregar("investigacao_vau_cinzento"), [ficha]), 30)
	b.iniciar()
	b.indice_vez = b.ordem.find("heroi")
	b._comecar_turno()
	b.perguntar_escolhas = true
	return b


func _topo(b: Batalha, cartas: Array[int]) -> void:
	var baralho := b.ativa().baralho
	for c in cartas:
		baralho.baralho.erase(c)
		baralho.mao.erase(c)
		baralho.descarte.erase(c)
		baralho.baralho.append(c)


func _parar(b: Batalha) -> void:
	b.parar()
	if b.vantagem_pendente():
		b.heroi_vantagem_confirmar()


func test_hipotese_e_coleta_atuam_antes_da_compra_em_vau(t) -> void:
	var b := _vau()
	var u := b.ativa()
	u.pos = Vector2i(14, 10)
	_topo(b, [7, 9, 22])
	t.ok(b.heroi_interagir("poco_praca", "hipotese_corda"), "prepara a verificação real no poço")
	t.igual(u.acoes_mov, 0, "preparação usa Movimento")
	t.igual(u.carta_com("hipotese-de-trabalho").fadiga, 1, "paga a Fadiga da carta")
	b.continuar()
	t.ok(b.heroi_interagir("poco_praca", "examinar"), "examina a corda que foi indicada")
	t.igual(b.pergunta.get("id"), "scry", "scry abre antes de comprar")
	t.igual(b.teste_pericia, null, "as duas cartas iniciais ainda não saíram")
	for i in 3:
		t.igual(b.pergunta.get("id"), "scry", "oferece cada uma das três cartas")
		b.heroi_responder("topo")
	t.igual(b.pergunta.get("id"), "iv_preparar_teste", "depois de scry, oferece Coleta Metódica")
	t.igual(b.teste_pericia, null, "a Coleta também ocorre antes das cartas")
	b.heroi_responder("sim")
	t.igual(b.teste_pericia.cartas, [22, 9], "preservou a ordem escolhida")
	t.igual(u.carta_com("coleta-metodica").fadiga, 1, "paga a Coleta antes do resultado")
	_parar(b)
	t.igual(b.pistas.size(), 1, "uma evidência no registro do grupo")
	t.igual(Investigador.pistas(u), 2, "uma Pista do Detetive e uma da Coleta")
	b.continuar()
	_topo(b, [10, 23])
	t.ok(b.heroi_interagir("poco_praca", "examinar"), "repete o exame")
	t.igual(b.fase, Batalha.Fase.INTERACAO_TESTE, "Coleta não é oferecida duas vezes na rodada")
	_parar(b)
	t.igual(b.pistas.size(), 1, "evidência repetida não duplica")
	t.igual(Investigador.pistas(u), 2, "evidência repetida não rende Pista")


func test_ligar_os_pontos_em_vau_nao_conta_como_terceira_evidencia(t) -> void:
	var b := _vau()
	var u := b.ativa()
	b.perguntar_escolhas = false
	u.pos = Vector2i(14, 10)
	_topo(b, [9, 22])
	t.ok(b.heroi_interagir("poco_praca", "examinar_vestigios"), "Detetive examina com a sua ativada")
	t.igual(u.acoes_mov, 0, "Examinar os Vestígios usa Movimento")
	_parar(b)
	b.continuar()
	u.pos = Vector2i(8, 8)
	_topo(b, [11, 24])
	t.ok(b.heroi_interagir("boticario", "pressionar"), "obtém a segunda evidência em Faro")
	_parar(b)
	b.continuar()
	u.pos = Vector2i(20, 18)
	var c = u.carta_com("coleta-metodica")
	c.virar()
	t.igual(Investigador.pistas(u), 1, "o Detetive ganha uma vez por rodada")
	t.ok(b.heroi_interagir("porta_armazem", "ligar_poco_boticario"), "gasta Pista para ligar as evidências")
	t.igual(c.fadiga, 1, "paga Fadiga de Ligar os Pontos")
	t.igual(Investigador.pistas(u), 0, "a Pista pessoal foi gasta")
	t.ok(b.deducoes.has("vau_acesso_ao_veneno"), "registra a inferência da missão")
	t.igual(b.pistas.size(), 2, "a dedução não vira nova evidência")
	b.continuar()
	b._comecar_turno()
	t.ok(not b.heroi_interagir("porta_armazem", "acusar"), "duas evidências e uma dedução não abrem a porta")
	Investigador.ganhar(b, u, 1)
	t.ok(not b.heroi_interagir("porta_armazem", "ligar_poco_boticario"), "não cobra pela mesma dedução de novo")
	t.igual(Investigador.pistas(u), 1, "recusa não cobra Pista")


func test_contraprova_em_vau_preserva_falha_e_cobra_so_pista_e_reacao(t) -> void:
	var b := _vau()
	var u := b.ativa()
	u.pos = Vector2i(14, 10)
	var c = u.carta_com("hipotese-de-trabalho")
	c.virar()
	Investigador.ganhar(b, u, 1)
	_topo(b, [1, 2])
	t.ok(b.heroi_interagir("poco_praca", "examinar"), "começa o exame que vai falhar")
	t.ok(b.heroi_responder("nao"), "dispensa a Coleta Metódica")
	_parar(b)
	t.igual(b.pergunta.get("id"), "iv_contraprova", "Contraprova só depois de aplicar a falha")
	t.igual(b.resultado_interacao.get("rotulo"), "falha", "resultado original é falha")
	b.heroi_responder("sim")
	t.igual(c.fadiga, 0, "v02 retira o custo de Fadiga")
	t.igual(u.acoes_reacao, 0, "paga uma Reação")
	t.igual(Investigador.pistas(u), 0, "paga uma Pista")
	t.igual(b.pistas.size(), 0, "o exame falhou e não gerou evidência")
	t.igual(b.deducoes.size(), 1, "registra apenas a orientação")
	t.ok(str(b.resultado_interacao["efeitos"]).contains("boticário"), "o painel mostra a próxima verificação")


func test_decifrador_corrige_falha_de_vau_antes_das_consequencias(t) -> void:
	var b := _vau("decifrador")
	var u := b.ativa()
	u.pos = Vector2i(14, 10)
	Investigador.ganhar(b, u, 1)
	_topo(b, [5, 5 + 13, 4])
	u.baralho.baralho.erase(9)
	if not 9 in u.baralho.mao:
		u.baralho.mao.append(9)
	t.ok(b.heroi_interagir("poco_praca", "examinar"), "começa o exame com soma insuficiente")
	b.heroi_responder("nao")
	_parar(b)
	t.igual(b.pergunta.get("id"), "iv_reagir_falha", "oferece Corrigir antes da falha definitiva")
	t.igual(b.pistas.size(), 0, "a falha provisória ainda não teve efeito")
	b.heroi_responder("sim")
	t.igual(b.pergunta.get("id"), "iv_corrigir_carta", "o executor escolhe uma carta real da mão")
	b.heroi_responder("9")
	t.igual(b.resultado_interacao.get("rotulo"), "sucesso", "a carta transforma a falha em sucesso")
	t.igual(b.pistas.keys(), ["Beladona no poço"], "aplica só a consequência do sucesso")
	t.igual(b.teste_pericia.cartas.size(), 3, "a carta extra pertence ao teste")
	t.ok(not b.teste_pericia.critico(), "a carta extra não gera crítico")
	t.ok(not 9 in u.baralho.mao and 9 in u.baralho.descarte, "a carta foi gasta uma vez")
	t.igual(u.fichas_total("Foco"), 1, "Leitura Confirmada dá Foco ao executor")


func test_segundo_caminho_em_vau_refaz_com_cartas_novas(t) -> void:
	var b := _vau("investigador-de-campo", ["classe.investigador.plano-de-extracao"])
	var u := b.ativa()
	u.pos = Vector2i(14, 10)
	var c = u.carta_com("plano-de-extracao")
	c.virar()
	Investigador.ganhar(b, u, 2)
	_topo(b, [9, 22, 1, 2])
	t.ok(b.heroi_interagir("poco_praca", "examinar"), "abre uma verificação na fase")
	_parar(b)
	t.igual(b.pergunta.get("dados", {}).get("slug"), "segundo-caminho", "oferece a reação antes da falha")
	b.heroi_responder("sim")
	t.igual(b.fase, Batalha.Fase.INTERACAO_TESTE, "abre uma nova tentativa")
	t.igual(b.teste_pericia.cartas, [22, 9], "usa cartas novas do baralho")
	t.ok(1 in u.baralho.descarte and 2 in u.baralho.descarte, "primeira tentativa segue gasta")
	t.igual(u.acoes_padrao, 1, "segunda tentativa não gasta outra Padrão")
	t.igual(u.acoes_reacao, 0, "gasta a Reação")
	t.igual(c.fadiga, 2, "paga a Fadiga")
	t.igual(Investigador.pistas(u), 0, "paga as duas Pistas")
	_parar(b)
	t.igual(b.resultado_interacao.get("rotulo"), "sucesso", "a tentativa extra substitui a falha")
	t.igual(b.pistas.size(), 1, "recolhe uma única evidência")
