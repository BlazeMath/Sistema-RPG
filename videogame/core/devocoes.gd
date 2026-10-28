## Divindades e devoções genéricas para testar as cartas que dependem delas (0.15).
## O Clérigo escolhe a divindade na criação; a divindade define a devoção:
## o tipo de dano divino e as criaturas inimigas da devoção (O Martelo da Luz).
## Nomes e números são provisórios, para o Lucas substituir pelos do cenário.
extends RefCounted

const DIVINDADES := {
	"aurora": {"nome": "Solenne, a Aurora", "devocao": "Luz", "tipo_dano": "Radiante",
		"inimigos": ["morto-vivo", "demonio"],
		"texto": "Deusa do sol nascente. Devoção da Luz: dano Radiante; inimigos: mortos-vivos e demônios."},
	"martelo": {"nome": "Karrak, o Martelo", "devocao": "Guerra", "tipo_dano": "Trovão",
		"inimigos": ["goblinoide"],
		"texto": "Deus das muralhas e dos que resistem. Devoção da Guerra: dano de Trovão; inimigos: goblinoides que saqueiam as vilas."},
	"mae_verde": {"nome": "Verdana, a Mãe Verde", "devocao": "Natureza", "tipo_dano": "Natural",
		"inimigos": ["morto-vivo", "aberracao"],
		"texto": "Deusa das florestas e das colheitas. Devoção da Natureza: dano Natural; inimigos: mortos-vivos e aberrações."},
	"guardiao": {"nome": "Ossário, o Guardião dos Mortos", "devocao": "Morte", "tipo_dano": "Necrótico",
		"inimigos": ["morto-vivo"],
		"texto": "Deus que guia as almas ao descanso. Devoção da Morte: dano Necrótico; inimigos: mortos-vivos, que fogem do descanso."},
}

const PADRAO := "aurora"

## Categorias de criatura dos inimigos (para devoções e cartas "contra mortos-vivos e demônios").
const CATEGORIAS := {"goblinoide": "goblinoide", "fera": "fera", "morto-vivo": "morto-vivo", "demonio": "demônio",
	"humanoide": "humanoide", "aberracao": "aberração"}


static func de(id: String) -> Dictionary:
	return DIVINDADES.get(id, DIVINDADES[PADRAO])


static func inimigo_da_devocao(divindade: String, categoria: String) -> bool:
	return categoria != "" and categoria in de(divindade)["inimigos"]
