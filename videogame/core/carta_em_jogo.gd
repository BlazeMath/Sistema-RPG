## Uma carta de dois lados em jogo (habilidade ou carta de herói), com o lado
## ativo, a fadiga e as fichas que estão sobre ela.
##
## Regras: ativar um lado coloca fadiga nele, até o limite do lado. Virar a carta
## custa uma ação Padrão e apaga as fichas VOLÁTEIS (fadiga, Foco, Imobilizar...);
## as persistentes (Sangramento, Veneno) ficam. O Fogo sai ao virar a carta. No fim do turno, o jogador
## retira 1 de fadiga de UMA carta à escolha.
extends RefCounted

const PERSISTENTES := ["Sangramento", "Veneno", "Fúria"]

var id := ""
var tipo := "habilidade"     # "habilidade" ou "heroi"
var lados: Array = []        # [{nome, slug, texto, limite_fadiga, custo, tags, efeitos?}, ...]
var lado := 0
var fadiga := 0
var fichas := {}             # nome -> quantidade
var opcao := ""           # opção de repertório escolhida (Aprendiz de Fogo, Água...)
var bonus_limite := 0        # ex.: Controlador do Arcano (+1 em todas as cartas)


func lado_ativo() -> Dictionary:
	return lados[lado]


func nome() -> String:
	return lado_ativo()["nome"]


func slug() -> String:
	return lado_ativo()["slug"]


func limite() -> int:
	if tipo == "arma":
		return int(lado_ativo().get("limite_fadiga", 0))   # carta de arma: sem bônus de limite
	return int(lado_ativo().get("limite_fadiga", 0)) + bonus_limite


func espaco() -> int:
	return limite() - fadiga


func pode_pagar(custo: int) -> bool:
	return custo <= espaco()


func pagar(custo: int) -> void:
	fadiga += custo


func virar() -> void:
	opcao = ""
	lado = 1 - lado if lados.size() > 1 else lado
	fadiga = 0
	for f in fichas.keys():
		if not f in PERSISTENTES:
			fichas.erase(f)


## Lucas (0.20): cada carta tem no máximo 1 ficha de cada tipo (fadiga não é ficha).
## Exceção: fichas que a própria carta manda acumular (Fúria Crescente: 5 ou mais).
const EMPILHAVEIS := ["Fúria"]


func dar_ficha(nome_ficha: String, qtd := 1) -> void:
	if nome_ficha in EMPILHAVEIS:
		fichas[nome_ficha] = fichas.get(nome_ficha, 0) + qtd
	elif qtd > 0:
		fichas[nome_ficha] = 1


func pode_receber(nome_ficha: String) -> bool:
	return nome_ficha in EMPILHAVEIS or not tem_ficha(nome_ficha)


func tirar_ficha(nome_ficha: String, qtd := 1) -> bool:
	if fichas.get(nome_ficha, 0) < qtd:
		return false
	fichas[nome_ficha] -= qtd
	if fichas[nome_ficha] <= 0:
		fichas.erase(nome_ficha)
	return true


func tem_ficha(nome_ficha: String) -> bool:
	return fichas.get(nome_ficha, 0) > 0


func fichas_texto() -> String:
	var partes := PackedStringArray()
	for f in fichas:
		partes.append("%s %d" % [f, fichas[f]] if fichas[f] > 1 else f)
	return ", ".join(partes)
