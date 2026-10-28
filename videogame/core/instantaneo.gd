## Retrato da batalha (0.19): guarda o estado inteiro de uma Batalha em texto, para
## salvar no meio da missão (nos pontos de descanso) e voltar exatamente ali.
##
## Percorre as variáveis de script dos objetos (Batalha, Unidade, Baralho, CartaEmJogo,
## Teste21, Grade...) e vira uma árvore de dicionários e listas; objetos repetidos viram
## referências ({"__ref": n}), então ligações como "atacante" continuam apontando para a
## mesma unidade da lista. Callables não são guardados. O texto usa var_to_str (aceita
## Vector2i e dicionários com chaves Vector2i).
extends RefCounted

const Teste21 := preload("res://core/teste21.gd")
const Baralho := preload("res://core/baralho.gd")
const Grade := preload("res://core/grade.gd")


static func para_texto(b: Object) -> String:
	return var_to_str(codificar(b, {}))


## Aplica o retrato em "b" (uma Batalha recém-criada do mesmo cenário).
static func aplicar_texto(b: Object, texto: String) -> bool:
	var arvore = str_to_var(texto)
	if not arvore is Dictionary or not arvore.has("__obj"):
		return false
	# var_to_str ordena as chaves: uma referência pode vir antes do objeto. Então
	# primeiro cria todos os objetos, depois preenche.
	var objs := {int(arvore["__obj"]): b}
	_criar_todos(arvore["p"], objs)
	objs["preenchidos"] = {int(arvore["__obj"]): true}
	_preencher(b, arvore["p"], objs)
	return true


static func _criar_todos(v: Variant, objs: Dictionary) -> void:
	if v is Dictionary:
		if v.has("__rng"):
			var r := RandomNumberGenerator.new()
			r.seed = int(v["seed"])
			r.state = int(v["state"])
			objs[int(v["__rng"])] = r
			return
		if v.has("__obj"):
			if not objs.has(int(v["__obj"])):
				objs[int(v["__obj"])] = _novo(load(str(v["script"])))
			_criar_todos(v["p"], objs)
			return
		for k in v:
			_criar_todos(v[k], objs)
	elif v is Array:
		for x in v:
			_criar_todos(x, objs)


static func codificar(v: Variant, ids: Dictionary = {}) -> Variant:
	match typeof(v):
		TYPE_OBJECT:
			if v == null or not is_instance_valid(v):
				return null
			var iid: int = v.get_instance_id()
			if ids.has(iid):
				return {"__ref": ids[iid]}
			var n := ids.size()
			ids[iid] = n
			if v is RandomNumberGenerator:
				return {"__rng": n, "seed": v.seed, "state": v.state}
			var sc = v.get_script()
			if sc == null:
				return null
			var props := {}
			for p in v.get_property_list():
				if int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
					props[p["name"]] = codificar(v.get(p["name"]), ids)
			return {"__obj": n, "script": sc.resource_path, "p": props}
		TYPE_ARRAY:
			var a := []
			for x in v:
				a.append(codificar(x, ids))
			return a
		TYPE_DICTIONARY:
			var d := {}
			for k in v:
				d[k] = codificar(v[k], ids)
			return d
		TYPE_CALLABLE, TYPE_SIGNAL, TYPE_RID:
			return null
	return v


static func _decodificar(v: Variant, objs: Dictionary) -> Variant:
	if v is Dictionary:
		if v.has("__ref"):
			return objs.get(int(v["__ref"]))
		if v.has("__rng"):
			return objs.get(int(v["__rng"]))
		if v.has("__obj"):
			var id := int(v["__obj"])
			var o = objs.get(id)
			if not objs["preenchidos"].has(id):
				objs["preenchidos"][id] = true
				_preencher(o, v["p"], objs)
			return o
		var d := {}
		for k in v:
			d[k] = _decodificar(v[k], objs)
		return d
	if v is Array:
		var a := []
		for x in v:
			a.append(_decodificar(x, objs))
		return a
	return v


static func _novo(sc: Script) -> Object:
	if sc == Teste21:
		return Teste21.new(Baralho.new())
	if sc == Grade:
		return Grade.new(1, 1)
	return sc.new()


static func _preencher(o: Object, props: Dictionary, objs: Dictionary) -> void:
	for nome in props:
		var valor = _decodificar(props[nome], objs)
		var atual = o.get(nome)
		if atual is Array and atual.is_typed():
			atual.clear()
			if valor is Array:
				atual.assign(valor)
		elif atual is Dictionary and atual.is_typed():
			atual.clear()
			if valor is Dictionary:
				atual.assign(valor)
		elif valor == null and typeof(atual) in [TYPE_CALLABLE, TYPE_SIGNAL, TYPE_ARRAY, TYPE_DICTIONARY, TYPE_STRING, TYPE_INT, TYPE_FLOAT, TYPE_BOOL]:
			continue
		else:
			o.set(nome, valor)
