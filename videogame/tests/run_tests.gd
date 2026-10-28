## Executa todos os testes automáticos do motor de regras.
##
## Linha de comando (sem abrir a janela do Godot):
##   godot --headless --path . -s res://tests/run_tests.gd
##
## Cada arquivo tests/test_*.gd tem funções que começam com "test_".
## Dentro delas, use t.ok(condição, mensagem) e t.igual(obtido, esperado, mensagem).
extends SceneTree

var falhas := 0
var verificacoes := 0
var _teste_atual := ""


func _init() -> void:
	var dir := DirAccess.open("res://tests")
	var arquivos := []
	for nome in dir.get_files():
		if nome.begins_with("test_") and nome.ends_with(".gd"):
			arquivos.append(nome)
	arquivos.sort()
	var total_testes := 0
	for nome in arquivos:
		var script: GDScript = load("res://tests/" + nome)
		if script == null or not script.can_instantiate():
			falhas += 1
			printerr("FALHOU  %s: o arquivo não compila" % nome)
			continue
		var obj = script.new()
		for m in script.get_script_method_list():
			if m["name"].begins_with("test_"):
				_teste_atual = nome + " › " + m["name"]
				total_testes += 1
				obj.call(m["name"], self)
	print("")
	print("%d testes, %d verificações, %d falhas" % [total_testes, verificacoes, falhas])
	quit(1 if falhas > 0 else 0)


func ok(condicao: bool, mensagem := "") -> void:
	verificacoes += 1
	if not condicao:
		falhas += 1
		printerr("FALHOU  %s: %s" % [_teste_atual, mensagem])


func igual(obtido, esperado, mensagem := "") -> void:
	ok(obtido == esperado, "%s (obtido %s, esperado %s)" % [mensagem, str(obtido), str(esperado)])
