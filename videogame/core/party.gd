## Party do jogo em rede (0.26). Mora só no computador do anfitrião, numa pasta própria:
## user://parties/<id>/party.json (nome e membros), herois.json (as fichas dos heróis
## vinculados, que evoluem na campanha) e campanha.json (bolsa, feridas, missões feitas).
## Cada jogador vincula o seu herói uma vez; depois, a cada sessão, escolhe de novo o
## herói dele na lista da party. A campanha segue sempre o computador do anfitrião.
extends RefCounted

const Personagem := preload("res://core/personagem.gd")
const Campanha := preload("res://core/campanha.gd")

const PASTA := "user://parties"
const MAXIMO := 4


static func _pasta(id: String) -> String:
	return "%s/%s" % [PASTA, id]


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
	s = s.strip_edges().trim_prefix("_").trim_suffix("_")
	return s if s != "" else "party"


static func _ler(caminho: String, padrao: Variant) -> Variant:
	if not FileAccess.file_exists(caminho):
		return padrao
	var d = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	return d if typeof(d) == typeof(padrao) else padrao


static func _gravar(caminho: String, v: Variant) -> void:
	var f := FileAccess.open(caminho, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(v, "\t"))


## Todas as parties salvas: [{"id", "nome", "membros": [{"heroi", "jogador"}]}].
static func listar() -> Array:
	var lista := []
	var dir := DirAccess.open(PASTA)
	if dir == null:
		return lista
	for sub in dir.get_directories():
		var p := carregar(sub)
		if not p.is_empty():
			lista.append(p)
	lista.sort_custom(func(a, b): return str(a["nome"]) < str(b["nome"]))
	return lista


static func carregar(id: String) -> Dictionary:
	var p: Dictionary = _ler(_pasta(id) + "/party.json", {})
	if p.is_empty():
		return {}
	p["id"] = id
	if not p.has("membros"):
		p["membros"] = []
	return p


## Cria a party (pasta nova, campanha do zero). Devolve a party ou {} se o nome já existe.
static func criar(nome: String) -> Dictionary:
	var id := id_de(nome)
	if nome.strip_edges() == "" or DirAccess.dir_exists_absolute(_pasta(id)):
		return {}
	DirAccess.make_dir_recursive_absolute(_pasta(id))
	var p := {"nome": nome.strip_edges(), "membros": []}
	_gravar(_pasta(id) + "/party.json", p)
	_gravar(_pasta(id) + "/herois.json", [])
	_gravar(_pasta(id) + "/campanha.json", Campanha._novos_dados())
	p["id"] = id
	return p


static func fichas(id: String) -> Array:
	return _ler(_pasta(id) + "/herois.json", [])


## Vincula o herói de um jogador à party (a ficha é copiada para o computador do anfitrião).
## Devolve "" ou o motivo de não dar.
static func vincular(id: String, ficha: Dictionary, jogador: String) -> String:
	var p := carregar(id)
	if p.is_empty():
		return "A party não existe mais."
	var nome := str(ficha.get("nome", ""))
	if not Personagem.validar(ficha).is_empty():
		return "A ficha de %s tem pendências; termine na criação de heróis." % nome
	for m in p["membros"]:
		if str(m["heroi"]) == nome:
			return "Já existe %s nesta party: escolha-o na lista da party." % nome
	if p["membros"].size() >= MAXIMO:
		return "A party já tem %d heróis." % MAXIMO
	var lista := fichas(id)
	lista.append(ficha.duplicate(true))
	_gravar(_pasta(id) + "/herois.json", lista)
	p["membros"].append({"heroi": nome, "jogador": jogador})
	var guardar := p.duplicate(true)
	guardar.erase("id")
	_gravar(_pasta(id) + "/party.json", guardar)
	return ""


## Tira um herói da party (a ficha sai do computador do anfitrião).
static func desvincular(id: String, heroi: String) -> void:
	var p := carregar(id)
	if p.is_empty():
		return
	p["membros"] = p["membros"].filter(func(m): return str(m["heroi"]) != heroi)
	var guardar := p.duplicate(true)
	guardar.erase("id")
	_gravar(_pasta(id) + "/party.json", guardar)
	_gravar(_pasta(id) + "/herois.json", fichas(id).filter(func(f): return str(f.get("nome", "")) != heroi))


static func apagar(id: String) -> void:
	var pasta := _pasta(id)
	var dir := DirAccess.open(pasta)
	if dir == null:
		return
	for arq in dir.get_files():
		dir.remove(arq)
	DirAccess.remove_absolute(pasta)


## Liga a campanha e os heróis aos arquivos da party (no anfitrião).
static func abrir(id: String) -> void:
	Personagem.memoria = null
	Personagem.arquivo = _pasta(id) + "/herois.json"
	Campanha.memoria = false
	Campanha.arquivo = _pasta(id) + "/campanha.json"
	Campanha.dados = {}


## Volta para os arquivos normais (fora do jogo em rede).
static func fechar() -> void:
	Personagem.memoria = null
	Personagem.arquivo = Personagem.ARQUIVO
	Campanha.memoria = false
	Campanha.arquivo = Campanha.ARQUIVO
	Campanha.dados = {}


## Resumo para a sala: "Guerreiro · Humano".
static func resumo_da_ficha(f: Dictionary) -> String:
	return "%s · %s" % [str(f.get("classe", "?")), str(f.get("raca", "?"))]
