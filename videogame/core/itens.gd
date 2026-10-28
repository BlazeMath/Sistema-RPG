## Itens COMUNS da planilha oficial (aba Armas e aba Itens), para a criação de
## personagem. "programado" diz se o efeito já funciona na batalha.
##
## Armas de alcance: a planilha lista as comuns por tamanho/peso; aqui entram
## os dois arcos (o livro, cap. 15, dá o alcance ideal de cada um). Arremessáveis
## e besta pesada ficam para quando houver munição e recarga.
extends RefCounted

const Combate := preload("res://core/combate.gd")

## 0.13 (pedido do Lucas: diferença de 5 para 7 entre as classes): armas leves +1 de dano
## (faca, florete, bastão, shuriken 3; arco curto 4) e focos +1. Provisório, medido na simulação.
const ARMAS := {
	"faca": {"nome": "Faca", "peso": "leve", "tamanho": "pequeno", "dano": 3, "tipo_dano": "Perfuração", "forca_min": 0},
	"florete": {"nome": "Florete", "peso": "leve", "tamanho": "medio", "dano": 3, "tipo_dano": "Perfuração", "forca_min": 0},
	"bastao": {"nome": "Bastão", "peso": "leve", "tamanho": "grande", "dano": 3, "tipo_dano": "Impacto", "forca_min": 0},
	"espada_curta": {"nome": "Espada Curta", "peso": "media", "tamanho": "pequeno", "dano": 4, "tipo_dano": "Corte", "forca_min": 1},
	"espada_longa": {"nome": "Espada Longa", "peso": "media", "tamanho": "medio", "dano": 4, "tipo_dano": "Corte", "forca_min": 1},
	"lanca": {"nome": "Lança", "peso": "media", "tamanho": "grande", "dano": 4, "tipo_dano": "Perfuração", "forca_min": 1},
	"maca": {"nome": "Maça", "peso": "pesada", "tamanho": "pequeno", "dano": 6, "tipo_dano": "Impacto", "forca_min": 2},
	"machado_de_guerra": {"nome": "Machado de Guerra", "peso": "pesada", "tamanho": "medio", "dano": 6, "tipo_dano": "Corte", "forca_min": 2},
	"montante": {"nome": "Montante", "peso": "pesada", "tamanho": "grande", "dano": 6, "tipo_dano": "Corte", "forca_min": 2},
	"arco_curto": {"nome": "Arco Curto", "peso": "leve", "tamanho": "tiro", "dano": 4, "tipo_dano": "Perfuração", "forca_min": 0,
		"distancia": true, "ideais": [Combate.Faixa.CURTO, Combate.Faixa.MEDIO], "duas_maos": true},
	"arco_de_guerra": {"nome": "Arco de Guerra", "peso": "media", "tamanho": "tiro", "dano": 4, "tipo_dano": "Perfuração", "forca_min": 0,
		"distancia": true, "ideais": [Combate.Faixa.MEDIO, Combate.Faixa.LONGO], "duas_maos": true},
	# Arremessáveis (PDF de equipamentos): leves voltam sozinhas; médias e grandes ficam no quadrado do alvo.
	"shuriken": {"nome": "Shuriken", "peso": "leve", "tamanho": "arremesso", "dano": 3, "tipo_dano": "Perfuração", "forca_min": 0,
		"distancia": true, "ideais": [Combate.Faixa.CURTO], "arremesso": true},
	"machado_de_arremesso": {"nome": "Machado de Arremesso", "peso": "media", "tamanho": "arremesso", "dano": 4, "tipo_dano": "Corte", "forca_min": 1,
		"distancia": true, "ideais": [Combate.Faixa.MEDIO], "arremesso": true, "fica_no_alvo": true, "atributo": "forca"},
	"javelin": {"nome": "Javelin", "peso": "pesada", "tamanho": "arremesso", "dano": 6, "tipo_dano": "Perfuração", "forca_min": 2,
		"distancia": true, "ideais": [Combate.Faixa.LONGO], "arremesso": true, "fica_no_alvo": true, "atributo": "forca"},
	"besta_pesada": {"nome": "Besta Pesada", "peso": "pesada", "tamanho": "tiro", "dano": 6, "tipo_dano": "Perfuração", "forca_min": 0,
		"distancia": true, "ideais": [Combate.Faixa.MEDIO, Combate.Faixa.LONGO], "duas_maos": true, "atributo": "nenhum",
		"ignora_resistencia": true, "recarregar": true},
}

const ARMADURAS := {
	"nenhuma": {"nome": "Sem armadura", "classe": "nenhuma", "vida": 0, "resistencia": 0,
		"texto": "Ao se defender bem, devolve ao baralho a carta usada na defesa."},
	"couro_do_batedor": {"nome": "Couro do Batedor", "classe": "leve", "vida": 4, "resistencia": 2,
		"texto": "Leve: 4 de vida, resistência 2. Ao se defender bem, devolve ao baralho uma carta aleatória. Toque: bolso oculto."},
	"cota_de_malha": {"nome": "Cota de Malha", "classe": "media", "vida": 9, "resistencia": 3,
		"texto": "Média: 9 de vida, resistência 3; exila 1 carta por turno. Toque: uma vez por cena, quando a vida chegaria a 0, fica com 1."},
	"arnes_de_placas": {"nome": "Arnês de Placas", "classe": "pesada", "vida": 16, "resistencia": 3,
		"texto": "Pesada: 16 de vida, resistência 3 (até 22 na defesa); exila 1 carta por turno, Velocidade −1. Toque: vantagem em Intimidação."},
}

## A planilha não tem escudos comuns: estes são os escudos-base do livro (cap. 16).
const ESCUDOS := {
	"nenhum": {"nome": "Sem escudo", "vida": 0, "resistencia": 0},
	"escudo_leve": {"nome": "Escudo leve", "vida": 5, "resistencia": 1},
	"escudo_pesado": {"nome": "Escudo pesado", "vida": 10, "resistencia": 2},
}

## "programado": o efeito já funciona no jogo. "uso": onde o jogo usa o item.
const CONSUMIVEIS := {
	"tocha": {"nome": "Tocha", "texto": "Ação: acender. Ilumina ao alcance curto e deixa o médio na penumbra. Quem segura defende com as cartas reveladas. Precisa de uma mão livre.", "programado": true, "uso": "luz"},
	"pocao_de_cura_pequena": {"nome": "Poção de Cura Pequena", "texto": "Ação: cure 5.", "programado": true, "acao": true},
	"pocao_de_mana_pequena": {"nome": "Poção de Mana Pequena", "texto": "Ação: recupere 3 de fadiga.", "programado": true, "acao": true},
	"gema_do_pantano": {"nome": "Gema do Pântano", "texto": "Tirada de um ovo da bruxa. Não serve para nada em combate; o mercador paga bem por ela.", "loja": false, "venda": 30},
	"cristal_de_ligacao": {"nome": "Lasca de Cristal", "texto": "Lasca de um cristal de ligação. O mercador paga bem.", "loja": false, "venda": 25},
	"frutas_silvestres": {"nome": "Frutas Silvestres", "texto": "Ação: coma; cure 2 e recupere 1 de fadiga. (Achadas no cenário; não se vendem.)", "programado": true, "acao": true, "loja": false},
	"veneno_acido": {"nome": "Veneno Ácido", "texto": "Ação: aplique na arma; seu próximo ataque causa +2 de dano que ignora resistência.", "programado": true, "acao": true},
	"kit_medico": {"nome": "Kit Médico", "texto": "Ação: remova todas as fichas de Sangramento de você ou de um aliado adjacente e cure 2 de vida.", "programado": true, "acao": true},
	"antidoto": {"nome": "Antídoto", "texto": "Ação: remova todas as fichas de Veneno. Recupere 1 de fadiga.", "programado": true, "acao": true},
	"racao_de_viagem": {"nome": "Ração de Viagem", "texto": "Necessária para o descanso longo; num descanso curto, recupere 3 de fadiga.", "programado": true,
		"uso": "Gasta sozinha no descanso curto (−3 de fadiga)."},
	"gazua": {"nome": "Gazua", "texto": "Ação: abra uma fechadura comum sem teste, ou faça um teste com Vantagem contra uma difícil; a gazua se quebra ao usar.", "programado": true,
		"uso": "Aparece como opção nas fechaduras."},
	"bomba_de_fumaca": {"nome": "Bomba de Fumaça", "texto": "Ação: crie uma área de fumaça 3×3 ao alcance curto. Ela conta como cobertura parcial para ataques à distância (10 rodadas).", "programado": true,
		"acao": true, "area": {"forma": "quadrado", "tamanho": 3, "alcance": 4}},
	"frasco_de_piche": {"nome": "Frasco de Piche (incomum)", "texto": "Ação: crie uma área 3×3 ao alcance curto. A área é terreno difícil e quem entrar num quadrado dela recebe 1 ficha de Imobilizar. A área é inflamável (10 rodadas).", "programado": true,
		"acao": true, "area": {"forma": "quadrado", "tamanho": 3, "alcance": 4}},
	"pedra_de_amolar": {"nome": "Pedra de Amolar", "texto": "Descanso longo: arma cortante ou perfurante causa +1 de dano.", "programado": false},
	"oleo_antiespectral": {"nome": "Óleo Antiespectral", "texto": "Ação: ataques atingem espectrais e causam +2 contra eles até o fim da cena.", "programado": false},
}

## Focos (PDF de equipamentos): "a arma" do ataque mágico. Ocupam uma mão (os
## cajados, as duas). Dano do ataque mágico = diferença + atributo de conjuração
## + dano do foco + dano extra da magia. O PDF ainda não tem o dano dos focos: os
## números de "dano" são do Claude, provisórios (o Lucas vai revisar a lista).
## "tipo": "arcano" (Mago) ou "sagrado" (Clérigo). "cartas": as ativadas, que viram
## cartas de item na batalha (com limite de fadiga próprio).
const FOCOS := {
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
const FOCO_DA_CLASSE := {"Mago": "varinha_eletrizante", "Clérigo": "simbolo_sagrado"}
const TIPO_DE_FOCO := {"Mago": "arcano", "Clérigo": "sagrado"}


## Kit Inicial de Aventura (todo herói recebe) e itens básicos de classe.
const NAO_CONSUMIVEIS := {
	"corda": {"nome": "Corda (15 m)", "texto": "Permite escalar, descer e prender-se com segurança; testes para escalar com ela têm Vantagem.", "programado": true,
		"uso": "Vantagem ao escalar; conserta a ponte quebrada."},
	"pe_de_cabra": {"nome": "Pé de Cabra", "texto": "Vantagem em testes de Força para forçar portas, tampas e mecanismos.", "programado": true,
		"uso": "Vantagem ao forçar o baú."},
	"pederneira": {"nome": "Pederneira", "texto": "Acende tochas, fogueiras e materiais inflamáveis sem gastar um teste.", "programado": false},
	"kit_de_reparos": {"nome": "Kit de Reparos", "texto": "Durante um descanso, restaure até 3 de vida de uma armadura ou escudo.", "programado": true,
		"uso": "Sozinho no descanso curto."},
	"kit_de_acampamento": {"nome": "Kit de Acampamento", "texto": "Permite realizar um descanso longo ao relento sem penalidade.", "programado": false},
	"lanterna": {"nome": "Lanterna", "texto": "Ilumina ao alcance curto. Presa ao cinto: não ocupa as mãos.", "programado": true,
		"uso": "Na batalha: acender ou apagar (ação de movimento). Vantagem ao procurar na toca escura."},
	"vara_de_3_metros": {"nome": "Vara de 3 Metros", "texto": "Testes para detectar armadilhas ou pisos falsos à sua frente têm Vantagem.", "programado": true,
		"uso": "Vantagem ao examinar a fechadura com armadilha."},
	"espelho_de_bolso": {"nome": "Espelho de Bolso", "texto": "Olhe por esquinas e cantos sem se expor, e sinalize à distância.", "programado": false},
	"bandoleira_de_armas": {"nome": "Bandoleira de Armas (Guerreiro)", "texto": "Duas vezes por cena, trocar de arma não custa ação.", "programado": false},
	"ferramentas_de_ladrao": {"nome": "Ferramentas de Ladrão (Ladino)", "texto": "Vantagem em testes para arrombar fechaduras e desarmar armadilhas, sem gastar gazuas.", "programado": true,
		"uso": "Vantagem ao destrancar fechaduras."},
	"simbolo_sagrado": {"nome": "Símbolo Sagrado (Clérigo)", "texto": "Foco sagrado (escolha em \"Foco mágico\"). No início do turno, retire 1 de fadiga dele.", "programado": true},
	"corda_de_arco_da_penumbra": {"nome": "Corda de Arco da Penumbra (Caçador)", "texto": "Se usou Sombra no último turno ou está na penumbra, scry 1 após atacar.", "programado": false},
	"varinha_eletrizante": {"nome": "Varinha Eletrizante (Mago)", "texto": "Foco arcano (escolha em \"Foco mágico\"). 3 de fadiga, Ação: 3 de dano a alcance médio, ignorando resistência.", "programado": true},
}

const KIT_INICIAL := ["corda", "pe_de_cabra", "pederneira", "kit_de_reparos", "kit_de_acampamento", "lanterna", "vara_de_3_metros", "espelho_de_bolso"]
const ITEM_DE_CLASSE := {"Guerreiro": "bandoleira_de_armas", "Ladino": "ferramentas_de_ladrao", "Clérigo": "simbolo_sagrado",
	"Caçador": "corda_de_arco_da_penumbra", "Mago": "varinha_eletrizante"}


## Texto da carta de arma (0.21): números e propriedades.
static func descricao_arma(a: Dictionary) -> String:
	if a.is_empty():
		return ""
	var partes := PackedStringArray()
	partes.append("Dano %d + %s" % [int(a.get("dano", 0)), "Destreza" if atributo_da_arma(a) == "destreza" else "Força"])
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
	var t := " · ".join(partes)
	if str(a.get("texto", "")) != "":
		t += "\n" + str(a["texto"])
	return t


static func atributo_da_arma(arma: Dictionary) -> String:
	## Armas leves e armas de tiro somam Destreza; as demais, Força.
	## Arremessáveis médias e grandes somam Força; a besta pesada não soma atributo.
	if arma.has("atributo"):
		return arma["atributo"]
	if arma.get("distancia", false) or arma["peso"] == "leve":
		return "destreza"
	return "forca"


static func alcance_corpo(arma: Dictionary) -> int:
	return 2 if arma["tamanho"] == "grande" else 1
