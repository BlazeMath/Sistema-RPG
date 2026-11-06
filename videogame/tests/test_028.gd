## 0.28: monstros clássicos no bestiário, regeneração (troll), invocação (mago), pistas
## de investigação e as seis missões prontas (data/fases).
extends RefCounted

const Batalha := preload("res://core/batalha.gd")
const Fase := preload("res://core/fase.gd")
const Bestiario := preload("res://core/bestiario.gd")
const Prontos := preload("res://core/herois_prontos.gd")
const Campanha := preload("res://core/campanha.gd")

const MISSOES := ["investigacao_vau_cinzento", "zumbis_sinos_mudos", "bandidos_cao_vermelho", "baile_mascaras_prata",
	"deserto_kesh_tar", "torre_vaelor"]


func _fichas(n := 4) -> Array:
	var l := []
	for c in ["Guerreiro", "Clérigo", "Ladino", "Mago"].slice(0, n):
		var f := Prontos.ficha(c)
		f["nome"] = c + " 28"
		l.append(f)
	return l


func _batalha(f: Dictionary, n := 4):
	var b := Batalha.new(Fase.para_cenario(f, _fichas(n)), 7)
	b.distribuicao_automatica = true
	b.iniciar()
	return b


func _arena(preset: String) -> Dictionary:
	var f := Fase.nova("Arena 28", 14, 10)
	f["inicio"] = ["1,4", "1,5", "2,4", "2,5"]
	f["inimigos"] = [{"id": "m", "preset": preset, "pos": "10,5", "alerta": true}]
	return Fase.normalizar(f)


func test_bestiario_novos_presets(t) -> void:
	for id in ["rato_gigante", "lobo", "lobo_atroz", "aranha_gigante", "escorpiao_gigante", "zumbi", "zumbi_inchado", "carnical",
			"mumia", "bandido", "bandido_besteiro", "capanga", "capitao_bandido", "cultista", "guarda_corrupto", "assassino",
			"duelista", "orc", "ogro", "troll", "gargula", "armadura_animada", "elemental_fogo", "elemental_terra", "diabrete",
			"verme_da_areia", "mago_vaelor"]:
		t.ok(Bestiario.PRESETS.has(id), "preset %s existe" % id)
		var b = _batalha(_arena(id), 2)
		var m = b.unidade("m")
		t.ok(m != null and m.vida > 0, "%s entra em batalha com vida" % id)


func test_troll_regenera_menos_no_fogo(t) -> void:
	var b = _batalha(_arena("troll"))
	var m = b.unidade("m")
	m.vida = m.vida_max - 10
	m.efeitos.erase("hab_turno")
	b._ia_habilidades(m)
	t.ok(m.vida > m.vida_max - 10, "o troll se regenera")
	var v: int = m.vida
	m.efeitos.erase("hab_turno")
	m.dar_ficha("Fogo")
	b._ia_habilidades(m)
	t.igual(m.vida, v, "em chamas, não se regenera")


func test_mago_invoca_e_invocacoes_somem(t) -> void:
	var b = _batalha(_arena("mago_vaelor"))
	var m = b.unidade("m")
	var hab: Dictionary = {}
	for h in m.habilidades:
		if h["tipo"] == "invocar":
			hab = h
	t.ok(not hab.is_empty(), "Vaelor tem a habilidade de invocar")
	var antes: int = b.unidades.size()
	b._invocar(m, hab)
	b._invocar(m, hab)
	t.igual(b.unidades.size(), antes + 2, "duas invocações surgem")
	var inv = b.unidades.filter(func(o): return o.efeitos.has("invocado_por"))
	t.igual(inv.size(), 2, "marcadas como invocações")
	t.ok(inv.all(func(o): return o.viva() and o.alerta), "chegam vivas e alertas")
	t.ok(b.ordem.has(inv[0].id), "entram na ordem de turnos")
	m.vida = 0
	b._inimigo_caiu(m)
	t.ok(inv.all(func(o): return not o.viva()), "se o mago cai, as invocações somem")


func test_pistas_liberam_opcao(t) -> void:
	var f := Fase.nova("Pistas", 12, 8)
	f["inicio"] = ["1,3", "1,4"]
	f["inimigos"] = [{"id": "x", "preset": "bandido", "pos": "10,6", "alvo": true}]
	f["objetivo"]["tipo"] = "derrotar_alvos"
	f["interacoes"] = [
		{"id": "testemunha", "nome": "Testemunha", "pos": "2,2", "opcoes": [
			{"id": "ouvir", "texto": "Ouvir", "custo": "nenhum", "resultados": {"feito": {"texto": "", "efeitos": [
				{"tipo": "pista", "nome": "Pista A", "texto": "a"}, {"tipo": "pista", "nome": "Pista B", "texto": "b"}]}}}]},
		{"id": "porta", "nome": "Porta", "pos": "2,5", "opcoes": [
			{"id": "acusar", "texto": "Acusar", "custo": "nenhum", "requer_pistas": 2, "resultados": {"feito": {"texto": "", "efeitos": [{"tipo": "lore", "texto": "ok"}]}}}]}]
	var b = _batalha(Fase.normalizar(f), 2)
	var h = b.unidade("heroi")
	h.pos = Vector2i(1, 4)
	b.indice_vez = b.ordem.find("heroi")
	b.fase = Batalha.Fase.HEROI_ESCOLHE
	b._comecar_turno()
	var porta: Dictionary = b.interacao("porta")
	t.ok(b.motivo_sem_opcao(h, porta, b.opcao_da_interacao(porta, "acusar")).contains("pistas"), "sem pistas, não dá para acusar")
	h.pos = Vector2i(1, 2)
	t.ok(b.heroi_interagir("testemunha", "ouvir"), "ouvir a testemunha")
	b.continuar()
	t.igual(b.pistas.size(), 2, "duas pistas anotadas")
	h.pos = Vector2i(1, 4)
	t.igual(b.motivo_sem_opcao(h, porta, b.opcao_da_interacao(porta, "acusar")), "", "com as pistas, a acusação libera")


func test_missoes_prontas(t) -> void:
	var ids_mural := Campanha.missoes().map(func(m): return str(m["id"]))
	for id in MISSOES:
		var f: Dictionary = Fase.carregar(id)
		t.ok(not f.is_empty(), "missão %s carrega" % id)
		if f.is_empty():
			continue
		var erros: Array = Fase.validar(f)
		t.ok(erros.is_empty(), "missão %s sem erros de validação %s" % [id, str(erros.map(func(e): return e["texto"]))])
		var b = _batalha(f)
		t.ok(b.unidades.size() >= 6, "missão %s monta a batalha" % id)
		t.ok(ids_mural.has("fase:" + id), "missão %s aparece no mural" % id)
		# Todo inimigo precisa poder ser alcançado por alguém (nenhum preso numa casa isolada).
		for e in f["inimigos"]:
			var u = b.unidade(str(e["id"]))
			t.ok(u != null and b.grade.dentro(u.pos) and not b.grade.bloqueado(u.pos), "%s/%s numa casa válida" % [id, e["id"]])


func test_baile_precisa_de_tres_pistas(t) -> void:
	var b = _batalha(Fase.carregar("baile_mascaras_prata"))
	var h = b.unidade("heroi")
	var brinde: Dictionary = b.interacao("brinde")
	h.pos = Vector2i(14, 3)
	b.indice_vez = b.ordem.find("heroi")
	b.fase = Batalha.Fase.HEROI_ESCOLHE
	b._comecar_turno()
	var mot: String = b.motivo_sem_opcao(h, brinde, b.opcao_da_interacao(brinde, "acusar_barao"))
	t.ok(mot.contains("pistas"), "acusar o Barão pede pistas: " + mot)
	b.pistas = {"a": "", "b": "", "c": ""}
	t.ok(not b.motivo_sem_opcao(h, brinde, b.opcao_da_interacao(brinde, "acusar_barao")).contains("pistas"), "com 3 pistas, libera")


func test_torre_tem_andares(t) -> void:
	var b = _batalha(Fase.carregar("torre_vaelor"))
	t.igual(b.grade.nivel(b.unidade("vaelor").pos), 3, "Vaelor está no último andar")


## Abre todas as portas e caminhos que as interações abrem e confere que todo inimigo,
## toda interação e todo ponto da fase pode ser alcançado a partir do início.
func test_missoes_tudo_alcancavel(t) -> void:
	for id in MISSOES:
		var f: Dictionary = Fase.carregar(id)
		var b = _batalha(f)
		for it in f["interacoes"]:
			for o in it["opcoes"]:
				for r in o["resultados"].values():
					for ef in r["efeitos"]:
						if ef.get("tipo", "") == "abrir_caminho":
							for c in ef["celulas"]:
								b.grade.obstaculos.erase(Fase.casa(str(c)))
		var mapa: Dictionary = b.grade.alcance(Fase.casa(str(f["inicio"][0])), 9999, {}, {})
		for e in f["inimigos"]:
			t.ok(mapa.has(Fase.casa(str(e["pos"]))), "%s: dá para chegar até %s" % [id, e["id"]])
		for it in f["interacoes"]:
			var p: Vector2i = Fase.casa(str(it["pos"]))
			var perto := mapa.has(p)
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
				perto = perto or mapa.has(p + d)
			t.ok(perto, "%s: dá para chegar perto de %s" % [id, it["id"]])


## Robô do teste de rede joga um trecho de cada missão (com todos os grupos alertas) para
## pegar erros do motor nas habilidades novas (invocar, regenerar, cavar do verme...).
func test_missoes_robo_joga(t) -> void:
	var bot = preload("res://tests/test_026.gd").new()
	for id in MISSOES:
		var f: Dictionary = Fase.carregar(id)
		for e in f["inimigos"]:
			e["alerta"] = true
		var b = _batalha(f)
		# Heróis perto do alvo principal para a luta acontecer logo.
		var alvo = null
		for e in f["inimigos"]:
			if e.get("alvo", false) or alvo == null:
				alvo = b.unidade(str(e["id"]))
		var livres: Array = []
		for dx in range(-3, 4):
			for dy in range(-3, 4):
				var p: Vector2i = alvo.pos + Vector2i(dx, dy)
				if b.grade.dentro(p) and not b.grade.bloqueado(p) and b.grade.nivel(p) == b.grade.nivel(alvo.pos) \
						and not b.unidades.any(func(o): return o.viva() and o.pos == p):
					livres.append(p)
		var i := 0
		for h in b.herois():
			if i < livres.size():
				h.pos = livres[i]
				i += 1
		var r0: int = b.rodada
		bot._tentou = {}
		var feitos := 0
		for k in 500:
			if b.fase in [Batalha.Fase.VITORIA, Batalha.Fase.DERROTA]:
				break
			var cmd: Array = bot._decidir(b)
			if cmd.is_empty():
				break
			b.callv(cmd[0], bot._dec(b, bot._cod(cmd[1])))
			b.eventos.clear()
			feitos += 1
		if id == "torre_vaelor":
			t.ok(b.unidades.any(func(o): return o.efeitos.has("invocado_por")), "Vaelor invocou criaturas na luta")
		t.ok(feitos > 20 and (b.rodada > r0 or b.fase in [Batalha.Fase.VITORIA, Batalha.Fase.DERROTA]), "%s: o robô jogou (%d comandos, rodada %d)" % [id, feitos, b.rodada])
