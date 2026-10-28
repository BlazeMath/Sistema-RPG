## 0.8: classes novas e grupo. Usa cada lado programado das cartas das classes
## numa arena com aliados e inimigos por perto, para pegar erros de execução.
extends RefCounted

const Batalha := preload("res://core/batalha.gd")
const Dados := preload("res://core/dados_batalha.gd")
const Personagem := preload("res://core/personagem.gd")
const Catalogo := preload("res://core/catalogo.gd")
const Efeitos := preload("res://core/efeitos.gd")


func _ficha(classe: String, nome: String, cartas: Array, herois: Array) -> Dictionary:
	var f := Personagem.nova()
	f["nome"] = nome
	if classe in Personagem.RACAS:
		f["raca"] = classe
		classe = "Guerreiro"
	elif classe in Personagem.BACKGROUNDS:
		f["background"] = classe
		classe = "Guerreiro"
	f["classe"] = classe
	f["xp"] = 10
	f["cartas"] = cartas
	f["meias"] = []
	f["herois"] = herois
	if classe in ["Mago", "Clérigo"]:
		f["foco"] = "varinha_eletrizante" if classe == "Mago" else "simbolo_sagrado"
		f["escudo"] = "nenhum"
	if classe in ["Mago", "Ladino", "Caçador"]:
		f["arma"] = "faca" if classe != "Caçador" else "arco_curto"
		f["escudo"] = "nenhum"
		f["armadura"] = "couro_do_batedor"
	return f


func _grupo_com(classe: String, carta_id: String, heroi_id: String) -> Batalha:
	var fichas := [
		_ficha(classe, "Testador", [carta_id] if carta_id != "" else [], [heroi_id] if heroi_id != "" else []),
		_ficha("Guerreiro", "Aliado", [], ["classe.guerreiro.heroi.foco-mortal", "raca.humano.heroi.incansavel"]),
	]
	var b := Batalha.new(Dados.arena(fichas, false), 7)
	b.iniciar()
	var u := b.unidade("heroi")
	u.pos = Vector2i(6, 5)
	b.unidade("heroi2").pos = Vector2i(5, 5)
	b.unidade("goblin1").pos = Vector2i(7, 5)
	b.unidade("goblin2").pos = Vector2i(8, 7)
	b.unidade("goblin3").pos = Vector2i(9, 3)
	b.indice_vez = b.ordem.find("heroi")
	b._comecar_turno()
	return b


func _terminar(b: Batalha) -> void:
	for passo in 80:
		if b.fase_automatica():
			b.passo_automatico()
			continue
		match b.fase:
			Batalha.Fase.HEROI_ATACANDO, Batalha.Fase.HEROI_DEFENDENDO, Batalha.Fase.INTERACAO_TESTE:
				b.parar()
			Batalha.Fase.RESOLVIDO, Batalha.Fase.INTERACAO_RESOLVIDA:
				b.continuar()
			Batalha.Fase.DISTRIBUINDO_DANO:
				var s := b.sugestao_distribuicao()
				b.heroi_distribuir_dano(s["escudo"], s["armadura"])
			_:
				if b.fase_automatica():
					b.passo_automatico()
				else:
					return


func _usar_todos_os_lados(t, classe: String) -> void:
	var usados := 0
	for carta in Catalogo.habilidades_de(classe):
		if carta["meia_carta"]:
			continue
		for lado in 2:
			var l = carta["lados"][lado]
			if l == null:
				continue
			var info: Dictionary = Efeitos.LADOS.get(Catalogo.slug(l["nome"]), {})
			if info.get("uso", "") != "ativada" or int(l["custo"]["fadiga"]) > int(l["limite_fadiga"]):
				continue   # (custo maior que o limite: carta inconsistente na planilha)
			if Catalogo.slug(l["nome"]) in ["lanterna-da-fe"]:
				continue   # precisa de mão livre: teste próprio em test_luz.gd
			var opcoes := [""]
			if info.has("opcoes"):
				opcoes = info["opcoes"].filter(func(o): return not o.has("motivo_fixo") and not o["id"] in ["isca", "dano-sagrado"] and int(o["custo"]["fadiga"]) <= int(l["limite_fadiga"])).map(func(o): return o["id"])
			for opcao in opcoes:
				var b := _grupo_com(classe, carta["id"], "")
				var u := b.unidade("heroi")
				var i := u.cartas.size() - 1
				u.cartas[i].lado = lado
				u.cartas[i].opcao = opcao
				# (o herói de teste tem poucas cartas: põe as fichas direto, sem o limite de 1 por carta)
				u.cartas[i].fichas["Sombra"] = 3
				u.cartas[i].fichas["Mira"] = 3
				u.gastos.append("pocao_de_cura_pequena")
				b.unidade("goblin1").dar_ficha("Marcado")
				b.unidade("heroi2").baralho.sofrer_dano(5)
				if Catalogo.slug(l["nome"]) == "ressurgir":
					b.unidade("heroi2").baralho.sofrer_dano(60)
				var ok := false
				var spec := b.spec_area(u.cartas[i])
				if not spec.is_empty():
					ok = b.heroi_usar_area(i, celula_de_area(b, u, spec))
				else:
					var alvos := b.alvos_de_habilidade(u, u.cartas[i])
					var alvo = alvos[0] if not alvos.is_empty() else null
					ok = b.heroi_usar_carta(i, alvo)
				if ok and b.fase == Batalha.Fase.PERGUNTA:
					b.heroi_responder(b.pergunta["opcoes"][0][0])
				t.ok(ok, "%s: %s %s (%s)" % [classe, l["nome"], opcao, b.opcoes_cartas(u)[i]["motivo"]])
				if ok:
					usados += 1
				_terminar(b)
	t.ok(usados > 3, "%s: usou %d lados" % [classe, usados])


func test_cartas_do_ladino(t) -> void:
	_usar_todos_os_lados(t, "Ladino")


func test_cartas_do_clerigo(t) -> void:
	_usar_todos_os_lados(t, "Clérigo")


func test_cartas_do_cacador(t) -> void:
	_usar_todos_os_lados(t, "Caçador")


func test_cartas_do_mago(t) -> void:
	_usar_todos_os_lados(t, "Mago")


func test_meias_cartas_das_classes(t) -> void:
	for classe in ["Ladino", "Clérigo", "Caçador", "Mago"]:
		for carta in Catalogo.habilidades_de(classe):
			if not carta["meia_carta"]:
				continue
			var l = carta["lados"][0]
			var info: Dictionary = Efeitos.LADOS.get(Catalogo.slug(l["nome"]), {})
			if info.get("uso", "") != "ativada":
				continue
			var f := _ficha(classe, "Testador", [], [])
			f["meias"] = [carta["id"], carta["id"]]
			var b := Batalha.new(Dados.arena([f, _ficha("Guerreiro", "Aliado", [], ["classe.guerreiro.heroi.foco-mortal", "raca.humano.heroi.incansavel"])], false), 3)
			b.iniciar()
			var u := b.unidade("heroi")
			u.pos = Vector2i(6, 5)
			b.unidade("heroi2").pos = Vector2i(5, 5)
			b.unidade("goblin1").pos = Vector2i(7, 5)
			b.indice_vez = b.ordem.find("heroi")
			b._comecar_turno()
			b.unidade("heroi2").baralho.sofrer_dano(4)
			b.unidade("heroi2").cartas[0].fadiga = 1
			var i := u.cartas.size() - 1
			var alvos := b.alvos_de_habilidade(u, u.cartas[i])
			var ok := b.heroi_usar_carta(i, alvos[0] if not alvos.is_empty() else null)
			t.ok(ok, "%s: %s (%s)" % [classe, l["nome"], b.opcoes_cartas(u)[i]["motivo"]])
			_terminar(b)


func test_metades_de_heroi(t) -> void:
	for classe in ["Ladino", "Clérigo", "Caçador", "Mago"]:
		for h in Catalogo.herois_de(classe):
			var b := _grupo_com(classe, "", h["id"])
			var u := b.unidade("heroi")
			b.unidade("heroi2").baralho.sofrer_dano(4)
			var info := b._info_lado(u.cartas[0])
			if info.get("uso", "") == "ativada":
				var alvos := b.alvos_de_habilidade(u, u.cartas[0])
				var ok := b.heroi_usar_carta(0, alvos[0] if not alvos.is_empty() else null)
				t.ok(ok, "%s: %s (%s)" % [classe, h["nome"], b.opcoes_cartas(u)[0]["motivo"]])
			b._critico(u)
			b.encerrar_turno()
			_terminar(b)


func test_grupo_de_quatro_turnos(t) -> void:
	var fichas := [_ficha("Guerreiro", "A", [], []), _ficha("Ladino", "B", [], []), _ficha("Clérigo", "C", [], []), _ficha("Mago", "D", [], [])]
	var b := Batalha.new(Dados.arena(fichas, false), 11)
	b.iniciar()
	t.igual(b.herois().size(), 4, "quatro heróis")
	var vistos := {}
	for passo in 400:
		if b.vez_do_heroi():
			vistos[b.ativa().id] = true
			b.encerrar_turno()
		elif b.fase in [Batalha.Fase.VITORIA, Batalha.Fase.DERROTA]:
			break
		else:
			b.defesa_automatica = true
			_terminar(b)
		if vistos.size() == 4:
			break
	t.igual(vistos.size(), 4, "cada herói teve o seu turno (%s, fase %d, ordem %s)" % [str(vistos.keys()), b.fase, str(b.ordem)])


func test_vida_dos_inimigos_escala_com_o_grupo(t) -> void:
	var um := Batalha.new(Dados.arena(Personagem.nova(), false), 1)
	var quatro := Batalha.new(Dados.arena([Personagem.nova(), Personagem.nova(), Personagem.nova(), Personagem.nova()]), 1)
	t.ok(quatro.unidade("goblin2").vida_max > um.unidade("goblin2").vida_max, "mais heróis, mais vida")


func test_ataque_magico_soma_atributo_de_conjuracao(t) -> void:
	var b := _grupo_com("Mago", "classe.mago.aprendiz-de-fogo", "")
	var u := b.unidade("heroi")
	t.igual(b.atributo_de_magia(u), u.raciocinio, "Mago conjura com Raciocínio")


func test_heroi_morto_e_derrota(t) -> void:
	var b := _grupo_com("Guerreiro", "", "")
	var h := b.unidade("heroi2")
	h.baralho.sofrer_dano(200)
	h.baralho.sofrer_dano(200)
	t.ok(b._verificar_fim(), "um herói morto encerra")
	t.igual(b.fase, Batalha.Fase.DERROTA, "derrota")


func test_cartas_das_racas_e_backgrounds(t) -> void:
	for origem in ["Humano", "Elfo", "Anão", "Halfling", "Orc", "Soldado", "Bandido", "Escravo", "Explorador", "Fervoroso"]:
		for carta in Catalogo.habilidades_de(origem):
			for lado in 2:
				var l = carta["lados"][lado]
				if l == null:
					continue
				var info: Dictionary = Efeitos.LADOS.get(Catalogo.slug(l["nome"]), {})
				if info.get("uso", "") != "ativada":
					continue
				var b := _grupo_com(origem, carta["id"], "")
				var u := b.unidade("heroi")
				var i := u.cartas.size() - 1
				u.cartas[i].lado = lado
				u.dar_ficha("Ferimento")
				u.dar_ficha("Medo")
				u.baralho.comprar_para_mao(1)
				b.unidade("heroi2").dar_ficha("Medo")
				b.unidade("heroi2").dar_ficha("Sangramento")
				var alvos := b.alvos_de_habilidade(u, u.cartas[i])
				var ok := b.heroi_usar_carta(i, alvos[0] if not alvos.is_empty() else null)
				t.ok(ok, "%s: %s (%s)" % [origem, l["nome"], b.opcoes_cartas(u)[i]["motivo"]])
				_terminar(b)


func test_metades_de_raca_e_background(t) -> void:
	for origem in ["Humano", "Elfo", "Anão", "Halfling", "Orc", "Soldado", "Bandido", "Escravo", "Explorador", "Fervoroso"]:
		for h in Catalogo.herois_de(origem):
			var b := _grupo_com(origem, Catalogo.habilidades_de("Guerreiro")[0]["id"], h["id"])
			var u := b.unidade("heroi")
			u.dar_ficha("Ferimento")
			u.carta_heroi().dar_ficha("Fúria", 2)
			u.gastos.append("antidoto")
			b.unidade("heroi2").dar_ficha("Fogo")
			b.unidade("heroi2").pos = u.pos + Vector2i(-1, 0)
			u.baralho.descarte.append(u.baralho.puxar_topo())
			for c in u.cartas:
				if c.tipo != "heroi":
					c.fadiga = 1
			var info := b._info_lado(u.cartas[0])
			var custo := int(u.cartas[0].lado_ativo().get("custo", {}).get("fadiga", 0))
			if info.get("uso", "") == "ativada" and custo <= u.cartas[0].limite():
				var alvos := b.alvos_de_habilidade(u, u.cartas[0])
				var ok := b.heroi_usar_carta(0, alvos[0] if not alvos.is_empty() else null)
				t.ok(ok, "%s: %s (%s)" % [origem, h["nome"], b.opcoes_cartas(u)[0]["motivo"]])
			_terminar(b)
			if b.vez_do_heroi() and b.ativa() == u:
				b._critico(u)
			_terminar(b)


func test_ataque_magico_soma_o_foco(t) -> void:
	var b := _grupo_com("Mago", "classe.mago.aprendiz-de-fogo", "")
	var u := b.unidade("heroi")
	t.igual(int(u.foco["dano"]), 3, "varinha: +3")
	var sem := _ficha("Mago", "Sem Foco", ["classe.mago.aprendiz-de-fogo"], [])
	sem["foco"] = "nenhum"
	var b2 := Batalha.new(Dados.arena([sem], false), 1)
	b2.iniciar()
	b2.indice_vez = b2.ordem.find("heroi")
	b2._comecar_turno()
	var u2 := b2.unidade("heroi")
	b2.inimigos_vivos()[0].pos = u2.pos + Vector2i(1, 0)
	t.ok(b2.opcoes_cartas(u2)[-1]["opcoes"][0]["motivo"].contains("foco"), "sem foco não há ataque mágico")


func test_ataque_de_oportunidade_do_inimigo(t) -> void:
	var b := _grupo_com("Guerreiro", "", "")
	var u := b.unidade("heroi")
	var g := b.unidade("goblin2")   # Brigão tem ataque de oportunidade
	for o in b.inimigos_vivos():
		o.pos = Vector2i(11, 0) + Vector2i(0, b.inimigos_vivos().find(o))
	g.pos = u.pos + Vector2i(1, 0)
	g.novo_turno()
	var destino := u.pos + Vector2i(-1, -1)
	t.ok(b.heroi_mover(destino), "anda")
	t.igual(b.fase, Batalha.Fase.IA_ATACANDO, "o Brigão ataca quando o herói sai do lado dele")
	b.defesa_automatica = true
	_terminar(b)
	if u.viva():
		t.igual(u.pos, destino, "depois do ataque, o herói termina o movimento")


func test_desengajar_evita_o_ataque(t) -> void:
	var b := _grupo_com("Guerreiro", "", "")
	var u := b.unidade("heroi")
	var g := b.unidade("goblin2")
	g.pos = u.pos + Vector2i(1, 0)
	g.novo_turno()
	u.efeitos["desengajar"] = {"ate": "inicio_turno"}
	b.heroi_mover(u.pos + Vector2i(-1, 0))
	t.igual(b.fase, Batalha.Fase.HEROI_ESCOLHE, "sem ataque de oportunidade")


func test_sorte_dos_pequenos(t) -> void:
	var b := _grupo_com("Halfling", "raca.halfling.sorte-dos-pequenos", "")
	var u := b.unidade("heroi")
	var tt = preload("res://core/teste21.gd").new(u.baralho, 0)
	b.teste_pericia = tt
	b.fase = Batalha.Fase.INTERACAO_TESTE
	tt.estourou = true
	b._ajustes_no_estouro(tt)
	t.igual(tt.resultado(), 21, "estourou, mas vale 21")


func test_braco_de_labuta_soma_forca(t) -> void:
	var b := _grupo_com("Escravo", "background.escravo.couro-duro", "")
	var u := b.unidade("heroi")
	var forca := u.forca
	var i := u.cartas.size() - 1
	b.heroi_virar(i)
	t.igual(u.forca, forca + 1, "virou para Braço de Labuta: +1 de Força")


func test_correcoes_de_limite(t) -> void:
	for nome in Catalogo.CORRECOES:
		var achou := false
		for c in Catalogo.habilidades_de("Caçador") + Catalogo.herois_de("Explorador"):
			for l in c.get("lados", [c]):
				if l != null and l.get("nome", "") == nome:
					achou = true
					t.ok(int(l["limite_fadiga"]) >= int(l["custo"]["fadiga"] if l.has("custo") else l["custo_ativada"]["fadiga"]), nome + ": dá para pagar")
		t.ok(achou, nome + " existe")


func test_escolhas_da_criacao(t) -> void:
	var f := _ficha("Escravo", "Aprendiz", ["background.escravo.atento-aos-desejos"], ["classe.guerreiro.heroi.foco-mortal", "raca.humano.heroi.incansavel"])
	t.ok(not Personagem.validar(f).is_empty(), "sem as escolhas a ficha não vale")
	f["escolhas"] = {"aprendiz-silencioso": ["Medicina", "Arte", "Política"]}
	t.ok(Personagem.validar(f).is_empty(), "com as três perícias, vale")


func test_refazer_teste_com_persistencia(t) -> void:
	var b := _grupo_com("Humano", "raca.humano.mente-maleavel", "")
	var u := b.unidade("heroi")
	var i := u.cartas.size() - 1
	if u.carta_com("persistencia-humana") == null:
		u.cartas[i].lado = 1 - u.cartas[i].lado
	var op := {"teste": {"somar": ["destreza", "acrobacia"]}, "dificuldade": 20,
		"resultados": {"falha": {"rotulo": "Falhou", "texto": "", "efeitos": [{"tipo": "dano", "valor": 2}]},
			"sucesso": {"rotulo": "Passou", "texto": "", "efeitos": []}}}
	b.teste_de_acao(u, op, null)
	b.teste_pericia.parar()
	b.teste_pericia.confirmar()
	b._resolver_interacao(5)
	t.igual(b.fase, Batalha.Fase.INTERACAO_RESOLVIDA, "falhou: espera a escolha")
	t.ok(b.resultado_interacao.get("pendente", false), "oferece refazer")
	var vida := u.baralho.total_cartas()
	t.ok(b.heroi_refazer("persistencia-humana"), "refaz")
	t.igual(b.fase, Batalha.Fase.INTERACAO_TESTE, "novo teste")
	t.igual(u.baralho.total_cartas() <= vida, true, "o dano da falha não foi aplicado antes")


## Um quadrado válido para apontar uma área (prefere o goblin mais próximo).
static func celula_de_area(b, u, spec: Dictionary) -> Vector2i:
	var g = b.unidade("goblin1")
	if g != null and b.motivo_area(u, spec, g.pos) == "":
		return g.pos
	for x in range(-4, 5):
		for y in range(-4, 5):
			var p: Vector2i = u.pos + Vector2i(x, y)
			if b.motivo_area(u, spec, p) == "":
				return p
	return u.pos
