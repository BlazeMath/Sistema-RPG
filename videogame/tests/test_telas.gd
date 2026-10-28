## As telas e ferramentas compilam (pega erros de digitação antes de abrir o jogo).
extends RefCounted


func test_scripts_das_telas_compilam(t) -> void:
	for pasta in ["res://ui", "res://tools"]:
		var dir := DirAccess.open(pasta)
		for nome in dir.get_files():
			if nome.ends_with(".gd"):
				var script: GDScript = load(pasta.path_join(nome))
				t.ok(script != null and script.can_instantiate(), "%s/%s compila" % [pasta, nome])
