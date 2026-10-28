## Um personagem no campo: herói (vida = baralho) ou inimigo (vida = número).
extends RefCounted

const Baralho := preload("res://core/baralho.gd")
const Combate := preload("res://core/combate.gd")
const CartaEmJogo := preload("res://core/carta_em_jogo.gd")

var id := ""
var nome := ""
var lado := "inimigo"          # "heroi" ou "inimigo"
var tipo := ""                 # aparência: "guerreiro", "goblin", "goblin_atirador", "goblin_chefe"
var pos := Vector2i.ZERO
var classe := ""               # heróis: "Guerreiro", "Ladino"...
var raca := ""
var background := ""
var tamanho := "medio"         # "pequeno", "medio", "grande"
var espirito := 0

# Atributos (heróis e inimigos)
var atributos := {}
var forca := 0
var destreza := 0
var percepcao := 0
var sabedoria := 0
var constituicao := 0
var raciocinio := 0
var iniciativa := 0
var pericias := {}              # nome da perícia -> valor (heróis)

# Herói
var baralho: Baralho = null
var cartas: Array = []          # CartaEmJogo; a carta de herói (se houver) é a primeira
var consumiveis: Array = []     # ids de itens consumíveis; repetido = mais de um
var equipamentos: Array = []    # ids de itens não consumíveis (kit de aventura, item de classe)
var arma := {}
var arma_reserva := {}          # segunda arma, guardada (troca: Batalha.heroi_trocar_arma)
var armadura := {}
var escudo := {}
var foco := {}                  # foco mágico (varinha, orbe, cajado, símbolo): "a arma" do ataque mágico
var escolhas := {}              # escolhas feitas na criação por carta (ex.: perícias da Mente Maleável)
var vida_armadura := 0
var vida_escudo := 0
var armadura_salvou_na_cena := false

# Inimigo
var vida := 0
var vida_max := 0
var perfil := ""
var parada_ataque := 17
var parada_defesa := 17
var risco := 0.35               # chance de estourar que a IA aceita
var fichas := {}                # fichas de inimigos (a carta deles é a própria unidade)
var alerta := true              # desatento: só age depois de perceber um herói
var vigia := 3                  # distância em que um inimigo desatento percebe heróis
var ataque_oportunidade := false  # inimigo com a habilidade de atacar quem sai do seu alcance
var grupo := ""                 # inimigos do mesmo grupo se alertam juntos
var dormindo := false           # só muda o rótulo: desatento "(dormindo)"

# Combate
var dano := 0                   # dano da arma (herói) ou dano-base do ataque (inimigo)
var atributo_dano := 0          # Força ou Destreza que soma no dano
var resistencia := 0            # resistência própria (inimigos); heróis somam armadura e escudo
var velocidade := 3
var a_distancia := false
var alcance_corpo := 1
var faixas_ideais: Array = [Combate.Faixa.CURTO]
var patamar := ""                 # inimigos: lacaio, medio, conjurador, elite, elite_escoltado, chefe
var papel := ""                   # inimigos: aggro, tank, control, support, neutro
var espalha_ataques := false      # elite/chefe: cada ataque do turno num herói diferente
var ao_acertar: Array = []        # inimigos: fichas que põem ao acertar ([{"ficha": "Imobilizar"}])
var cura_aliado := 0              # inimigos de suporte: cura um aliado ferido no lugar de atacar
var lacaio := false
var bonus_limite_ataque := 0     # inimigos aggro à distância: +1 no limite do 21 ao atacar
var inteligencia := 1             # inimigos: 0 ignora zonas; 1 evita zona perigosa quando não atrapalha o ataque
var categoria := ""               # inimigos: goblinoide, fera, morto-vivo, demonio... (core/devocoes.gd)
var tipo_dano := "Corte"          # inimigos: tipo do dano do ataque
var fraquezas := {}               # inimigos: tipo de dano -> dano a mais que sofrem
var resiste_tipo := {}            # inimigos: tipo de dano -> dano a menos que sofrem
var divindade := ""               # Clérigo: divindade escolhida na criação (define a devoção)
var visao_no_escuro := false      # enxerga no escuro como penumbra
var luz := ""                     # luz que carrega acesa: "", "tocha", "lanterna"
var magias: Array = []            # inimigos conjuradores (Batalha._ia_conjurar)
var habilidades: Array = []       # inimigos (0.23): ações especiais de chefe/monstro (Batalha._ia_habilidades)
var escolta := ""                 # inimigos (0.23): id do líder; fica atrás dele até ele entrar na luta
var protegido_por: Array = []     # inimigos (0.23): enquanto algum destes viver, sofre metade do dano
var estrategia := ""              # inimigos (0.22): o jeito de agir agora (atacar, atirar, fugir...)
var intencao := ""                # inimigos (0.22): o que pretende no próximo turno, em texto
var alvo_plano := ""              # inimigos (0.22): o herói que pretende atacar
var flutua := false               # fantasmas: atravessam água e ignoram terreno difícil
var reacoes: Array = []           # inimigos: [{"gatilho": "ao_ser_atacado", "efeito": "mover"|"ficha_no_atacante"|"bonus_contra_atacante", ...}]

# Economia de ações e efeitos temporários
var mov_por_turno := 1
var padrao_por_turno := 2
var reacao_por_turno := 1
var acoes_mov := 0
var acoes_padrao := 0
var acoes_reacao := 0
var deslocamento := 0
var ignora_impedimento := false   # Romper a Linha: até o fim do movimento concedido
var efeitos := {}                 # nome -> {"valor": x, "ate": "inicio_turno"/"fim_turno"/"proximo_ataque"}
var atacou_nesta_rodada := false
var recuperar_fadiga_no_fim := 0  # Respirar Fundo
var moveu_no_turno := false
var so_moveu := true              # só fez ações de movimento neste turno (Fôlego de Viajante)
var gastos: Array = []            # consumíveis gastos (Sempre um Plano)


static func criar(cfg: Dictionary, rng: RandomNumberGenerator):
	var u = load("res://core/unidade.gd").new()
	for chave in cfg:
		if chave in u and chave != "cartas":
			u.set(chave, cfg[chave])
	if u.lado == "heroi":
		u.baralho = Baralho.new(rng)
		for c in cfg.get("cartas_cfg", []):
			var cj := CartaEmJogo.new()
			cj.id = c["id"]
			cj.tipo = c["tipo"]
			cj.lados = c["lados"]
			u.cartas.append(cj)
		u.vida_armadura = int(u.armadura.get("vida", 0))
		u.vida_escudo = int(u.escudo.get("vida", 0))
	else:
		u.vida_max = u.vida
	return u


## Valor de um atributo pelo nome ("mentira", "diplomacia"...).
func atributo(nome: String) -> int:
	return int(atributos.get(nome, 0))


func eh_heroi() -> bool:
	return lado == "heroi"


func viva() -> bool:
	if eh_heroi():
		return baralho.estado == Baralho.Estado.ATIVO
	return vida > 0


func novo_turno() -> void:
	acoes_mov = mov_por_turno
	acoes_padrao = padrao_por_turno
	acoes_reacao = reacao_por_turno
	deslocamento = 0
	ignora_impedimento = false
	atacou_nesta_rodada = false
	for nome_ef in efeitos.keys():
		if efeitos[nome_ef].get("ate", "") == "inicio_turno":
			efeitos.erase(nome_ef)


## Imobilizado: tem a ficha Imobilizar em alguma carta (heróis) ou em si (inimigos).
func imobilizado() -> bool:
	if not eh_heroi():
		return fichas.get("Imobilizar", 0) > 0
	for c in cartas:
		if c.tem_ficha("Imobilizar"):
			return true
	return false


## O lado ativo de alguma carta tem este slug?
func ativo(slug: String) -> bool:
	for c in cartas:
		if c.slug() == slug:
			return true
	return false


func carta_com(slug: String):
	for c in cartas:
		if c.slug() == slug:
			return c
	return null


func carta_heroi():
	for c in cartas:
		if c.tipo == "heroi":
			return c
	return null


## Cartas que deixam o herói imune a uma ficha.
const IMUNIDADES := {"Veneno": "constituicao-de-pedra", "Imobilizar": "sempre-uma-saida", "Medo": "coragem-miuda"}


## Fichas somadas: nas cartas (heróis) ou na própria unidade (inimigos).
func fichas_total(nome_ficha: String) -> int:
	if not eh_heroi():
		return int(fichas.get(nome_ficha, 0))
	var n := 0
	for c in cartas:
		n += int(c.fichas.get(nome_ficha, 0))
	return n


## Dá fichas: inimigos guardam na unidade (sem limite). Heróis (Lucas, 0.20): cada ficha
## vai para uma carta que ainda não tem desse tipo — a de herói primeiro; se não couber em
## nenhuma, a ficha se perde. Quando havia mais de uma carta possível, a escolha fica em
## "fichas_a_escolher" e a tela pergunta ao jogador onde ela fica (Batalha.mover_ficha).
var fichas_a_escolher: Array = []   # [{"ficha", "carta": índice}]


func dar_ficha(nome_ficha: String, qtd := 1) -> void:
	if not eh_heroi():
		fichas[nome_ficha] = int(fichas.get(nome_ficha, 0)) + qtd
		return
	if IMUNIDADES.has(nome_ficha) and ativo(IMUNIDADES[nome_ficha]):
		return
	var ordem := []
	if carta_heroi() != null:
		ordem.append(cartas.find(carta_heroi()))
	for i in cartas.size():
		if not i in ordem:
			ordem.append(i)
	for k in qtd:
		var possiveis := ordem.filter(func(i): return cartas[i].pode_receber(nome_ficha))
		if possiveis.is_empty():
			return
		cartas[possiveis[0]].dar_ficha(nome_ficha, 1)
		if possiveis.size() > 1 and not nome_ficha in cartas[possiveis[0]].EMPILHAVEIS:
			fichas_a_escolher.append({"ficha": nome_ficha, "carta": possiveis[0]})


## Tira até "qtd" fichas de onde estiverem. Devolve quantas saíram.
func tirar_fichas(nome_ficha: String, qtd := 999) -> int:
	var tiradas := 0
	if not eh_heroi():
		tiradas = mini(int(fichas.get(nome_ficha, 0)), qtd)
		if tiradas > 0:
			fichas[nome_ficha] = int(fichas[nome_ficha]) - tiradas
			if fichas[nome_ficha] <= 0:
				fichas.erase(nome_ficha)
		return tiradas
	for c in cartas:
		while tiradas < qtd and c.tirar_ficha(nome_ficha):
			tiradas += 1
	return tiradas


func tem_item(id: String) -> bool:
	return id in consumiveis or id in equipamentos


func quantidade(id: String) -> int:
	return consumiveis.count(id)


func resistencia_total() -> int:
	if not eh_heroi():
		return resistencia
	var r := resistencia
	var muralha := ativo("a-muralha")   # quebrados, ainda dão +1 de resistência
	if vida_armadura > 0:
		r += int(armadura.get("resistencia", 0)) * (2 if efeitos.has("peso_da_muralha") else 1)
	elif muralha and int(armadura.get("resistencia", 0)) > 0:
		r += 1
	if vida_escudo > 0:
		r += int(escudo.get("resistencia", 0))
	elif muralha and int(escudo.get("resistencia", 0)) > 0:
		r += 1
	if efeitos.has("ancora"):
		r += 3
	return r


func resistencia_armadura() -> int:
	return int(armadura.get("resistencia", 0)) if vida_armadura > 0 else 0


func vida_texto() -> String:
	if eh_heroi():
		return "%d cartas" % baralho.baralho.size()
	return "%d/%d" % [vida, vida_max]
