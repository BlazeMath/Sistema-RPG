extends RefCounted

const Catalogo := preload("res://core/catalogo.gd")
const Personagem := preload("res://core/personagem.gd")
const Prontos := preload("res://core/herois_prontos.gd")


func test_catalogo_v04_do_invocador(t) -> void:
	var cartas := Catalogo.habilidades_de("Invocador")
	var criaturas := cartas.filter(func(c): return c["tipo"] == "criatura")
	var gerais := cartas.filter(func(c): return c["tipo"] == "geral")
	t.igual(Catalogo.herois_de("Invocador").size(), 1, "uma metade de herói")
	t.igual(gerais.size(), 18, "dezoito habilidades gerais")
	t.igual(gerais.filter(func(c): return c["xp"] == 0.5 and c["meia_carta"] and c["lados"][1] == null).size(), 6, "seis meias-cartas")
	t.igual(criaturas.size(), 6, "seis criaturas")
	for c in criaturas:
		var a: Dictionary = c["lados"][0]
		var b: Dictionary = c["lados"][1]
		t.igual(c["xp"], 1, "cada vínculo custa 1 XP")
		t.igual(c["raridade"], "Comum", "raridade confirmada")
		t.igual(a["custo"]["fadiga"], a["criatura"]["fadiga_criar"], "custo de chamada vem do perfil")
		t.igual(a["custo"]["acao"], "padrao", "chamar usa ação Padrão")
		t.igual(b["nome"], "Recuperar o Vínculo", "verso de recuperação")
		t.ok(b.has("dificuldade_medicina") and b["dificuldade_medicina"] == null, "dificuldade de Medicina em aberto")
		t.igual(b["pocao_exigida"], "Poção de cura comum", "alternativa confirmada")
		t.ok(not c["virada_normal_permitida"] and not c["preparo_permitido"], "a carta exige o procedimento")
	var lobo: Dictionary = Catalogo.habilidade("classe.invocador.lobo-atroz")["lados"][0]["criatura"]
	t.igual(lobo["vida"], 25, "Vida do Lobo Atroz")
	t.ok(lobo["habilidade"].contains("Antes de iniciar o teste"), "redação v04 do Ferimento")


func test_ficha_pronta_do_invocador_testa_lobo_e_ave(t) -> void:
	var ficha := Prontos.ficha("Invocador")
	t.ok(Personagem.validar(ficha).is_empty(), "ficha pronta válida")
	t.igual(ficha["herois"][0], "classe.invocador.heroi.adestrador-arcano", "Adestrador Arcano")
	t.igual(Personagem.custo_xp(ficha), 2, "dois vínculos adquiridos")
	var cfg := Personagem.cartas_em_jogo_cfg(ficha).filter(func(c): return c["tipo"] == "criatura")
	t.igual(cfg.map(func(c): return c["id_fonte"]), ["IN-G01", "IN-G07"], "Lobo e Ave são cartas distintas")
	t.igual(cfg[1]["lados"][0]["criatura"]["velocidade"], 6, "perfil acompanha a carta em jogo")
	t.ok(cfg[0]["lados"][0]["texto"].contains("Vida 25"), "perfil visível")
	t.igual(cfg[0]["lados"][1]["slug"], "recuperar-o-vinculo", "verso disponível pelo procedimento")
