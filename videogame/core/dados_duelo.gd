## Valores PROVISÓRIOS do duelo de teste. Ajuste aqui para mudar o combate.
##
## Herói: Guerreiro de teste com espada média (dano 4 + Força) e armadura leve.
##   Testes de ataque e defesa: só as cartas (regra confirmada pelo Lucas).
## Goblin: perfil Covarde (para em 14 atacando e em 17 defendendo).
extends RefCounted

const IA := preload("res://core/ia_inimigo.gd")

const HEROI := {
	"nome": "Guerreiro",
	"ataque": 0,
	"defesa": 0,
	"dano_arma": 4,
	"atributo_dano": 3,     # Força
	"resistencia": 2,       # armadura leve
	"sabedoria": 2,         # mão inicial = 2 + 2
	"destreza": 2,
	"iniciativa": 1,
	"ataques_por_turno": 2, # duas ações padrão
}


static func goblin() -> Dictionary:
	var perfil: Dictionary = IA.PERFIS["covarde"]
	return {
		"nome": "Goblin Desordeiro",
		"vida": 45,
		"ataque": 0,
		"defesa": 0,
		"dano": 3,
		"resistencia": 0,
		"destreza": 3,
		"iniciativa": 1,
		"ataques_por_turno": 1,
		"perfil": perfil["nome"],
		"parada_ataque": perfil["parada_ataque"],
		"parada_defesa": perfil["parada_defesa"],
	}
