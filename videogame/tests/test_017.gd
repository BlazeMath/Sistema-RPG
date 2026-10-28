## 0.17: inimigos que conjuram (Mana Densa, Contramagia), fantasmas e o pântano.
extends RefCounted

const Batalha := preload("res://core/batalha.gd")
const Pantano := preload("res://core/dados_pantano.gd")
const TC := preload("res://tests/test_classes.gd")


func _pantano() -> Batalha:
	var tc = TC.new()
	var fichas := [tc._ficha("Guerreiro", "A", [], []), tc._ficha("Mago", "B", ["classe.mago.mente-belica"], []),
		tc._ficha("Clérigo", "C", [], []), tc._ficha("Caçador", "D", [], [])]
	var b := Batalha.new(Pantano.missao(fichas), 4)
	b.iniciar()
	return b


func test_pantano_monta(t) -> void:
	var b := _pantano()
	t.ok(b.escuro and b.luz_ambiente == 1, "noite de lua: tudo é penumbra")
	t.igual(b.nivel_de_luz(Vector2i(5, 5)), 1, "penumbra no meio do mato")
	t.ok(b.unidade("morgana") != null and not b.unidade("morgana").magias.is_empty(), "a bruxa conjura")
	t.ok(not b.zonas_em(Vector2i(12, 9)).is_empty(), "lodo no mapa")
	t.ok(b.grade.custo_extra.has(Vector2i(12, 9)), "lodo é terreno difícil")


func test_fantasma_flutua(t) -> void:
	var b := _pantano()
	var f := b.unidade("fantasma1")
	t.ok(b.modo_de_andar(f)["nada"], "fantasma atravessa a água")


func _bruxa_e_alvo(b: Batalha):
	var m := b.unidade("morgana")
	var h := b.unidade("heroi2")
	m.alerta = true
	m.pos = Vector2i(20, 12)
	h.pos = Vector2i(16, 12)
	b.escuro = false
	return [m, h]


func test_maldicao_e_mana_densa(t) -> void:
	var b := _pantano()
	var par = _bruxa_e_alvo(b)
	var m = par[0]
	var h = par[1]
	var mente = h.cartas[h.cartas.size() - 1]
	if mente.slug() != "mana-densa":
		mente.lado = 1 - mente.lado
	b.perguntar_escolhas = true
	m.acoes_padrao = 1
	t.ok(b._ia_conjurar(m, h), "conjura")
	t.igual(b.fase, Batalha.Fase.PERGUNTA, "pergunta se alguém reage")
	var ops: Array = b.pergunta["opcoes"]
	t.ok(ops.any(func(o): return str(o[0]).begins_with("mana:")), "Mana Densa oferecida")
	var mao: int = h.baralho.mao.size()
	b.heroi_responder("mana:" + h.id)
	t.igual(h.baralho.mao.size(), mao - 1, "descartou uma carta")
	t.igual(h.fichas_total("Penalidade"), 0, "a maldição foi anulada")


func test_maldicao_sem_reacao(t) -> void:
	var b := _pantano()
	var par = _bruxa_e_alvo(b)
	var m = par[0]
	var h = par[1]
	h.espirito = -30   # não resiste
	m.acoes_padrao = 1
	t.ok(b._ia_conjurar(m, h), "conjura")
	t.igual(h.fichas_total("Penalidade"), 1, "Penalidade da Maldição do Lodo")
