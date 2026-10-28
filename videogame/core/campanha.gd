## Campanha da guilda (0.15): ouro, feridas que ficam entre missões, compras e descanso.
## Guardada em user://campanha.json. Números PROVISÓRIOS (preços, recompensas, estalagem).
##
## Entre missões (Lucas, 0.16): só as cartas do EXÍLIO continuam perdidas; o descarte
## volta ao baralho. O exílio só se recupera com um descanso longo na estalagem.
## Os consumíveis gastos somem da ficha do herói; os achados entram nela.
extends RefCounted

const Personagem := preload("res://core/personagem.gd")
const Itens := preload("res://core/itens.gd")

const ARQUIVO := "user://campanha.json"
const OURO_INICIAL := 60
const CUSTO_ESTALAGEM := 5            # por herói, descanso longo

## Preços em ouro (inventados para testar; o PDF não traz preços).
const PRECOS := {
	"pocao_de_cura_pequena": 12, "pocao_de_mana_pequena": 12, "antidoto": 8, "tocha": 1,
	"racao_de_viagem": 2, "kit_medico": 10, "bomba_de_fumaca": 15, "frasco_de_piche": 15, "veneno_acido": 12,
}
const PRECO_PADRAO := 10

## Quadro de missões da guilda.
## Campanha (Lucas, 0.19): ciclos de 3 missões — 1ª abre a trama, 2ª a desenrola e aponta
## o problema final, 3ª é a missão grande que a resolve. Ao fechar um ciclo, o grupo sobe
## de nível (começa no 1, termina no 5 depois de 4 ciclos). Cada missão abre a seguinte;
## "requer" lista o que precisa estar cumprido (ou desbloqueado por uma interação).
const MISSOES := [
	{"id": "fazenda", "nome": "A fazenda Vale Seco", "recompensa": 80, "ciclo": 1, "requer": [],
		"texto": "Goblins atacam a fazenda Vale Seco e cavam buracos no milharal. Mas goblins não costumam se arriscar tão perto da vila: do que estão fugindo? Ao ar livre, de dia."},
	{"id": "masmorra", "nome": "A cripta de Pedravelha", "recompensa": 120, "ciclo": 1, "requer": ["fazenda"],
		"texto": "Os túneis dos goblins dão na cripta sob a capela velha, onde os mortos estão se levantando. Descubram quem os acordou. Levem luz: lá embaixo é escuro."},
	{"id": "pantano", "nome": "O Pântano dos Afogados", "recompensa": 150, "ciclo": 1, "requer": ["masmorra"],
		"texto": "O lodo nos ossos de Aldric e a inscrição da cripta apontam para Brejo Fundo, onde a Bruxa Morgana afoga viajantes e chama os mortos. Acabem com ela. Levem fogo: a noite é escura e o lodo prende as pernas."},
	{"id": "catacumbas", "nome": "As Catacumbas de Vel-Dorath", "recompensa": 200,
		"texto": "Uma missão longa: onze salas sob a colina, armadilhas e um guardião que não morre fácil. Levem tochas, cordas e quem saiba procurar armadilhas."},
	{"id": "arena", "nome": "Treino na arena", "recompensa": 0,
		"texto": "Um combate simples contra goblins, para testar o grupo. Não paga nada."},
]

## Ciclos da campanha. Os ciclos 2 a 4 são propostas de trama (sem missões prontas ainda).
const CICLOS := [
	{"numero": 1, "nome": "A Sombra de Pedravelha", "missoes": ["fazenda", "masmorra", "pantano"]},
	{"numero": 2, "nome": "O Pão Podre (em preparação)", "missoes": []},
	{"numero": 3, "nome": "Os Sinos de Ferro (em preparação)", "missoes": []},
	{"numero": 4, "nome": "O Coração que Não Dorme (em preparação)", "missoes": []},
]
const NIVEL_MAXIMO := 5
## XP de cartas por nível do grupo (Lucas, 0.20: +1 por nível; o nível 1 tem os 2 da criação).
const XP_POR_NIVEL := {1: 2, 2: 3, 3: 4, 4: 5, 5: 6}
## Inimigos acompanham o nível do grupo (provisório): +25% de vida e +1 de dano por nível acima do 1.
const VIDA_POR_NIVEL := 0.25
const DANO_POR_NIVEL := 1

static var dados := {}


static func carregar() -> Dictionary:
	if not dados.is_empty():
		return dados
	dados = {"ouro": OURO_INICIAL, "feridas": {}, "concluidas": [], "nivel": 1, "desbloqueadas": []}
	if FileAccess.file_exists(ARQUIVO):
		var d = JSON.parse_string(FileAccess.get_file_as_string(ARQUIVO))
		if d is Dictionary:
			dados.merge(d, true)
	return dados


static func salvar() -> void:
	var f := FileAccess.open(ARQUIVO, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(dados, "\t"))


static func reiniciar() -> void:
	dados = {"ouro": OURO_INICIAL, "feridas": {}, "concluidas": [], "nivel": 1, "desbloqueadas": []}
	salvar()


static func ouro() -> int:
	return int(carregar()["ouro"])


static func preco(item: String) -> int:
	return int(PRECOS.get(item, PRECO_PADRAO))


static func missao(id: String) -> Dictionary:
	for m in MISSOES:
		if m["id"] == id:
			return m
	return {}


static func nivel() -> int:
	return int(carregar().get("nivel", 1))


## Missão disponível? "" = sim; senão o motivo.
static func motivo_trancada(id: String) -> String:
	var m := missao(id)
	if m.is_empty():
		return "missão desconhecida"
	var feitas: Array = carregar()["concluidas"]
	if id in carregar().get("desbloqueadas", []):
		return ""
	for r in m.get("requer", []):
		if not r in feitas:
			return "Termine antes: %s" % missao(r).get("nome", r)
	return ""


static func ciclo_completo(numero: int) -> bool:
	for c in CICLOS:
		if int(c["numero"]) == numero:
			if c["missoes"].is_empty():
				return false
			for id in c["missoes"]:
				if not id in carregar()["concluidas"]:
					return false
			return true
	return false


## Sobe o nível do grupo quando um ciclo fecha. Devolve o texto (vazio se não subiu).
static func _verificar_nivel() -> String:
	var n := 1
	for c in CICLOS:
		if ciclo_completo(int(c["numero"])):
			n += 1
	n = mini(n, NIVEL_MAXIMO)
	if n <= nivel():
		return ""
	dados["nivel"] = n
	var xp := int(XP_POR_NIVEL.get(n, 2 * n))
	var fichas := Personagem.carregar_todos()
	for f in fichas:
		f["xp"] = maxi(int(f.get("xp", 2)), xp)
	Personagem.salvar_todos(fichas)
	return "O GRUPO SOBE PARA O NÍVEL %d! Cada herói agora tem %d de XP para cartas de habilidade: escolha as novas em \"Heróis e grupo\"." % [n, xp]


## Interação que abre outra missão (efeito "desbloquear" em Batalha).
static func desbloquear(id: String) -> void:
	carregar()
	if not id in dados["desbloqueadas"]:
		dados["desbloqueadas"].append(id)
		salvar()


## Cartas que o herói perdeu e ainda não recuperou: {"exilio": n, "descarte": n}.
static func feridas_de(nome: String) -> Dictionary:
	return carregar()["feridas"].get(nome, {"exilio": 0, "descarte": 0})


## Início de missão: tira do baralho as cartas que estavam no exílio e no descarte.
static func aplicar(b) -> void:
	var extra := nivel() - 1
	if extra > 0:
		for o in b.unidades:
			if not o.eh_heroi():
				o.vida_max = int(round(o.vida_max * (1.0 + VIDA_POR_NIVEL * extra)))
				o.vida = o.vida_max
				o.dano += DANO_POR_NIVEL * extra
	for u in b.herois():
		var f := feridas_de(u.nome)
		for i in int(f.get("exilio", 0)):
			if u.baralho.baralho.size() > 1:
				u.baralho.exilio.append(u.baralho.baralho.pop_back())


## Fim de missão: paga o contrato (só na vitória), soma o ouro achado, guarda as
## feridas e os consumíveis de cada herói. Devolve o texto do resumo.
static func registrar_fim(b, modo: String, vitoria: bool) -> String:
	carregar()
	var linhas := PackedStringArray()
	var ganho: int = int(b.ouro_ganho) + (int(b.recompensa) if vitoria else 0)
	dados["ouro"] = int(dados["ouro"]) + ganho
	linhas.append("Ouro: +%d (achado %d%s). Total: %d." % [ganho, int(b.ouro_ganho),
		(", contrato %d" % int(b.recompensa)) if vitoria and int(b.recompensa) > 0 else "", int(dados["ouro"])])
	if vitoria and not modo in dados["concluidas"]:
		dados["concluidas"].append(modo)
	var fichas := Personagem.carregar_todos()
	for u in b.herois():
		var perdidas := {"exilio": u.baralho.exilio.size(), "descarte": 0}
		dados["feridas"][u.nome] = perdidas
		linhas.append("%s: %d carta(s) no exílio%s." % [u.nome, perdidas["exilio"], " (só voltam com o descanso longo)" if perdidas["exilio"] > 0 else ""])
		for f in fichas:
			if f["nome"] == u.nome:
				f["consumiveis"] = u.consumiveis.duplicate()
	Personagem.salvar_todos(fichas)
	for id in b.missoes_desbloqueadas:
		if not id in dados["desbloqueadas"]:
			dados["desbloqueadas"].append(id)
			linhas.append("Pista nova: a missão \"%s\" entrou no quadro da guilda." % missao(id).get("nome", id))
	if vitoria:
		var subiu := _verificar_nivel()
		if subiu != "":
			linhas.append(subiu)
		for m in MISSOES:
			if m.get("requer", []).has(modo) and motivo_trancada(m["id"]) == "":
				linhas.append("Nova missão no quadro da guilda: %s." % m["nome"])
	salvar()
	return "\n".join(linhas)


## Descanso longo na estalagem: CUSTO_ESTALAGEM por herói; recompõe tudo.
static func custo_descanso(nomes: Array) -> int:
	return CUSTO_ESTALAGEM * nomes.size()


static func descansar(nomes: Array) -> bool:
	carregar()
	var custo := custo_descanso(nomes)
	if int(dados["ouro"]) < custo:
		return false
	dados["ouro"] = int(dados["ouro"]) - custo
	for nome in nomes:
		dados["feridas"].erase(nome)
	salvar()
	return true


## Compra um consumível para o herói (vai para a ficha salva).
const PRECO_PESO := {"leve": 20, "media": 35, "pesada": 50}
const PRECO_ARMADURA := {"leve": 30, "media": 60, "pesada": 100}
const PRECO_ESCUDO := {"escudo_leve": 20, "escudo_pesado": 40}


static func preco_equip(campo: String, id: String) -> int:
	match campo:
		"arma":
			return int(PRECO_PESO.get(Itens.ARMAS[id].get("peso", "media"), 35))
		"armadura":
			return int(PRECO_ARMADURA.get(Itens.ARMADURAS[id].get("classe", "media"), 60))
	return int(PRECO_ESCUDO.get(id, 30))


## Ferreiro (0.23): arma vai para a reserva; armadura e escudo trocam os atuais.
## Devolve "" se comprou, ou o motivo.
static func comprar_equip(nome_heroi: String, campo: String, id: String) -> String:
	carregar()
	var preco := preco_equip(campo, id)
	if int(dados["ouro"]) < preco:
		return "Ouro insuficiente."
	var fichas := Personagem.carregar_todos()
	for f in fichas:
		if f["nome"] != nome_heroi:
			continue
		var chave: String = {"arma": "arma2", "armadura": "armadura", "escudo": "escudo"}[campo]
		var antes = f.get(chave, "")
		f[chave] = id
		var erros := Personagem.validar(f)
		if not erros.is_empty():
			f[chave] = antes
			return "Não dá: " + erros[0]
		dados["ouro"] = int(dados["ouro"]) - preco
		Personagem.salvar_todos(fichas)
		salvar()
		return ""
	return "Herói não encontrado (salve o herói antes)."


static func preco_venda(item: String) -> int:
	return int(Itens.CONSUMIVEIS.get(item, {}).get("venda", int(preco(item) / 2)))


static func vender(nome_heroi: String, item: String) -> bool:
	carregar()
	var fichas := Personagem.carregar_todos()
	for f in fichas:
		if f["nome"] == nome_heroi and item in f["consumiveis"]:
			f["consumiveis"].erase(item)
			dados["ouro"] = int(dados["ouro"]) + preco_venda(item)
			Personagem.salvar_todos(fichas)
			salvar()
			return true
	return false


static func comprar(nome_heroi: String, item: String) -> bool:
	carregar()
	if int(dados["ouro"]) < preco(item) or not Itens.CONSUMIVEIS.has(item) or not Itens.CONSUMIVEIS[item].get("loja", true):
		return false
	var fichas := Personagem.carregar_todos()
	for f in fichas:
		if f["nome"] == nome_heroi:
			f["consumiveis"].append(item)
			dados["ouro"] = int(dados["ouro"]) - preco(item)
			Personagem.salvar_todos(fichas)
			salvar()
			return true
	return false
