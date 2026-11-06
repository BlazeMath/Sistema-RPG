## Exercita as duas entradas de Vau-Cinzento na fase do mural.
extends RefCounted

const Batalha := preload("res://core/batalha.gd")
const Fase := preload("res://core/fase.gd")
const Prontos := preload("res://core/herois_prontos.gd")

const PORTA := Vector2i(21, 18)
const ENTRADA := Vector2i(20, 18)


func _vau() -> Batalha:
	var f := Fase.carregar("investigacao_vau_cinzento")
	var b := Batalha.new(Fase.para_cenario(f, [Prontos.ficha("Guerreiro")]), 30)
	b.iniciar()
	b.indice_vez = b.ordem.find("heroi")
	b._comecar_turno()
	return b


func _testar(t, b: Batalha, id: String, opcao: String, cartas: Array[int], resultado: String) -> bool:
	# O fim do baralho é o topo. Preserva a identidade das cartas ao mudar de zona.
	var baralho := b.ativa().baralho
	for carta in cartas:
		baralho.baralho.erase(carta)
		baralho.mao.erase(carta)
		baralho.descarte.erase(carta)
		baralho.baralho.append(carta)
	var iniciou := b.heroi_interagir(id, opcao)
	t.ok(iniciou, "%s/%s inicia pela interação da fase" % [id, opcao])
	if not iniciou:
		return false
	t.igual(b.fase, Batalha.Fase.INTERACAO_TESTE, "usa a mesa de 21")
	t.ok(b.parar(), "encerra o teste")
	if b.vantagem_pendente():
		b.heroi_vantagem_confirmar()
	t.igual(b.fase, Batalha.Fase.INTERACAO_RESOLVIDA, "exibe o resultado da interação")
	t.igual(b.resultado_interacao.get("rotulo", ""), resultado, "%s/%s" % [id, opcao])
	return b.continuar()


func test_vau_acusacao_exige_tres_evidencias_distintas(t) -> void:
	var b := _vau()
	var heroi := b.ativa()
	heroi.pos = Vector2i(14, 10)
	t.ok(_testar(t, b, "poco_praca", "examinar", [9, 22], "sucesso"), "examina o poço")
	t.igual(b.pistas.keys(), ["Beladona no poço"], "o poço dá a primeira evidência")
	t.ok(_testar(t, b, "poco_praca", "examinar", [10, 23], "sucesso"), "pode repetir o exame")
	t.igual(b.pistas.size(), 1, "o mesmo achado não conta de novo")
	b._comecar_turno()
	heroi.pos = Vector2i(8, 8)
	t.ok(_testar(t, b, "boticario", "pressionar", [11, 24], "sucesso"), "ouve o boticário")
	t.igual(b.pistas.size(), 2, "duas evidências diferentes")
	heroi.pos = ENTRADA
	t.ok(not b.heroi_interagir("porta_armazem", "acusar"), "duas evidências não autorizam a acusação")
	t.ok(b.grade.bloqueado(PORTA), "o acesso continua bloqueado")
	t.ok(not b.unidade("orsk").alerta, "a tentativa inválida não alerta Orsk")
	heroi.pos = Vector2i(13, 12)
	t.ok(_testar(t, b, "viuva", "consolar", [12, 25], "sucesso"), "ouve Marta")
	t.igual(b.pistas.keys(), ["Beladona no poço", "Venda ao capitão", "Botas de barro vermelho"], "as evidências da praça e do boticário são coletivas")
	heroi.pos = ENTRADA
	b._comecar_turno()
	t.ok(b.heroi_interagir("porta_armazem", "acusar"), "três evidências liberam a acusação ao guerreiro")
	t.ok(b.continuar(), "fecha o resultado da acusação")
	t.ok(not b.grade.bloqueado(PORTA), "a guarda abre a entrada")
	t.ok(b.unidade("orsk").alerta and b.unidade("cultista1").alerta, "o grupo do armazém fica em alerta")
	t.igual(b.vitoria_se_morrer, ["orsk"], "Orsk é o alvo da missão")
	t.ok(b.heroi_mover(PORTA), "a casa da porta fica transitável")


func test_vau_arrombamento_funciona_sem_evidencias_e_preserva_dano(t) -> void:
	var b := _vau()
	var heroi := b.ativa()
	b.distribuicao_automatica = false
	heroi.pos = ENTRADA
	t.ok(not b.heroi_interagir("porta_armazem", "acusar"), "sem evidências não dá para acusar")
	t.ok(_testar(t, b, "porta_armazem", "arrombar", [1, 2], "falha"), "tenta arrombar sem evidências")
	t.igual(b.dano_pendente.get("dano", 0), 2, "a falha causa dois pontos de dano")
	var antes := heroi.baralho.baralho.size()
	t.ok(b.heroi_distribuir_dano(0, 0), "aplica o dano ao baralho")
	t.igual(heroi.baralho.baralho.size(), antes - 2, "o baralho perde duas cartas")
	t.ok(b.grade.bloqueado(PORTA), "a falha mantém a porta fechada")
	t.ok(not b.unidade("orsk").alerta, "a falha não alerta o grupo")
	t.ok(_testar(t, b, "porta_armazem", "arrombar", [9, 22], "sucesso"), "pode arrombar em uma nova tentativa")
	t.igual(b.pistas.size(), 0, "a força abre a porta sem criar evidências")
	t.ok(not b.grade.bloqueado(PORTA), "o arrombamento abre a mesma entrada")
	t.ok(b.unidade("orsk").alerta and b.unidade("cultista1").alerta, "o arrombamento alerta o mesmo grupo")
	t.igual(b.vitoria_se_morrer, ["orsk"], "Orsk continua sendo o alvo")
