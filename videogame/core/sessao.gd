## O que foi escolhido no menu (herói, grupo e modo), compartilhado entre as telas.
extends RefCounted

const Personagem := preload("res://core/personagem.gd")
const ARQUIVO_GRUPO := "user://grupo.json"
const MAXIMO_GRUPO := 4

static var ficha: Dictionary = {}
static var grupo: Array = []       # nomes dos heróis salvos que formam o grupo (até 4)
static var modo := "arena"         # "arena", "x1", "trilha" ou "fazenda"
static var _grupo_carregado := false
static var distribuir_sugestao := false   # "sempre usar a sugestão" na distribuição de dano
static var campanha := false       # missão saída da vila: ouro, feridas e consumíveis ficam (core/campanha.gd)
static var estado_salvo := ""
static var vila_pos := Vector2i(-1, -1)   # 0.23: onde o herói estava na vila andável      # retrato de uma batalha salva no meio da missão (core/instantaneo.gd)
static var solo := false           # "Testar este herói" na criação: joga só com ele


static func ficha_atual() -> Dictionary:
	if ficha.is_empty():
		var salvos := Personagem.carregar_todos()
		for f in salvos:
			if Personagem.validar(f).is_empty():
				ficha = f
				break
	if ficha.is_empty():
		ficha = Personagem.nova()
	return ficha


static func nomes_do_grupo() -> Array:
	if not _grupo_carregado:
		_grupo_carregado = true
		if FileAccess.file_exists(ARQUIVO_GRUPO):
			var d = JSON.parse_string(FileAccess.get_file_as_string(ARQUIVO_GRUPO))
			if d is Array:
				grupo = d
	return grupo


static func definir_grupo(nomes: Array) -> void:
	grupo = nomes.slice(0, MAXIMO_GRUPO)
	_grupo_carregado = true
	var f := FileAccess.open(ARQUIVO_GRUPO, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(grupo))


## As fichas do grupo (só as válidas). Sem grupo, só o herói atual.
static func fichas_do_grupo() -> Array:
	if solo:
		return [ficha_atual()]
	var salvos := Personagem.carregar_todos()
	var lista := []
	for nome in nomes_do_grupo():
		for f in salvos:
			if f["nome"] == nome and Personagem.validar(f).is_empty():
				lista.append(f)
				break
	if lista.is_empty():
		lista.append(ficha_atual())
	return lista
