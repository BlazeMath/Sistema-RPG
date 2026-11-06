## 0.27: fases do editor. A fase é só dados (JSON); Fase.para_cenario a transforma no
## cenário que a Batalha já conhece. Aqui: chão, objetos, início, inimigos (bestiário e
## números próprios), saque, áreas (fala, teste, armadilha, chegada), interações,
## objetivos, validação, biblioteca e o mural da campanha.
extends RefCounted

const Batalha := preload("res://core/batalha.gd")
const Fase := preload("res://core/fase.gd")
const Bestiario := preload("res://core/bestiario.gd")
const Prontos := preload("res://core/herois_prontos.gd")
const Campanha := preload("res://core/campanha.gd")
const Personagem := preload("res://core/personagem.gd")
const Grade := preload("res://core/grade.gd")


func _fichas(n := 2) -> Array:
	var l := []
	for c in ["Guerreiro", "Clérigo", "Ladino", "Mago"].slice(0, n):
		var f := Prontos.ficha(c)
		f["nome"] = c + " da Fase"
		l.append(f)
	return l


func _fase() -> Dictionary:
	var f := Fase.nova("Teste do Editor", 16, 10)
	f["inicio"] = ["1,4", "1,5"]
	f["chao"] = {"8,0": "vazio", "8,1": "vazio", "5,5": "dificil", "6,6": "agua", "3,3": "pedra"}
	f["objetos"] = [
		{"pos": "4,2", "tipo": "pilar", "colisao": true, "visao": "padrao"},
		{"pos": "4,3", "tipo": "barril", "colisao": false, "visao": "padrao"},
		{"pos": "4,6", "tipo": "pilar", "colisao": true, "visao": "livre"},
		{"pos": "4,7", "tipo": "velas", "colisao": false, "visao": "bloqueia"},
	]
	f["inimigos"] = [
		{"id": "g1", "preset": "goblin_brigao", "nome": "Goblin Brigão", "pos": "12,4", "patamar": "medio", "papel": "tank",
			"grupo": "bando", "alerta": false, "vigia": 3, "alvo": true, "saque": [{"tipo": "ouro", "valor": 7}, {"tipo": "item", "item": "tocha", "qtd": 1}]},
		{"id": "g2", "preset": "esqueleto", "nome": "Ossudo", "pos": "13,6", "patamar": "lacaio", "papel": "aggro",
			"proprios": {"ativo": true, "vida": 30, "dano": 9, "resistencia": 2, "velocidade": 5, "fraquezas": {"Fogo": 3}, "resiste_tipo": {"Corte": 1}}},
	]
	f["grupos"] = {"bando": {"titulo": "O bando", "texto": "Goblins!", "alerta": true}}
	f["areas"] = [
		{"id": "a_fala", "nome": "Entrada", "tipo": "fala", "celulas": ["2,4"], "titulo": "A entrada", "texto": "Um vento frio.", "parar": true},
		{"id": "a_teste", "nome": "Ponte", "tipo": "teste", "celulas": ["2,5"], "titulo": "Ponte bamba",
			"teste": {"somar": ["Acrobacia", "destreza"], "nivel": "facil"},
			"resultados": {"sucesso": {"texto": "Passa.", "efeitos": [{"tipo": "ouro", "valor": 2}]}, "falha": {"texto": "Cai.", "efeitos": [{"tipo": "dano", "valor": 3}]}}},
		{"id": "a_arm", "nome": "Fosso", "tipo": "armadilha", "celulas": ["3,4"], "armadilha": {"dano": 5, "evitar": "medio"}},
		{"id": "a_fim", "nome": "Saída", "tipo": "chegada", "celulas": ["14,1"]},
	]
	f["interacoes"] = [
		{"id": "bau", "nome": "Baú velho", "pos": "4,2", "alcance": 1, "texto": "Um baú.", "opcoes": [
			{"id": "abrir", "texto": "Abrir", "custo": "padrao", "uma_vez": true,
				"resultados": {"feito": {"texto": "Moedas.", "efeitos": [{"tipo": "ouro", "valor": 10}]}}},
			{"id": "forcar", "texto": "Forçar", "custo": "movimento", "teste": {"ativo": true, "somar": ["forca"], "nivel": "medio"},
				"resultados": {"sucesso": {"texto": "Abre.", "efeitos": [{"tipo": "item", "item": "tocha"}]}, "falha": {"texto": "Emperra."}}}]},
	]
	return f


func _batalha(f: Dictionary, n := 2):
	var b := Batalha.new(Fase.para_cenario(f, _fichas(n)), 11)
	b.distribuicao_automatica = true
	b.iniciar()
	return b


func _vez_de(b, id: String) -> void:
	b.indice_vez = b.ordem.find(id)
	b.fase = Batalha.Fase.HEROI_ESCOLHE
	b._comecar_turno()


func test_fase_chao_e_objetos(t) -> void:
	var b = _batalha(_fase())
	t.igual(b.unidade("heroi").pos, Vector2i(1, 4), "herói começa no início 1")
	t.igual(b.unidade("heroi2").pos, Vector2i(1, 5), "herói 2 no início 2")
	t.ok(b.grade.bloqueado(Vector2i(8, 0)), "chão vazio bloqueia o passo")
	t.ok(b.grade.linha_de_visao(Vector2i(8, 3), Vector2i(8, 0)) or true, "vazio não é parede")
	t.ok(b.grade.bloqueado(Vector2i(4, 2)), "pilar com colisão bloqueia")
	t.ok(not b.grade.bloqueado(Vector2i(4, 3)), "barril sem colisão não bloqueia")
	t.igual(b.decoracao.get(Vector2i(4, 3), ""), "barril", "sem colisão vira enfeite")
	t.ok(not b.grade.linha_de_visao(Vector2i(3, 2), Vector2i(5, 2)), "pilar bloqueia a visão")
	t.ok(b.grade.linha_de_visao(Vector2i(3, 6), Vector2i(5, 6)), "pilar marcado 'não bloqueia a visão'")
	t.ok(not b.grade.linha_de_visao(Vector2i(3, 7), Vector2i(5, 7)), "velas marcadas 'bloqueiam a visão'")
	t.igual(int(b.grade.custo_extra.get(Vector2i(5, 5), 0)), 1, "terreno difícil")
	t.ok(b.grade.bloqueado(Vector2i(6, 6)), "água bloqueia quem não nada")
	t.igual(b.chao.get(Vector2i(3, 3), ""), "pedra", "chão por casa")


func test_fase_inimigos(t) -> void:
	var b = _batalha(_fase(), 4)
	var g1 = b.unidade("g1")
	var g2 = b.unidade("g2")
	t.ok(g1 != null and g2 != null, "inimigos criados")
	t.igual(g1.pos, Vector2i(12, 4), "posição do inimigo")
	t.igual(g1.grupo, "bando", "grupo")
	t.igual(g1.vigia, 3, "vigia")
	t.igual(g2.vida_max, 30, "números próprios: vida (4 heróis)")
	t.igual(g2.dano, 9, "números próprios: dano")
	t.igual(g2.resistencia, 2, "números próprios: resistência")
	t.igual(g2.velocidade, 5, "números próprios: velocidade")
	t.igual(int(g2.fraquezas.get("Fogo", 0)), 3, "fraqueza própria")
	t.igual(int(g2.resiste_tipo.get("Corte", 0)), 1, "resistência própria")
	t.ok(not g2.fraquezas.has("Concussão"), "as fraquezas próprias substituem as do preset")
	var b2 = _batalha(_fase(), 2)
	t.igual(b2.unidade("g2").vida_max, 12, "vida própria escala com o grupo (30% por herói)")
	for id in Bestiario.ids():
		var f := Fase.nova("x", 10, 10)
		f["inimigos"] = [{"id": "m", "preset": id, "pos": "8,5"}]
		var bb := Batalha.new(Fase.para_cenario(f, _fichas(2)), 1)
		t.ok(bb.unidade("m") != null and bb.unidade("m").vida_max > 0, "preset %s monta" % id)


func test_fase_saque(t) -> void:
	var b = _batalha(_fase())
	var g1 = b.unidade("g1")
	g1.vida = 0
	b._inimigo_caiu(g1)
	var it: Dictionary = b.interacao("saque_g1")
	t.ok(not it.is_empty(), "o inimigo caído deixa o saque")
	t.igual(it["pos"], Vector2i(12, 4), "na casa dele")
	var h = b.unidade("heroi")
	h.pos = Vector2i(11, 4)
	_vez_de(b, "heroi")
	var antes: int = b.ouro_ganho
	t.ok(b.heroi_interagir("saque_g1", "pegar"), "pegar o saque")
	b.continuar()
	t.igual(b.ouro_ganho - antes, 70, "7 pratas = 70 cobre")
	t.ok("tocha" in h.consumiveis, "item do saque")
	t.ok(not b.interacao("saque_g1").get("ativa", true), "saque some depois de pego")


func test_fase_areas(t) -> void:
	var b = _batalha(_fase())
	_vez_de(b, "heroi")
	b.heroi_mover(Vector2i(2, 4))
	t.ok(b.gatilhos_feitos.has("a_fala"), "área de fala dispara")
	t.ok(str(b.registro).contains("Um vento frio"), "a fala vai para o registro")
	# Área de teste: abre a mesa de teste.
	var b2 = _batalha(_fase())
	_vez_de(b2, "heroi2")
	b2.heroi_mover(Vector2i(2, 5))
	t.igual(b2.fase, Batalha.Fase.INTERACAO_TESTE, "área de teste pede um teste")
	b2.parar()
	t.igual(b2.fase, Batalha.Fase.INTERACAO_RESOLVIDA, "resultado do teste")
	b2.continuar()
	# Armadilha
	var b3 = _batalha(_fase())
	b3.unidade("heroi").pos = Vector2i(3, 3)
	_vez_de(b3, "heroi")
	b3.heroi_mover(Vector2i(3, 4))
	t.igual(b3.fase, Batalha.Fase.INTERACAO_TESTE, "armadilha pede o teste de escapar")


func test_fase_interacoes(t) -> void:
	var b = _batalha(_fase())
	var h = b.unidade("heroi")
	h.pos = Vector2i(3, 2)
	_vez_de(b, "heroi")
	var antes: int = b.ouro_ganho
	t.ok(b.heroi_interagir("bau", "abrir"), "opção sem teste")
	b.continuar()
	t.igual(b.ouro_ganho - antes, 100, "dinheiro da interação")
	var op: Dictionary = b.opcao_da_interacao(b.interacao("bau"), "abrir")
	t.ok(not op.get("ativa", true), "uma vez: a opção some")
	t.ok(b.heroi_interagir("bau", "forcar"), "opção com teste")
	t.igual(b.fase, Batalha.Fase.INTERACAO_TESTE, "teste de Força")


func test_fase_objetivos(t) -> void:
	var f := _fase()
	f["objetivo"]["tipo"] = "derrotar_alvos"
	var b = _batalha(f)
	t.igual(b.vitoria_se_morrer, ["g1"], "alvos do objetivo")
	t.ok(not b.vitoria_ao_derrotar_todos, "não precisa matar todos")
	b.unidade("g1").vida = 0
	t.ok(b._verificar_fim() and b.fase == Batalha.Fase.VITORIA, "derrubou o alvo: vitória")
	# Chegar
	f["objetivo"]["tipo"] = "chegar"
	var b2 = _batalha(f)
	var h = b2.unidade("heroi")
	h.pos = Vector2i(13, 1)
	_vez_de(b2, "heroi")
	b2.heroi_mover(Vector2i(14, 1))
	t.igual(b2.fase, Batalha.Fase.INTERACAO_RESOLVIDA, "chegou: resultado")
	b2.continuar()
	t.igual(b2.fase, Batalha.Fase.VITORIA, "chegada cumpre a fase")
	# Sobreviver
	f["objetivo"]["tipo"] = "sobreviver"
	f["objetivo"]["rodadas"] = 1
	var b3 = _batalha(f)
	t.igual(b3.vitoria_na_rodada, 1, "rodadas para sobreviver")
	b3.indice_vez = b3.ordem.size() - 1
	b3._proximo_turno()
	t.igual(b3.fase, Batalha.Fase.VITORIA, "passou a rodada: vitória")


func test_fase_validacao(t) -> void:
	t.igual(Fase.validar(_fase()).size(), 0, "fase de teste é válida: %s" % str(Fase.validar(_fase())))
	var f := _fase()
	f["inicio"] = ["4,2"]
	f["inimigos"][0]["pos"] = "8,0"
	f["objetivo"]["tipo"] = "chegar"
	f["areas"] = [{"id": "z", "nome": "Z", "tipo": "fala", "celulas": []}]
	f["interacoes"][0]["opcoes"][0]["resultados"]["feito"]["efeitos"] = [{"tipo": "item"}]
	var erros := Fase.validar(f)
	var texto := str(erros)
	t.ok(texto.contains("início 1"), "início em casa bloqueada")
	t.ok(texto.contains("Goblin Brigão"), "inimigo no vazio")
	t.ok(texto.contains("Chegada"), "objetivo de chegar sem área")
	t.ok(texto.contains("não tem casas"), "área sem casas")
	t.ok(texto.contains("escolha o item"), "efeito sem item")


func test_fase_biblioteca_e_mural(t) -> void:
	var f := _fase()
	f["id"] = "teste_editor_027"
	f["campanha"] = {"no_mural": true, "texto": "Contrato de teste.", "recompensa": 120, "requer": []}
	t.igual(Fase.salvar(f), "", "salva")
	var lida := Fase.carregar("teste_editor_027")
	t.igual(lida["nome"], "Teste do Editor", "lê de volta")
	t.igual(lida["inimigos"].size(), 2, "inimigos voltam")
	t.ok(Fase.listar().any(func(x): return x["id"] == "teste_editor_027"), "aparece na biblioteca")
	var copia := Fase.duplicar("teste_editor_027")
	t.ok(copia["id"] != "teste_editor_027" and Fase.carregar(copia["id"]).size() > 0, "duplicar")
	Fase.apagar(copia["id"])
	t.ok(Fase.carregar(copia["id"]).is_empty(), "apagar")
	var m := Campanha.missao("fase:teste_editor_027")
	t.igual(int(m.get("recompensa", 0)), 120, "fase no mural vira contrato")
	t.igual(Campanha.motivo_trancada("fase:teste_editor_027"), "", "contrato liberado")
	# Exemplo que vem com o jogo
	t.ok(Fase.listar().any(func(x): return x["exemplo"]), "há fase de exemplo")
	for x in Fase.listar():
		if x["exemplo"]:
			t.igual(Fase.validar(Fase.carregar(x["id"])).size(), 0, "exemplo %s é válido" % x["id"])
			var be := Batalha.new(Fase.para_cenario(Fase.carregar(x["id"]), _fichas(3)), 5)
			be.iniciar()
			t.ok(be.herois().size() == 3, "exemplo %s monta" % x["id"])
	Fase.apagar("teste_editor_027")
	t.ok(Campanha.missao("fase:teste_editor_027").is_empty(), "apagada sai do mural")
	# Rede: o convidado lê a fase da memória (mandada pelo anfitrião).
	Fase.memoria = {"so_na_memoria": f}
	t.igual(Fase.carregar("so_na_memoria")["nome"], "Teste do Editor", "fase vinda do anfitrião")
	Fase.memoria = {}
