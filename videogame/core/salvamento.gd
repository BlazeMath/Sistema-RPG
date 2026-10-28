## Jogos salvos (0.18): 3 espaços com o grupo, as fichas dos heróis e a campanha
## (ouro, exílio de cada herói, missões cumpridas). Salva-se na vila, entre as missões.
extends RefCounted

const Personagem := preload("res://core/personagem.gd")
const Campanha := preload("res://core/campanha.gd")
const Sessao := preload("res://core/sessao.gd")
const Instantaneo := preload("res://core/instantaneo.gd")

const PASTA := "user://saves"
const ESPACOS := 3
const VERSAO_SAVE := 1


static func _arquivo(espaco: int) -> String:
	return "%s/espaco%d.json" % [PASTA, espaco]


## Resumo de um espaço ({} se vazio): nome do grupo, ouro, missões, data.
static func resumo(espaco: int) -> Dictionary:
	var a := _arquivo(espaco)
	if not FileAccess.file_exists(a):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(a))
	return d if d is Dictionary else {}


## Com "batalha", salva também a missão em andamento (ponto de descanso, 0.19).
static func salvar(espaco: int, data_texto: String, batalha: Object = null) -> String:
	DirAccess.make_dir_recursive_absolute(PASTA)
	var nomes: Array = Sessao.nomes_do_grupo()
	var fichas := Sessao.fichas_do_grupo()
	var d := {
		"versao": VERSAO_SAVE, "data": data_texto,
		"grupo": nomes, "herois": fichas,
		"campanha": Campanha.carregar().duplicate(true),
	}
	if batalha != null:
		d["missao"] = {"modo": Sessao.modo, "campanha": Sessao.campanha, "nome": Campanha.missao(Sessao.modo).get("nome", Sessao.modo),
			"estado": Instantaneo.para_texto(batalha)}
	var f := FileAccess.open(_arquivo(espaco), FileAccess.WRITE)
	if f == null:
		return "Não deu para salvar no espaço %d." % espaco
	f.store_string(JSON.stringify(d, "\t"))
	return "Jogo salvo no espaço %d (%s)." % [espaco, ", ".join(PackedStringArray(fichas.map(func(x): return x["nome"])))]


## Carrega: as fichas do save substituem as de mesmo nome; o grupo e a campanha voltam.
static func carregar(espaco: int) -> String:
	var d := resumo(espaco)
	if d.is_empty():
		return "O espaço %d está vazio." % espaco
	var salvos := Personagem.carregar_todos()
	for h in d.get("herois", []):
		salvos = salvos.filter(func(x): return x["nome"] != h["nome"])
		salvos.append(h)
	Personagem.salvar_todos(salvos)
	Sessao.definir_grupo(d.get("grupo", []))
	Campanha.dados = d.get("campanha", {}).duplicate(true)
	Campanha.carregar()
	Campanha.salvar()
	Sessao.estado_salvo = ""
	if d.has("missao"):
		Sessao.modo = d["missao"]["modo"]
		Sessao.campanha = bool(d["missao"].get("campanha", true))
		Sessao.estado_salvo = d["missao"]["estado"]
	return "Jogo do espaço %d carregado." % espaco


static func apagar(espaco: int) -> void:
	if FileAccess.file_exists(_arquivo(espaco)):
		DirAccess.remove_absolute(_arquivo(espaco))
