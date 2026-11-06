extends RefCounted

const Campanha := preload("res://core/campanha.gd")
const Batalha := preload("res://core/batalha.gd")
const Fase := preload("res://core/fase.gd")
const Personagem := preload("res://core/personagem.gd")
const Prontos := preload("res://core/herois_prontos.gd")

const VAU := "fase:investigacao_vau_cinzento"
const CAO := "fase:bandidos_cao_vermelho"
const BAILE := "fase:baile_mascaras_prata"
const PRIMEIRO_CICLO := ["fazenda", "masmorra", "pantano"]


func _isolar() -> Dictionary:
	var antes := {"campanha": Campanha.dados, "arquivo": Campanha.arquivo, "memoria": Campanha.memoria,
		"fichas": Personagem.memoria}
	Campanha.memoria = true
	Campanha.dados = Campanha._novos_dados()
	Campanha.dados["concluidas"] = PRIMEIRO_CICLO.duplicate()
	Campanha.dados["nivel"] = 2
	Personagem.memoria = [Prontos.ficha("Investigador")]
	return antes


func _restaurar(antes: Dictionary) -> void:
	Campanha.dados = antes["campanha"]
	Campanha.arquivo = antes["arquivo"]
	Campanha.memoria = antes["memoria"]
	Personagem.memoria = antes["fichas"]


func _batalha(id: String) -> Batalha:
	var fase := Fase.carregar(id.trim_prefix("fase:"))
	var b := Batalha.new(Fase.para_cenario(fase, Personagem.memoria), 42)
	b.iniciar()
	b.indice_vez = b.ordem.find("heroi")
	b._comecar_turno()
	return b


func test_dossie_arquiva_provas_de_vau_uma_vez_e_so_na_vitoria(t) -> void:
	var antes := _isolar()
	var b := _batalha(VAU)
	var u := b.ativa()
	u.pos = Vector2i(7, 15)
	u.pericias["Ladinagem"] = 3
	u.atributos["destreza"] = 3
	for c in [9, 22]:
		u.baralho.baralho.erase(c)
		u.baralho.mao.erase(c)
		u.baralho.baralho.append(c)
	t.ok(b.heroi_interagir("bau_guarda", "abrir"), "abre o baú da fase real de Vau")
	t.ok(b.parar(), "resolve o teste da fechadura")
	if b.vantagem_pendente():
		b.heroi_vantagem_confirmar()
	t.ok(b.pistas.has("Recibo do Círculo Rubro"), "encontra o recibo na missão")
	b.continuar()
	b.deducoes["vau_pagamento"] = "As moedas e o recibo ligam os pagamentos."
	b.deducoes["contraprova:Procure Faro"] = "Procure Faro."
	Campanha.registrar_fim(b, VAU, false)
	t.ok(Campanha.dossie().is_empty(), "derrota não arquiva as evidências")
	var alvo := b.unidade("orsk")
	b._dano_direto(alvo, alvo.vida, "teste de vitória")
	b._verificar_fim()
	t.igual(b.fase, Batalha.Fase.VITORIA, "derrotar Orsk vence Vau")
	var resumo := Campanha.registrar_fim(b, VAU, true)
	var provas := Campanha.dossie()
	t.igual(provas.keys(), ["livro_de_orsk", "recibo_de_orsk", "vau_pagamento"], "arquiva o relatório, a prova achada e a dedução")
	t.ok(resumo.contains("Dossiê da guilda: 3"), "resumo anuncia os novos registros")
	t.igual(provas.get("vau_pagamento", {}).get("missao"), VAU, "registra a origem da dedução")
	var repetido := Campanha.registrar_fim(b, VAU, true)
	t.igual(Campanha.dossie(), provas, "repetição não duplica registros")
	t.ok(not repetido.contains("Dossiê da guilda"), "repetição não anuncia evidências novas")
	_restaurar(antes)


func test_dossie_persiste_em_arquivo_e_nao_adianta_a_carta_do_baile(t) -> void:
	var antes := _isolar()
	Campanha.dados["concluidas"].append_array([VAU, CAO])
	var b := _batalha(BAILE)
	Campanha.registrar_fim(b, BAILE, false)
	t.igual(Campanha.dossie().keys(), ["livro_de_orsk", "carta_a_ferrabras"], "não revela Corvin antes de vencer")
	var alvo := b.unidade("corvin")
	b._dano_direto(alvo, alvo.vida, "teste de vitória")
	b._verificar_fim()
	t.igual(b.fase, Batalha.Fase.VITORIA, "derrotar Corvin vence o Baile")
	Campanha.registrar_fim(b, BAILE, true)
	var provas := Campanha.dossie()
	t.igual(provas.keys(), ["livro_de_orsk", "carta_a_ferrabras", "carta_a_corvin"], "a vitória no Baile completa as três provas")
	var arquivo := "user://teste-dossie-032-%d.json" % Time.get_ticks_usec()
	Campanha.arquivo = arquivo
	Campanha.memoria = false
	Campanha.salvar()
	Campanha.dados = {}
	t.igual(Campanha.dossie(), provas, "reabrir o arquivo preserva o dossiê")
	DirAccess.remove_absolute(arquivo)
	Campanha.memoria = true
	Campanha.reiniciar()
	t.ok(Campanha.dossie().is_empty(), "uma nova campanha começa com dossiê vazio")
	_restaurar(antes)


func test_dossie_recupera_so_as_provas_de_contratos_antigos_concluidos(t) -> void:
	var antes := _isolar()
	Campanha.dados = {"concluidas": ["fazenda", VAU], "nivel": 1}
	var provas := Campanha.dossie()
	t.igual(provas.keys(), ["livro_de_orsk"], "save antigo reconstrói apenas o relatório da vitória registrada")
	provas.clear()
	t.igual(Campanha.dossie().size(), 1, "consultas não alteram o arquivo da guilda")
	_restaurar(antes)
