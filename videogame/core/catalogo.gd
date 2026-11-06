## Catálogo das cartas exportadas da planilha (data/cartas/*.json).
extends RefCounted

static var _habilidades: Array = []
static var _herois: Array = []
static var _pactos: Dictionary = {}    # Bruxo (0.25): data/cartas/bruxo.json

## Correções do Lucas que ainda não estão na planilha exportada (aplicadas ao carregar).
const CORRECOES := {
	"Flecha de Rede": {"limite_fadiga": 2},
	"Mestre das Cavernas": {"limite_fadiga": 3},
}


static func _carregar() -> void:
	if not _habilidades.is_empty():
		return
	_habilidades = JSON.parse_string(FileAccess.get_file_as_string("res://data/cartas/habilidades.json"))
	_herois = JSON.parse_string(FileAccess.get_file_as_string("res://data/cartas/herois.json"))
	# Bruxo (0.25): cartas da proposta v02 do Lucas, geradas por tools/gerar_bruxo.py.
	var bruxo = JSON.parse_string(FileAccess.get_file_as_string("res://data/cartas/bruxo.json")) if FileAccess.file_exists("res://data/cartas/bruxo.json") else null
	if bruxo is Dictionary:
		_habilidades.append_array(bruxo.get("habilidades", []))
		_herois.append_array(bruxo.get("herois", []))
		_pactos = bruxo.get("pactos", {})
	for c in _habilidades:
		for l in c.get("lados", []):
			if l != null and CORRECOES.has(l.get("nome", "")):
				l.merge(CORRECOES[l["nome"]], true)
	for h in _herois:
		if CORRECOES.has(h.get("nome", "")):
			h.merge(CORRECOES[h["nome"]], true)


static func habilidades_de(entidade: String) -> Array:
	_carregar()
	return _habilidades.filter(func(c): return c["entidade"] == entidade)


static func herois_de(entidade: String) -> Array:
	_carregar()
	return _herois.filter(func(c): return c["entidade"] == entidade)


static func habilidade(id: String) -> Dictionary:
	_carregar()
	for c in _habilidades:
		if c["id"] == id:
			return c
	return {}


static func heroi(id: String) -> Dictionary:
	_carregar()
	for c in _herois:
		if c["id"] == id:
			return c
	return {}


static func slug(texto: String) -> String:
	var s := texto.to_lower()
	var trocas := {"á": "a", "à": "a", "â": "a", "ã": "a", "é": "e", "ê": "e", "í": "i", "ó": "o", "ô": "o", "õ": "o", "ú": "u", "ç": "c", "!": "", ",": ""}
	for k in trocas:
		s = s.replace(k, trocas[k])
	var r := ""
	for ch in s:
		r += ch if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") else "-"
	while r.contains("--"):
		r = r.replace("--", "-")
	return r.strip_edges().trim_prefix("-").trim_suffix("-")


## Nome do lado de carta (ou metade de herói) a partir da slug.
static func habilidade_por_slug(s: String) -> String:
	_carregar()
	for c in _habilidades:
		for l in c["lados"]:
			if l != null and slug(l["nome"]) == s:
				return l["nome"]
	for h in _herois:
		if slug(h["nome"]) == s:
			return h["nome"]
	return s


## Pactos do Bruxo (0.25): id do pacto -> dados (nome, patrono, tags, heroi, inicial, menor...).
static func pactos() -> Dictionary:
	_carregar()
	return _pactos


## Pacto pleno da ficha (pela metade de herói do patrono) ou "".
static func pacto_da_ficha(f: Dictionary) -> String:
	_carregar()
	for hid in f.get("herois", []):
		for p in _pactos:
			if _pactos[p].get("heroi", "") == hid:
				return p
	return ""


## Tags que os pactos da ficha concedem (pleno e menor).
static func tags_do_pacto(f: Dictionary) -> Array:
	var tags := []
	var ids := [pacto_da_ficha(f)]
	ids.append_array(f.get("escolhas", {}).get("pacto-menor", []))
	for p in ids:
		for t in _pactos.get(p, {}).get("tags", []):
			if not t in tags:
				tags.append(t)
	if not ids.filter(func(x): return x != "").is_empty():
		tags.append("Pacto")
	return tags
