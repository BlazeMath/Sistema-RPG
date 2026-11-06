## Itens do jogo (0.25): os 170 equipamentos do Lucas, lidos de data/equipamentos.json
## (gerado por tools/gerar_equipamentos.py a partir do estudo de economia e do inventário
## por espaços). ARMAS, ARMADURAS, ESCUDOS, FOCOS, CONSUMIVEIS, NAO_CONSUMIVEIS (vestíveis,
## acessórios e ferramentas) e GRIMORIOS são montados ao carregar o script.
##
## Cada item guarda: "nome", "texto" (a carta), "raridade", "preco" (em cobre), "mercado"
## (V vila, C cidade, E especialista, O encomenda, R relíquia), "espaco" e "ocupa" (inventário
## por espaços), "programado" (o efeito já funciona na batalha) e "nota" (o que falta).
extends RefCounted

const Combate := preload("res://core/combate.gd")
const ARQUIVO := "res://data/equipamentos.json"

## 0.13 (pedido do Lucas: diferença de 5 para 7 entre as classes): armas leves +1 de dano.
## As cartas novas trazem o dano-base (faca 2); o ajuste continua por cima (faca 3).
const AJUSTE_LEVES := 1

## Tipo de dano das armas raras que não trazem a tag (provisório).
const TIPO_DAS_RARAS := {
	"adaga_da_mao_vazia": "Perfuração", "florete_do_contragolpe": "Perfuração", "cajado_do_condutor": "Concussão",
	"lamina_do_vento": "Corte", "gladio_inquietante": "Corte", "lanca_da_muralha": "Perfuração", "quebra_elmos": "Concussão",
	"machado_da_sepultura": "Corte", "montante_do_frenesi": "Corte", "shuriken": "Perfuração", "machado_de_arremesso": "Corte",
	"javelin": "Perfuração", "arco_curto": "Perfuração", "arco_longo": "Perfuração", "besta_pesada": "Perfuração",
	"adaga_balanceada": "Perfuração", "machete_farpado": "Corte", "lanca_espiral": "Perfuração", "arco_recurvo": "Perfuração",
	"arco_de_teixo": "Perfuração", "besta_da_seta_dupla": "Perfuração", "leque_de_laminas": "Corte", "machado_sedento": "Corte",
	"lanca_trovejante": "Raio", "arco_das_sombras": "Perfuração", "arco_da_mare": "Concussão", "balestra_de_cerco": "Perfuração",
}

## Ids antigos (até a 0.24) que mudaram.
const IDS_ANTIGOS := {"arco_de_guerra": "arco_longo"}

## Regras das classes de armadura (o que vale para toda armadura leve, média ou pesada).
const TEXTO_CLASSE_ARMADURA := {
	"nenhuma": "Ao se defender bem, devolve ao baralho a carta usada na defesa.",
	"leve": "Leve: ao se defender bem, devolve ao baralho uma carta aleatória.",
	"media": "Média: exila 1 carta do descarte por turno; −2 em testes de movimento.",
	"pesada": "Pesada: +1 no limite da defesa enquanto tiver vida; exila 1 carta por turno; Velocidade −1; −4 em testes de movimento.",
}

static var CATALOGO := _ler_catalogo()
static var ARMAS := _montar_armas()
static var ARMADURAS := _montar_armaduras()
static var ESCUDOS := _montar_escudos()
static var FOCOS := _montar_focos()
static var CONSUMIVEIS := _montar_consumiveis()
static var NAO_CONSUMIVEIS := _montar_permanentes()
static var GRIMORIOS := _montar_grimorios()


static func _ler_catalogo() -> Dictionary:
	var d = JSON.parse_string(FileAccess.get_file_as_string(ARQUIVO))
	var r := {}
	if d is Dictionary:
		for it in d.get("itens", []):
			r[it["id"]] = it
	return r


## Dados de inventário e loja comuns a todo item do catálogo.
static func _base(it: Dictionary) -> Dictionary:
	return {"nome": it["nome"], "texto": it["habilidade"], "raridade": it["raridade"], "preco": int(it["preco_cobre"]),
		"mercado": it["mercado"], "revenda": float(it["revenda"]), "espaco": it["espaco"], "ocupa": int(it["ocupa"]),
		"eq": it["eq"], "categoria": it["categoria"], "tags": it["tags"], "campos": it["campos"],
		"amuleto": it.get("amuleto", false), "tambem_costas": it.get("tambem_costas", false),
		"reserva_mochila": int(it.get("reserva_mochila", 0)), "pacote": int(it.get("pacote", 1))}


static func _numero(s: String) -> int:
	var re := RegEx.create_from_string("\\d+")
	var m := re.search(s)
	return int(m.get_string()) if m != null else 0


static func _montar_armas() -> Dictionary:
	# 0.25: "sem arma" para conjuradores que levam só foco e livros (inventário por espaços).
	var r := {"desarmado": {"nome": "Sem arma (desarmado)", "peso": "nenhum", "tamanho": "desarmado", "dano": 0, "tipo_dano": "Concussão",
		"forca_min": 0, "atributo": "forca", "preco": 0, "ocupa": 0, "espaco": "armamentos", "raridade": "COMUM", "loja": false, "mercado": "V",
		"texto": "Desarmado: só a diferença, mais a Força se ela for 3 ou mais.", "limite": 0}}
	for id in CATALOGO:
		var it: Dictionary = CATALOGO[id]
		var cat: String = it["categoria"]
		if not cat.begins_with("ARMA"):
			continue
		var a := _base(it)
		var tags: Array = it["tags"]
		var campos: Dictionary = it["campos"]
		var dano_txt: String = str(campos.get("Dano", "0"))
		a["dano"] = _numero(dano_txt)
		if dano_txt.contains("For"):
			a["atributo"] = "forca"
		elif dano_txt.contains("Des"):
			a["atributo"] = "destreza"
		else:
			a["atributo"] = "nenhum"
		a["tipo_dano"] = TIPO_DAS_RARAS.get(id, "Corte")
		for t in ["Corte", "Perfuração", "Concussão"]:
			if t in tags:
				a["tipo_dano"] = t
		var req: String = str(campos.get("Requisito", ""))
		a["forca_min"] = _numero(req) if req.contains("Força") else 0
		if req.contains("Destreza"):
			a["destreza_min"] = _numero(req)
		a["limite"] = _numero(str(campos.get("Limite de Fadiga", "0")))
		if cat == "ARMA CORPO A CORPO":
			a["peso"] = "leve" if "Peso Leve" in tags else ("pesada" if "Peso Pesado" in tags else "media")
			a["tamanho"] = "grande" if "Tamanho Grande" in tags else ("pequeno" if "Tamanho Pequeno" in tags else "medio")
			if str(campos.get("Alcance", "")).contains("(2)"):
				a["tamanho"] = "grande"
		else:
			a["distancia"] = true
			a["peso"] = "leve" if a["dano"] <= 3 else ("media" if a["dano"] <= 4 else "pesada")
			a["arremesso"] = "Arremessável" in tags
			a["tamanho"] = "arremesso" if a["arremesso"] else "tiro"
			if "Recuperável" in tags:
				a["fica_no_alvo"] = true
			if not a["arremesso"]:
				a["duas_maos"] = true
			a["ideais"] = _faixas(str(campos.get("Alcance", "")))
			if "Ignora Resistência" in tags:
				a["ignora_resistencia"] = true
			if "Recarga" in tags:
				a["recarregar"] = true
		if a["peso"] == "leve" and a["dano"] > 0:
			a["dano"] += AJUSTE_LEVES
		r[id] = a
	return r


static func _faixas(t: String) -> Array:
	var s := t.to_lower()
	var f := []
	if s.contains("curt"):
		f.append(Combate.Faixa.CURTO)
	if s.contains("méd") or s.contains("med"):
		f.append(Combate.Faixa.MEDIO)
	if s.contains("long"):
		f.append(Combate.Faixa.LONGO)
	return f if not f.is_empty() else [Combate.Faixa.CURTO, Combate.Faixa.MEDIO]


static func _montar_armaduras() -> Dictionary:
	var r := {"nenhuma": {"nome": "Sem armadura", "classe": "nenhuma", "vida": 0, "resistencia": 0, "preco": 0,
		"texto": TEXTO_CLASSE_ARMADURA["nenhuma"], "espaco": "armadura", "ocupa": 0, "raridade": "COMUM", "mercado": "V"}}
	for id in CATALOGO:
		var it: Dictionary = CATALOGO[id]
		if it["categoria"] != "ARMADURA":
			continue
		var a := _base(it)
		var tags: Array = it["tags"]
		a["classe"] = "leve" if "Leve" in tags else ("pesada" if "Pesada" in tags else "media")
		a["vida"] = int(it["campos"].get("Vida", "0"))
		a["resistencia"] = int(it["campos"].get("Resistência", "0"))
		a["texto"] = "%s\n%s" % [TEXTO_CLASSE_ARMADURA[a["classe"]], it["habilidade"]]
		r[id] = a
	return r


static func _montar_escudos() -> Dictionary:
	var r := {"nenhum": {"nome": "Sem escudo", "vida": 0, "resistencia": 0, "preco": 0, "texto": "", "espaco": "armamentos", "ocupa": 0,
		"raridade": "COMUM", "mercado": "V"}}
	for id in CATALOGO:
		var it: Dictionary = CATALOGO[id]
		if it["categoria"] != "ESCUDO":
			continue
		var e := _base(it)
		e["vida"] = int(it["campos"].get("Vida", "0"))
		e["resistencia"] = int(it["campos"].get("Resistência", "0"))
		e["peso"] = "pesado" if "Pesado" in it["tags"] else "leve"
		r[id] = e
	return r


static func _montar_focos() -> Dictionary:
	var r := {}
	for id in FOCOS_BASE:
		var f: Dictionary = FOCOS_BASE[id].duplicate(true)
		if CATALOGO.has(id):
			f.merge(_base(CATALOGO[id]), false)
			f["texto"] = FOCOS_BASE[id]["texto"]
		else:
			f.merge({"preco": 0, "espaco": "armamentos", "ocupa": 0, "raridade": "COMUM", "mercado": "V"}, false)
		r[id] = f
	return r


static func _montar_consumiveis() -> Dictionary:
	var r := {}
	for id in CATALOGO:
		var it: Dictionary = CATALOGO[id]
		if not it["categoria"] in ["CONSUMÍVEL", "RUNA CONSUMÍVEL"]:
			continue
		var c := _base(it)
		c.merge(CONSUMIVEIS_BASE.get(id, {}), true)
		c["texto"] = it["habilidade"]
		if not c.has("programado"):
			c["programado"] = false
		r[id] = c
	# Itens do jogo que não estão no catálogo (kit médico do Lucas; achados de missão).
	for id in CONSUMIVEIS_BASE:
		if not r.has(id):
			var c2: Dictionary = CONSUMIVEIS_BASE[id].duplicate(true)
			c2.merge({"espaco": "consumiveis", "ocupa": 1, "raridade": "COMUM", "mercado": "E", "revenda": 0.35, "pacote": 1}, false)
			r[id] = c2
	return r


static func _montar_permanentes() -> Dictionary:
	var r := {}
	for id in CATALOGO:
		var it: Dictionary = CATALOGO[id]
		if not it["categoria"] in ["PERMANENTE", "AMULETO"] or FOCOS_BASE.has(id):
			continue
		var p := _base(it)
		p.merge(PERMANENTES_BASE.get(id, {}), true)
		if not p.has("programado"):
			p["programado"] = false
		r[id] = p
	return r


static func _montar_grimorios() -> Dictionary:
	var r := {}
	for id in CATALOGO:
		var it: Dictionary = CATALOGO[id]
		if not it["categoria"] in ["GRIMÓRIO BÁSICO", "GRIMÓRIO RARO", "TEXTO SAGRADO"]:
			continue
		var g := _base(it)
		g["requisito"] = str(it["campos"].get("Requisito", ""))
		g["sagrado"] = it["categoria"] == "TEXTO SAGRADO"
		g["magias"] = _magias_do_texto(it["habilidade"])
		r[id] = g
	return r


## "Nome: 3 de Fadiga, Ação Padrão: efeito" (uma por linha) -> lista de magias.
static func _magias_do_texto(texto: String) -> Array:
	var lista := []
	for linha in texto.split("\n"):
		linha = linha.strip_edges()
		if linha == "":
			continue
		var re := RegEx.create_from_string("^(.+?)\\s*(?::|—)\\s*(\\d+) de Fadiga(?: e (\\d+) de vida)?,\\s*([^:]+?):\\s*(.+)$")
		var m := re.search(linha)
		if m == null:
			continue
		var acao_txt := m.get_string(4).to_lower()
		var acao := "padrao"
		if acao_txt.contains("movimento"):
			acao = "movimento"
		elif acao_txt.contains("reação"):
			acao = "reacao"
		lista.append({"nome": m.get_string(1).strip_edges(), "fadiga": int(m.get_string(2)), "vida": int(m.get_string(3)) if m.get_string(3) != "" else 0,
			"acao": acao, "texto": m.get_string(5).strip_edges()})
	return lista


## Item de qualquer tipo pelo id (para nome, preço e espaço).
static func item(id: String) -> Dictionary:
	id = IDS_ANTIGOS.get(id, id)
	for tabela in [ARMAS, ARMADURAS, ESCUDOS, FOCOS, CONSUMIVEIS, NAO_CONSUMIVEIS, GRIMORIOS]:
		if tabela.has(id):
			return tabela[id]
	return {}


static func nome(id: String) -> String:
	return str(item(id).get("nome", id))


static func preco(id: String) -> int:
	return int(item(id).get("preco", 100))


static func eh_amuleto(id: String) -> bool:
	return item(id).get("amuleto", false)


# --- Focos -----------------------------------------------------------------

## Focos (PDF de equipamentos): "a arma" do ataque mágico. Ocupam uma mão (os
## cajados, as duas). Dano do ataque mágico = diferença + atributo de conjuração
## + dano do foco + dano extra da magia. Os números de "dano" são do Claude, provisórios.
## "tipo": "arcano" (Mago, Bruxo) ou "sagrado" (Clérigo). "cartas": as ativadas, que viram
## cartas de item na batalha (com limite de fadiga próprio).
## Lucas (0.24): o foco com mãos ocupa o lugar de uma arma. Quem tem arma e foco (sem
## segunda arma) troca entre os dois como troca de arma.
static func foco_como_arma(f: Dictionary) -> Dictionary:
	return {"nome": "%s (foco)" % f.get("nome", "Foco"), "peso": "leve", "tamanho": "pequeno", "dano": int(f.get("dano", 1)),
		"tipo_dano": "Concussão", "forca_min": 0, "atributo": "forca", "eh_foco": true}


## O herói tem foco trocável (com mãos) e nenhuma segunda arma?
static func foco_trocavel(ficha: Dictionary) -> bool:
	return int(FOCOS.get(ficha.get("foco", "nenhum"), {}).get("maos", 0)) > 0 and ficha.get("arma2", "nenhuma") == "nenhuma"


const FOCOS_BASE := {
	"nenhum": {"nome": "Sem foco", "dano": 0, "maos": 0, "tipo": "", "texto": "Sem foco não há ataque mágico."},
	# Itens básicos de classe que também são focos
	"varinha_eletrizante": {"nome": "Varinha Eletrizante", "dano": 3, "maos": 1, "tipo": "arcano", "limite": 3,
		"texto": "Item do Mago. 3 de fadiga, Ação: cause 3 de dano a um inimigo a alcance médio, ignorando resistência.",
		"cartas": [{"slug": "varinha-eletrizante", "nome": "Varinha Eletrizante", "custo": {"fadiga": 3, "acao": "padrao"},
			"texto": "3 de fadiga, Ação: cause 3 de dano a um inimigo a alcance médio, ignorando resistência."}]},
	"simbolo_sagrado": {"nome": "Símbolo Sagrado", "dano": 2, "maos": 1, "tipo": "sagrado", "limite": 4,
		"texto": "Item do Clérigo (dano 1 no PDF). No início do seu turno, retire 1 de fadiga de Símbolo Sagrado.",
		"cartas": [{"slug": "simbolo-sagrado", "nome": "Símbolo Sagrado", "passiva": true,
			"texto": "No início do seu turno, retire 1 de fadiga de Símbolo Sagrado. Só serve para ataques mágicos."}]},
	# Focos arcanos
	"varinha_de_cristal": {"nome": "Varinha de Cristal", "dano": 3, "maos": 1, "tipo": "arcano", "limite": 2,
		"texto": "2 de fadiga: até o final do turno, seus ataques mágicos causam seu Raciocínio ou sua Sabedoria a mais de dano.",
		"cartas": [{"slug": "varinha-de-cristal", "nome": "Varinha de Cristal", "custo": {"fadiga": 2},
			"texto": "2 de fadiga: até o final do turno, seus ataques mágicos causam seu Raciocínio ou sua Sabedoria a mais de dano."}]},
	"cajado_do_aprendiz": {"nome": "Cajado do Aprendiz", "dano": 4, "maos": 2, "tipo": "arcano", "limite": 5,
		"texto": "2 de fadiga: vire a sua carta de Aprendiz.",
		"cartas": [{"slug": "cajado-do-aprendiz", "nome": "Cajado do Aprendiz", "custo": {"fadiga": 2}, "texto": "2 de fadiga: vire a sua carta de Aprendiz."}]},
	"cajado_de_batalha": {"nome": "Cajado de Batalha", "dano": 4, "maos": 2, "tipo": "arcano", "limite": 3, "limite_magia": 1,
		"texto": "Auxílio: seus ataques mágicos têm +1 no limite do 21. 2 de fadiga: Onda de força — empurre todos os inimigos adjacentes 2 quadrados.",
		"cartas": [{"slug": "cajado-de-batalha", "nome": "Cajado de Batalha", "custo": {"fadiga": 2},
			"texto": "Auxílio: seus ataques mágicos têm +1 no limite do 21.\n2 de fadiga: Onda de força — empurre todos os inimigos adjacentes 2 quadrados."}]},
	"orbe_de_concentracao": {"nome": "Orbe de Concentração", "dano": 2, "maos": 1, "tipo": "arcano", "limite": 2,
		"texto": "1 de fadiga: ao realizar a ação Concentrar, compre uma carta adicional.",
		"cartas": [{"slug": "orbe-de-concentracao", "nome": "Orbe de Concentração", "custo": {"fadiga": 1},
			"texto": "1 de fadiga: na próxima ação Concentrar deste turno, compre uma carta adicional."}]},
	"orbe_de_protecao": {"nome": "Orbe de Proteção", "dano": 2, "maos": 1, "tipo": "arcano", "limite": 2, "limite_defesa": 1,
		"texto": "Auxílio: o limite do 21 na sua defesa aumenta em 1. 2 de fadiga: você ou um aliado adjacente ganha resistência 2 até o seu próximo turno.",
		"cartas": [{"slug": "orbe-de-protecao", "nome": "Orbe de Proteção", "custo": {"fadiga": 2},
			"texto": "Auxílio: +1 no limite do 21 na sua defesa.\n2 de fadiga: você ou um aliado adjacente ganha resistência 2 até o seu próximo turno."}]},
	# Focos sagrados
	"calice_da_vida": {"nome": "Cálice da Vida", "dano": 2, "maos": 1, "tipo": "sagrado", "limite": 2,
		"texto": "Auxílio: suas magias curam 1 a mais.", "cartas": []},
	"relicario_do_guardiao": {"nome": "Relicário do Guardião", "dano": 2, "maos": 1, "tipo": "sagrado", "limite": 4,
		"texto": "3 de fadiga, Ação: o aliado alvo ganha 1 ficha de Guarda.",
		"cartas": [{"slug": "relicario-do-guardiao", "nome": "Relicário do Guardião", "custo": {"fadiga": 3, "acao": "padrao"},
			"texto": "3 de fadiga, Ação: o aliado alvo (à vista, alcance curto) ganha 1 ficha de Guarda."}]},
	"marca_da_punicao": {"nome": "Marca da Punição", "dano": 1, "maos": 1, "tipo": "sagrado", "limite": 4,
		"texto": "Auxílio: suas magias causam 2 de dano a mais e aplicam Ferimento.", "cartas": []},
	"turibulo_das_bencaos": {"nome": "Turíbulo das Bênçãos", "dano": 2, "maos": 1, "tipo": "sagrado", "limite": 3,
		"texto": "Auxílio: você e aliados adjacentes a você recuperam 1 de fadiga adicional ao final do turno.", "cartas": []},
	"escrituras_de_maftone": {"nome": "Escrituras de Maftoné", "dano": 2, "maos": 1, "tipo": "sagrado", "limite": 2,
		"texto": "1 de fadiga: você ou um aliado adjacente faz scry 1. 1 de fadiga: some o seu Espírito ao dano de uma magia que você conjurou.",
		"cartas": [{"slug": "escrituras-scry", "nome": "Escrituras de Maftoné: scry", "custo": {"fadiga": 1},
				"texto": "1 de fadiga: você ou um aliado adjacente faz scry 1 (olha o topo e pode mandar para o fundo)."},
			{"slug": "escrituras-espirito", "nome": "Escrituras de Maftoné: Espírito", "custo": {"fadiga": 1},
				"texto": "1 de fadiga: some o seu Espírito ao dano da próxima magia que você conjurar."}]},
	"rosario_da_devocao": {"nome": "Rosário da Devoção", "dano": 2, "maos": 1, "tipo": "sagrado", "limite": 3, "resistencia": 1,
		"texto": "Auxílio: você tem 1 de resistência. 3 de fadiga, Ação: substitua um marcador de Ferimento por um marcador de Foco.",
		"cartas": [{"slug": "rosario-da-devocao", "nome": "Rosário da Devoção", "custo": {"fadiga": 3, "acao": "padrao"},
			"texto": "Auxílio: você tem 1 de resistência.\n3 de fadiga, Ação: substitua uma ficha de Ferimento por uma de Foco."}]},
}

## Focos das versões 0.9/0.10 (inventados) trocados pelos do PDF.
const FOCOS_ANTIGOS := {"varinha": "varinha_de_cristal", "orbe": "orbe_de_protecao", "cajado": "cajado_de_batalha"}
const FOCO_DA_CLASSE := {"Mago": "varinha_eletrizante", "Clérigo": "simbolo_sagrado", "Bruxo": "varinha_eletrizante"}
const TIPO_DE_FOCO := {"Mago": "arcano", "Clérigo": "sagrado", "Bruxo": "arcano"}


# --- Consumíveis -------------------------------------------------------------

## Dados de jogo dos consumíveis (somados ao catálogo). "programado": o efeito funciona.
## "acao": usa-se pelo menu Itens (ação Padrão); "alvo": "aliado" = você ou aliado adjacente;
## "area": cria uma área; "uso": onde o jogo usa o item sozinho.
const CONSUMIVEIS_BASE := {
	"tocha": {"programado": true, "uso": "luz", "nota": "como arma improvisada ainda não"},
	"pocao_de_cura_pequena": {"programado": true, "acao": true, "alvo": "aliado"},
	"pocao_de_mana_pequena": {"programado": true, "acao": true},
	"antidoto": {"programado": true, "acao": true, "alvo": "aliado"},
	"racao_de_viagem": {"programado": true, "uso": "Gasta sozinha no descanso curto: +1 carta na mão inicial da próxima cena."},
	"bomba_de_fumaca": {"programado": true, "acao": true, "area": {"forma": "quadrado", "tamanho": 3, "alcance": 4}},
	"pedra_de_amolar": {"programado": true, "uso": "Gasta sozinha no descanso curto do mapa (o jogo ainda não tem descanso longo na missão): +1 de dano até o fim da missão com arma de Corte ou Perfuração."},
	"veneno_acido": {"programado": true, "acao": true},
	"oleo_antiespectral": {"programado": true, "acao": true},
	"gazua": {"programado": true, "uso": "Aparece como opção nas fechaduras."},
	"pocao_de_pele_de_pedra": {"programado": true, "acao": true},
	"pocao_carmim": {"programado": true, "acao": true},
	"incenso_de_jasmim": {"programado": true, "acao": true},
	"frasco_de_piche": {"programado": true, "acao": true, "area": {"forma": "quadrado", "tamanho": 3, "alcance": 4}},
	"pocao_turquesa": {"programado": true, "acao": true},
	"sangue_de_batalha": {"programado": true, "acao": true},
	"flocos_de_sombras": {"programado": true, "acao": true, "nota": "usada no seu turno (como reação antes de ser atacado, ainda não)"},
	"agua_abencoada": {"programado": true, "acao": true},
	"flecha_explosiva": {"programado": true, "acao": true, "nota": "a explosão por dano de Fogo ainda não"},
	"pergaminho_do_desencantamento": {"programado": true, "acao": true, "nota": "desfaz uma zona de magia à sua escolha (a mais próxima)"},
	"runa_de_fogo": {"programado": true, "acao": true, "opcoes": ["fogo_adjacente"], "nota": "só a ficha de Fogo no alvo adjacente"},
	"runa_de_agua": {"programado": true, "acao": true, "alvo": "aliado", "nota": "só tirar o Fogo"},
	"runa_de_terra": {"programado": true, "acao": true, "nota": "só Imobilizar um inimigo adjacente"},
	"runa_de_ar": {"programado": true, "acao": true, "nota": "só empurrar um inimigo adjacente"},
	"runa_de_luz": {"programado": true, "acao": true, "nota": "Cegueira num inimigo ao alcance curto"},
	"runa_de_sombra": {"programado": true, "acao": true, "nota": "ganha 1 Sombra"},
	"pocao_de_regeneracao": {"programado": true, "acao": true},
	"pocao_de_folego_prolongado": {"programado": true, "acao": true},
	"pocao_de_visao_noturna": {"programado": true, "acao": true},
	"pocao_de_vigor_lunar": {"programado": true, "acao": true, "nota": "a vida da carta soma à vida da armadura"},
	"pocao_de_sangue_caustico": {"programado": true, "acao": true},
	"pocao_de_reflexos_predatorios": {"programado": true, "acao": true},
	"pocao_de_sangue_limpo": {"programado": true, "acao": true},
	"pocao_de_mergulho": {"programado": true, "acao": true, "nota": "na batalha: nadar com vantagem"},
	"pocao_de_foco_crescente": {"programado": true, "acao": true},
	"pocao_de_amplificacao": {"programado": true, "acao": true},
	"pocao_de_purificacao": {"programado": true, "acao": true},
	"pocao_de_superacao": {"programado": false, "nota": "requisitos de equipamento só contam na criação"},
	"pocao_de_feromonios": {"programado": false, "nota": "fora de combate (com o mestre)"},
	"pocao_de_reaprendizado": {"programado": false, "nota": "troca de carta: use a tela de heróis"},
	# Fora do catálogo de 170
	"kit_medico": {"nome": "Kit Médico", "texto": "Ação: remova todas as fichas de Sangramento de você ou de um aliado adjacente e cure 2 de vida.",
		"programado": true, "acao": true, "alvo": "aliado", "preco": 100},
	"frutas_silvestres": {"nome": "Frutas Silvestres", "texto": "Ação: coma; cure 2 e recupere 1 de fadiga. (Achadas no cenário; não se vendem.)",
		"programado": true, "acao": true, "loja": false, "preco": 0, "venda": 0},
	"gema_do_pantano": {"nome": "Gema do Pântano", "texto": "Tirada de um ovo da bruxa. Não serve para nada em combate; o mercador paga bem por ela.",
		"loja": false, "venda": 300, "preco": 0, "espaco": "mochila"},
	"cristal_de_ligacao": {"nome": "Lasca de Cristal", "texto": "Lasca de um cristal de ligação. O mercador paga bem.",
		"loja": false, "venda": 250, "preco": 0, "espaco": "mochila"},
}

## Dados de jogo dos permanentes (ferramentas, vestíveis, acessórios, amuletos).
const PERMANENTES_BASE := {
	"corda": {"programado": true, "uso": "Vantagem ao escalar; conserta a ponte quebrada."},
	"pe_de_cabra": {"programado": true, "uso": "Vantagem ao forçar o baú."},
	"pederneira": {"programado": false, "nota": "fora de combate"},
	"kit_de_reparos": {"programado": true, "uso": "Sozinho no descanso curto."},
	"kit_de_acampamento": {"programado": false, "nota": "descanso longo ao relento ainda não existe"},
	"lanterna": {"programado": true, "uso": "Na batalha: acender ou apagar (ação de movimento). Vantagem ao procurar na toca escura."},
	"vara_de_3_metros": {"programado": true, "uso": "Vantagem ao examinar armadilhas."},
	"espelho_de_bolso": {"programado": false, "nota": "fora de combate"},
	"bandoleira_de_armas": {"programado": true, "uso": "Até 2 trocas de arma por cena sem custo."},
	"ferramentas_de_ladrao": {"programado": true, "uso": "Vantagem ao destrancar fechaduras."},
	"corda_de_arco_da_penumbra": {"programado": true},
	"paraquedas_elfico": {"programado": true},
	"bussola_do_rumo": {"programado": false, "nota": "fora de combate"},
	"equipamento_de_pesca": {"programado": false, "nota": "fora de combate"},
	"gancho_de_escalada": {"programado": false, "nota": "a critério do mestre"},
	"grilhao_de_ferro": {"programado": false, "nota": "prender a objeto ainda não existe"},
	"manopla_de_bronze": {"programado": true},
	"botas_de_lince": {"programado": true},
	"pergaminho_ancestral": {"programado": true},
	"manto_camuflado": {"programado": true},
	"anel_do_iniciado": {"programado": true, "carta": {"slug": "anel-do-iniciado", "custo": {"fadiga": 0, "acao": null}}},
	"elmo_de_touro": {"programado": true},
	"bainha_impetuosa": {"programado": true},
	"cachecol_da_parceria": {"programado": false, "nota": "ainda não"},
	"cinto_estelar": {"programado": true},
	"botas_seccundas": {"programado": false, "nota": "salto no ar ainda não"},
	"carta_da_sorte": {"programado": false, "nota": "ainda não"},
	"ampulheta_trincada": {"programado": false, "nota": "ainda não"},
	"mascara_do_impostor": {"programado": false, "nota": "fora de combate"},
	"selo_de_sangue": {"programado": true},
	"colar_vinculador": {"programado": false, "nota": "ainda não"},
	"grevas_do_vazio": {"programado": true, "carta": {"slug": "grevas-do-vazio", "custo": {"fadiga": 2, "acao": null}}},
	"espelho_arcano": {"programado": false, "nota": "inimigos ainda não conjuram magias arcanas contra um alvo"},
	"amuleto_de_pacenas": {"programado": true, "carta": {"slug": "amuleto-de-pacenas", "custo": {"fadiga": 0, "acao": "padrao"}}},
	"amuleto_de_grevha": {"programado": true, "carta": {"slug": "amuleto-de-grevha", "custo": {"fadiga": 2, "acao": "padrao"}}},
	"amuleto_de_nebtor": {"programado": true, "nota": "+1 em Diplomacia; a mensagem é fora de combate"},
	"amuleto_de_vael": {"programado": true, "carta": {"slug": "amuleto-de-vael", "custo": {"fadiga": 2, "acao": "padrao"}}},
	"amuleto_de_kanil": {"programado": true, "carta": {"slug": "amuleto-de-kanil", "custo": {"fadiga": 2, "acao": "padrao"}}},
	"amuleto_de_kagen": {"programado": true, "carta": {"slug": "amuleto-de-kagen", "custo": {"fadiga": 2, "acao": "padrao"}}},
}

## Ferramentas que todo herói novo leva na mochila (5 espaços; sobra 1 para um pacote de tochas).
## O Ladino troca o pé de cabra pelas ferramentas de ladrão.
const MOCHILA_INICIAL := ["corda", "lanterna", "kit_de_reparos", "pe_de_cabra"]
## Item básico de cada classe (já vem marcado na criação; ocupa o espaço normal).
const ITEM_DE_CLASSE := {"Guerreiro": "bandoleira_de_armas", "Ladino": "ferramentas_de_ladrao", "Clérigo": "simbolo_sagrado",
	"Caçador": "corda_de_arco_da_penumbra", "Mago": "varinha_eletrizante"}


# --- Armas -------------------------------------------------------------------

## Texto da carta de arma (0.21): números e propriedades.
static func descricao_arma(a: Dictionary) -> String:
	if a.is_empty():
		return ""
	var partes := PackedStringArray()
	var at := atributo_da_arma(a)
	partes.append("Dano %d%s" % [int(a.get("dano", 0)), "" if at == "nenhum" else " + " + ("Destreza" if at == "destreza" else "Força")])
	partes.append(str(a.get("tipo_dano", "")))
	partes.append({"leve": "leve", "media": "média", "pesada": "pesada"}.get(a.get("peso", ""), str(a.get("peso", ""))))
	if a.get("distancia", false):
		partes.append("à distância" + (" (arremesso)" if a.get("arremesso", false) else ""))
	else:
		partes.append("corpo a corpo" + (" (alcance 2)" if a.get("tamanho", "") == "grande" else ""))
	if a.get("duas_maos", false) or a.get("tamanho", "") == "grande":
		partes.append("duas mãos")
	if int(a.get("forca_min", 0)) > 0:
		partes.append("Força %d" % int(a["forca_min"]))
	if int(a.get("destreza_min", 0)) > 0:
		partes.append("Destreza %d" % int(a["destreza_min"]))
	var t := " · ".join(partes)
	if str(a.get("texto", "")) != "":
		t += "\n" + str(a["texto"])
	return t


static func atributo_da_arma(arma: Dictionary) -> String:
	## Armas leves e armas de tiro somam Destreza; as demais, Força.
	## Arremessáveis médias e grandes somam Força; a besta pesada não soma atributo.
	if arma.has("atributo"):
		return arma["atributo"]
	if arma.get("distancia", false) or arma.get("peso", "") == "leve":
		return "destreza"
	return "forca"


static func alcance_corpo(arma: Dictionary) -> int:
	return 2 if arma.get("tamanho", "") == "grande" else 1
