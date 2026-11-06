## Fases criadas no editor (0.27). Uma fase é só dados (JSON): o formato do chão,
## os objetos, as áreas, as interações, os inimigos, o início dos heróis e o
## objetivo. para_cenario() transforma a fase no mesmo dicionário de cenário que as
## missões feitas à mão (core/dados_*.gd) entregam para Batalha.new, então o motor
## inteiro serve igual.
##
## Casas no JSON são textos "x,y" (JSON não guarda Vector2i).
## Biblioteca: user://fases/<id>.json (as do Lucas) e res://data/fases/ (exemplos,
## só leitura: para mudar, duplique).
extends RefCounted

const Dados := preload("res://core/dados_batalha.gd")
const Bestiario := preload("res://core/bestiario.gd")
const Itens := preload("res://core/itens.gd")
const Personagem := preload("res://core/personagem.gd")

const VERSAO := 1
const PASTA := "user://fases"
const EXEMPLOS := "res://data/fases"
const PREFIXO := "fase:"
const MAXIMO := 60

## Tipos de chão. "vazio" = a casa não existe (é o formato do mapa); "agua" vira o
## obstáculo de água (só quem nada atravessa); "dificil" = terreno difícil (custa 2).
const CHAOS := {
	"grama": {"nome": "Grama", "cor": "466639"},
	"pedra": {"nome": "Pedra", "cor": "524f58"},
	"lodo": {"nome": "Lodo", "cor": "3a4630"},
	"terra": {"nome": "Terra", "cor": "6b5139"},
	"madeira": {"nome": "Madeira", "cor": "7a5a36"},
	"areia": {"nome": "Areia", "cor": "b3a06a"},
	"agua": {"nome": "Água", "cor": "336791"},
	"dificil": {"nome": "Terreno difícil", "cor": "5d5a3a"},
	"vazio": {"nome": "Vazio (sem chão)", "cor": "101014"},
}
const PISOS := ["grama", "pedra", "lodo"]   # o piso padrão também escolhe os modelos (ex.: árvore morta no lodo)

## Objetos do cenário: nome, letra no editor, colisão e visão padrão (o editor deixa mudar).
## visão: "bloqueia" (parede, pilar), "baixo" (mesa, cerca: bloqueia o passo, não a visão).
const OBJETOS := {
	"parede": {"nome": "Parede", "letra": "█", "colisao": true, "visao": "bloqueia"},
	"porta": {"nome": "Porta", "letra": "P", "colisao": true, "visao": "bloqueia"},
	"pilar": {"nome": "Pilar", "letra": "I", "colisao": true, "visao": "bloqueia"},
	"rocha": {"nome": "Rocha grande", "letra": "R", "colisao": true, "visao": "bloqueia"},
	"pedra": {"nome": "Pedra", "letra": "o", "colisao": true, "visao": "bloqueia"},
	"pedra_alta": {"nome": "Pedra alta (dá para subir)", "letra": "A", "colisao": true, "visao": "bloqueia"},
	"arvore": {"nome": "Árvore", "letra": "♣", "colisao": true, "visao": "bloqueia"},
	"casa": {"nome": "Casa", "letra": "⌂", "colisao": true, "visao": "bloqueia"},
	"celeiro": {"nome": "Celeiro", "letra": "C", "colisao": true, "visao": "bloqueia"},
	"tenda": {"nome": "Tenda", "letra": "T", "colisao": true, "visao": "bloqueia"},
	"estante": {"nome": "Estante", "letra": "E", "colisao": true, "visao": "bloqueia"},
	"feno": {"nome": "Fardo de feno", "letra": "f", "colisao": true, "visao": "bloqueia"},
	"caixa": {"nome": "Caixa", "letra": "x", "colisao": true, "visao": "bloqueia"},
	"barril": {"nome": "Barril", "letra": "b", "colisao": true, "visao": "bloqueia"},
	"monte_terra": {"nome": "Monte de terra", "letra": "m", "colisao": true, "visao": "bloqueia"},
	"tocha_parede": {"nome": "Tocha na parede (luz)", "letra": "¡", "colisao": true, "visao": "bloqueia"},
	"cerca": {"nome": "Cerca", "letra": "#", "colisao": true, "visao": "baixo"},
	"mesa": {"nome": "Mesa", "letra": "M", "colisao": true, "visao": "baixo"},
	"bau": {"nome": "Baú", "letra": "B", "colisao": true, "visao": "baixo"},
	"sarcofago": {"nome": "Sarcófago", "letra": "S", "colisao": true, "visao": "baixo"},
	"altar": {"nome": "Altar", "letra": "+", "colisao": true, "visao": "baixo"},
	"fonte": {"nome": "Fonte", "letra": "~", "colisao": true, "visao": "baixo"},
	"poco": {"nome": "Poço", "letra": "O", "colisao": true, "visao": "baixo"},
	"saco": {"nome": "Saco", "letra": "s", "colisao": true, "visao": "baixo"},
	"tronco": {"nome": "Tronco caído", "letra": "=", "colisao": true, "visao": "baixo"},
	"fogueira": {"nome": "Fogueira (luz)", "letra": "*", "colisao": true, "visao": "baixo"},
	"fogueira_apagada": {"nome": "Fogueira apagada", "letra": "·", "colisao": true, "visao": "baixo"},
	"escombro": {"nome": "Escombros", "letra": "%", "colisao": true, "visao": "baixo"},
	"lapide": {"nome": "Lápide", "letra": "†", "colisao": true, "visao": "baixo"},
	"npc": {"nome": "Pessoa parada (NPC)", "letra": "☺", "colisao": true, "visao": "baixo"},
	"velas": {"nome": "Velas", "letra": "i", "colisao": false, "visao": "baixo"},
	"caveira_vela": {"nome": "Caveira com vela", "letra": "☠", "colisao": false, "visao": "baixo"},
	"lanterna_chao": {"nome": "Lanterna no chão", "letra": "¤", "colisao": false, "visao": "baixo"},
	"saco_de_dormir": {"nome": "Saco de dormir", "letra": "_", "colisao": false, "visao": "baixo"},
	"ponte": {"nome": "Ponte (tábuas no chão)", "letra": "≡", "colisao": false, "visao": "baixo"},
}
## Objetos que acendem (iguais aos do jogo: Batalha.LUZES) mesmo quando sem colisão.
const LUZ_DE_OBJETO := {"fogueira": [3, 6], "tocha_parede": [3, 6], "lanterna_chao": [2, 4], "velas": [1, 3], "caveira_vela": [1, 2]}

const TIPOS_DE_AREA := {
	"fala": "Fala (texto ao entrar)",
	"teste": "Teste (pede um teste ao entrar)",
	"efeito": "Acontecimento (efeitos ao entrar)",
	"armadilha": "Armadilha",
	"chegada": "Chegada (objetivo: chegar aqui)",
}
const OBJETIVOS := {
	"derrotar_todos": "Derrotar todos os inimigos",
	"derrotar_alvos": "Derrotar os inimigos marcados como alvo",
	"chegar": "Chegar a uma área de chegada",
	"interagir": "Cumprir uma interação (efeito Vitória)",
	"sobreviver": "Sobreviver um número de rodadas",
}
const CUSTOS := {"nenhum": "Sem custo", "movimento": "1 ação de Movimento", "padrao": "1 ação Padrão", "turno": "O turno inteiro"}
const NIVEIS := {"muito_facil": "Muito fácil", "facil": "Fácil", "medio": "Médio", "dificil": "Difícil", "muito_dificil": "Muito difícil"}
const NIVEL_VALOR := {"muito_facil": 12, "facil": 14, "medio": 16, "dificil": 18, "muito_dificil": 20}
const ATRIBUTOS := {"forca": "Força", "destreza": "Destreza", "constituicao": "Constituição", "percepcao": "Percepção",
	"sabedoria": "Sabedoria", "raciocinio": "Raciocínio", "espirito": "Espírito", "mentira": "Mentira", "diplomacia": "Diplomacia"}
const FICHAS := ["Foco", "Preparo", "Bloqueio", "Sombra", "Mira", "Fúria", "Medo", "Sangramento", "Veneno", "Fogo",
	"Imobilizar", "Ferimento", "Penalidade", "Cegueira", "Confusão", "Atordoamento"]

## Efeitos que o editor oferece. Campos: [chave, tipo, rótulo]. Tipos: int, texto,
## texto_longo, item, ficha, grupo, interacao, inimigo, casas, missao.
const EFEITOS := {
	"ouro": {"nome": "Dinheiro (pratas)", "campos": [["valor", "int", "Pratas"]]},
	"item": {"nome": "Item", "campos": [["item", "item", "Item"], ["qtd", "int", "Quantidade"]]},
	"dano": {"nome": "Dano no herói", "campos": [["valor", "int", "Dano"]]},
	"ficha": {"nome": "Ficha no herói", "campos": [["ficha", "ficha", "Ficha"]]},
	"fichas_grupo": {"nome": "Ficha para o grupo (até 4 casas)", "campos": [["ficha", "ficha", "Ficha"]]},
	"fadiga": {"nome": "Tirar fadiga", "campos": [["valor", "int", "Quanto"]]},
	"descanso_curto": {"nome": "Descanso curto do grupo", "campos": []},
	"narrar": {"nome": "Fala / narração", "campos": [["titulo", "texto", "Título"], ["texto", "texto_longo", "Texto"]]},
	"lore": {"nome": "História (fica no registro)", "campos": [["texto", "texto_longo", "Texto"]]},
	"alertar": {"nome": "Alertar um grupo de inimigos", "campos": [["grupo", "grupo", "Grupo"], ["texto", "texto", "Texto"]]},
	"retirar": {"nome": "Inimigos vão embora", "campos": [["grupo", "grupo", "Grupo"], ["texto", "texto", "Texto"]]},
	"marcar": {"nome": "Marcar um inimigo (defesa à vista)", "campos": [["id", "inimigo", "Inimigo"]]},
	"abrir_caminho": {"nome": "Abrir caminho (tira obstáculos)", "campos": [["celulas", "casas", "Casas"], ["texto", "texto", "Texto"]]},
	"ativar": {"nome": "Ativar outra interação", "campos": [["id", "interacao", "Interação"], ["texto", "texto", "Texto"]]},
	"desativar": {"nome": "Desativar esta interação", "campos": []},
	"queda": {"nome": "Queda", "campos": [["quadrados", "int", "Altura (quadrados)"]]},
	"desbloquear": {"nome": "Abrir missão no mural", "campos": [["missao", "missao", "Missão"], ["texto", "texto", "Texto"]]},
	"pista": {"nome": "Pista (investigação)", "campos": [["nome", "texto", "Nome da pista"], ["texto", "texto", "O que ela diz"]]},
	"vitoria": {"nome": "Vitória (cumpre a fase)", "campos": [["texto", "texto_longo", "Texto"]]},
}

## Leitura de JSON (a biblioteca) e fases recebidas do anfitrião no jogo em rede.
static var memoria := {}   # id -> fase (convidado em rede; o anfitrião manda)


# --- Casas ------------------------------------------------------------------------

static func casa(texto: String) -> Vector2i:
	var p := str(texto).split(",")
	if p.size() < 2:
		return Vector2i(-1, -1)
	return Vector2i(int(p[0]), int(p[1]))


static func texto_casa(p: Vector2i) -> String:
	return "%d,%d" % [p.x, p.y]


# --- Fase nova e normalização -------------------------------------------------------

static func nova(nome := "Fase nova", largura := 20, altura := 14) -> Dictionary:
	var f := {"versao": VERSAO, "id": id_de(nome), "nome": nome, "descricao": "", "largura": largura, "altura": altura,
		"piso": "grama", "escuro": false, "luz_ambiente": 0, "abertura": {"titulo": "", "texto": ""},
		"chao": {}, "niveis": {}, "escadas": [], "objetos": [], "luzes": [],
		"inicio": ["1,%d" % (altura / 2), "1,%d" % (altura / 2 + 1), "2,%d" % (altura / 2), "2,%d" % (altura / 2 + 1)],
		"inimigos": [], "grupos": {}, "areas": [], "interacoes": [],
		"objetivo": {"tipo": "derrotar_todos", "texto": "Derrote os inimigos.", "rodadas": 8, "mensagem_vitoria": "Missão cumprida."},
		"campanha": {"no_mural": false, "texto": "", "recompensa": 100, "requer": []}}
	return f


## Garante todos os campos (arquivos antigos ou feitos à mão).
static func normalizar(f: Dictionary) -> Dictionary:
	var base := nova(str(f.get("nome", "Fase")), int(f.get("largura", 20)), int(f.get("altura", 14)))
	for k in base:
		if not f.has(k):
			f[k] = base[k]
	for k in ["abertura", "objetivo", "campanha"]:
		for kk in base[k]:
			if not f[k].has(kk):
				f[k][kk] = base[k][kk]
	f["largura"] = clampi(int(f["largura"]), 4, MAXIMO)
	f["altura"] = clampi(int(f["altura"]), 4, MAXIMO)
	# Campos internos que o editor espera (arquivos feitos à mão podem não ter).
	for e in f["inimigos"]:
		_completar(e, {"grupo": "", "alerta": false, "vigia": 4, "dormindo": false, "alvo": false, "saque": [], "proprios": {"ativo": false}})
	for a in f["areas"]:
		_completar(a, {"nome": str(a.get("id", "área")), "tipo": "fala", "celulas": [], "titulo": "", "texto": "", "parar": true, "procurar": false,
			"efeitos": [], "teste": {"somar": ["percepcao"], "nivel": "medio"},
			"resultados": {"sucesso": {"texto": "", "efeitos": []}, "falha": {"texto": "", "efeitos": []}},
			"armadilha": {"dano": 4, "ficha": "", "achar": "medio", "evitar": "medio", "desarmar": "medio", "texto_disparo": "O mecanismo dispara!"}})
		for r in ["sucesso", "falha"]:
			_completar(a["resultados"], {r: {"texto": "", "efeitos": []}})
			_completar(a["resultados"][r], {"texto": "", "efeitos": []})
	for it in f["interacoes"]:
		_completar(it, {"nome": "Ponto", "alcance": 1, "texto": "", "oculta": false, "opcoes": []})
		for o in it["opcoes"]:
			_completar(o, {"texto": "Interagir", "custo": "padrao", "uma_vez": false, "sem_inimigos": false, "requer_item": "", "requer_classe": [], "requer_pistas": 0,
				"teste": {"ativo": false, "somar": ["percepcao"], "nivel": "medio"}, "resultados": {}})
			for r in ["feito", "sucesso", "falha"]:
				_completar(o["resultados"], {r: {"texto": "", "efeitos": []}})
				_completar(o["resultados"][r], {"texto": "", "efeitos": []})
	return f


static func _completar(d: Dictionary, padrao: Dictionary) -> void:
	for k in padrao:
		if not d.has(k):
			d[k] = padrao[k].duplicate(true) if padrao[k] is Dictionary or padrao[k] is Array else padrao[k]


static func id_de(nome: String) -> String:
	var s := ""
	for ch in nome.strip_edges().to_lower():
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"):
			s += ch
		elif ch in "áàâãä": s += "a"
		elif ch in "éèêë": s += "e"
		elif ch in "íìîï": s += "i"
		elif ch in "óòôõö": s += "o"
		elif ch in "úùûü": s += "u"
		elif ch == "ç": s += "c"
		elif not s.ends_with("_"): s += "_"
	s = s.trim_prefix("_").trim_suffix("_")
	return s if s != "" else "fase"


# --- Biblioteca ---------------------------------------------------------------------

static func _ler(caminho: String) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	return normalizar(d) if d is Dictionary else {}


## [{id, nome, exemplo, no_mural, descricao}], as do Lucas primeiro.
static func listar() -> Array:
	var lista := []
	for origem in [[PASTA, false], [EXEMPLOS, true]]:
		var dir := DirAccess.open(origem[0])
		if dir == null:
			continue
		for arq in dir.get_files():
			if not arq.ends_with(".json"):
				continue
			var f := _ler(origem[0] + "/" + arq)
			if f.is_empty():
				continue
			var id := arq.trim_suffix(".json")
			if lista.any(func(x): return x["id"] == id):
				continue
			lista.append({"id": id, "nome": f["nome"], "exemplo": origem[1], "no_mural": bool(f["campanha"].get("no_mural", false)),
				"descricao": f.get("descricao", "")})
	lista.sort_custom(func(a, b): return [a["exemplo"], a["nome"]] < [b["exemplo"], b["nome"]])
	return lista


static func eh_exemplo(id: String) -> bool:
	return not FileAccess.file_exists("%s/%s.json" % [PASTA, id]) and FileAccess.file_exists("%s/%s.json" % [EXEMPLOS, id])


static func carregar(id: String) -> Dictionary:
	if memoria.has(id):
		return normalizar(memoria[id].duplicate(true))
	var f := _ler("%s/%s.json" % [PASTA, id])
	if f.is_empty():
		f = _ler("%s/%s.json" % [EXEMPLOS, id])
	if not f.is_empty():
		f["id"] = id
	return f


static func salvar(f: Dictionary) -> String:
	DirAccess.make_dir_recursive_absolute(PASTA)
	var arq := FileAccess.open("%s/%s.json" % [PASTA, f["id"]], FileAccess.WRITE)
	if arq == null:
		return "Não deu para salvar a fase."
	arq.store_string(JSON.stringify(f, "\t"))
	return ""


static func apagar(id: String) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path("%s/%s.json" % [PASTA, id]))


## Um id livre a partir de um nome ("moinho", "moinho_2"...).
static func id_livre(nome: String) -> String:
	var base := id_de(nome)
	var id := base
	var n := 2
	while FileAccess.file_exists("%s/%s.json" % [PASTA, id]) or FileAccess.file_exists("%s/%s.json" % [EXEMPLOS, id]):
		id = "%s_%d" % [base, n]
		n += 1
	return id


static func duplicar(id: String) -> Dictionary:
	var f := carregar(id)
	if f.is_empty():
		return {}
	f["nome"] = str(f["nome"]) + " (cópia)"
	f["id"] = id_livre(f["nome"])
	salvar(f)
	return f


# --- Campanha ------------------------------------------------------------------------

## Fases marcadas para o mural da guilda, no formato de Campanha.MISSOES.
static func missoes_do_mural() -> Array:
	var lista := []
	var ids := memoria.keys() if not memoria.is_empty() else listar().map(func(x): return x["id"])
	for id in ids:
		var f := carregar(id)
		if f.is_empty() or not bool(f["campanha"].get("no_mural", false)):
			continue
		var m := {"id": PREFIXO + id, "nome": f["nome"], "texto": f["campanha"].get("texto", "") if str(f["campanha"].get("texto", "")) != "" else f.get("descricao", ""),
			"recompensa": int(f["campanha"].get("recompensa", 0)), "requer": f["campanha"].get("requer", []).duplicate()}
		if f["campanha"].has("ciclo") and int(f["campanha"]["ciclo"]) > 0:
			m["ciclo"] = int(f["campanha"]["ciclo"])
		lista.append(m)
	return lista


## Todas as fases do mural (para o anfitrião mandar aos convidados).
static func fases_do_mural() -> Dictionary:
	var d := {}
	for x in listar():
		if x["no_mural"]:
			d[x["id"]] = carregar(x["id"])
	return d


# --- Conversão para o cenário da Batalha ------------------------------------------------

static func _casas(lista) -> Array:
	var l := []
	for c in lista:
		l.append(casa(c) if c is String else c)
	return l


## Efeitos do JSON para o motor: casas viram Vector2i e números viram int.
static func _efeitos(lista: Array) -> Array:
	var l := []
	for e in lista:
		var ef: Dictionary = e.duplicate(true)
		if ef.has("celulas"):
			ef["celulas"] = _casas(ef["celulas"])
		for k in ["valor", "qtd", "quadrados"]:
			if ef.has(k):
				ef[k] = int(ef[k])
		if ef.get("tipo", "") == "vitoria" and str(ef.get("texto", "")) == "":
			ef["texto"] = "Missão cumprida."
		l.append(ef)
	return l


static func _teste(t: Dictionary) -> Dictionary:
	var somar: Array = t.get("somar", ["percepcao"])
	return {"somar": somar.duplicate() if not somar.is_empty() else ["percepcao"]}


## Uma opção de interação (ou a ação de uma área) no formato do motor.
static func _opcao(o: Dictionary) -> Dictionary:
	var op := {"id": str(o.get("id", "op")), "texto": str(o.get("texto", "Interagir"))}
	match str(o.get("custo", "padrao")):
		"movimento": op["custo"] = {"movimento": 1}
		"padrao": op["custo"] = {"padrao": 1}
		"turno": op["custo"] = {"turno": true}
		_: op["custo"] = {}
	if str(o.get("requer_item", "")) != "":
		op["requer"] = str(o["requer_item"])
	if not o.get("requer_classe", []).is_empty():
		op["requer_classe"] = o["requer_classe"].duplicate()
	if o.get("sem_inimigos", false):
		op["sem_alerta"] = true
	if int(o.get("requer_pistas", 0)) > 0:
		op["requer_pistas"] = int(o["requer_pistas"])
	if not o.get("investigador", {}).is_empty():
		op["investigador"] = o["investigador"].duplicate(true)
	var res: Dictionary = o.get("resultados", {})
	var extra := []
	if o.get("uma_vez", false):
		extra.append({"tipo": "desativar_opcao", "opcao": op["id"]})
	if o.get("teste", {}).get("ativo", false):
		op["teste"] = _teste(o["teste"])
		op["nivel"] = str(o["teste"].get("nivel", "medio"))
		var suc: Dictionary = res.get("sucesso", {})
		var fal: Dictionary = res.get("falha", {})
		op["resultados"] = {
			"falha": {"rotulo": "falha", "texto": str(fal.get("texto", "Não deu certo.")), "efeitos": _efeitos(fal.get("efeitos", [])) + extra},
			"sucesso": {"rotulo": "sucesso", "texto": str(suc.get("texto", "Deu certo.")), "efeitos": _efeitos(suc.get("efeitos", [])) + extra},
		}
	else:
		var feito: Dictionary = res.get("feito", res.get("sucesso", {}))
		op["resultado"] = "feito"
		op["resultados"] = {"feito": {"texto": str(feito.get("texto", "Feito.")), "efeitos": _efeitos(feito.get("efeitos", [])) + extra}}
	return op


static func _inimigo(e: Dictionary, n: int) -> Dictionary:
	var pr := Bestiario.preset(str(e.get("preset", "goblin_brigao")))
	var extra: Dictionary = pr.get("extra", {}).duplicate(true)
	extra["alerta"] = bool(e.get("alerta", false))
	extra["vigia"] = int(e.get("vigia", 4))
	if str(e.get("grupo", "")) != "":
		extra["grupo"] = str(e["grupo"])
	if e.get("dormindo", false):
		extra["dormindo"] = true
		extra["alerta"] = false
	var proprios: Dictionary = e.get("proprios", {})
	if proprios.get("ativo", false):
		var vida4 := float(proprios.get("vida", 20))
		extra["vida"] = maxi(int(round(vida4 * maxf(1.0 + 0.3 * (n - 4), 0.1))), 1)
		for k in ["dano", "resistencia", "velocidade"]:
			if proprios.has(k):
				extra[k] = int(proprios[k])
		if proprios.has("ataques_por_turno"):
			extra["padrao_por_turno"] = int(proprios["ataques_por_turno"])
		extra["a_distancia"] = bool(proprios.get("a_distancia", false))
		if extra["a_distancia"]:
			extra["faixas_ideais"] = [0, 1]
		else:
			extra.erase("faixas_ideais")
		extra["ataque_oportunidade"] = bool(proprios.get("ataque_oportunidade", false))
		if extra["ataque_oportunidade"]:
			extra["reacao_por_turno"] = maxi(int(extra.get("reacao_por_turno", 0)), 1)
		for k in ["tamanho", "categoria", "tipo_dano"]:
			if str(proprios.get(k, "")) != "":
				extra[k] = str(proprios[k])
		extra["visao_no_escuro"] = bool(proprios.get("visao_no_escuro", extra.get("visao_no_escuro", false)))
		for k in ["fraquezas", "resiste_tipo"]:
			var d := {}
			for t in proprios.get(k, {}):
				if int(proprios[k][t]) != 0:
					d[t] = int(proprios[k][t])
			extra[k] = d
		if str(proprios.get("perfil", "")) != "":
			extra["perfil_id"] = str(proprios["perfil"])
	# Renomeado no editor: as reações do monstro do bestiário vão junto (elas vêm pelo nome).
	var Reacoes := preload("res://core/reacoes_monstros.gd")
	if str(e.get("nome", pr["nome"])) != str(pr["nome"]) and Reacoes.POR_NOME.has(pr["nome"]) and not extra.has("reacoes"):
		extra["reacoes"] = Reacoes.POR_NOME[pr["nome"]].duplicate(true)
	var cfg := Dados.inimigo_de(str(e["id"]), str(e.get("nome", pr["nome"])), str(pr["modelo"]), casa(str(e["pos"])),
		str(e.get("patamar", pr["patamar"])), str(e.get("papel", pr["papel"])), n, extra)
	if proprios.get("ativo", false):
		# Números próprios valem como escritos (o papel não soma velocidade nem dano por cima).
		for k in ["dano", "resistencia", "velocidade"]:
			if proprios.has(k):
				cfg[k] = int(proprios[k])
	return cfg


## Onde cada herói começa: as casas marcadas; se faltar, a casa livre mais perto.
static func _inicios(f: Dictionary, n: int, bloqueadas: Dictionary) -> Array:
	var l := _casas(f["inicio"]).filter(func(p): return not bloqueadas.has(p))
	var base: Vector2i = l[0] if not l.is_empty() else Vector2i(1, 1)
	var raio := 1
	while l.size() < n and raio < MAXIMO:
		for dx in range(-raio, raio + 1):
			for dy in range(-raio, raio + 1):
				var p := base + Vector2i(dx, dy)
				if l.size() < n and p.x >= 0 and p.y >= 0 and p.x < int(f["largura"]) and p.y < int(f["altura"]) \
						and not bloqueadas.has(p) and not p in l:
					l.append(p)
		raio += 1
	return l


static func para_cenario(f0: Dictionary, fichas) -> Dictionary:
	var f := normalizar(f0.duplicate(true))
	var n := Dados._quantos(fichas)
	var obst := {}
	var deco := {}
	var chao := {}
	var dificil := []
	var visao_livre := []
	var visao_bloqueia := []
	var luzes := []
	for c in f["chao"]:
		var p := casa(c)
		var t: String = f["chao"][c]
		match t:
			"vazio": obst[p] = "vazio"
			"agua": obst[p] = "agua"
			"dificil":
				dificil.append(p)
				chao[p] = t
			_: chao[p] = t
	for o in f["objetos"]:
		var p := casa(str(o["pos"]))
		var t: String = o["tipo"]
		var info: Dictionary = OBJETOS.get(t, {"colisao": true, "visao": "bloqueia"})
		var colisao := bool(o.get("colisao", info["colisao"]))
		var visao: String = str(o.get("visao", "padrao"))
		if colisao:
			obst[p] = t
			if visao == "livre" and info["visao"] == "bloqueia":
				visao_livre.append(p)
			elif visao == "bloqueia" and info["visao"] == "baixo":
				visao_bloqueia.append(p)
		else:
			deco[p] = t
			if visao == "bloqueia":
				visao_bloqueia.append(p)
			if LUZ_DE_OBJETO.has(t):
				luzes.append({"pos": p, "claro": LUZ_DE_OBJETO[t][0], "penumbra": LUZ_DE_OBJETO[t][1], "nome": info.get("nome", t)})
	for l in f["luzes"]:
		luzes.append({"pos": casa(str(l["pos"])), "claro": int(l.get("claro", 2)), "penumbra": int(l.get("penumbra", 4)), "nome": str(l.get("nome", "luz"))})
	var unidades := Dados.herois_cfg(fichas, _inicios(f, n, obst))
	var saques := {}
	var alvos := []
	for e in f["inimigos"]:
		unidades.append(_inimigo(e, n))
		if not e.get("saque", []).is_empty():
			saques[str(e["id"])] = _efeitos(e["saque"])
		if e.get("alvo", false):
			alvos.append(str(e["id"]))
	var gatilhos := []
	var armadilhas := []
	for a in f["areas"]:
		var cels := _casas(a.get("celulas", []))
		if cels.is_empty():
			continue
		var tipo: String = a.get("tipo", "fala")
		if tipo == "armadilha":
			var ar: Dictionary = a.get("armadilha", {})
			armadilhas.append({"id": str(a["id"]), "sala": "", "nome": str(a.get("nome", "Armadilha")), "celulas": cels,
				"dif_achar": NIVEL_VALOR.get(str(ar.get("achar", "medio")), 16), "dif_evitar": NIVEL_VALOR.get(str(ar.get("evitar", "medio")), 16),
				"dif_desarmar": NIVEL_VALOR.get(str(ar.get("desarmar", "medio")), 16), "dano": int(ar.get("dano", 4)),
				"texto": str(a.get("texto", "")), "texto_disparo": str(ar.get("texto_disparo", "O mecanismo dispara!"))})
			if str(ar.get("ficha", "")) != "":
				armadilhas[-1]["ficha"] = str(ar["ficha"])
			continue
		var g := {"id": str(a["id"]), "celulas": cels, "titulo": str(a.get("titulo", "")), "texto": str(a.get("texto", "")),
			"parar": bool(a.get("parar", true)), "procurar": bool(a.get("procurar", false))}
		match tipo:
			"teste":
				var o := {"id": "teste", "texto": str(a.get("titulo", "Teste")), "custo": "nenhum",
					"teste": a.get("teste", {}).merged({"ativo": true}), "resultados": a.get("resultados", {})}
				var op := _opcao(o)
				op["titulo"] = str(a.get("titulo", "Teste"))
				g["acao"] = op
			"efeito":
				var op2 := _opcao({"id": "efeito", "texto": str(a.get("titulo", "")), "custo": "nenhum",
					"resultados": {"feito": {"texto": str(a.get("texto_resultado", a.get("texto", ""))), "efeitos": a.get("efeitos", [])}}})
				op2["titulo"] = str(a.get("titulo", "Acontecimento"))
				g["acao"] = op2
				g["texto"] = ""
			"chegada":
				var msg: String = str(f["objetivo"].get("mensagem_vitoria", "Missão cumprida."))
				var op3 := _opcao({"id": "chegada", "texto": str(a.get("titulo", "Chegada")), "custo": "nenhum",
					"resultados": {"feito": {"texto": str(a.get("texto", msg)), "efeitos": [{"tipo": "vitoria", "texto": msg}]}}})
				op3["titulo"] = str(a.get("titulo", "Chegada"))
				g["acao"] = op3
				g["texto"] = ""
		gatilhos.append(g)
	var interacoes := []
	for it0 in f["interacoes"]:
		var p := casa(str(it0["pos"]))
		var it := {"id": str(it0["id"]), "nome": str(it0.get("nome", "Ponto")), "pos": p, "alcance": int(it0.get("alcance", 1)),
			"texto": str(it0.get("texto", "")), "opcoes": []}
		if not obst.has(p):
			it["chao"] = true
		if it0.get("oculta", false):
			it["oculta"] = true
			it["ativa"] = false
		for o in it0.get("opcoes", []):
			it["opcoes"].append(_opcao(o))
		if it["opcoes"].is_empty():
			it["opcoes"].append(_opcao({"id": "olhar", "texto": "Olhar", "custo": "nenhum", "resultados": {"feito": {"texto": it["texto"]}}}))
		interacoes.append(it)
	var obj: Dictionary = f["objetivo"]
	var tipo_obj: String = obj.get("tipo", "derrotar_todos")
	var niveis := {}
	for c in f["niveis"]:
		if int(f["niveis"][c]) != 0:
			niveis[casa(c)] = int(f["niveis"][c])
	var escadas := {}
	for c in f["escadas"]:
		escadas[casa(c)] = true
	var cen := {
		"nome": str(f["nome"]),
		"objetivo": str(obj.get("texto", "")),
		"vitoria_ao_derrotar_todos": tipo_obj == "derrotar_todos",
		"vitoria_se_morrer": alvos if tipo_obj == "derrotar_alvos" else [],
		"vitoria_na_rodada": int(obj.get("rodadas", 8)) if tipo_obj == "sobreviver" else 0,
		"mensagem_vitoria": str(obj.get("mensagem_vitoria", "Missão cumprida.")),
		"largura": int(f["largura"]), "altura": int(f["altura"]), "obstaculos": obst, "decoracao": deco,
		"chao": chao, "terreno_dificil": dificil, "visao_livre": visao_livre, "visao_bloqueia": visao_bloqueia,
		"piso": str(f["piso"]), "escuro": bool(f["escuro"]), "luz_ambiente": int(f["luz_ambiente"]), "luzes": luzes,
		"niveis": niveis, "escadas": escadas,
		"unidades": unidades, "saques": saques, "grupos": f["grupos"].duplicate(true),
		"gatilhos": gatilhos, "armadilhas": armadilhas, "interacoes": interacoes,
		"recompensa": int(f["campanha"].get("recompensa", 0)),
	}
	if str(f["abertura"].get("texto", "")) != "":
		cen["abertura"] = {"titulo": str(f["abertura"].get("titulo", f["nome"])), "texto": str(f["abertura"]["texto"])}
	return cen


# --- Validação -------------------------------------------------------------------------

## Problemas da fase: [{"texto", "tipo" (inimigo/area/interacao/inicio/fase), "id"}].
static func validar(f: Dictionary) -> Array:
	var erros := []
	var l := int(f["largura"])
	var a := int(f["altura"])
	var bloqueada := {}
	for c in f["chao"]:
		if f["chao"][c] in ["vazio", "agua"]:
			bloqueada[casa(c)] = f["chao"][c]
	for o in f["objetos"]:
		if bool(o.get("colisao", OBJETOS.get(o["tipo"], {"colisao": true})["colisao"])):
			bloqueada[casa(str(o["pos"]))] = o["tipo"]
	var dentro := func(p: Vector2i) -> bool: return p.x >= 0 and p.y >= 0 and p.x < l and p.y < a
	var inicios := _casas(f["inicio"])
	if inicios.is_empty():
		erros.append({"texto": "Marque onde os heróis começam (ferramenta Início).", "tipo": "inicio", "id": ""})
	for i in inicios.size():
		var p: Vector2i = inicios[i]
		if not dentro.call(p) or bloqueada.has(p):
			erros.append({"texto": "O início %d está fora do mapa ou numa casa bloqueada." % (i + 1), "tipo": "inicio", "id": str(i)})
	var ids := {}
	var grupos := {}
	for e in f["inimigos"]:
		var p := casa(str(e["pos"]))
		if ids.has(e["id"]):
			erros.append({"texto": "Dois inimigos com o id \"%s\"." % e["id"], "tipo": "inimigo", "id": e["id"]})
		ids[e["id"]] = true
		if str(e.get("grupo", "")) != "":
			grupos[e["grupo"]] = true
		if not dentro.call(p) or bloqueada.has(p):
			erros.append({"texto": "%s está fora do mapa ou numa casa bloqueada." % e.get("nome", e["id"]), "tipo": "inimigo", "id": e["id"]})
		if p in inicios:
			erros.append({"texto": "%s está em cima do início de um herói." % e.get("nome", e["id"]), "tipo": "inimigo", "id": e["id"]})
		for ef in e.get("saque", []):
			_validar_efeito(ef, "Saque de %s" % e.get("nome", e["id"]), "inimigo", e["id"], erros, f)
	var obj: Dictionary = f["objetivo"]
	match str(obj.get("tipo", "derrotar_todos")):
		"derrotar_todos":
			if f["inimigos"].is_empty():
				erros.append({"texto": "O objetivo é derrotar todos, mas não há inimigos.", "tipo": "fase", "id": ""})
		"derrotar_alvos":
			if not f["inimigos"].any(func(e): return e.get("alvo", false)):
				erros.append({"texto": "O objetivo é derrotar alvos: marque \"Alvo do objetivo\" em pelo menos um inimigo.", "tipo": "fase", "id": ""})
		"chegar":
			if not f["areas"].any(func(x): return x.get("tipo", "") == "chegada" and not x.get("celulas", []).is_empty()):
				erros.append({"texto": "O objetivo é chegar: pinte uma área do tipo Chegada.", "tipo": "fase", "id": ""})
		"interagir":
			if not str(f["interacoes"]).contains("vitoria"):
				erros.append({"texto": "O objetivo é cumprir uma interação: ponha o efeito Vitória no resultado de alguma.", "tipo": "fase", "id": ""})
		"sobreviver":
			if int(obj.get("rodadas", 0)) < 1:
				erros.append({"texto": "Diga quantas rodadas o grupo precisa sobreviver.", "tipo": "fase", "id": ""})
	var ids_area := {}
	for ar in f["areas"]:
		if ar.get("celulas", []).is_empty():
			erros.append({"texto": "A área \"%s\" não tem casas: pinte-a no mapa." % ar.get("nome", ar["id"]), "tipo": "area", "id": ar["id"]})
		if ids_area.has(ar["id"]):
			erros.append({"texto": "Duas áreas com o id \"%s\"." % ar["id"], "tipo": "area", "id": ar["id"]})
		ids_area[ar["id"]] = true
		if ar.get("tipo", "") == "teste" and ar.get("teste", {}).get("somar", []).is_empty():
			erros.append({"texto": "A área de teste \"%s\" não diz o que somar no teste." % ar.get("nome", ar["id"]), "tipo": "area", "id": ar["id"]})
		for ef in ar.get("efeitos", []):
			_validar_efeito(ef, "Área %s" % ar.get("nome", ar["id"]), "area", ar["id"], erros, f)
		for r in ar.get("resultados", {}).values():
			for ef in r.get("efeitos", []):
				_validar_efeito(ef, "Área %s" % ar.get("nome", ar["id"]), "area", ar["id"], erros, f)
	var ids_it := {}
	for it in f["interacoes"]:
		var p := casa(str(it["pos"]))
		if not dentro.call(p):
			erros.append({"texto": "A interação \"%s\" está fora do mapa." % it.get("nome", it["id"]), "tipo": "interacao", "id": it["id"]})
		if ids_it.has(it["id"]):
			erros.append({"texto": "Duas interações com o id \"%s\"." % it["id"], "tipo": "interacao", "id": it["id"]})
		ids_it[it["id"]] = true
		for o in it.get("opcoes", []):
			if o.get("teste", {}).get("ativo", false) and o["teste"].get("somar", []).is_empty():
				erros.append({"texto": "\"%s\" → \"%s\": o teste não diz o que somar." % [it.get("nome", ""), o.get("texto", "")], "tipo": "interacao", "id": it["id"]})
			for r in o.get("resultados", {}).values():
				for ef in r.get("efeitos", []):
					_validar_efeito(ef, "%s → %s" % [it.get("nome", ""), o.get("texto", "")], "interacao", it["id"], erros, f)
	return erros


static func _validar_efeito(ef: Dictionary, onde: String, tipo: String, id: String, erros: Array, f: Dictionary) -> void:
	var esq: Dictionary = EFEITOS.get(ef.get("tipo", ""), {})
	if esq.is_empty():
		erros.append({"texto": "%s: efeito desconhecido (%s)." % [onde, ef.get("tipo", "?")], "tipo": tipo, "id": id})
		return
	for c in esq["campos"]:
		var v = ef.get(c[0], null)
		match c[1]:
			"item":
				if v == null or str(v) == "" or (not Itens.CONSUMIVEIS.has(str(v)) and not Itens.NAO_CONSUMIVEIS.has(str(v)) and Itens.item(str(v)).is_empty()):
					erros.append({"texto": "%s: escolha o item." % onde, "tipo": tipo, "id": id})
			"ficha":
				if v == null or str(v) == "":
					erros.append({"texto": "%s: escolha a ficha." % onde, "tipo": tipo, "id": id})
			"casas":
				if v == null or v.is_empty():
					erros.append({"texto": "%s: escolha as casas no mapa." % onde, "tipo": tipo, "id": id})
			"interacao":
				if v == null or not f["interacoes"].any(func(x): return x["id"] == str(v)):
					erros.append({"texto": "%s: escolha a interação." % onde, "tipo": tipo, "id": id})
			"inimigo":
				if v == null or not f["inimigos"].any(func(x): return x["id"] == str(v)):
					erros.append({"texto": "%s: escolha o inimigo." % onde, "tipo": tipo, "id": id})
			"int":
				if v == null and c[0] != "qtd":
					erros.append({"texto": "%s: falta o número (%s)." % [onde, c[2]], "tipo": tipo, "id": id})
