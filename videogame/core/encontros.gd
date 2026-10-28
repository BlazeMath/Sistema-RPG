## Encontros e inimigos pela filosofia do Lucas (0.11).
##
## Patamares (para um grupo de 4):
##   lacaio   — cai com 1,5 ataques de um herói; causa 10% da vida de um herói por acerto.
##   médio    — cai com 3 ataques; causa 20%.
##   conjurador — único no combate; pouco dano, foco em suporte (inimigos) e controle (heróis).
##   elite    — sozinho: cai com 16 ataques e causa 40% por ataque, 2 ataques por turno em heróis
##              diferentes. Com escolta: 10 ataques e 25%.
##   chefe    — cai com 32 a 40 ataques (usamos 36).
## Referências medidas na simulação: um herói causa ~6 de dano por ataque; a vida
## de um herói é o baralho (52). Num acerto, a diferença média é ~4 e a resistência
## média do herói é ~2: o dano fixo do inimigo = alvo − 4 + 2.
## Papéis (inventados, para o Lucas revisar): aggro, tank, control, support e neutro.
extends RefCounted

const IA := preload("res://core/ia_inimigo.gd")
const Combate := preload("res://core/combate.gd")

const DANO_ATAQUE_HEROI := 7.0
const VIDA_HEROI := 52.0
const DIFERENCA_MEDIA := 4
const RESISTENCIA_MEDIA_HEROI := 2

const PATAMARES := {
	"lacaio": {"ataques": 1.5, "dano": 0.10, "ataques_por_turno": 1},
	"medio": {"ataques": 3.0, "dano": 0.20, "ataques_por_turno": 1},
	"conjurador": {"ataques": 2.5, "dano": 0.10, "ataques_por_turno": 1},
	"elite": {"ataques": 16.0, "dano": 0.40, "ataques_por_turno": 2, "pelo_grupo": true, "espalha": true},
	"elite_escoltado": {"ataques": 10.0, "dano": 0.25, "ataques_por_turno": 2, "pelo_grupo": true, "espalha": true},
	"chefe": {"ataques": 36.0, "dano": 0.30, "ataques_por_turno": 2, "pelo_grupo": true, "espalha": true},
}

const PAPEIS := {
	"neutro": {"vida": 1.0, "dano": 1.0},
	"aggro": {"vida": 0.8, "dano": 1.25, "perfil": "covarde"},
	"tank": {"vida": 1.3, "dano": 0.75, "resistencia": 1, "perfil": "bruto", "ataque_oportunidade": true},
	"control": {"vida": 1.0, "dano": 0.75, "ao_acertar": [{"ficha": "Imobilizar"}]},
	"support": {"vida": 0.8, "dano": 0.5, "cura": 0.25},
}


## Números de um inimigo. Elites e chefes (sozinhos contra o grupo) têm a vida
## proporcional ao tamanho do grupo (25% por herói), para o combate durar o mesmo
## número de rodadas; lacaios e médios mudam em quantidade, não em vida.
## Ajustes finos medidos na simulação (multiplicam vida e dano de um patamar).
## Medido com heróis "sem estratégia" (andam até o mais perto e atacam; conjuradores usam a
## magia básica): para dar ~40% de vitória no elite e ~10% no chefe, como o Lucas pediu
## (dano de referência 7 por ataque), o elite precisa de 1,3× a vida e 2× o dano das
## fórmulas; o chefe, de 0,75× a vida.
static var calibragem := {
	"elite": {"vida": 1.3, "dano": 0.8},              # Lucas (0.23): ~15 por golpe + a diferença (antes ~40)
	"elite_escoltado": {"vida": 1.35, "dano": 1.1},
	"chefe": {"vida": 0.52, "dano": 1.0},   # Lucas (0.20): chefe de 4 heróis com ~130 (era ~190)
}
## Lucas (0.20): lacaios com 11 de vida (antes ~4 no combate simples). Valor fixo, sem papel
## nem a metade do combate simples.
const VIDA_LACAIO := 11

## Por tipo de combate (0.13): no combate simples, o grupo gasta o baralho mais nos
## testes (ataque e defesa) do que no dano sofrido. Para gastar 35–45% da vida do
## grupo (2 a 3 combates antes de descansar), lacaios e médios ali têm metade da vida.
static var calibragem_combate := {
	"simples": {"vida": 0.5},
}


## Aplica a calibragem do tipo de combate num inimigo já montado.
static func para_combate(cfg: Dictionary, tipo: String) -> Dictionary:
	var c: Dictionary = calibragem_combate.get(tipo, {})
	if c.has("vida") and cfg.get("patamar", "") in ["medio"]:
		cfg["vida"] = maxi(int(round(cfg["vida"] * float(c["vida"]))), 1)
	return cfg


static func status(patamar: String, papel: String, herois: int) -> Dictionary:
	var p: Dictionary = PATAMARES[patamar]
	var r: Dictionary = PAPEIS[papel]
	var cal: Dictionary = calibragem.get(patamar, {"vida": 1.0, "dano": 1.0})
	var vida: float = DANO_ATAQUE_HEROI * p["ataques"] * r["vida"] * float(cal.get("vida", 1.0))
	if p.get("pelo_grupo", false):
		vida *= maxf(herois, 1) / 4.0
	var alvo: float = VIDA_HEROI * p["dano"] * r["dano"] * float(cal.get("dano", 1.0))
	# Elite e chefe contra grupos menores: o dano cai junto (metade fixa, metade pelo grupo),
	# senão dois ataques por turno pesam demais em 1 ou 2 heróis.
	if p.get("pelo_grupo", false):
		alvo *= 0.5 + 0.5 * minf(maxf(herois, 1) / 4.0, 1.5)
	if patamar == "lacaio":
		vida = VIDA_LACAIO
	var cfg := {
		"vida": maxi(int(round(vida)), 1),
		"dano": maxi(int(round(alvo - DIFERENCA_MEDIA + RESISTENCIA_MEDIA_HEROI)), 1),
		"atributo_dano": 0, "forca": 0,
		"resistencia": int(r.get("resistencia", 0)),
		"padrao_por_turno": int(p["ataques_por_turno"]),
		"patamar": patamar, "papel": papel,
		"espalha_ataques": p.get("espalha", false),
		"lacaio": patamar == "lacaio",
	}
	if r.get("ataque_oportunidade", false) or patamar in ["elite", "elite_escoltado", "chefe"]:
		cfg["ataque_oportunidade"] = true
		cfg["reacao_por_turno"] = 1
	if r.has("ao_acertar"):
		cfg["ao_acertar"] = r["ao_acertar"].duplicate(true)
	if r.has("cura"):
		cfg["cura_aliado"] = maxi(int(round(DANO_ATAQUE_HEROI * PATAMARES["medio"]["ataques"] * r["cura"])), 1)
	return cfg


## Quantos lacaios e médios cada tipo de combate pede para "herois" heróis.
static func composicao(tipo: String, herois: int) -> Dictionary:
	match tipo:
		"obstaculo":
			return {"lacaio": clampi(int(round(1.75 * herois)), 2, 12)}
		"simples", "complexo":
			return {"lacaio": herois, "medio": herois}
		"elite":
			return {"elite": 1}
		"elite_escoltado":
			return {"elite_escoltado": 1, "lacaio": maxi(herois / 2, 1), "medio": maxi(herois / 2, 1)}
		"chefe":
			return {"chefe": 1, "medio": maxi(herois / 2, 1)}
	return {}
