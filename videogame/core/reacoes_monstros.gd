## Reações dos monstros (0.22, no estilo do Descent).
##
## Cada monstro pode ter efeitos que disparam sozinhos:
##   "ao_ser_atacado": depois de um ataque de herói contra ele (vivo ou não, conforme o efeito);
##   "ao_atacar":      depois de um ataque dele (com "so_acerto", só se acertou);
##   "ao_morrer":      quando cai.
## As reações "livre" não gastam a Reação do monstro, mas cada uma dispara no
## máximo uma vez por rodada (até o próximo turno dele). As antigas (fuga do
## goblin covarde) continuam gastando a Reação.
##
## Efeitos (Batalha._efeito_reacao_monstro):
##   "investir":   anda até "valor" quadrados na direção do atacante; se chegar ao lado, põe "ficha" nele.
##   "inspirar":   um aliado aleatório a até "raio" quadrados causa +"valor" de dano no próximo ataque.
##   "chamar":     um aliado aleatório a até "raio" anda até "valor" quadrados na direção do herói.
##   "mover":      se afasta "valor" quadrados de quem atacou ("so_corpo_a_corpo": só se o ataque foi de perto).
##   "bonus_contra_atacante": o próximo ataque dele contra quem o atacou causa +"valor".
##   "estilhacar": ao morrer, causa "valor" de dano em cada herói ao lado.
##   "fichas_ao_lado": ao morrer, cada herói ao lado recebe "ficha".
##   "remontar":   ao morrer pela primeira vez, levanta no início da próxima rodada com metade da
##                 vida, a não ser que o golpe final tenha sido de um dos tipos em "impede".
extends RefCounted

const POR_NOME := {
	"Goblin Brigão": [
		{"gatilho": "ao_ser_atacado", "efeito": "bonus_contra_atacante", "valor": 2, "livre": true,
			"nome": "Revide", "texto": "o próximo ataque dele contra quem o atacou causa +2"},
	],
	"Goblin Atirador": [
		{"gatilho": "ao_ser_atacado", "efeito": "mover", "valor": 1, "livre": true, "so_corpo_a_corpo": true,
			"nome": "Recuar", "texto": "atacado de perto, recua 1 quadrado"},
	],
	"Rokk, chefe goblin": [
		{"gatilho": "ao_ser_atacado", "efeito": "inspirar", "valor": 1, "raio": 6, "livre": true,
			"nome": "Grito de guerra", "texto": "um goblin aleatório a até 6 quadrados causa +1 de dano no próximo ataque"},
		{"gatilho": "ao_atacar", "efeito": "chamar", "valor": 2, "raio": 8, "livre": true, "so_acerto": true,
			"nome": "Todos nele!", "texto": "ao acertar, um goblin aleatório a até 8 quadrados avança 2 na direção do alvo"},
	],
	"Chefe Goblin": [
		{"gatilho": "ao_ser_atacado", "efeito": "inspirar", "valor": 1, "raio": 6, "livre": true,
			"nome": "Grito de guerra", "texto": "um aliado aleatório a até 6 quadrados causa +1 de dano no próximo ataque"},
	],
	"Toupeira Atroz": [
		{"gatilho": "ao_ser_atacado", "efeito": "investir", "valor": 2, "ficha": "Ferimento", "livre": true,
			"nome": "Fúria da toca", "texto": "avança até 2 quadrados na direção de quem a atacou; se chegar ao lado, ele recebe 1 Ferimento"},
	],
	"Esqueleto": [
		{"gatilho": "ao_morrer", "efeito": "estilhacar", "valor": 1, "livre": true,
			"nome": "Ossos que estilhaçam", "texto": "ao cair, cada herói ao lado sofre 1 de dano"},
	],
	"Esqueleto Arqueiro": [
		{"gatilho": "ao_ser_atacado", "efeito": "mover", "valor": 1, "livre": true, "so_corpo_a_corpo": true,
			"nome": "Recuar", "texto": "atacado de perto, recua 1 quadrado"},
	],
	"Guarda de Ossos": [
		{"gatilho": "ao_morrer", "efeito": "remontar", "livre": true, "impede": ["Concussão", "Radiante"],
			"nome": "Ossos teimosos", "texto": "na primeira vez que cai, levanta no início da rodada seguinte com metade da vida, a não ser que o golpe final seja de Concussão ou Radiante"},
	],
	"Sir Aldric, o Cavaleiro Ossudo": [
		{"gatilho": "ao_ser_atacado", "efeito": "chamar", "valor": 2, "raio": 10, "livre": true,
			"nome": "Às armas!", "texto": "um aliado aleatório a até 10 quadrados avança 2 na direção de quem o atacou"},
		{"gatilho": "ao_atacar", "efeito": "inspirar", "valor": 1, "raio": 8, "livre": true, "so_acerto": true,
			"nome": "Exemplo do cavaleiro", "texto": "ao acertar, um aliado aleatório a até 8 quadrados causa +1 de dano no próximo ataque"},
	],
	"Afogado": [
		{"gatilho": "ao_morrer", "efeito": "fichas_ao_lado", "ficha": "Imobilizar", "livre": true,
			"nome": "Estoura em lodo", "texto": "ao cair, o lodo prende os pés: cada herói ao lado recebe 1 Imobilizar"},
	],
	"Fantasma Afogado": [
		{"gatilho": "ao_ser_atacado", "efeito": "mover", "valor": 1, "livre": true, "so_corpo_a_corpo": true,
			"nome": "Desfazer-se", "texto": "atacado de perto, se desfaz em névoa e reaparece 1 quadrado mais longe"},
	],
	"Bruxa Morgana": [
		{"gatilho": "ao_ser_atacado", "efeito": "inspirar", "valor": 1, "raio": 8, "livre": true,
			"nome": "Grito do pântano", "texto": "um servo aleatório a até 8 quadrados causa +1 de dano no próximo ataque"},
	],
}


## Põe as reações da tabela num inimigo (se ele ainda não tiver as suas).
static func aplicar(cfg: Dictionary) -> Dictionary:
	if cfg.get("reacoes", []).is_empty() and POR_NOME.has(cfg.get("nome", "")):
		cfg["reacoes"] = POR_NOME[cfg["nome"]].duplicate(true)
	return cfg


## Texto curto de uma reação para a ficha do monstro.
static func descricao(r: Dictionary) -> String:
	var quando: String = {"ao_ser_atacado": "Ao ser atacado", "ao_atacar": "Ao atacar", "ao_morrer": "Ao cair"}.get(r.get("gatilho", "ao_ser_atacado"), "")
	var nome: String = r.get("nome", "")
	return "%s%s: %s." % [(nome + " — ") if nome != "" else "", quando, r.get("texto", r.get("efeito", ""))]
