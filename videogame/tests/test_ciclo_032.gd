extends RefCounted

const Batalha := preload("res://core/batalha.gd")
const Baralho := preload("res://core/baralho.gd")
const Campanha := preload("res://core/campanha.gd")
const Fase := preload("res://core/fase.gd")
const Personagem := preload("res://core/personagem.gd")
const Prontos := preload("res://core/herois_prontos.gd")

const PEDRAVELHA := ["fazenda", "masmorra", "pantano"]
const VAU := "fase:investigacao_vau_cinzento"
const CAO := "fase:bandidos_cao_vermelho"
const BAILE := "fase:baile_mascaras_prata"
const RUBRO := [VAU, CAO, BAILE]


func _isolar() -> Dictionary:
	var anterior := {"dados": Campanha.dados, "memoria": Campanha.memoria, "arquivo": Campanha.arquivo,
		"herois": Personagem.memoria, "fases": Fase.memoria}
	Campanha.dados = Campanha._novos_dados()
	Campanha.memoria = true
	Fase.memoria = {}
	var f := Prontos.ficha("Guerreiro")
	f["xp"] = 2
	Personagem.memoria = [f]
	return anterior


func _restaurar(anterior: Dictionary) -> void:
	Campanha.dados = anterior["dados"]
	Campanha.memoria = anterior["memoria"]
	Campanha.arquivo = anterior["arquivo"]
	Personagem.memoria = anterior["herois"]
	Fase.memoria = anterior["fases"]


func _resultado(t, id: String, vitoria: bool) -> String:
	var fase := Fase.carregar(id.trim_prefix(Fase.PREFIXO))
	var b := Batalha.new(Fase.para_cenario(fase, Personagem.carregar_todos()), 32)
	b.iniciar()
	t.ok(not b.vitoria_se_morrer.is_empty(), "a fase real tem alvos de vitória")
	if vitoria:
		for alvo in b.vitoria_se_morrer:
			b.unidade(alvo).vida = 0
	else:
		b.herois()[0].baralho.estado = Baralho.Estado.MORTO
	t.ok(b._verificar_fim(), "o motor encerra a missão")
	t.igual(b.fase, Batalha.Fase.VITORIA if vitoria else Batalha.Fase.DERROTA, "o motor reconhece o resultado")
	return Campanha.registrar_fim(b, id, b.fase == Batalha.Fase.VITORIA)


func test_ciclo_do_circulo_rubro_abre_na_ordem_e_chega_ao_nivel_tres(t) -> void:
	var anterior := _isolar()
	Campanha.dados["concluidas"] = ["fazenda", "masmorra"]
	Campanha.dados["desbloqueadas"] = RUBRO.duplicate()
	t.ok(Campanha.motivo_trancada(VAU).contains("Pântano"), "Vau-Cinzento espera o fechamento de Pedravelha")
	t.ok(Campanha.motivo_trancada(CAO) != "" and Campanha.motivo_trancada(BAILE) != "", "o desbloqueio avulso não pula a trilha")
	t.igual(Campanha.motivo_trancada("fase:zumbis_sinos_mudos"), "", "Sinos Mudos segue independente após a Cripta")
	Campanha.dados["concluidas"].append("pantano")
	t.ok(Campanha._verificar_nivel().contains("NÍVEL 2"), "Pedravelha entrega o nível 2")
	t.igual(Campanha.motivo_trancada(VAU), "", "Vau-Cinzento abre")
	t.ok(Campanha.motivo_trancada(CAO) != "" and Campanha.motivo_trancada(BAILE) != "", "os sucessores ainda esperam")
	for id in RUBRO:
		t.igual(Campanha.missao(id).get("ciclo"), 2, "metadados da fase no segundo ciclo")
	var texto := _resultado(t, VAU, true)
	t.ok(texto.contains(Campanha.missao(CAO)["nome"]), "a vitória anuncia Cão Vermelho")
	t.igual(Campanha.motivo_trancada(CAO), "", "Cão Vermelho abre")
	t.ok(Campanha.motivo_trancada(BAILE) != "", "Baile ainda espera")
	_resultado(t, CAO, true)
	t.igual(Campanha.motivo_trancada(BAILE), "", "Baile abre após Cão Vermelho")
	_resultado(t, BAILE, false)
	t.igual(Campanha.nivel(), 2, "derrota no Baile não promove")
	t.ok(not Campanha.ciclo_completo(2), "segundo ciclo incompleto")
	texto = _resultado(t, BAILE, true)
	t.ok(texto.contains("NÍVEL 3"), "a vitória final anuncia o nível 3")
	t.igual(Campanha.nivel(), 3, "dois ciclos completos entregam nível 3")
	t.ok(Campanha.ciclo_completo(2), "fecha o Círculo Rubro")
	t.igual(Personagem.carregar_todos()[0]["xp"], 4, "libera quatro XP de cartas")
	_restaurar(anterior)


func test_vitorias_antigas_valem_sem_replay_e_a_migracao_preserva_o_save(t) -> void:
	var anterior := _isolar()
	Campanha.memoria = false
	Campanha.arquivo = "user://campanha_ciclo_032_%d.json" % Time.get_ticks_usec()
	Campanha.dados = {}
	var arquivo := FileAccess.open(Campanha.arquivo, FileAccess.WRITE)
	arquivo.store_string(JSON.stringify({"cobre": 4567, "nivel": 2, "concluidas": PEDRAVELHA + RUBRO,
		"feridas": {"Caio": {"exilio": 4, "descarte": 0}}, "desbloqueadas": ["fase:torre_vaelor"], "encomendas": []}))
	arquivo.close()
	t.igual(Campanha.nivel(), 3, "o save anterior sobe ao carregar, sem replay")
	t.igual(Campanha.dinheiro(), 4567, "mantém a bolsa")
	t.igual(Campanha.feridas_de("Caio")["exilio"], 4, "mantém feridas")
	t.igual(Campanha.motivo_trancada("fase:torre_vaelor"), "", "mantém desbloqueio de contrato independente")
	t.igual(Campanha.carregar()["concluidas"], PEDRAVELHA + RUBRO, "mantém todos os IDs antigos")
	t.igual(Personagem.carregar_todos()[0]["xp"], 4, "migra XP do grupo")
	var salvo: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Campanha.arquivo))
	t.igual(salvo["nivel"], 3, "persiste o nível migrado")
	Campanha.dados = {}
	t.igual(Campanha.nivel(), 3, "reabrir o save conserva o nível")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Campanha.arquivo))
	_restaurar(anterior)


func test_vitorias_do_segundo_ciclo_so_promovem_depois_do_primeiro(t) -> void:
	var anterior := _isolar()
	Campanha.dados["concluidas"] = RUBRO.duplicate()
	t.igual(Campanha._verificar_nivel(), "", "o segundo ciclo isolado não promove")
	t.igual(Campanha.nivel(), 1, "segue no nível inicial")
	Campanha.dados["concluidas"].append_array(PEDRAVELHA)
	t.ok(Campanha._verificar_nivel().contains("NÍVEL 3"), "as vitórias anteriores contam quando o primeiro ciclo fecha")
	t.igual(Campanha._verificar_nivel(), "", "a promoção acontece uma vez")
	Campanha.dados["concluidas"] = []
	t.igual(Campanha._verificar_nivel(), "", "não rebaixa um nível já alcançado")
	t.igual(Campanha.nivel(), 3, "conserva o nível guardado")
	_restaurar(anterior)
