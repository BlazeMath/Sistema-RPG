## Ficha de personagem criada pelo jogador e salva em disco.
##
## Atributos: o jogador distribui exatamente 3, 3, 2, 2, 1, 1, 1, 0, 0.
## Cartas de habilidade: o custo em XP somado não passa do XP do personagem;
## meias cartas entram em pares, e cada par forma uma carta de 1 XP.
## Carta de herói: duas metades entre as da classe, da raça e do background.
## Itens: arma, armadura e escudo comuns, e consumíveis comuns.
extends RefCounted

const Catalogo := preload("res://core/catalogo.gd")
const Devocoes := preload("res://core/devocoes.gd")
const Efeitos := preload("res://core/efeitos.gd")
const Itens := preload("res://core/itens.gd")
const CartaEmJogo := preload("res://core/carta_em_jogo.gd")

const ATRIBUTOS := ["forca", "destreza", "constituicao", "percepcao", "sabedoria", "raciocinio", "espirito", "mentira", "diplomacia"]
const NOMES_ATRIBUTOS := {"forca": "Força", "destreza": "Destreza", "constituicao": "Constituição", "percepcao": "Percepção",
	"sabedoria": "Sabedoria", "raciocinio": "Raciocínio", "espirito": "Espírito", "mentira": "Mentira", "diplomacia": "Diplomacia"}
const DISTRIBUICAO := [3, 3, 2, 2, 1, 1, 1, 0, 0]
## O que cada atributo dá na batalha (0.21: mostrado na criação e na ficha).
## "base" vale sempre; 3 e 5 são os efeitos desses valores (5 inclui o de 3).
const EFEITOS_ATRIBUTO := {
	"forca": {"base": "Soma no dano das armas médias e pesadas.", 3: "Dano mesmo errando: o ataque que erra causa a Força de dano.", 5: "Errando, causa a Força + o dano da arma."},
	"destreza": {"base": "Soma no dano das armas leves e de tiro; entra na iniciativa.", 3: "+1 de Velocidade.", 5: "Ao se defender bem, anda 1 quadrado (esquiva)."},
	"constituicao": {"base": "Recuperar o Fôlego cura esse valor.", 3: "Regeneração 1 no início do turno (com 2+ cartas no descarte).", 5: "Curas trazem primeiro as cartas do exílio."},
	"percepcao": {"base": "Testes de perceber e procurar.", 3: "No seu ataque, a carta fechada do defensor fica à vista.", 5: "No seu ataque, você vê o topo do baralho do defensor."},
	"sabedoria": {"base": "Mão inicial = 2 + Sabedoria; atributo da magia do Clérigo.", 3: "Uma vez por teste: +1 ou −1.", 5: "Mulligan: devolve a mão e compra de novo, uma vez no começo da cena."},
	"raciocinio": {"base": "Atributo da magia do Mago.", 3: "Planejar deixa reordenar as cartas do topo.", 5: "Planejar também compra 1 carta."},
	"espirito": {"base": "Descanso curto devolve esse número de cartas do exílio ao descarte.", 3: "Ação Comandar: um aliado compra 1 carta.", 5: "Comandar compra 2."},
	"mentira": {"base": "Enganar e blefar.", 3: "Uma carta do seu ataque volta ao baralho.", 5: "Se a carta veio da mão, volta para o topo do baralho."},
	"diplomacia": {"base": "Ação Orientar (1 Foco num aliado), esse número de vezes por cena.", 3: "", 5: "Inconsciente, o dano exila só metade das cartas."},
}


static func texto_atributo(nome: String, valor: int) -> String:
	var e: Dictionary = EFEITOS_ATRIBUTO.get(nome, {})
	var linhas := PackedStringArray([str(e.get("base", ""))])
	for n in [3, 5]:
		if str(e.get(n, "")) != "":
			linhas.append("%s %d: %s%s" % ["✔" if valor >= n else "·", n, e[n], "" if valor >= n else " (ainda não)"])
	return "\n".join(linhas)
const ARQUIVO := "user://herois.json"
## 0.26: no jogo em rede o anfitrião troca para os heróis da party; os convidados guardam
## a cópia do anfitrião só na memória (memoria != null: carregar/salvar não tocam no disco).
static var arquivo := ARQUIVO
static var memoria = null

const CLASSES := ["Guerreiro", "Ladino", "Clérigo", "Caçador", "Mago", "Bruxo", "Investigador", "Invocador"]
const RACAS := ["Humano", "Elfo", "Anão", "Halfling", "Orc"]
const BACKGROUNDS := ["Soldado", "Bandido", "Escravo", "Explorador", "Fervoroso"]
const DISPONIVEIS := CLASSES + RACAS + BACKGROUNDS   # versão 0.9: tudo liberado

## Cartas que pedem escolhas na criação (pela "slug" do lado ou da metade de herói).
## tipo "pericia": escolhe perícias; "atributo": escolhe atributos (só os listados).
const ESCOLHAS := {
	"mente-maleavel": {"tipo": "pericia", "qtd": 2, "bonus": 2, "texto": "Mente Maleável: duas perícias com valor menor que 3 (+2)", "menor_que": 3},
	"aprendiz-silencioso": {"tipo": "pericia", "qtd": 3, "bonus": 1, "texto": "Aprendiz Silencioso: três perícias (+1)"},
	"maestria-de-uma-vida": {"tipo": "pericia", "qtd": 1, "limite": 2, "texto": "Maestria de uma Vida: uma perícia (+2 no limite)"},
	"mil-oficios": {"tipo": "pericia", "qtd": 2, "bonus": 1, "texto": "Mil Ofícios: duas perícias adicionais (+1)"},
	"mil-oficios-atributo": {"tipo": "atributo", "qtd": 1, "bonus": 1, "texto": "Mil Ofícios: um atributo mental ou social (+1)",
		"opcoes": ["percepcao", "sabedoria", "raciocinio", "espirito", "mentira", "diplomacia"], "carta": "mil-oficios"},
	# Bruxo (0.25): o patrono secundário da carta Pacto Menor / Procuração.
	"pacto-menor": {"tipo": "pacto", "qtd": 1, "texto": "Pacto Menor: o patrono secundário"},
}
const TAMANHOS := {"Halfling": "pequeno"}

## Perícias (livro, cap. 5): 13 físicas, 13 mentais e 13 sociais.
## O jogador escolhe quatro com 3, seis com 2 e oito com 1; o resto fica 0.
const PERICIAS := {
	"Físico": ["Acrobacia", "Atletismo", "Cavalgar", "Direção", "Escalada", "Furtividade", "Iniciativa",
		"Ladinagem", "Luta", "Natação", "Pontaria"],
	"Mental": ["Arcanismo", "Ciência", "Guerra", "História", "Investigação", "Literatura", "Medicina", "Monstros",
		"Natureza", "Ocultismo", "Ofício", "Religião", "Sobrevivência"],
	"Social": ["Acalmar", "Adestramento", "Arte", "Atuação", "Intimidação", "Intuição", "Irritar",
		"Jogatina", "Liderança", "Negociação", "Nobreza", "Política"],
}
const DISTRIBUICAO_PERICIAS := {3: 4, 2: 6, 1: 8}
const TIPOS_CLASSE := {"Guerreiro": "guerreiro", "Ladino": "ladino", "Clérigo": "clerigo", "Caçador": "cacador", "Mago": "mago",
	"Bruxo": "bruxo", "Investigador": "investigador", "Invocador": "invocador"}


static func nova() -> Dictionary:
	return {
		"nome": "Guerreiro de Teste",
		"classe": "Guerreiro", "raca": "Humano", "background": "Soldado",
		"xp": 2,
		"atributos": {"forca": 3, "destreza": 2, "constituicao": 3, "percepcao": 1, "sabedoria": 2,
			"raciocinio": 1, "espirito": 1, "mentira": 0, "diplomacia": 0},
		"cartas": ["classe.guerreiro.ombro-de-ferro", "classe.guerreiro.postura-do-leao"],
		"meias": [],
		"herois": ["classe.guerreiro.heroi.foco-mortal", "raca.humano.heroi.incansavel"],
		"arma": "espada_longa",
		"arma2": "nenhuma",
		"armadura": "cota_de_malha",
		"escudo": "escudo_leve",
		"consumiveis": ["pocao_de_cura_pequena", "tocha", "tocha", "tocha"],
		"foco": "nenhum",
		"costas": "nenhum", "cabeca": "nenhum", "pes": "nenhum",
		"acessorios": ["bandoleira_de_armas"],
		"grimorios": [],
		"mochila": Itens.MOCHILA_INICIAL.duplicate(),
		"divindade": "aurora",
		"escolhas": {},
		"pericias": {
			"Atletismo": 3, "Luta": 3, "Intimidação": 3, "Sobrevivência": 3,
			"Escalada": 2, "Natação": 2, "Guerra": 2, "Liderança": 2, "Medicina": 2, "Acrobacia": 2,
			"Pontaria": 1, "Iniciativa": 1, "Cavalgar": 1, "Monstros": 1, "Natureza": 1, "Intuição": 1, "Furtividade": 1, "Religião": 1,
		},
	}


## Quantas perícias estão com 3, 2 e 1.
static func contagem_pericias(ficha: Dictionary) -> Dictionary:
	var c := {3: 0, 2: 0, 1: 0}
	for nome in ficha.get("pericias", {}):
		var v := int(ficha["pericias"][nome])
		if c.has(v):
			c[v] += 1
	return c


static func custo_xp(ficha: Dictionary) -> int:
	var total := 0
	var gratis := _repertorio_gratis(ficha)
	for id in ficha["cartas"]:
		if id == gratis:
			continue
		total += int(Catalogo.habilidade(id).get("xp", 1))
	total += int(ficha["meias"].size() / 2.0 + 0.5)
	return total


## Devorador de Grimórios (passiva): um repertório básico (carta "Aprendiz") custa 0 de XP.
## O jogo escolhe o de maior custo entre os que o herói pegou (0.20).
static func _repertorio_gratis(ficha: Dictionary) -> String:
	if not "classe.mago.heroi.devorador-de-grimorios" in ficha.get("herois", []):
		return ""
	var melhor := ""
	var melhor_xp := -1
	for id in ficha["cartas"]:
		var h: Dictionary = Catalogo.habilidade(id)
		var tags: Array = h.get("lados", [{}])[0].get("tags", []) if not h.get("lados", []).is_empty() and h["lados"][0] != null else []
		if "Aprendiz" in tags and int(h.get("xp", 1)) > melhor_xp:
			melhor = id
			melhor_xp = int(h.get("xp", 1))
	return melhor


## Lista de problemas que impedem salvar/jogar. Vazia = ficha válida.
static func validar(ficha: Dictionary) -> Array[String]:
	var erros: Array[String] = []
	if str(ficha["nome"]).strip_edges() == "":
		erros.append("Dê um nome ao personagem.")
	var valores := []
	for a in ATRIBUTOS:
		valores.append(int(ficha["atributos"].get(a, 0)))
	valores.sort()
	var esperado := DISTRIBUICAO.duplicate()
	esperado.sort()
	if valores != esperado:
		erros.append("Distribua os atributos assim: dois 3, dois 2, três 1 e dois 0.")
	var cp := contagem_pericias(ficha)
	for v in [3, 2, 1]:
		if cp[v] != DISTRIBUICAO_PERICIAS[v]:
			erros.append("Distribua as perícias: quatro com 3, seis com 2 e oito com 1.")
			break
	if custo_xp(ficha) > int(ficha["xp"]):
		erros.append("As cartas custam %d de XP, mas o personagem tem %d." % [custo_xp(ficha), ficha["xp"]])
	if ficha["meias"].size() % 2 == 1:
		erros.append("Meias cartas entram em pares: escolha mais uma (ou tire uma).")
	if ficha["herois"].size() != 2:
		erros.append("Escolha exatamente 2 metades de carta de herói.")
	if ficha["classe"] == "Bruxo":
		var patronos: Array = ficha["herois"].filter(func(h): return Catalogo.heroi(h).has("pacto"))
		if patronos.size() != 1:
			erros.append("O Bruxo põe exatamente 1 patrono (pacto pleno) na carta de herói; a outra metade é da raça ou do background.")
		var menor: Array = ficha.get("escolhas", {}).get("pacto-menor", [])
		if not menor.is_empty() and menor[0] == Catalogo.pacto_da_ficha(ficha):
			erros.append("O Pacto Menor precisa de outro patrono (não o do pacto pleno).")
	var arma: Dictionary = Itens.ARMAS[ficha["arma"]]
	if int(ficha["atributos"]["forca"]) < arma["forca_min"]:
		erros.append("%s exige Força %d." % [arma["nome"], arma["forca_min"]])
	if ficha["escudo"] != "nenhum" and (arma.get("duas_maos", false) or arma["tamanho"] == "grande"):
		erros.append("Escudo ocupa uma mão: não combina com %s." % arma["nome"])
	if int(ficha["atributos"].get("destreza", 0)) < int(arma.get("destreza_min", 0)):
		erros.append("%s exige Destreza %d." % [arma["nome"], int(arma["destreza_min"])])
	erros.append_array(erros_de_inventario(ficha))
	for gid in ficha.get("grimorios", []):
		var motivo := motivo_grimorio(ficha, gid)
		if motivo != "":
			erros.append(motivo)
	var arma2: Dictionary = Itens.ARMAS.get(ficha.get("arma2", "nenhuma"), {})
	if not arma2.is_empty() and int(ficha["atributos"]["forca"]) < int(arma2["forca_min"]):
		erros.append("%s (segunda arma) exige Força %d." % [arma2["nome"], arma2["forca_min"]])
	var foco: Dictionary = Itens.FOCOS.get(ficha.get("foco", "nenhum"), Itens.FOCOS["nenhum"])
	if foco["tipo"] != "" and Itens.TIPO_DE_FOCO.get(ficha["classe"], "") != foco["tipo"]:
		erros.append("%s é um foco %s: só %s usa." % [foco["nome"], foco["tipo"], "o Mago e o Bruxo" if foco["tipo"] == "arcano" else "o Clérigo"])
	if int(foco["maos"]) > 0 and ficha["escudo"] != "nenhum":
		erros.append("O foco ocupa a mão do escudo: escolha um ou outro.")
	if int(foco["maos"]) == 2 and (arma.get("duas_maos", false) or arma["tamanho"] == "grande"):
		erros.append("O cajado usa as duas mãos: não combina com %s." % arma["nome"])
	for chave in escolhas_pendentes(ficha):
		var e: Dictionary = ESCOLHAS[chave]
		var feitas: Array = ficha.get("escolhas", {}).get(chave, [])
		if feitas.size() != int(e["qtd"]):
			erros.append("Faça as escolhas de %s." % e["texto"].split(":")[0])
		elif e.has("menor_que") and feitas.any(func(p): return int(ficha.get("pericias", {}).get(p, 0)) >= int(e["menor_que"])):
			erros.append("%s: escolha perícias com valor menor que %d." % [e["texto"].split(":")[0], int(e["menor_que"])])
	return erros


## Escolhas que as cartas da ficha pedem (chaves de ESCOLHAS).
static func escolhas_pendentes(ficha: Dictionary) -> Array:
	var slugs := []
	for id in ficha["cartas"] + ficha["meias"]:
		for l in Catalogo.habilidade(id).get("lados", []):
			if l != null:
				slugs.append(Catalogo.slug(l["nome"]))
	for id in ficha["herois"]:
		slugs.append(Catalogo.slug(Catalogo.heroi(id).get("nome", "")))
	var lista := []
	for chave in ESCOLHAS:
		if ESCOLHAS[chave].get("carta", chave) in slugs:
			lista.append(chave)
	return lista


## Converte a ficha na configuração de uma unidade de batalha.
static func para_unidade(ficha: Dictionary, id: String, pos: Vector2i) -> Dictionary:
	var at: Dictionary = ficha["atributos"]
	var arma: Dictionary = Itens.ARMAS[ficha["arma"]].duplicate(true)
	arma["id"] = ficha["arma"]
	var armadura: Dictionary = Itens.ARMADURAS[ficha["armadura"]].duplicate(true)
	armadura["id"] = ficha["armadura"]
	var escudo: Dictionary = Itens.ESCUDOS[ficha["escudo"]].duplicate(true)
	escudo["id"] = ficha["escudo"]
	var reserva: Dictionary = Itens.ARMAS.get(ficha.get("arma2", "nenhuma"), {}).duplicate(true)
	if not reserva.is_empty():
		reserva["id"] = ficha["arma2"]
	var at_com_itens: Dictionary = at.duplicate()
	if "amuleto_de_nebtor" in ficha.get("acessorios", []):
		at_com_itens["diplomacia"] = int(at_com_itens.get("diplomacia", 0)) + 1   # Amuleto de Nebtor
	if Itens.foco_trocavel(ficha):
		reserva = Itens.foco_como_arma(Itens.FOCOS[ficha["foco"]])
		if ficha.get("comeca_com_foco", ficha["classe"] in ["Mago", "Clérigo", "Bruxo"]):
			var t := arma
			arma = reserva
			reserva = t
	return {
		"id": id, "nome": ficha["nome"], "lado": "heroi", "tipo": TIPOS_CLASSE.get(ficha["classe"], "guerreiro"), "pos": pos,
		"classe": ficha["classe"], "raca": ficha["raca"], "background": ficha["background"],
		"divindade": ficha.get("divindade", Devocoes.PADRAO) if ficha["classe"] == "Clérigo" else "",
		"pacto": Catalogo.pacto_da_ficha(ficha) if ficha["classe"] == "Bruxo" else "",
		"pacto_menor": str(ficha.get("escolhas", {}).get("pacto-menor", [""])[0]) if not ficha.get("escolhas", {}).get("pacto-menor", []).is_empty() and "classe.bruxo.pacto-menor" in ficha["cartas"] else "",
		"nivel_pacto": int(ficha.get("nivel_pacto", 1)),
		"tamanho": TAMANHOS.get(ficha["raca"], "medio"),
		"escolhas": ficha.get("escolhas", {}).duplicate(true),
		"foco": Itens.FOCOS.get(ficha.get("foco", "nenhum"), Itens.FOCOS["nenhum"]).merged({"id": ficha.get("foco", "nenhum")}),
		"atributos": at_com_itens,
		"espirito": int(at.get("espirito", 0)),
		"forca": int(at["forca"]), "destreza": int(at["destreza"]),
		"iniciativa": int(ficha.get("pericias", {}).get("Iniciativa", 0)),
		"pericias": ficha.get("pericias", {}).duplicate(),
		"sabedoria": int(at["sabedoria"]), "constituicao": int(at["constituicao"]), "raciocinio": int(at["raciocinio"]),
		"percepcao": int(at["percepcao"]),
		"arma": arma.duplicate(true), "armadura": armadura.duplicate(), "escudo": escudo.duplicate(),
		"arma_reserva": reserva,
		"dano": arma["dano"],
		"atributo_dano": int(at.get(Itens.atributo_da_arma(arma), 0)),
		"a_distancia": arma.get("distancia", false),
		"faixas_ideais": arma.get("ideais", []),
		"alcance_corpo": Itens.alcance_corpo(arma),
		"velocidade": 3 - (1 if armadura["classe"] == "pesada" else 0),
		"cartas_cfg": cartas_em_jogo_cfg(ficha),
		"consumiveis": ficha["consumiveis"].duplicate(),
		"equipamentos": equipamentos_de(ficha),
		"vestidos": vestidos_de(ficha),
		"grimorios": ficha.get("grimorios", []).duplicate(),
		"mov_por_turno": 1, "padrao_por_turno": 2, "reacao_por_turno": 1,
	}


## As cartas da ficha prontas para virar CartaEmJogo: a carta de herói primeiro.
static func cartas_em_jogo_cfg(ficha: Dictionary) -> Array:
	var lista := []
	var lados_heroi := []
	for hid in ficha["herois"]:
		var h := Catalogo.heroi(hid)
		if h.is_empty():
			continue
		lados_heroi.append({"nome": h["nome"], "slug": Catalogo.slug(h["nome"]), "limite_fadiga": h["limite_fadiga"],
			"passiva": h["passiva"], "ativada": h["ativada"], "desencadeada": h["desencadeada"], "critico": h["critico"],
			"custo": h["custo_ativada"], "texto": "Ativada: " + str(h["ativada"])})
	if not lados_heroi.is_empty():
		lista.append({"id": "heroi", "tipo": "heroi", "lados": lados_heroi})
	# Bruxo (0.25): a carta de pacto (reserva de Pacto) e a habilidade inicial A/B, de graça.
	var pid := Catalogo.pacto_da_ficha(ficha) if ficha.get("classe", "") == "Bruxo" else ""
	if pid != "":
		var pc: Dictionary = Catalogo.pactos()[pid]
		lista.append({"id": "pacto", "tipo": "pacto", "lados": [{"nome": pc["nome"], "slug": "pacto-" + pid, "limite_fadiga": 0, "custo": {},
			"tags": pc["tags"] + ["Pacto"], "texto": "Nível %d · começo da cena: %d Pactos.\nCumprimento: %s\nCobrança: %s\nReparação: %s" % [
				int(ficha.get("nivel_pacto", 1)), 2 * int(ficha.get("nivel_pacto", 1)), pc["cumprimento"], pc["cobranca"], pc["reparacao"]]}]})
		var ini := Catalogo.habilidade(pc["inicial"])
		if not ini.is_empty():
			lista.append({"id": ini["id"], "tipo": "habilidade", "lados": [_lado(ini["lados"][0]), _lado(ini["lados"][1])]})
	for cid in ficha["cartas"]:
		var c := Catalogo.habilidade(cid)
		if c.is_empty():
			continue
		var lados := []
		for l in c["lados"]:
			if l != null:
				lados.append(_lado(l))
		var cfg := {"id": cid, "tipo": "habilidade", "lados": lados}
		if c.get("tipo") == "criatura":
			cfg["tipo"] = "criatura"
			for campo in ["id_fonte", "raridade", "virada_normal_permitida", "preparo_permitido", "modelo_recuperacao"]:
				cfg[campo] = c[campo]
		lista.append(cfg)
	var i := 0
	while i + 1 < ficha["meias"].size():
		var a := Catalogo.habilidade(ficha["meias"][i])
		var b := Catalogo.habilidade(ficha["meias"][i + 1])
		lista.append({"id": "meias-%d" % i, "tipo": "habilidade", "lados": [_lado(a["lados"][0]), _lado(b["lados"][0])]})
		i += 2
	# Carta de arma (Lucas, 0.21): um lado para a arma e outro para a segunda arma; virar = trocar.
	# Guarda fichas como as outras cartas. As armas comuns ainda não têm ativadas.
	var arma: Dictionary = Itens.ARMAS.get(ficha.get("arma", ""), {})
	if not arma.is_empty():
		var lados_arma := [{"nome": arma["nome"], "slug": "arma", "limite_fadiga": int(arma.get("limite", 0)), "custo": {},
			"texto": Itens.descricao_arma(arma), "tags": ["Arma"]}]
		var a2: Dictionary = Itens.ARMAS.get(ficha.get("arma2", "nenhuma"), {})
		if Itens.foco_trocavel(ficha):
			a2 = Itens.foco_como_arma(Itens.FOCOS[ficha["foco"]])
		if not a2.is_empty():
			lados_arma.append({"nome": a2["nome"], "slug": "arma", "limite_fadiga": int(a2.get("limite", 0)), "custo": {},
				"texto": Itens.descricao_arma(a2) + ("\nSegurando o foco: dá para conjurar ataques mágicos." if a2.get("eh_foco", false) else ""), "tags": ["Arma"]})
			if Itens.foco_trocavel(ficha) and ficha.get("comeca_com_foco", ficha["classe"] in ["Mago", "Clérigo", "Bruxo"]):
				lados_arma.reverse()
		lista.insert(1 if not lados_heroi.is_empty() else 0, {"id": "arma", "tipo": "arma", "lados": lados_arma})
	# 0.25: itens com ativada (acessórios, amuletos, botas, armas especiais) e livros de repertório.
	lista.append_array(preload("res://core/itens_batalha.gd").cartas_dos_itens(ficha))
	# O foco vira carta(s) de item, com o limite de fadiga dele (logo depois da carta de herói).
	var foco: Dictionary = Itens.FOCOS.get(ficha.get("foco", "nenhum"), {})
	var pos_item := 1 if not lados_heroi.is_empty() else 0
	for fc in foco.get("cartas", []):
		lista.insert(pos_item, {"id": "item." + fc["slug"], "tipo": "item", "lados": [{"nome": fc["nome"], "slug": fc["slug"],
			"limite_fadiga": int(foco.get("limite", 0)), "custo": fc.get("custo", {}), "texto": fc["texto"]}]})
		pos_item += 1
	return lista


static func _lado(l: Dictionary) -> Dictionary:
	var cfg := {"nome": l["nome"], "slug": Catalogo.slug(l["nome"]), "texto": Catalogo.texto_lado(l), "limite_fadiga": l["limite_fadiga"],
		"custo": l["custo"], "tags": l["tags"]}
	for campo in ["criatura", "dificuldade_medicina", "dificuldade_medicina_referencia", "pocao_exigida"]:
		if l.has(campo):
			cfg[campo] = l[campo]
	return cfg


static func carregar_todos() -> Array:
	var dados
	if memoria is Array:
		dados = memoria.duplicate(true)
	else:
		if not FileAccess.file_exists(arquivo):
			return []
		dados = JSON.parse_string(FileAccess.get_file_as_string(arquivo))
	if not dados is Array:
		return []
	for f in dados:
		if f is Dictionary and not f.has("pericias"):
			f["pericias"] = {}   # heróis da 0.6: o jogador precisa escolher as perícias
		if f is Dictionary and not f.has("foco"):
			f["foco"] = "nenhum"
		if f is Dictionary and Itens.FOCOS_ANTIGOS.has(f["foco"]):
			f["foco"] = Itens.FOCOS_ANTIGOS[f["foco"]]
		if f is Dictionary and not f.has("escolhas"):
			f["escolhas"] = {}
		if f is Dictionary:
			_migrar_pericias(f)
			migrar_inventario(f)
	return dados


## Inventário por espaços (0.25). Heróis antigos ganham a mochila inicial e o item
## da classe no espaço certo (antes vinham de graça, fora da ficha).
static func migrar_inventario(f: Dictionary) -> void:
	for chave in ["arma", "arma2"]:
		if Itens.IDS_ANTIGOS.has(str(f.get(chave, ""))):
			f[chave] = Itens.IDS_ANTIGOS[f[chave]]
	if f.has("mochila"):
		return
	f["mochila"] = Itens.MOCHILA_INICIAL.duplicate()
	f["acessorios"] = []
	for chave in ["costas", "cabeca", "pes"]:
		f[chave] = "nenhum"
	f["grimorios"] = []
	_item_de_classe(f)


## Põe o item básico da classe no espaço dele (acessório ou mochila; os focos já são escolhidos à parte).
static func _item_de_classe(f: Dictionary) -> void:
	var item: String = Itens.ITEM_DE_CLASSE.get(f.get("classe", ""), "")
	if item == "" or Itens.FOCOS.has(item):
		return
	var dados: Dictionary = Itens.item(item)
	if dados.get("espaco", "") == "acessorios":
		if not item in f["acessorios"] and f["acessorios"].size() < LIMITES["acessorios"]:
			f["acessorios"].append(item)
	elif not item in f["mochila"]:
		if item == "ferramentas_de_ladrao":
			f["mochila"].erase("pe_de_cabra")
		f["mochila"].append(item)


## Troca de classe na criação: tira o item da classe antiga e põe o da nova.
static func trocar_item_de_classe(f: Dictionary, antiga: String) -> void:
	var velho: String = Itens.ITEM_DE_CLASSE.get(antiga, "")
	if velho != "":
		f.get("acessorios", []).erase(velho)
		f.get("mochila", []).erase(velho)
		if velho == "ferramentas_de_ladrao" and not "pe_de_cabra" in f.get("mochila", []):
			f["mochila"].append("pe_de_cabra")
	_item_de_classe(f)


## Limites do inventário por espaços (Lucas, 0.25).
const LIMITES := {"armadura": 1, "costas": 1, "cabeca": 1, "pes": 1, "acessorios": 2, "amuletos": 1,
	"armamentos": 4, "consumiveis": 6, "mochila": 6}
const NOMES_ESPACOS := {"armadura": "Armadura", "costas": "Costas", "cabeca": "Cabeça", "pes": "Pés", "acessorios": "Acessórios",
	"amuletos": "Amuletos ou colares", "armamentos": "Armamentos e repertórios", "consumiveis": "Consumíveis especiais", "mochila": "Mochila"}


## Quanto de cada espaço a ficha usa: {espaço: usado}.
static func ocupacao(f: Dictionary) -> Dictionary:
	var o := {}
	for k in LIMITES:
		o[k] = 0
	for chave in ["arma", "arma2"]:
		var a: Dictionary = Itens.ARMAS.get(f.get(chave, "nenhuma"), {})
		o["armamentos"] += int(a.get("ocupa", 0))
	o["armamentos"] += int(Itens.ESCUDOS.get(f.get("escudo", "nenhum"), {}).get("ocupa", 0))
	o["armamentos"] += int(Itens.FOCOS.get(f.get("foco", "nenhum"), {}).get("ocupa", 0))
	for g in f.get("grimorios", []):
		o["armamentos"] += int(Itens.GRIMORIOS.get(g, {}).get("ocupa", 1))
	var arm: Dictionary = Itens.ARMADURAS.get(f.get("armadura", "nenhuma"), {})
	o["armadura"] += int(arm.get("ocupa", 0))
	if arm.get("tambem_costas", false):
		o["costas"] += 1
	for chave in ["costas", "cabeca", "pes"]:
		if str(f.get(chave, "nenhum")) != "nenhum":
			o[chave] += 1
	for a in f.get("acessorios", []):
		o["acessorios"] += 1
		if Itens.eh_amuleto(a):
			o["amuletos"] += 1
	var contagem := {}
	for c in f.get("consumiveis", []):
		contagem[c] = int(contagem.get(c, 0)) + 1
	for c in contagem:
		var d: Dictionary = Itens.CONSUMIVEIS.get(c, {})
		if not d.get("loja", true):
			continue   # achados (gemas, frutas) vão na bolsa de tesouro
		if d.get("espaco", "consumiveis") == "mochila":
			o["mochila"] += ceili(float(contagem[c]) / maxf(1.0, float(d.get("pacote", 1)))) * int(d.get("ocupa", 1))
		else:
			o["consumiveis"] += int(contagem[c]) * int(d.get("ocupa", 1))
	for m in f.get("mochila", []):
		var d2: Dictionary = Itens.item(m)
		# Peça de vestuário ou acessório guardado ocupa o espaço "de reserva" na mochila.
		o["mochila"] += int(d2.get("reserva_mochila", 0)) if d2.get("espaco", "mochila") != "mochila" else int(d2.get("ocupa", 1))
	return o


static func erros_de_inventario(f: Dictionary) -> Array[String]:
	var erros: Array[String] = []
	var o := ocupacao(f)
	for k in LIMITES:
		if int(o[k]) > int(LIMITES[k]):
			erros.append("Inventário cheio em %s: %d de %d." % [NOMES_ESPACOS[k], o[k], LIMITES[k]])
	return erros


## Texto curto da ocupação ("Armamentos 3/4 · Consumíveis 4/6 · Mochila 6/6").
static func texto_ocupacao(f: Dictionary) -> String:
	var o := ocupacao(f)
	var partes := PackedStringArray()
	for k in ["armamentos", "consumiveis", "mochila", "acessorios", "armadura", "costas", "cabeca", "pes"]:
		partes.append("%s %d/%d" % [NOMES_ESPACOS[k].split(" ")[0], o[k], LIMITES[k]])
	return " · ".join(partes)


## Peças vestidas: capa, elmo, botas e acessórios (só elas dão efeito).
static func vestidos_de(f: Dictionary) -> Array:
	var lista := []
	for chave in ["costas", "cabeca", "pes"]:
		if str(f.get(chave, "nenhum")) != "nenhum":
			lista.append(f[chave])
	lista.append_array(f.get("acessorios", []))
	return lista


## Itens que o herói tem fora das mãos: mochila e peças vestidas (o que Unidade.tem_item procura).
static func equipamentos_de(f: Dictionary) -> Array:
	var lista: Array = f.get("mochila", []).duplicate()
	for chave in ["costas", "cabeca", "pes"]:
		if str(f.get(chave, "nenhum")) != "nenhum":
			lista.append(f[chave])
	lista.append_array(f.get("acessorios", []))
	return lista


## Grimório ou texto sagrado: "" se o herói pode prepará-lo, senão o motivo.
## Requisito "Fogo" = ter a tag Fogo (cartas de Aprendiz, pactos); "Conjurador divino" = Clérigo.
static func motivo_grimorio(f: Dictionary, gid: String) -> String:
	var g: Dictionary = Itens.GRIMORIOS.get(gid, {})
	if g.is_empty():
		return "Repertório desconhecido: %s." % gid
	if g.get("sagrado", false):
		return "" if f.get("classe", "") == "Clérigo" else "%s: só um conjurador divino (Clérigo) usa." % g["nome"]
	var tags := tags_da_ficha(f)
	for t in str(g.get("requisito", "")).split(" ", false):
		if not t in tags:
			return "%s exige a tag %s (cartas de Aprendiz ou um pacto)." % [g["nome"], t]
	return ""


## Tags elementais que as cartas da ficha concedem ("Concede Fogo.").
static func tags_da_ficha(f: Dictionary) -> Array:
	var tags := []
	for id in f.get("cartas", []) + f.get("meias", []):
		for l in Catalogo.habilidade(id).get("lados", []):
			if l == null:
				continue
			for t in l.get("tags", []):
				if t in ["Fogo", "Água", "Terra", "Ar", "Luz", "Sombra"] and not t in tags:
					tags.append(t)
	for t in Catalogo.tags_do_pacto(f):
		if not t in tags:
			tags.append(t)
	return tags


## Perícias cortadas pelo Lucas (0.11). O valor delas passa para a primeira
## perícia ainda sem valor, para a ficha continuar válida.
const PERICIAS_REMOVIDAS := ["Fortitude", "Reflexos", "Contatos"]


static func _migrar_pericias(f: Dictionary) -> void:
	var p: Dictionary = f["pericias"]
	for velha in PERICIAS_REMOVIDAS:
		if not p.has(velha):
			continue
		var v := int(p[velha])
		p.erase(velha)
		if v <= 0:
			continue
		for grupo in PERICIAS:
			var feito := false
			for nova in PERICIAS[grupo]:
				if int(p.get(nova, 0)) == 0:
					p[nova] = v
					feito = true
					break
			if feito:
				break


static func salvar_todos(lista: Array) -> void:
	if memoria is Array:
		memoria = lista.duplicate(true)
		return
	var f := FileAccess.open(arquivo, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(lista, "\t"))
