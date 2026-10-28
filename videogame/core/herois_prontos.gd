## Heróis prontos para testar (0.16): um de cada classe, fichas válidas.
## O menu pode guardá-los entre os heróis salvos e montar um grupo com eles.
extends RefCounted

const Personagem := preload("res://core/personagem.gd")
const Catalogo := preload("res://core/catalogo.gd")

const PERICIAS_GERAIS := ["Atletismo", "Luta", "Iniciativa", "Furtividade", "Acrobacia", "Pontaria", "Medicina", "Religião",
	"Sobrevivência", "Natureza", "Intuição", "Arcanismo", "História", "Ladinagem", "Escalada", "Natação", "Monstros",
	"Investigação", "Intimidação", "Liderança", "Negociação", "Guerra"]

const MODELOS := {
	"Guerreiro": {"nome": "Bruna (pronta)", "atributos": {"forca": 3, "constituicao": 3, "destreza": 2, "sabedoria": 2, "percepcao": 1, "raciocinio": 1, "espirito": 1, "mentira": 0, "diplomacia": 0},
		"arma": "espada_longa", "arma2": "maca", "armadura": "cota_de_malha", "escudo": "escudo_leve", "foco": "nenhum",
		"cartas": ["classe.guerreiro.ombro-de-ferro", "classe.guerreiro.postura-do-leao"], "topo": ["Atletismo", "Luta", "Intimidação", "Guerra"]},
	"Ladino": {"nome": "Lis (pronta)", "atributos": {"destreza": 3, "percepcao": 3, "sabedoria": 2, "constituicao": 2, "forca": 1, "raciocinio": 1, "mentira": 1, "espirito": 0, "diplomacia": 0},
		"arma": "faca", "arma2": "shuriken", "armadura": "couro_do_batedor", "escudo": "nenhum", "foco": "nenhum",
		"cartas": ["classe.ladino.ataque-furtivo", "classe.ladino.nunca-visto"], "topo": ["Furtividade", "Ladinagem", "Acrobacia", "Investigação"]},
	"Clérigo": {"nome": "Tomas (pronto)", "atributos": {"sabedoria": 3, "constituicao": 3, "forca": 2, "espirito": 2, "destreza": 1, "percepcao": 1, "diplomacia": 1, "raciocinio": 0, "mentira": 0},
		"arma": "maca", "arma2": "nenhuma", "armadura": "cota_de_malha", "escudo": "nenhum", "foco": "simbolo_sagrado",
		"cartas": ["classe.clerigo.feixe-de-luz", "classe.clerigo.toque-restaurador"], "topo": ["Religião", "Medicina", "Intuição", "Luta"]},
	"Caçador": {"nome": "Iara (pronta)", "atributos": {"destreza": 3, "percepcao": 3, "constituicao": 2, "sabedoria": 2, "forca": 1, "raciocinio": 1, "espirito": 1, "mentira": 0, "diplomacia": 0},
		"arma": "arco_curto", "arma2": "faca", "armadura": "couro_do_batedor", "escudo": "nenhum", "foco": "nenhum",
		"cartas": ["classe.cacador.preparar-o-tiro", "classe.cacador.flecha-aleijadora"], "topo": ["Pontaria", "Sobrevivência", "Natureza", "Furtividade"]},
	"Mago": {"nome": "Aldo (pronto)", "atributos": {"raciocinio": 3, "sabedoria": 3, "destreza": 2, "constituicao": 2, "percepcao": 1, "espirito": 1, "forca": 1, "mentira": 0, "diplomacia": 0},
		"arma": "faca", "arma2": "nenhuma", "armadura": "nenhuma", "escudo": "nenhum", "foco": "varinha_eletrizante",
		"cartas": ["classe.mago.aprendiz-de-fogo", "classe.mago.aprendiz-de-terra"], "topo": ["Arcanismo", "História", "Investigação", "Medicina"]},
}


static func ficha(classe: String) -> Dictionary:
	var m: Dictionary = MODELOS[classe]
	var f := Personagem.nova()
	f["nome"] = m["nome"]
	f["classe"] = classe
	f["xp"] = 10
	for chave in ["atributos", "arma", "arma2", "armadura", "escudo", "foco", "cartas"]:
		f[chave] = m[chave].duplicate() if m[chave] is Dictionary or m[chave] is Array else m[chave]
	f["meias"] = []
	f["herois"] = [Catalogo.herois_de(classe)[0]["id"], "raca.humano.heroi.incansavel"]
	f["consumiveis"] = ["pocao_de_cura_pequena", "tocha", "tocha"]
	var ordem: Array = m["topo"].duplicate()
	for p in PERICIAS_GERAIS:
		if not p in ordem:
			ordem.append(p)
	var pericias := {}
	for i in 18:
		pericias[ordem[i]] = 3 if i < 4 else (2 if i < 10 else 1)
	f["pericias"] = pericias
	return f


static func todas() -> Array:
	return MODELOS.keys().map(func(c): return ficha(c))


## Guarda os prontos entre os heróis salvos (troca os que já existem com o mesmo nome).
static func salvar_prontos() -> Array:
	var salvos := Personagem.carregar_todos()
	var nomes := []
	for f in todas():
		nomes.append(f["nome"])
		salvos = salvos.filter(func(x): return x["nome"] != f["nome"])
		salvos.append(f)
	Personagem.salvar_todos(salvos)
	return nomes
