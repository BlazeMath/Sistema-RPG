## Campanha da guilda (0.15): dinheiro, feridas que ficam entre missões, compras e descanso.
## Guardada em user://campanha.json.
##
## Economia (Lucas, 0.25, "Estudo de economia e preços"): 1 ouro (PO) = 100 pratas (PP) =
## 1.000 cobres (PC). O dinheiro é guardado em COBRE ("cobre"). Preços dos 170 itens no
## catálogo (core/itens.gd); revenda pela loja de origem (vila e cidade 40%, especialista 35%,
## encomenda 30%, relíquia 25%). Contratos de aldeia e pequena guilda: 80–200 pratas para o
## grupo. Descanso atendido na estalagem: 5 pratas por herói.
##
## Entre missões (Lucas, 0.16): só as cartas do EXÍLIO continuam perdidas; o descarte
## volta ao baralho. O exílio só se recupera com um descanso longo na estalagem.
## Os consumíveis gastos somem da ficha do herói; os achados entram nela.
extends RefCounted

const Personagem := preload("res://core/personagem.gd")
const Itens := preload("res://core/itens.gd")
const DossieGuilda := preload("res://core/dossie_guilda.gd")

const ARQUIVO := "user://campanha.json"
const COBRE_POR_PRATA := 10
const PRATA_POR_OURO := 100
const DINHEIRO_INICIAL := 600         # cobre (60 pratas para o grupo)
const CUSTO_ESTALAGEM := 50           # cobre por herói (5 pratas), descanso longo
## Lojas da vila: vila (V), cidade (C) e especialista (E) têm estoque; encomenda (O) chega
## depois da próxima missão; relíquias (R) não se compram, só se acham.
const MERCADOS_DA_VILA := ["V", "C", "E"]
const NOMES_MERCADO := {"V": "comércio da vila", "C": "loja de cidade", "E": "especialista", "O": "encomenda", "R": "relíquia"}

## Quadro de missões da guilda. "recompensa" em PRATAS, para o grupo (contrato na vitória).
## Campanha (Lucas, 0.19): ciclos de 3 missões — 1ª abre a trama, 2ª a desenrola e aponta
## o problema final, 3ª é a missão grande que a resolve. Ao fechar um ciclo, o grupo sobe
## de nível (começa no 1, termina no 5 depois de 4 ciclos). Cada missão abre a seguinte;
## "requer" lista o que precisa estar cumprido (ou desbloqueado por uma interação).
const MISSOES := [
	{"id": "fazenda", "nome": "A fazenda Vale Seco", "recompensa": 100, "ciclo": 1, "requer": [],
		"texto": "Goblins atacam a fazenda Vale Seco e cavam buracos no milharal. Mas goblins não costumam se arriscar tão perto da vila: do que estão fugindo? Ao ar livre, de dia."},
	{"id": "masmorra", "nome": "A cripta de Pedravelha", "recompensa": 150, "ciclo": 1, "requer": ["fazenda"],
		"texto": "Os túneis dos goblins dão na cripta sob a capela velha, onde os mortos estão se levantando. Descubram quem os acordou. Levem luz: lá embaixo é escuro."},
	{"id": "pantano", "nome": "O Pântano dos Afogados", "recompensa": 200, "ciclo": 1, "requer": ["masmorra"],
		"texto": "O lodo nos ossos de Aldric e a inscrição da cripta apontam para Brejo Fundo, onde a Bruxa Morgana afoga viajantes e chama os mortos. Acabem com ela. Levem fogo: a noite é escura e o lodo prende as pernas."},
	{"id": "catacumbas", "nome": "As Catacumbas de Vel-Dorath", "recompensa": 300,
		"texto": "Uma missão longa: onze salas sob a colina, armadilhas e um guardião que não morre fácil. Levem tochas, cordas e quem saiba procurar armadilhas."},
	{"id": "arena", "nome": "Treino na arena", "recompensa": 0,
		"texto": "Um combate simples contra goblins, para testar o grupo. Não paga nada."},
]

## Ciclos da campanha. Os ciclos 3 e 4 ainda estão em preparação.
const CICLOS := [
	{"numero": 1, "nome": "A Sombra de Pedravelha", "missoes": ["fazenda", "masmorra", "pantano"]},
	{"numero": 2, "nome": "O Círculo Rubro", "missoes": ["fase:investigacao_vau_cinzento", "fase:bandidos_cao_vermelho", "fase:baile_mascaras_prata"]},
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
## 0.26: a party online guarda a campanha na pasta dela; nos convidados a campanha é só memória.
static var arquivo := ARQUIVO
static var memoria := false


static func carregar() -> Dictionary:
	if not dados.is_empty():
		_migrar(dados)
		return dados
	dados = _novos_dados()
	if not memoria and FileAccess.file_exists(arquivo):
		var d = JSON.parse_string(FileAccess.get_file_as_string(arquivo))
		if d is Dictionary:
			dados.erase("cobre")
			dados.merge(d, true)
	_migrar(dados)
	return dados


static func _novos_dados() -> Dictionary:
	return {"cobre": DINHEIRO_INICIAL, "feridas": {}, "concluidas": [], "nivel": 1, "desbloqueadas": [], "encomendas": [], "dossie": {}}


## Campanhas de antes da 0.25 guardavam "ouro" na escala de uma prata (poção = 12).
static func _migrar(d: Dictionary) -> void:
	if d.has("ouro") and not d.has("cobre"):
		d["cobre"] = int(d["ouro"]) * COBRE_POR_PRATA
	d.erase("ouro")
	if not d.has("encomendas"):
		d["encomendas"] = []
	# As fases do segundo ciclo já podiam ser vencidas como contratos do mural.
	# A campanha do convidado recebe nível e fichas já atualizados do anfitrião.
	var nivel_migrado := false
	if not memoria and not d.get("ciclo_rubro_migrado", false):
		d["ciclo_rubro_migrado"] = true
		nivel_migrado = _atualizar_nivel_de_ciclos(d) != ""
	DossieGuilda.atualizar(d)
	if nivel_migrado and is_same(d, dados):
		salvar()


## Dinheiro do grupo em cobre.
static func dinheiro() -> int:
	return int(carregar()["cobre"])


static func dossie() -> Dictionary:
	return carregar()["dossie"].duplicate(true)


## Mantido para o código antigo: dinheiro em cobre.
static func ouro() -> int:
	return dinheiro()


## "1 PO 20 PP 5 PC" (só as moedas que aparecem; 0 = "0 PC").
static func moeda(cobre: int) -> String:
	var po := cobre / (COBRE_POR_PRATA * PRATA_POR_OURO)
	var resto := cobre % (COBRE_POR_PRATA * PRATA_POR_OURO)
	var pp := resto / COBRE_POR_PRATA
	var pc := resto % COBRE_POR_PRATA
	var partes := PackedStringArray()
	if po > 0:
		partes.append("%d PO" % po)
	if pp > 0:
		partes.append("%d PP" % pp)
	if pc > 0 or partes.is_empty():
		partes.append("%d PC" % pc)
	return " ".join(partes)


## Jogo em rede (0.26): as ações da vila que mudam a campanha, por nome (o anfitrião roda
## os pedidos dos convidados por aqui).
static func executar(metodo: String, args: Array) -> Variant:
	match metodo:
		"comprar_item":
			return comprar_item(str(args[0]), str(args[1]), bool(args[2]) if args.size() > 2 else false)
		"vender":
			return vender(str(args[0]), str(args[1]))
		"descansar":
			return descansar(args[0])
	return null


static func salvar() -> void:
	if memoria:
		return
	var f := FileAccess.open(arquivo, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(dados, "\t"))


static func reiniciar() -> void:
	dados = _novos_dados()
	salvar()


## Preço de compra em cobre (catálogo).
static func preco(item: String) -> int:
	return Itens.preco(item)


## A loja da vila vende este item? "" = sim; senão o motivo.
static func motivo_sem_venda(item: String) -> String:
	var d: Dictionary = Itens.item(item)
	if d.is_empty() or not d.get("loja", true):
		return "não se vende"
	match str(d.get("mercado", "V")):
		"O":
			return "só por encomenda"
		"R":
			return "relíquia: não se compra, só se acha"
	return ""


## Missões do mural: as feitas à mão e as fases do editor marcadas "no mural" (0.27).
static func missoes() -> Array:
	return MISSOES + preload("res://core/fase.gd").missoes_do_mural()


static func missao(id: String) -> Dictionary:
	for m in missoes():
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
	var estado := carregar()
	var feitas: Array = estado["concluidas"]
	if id in CICLOS[1]["missoes"]:
		for r in CICLOS[0]["missoes"]:
			if not r in feitas:
				return "Termine antes: %s" % missao(r).get("nome", r)
	elif id in estado.get("desbloqueadas", []):
		return ""
	for r in m.get("requer", []):
		if not r in feitas:
			return "Termine antes: %s" % missao(r).get("nome", r)
	return ""


static func ciclo_completo(numero: int) -> bool:
	var feitas: Array = carregar()["concluidas"]
	for c in CICLOS:
		if int(c["numero"]) == numero:
			return _missoes_completas(c["missoes"], feitas)
	return false


static func _missoes_completas(ids: Array, feitas: Array) -> bool:
	return not ids.is_empty() and ids.all(func(id): return id in feitas)


## Sobe o nível do grupo quando um ciclo fecha. Devolve o texto (vazio se não subiu).
static func _verificar_nivel() -> String:
	return _atualizar_nivel_de_ciclos(dados if not dados.is_empty() else carregar())


static func _atualizar_nivel_de_ciclos(estado: Dictionary) -> String:
	var n := 1
	var feitas: Array = estado.get("concluidas", [])
	for c in CICLOS:
		if not _missoes_completas(c["missoes"], feitas):
			break
		n += 1
	n = mini(n, NIVEL_MAXIMO)
	if n <= int(estado.get("nivel", 1)):
		return ""
	estado["nivel"] = n
	var xp := int(XP_POR_NIVEL.get(n, 2 * n))
	if not memoria or Personagem.memoria is Array:
		var fichas := Personagem.carregar_todos()
		for f in fichas:
			f["xp"] = maxi(int(f.get("xp", 2)), xp)
			f["nivel_pacto"] = maxi(int(f.get("nivel_pacto", 1)), n)   # Bruxo: o pacto acompanha o nível do grupo
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
	var contrato := int(missao(modo).get("recompensa", 0)) * COBRE_POR_PRATA if vitoria else 0
	var ganho: int = int(b.ouro_ganho) + contrato
	dados["cobre"] = int(dados["cobre"]) + ganho
	linhas.append("Dinheiro: +%s (achado %s%s). Total: %s." % [moeda(ganho), moeda(int(b.ouro_ganho)),
		(", contrato %s" % moeda(contrato)) if contrato > 0 else "", moeda(int(dados["cobre"]))])
	if vitoria and not dados["encomendas"].is_empty():
		linhas.append(_entregar_encomendas())
	if vitoria and not modo in dados["concluidas"]:
		dados["concluidas"].append(modo)
	if vitoria:
		var arquivadas := DossieGuilda.registrar_vitoria(dados, b, modo)
		if arquivadas > 0:
			linhas.append("Dossiê da guilda: %d novo(s) registro(s)." % arquivadas)
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
		for m in missoes():
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
	if int(dados["cobre"]) < custo:
		return false
	dados["cobre"] = int(dados["cobre"]) - custo
	for nome in nomes:
		dados["feridas"].erase(nome)
	salvar()
	return true


## Preço de equipamento do ferreiro (cobre).
static func preco_equip(_campo: String, id: String) -> int:
	return Itens.preco(id)


## Campo da ficha onde o item entra.
static func campo_do_item(id: String) -> String:
	if Itens.ARMAS.has(id):
		return "arma"
	if Itens.ARMADURAS.has(id):
		return "armadura"
	if Itens.ESCUDOS.has(id):
		return "escudo"
	if Itens.FOCOS.has(id):
		return "foco"
	if Itens.GRIMORIOS.has(id):
		return "grimorio"
	if Itens.CONSUMIVEIS.has(id):
		return "consumivel"
	var d: Dictionary = Itens.NAO_CONSUMIVEIS.get(id, {})
	return str(d.get("espaco", "mochila"))


## Compra qualquer item para o herói (0.25). Armas vão para a segunda arma; armadura,
## escudo, foco e peças de vestir trocam as atuais (a antiga é vendida pela revenda);
## acessórios e grimórios entram se houver espaço; o resto vai para a mochila ou a bolsa.
## Devolve "" se comprou, ou o motivo.
static func comprar_item(nome_heroi: String, id: String, encomenda := false) -> String:
	carregar()
	var motivo := motivo_sem_venda(id)
	if motivo != "" and not (encomenda and motivo == "só por encomenda"):
		return motivo[0].to_upper() + motivo.substr(1)
	var preco_item := preco(id)
	if int(dados["cobre"]) < preco_item:
		return "Dinheiro insuficiente."
	var fichas := Personagem.carregar_todos()
	for f in fichas:
		if f["nome"] != nome_heroi:
			continue
		if encomenda:
			dados["cobre"] = int(dados["cobre"]) - preco_item
			dados["encomendas"].append({"heroi": nome_heroi, "item": id})
			salvar()
			return ""
		var antes: Dictionary = f.duplicate(true)
		var vendido := _equipar(f, id)
		var erros := Personagem.validar(f)
		erros = erros.filter(func(e): return not e in Personagem.validar(antes))
		if not erros.is_empty():
			return "Não dá: " + erros[0]
		dados["cobre"] = int(dados["cobre"]) - preco_item
		if vendido != "":
			dados["cobre"] = int(dados["cobre"]) + preco_venda(vendido)
		Personagem.salvar_todos(fichas)
		salvar()
		return ""
	return "Herói não encontrado (salve o herói antes)."


## Põe o item na ficha. Devolve o id da peça trocada (vendida), ou "".
static func _equipar(f: Dictionary, id: String) -> String:
	var campo := campo_do_item(id)
	match campo:
		"arma":
			var velha: String = f.get("arma2", "nenhuma")
			f["arma2"] = id
			return "" if velha == "nenhuma" else velha
		"armadura", "escudo", "foco", "costas", "cabeca", "pes":
			var velho: String = str(f.get(campo, "nenhum"))
			f[campo] = id
			return "" if velho in ["nenhum", "nenhuma"] else velho
		"grimorio":
			if not id in f["grimorios"]:
				f["grimorios"].append(id)
		"acessorios":
			f["acessorios"].append(id)
		"consumivel":
			f["consumiveis"].append(id)
		_:
			f["mochila"].append(id)
	return ""


## Ferreiro (0.23, mantido): compra de arma, armadura ou escudo.
static func comprar_equip(nome_heroi: String, _campo: String, id: String) -> String:
	return comprar_item(nome_heroi, id)


## Encomendas chegam ao fim da próxima missão vencida.
static func _entregar_encomendas() -> String:
	var fichas := Personagem.carregar_todos()
	var nomes := PackedStringArray()
	for e in dados["encomendas"]:
		for f in fichas:
			if f["nome"] == e["heroi"]:
				_equipar(f, e["item"])
				nomes.append("%s (%s)" % [Itens.nome(e["item"]), e["heroi"]])
	dados["encomendas"] = []
	Personagem.salvar_todos(fichas)
	return "Encomendas entregues: %s." % ", ".join(nomes)


## Valor de revenda em cobre (pela loja de origem do item).
static func preco_venda(item: String) -> int:
	var d: Dictionary = Itens.item(item)
	if d.has("venda"):
		return int(d["venda"])
	return int(floor(float(d.get("preco", 0)) * float(d.get("revenda", 0.4))))


static func vender(nome_heroi: String, item: String) -> bool:
	carregar()
	var fichas := Personagem.carregar_todos()
	for f in fichas:
		if f["nome"] != nome_heroi:
			continue
		var achou := false
		for chave in ["consumiveis", "mochila", "acessorios", "grimorios"]:
			if item in f.get(chave, []):
				f[chave].erase(item)
				achou = true
				break
		if not achou:
			for chave in ["costas", "cabeca", "pes"]:
				if f.get(chave, "") == item:
					f[chave] = "nenhum"
					achou = true
					break
		if not achou and f.get("arma2", "") == item:
			f["arma2"] = "nenhuma"
			achou = true
		if not achou:
			return false
		dados["cobre"] = int(dados["cobre"]) + preco_venda(item)
		Personagem.salvar_todos(fichas)
		salvar()
		return true
	return false


## Compra um consumível (mercado). Mantido para o código antigo.
static func comprar(nome_heroi: String, item: String) -> bool:
	return comprar_item(nome_heroi, item) == ""
