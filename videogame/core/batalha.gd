## Batalha no grid: heróis contra inimigos, em turnos pela iniciativa.
##
## Turno: 1 ação de Movimento, ações Padrão (2 para heróis) e 1 Reação. Uma
## Padrão pode ser rebaixada a Movimento. Uma ação de movimento dá deslocamento
## igual à Velocidade, usado aos poucos. Impedimento: ao ficar adjacente a um
## inimigo, o deslocamento restante zera; impedido, uma ação de movimento dá 1.
##
## Testes de ataque e defesa: SÓ as cartas (+ ajustes de habilidades).
## Dano = diferença + dano da arma + atributo da arma (Destreza para leves e
## armas de tiro, Força para as outras) − resistência do defensor.
##
## A tela chama as ações do herói e, enquanto fase_automatica() for verdadeira,
## chama passo_automatico() com pausas. Animações vêm da fila "eventos".
extends RefCounted

const Baralho := preload("res://core/baralho.gd")
const BaralhoInimigo := preload("res://core/baralho_inimigo.gd")
const Teste21 := preload("res://core/teste21.gd")
const Combate := preload("res://core/combate.gd")
const Iniciativa := preload("res://core/iniciativa.gd")
const IA := preload("res://core/ia_inimigo.gd")
const Grade := preload("res://core/grade.gd")
const Unidade := preload("res://core/unidade.gd")
const Carta := preload("res://core/carta.gd")
const Efeitos := preload("res://core/efeitos.gd")
const Itens := preload("res://core/itens.gd")
const Classes := preload("res://core/cartas_classes.gd")
const Origens := preload("res://core/cartas_origens.gd")
const Extras := preload("res://core/cartas_extras.gd")
const Personagem := preload("res://core/personagem.gd")
const Areas := preload("res://core/areas.gd")
const Devocoes := preload("res://core/devocoes.gd")

## Ataque mágico: diferença + dano do foco + atributo de conjuração da classe
## (+ o dano extra da magia).
const ATRIBUTO_MAGIA := {"Mago": "raciocinio", "Clérigo": "sabedoria"}

enum Fase { HEROI_ESCOLHE, HEROI_ATACANDO, IA_DEFENDENDO, IA_TURNO, IA_ATACANDO, HEROI_DEFENDENDO, RESOLVIDO, VITORIA, DERROTA,
	DISTRIBUINDO_DANO, INTERACAO_TESTE, INTERACAO_RESOLVIDA, SOMBRA_ESCOLHA, ACAO_LONGA, PERGUNTA }

const PARADA_DEFESA_AUTOMATICA := 17
const RISCO_DEFESA_AUTOMATICA := 0.35

var rng := RandomNumberGenerator.new()
var semente: int
var grade: Grade
var unidades: Array = []
var baralho_inimigos: BaralhoInimigo

var fase: Fase = Fase.HEROI_ESCOLHE
var ordem: Array = []
var indice_vez := 0
var rodada := 1
var teste_ataque: Teste21
var teste_defesa: Teste21
var atacante: Unidade
var defensor: Unidade
var ctx: Dictionary = {}          # contexto do ataque em andamento (habilidade usada etc.)
var resultado: Dictionary = {}
var defesa_automatica := false
var dano_na_armadura := true      # o herói absorve dano com escudo e armadura antes do baralho
var registro: Array[String] = []
var eventos: Array = []

# Dano no herói: o jogador escolhe quanto vai para escudo, armadura e baralho.
var distribuicao_automatica := true   # testes e simulações; a tela desliga para o jogador escolher
var dano_pendente: Dictionary = {}    # {"id", "dano", "origem", "volta"}

# Exploração: pontos de interação no mapa e testes de atributo.
var interacoes: Array = []            # ver core/dados_exploracao.gd
var decoracao: Dictionary = {}        # Vector2i -> tipo (chão especial, ex.: "ponte")
var teste_pericia: Teste21
var interacao_atual: Dictionary = {}  # {"id", "opcao", "dano", "vitoria"}
var resultado_interacao: Dictionary = {}
var vitoria_ao_derrotar_todos := true
var objetivo := ""
var vitoria_se_morrer: Array = []   # ids de inimigos: quando todos caem, a missão está cumprida
var mensagem_vitoria := ""
var sombra_usada := false          # algum herói gastou Sombra (Seguidor da Noite)
var fadiga_dupla := false          # Matador de Gigante (crítico): 2 de fadiga saem no fim do turno
var sem_reacoes_ate := ""          # Seguidor da Noite (crítico): inimigos sem reações até o turno deste herói
var mensagem_fim := ""


func _init(cenario: Dictionary, semente_inicial: int) -> void:
	semente = semente_inicial
	rng.seed = semente
	grade = Grade.new(cenario["largura"], cenario["altura"])
	for p in cenario["obstaculos"]:
		grade.obstaculos[p] = cenario["obstaculos"][p]
	baralho_inimigos = BaralhoInimigo.new(rng)
	for cfg in cenario["unidades"]:
		unidades.append(Unidade.criar(cfg, rng))
	interacoes = cenario.get("interacoes", []).duplicate(true)
	for it in interacoes:
		for op in it.get("opcoes", []):
			_normalizar_teste(op)
			for ab in op.get("abordagens", []):
				_normalizar_teste(ab)
			# Descanso curto só nos pontos de descanso, e sem inimigos por perto (0.19).
			if str(op.get("resultados", {})).contains("descanso_curto"):
				it["descanso"] = true
				op["sem_inimigos_perto"] = int(op.get("sem_inimigos_perto", RAIO_DESCANSO_SEGURO))
	decoracao = cenario.get("decoracao", {}).duplicate()
	vitoria_ao_derrotar_todos = cenario.get("vitoria_ao_derrotar_todos", true)
	objetivo = cenario.get("objetivo", "")
	vitoria_se_morrer = cenario.get("vitoria_se_morrer", [])
	tutorial = cenario.get("tutorial", []).duplicate(true)
	_iniciar_cenas(cenario)
	for u in herois():
		if u.ativo("braco-de-labuta"):
			_ajustar_forca(u, 1)
	mensagem_vitoria = cenario.get("mensagem_vitoria", "")
	escuro = cenario.get("escuro", false)
	luz_ambiente = int(cenario.get("luz_ambiente", 0))
	for zc in cenario.get("zonas", []):
		criar_zona(zc["tipo"], zc["nome"], zc["celulas"], null, zc.get("opcoes", {"vinculada": false, "rodadas": -1}))
	piso = cenario.get("piso", "grama")
	recompensa = int(cenario.get("recompensa", 0))
	for l in cenario.get("luzes", []):
		luzes.append(l.duplicate())


func iniciar() -> void:
	for u in herois():
		_iniciar_cena(u)
	_log("Início da cena: cada herói compra 2 + Sabedoria cartas.")
	var participantes := []
	for u in unidades:
		participantes.append({"id": u.id, "destreza": u.destreza, "iniciativa": u.iniciativa})
	ordem = Iniciativa.ordenar(participantes, rng)
	_log("Iniciativa: " + ", ".join(PackedStringArray(ordem.map(func(i): return nome_visto(unidade(i))))))
	indice_vez = 0
	if not abertura.is_empty():
		_narrar(abertura.get("titulo", ""), abertura.get("texto", ""))
	_comecar_turno()


func _iniciar_cena(u: Unidade) -> void:
	u.baralho.iniciar_cena(u.sabedoria)
	if u.ativo("devorador-de-grimorios"):
		u.baralho.comprar_para_mao(1)
		_log("Devorador de Grimórios: %s compra 1 carta a mais." % u.nome)
	_atualizar_limites(u)
	u.armadura_salvou_na_cena = false
	if u.ativo("manutencao-do-equipamento"):
		if u.vida_armadura > 0:
			u.vida_armadura = int(u.armadura["vida"]) + 2
		if u.vida_escudo > 0:
			u.vida_escudo = int(u.escudo["vida"]) + 2
		_log("Manutenção do Equipamento: armadura e escudo começam com +2 de vida.")
	if u.ativo("incansavel"):
		u.carta_heroi().dar_ficha("Preparo")
		_log("Incansável: %s ganha 1 ficha de Preparo." % u.nome)


# --- Consultas --------------------------------------------------------------

func unidade(id: String) -> Unidade:
	for u in unidades:
		if u.id == id:
			return u
	return null


func ativa() -> Unidade:
	return unidade(ordem[indice_vez]) if not ordem.is_empty() else null


func herois() -> Array:
	return unidades.filter(func(u): return u.eh_heroi())


func inimigos_vivos() -> Array:
	return unidades.filter(func(u): return not u.eh_heroi() and u.viva())


func herois_ativos() -> Array:
	return unidades.filter(func(u): return u.eh_heroi() and u.viva())


func na_posicao(p: Vector2i) -> Unidade:
	for u in unidades:
		if u.viva() and u.pos == p:
			return u
	return null


func oponentes(u: Unidade) -> Array:
	return unidades.filter(func(o): return o.viva() and o.eh_heroi() != u.eh_heroi())


func aliados_adjacentes(u: Unidade, p: Vector2i) -> int:
	var n := 0
	for o in unidades:
		if o != u and o.viva() and o.eh_heroi() == u.eh_heroi() and Grade.adjacentes(o.pos, p):
			n += 1
	return n


func impedido(u: Unidade) -> bool:
	for o in oponentes(u):
		if Grade.adjacentes(o.pos, u.pos):
			return true
	return false


func _ocupadas(exceto: Unidade) -> Dictionary:
	var d := {}
	for u in unidades:
		if u != exceto and u.viva():
			d[u.pos] = true
	return d


func _perigos(u: Unidade) -> Dictionary:
	var d := {}
	if u.ignora_impedimento:
		return d
	for o in oponentes(u):
		for dir in Grade.DIRECOES:
			d[o.pos + dir] = true
	return d


func pode_ganhar_deslocamento(u: Unidade) -> bool:
	return (u.acoes_mov > 0 or u.acoes_padrao > 0) and not preso(u)


## Quadrados que uma ação de movimento rende agora: a velocidade (1 se impedido
## ou caído), menos 1 por ficha de Imobilizar.
func passos_por_acao(u: Unidade) -> int:
	if agarrado(u):
		return 0
	var v := 1 if (impedido(u) or u.efeitos.has("caido")) else _velocidade(u)
	if u.eh_heroi() and u.ativo("ignorar-a-dor"):
		return v
	return maxi(v - u.fichas_total("Imobilizar"), 0)


## Não consegue sair do lugar (Imobilizar demais).
func preso(u: Unidade) -> bool:
	return passos_por_acao(u) <= 0


func alcance_movimento(u: Unidade) -> Dictionary:
	var passos := u.deslocamento
	var precisa_acao := false
	if passos == 0 and pode_ganhar_deslocamento(u):
		passos = passos_por_acao(u)
		precisa_acao = true
	var mapa := _sem_passagem(grade.alcance(u.pos, passos, _ocupadas(u), _perigos(u), modo_de_andar(u)))
	mapa.erase(u.pos)
	return {"mapa": mapa, "precisa_acao": precisa_acao}


## Casas onde dá para parar (tira as casas de aliados, que só se atravessam).
func _sem_passagem(mapa: Dictionary) -> Dictionary:
	var m := {}
	for p in mapa:
		if not mapa[p].get("passa", false):
			m[p] = mapa[p]
	return m


func _velocidade(u: Unidade) -> int:
	var v := u.velocidade - (1 if u.efeitos.has("lento") else 0)
	if u.efeitos.has("pes_no_telhado"):
		v += 1
	if u.eh_heroi() and u.ativo("furia-crescente") and u.fichas_total("Fúria") >= 5:
		v += 1
	if u.eh_heroi() and u.destreza >= 3:
		v += 1
	return maxi(v, 1)


func faixa_entre(a: Unidade, b: Unidade) -> Combate.Faixa:
	return Combate.faixa(Grade.distancia(a.pos, b.pos))


## Pode "u" atacar "alvo" agora? Retorna "" se pode, ou o motivo.
func motivo_sem_ataque(u: Unidade, alvo: Unidade, exige_padrao := true) -> String:
	if alvo == null or not alvo.viva() or alvo == u:
		return "alvo inválido"
	var confuso: String = u.efeitos.get("confuso", {}).get("alvo", "")
	if confuso != "" and alvo.id != confuso:
		return "confuso: só pode atacar %s" % unidade(confuso).nome
	if alvo.eh_heroi() == u.eh_heroi() and confuso != alvo.id:
		return "alvo inválido"
	if exige_padrao and u.acoes_padrao <= 0:
		return "sem ação padrão"
	if u.efeitos.has("descarregada"):
		return "a besta precisa ser recarregada"
	return motivo_alcance(u, alvo, u.pos)


func motivo_alcance(u: Unidade, alvo: Unidade, de: Vector2i) -> String:
	var dist := Grade.distancia(de, alvo.pos)
	if not u.a_distancia:
		return "" if dist <= u.alcance_corpo else "fora do alcance corpo a corpo"
	if dist > 12:
		return "além do alcance longo"
	if not grade.linha_de_visao(de, alvo.pos):
		return "sem linha de visão"
	if not ve_de(u, de, alvo.pos):
		return "no escuro: não enxerga o alvo"
	return ""


# --- Ações do herói ---------------------------------------------------------

func vez_do_heroi() -> bool:
	return fase == Fase.HEROI_ESCOLHE and ativa() != null and ativa().eh_heroi()


func heroi_mover(destino: Vector2i) -> bool:
	if not vez_do_heroi():
		return false
	return _mover(ativa(), destino)


func heroi_atacar(alvo: Unidade) -> bool:
	if not vez_do_heroi() or motivo_sem_ataque(ativa(), alvo) != "":
		return false
	ativa().acoes_padrao -= 1
	_agiu(ativa())
	_tut("atacou")
	_novo_ataque(ativa(), alvo, {})
	return true


func heroi_concentrar() -> bool:
	var u := ativa()
	if not vez_do_heroi() or u.acoes_padrao <= 0 or u.efeitos.has("confuso"):
		return false
	u.acoes_padrao -= 1
	_agiu(u)
	var n_c := 2 if u.efeitos.has("concentrar_extra") else 1
	u.efeitos.erase("concentrar_extra")
	u.baralho.comprar_para_mao(n_c)
	_log("%s se concentra e compra %d carta(s)." % [u.nome, n_c])
	_tut("acao")
	_verificar_queda_heroi(u)
	return true


func heroi_recuperar_folego() -> bool:
	var u := ativa()
	if not vez_do_heroi() or u.acoes_padrao <= 0 or u.baralho.descarte.is_empty() or u.efeitos.has("confuso"):
		return false
	u.acoes_padrao -= 1
	_agiu(u)
	_curar(u, u.constituicao, "recupera o fôlego")
	_tut("acao")
	return true


func heroi_planejar() -> bool:
	var u := ativa()
	if not vez_do_heroi() or u.acoes_padrao <= 0 or u.efeitos.has("confuso"):
		return false
	u.acoes_padrao -= 1
	_agiu(u)
	_tut("acao")
	# Planejar: olha as 2 cartas do topo (o dobro com O Atemporal).
	var topo := u.baralho.baralho.slice(-2 * (2 if u.ativo("o-atemporal") else 1))
	topo.reverse()
	_log("%s planeja: o topo do baralho é %s." % [u.nome, _nomes(topo)])
	eventos.append({"tipo": "espiar", "id": u.id, "titulo": "Topo do seu\nbaralho:", "cartas": topo})
	if u.raciocinio >= 3:
		u.efeitos["planejou"] = {"cartas": topo, "ate": "inicio_turno"}
	if u.raciocinio >= 5:
		u.baralho.comprar_para_mao(1)
		u.efeitos["topo_da_mao"] = {"ate": "inicio_turno"}
		_log("Raciocínio 5: %s compra 1 carta e vai pôr uma carta da mão no topo do baralho." % u.nome)
	return true


# --- Tutorial (0.22) ----------------------------------------------------------
##
## Uma missão pode ter "tutorial": uma lista de etapas, cada uma com "titulo",
## "texto", a condição para passar ("cond") e efeitos ao começar ("ao_comecar").
## Condições: {"tipo": "botao"} (o jogador aperta Próximo), {"tipo": "perto", "id": u}
## (o herói ao lado da unidade), {"tipo": "flag", "flags": [...]} (alguma das ações
## marcadas aconteceu: atacou, carta, acao, encerrou, subiu, saltou, manobra, defendeu)
## e {"tipo": "nunca"} (a última, que termina com a vitória).

var tutorial: Array = []
var tutorial_etapa := 0
var tutorial_flags := {}


func _tut(flag: String) -> void:
	tutorial_flags[flag] = true


func etapa_tutorial() -> Dictionary:
	return tutorial[tutorial_etapa] if tutorial_etapa < tutorial.size() else {}


func _cond_tutorial(c: Dictionary) -> bool:
	match c.get("tipo", "botao"):
		"perto":
			var o := unidade(c["id"])
			return o != null and herois_ativos().any(func(h): return Grade.adjacentes(h.pos, o.pos))
		"flag":
			return c["flags"].any(func(f): return tutorial_flags.has(f))
	return false


## Passa as etapas cumpridas. Devolve true se mudou de etapa.
func avancar_tutorial() -> bool:
	if not vez_do_heroi():
		return false
	var mudou := false
	while tutorial_etapa < tutorial.size() and _cond_tutorial(tutorial[tutorial_etapa].get("cond", {})):
		_proxima_etapa()
		mudou = true
	return mudou


func tutorial_proximo() -> bool:
	var e := etapa_tutorial()
	if e.is_empty() or e.get("cond", {}).get("tipo", "botao") != "botao":
		return false
	_proxima_etapa()
	avancar_tutorial()
	return true


func _proxima_etapa() -> void:
	tutorial_etapa += 1
	var e := etapa_tutorial()
	if e.is_empty():
		return
	_log("Treino: %s." % e["titulo"])
	var h: Unidade = herois()[0] if not herois().is_empty() else null
	for ef in e.get("ao_comecar", []):
		_aplicar_efeito(h, {"id": "", "nome": "Treino", "pos": h.pos if h != null else Vector2i.ZERO}, ef)


# --- Ações do livro (0.22): Correr, Saltar e manobras de luta -----------------
##
## Correr: 3 ações de movimento (a de Movimento + as Padrão rebaixadas). Teste de
## Atletismo + Força: 2–8 avança 1 e cai; 9–12 velocidade normal; 13–16 o dobro;
## 17–21 o triplo; 22+ quatro vezes a velocidade + Atletismo. Ignora impedimento;
## os inimigos têm vantagem para atacá-lo até o próximo turno dele.
## Saltar: 2 ações de movimento. 2–8 avança 1 e cai; 9–12 salta 1; 13–16, 2;
## 17–21, 3; 22+, 4. Ignora impedimento e terreno difícil (é o jeito de sair de um
## cerco); o ataque de oportunidade contra quem salta tem vantagem.
## Manobras: 1 ação Padrão, contra um inimigo ao lado. Luta + Força contra
## Força do inimigo (2 cartas do baralho dos inimigos). Inimigo maior: −5 no limite
## por degrau de tamanho.

const MANOBRAS := {
	"derrubar": {"nome": "Derrubar", "texto": "o alvo fica Caído"},
	"empurrar": {"nome": "Empurrar", "texto": "empurra 1 quadrado, +1 a cada 5 de diferença"},
	"atrapalhar": {"nome": "Atrapalhar", "texto": "1 Penalidade no alvo, +1 a cada 5 de diferença"},
	"desarmar": {"nome": "Desarmar", "texto": "o alvo larga a arma"},
	"agarrar": {"nome": "Agarrar", "texto": "o alvo fica Agarrado: não sai do lugar enquanto você estiver ao lado"},
}


## Ações de movimento que ainda dá para gastar (a de Movimento + as Padrão).
func acoes_de_movimento(u: Unidade) -> int:
	return u.acoes_mov + u.acoes_padrao


func motivo_sem_correr(u: Unidade, custo: int) -> String:
	if not vez_do_heroi():
		return "não é a sua vez"
	if u.efeitos.has("caido"):
		return "caído: levante-se primeiro"
	if u.efeitos.has("confuso"):
		return "confuso"
	if u.efeitos.has("agarrado"):
		return "agarrado"
	if preso(u) and not impedido(u):
		return "imobilizado"
	if acoes_de_movimento(u) < custo:
		return "precisa de %d ações de movimento (a de Movimento e as Padrão rebaixadas)" % custo
	return ""


func _pagar_movimentos(u: Unidade, n: int) -> void:
	for i in n:
		if u.acoes_mov > 0:
			u.acoes_mov -= 1
		else:
			u.acoes_padrao -= 1
	u.deslocamento = 0
	u.moveu_no_turno = true


func opcao_correr(u: Unidade) -> Dictionary:
	var v := _velocidade(u)
	var atl := valor_componente(u, "Atletismo")
	return {"titulo": "Correr", "texto": "Correr", "teste": {"somar": ["Atletismo", "forca"], "movimento": true},
		"faixas": [[0, "cai"], [9, "normal"], [13, "dobro"], [17, "triplo"], [22, "quadruplo"]],
		"resultados": {
			"cai": {"rotulo": "tropeça", "sucesso": false, "texto": "O pé engancha e você vai ao chão depois de um passo.",
				"efeitos": [{"tipo": "correr", "quadrados": 1, "cai": true}]},
			"normal": {"rotulo": "%d quadrados" % v, "sucesso": true, "texto": "Você corre no ritmo de sempre.",
				"efeitos": [{"tipo": "correr", "quadrados": v}]},
			"dobro": {"rotulo": "%d quadrados" % (2 * v), "sucesso": true, "texto": "Você dispara.",
				"efeitos": [{"tipo": "correr", "quadrados": 2 * v}]},
			"triplo": {"rotulo": "%d quadrados" % (3 * v), "sucesso": true, "texto": "Você voa pelo campo.",
				"efeitos": [{"tipo": "correr", "quadrados": 3 * v}]},
			"quadruplo": {"rotulo": "%d quadrados" % (4 * v + atl), "sucesso": true, "texto": "Uma corrida que ninguém vai esquecer.",
				"efeitos": [{"tipo": "correr", "quadrados": 4 * v + atl}]},
		}}


func opcao_saltar(_u: Unidade) -> Dictionary:
	return {"titulo": "Saltar", "texto": "Saltar", "teste": {"somar": ["Atletismo", "forca"], "movimento": true},
		"faixas": [[0, "cai"], [9, "um"], [13, "dois"], [17, "tres"], [22, "quatro"]],
		"resultados": {
			"cai": {"rotulo": "1 quadrado e cai", "sucesso": false, "texto": "O impulso sai torto: você avança pouco e cai.",
				"efeitos": [{"tipo": "saltar", "quadrados": 1, "cai": true}]},
			"um": {"rotulo": "1 quadrado", "sucesso": true, "texto": "Um salto curto, mas limpo.", "efeitos": [{"tipo": "saltar", "quadrados": 1}]},
			"dois": {"rotulo": "2 quadrados", "sucesso": true, "texto": "Você pula longe.", "efeitos": [{"tipo": "saltar", "quadrados": 2}]},
			"tres": {"rotulo": "3 quadrados", "sucesso": true, "texto": "Um salto enorme.", "efeitos": [{"tipo": "saltar", "quadrados": 3}]},
			"quatro": {"rotulo": "4 quadrados", "sucesso": true, "texto": "Você parece flutuar.", "efeitos": [{"tipo": "saltar", "quadrados": 4}]},
		}}


func heroi_correr() -> bool:
	var u := ativa()
	if u == null or motivo_sem_correr(u, 3) != "":
		return false
	_pagar_movimentos(u, 3)
	_tut("saltou")
	if u.ativo("resistencia-do-corredor"):
		_log("Resistência do Corredor: −%d de fadiga." % _tirar_fadiga(u, 1))
	teste_de_acao(u, opcao_correr(u))
	return true


func heroi_saltar() -> bool:
	var u := ativa()
	if u == null or motivo_sem_correr(u, 2) != "":
		return false
	_pagar_movimentos(u, 2)
	_tut("saltou")
	teste_de_acao(u, opcao_saltar(u))
	return true


## Efeito de Correr/Saltar: o herói ganha o deslocamento e anda com o mouse, como sempre.
func _efeito_correr(u: Unidade, ef: Dictionary, saltar: bool) -> String:
	var q := int(ef["quadrados"])
	u.deslocamento = q
	u.ignora_impedimento = true
	if saltar:
		u.efeitos["saltando"] = {"ate": "inicio_turno"}
	else:
		u.efeitos["correu"] = {"ate": "inicio_turno"}
	if ef.get("cai", false):
		u.efeitos["cai_ao_parar"] = {"ate": "inicio_turno"}
		return "Anda %d quadrado e fica Caído." % q
	if saltar:
		return "Pode saltar até %d quadrado(s): ignora impedimento e terreno difícil. Ataque de oportunidade contra você tem vantagem." % q
	return "Pode correr até %d quadrados: ignora impedimento. Até o seu próximo turno, os inimigos têm vantagem para atacá-lo." % q


## Fim do deslocamento de Correr/Saltar.
func _fim_da_corrida(u: Unidade) -> void:
	u.efeitos.erase("saltando")
	if u.efeitos.has("escalando"):
		if grade.nivel(u.pos) > int(u.efeitos["escalando"].get("nivel", 0)) or no_alto(u):
			u.dar_ficha("Mira")
			_log("Cabra da Montanha: %s termina mais alto e ganha 1 Mira." % u.nome)
		u.efeitos.erase("escalando")
	if u.efeitos.has("cai_ao_parar"):
		u.efeitos.erase("cai_ao_parar")
		derrubar(u)


func motivo_sem_manobra(u: Unidade, alvo: Unidade, tipo: String) -> String:
	if not vez_do_heroi() or u == null:
		return "não é a sua vez"
	if not MANOBRAS.has(tipo):
		return "manobra desconhecida"
	if alvo == null or alvo.eh_heroi() or not alvo.viva():
		return "escolha um inimigo"
	if u.acoes_padrao <= 0:
		return "sem ação padrão"
	if u.efeitos.has("confuso"):
		return "confuso"
	if not Grade.adjacentes(u.pos, alvo.pos):
		return "o alvo precisa estar ao lado"
	if tipo == "desarmar" and (alvo.efeitos.has("sem_arma") or alvo.tipo in ARMA_NATURAL):
		return "o alvo não tem arma para largar"
	if tipo == "agarrar" and alvo.efeitos.has("agarrado"):
		return "já está agarrado"
	if tipo == "derrubar" and alvo.efeitos.has("caido"):
		return "já está caído"
	return ""


## Degraus de tamanho que o alvo tem a mais que o herói.
func _degraus_acima(u: Unidade, alvo: Unidade) -> int:
	return maxi(int(Origens.TAMANHO.get(alvo.tamanho, 1)) - int(Origens.TAMANHO.get(u.tamanho, 1)), 0)


func heroi_manobra(tipo: String, alvo: Unidade) -> bool:
	var u := ativa()
	if motivo_sem_manobra(u, alvo, tipo) != "":
		return false
	u.acoes_padrao -= 1
	_agiu(u)
	_tut("manobra")
	_alertar_inimigos(alvo.grupo)
	var dif := valor_resistido(alvo, "forca") + int(alvo.pericias.get("Luta", 0))
	var m: Dictionary = MANOBRAS[tipo]
	var degraus := _degraus_acima(u, alvo)
	_log("%s tenta %s %s: o inimigo resiste com %d (Força)." % [u.nome, m["nome"].to_lower(), alvo.nome, dif])
	var op := {"titulo": "%s: %s" % [m["nome"], alvo.nome], "texto": m["nome"],
		"teste": {"somar": ["Luta", "forca"]}, "dificuldade": dif, "manobra_limite": -5 * degraus,
		"faixas": [[0, "falha"], [dif, "sucesso"]],
		"resultados": {
			"falha": {"rotulo": "o inimigo resiste", "texto": "%s não cede." % alvo.nome},
			"sucesso": {"rotulo": "consegue", "texto": "", "efeitos": [{"tipo": "manobra", "manobra": tipo, "dif": dif}]},
		}}
	if degraus > 0:
		_log("%s é maior: −%d no limite do teste." % [alvo.nome, 5 * degraus])
	teste_de_acao(u, op, alvo)
	return true


func _efeito_manobra(u: Unidade, ef: Dictionary, valor: int) -> String:
	var alvo := unidade(interacao_atual.get("alvo", ""))
	if alvo == null or not alvo.viva():
		return ""
	var extra := maxi(int((valor - int(ef["dif"])) / 5), 0)
	match ef["manobra"]:
		"derrubar":
			derrubar(alvo)
			return "%s fica Caído." % alvo.nome
		"empurrar":
			_empurrar(alvo, u.pos, 1 + extra)
			return "%s é empurrado %d quadrado(s)." % [alvo.nome, 1 + extra]
		"atrapalhar":
			alvo.dar_ficha("Penalidade", 1 + extra)
			return "%s recebe %d Penalidade (−1 no limite do próximo teste por ficha)." % [alvo.nome, 1 + extra]
		"desarmar":
			desarmar(alvo)
			return "%s larga a arma até o fim da cena." % alvo.nome
		"agarrar":
			alvo.efeitos["agarrado"] = {"por": u.id}
			return "%s está agarrado: não sai do lugar enquanto %s estiver ao lado dele." % [alvo.nome, u.nome]
	return ""


## Agarrado: preso enquanto quem agarrou estiver vivo e ao lado.
func agarrado(u: Unidade) -> bool:
	var ag: Dictionary = u.efeitos.get("agarrado", {})
	if ag.is_empty():
		return false
	var por := unidade(ag.get("por", ""))
	if por == null or not por.viva() or not Grade.adjacentes(por.pos, u.pos):
		u.efeitos.erase("agarrado")
		return false
	return true


## O inimigo agarrado gasta a ação Padrão tentando escapar: Força dele contra Luta + Força do herói.
func _ia_escapar(u: Unidade) -> bool:
	if not agarrado(u) or u.acoes_padrao <= 0:
		return false
	var h := unidade(u.efeitos["agarrado"]["por"])
	u.acoes_padrao -= 1
	var forca_m := valor_resistido(u, "forca")
	var luta_h := _teste_automatico(h, valor_componente(h, "Luta") + valor_componente(h, "forca"))
	if forca_m > luta_h:
		u.efeitos.erase("agarrado")
		_log("%s se solta de %s (%d contra %d)." % [u.nome, h.nome, forca_m, luta_h])
	else:
		_log("%s tenta se soltar de %s, mas não consegue (%d contra %d)." % [u.nome, h.nome, forca_m, luta_h])
	return true


## Raciocínio 3: depois de Planejar, reordena as cartas vistas ("ordem" = do topo para baixo).
func heroi_reordenar_topo(ordem: Array) -> bool:
	var u := ativa()
	if u == null or not u.efeitos.has("planejou"):
		return false
	var vistas: Array = u.efeitos["planejou"]["cartas"]
	var n := vistas.size()
	var atual := u.baralho.baralho.slice(-n)
	atual.reverse()
	var a := atual.duplicate()
	var o := ordem.duplicate()
	a.sort()
	o.sort()
	if a != o:
		return false
	for i in n:
		u.baralho.baralho[u.baralho.baralho.size() - 1 - i] = ordem[i]
	u.efeitos["planejou"]["cartas"] = ordem.duplicate()
	_log("%s reordena o topo do baralho." % u.nome)
	return true


## Raciocínio 5: põe uma carta da mão no topo do baralho (depois de Planejar).
func heroi_por_no_topo(carta: int) -> bool:
	var u := ativa()
	if u == null or not u.efeitos.has("topo_da_mao") or not u.baralho.tirar_da_mao(carta):
		return false
	u.baralho.baralho.append(carta)
	u.efeitos.erase("topo_da_mao")
	_log("%s põe uma carta da mão no topo do baralho." % u.nome)
	return true


## Sabedoria 5: mulligan uma vez, no começo da cena (antes de agir).
func pode_mulligan(u: Unidade) -> bool:
	return vez_do_heroi() and ativa() == u and u.sabedoria >= 5 and not u.efeitos.has("mulligan") and not u.moveu_no_turno \
		and u.acoes_padrao == u.padrao_por_turno and rodada == 1


func heroi_mulligan() -> bool:
	var u := ativa()
	if not pode_mulligan(u):
		return false
	u.efeitos["mulligan"] = {}
	var n := u.baralho.mao.size()
	for c in u.baralho.mao:
		u.baralho.baralho.append(c)
	u.baralho.mao.clear()
	u.baralho.embaralhar()
	u.baralho.comprar_para_mao(n)
	_log("Sabedoria 5: %s devolve a mão, embaralha e compra %d cartas." % [u.nome, n])
	return true


## Espírito 3: Comandar (ação Padrão) — um aliado à vista a alcance curto compra 1 carta (2 com Espírito 5).
func alvos_de_comandar(u: Unidade) -> Array:
	if u.espirito < 3:
		return []
	return herois_ativos().filter(func(h): return h != u and Grade.distancia(h.pos, u.pos) <= 4 and grade.linha_de_visao(u.pos, h.pos))


func heroi_comandar(alvo: Unidade) -> bool:
	var u := ativa()
	if not vez_do_heroi() or u.acoes_padrao <= 0 or u.efeitos.has("confuso") or not alvo in alvos_de_comandar(u):
		return false
	u.acoes_padrao -= 1
	_agiu(u)
	var n := 2 if u.espirito >= 5 else 1
	alvo.baralho.comprar_para_mao(n)
	_log("%s comanda %s, que compra %d carta(s)." % [u.nome, alvo.nome, n])
	_verificar_queda_heroi_sem_turno(alvo)
	return true


## Diplomacia: Orientar (ação livre) — um aliado à vista a alcance curto ganha 1 ficha de Foco.
## Usos por cena = Diplomacia.
func alvos_de_orientar(u: Unidade) -> Array:
	if int(u.efeitos.get("orientar", {}).get("usos", 0)) >= u.atributo("diplomacia"):
		return []
	return herois_ativos().filter(func(h): return h != u and Grade.distancia(h.pos, u.pos) <= 4 and grade.linha_de_visao(u.pos, h.pos))


func heroi_orientar(alvo: Unidade) -> bool:
	var u := ativa()
	if not vez_do_heroi() or u.efeitos.has("confuso") or not alvo in alvos_de_orientar(u):
		return false
	var usos := int(u.efeitos.get("orientar", {}).get("usos", 0)) + 1
	u.efeitos["orientar"] = {"usos": usos}
	alvo.dar_ficha("Foco")
	_log("%s orienta %s: +1 ficha de Foco (%d de %d nesta cena)." % [u.nome, alvo.nome, usos, u.atributo("diplomacia")])
	return true


func heroi_usar_item(item: String) -> bool:
	var u := ativa()
	if not vez_do_heroi() or u.acoes_padrao <= 0 or not item in u.consumiveis or u.efeitos.has("confuso"):
		return false
	match item:
		"pocao_de_cura_pequena":
			if u.baralho.descarte.is_empty():
				return false
			_curar(u, 5, "bebe a Poção de Cura Pequena")
		"frutas_silvestres":
			_curar(u, 2, "come as frutas")
			_tirar_fadiga(u, 1)
		"pocao_de_mana_pequena":
			var tirada := _tirar_fadiga(u, 3)
			_log("%s bebe a Poção de Mana Pequena: −%d de fadiga." % [u.nome, tirada])
		"veneno_acido":
			u.efeitos["veneno_acido"] = {"ate": "proximo_ataque"}
			_log("%s aplica Veneno Ácido na arma: o próximo ataque causa +2 que ignora resistência." % u.nome)
		"kit_medico":
			var alvos := alvos_de_tratar(u)
			var alvo: Unidade = u
			if not alvos.is_empty() and not u in alvos:
				alvo = alvos[0]
			var n := alvo.tirar_fichas("Sangramento")
			_log("%s usa o Kit Médico em %s: %d ficha(s) de Sangramento removida(s)." % [u.nome, alvo.nome, n])
			_curar(alvo, 2, "é tratado com o Kit Médico")
		"antidoto":
			var tiradas := 0
			for c in u.cartas:
				while c.tirar_ficha("Veneno"):
					tiradas += 1
			var fad := _tirar_fadiga(u, 1)
			_log("%s toma o Antídoto: %d ficha(s) de Veneno removida(s), −%d de fadiga." % [u.nome, tiradas, fad])
		_:
			return false
	u.acoes_padrao -= 1
	_agiu(u)
	u.consumiveis.erase(item)
	u.gastos.append(item)
	if u.ativo("mestre-das-cavernas"):
		u.dar_ficha("Preparo")
	return true


## Fim do turno. "indice_fadiga": carta de onde sai 1 de fadiga (-1 = escolha automática).
## Encerrar o turno. "escolhas" vem da tela de fim do turno (0.20):
## {"fadiga": [índices de carta, um por ponto], "respirar": [índices], "opcionais": [ids]}.
## Um número sozinho = a carta que perde 1 de fadiga (como antes).
func encerrar_turno(escolhas: Variant = -1) -> bool:
	if not vez_do_heroi():
		return false
	var u := ativa()
	var esc: Dictionary = escolhas if escolhas is Dictionary else ({"fadiga": [int(escolhas)]} if int(escolhas) >= 0 else {})
	_fim_de_turno_heroi(u, esc)
	_tut("encerrou")
	_log("%s encerra o turno." % u.nome)
	_proximo_turno()
	return true


## O que o jogador decide ao passar o turno (0.20): de que cartas sai a fadiga (1 ponto,
## 2 com Fôlego de Viajante ou o crítico do Matador de Gigante), Respirar Fundo e os efeitos
## opcionais de fim de turno (Bênção Persistente).
func opcoes_fim_de_turno(u: Unidade) -> Dictionary:
	var pontos := 1 + (1 if fadiga_dupla else 0) + (1 if u.ativo("folego-de-viajante") and u.so_moveu else 0)
	var opcionais := []
	var bp = u.carta_com("bencao-persistente")
	if bp != null and bp.pode_pagar(1):
		opcionais.append({"id": "bencao-persistente", "texto": "Bênção Persistente: põe 1 de fadiga nela; você e cada aliado a até 4 quadrados exilam 1 carta do descarte e curam 1."})
	var dona = u.carta_com("respirar-fundo")
	return {"pontos": pontos, "cartas": cartas_com_fadiga(u), "respirar": int(u.recuperar_fadiga_no_fim),
		"cartas_respirar": cartas_com_fadiga(u).filter(func(i): return u.cartas[i] != dona), "opcionais": opcionais}


## Precisa da tela? (há escolha de verdade a fazer)
func fim_de_turno_tem_escolha(u: Unidade) -> bool:
	var op := opcoes_fim_de_turno(u)
	return op["cartas"].size() >= 2 or not op["opcionais"].is_empty() or (op["respirar"] > 0 and op["cartas_respirar"].size() >= 2)


func cartas_com_fadiga(u: Unidade) -> Array:
	var lista := []
	for i in u.cartas.size():
		if u.cartas[i].fadiga > 0:
			lista.append(i)
	return lista


# --- Cartas de habilidade ---------------------------------------------------

## Situação de cada carta do herói: o que dá para fazer com ela agora.
func opcoes_cartas(u: Unidade) -> Array:
	var lista := []
	for i in u.cartas.size():
		var c = u.cartas[i]
		var info := _info_lado(c)
		var motivo := ""
		if not vez_do_heroi() or ativa() != u:
			motivo = "não é a sua vez"
		elif info["uso"] != "ativada":
			motivo = {"passiva": "passiva", "reacao": "reação (o jogo oferece na hora)", "na_mesa": "usada durante um teste",
				"fim_turno": "no fim do turno (ao passar)", "arma": "arma",
				"ao_virar": "dispara ao virar", "sem_programa": "ainda não programada", "fora": "sem efeito na batalha"}.get(info["uso"], "")
		elif not info.has("opcoes"):
			motivo = _motivo_sem_usar(u, c, info)
		var pode_virar: bool = vez_do_heroi() and ativa() == u and c.lados.size() > 1 \
			and (u.acoes_padrao > 0 or c.tem_ficha("Preparo"))
		if c.tipo == "arma":
			pode_virar = vez_do_heroi() and ativa() == u and motivo_troca(u) == ""
		var item := {"indice": i, "carta": c, "uso": info["uso"], "alvo": info.get("alvo", "nenhum"),
			"custo": _custo_fadiga(u, c), "acao": custo_do_lado(c).get("acao"),
			"pode": motivo == "", "motivo": motivo, "pode_virar": pode_virar}
		if info.has("opcoes") and info["uso"] == "ativada":
			item["opcoes"] = _opcoes_do_repertorio(u, c, motivo)
			item["pode"] = item["opcoes"].any(func(o): return o["pode"])
		lista.append(item)
	return lista


## Cada opção do repertório: custo, ação, alvo e se dá para usar agora.
func _opcoes_do_repertorio(u: Unidade, c, motivo_da_carta: String) -> Array:
	var antes: String = c.opcao
	var lista := []
	for op in _registro_do_lado(c)["opcoes"]:
		c.opcao = op["id"]
		var info := _info_lado(c)
		var motivo := motivo_da_carta if motivo_da_carta != "" else _motivo_sem_usar(u, c, info)
		lista.append({"opcao": op["id"], "nome": op["nome"], "custo": _custo_fadiga(u, c), "acao": custo_do_lado(c).get("acao"),
			"alvo": info.get("alvo", "nenhum"), "pode": motivo == "", "motivo": motivo})
	c.opcao = antes
	return lista


## Números calculados mostrados na própria carta (0.20), ex.: Avalanche.
func nota_da_carta(u: Unidade, c) -> String:
	match c.slug():
		"avalanche":
			return "Agora: +%d de dano (2 × resistência %d da armadura)." % [2 * u.resistencia_armadura(), u.resistencia_armadura()]
		"contragolpe-de-aco":
			return "Agora: +%d de dano (resistência da armadura)." % u.resistencia_armadura()
	return ""


func _registro_do_lado(c) -> Dictionary:
	if c.tipo == "arma":
		return {"uso": "arma"}
	var s: String = c.slug()
	if c.tipo == "heroi":
		if not Efeitos.HEROIS.has(s):
			return {"uso": "sem_programa"}
		return Classes.ATIVADAS_DE_HEROI.get(s, Origens.ATIVADAS_DE_HEROI.get(s, {"uso": "passiva"}))
	if Extras.LADOS.has(s):
		return Extras.LADOS[s]
	return Efeitos.LADOS.get(s, {"uso": "sem_programa"})


func _info_lado(c) -> Dictionary:
	var info: Dictionary = _registro_do_lado(c)
	if info.has("opcoes"):
		# Repertório: a opção escolhida (ou a primeira) completa o registro da carta.
		var op: Dictionary = info["opcoes"][0]
		for o in info["opcoes"]:
			if o["id"] == c.opcao:
				op = o
		var junto := info.duplicate()
		junto.merge(op, true)
		junto["opcao"] = op["id"]
		return junto
	return info


## Custo do lado ativo: o registro em core/efeitos.gd pode corrigir o da planilha
## (repertórios, onde o custo está no texto de cada opção).
func custo_do_lado(c) -> Dictionary:
	var info := _info_lado(c)
	if info.has("custo"):
		return info["custo"]
	return c.lado_ativo().get("custo", {})


func _custo_fadiga(u: Unidade, c) -> int:
	var custo := int(custo_do_lado(c).get("fadiga", 0))
	var info := _info_lado(c)
	# Foco Mortal (Lucas, 0.20): só as habilidades da própria ARMA (carta de arma) custam 1
	# a menos, e nunca menos que 1. As armas comuns ainda não têm habilidades ativadas.
	if u.ativo("foco-mortal") and c.tipo == "arma" and custo > 1:
		custo -= 1
	if info.get("magia", false):
		if u.ativo("conjuracao-perfeita") and not u.efeitos.has("perfeita_usada"):
			return 0
		if u.ativo("conjuracao-economica") and not u.efeitos.has("economica_usada"):
			custo = maxi(custo - 1, 0)
	return custo


func _motivo_sem_usar(u: Unidade, c, info: Dictionary) -> String:
	if u.efeitos.has("confuso"):
		return "confuso: só pode ir atrás do alvo e atacá-lo"
	if info.has("motivo_fixo"):
		return info["motivo_fixo"]
	if info.has("motivo_se") and u.efeitos.has(info["motivo_se"]):
		return "já ativo nesta cena"
	if info.get("precisa_aliado", false):
		return "precisa de aliados"
	if not pode_pagar_fadiga(u, c, _custo_fadiga(u, c)):
		return "fadiga cheia (vire a carta ou espere)"
	var acao = custo_do_lado(c).get("acao")
	if acao == "padrao" and u.acoes_padrao <= 0:
		return "sem ação padrão"
	if acao == "movimento" and (preso(u) or (u.acoes_mov <= 0 and u.acoes_padrao <= 0)):
		return "sem ação de movimento" if not preso(u) else "imobilizado"
	var s: String = c.slug()
	if s == "foco-mortal" and not c.tem_ficha("Foco"):
		return "sem ficha de Foco"
	if s == "segundo-folego" and u.baralho.descarte.is_empty():
		return "descarte vazio"
	if s == "incansavel" and u.baralho.descarte.is_empty():
		return "descarte vazio"
	if s == "respirar-fundo" and u.recuperar_fadiga_no_fim > 0:
		return "já ativada neste turno"
	for f in info.get("exige_fichas", {}):
		if u.fichas_total(f) < int(info["exige_fichas"][f]):
			return "precisa de %d ficha(s) de %s" % [int(info["exige_fichas"][f]), f]
	var tipo_alvo := str(info.get("alvo", ""))
	if tipo_alvo != "nenhum" and tipo_alvo != "" and tipo_alvo != "area" and alvos_de_habilidade(u, c).is_empty():
		return "nenhum inimigo ao alcance" if tipo_alvo.begins_with("inimigo") else "nenhum aliado ao alcance"
	var m_c := Classes.motivo_extra(self, u, c)
	return m_c if m_c != "" else Extras.motivo(self, u, c)


## Inimigos que a habilidade pode atingir (para destacar no mapa).
func alvos_de_habilidade(u: Unidade, c) -> Array:
	var info := _info_lado(c)
	var lista := []
	for o in oponentes(u):
		match info.get("alvo", "nenhum"):
			"inimigo_corpo":
				if motivo_alcance(u, o, u.pos) == "" and not u.a_distancia:
					lista.append(o)
			"inimigo_salto":
				if not u.a_distancia and _casa_para_atacar(u, o, 1) != Vector2i(-99, -99):
					lista.append(o)
			"inimigo_investida":
				if _casa_para_atacar(u, o, 3) != Vector2i(-99, -99):
					lista.append(o)
			"inimigo_arma":
				if motivo_alcance(u, o, u.pos) == "":
					lista.append(o)
			"inimigo_distancia":
				if u.a_distancia and motivo_alcance(u, o, u.pos) == "":
					lista.append(o)
			"inimigo_magico":
				if Grade.distancia(u.pos, o.pos) <= int(info.get("alcance", 4)) + (4 if u.efeitos.has("tecer") and info.get("magia", false) else 0) and grade.linha_de_visao(u.pos, o.pos) and ve_de(u, u.pos, o.pos):
					lista.append(o)
			"inimigo_profano":
				if o.categoria in ["morto-vivo", "demonio"] and Grade.distancia(u.pos, o.pos) <= int(info.get("alcance", 1)) and ve_de(u, u.pos, o.pos):
					lista.append(o)
			"inimigo_corpo_qualquer":
				if Grade.distancia(u.pos, o.pos) <= 1:
					lista.append(o)
			"inimigo_visivel":
				if Grade.distancia(u.pos, o.pos) <= 12 and grade.linha_de_visao(u.pos, o.pos) and ve_de(u, u.pos, o.pos):
					lista.append(o)
	if info.get("exige_marca", false):
		lista = lista.filter(func(o): return o.fichas_total("Marcado") > 0)
	if info.get("exige_marca_ou_metade", false):
		lista = lista.filter(func(o): return o.fichas_total("Marcado") > 0 or o.vida * 2 < o.vida_max)
	var tipo: String = info.get("alvo", "nenhum")
	if tipo == "qualquer_adjacente":
		lista = unidades.filter(func(o): return o.viva() and o != u and Grade.adjacentes(o.pos, u.pos))
	if tipo == "qualquer_medio":
		lista = unidades.filter(func(o): return o.viva() and o != u and Grade.distancia(o.pos, u.pos) <= 8 \
			and grade.linha_de_visao(u.pos, o.pos) and ve_de(u, u.pos, o.pos))
	if tipo in ["aliado", "aliado_caido"]:
		for h in herois():
			if Grade.distancia(u.pos, h.pos) > int(info.get("alcance", 1)):
				continue
			if h == u and info.get("sem_si", false):
				continue
			if tipo == "aliado" and h.viva():
				lista.append(h)
			elif tipo == "aliado_caido" and h != u and h.baralho.estado == Baralho.Estado.INCONSCIENTE:
				lista.append(h)
	return lista


## Casa a até "passos" de distância de onde dá para atacar "alvo" (a atual vale).
## Casas de onde dá para atacar "alvo" andando até "passos" (inclui ficar onde está).
## A tela deixa o jogador escolher (Ombro de Ferro: mesmo com inimigo ao lado, 0.20).
func casas_para_atacar(u: Unidade, alvo: Unidade, passos: int) -> Array:
	var mapa := _sem_passagem(grade.alcance(u.pos, passos, _ocupadas(u), _perigos(u), modo_de_andar(u)))
	var lista := []
	for p in mapa:
		if motivo_alcance(u, alvo, p) == "":
			lista.append(p)
	return lista


## Passos de andar das cartas que andam e atacam (para a tela oferecer as casas).
func passos_antes_do_ataque(c) -> int:
	match c.slug():
		"ombro-de-ferro":
			return 1
	return 3 if str(_info_lado(c).get("alvo", "")) == "inimigo_investida" else 0


var destino_escolhido := Vector2i(-99, -99)


func _destino_para(u: Unidade, alvo: Unidade, passos: int) -> Vector2i:
	var d := destino_escolhido
	destino_escolhido = Vector2i(-99, -99)
	if d != Vector2i(-99, -99) and d in casas_para_atacar(u, alvo, passos):
		return d
	return _casa_para_atacar(u, alvo, passos)


func _casa_para_atacar(u: Unidade, alvo: Unidade, passos: int) -> Vector2i:
	if motivo_alcance(u, alvo, u.pos) == "":
		return u.pos
	var mapa := _sem_passagem(grade.alcance(u.pos, passos, _ocupadas(u), _perigos(u), modo_de_andar(u)))
	var melhor := Vector2i(-99, -99)
	var melhor_custo := 99
	for p in mapa:
		if motivo_alcance(u, alvo, p) == "" and mapa[p]["custo"] < melhor_custo:
			melhor = p
			melhor_custo = mapa[p]["custo"]
	return melhor


func heroi_usar_carta(indice: int, alvo: Unidade = null, opcao := "", destino := Vector2i(-99, -99)) -> bool:
	destino_escolhido = destino
	var u := ativa()
	if not vez_do_heroi() or indice < 0 or indice >= u.cartas.size():
		return false
	var c = u.cartas[indice]
	if opcao != "":
		c.opcao = opcao
	var info := _info_lado(c)
	if info.has("opcoes"):
		c.opcao = info["opcao"]
	if info["uso"] != "ativada" or _motivo_sem_usar(u, c, info) != "":
		return false
	var tipo_alvo: String = info.get("alvo", "nenhum")
	if tipo_alvo == "area":
		if area_atual.is_empty():
			return false
	elif tipo_alvo != "nenhum" and (alvo == null or not alvo in alvos_de_habilidade(u, c)):
		return false
	# Paga: fadiga e ação.
	var custo := _custo_fadiga(u, c)
	if info.get("magia", false):
		if u.ativo("conjuracao-perfeita") and not u.efeitos.has("perfeita_usada"):
			u.efeitos["perfeita_usada"] = {"ate": "inicio_turno"}
		elif u.ativo("conjuracao-economica"):
			u.efeitos["economica_usada"] = {"ate": "inicio_turno"}
	pagar_fadiga(u, c, custo)
	var acao = custo_do_lado(c).get("acao")
	if acao == "padrao":
		u.acoes_padrao -= 1
	elif acao == "movimento":
		if u.acoes_mov > 0:
			u.acoes_mov -= 1
		else:
			u.acoes_padrao -= 1
	_log("%s usa %s." % [u.nome, c.nome() + (" (%s)" % info["nome"] if info.has("opcoes") else "")])
	_tut("carta")
	if acao != "movimento":
		_agiu(u)
	match c.slug():
		"peso-da-muralha":
			u.efeitos["peso_da_muralha"] = {"ate": "inicio_turno"}
		"contragolpe-de-aco":
			_novo_ataque(u, alvo, {"habilidade": c.nome(), "bonus_res_armadura": 1})
		"ombro-de-ferro":
			_andar_e_atacar(u, _destino_para(u, alvo, 1), alvo, {"habilidade": c.nome(), "imobilizar_se_dano": true})
		"avalanche":
			_novo_ataque(u, alvo, {"habilidade": c.nome(), "bonus_res_armadura": 2, "imobiliza_atacante": c})
		"marcha-militar":
			u.deslocamento += 2
		"romper-a-linha":
			u.deslocamento += _velocidade(u)
			u.ignora_impedimento = true
		"lanca-em-riste":
			var n := aliados_adjacentes(u, u.pos) + aliados_adjacentes(u, alvo.pos)
			_novo_ataque(u, alvo, {"habilidade": c.nome(), "bonus": n})
		"perfurar-e-recuar":
			_novo_ataque(u, alvo, {"habilidade": c.nome(), "depois_mover": 1})
		"respirar-fundo":
			u.recuperar_fadiga_no_fim += 1
		"firmar-os-pes":
			u.efeitos["firmar_os_pes"] = {"ate": "inicio_turno"}
		"reposicionar":
			u.deslocamento += 1
		"segundo-folego":
			u.baralho.baralho.insert(0, u.baralho.descarte.pop_back())
			_log("Uma carta volta do descarte para o fundo do baralho.")
		"sangue-fervente":
			u.acoes_padrao += 1
			var c_topo := u.baralho.puxar_topo()
			if c_topo >= 0:
				u.baralho.exilio.append(c_topo)
			_log("Ganha uma ação padrão; a carta do topo vai para o exílio.")
			_verificar_queda_heroi(u)
		"ancora":
			u.efeitos["ancora"] = {"ate": "inicio_turno"}
		"foco-mortal":
			c.tirar_ficha("Foco")
			u.efeitos["ignora_reducao"] = {"ate": "proximo_ataque"}
			_log("O próximo ataque ignora qualquer redução de dano.")
		"incansavel":
			_curar(u, u.constituicao, "recupera o fôlego (Incansável)")
			for ficha in ["Ferimento", "Sangramento", "Atordoamento", "Imobilizar"]:
				var removida := false
				for outra in u.cartas:
					if outra.tirar_ficha(ficha):
						removida = true
						break
				if removida:
					_log("Remove uma ficha de %s." % ficha)
					break
		"tomar-a-posicao":
			_andar_e_atacar(u, _destino_para(u, alvo, 3), alvo, {"habilidade": c.nome()})
		_:
			if info.get("magia", false):
				conjurando = u
			tipo_da_magia_atual = _tipo_da_carta(c)
			if info.get("magia", false):
				u.efeitos.erase("tecer")
			Classes.usar(self, u, c, alvo)
			tipo_da_magia_atual = ""
			conjurando = null
	return true


## Virar uma carta: custa 1 ação Padrão (ou uma ficha de Preparo) e apaga as
## fichas voláteis dela. Dispara efeitos "ao virar".
## Virar: "modo" = "preparo" (gasta 1 ficha de Preparo), "acao" (gasta a ação Padrão)
## ou "" (usa Preparo se tiver, senão a ação). A tela mostra os dois botões.
func heroi_virar(indice: int, modo := "") -> bool:
	var u := ativa()
	if not vez_do_heroi() or indice < 0 or indice >= u.cartas.size():
		return false
	var c = u.cartas[indice]
	if c.tipo == "arma":
		return heroi_trocar_arma()   # virar a carta de arma = trocar de arma (0.21)
	if c.lados.size() < 2:
		return false
	# Lucas (0.20): a ficha de Preparo só vira a carta em que está.
	var com_preparo: bool = c.tem_ficha("Preparo") if modo != "acao" else false
	if modo == "preparo" and not com_preparo:
		return false
	if not com_preparo and u.acoes_padrao <= 0:
		return false
	if com_preparo:
		c.tirar_ficha("Preparo")
		_log("%s gasta uma ficha de Preparo para virar %s." % [u.nome, c.nome()])
	else:
		u.acoes_padrao -= 1
		_agiu(u)
		_log("%s vira %s." % [u.nome, c.nome()])
	_virar(u, c)
	return true


func _virar(u: Unidade, c) -> void:
	var feridas: int = int(c.fichas.get("Ferimento", 0))
	var tinha_imob: bool = c.tem_ficha("Imobilizar")
	var tinha_fogo: bool = c.tem_ficha("Fogo")
	c.virar()
	_atualizar_limites(u)
	Origens.ao_virar(self, u, c)
	Extras.ao_virar(self, u, c)
	if tinha_fogo:
		_log("Virar a carta apaga o fogo dela.")
	if tinha_imob:
		_log("As fichas de Imobilizar saem com a virada.")
	if feridas > 0:
		_dano_direto(u, feridas, "Ferimento (ao virar a carta)")
	if u.fichas_total("Confusão") == 0:
		u.efeitos.erase("confuso")
	_log("Lado ativo agora: %s." % c.nome())
	match c.slug():
		"segundo-vento":
			var ops := [["curar", "Curar %d (Constituição)" % u.constituicao]]
			for i in u.cartas.size():
				if u.cartas[i] != c and u.cartas[i].fadiga > 0:
					ops.append([str(i), "Tirar %d de fadiga de %s" % [u.espirito, u.cartas[i].nome()]])
			if ops.size() == 1 or not perguntar_escolhas:
				_segundo_vento(u, "curar")
			else:
				perguntar("segundo_vento", "Segundo Vento: curar ou tirar fadiga de outra carta?", ops, {"quem": u.id})
		"instinto-defensivo":
			c.dar_ficha("Bloqueio")
			_log("Instinto Defensivo: 1 ficha de Bloqueio (reduz à metade o dano de um ataque).")


func _tem_preparo(u: Unidade) -> bool:
	for c in u.cartas:
		if c.tem_ficha("Preparo"):
			return true
	return false


var foco_marcial_visto := -1   # carta do topo vista pelo Foco Marcial (para mandar ao fundo)


## Foco Marcial em dois passos: olhar (paga 1 de fadiga) e, se estiver num
## teste, decidir se a carta do topo vai para o fundo.
func foco_marcial_olhar(u: Unidade) -> int:
	if not pode_foco_marcial(u):
		return -1
	u.carta_com("foco-marcial").pagar(1)
	foco_marcial_visto = u.baralho.baralho[-1]
	_log("Foco Marcial: %s olha o topo do baralho." % u.nome)
	return foco_marcial_visto


func foco_marcial_fundo(u: Unidade) -> bool:
	if foco_marcial_visto < 0 or teste_do_heroi() == null or u.baralho.baralho.is_empty() or u.baralho.baralho[-1] != foco_marcial_visto:
		foco_marcial_visto = -1
		return false
	u.baralho.baralho.pop_back()
	u.baralho.baralho.insert(0, foco_marcial_visto)
	foco_marcial_visto = -1
	_log("Foco Marcial: a carta do topo vai para o fundo do baralho.")
	return true


## Foco Marcial (1 de fadiga): olha o topo do baralho; durante ataque ou defesa,
## pode mandar a carta do topo para o fundo.
func pode_foco_marcial(u: Unidade) -> bool:
	if u == null:
		return false
	var c = u.carta_com("foco-marcial")
	return c != null and c.pode_pagar(1) and not u.baralho.baralho.is_empty()


func heroi_foco_marcial(u: Unidade, mandar_para_fundo: bool) -> bool:
	if not pode_foco_marcial(u):
		return false
	var c = u.carta_com("foco-marcial")
	c.pagar(1)
	var topo: int = u.baralho.baralho[-1]
	if mandar_para_fundo and teste_do_heroi() != null:
		u.baralho.baralho.pop_back()
		u.baralho.baralho.insert(0, topo)
		_log("Foco Marcial: %s olha o topo (%s) e manda para o fundo." % [u.nome, Carta.nome(topo)])
	else:
		_log("Foco Marcial: %s olha o topo do baralho (%s)." % [u.nome, Carta.nome(topo)])
	return true


## Cartas "como parte de um ataque" (0.14): usadas na mesa, durante o ataque do herói,
## e somam efeitos no mesmo ataque. Devolve [{"slug", "opcao", "texto"}].
func cartas_durante_ataque() -> Array:
	var lista := []
	if fase != Fase.HEROI_ATACANDO or atacante == null or not atacante.eh_heroi() or teste_ataque.encerrado:
		return lista
	var u := atacante
	var usadas: Array = ctx.get("cartas_usadas", [])
	var distancia: bool = u.a_distancia and not ctx.get("magico", false)
	var c = u.carta_com("ataque-furtivo")
	if c != null and u.fichas_total("Sombra") > 0 and not ctx.get("magico", false):
		lista.append({"slug": "ataque-furtivo", "opcao": "", "texto": "Ataque Furtivo: descartar 1 Sombra (+%d de dano)" % u.dano})
	# Ficha de Mira (Lucas, 0.20): o efeito é da própria ficha — descartar 1 dá −1 no limite
	# do defensor. O Tiro Certeiro (ataque à distância) soma +2 de dano por ficha descartada.
	if u.fichas_total("Mira") > 0 and not teste_defesa.encerrado:
		var tiro: bool = u.carta_com("tiro-certeiro") != null and distancia
		lista.append({"slug": "mira", "opcao": "", "texto": "Descartar 1 Mira: −1 no limite do defensor%s" % (" e +2 de dano (Tiro Certeiro)" if tiro else "")})
	c = u.carta_com("flecha-pesada")
	if c != null and not "flecha-pesada" in usadas and c.pode_pagar(_custo_fadiga(u, c)) and not ctx.get("magico", false) \
			and (defensor.imobilizado() or defensor.fichas_total("Ferimento") > 0):
		lista.append({"slug": "flecha-pesada", "opcao": "", "texto": "Flecha Pesada (%d fadiga): dano da arma ×3, ignora resistência" % _custo_fadiga(u, c)})
	c = u.carta_com("quebrar-a-fenda")
	if c != null and not "quebrar-a-fenda" in usadas and c.pode_pagar(_custo_fadiga(u, c)):
		lista.append({"slug": "quebrar-a-fenda", "opcao": "Imobilizar", "texto": "Quebrar a Fenda (%d fadiga): 1 Imobilizar" % _custo_fadiga(u, c)})
		lista.append({"slug": "quebrar-a-fenda", "opcao": "Ferimento", "texto": "Quebrar a Fenda (%d fadiga): 1 Ferimento" % _custo_fadiga(u, c)})
	return lista


func heroi_durante_ataque(slug: String, opcao := "") -> bool:
	if not cartas_durante_ataque().any(func(o): return o["slug"] == slug and o["opcao"] == opcao):
		return false
	var u := atacante
	var c = u.carta_com(slug)
	if not ctx.has("cartas_usadas"):
		ctx["cartas_usadas"] = []
	if not ctx.has("bonus_extra"):
		ctx["bonus_extra"] = []
	match slug:
		"ataque-furtivo":
			u.tirar_fichas("Sombra", 1)
			_gastou_sombra(u)
			ctx["bonus_extra"].append(["Ataque Furtivo (1 Sombra)", u.dano])
			_log("Ataque Furtivo: %s descarta 1 Sombra (+%d de dano se acertar)." % [u.nome, u.dano])
		"mira":
			u.tirar_fichas("Mira", 1)
			teste_defesa.ajustar_limite(-1)
			_log("%s descarta 1 Mira: o defensor tem −1 no limite." % u.nome)
			if u.carta_com("tiro-certeiro") != null and u.a_distancia and not ctx.get("magico", false):
				ctx["bonus_extra"].append(["Tiro Certeiro (1 Mira)", 2])
				_log("Tiro Certeiro: +2 de dano se acertar.")
		"flecha-pesada":
			c.pagar(_custo_fadiga(u, c))
			ctx["multiplicar_arma"] = 3
			ctx["ignora_resistencia"] = true
			_log("Flecha Pesada: o dano da arma triplica e ignora resistência.")
		"quebrar-a-fenda":
			c.pagar(_custo_fadiga(u, c))
			defensor.dar_ficha(opcao)
			_log("Quebrar a Fenda: %s recebe 1 %s." % [defensor.nome, opcao])
	ctx["cartas_usadas"].append(slug)
	return true


## Ajustes opcionais que o herói pode somar no teste atual (contam para estourar).
func ajustes_disponiveis() -> Array:
	var t := teste_do_heroi()
	var u := heroi_dono_do_teste()
	var lista := []
	if t == null or u == null or t.encerrado:
		return lista
	if u.sabedoria >= 3 and not "Sabedoria +1" in t.ajustes_usados and not "Sabedoria −1" in t.ajustes_usados:
		lista.append({"nome": "Sabedoria +1", "valor": 1})
		lista.append({"nome": "Sabedoria −1", "valor": -1})
	if t == teste_ataque:
		if u.arma.get("tamanho", "") == "pequeno":
			lista.append({"nome": "%s +1" % u.arma["nome"], "valor": 1})
	elif t == teste_defesa:
		if u.efeitos.has("firmar_os_pes"):
			lista.append({"nome": "Firmar os Pés +2", "valor": 2})
	# Palavra de Ânimo: um aliado a até 3 quadrados soma +1 (1 de fadiga dele).
	for h in herois_ativos():
		var c = h.carta_com("palavra-de-animo")
		if h != u and c != null and c.pode_pagar(1) and Grade.distancia(h.pos, u.pos) <= 3:
			lista.append({"nome": "Palavra de Ânimo (%s) +1" % h.nome, "valor": 1, "pagador": h.id})
	return lista.filter(func(a): return not a["nome"] in t.ajustes_usados)


func heroi_ajuste(nome_ajuste: String) -> bool:
	var t := teste_do_heroi()
	for a in ajustes_disponiveis():
		if a["nome"] == nome_ajuste:
			if t.aplicar_ajuste(nome_ajuste, a["valor"]):
				if a.has("pagador"):
					unidade(a["pagador"]).carta_com("palavra-de-animo").pagar(1)
				_log("%s soma %+d no teste (%s)." % [heroi_dono_do_teste().nome, a["valor"], nome_ajuste])
				_depois_do_lance_do_heroi(t)
				return true
	return false


## Armas arremessadas no chão: pos -> lista de {"dono", "arma"}.
var armas_no_chao := {}
## Desarmado (Lucas): só a diferença, mais a Força se ela for 3 ou mais.
const DESARMADO := {"nome": "Desarmado", "peso": "nenhum", "tamanho": "desarmado", "dano": 0, "tipo_dano": "Concussão", "forca_min": 0, "atributo": "forca"}


func _largar_arma(u: Unidade, onde: Vector2i) -> void:
	if not armas_no_chao.has(onde):
		armas_no_chao[onde] = []
	armas_no_chao[onde].append({"dono": u.id, "arma": u.arma.duplicate(true),
		"campos": {"dano": u.dano, "atributo_dano": u.atributo_dano, "a_distancia": u.a_distancia,
			"faixas_ideais": u.faixas_ideais.duplicate(), "alcance_corpo": u.alcance_corpo}})
	_log("%s fica no chão, no quadrado de quem foi atingido." % u.arma["nome"])
	u.arma = DESARMADO.duplicate()
	u.dano = 0
	u.atributo_dano = u.forca if u.forca >= 3 else 0
	u.a_distancia = false
	u.faixas_ideais = []
	u.alcance_corpo = 1
	u.efeitos["sem_arma"] = {}
	eventos.append({"tipo": "mapa"})


## Onde está a arma do herói (ou Vector2i(-99, -99)).
func arma_no_chao_de(u: Unidade) -> Vector2i:
	for p in armas_no_chao:
		for a in armas_no_chao[p]:
			if a["dono"] == u.id:
				return p
	return Vector2i(-99, -99)


## Pegar a arma do chão: 1 ação de movimento, no quadrado dela ou ao lado.
func heroi_pegar_arma() -> bool:
	var u := ativa()
	var p := arma_no_chao_de(u)
	if not vez_do_heroi() or p == Vector2i(-99, -99) or Grade.distancia(p, u.pos) > 1 or (u.acoes_mov <= 0 and u.acoes_padrao <= 0):
		return false
	if u.acoes_mov > 0:
		u.acoes_mov -= 1
	else:
		u.acoes_padrao -= 1
	u.deslocamento = 0
	for a in armas_no_chao[p]:
		if a["dono"] == u.id:
			u.arma = a["arma"]
			for campo in a["campos"]:
				u.set(campo, a["campos"][campo])
			armas_no_chao[p].erase(a)
			break
	if armas_no_chao[p].is_empty():
		armas_no_chao.erase(p)
	u.efeitos.erase("sem_arma")
	_log("%s pega %s do chão." % [u.nome, u.arma["nome"]])
	eventos.append({"tipo": "mapa"})
	return true


## Besta Pesada: Recarregar (ação Padrão) depois de cada tiro.
func heroi_recarregar() -> bool:
	var u := ativa()
	if not vez_do_heroi() or not u.efeitos.has("descarregada") or u.acoes_padrao <= 0:
		return false
	u.acoes_padrao -= 1
	u.efeitos.erase("descarregada")
	_log("%s recarrega %s." % [u.nome, u.arma["nome"]])
	return true


## Reações próprias dos inimigos quando são atacados (Lâmina Rápida e Tiro Rápido impedem).
## 0.22: reações "livre" (estilo Descent) não gastam a Reação; cada uma dispara uma vez por rodada.
func _reacao_do_inimigo(o: Unidade, atacante_h: Unidade) -> void:
	if not o.viva() or not o.alerta:
		return
	for i in o.reacoes.size():
		var r: Dictionary = o.reacoes[i]
		if r.get("gatilho", "ao_ser_atacado") != "ao_ser_atacado":
			continue
		if r.get("so_corpo_a_corpo", false) and Grade.distancia(o.pos, atacante_h.pos) > 1:
			continue
		if r.get("livre", false):
			if not _reacao_livre_disponivel(o, i):
				continue
		elif o.acoes_reacao <= 0:
			continue
		else:
			o.acoes_reacao -= 1
		_efeito_reacao_monstro(o, r, atacante_h)
		if not r.get("livre", false):
			return


func _reacao_livre_disponivel(o: Unidade, i: int) -> bool:
	var chave := "reagiu_%d" % i
	if o.efeitos.has(chave):
		return false
	o.efeitos[chave] = {"ate": "inicio_turno"}
	return true


## Reações de monstro que disparam depois de um ataque dele.
func _reacao_ao_atacar(o: Unidade, alvo: Unidade, acertou: bool) -> void:
	if o.eh_heroi() or not o.viva() or sem_reacoes_ate != "":
		return
	for i in o.reacoes.size():
		var r: Dictionary = o.reacoes[i]
		if r.get("gatilho", "") != "ao_atacar" or (r.get("so_acerto", false) and not acertou):
			continue
		if _reacao_livre_disponivel(o, i):
			_efeito_reacao_monstro(o, r, alvo)


## Reações de monstro ao cair (estilhaçar, lodo, remontar).
func _reacao_ao_morrer(o: Unidade) -> void:
	for i in o.reacoes.size():
		var r: Dictionary = o.reacoes[i]
		if r.get("gatilho", "") == "ao_morrer":
			_efeito_reacao_monstro(o, r, atacante if atacante != null and atacante != o else null)


func _efeito_reacao_monstro(o: Unidade, r: Dictionary, h: Unidade) -> void:
	var nome: String = r.get("nome", "Reação")
	# Voz do Exorcista (0.23): anula reações de mortos-vivos e demônios (Espírito contra Espírito).
	if o.categoria in ["morto-vivo", "demonio"]:
		for x in herois_ativos():
			var cv = x.carta_com("voz-do-exorcista")
			if cv != null and x.ativo("voz-do-exorcista") and cv.pode_pagar(1) and x.acoes_reacao > 0:
				var meu := _teste_automatico(x, x.espirito)
				var dele := valor_resistido(o, "espirito")
				cv.pagar(1)
				x.acoes_reacao -= 1
				if meu >= dele:
					_log("Voz do Exorcista: %s anula %s de %s (%d contra %d)." % [x.nome, nome, o.nome, meu, dele])
					return
				_log("Voz do Exorcista: %s tenta anular %s, mas falha (%d contra %d)." % [x.nome, nome, meu, dele])
				break
	match r.get("efeito", ""):
		"mover":
			if h == null:
				return
			_log("Reação de %s (%s): %s." % [o.nome, nome, r.get("texto", "se afasta")])
			_empurrar_sem_dano(o, h.pos, int(r.get("valor", 1)))
		"ficha_no_atacante":
			if h == null:
				return
			h.dar_ficha(r["ficha"], int(r.get("qtd", 1)))
			_log("Reação de %s: %s recebe %d ficha(s) de %s." % [o.nome, h.nome, int(r.get("qtd", 1)), r["ficha"]])
		"bonus_contra_atacante":
			if h == null:
				return
			o.efeitos["bonus_contra"] = {"id": h.id, "valor": int(r.get("valor", 2))}
			_log("Reação de %s (%s): o próximo ataque dele contra %s causa +%d." % [o.nome, nome, h.nome, int(r.get("valor", 2))])
		"investir":
			if h == null or preso(o):
				return
			var antes := o.pos
			_andar_na_direcao(o, h.pos, int(r.get("valor", 1)))
			var chegou := Grade.adjacentes(o.pos, h.pos)
			_log("Reação de %s (%s): avança%s%s." % [o.nome, nome, "" if o.pos != antes else " (não há espaço)",
				(" e chega ao lado de %s, que recebe 1 %s" % [h.nome, r.get("ficha", "")]) if chegou and r.has("ficha") else ""])
			if chegou and r.has("ficha"):
				h.dar_ficha(r["ficha"], int(r.get("qtd", 1)))
				fichas_de_inimigo(h, o)
			eventos.append({"tipo": "reacao_monstro", "id": o.id, "nome": nome})
		"inspirar":
			var raio := int(r.get("raio", 6))
			var aliados := inimigos_vivos().filter(func(x): return x != o and x.alerta and Grade.distancia(x.pos, o.pos) <= raio)
			if aliados.is_empty():
				return
			var a: Unidade = aliados[rng.randi_range(0, aliados.size() - 1)]
			var atual := int(a.efeitos.get("inspirado", {}).get("valor", 0))
			a.efeitos["inspirado"] = {"valor": atual + int(r.get("valor", 1)), "nome": nome}
			_log("Reação de %s (%s): %s causa +%d de dano no próximo ataque." % [o.nome, nome, nome_visto(a), int(r.get("valor", 1))])
			eventos.append({"tipo": "reacao_monstro", "id": o.id, "nome": nome})
			if unidade_visivel(a):
				eventos.append({"tipo": "reacao_monstro", "id": a.id, "nome": "+%d de dano" % int(r.get("valor", 1))})
		"chamar":
			if h == null:
				return
			var raio_c := int(r.get("raio", 8))
			var aliados_c := inimigos_vivos().filter(func(x): return x != o and Grade.distancia(x.pos, o.pos) <= raio_c and not preso(x) \
				and not Grade.adjacentes(x.pos, h.pos))
			if aliados_c.is_empty():
				return
			var c: Unidade = aliados_c[rng.randi_range(0, aliados_c.size() - 1)]
			c.alerta = true
			_andar_na_direcao(c, h.pos, int(r.get("valor", 2)))
			_log("Reação de %s (%s): %s corre na direção de %s." % [o.nome, nome, nome_visto(c), h.nome])
			eventos.append({"tipo": "reacao_monstro", "id": o.id, "nome": nome})
		"estilhacar":
			_log("%s (%s): os ossos estouram em lascas." % [o.nome, nome])
			for x in herois_ativos():
				if Grade.adjacentes(x.pos, o.pos):
					_dano_direto(x, int(r.get("valor", 1)), nome)
		"fichas_ao_lado":
			var atingidos := []
			for x in herois_ativos():
				if Grade.adjacentes(x.pos, o.pos):
					x.dar_ficha(r["ficha"], int(r.get("qtd", 1)))
					atingidos.append(x.nome)
			if not atingidos.is_empty():
				_log("%s (%s): %s recebe(m) 1 %s." % [o.nome, nome, ", ".join(PackedStringArray(atingidos)), r["ficha"]])
		"remontar":
			if o.efeitos.has("remontou"):
				return
			var tipos: Array = tipos_de_dano(atacante, ctx) if atacante != null and atacante != o else []
			for t in tipos:
				if t in r.get("impede", []):
					_log("%s: o golpe de %s quebra os ossos de vez." % [o.nome, t])
					return
			o.efeitos["remontou"] = {}
			o.efeitos["remontando"] = {}
			_log("%s (%s): os ossos tremem no chão... vão se juntar de novo na próxima rodada." % [o.nome, nome])


## Anda até "n" quadrados para perto de "destino" (movimento dado por reação, sem gastar ação).
func _andar_na_direcao(u: Unidade, destino: Vector2i, n: int) -> void:
	var mapa := _sem_passagem(grade.alcance(u.pos, n, _ocupadas(u), {}, modo_de_andar(u)))
	var melhor := u.pos
	for p in mapa:
		if Grade.distancia(p, destino) < Grade.distancia(melhor, destino):
			melhor = p
	if melhor == u.pos:
		return
	var caminho := Grade.caminho(grade.alcance(u.pos, n, _ocupadas(u), {}, modo_de_andar(u)), melhor)
	u.pos = melhor
	eventos.append({"tipo": "mover", "id": u.id, "caminho": caminho})


## Ossos teimosos: quem está "remontando" levanta no começo da rodada, com metade da vida.
func _remontar_mortos() -> void:
	for o in unidades:
		if o.eh_heroi() or o.viva() or not o.efeitos.has("remontando"):
			continue
		o.efeitos.erase("remontando")
		var casa: Vector2i = o.pos if na_posicao(o.pos) == null else _casa_livre_perto(o.pos)
		if casa == Vector2i(-1, -1):
			continue
		o.pos = casa
		o.vida = maxi(int(o.vida_max / 2), 1)
		o.alerta = true
		_log("%s se levanta de novo, com os ossos remendados (%d de vida)." % [o.nome, o.vida])
		eventos.append({"tipo": "reviver", "id": o.id})


func _empurrar_sem_dano(u: Unidade, origem: Vector2i, n: int) -> void:
	var d := u.pos - origem
	var dir := Vector2i(signi(d.x), signi(d.y))
	var caminho := []
	for i in n:
		var q := u.pos + dir
		if dir == Vector2i.ZERO or not grade.dentro(q) or grade.bloqueado(q) or na_posicao(q) != null:
			break
		u.pos = q
		caminho.append(q)
	if not caminho.is_empty():
		eventos.append({"tipo": "mover", "id": u.id, "caminho": caminho})


## Mentira 3: uma carta usada no ataque volta para o fundo do baralho. Se veio da
## mão, é ela; com Mentira 5, essa carta da mão volta para o topo.
func _mentira_devolve(u: Unidade, t: Teste21) -> void:
	var c := -1
	var topo := false
	if not t.da_mao.is_empty():
		c = t.da_mao[-1]
		topo = u.atributo("mentira") >= 5
	elif not t.cartas.is_empty():
		c = t.cartas[rng.randi_range(0, t.cartas.size() - 1)]
	if c < 0 or not c in u.baralho.descarte:
		return
	u.baralho.descarte.erase(c)
	if topo:
		u.baralho.baralho.append(c)
	else:
		u.baralho.baralho.insert(0, c)
	_log("Mentira %d: %s volta para o %s do baralho." % [u.atributo("mentira"), Carta.nome(c), "topo" if topo else "fundo"])


## Scry 1 (Escrituras de Maftoné): olha o topo e decide se manda para o fundo.
func comecar_scry(h: Unidade) -> void:
	if h.baralho.baralho.is_empty():
		return
	scry_de = h.id
	eventos.append({"tipo": "espiar", "id": h.id, "titulo": "Scry 1 (%s):\ntopo do baralho" % h.nome,
		"cartas": [h.baralho.baralho[-1]], "fundo": true})


func heroi_scry(mandar_para_fundo: bool) -> bool:
	var h := unidade(scry_de)
	scry_de = ""
	if h == null or h.baralho.baralho.is_empty():
		return false
	if mandar_para_fundo:
		h.baralho.baralho.insert(0, h.baralho.baralho.pop_back())
		_log("Scry: %s manda a carta do topo para o fundo." % h.nome)
	return true


## Destreza 5: depois de se defender com sucesso, o herói pode andar 1 quadrado.
func heroi_passo_de_defesa(destino: Vector2i) -> bool:
	if fase != Fase.RESOLVIDO or resultado.get("passo", "") == "":
		return false
	var u := unidade(resultado["passo"])
	if Grade.distancia(u.pos, destino) != 1 or not grade.dentro(destino) or grade.bloqueado(destino) or na_posicao(destino) != null:
		return false
	resultado.erase("passo")
	u.pos = destino
	eventos.append({"tipo": "mover", "id": u.id, "caminho": [destino]})
	_log("Destreza 5: %s se esquiva e anda 1 quadrado." % u.nome)
	return true


## Reação oferecida no resultado (ex.: Postura da Cascavel).
func reacao_disponivel() -> String:
	if fase != Fase.RESOLVIDO or resultado.is_empty():
		return ""
	return resultado.get("reacao", "")


## Texto do botão da reação oferecida.
func texto_reacao() -> String:
	match reacao_disponivel():
		"postura-da-cascavel":
			return "Postura da Cascavel (1 fadiga, Reação): revidar %d de dano" % maxi(defensor.dano + defensor.atributo_dano - atacante.resistencia_total(), 0)
		"castigo":
			return "Castigo (1 fadiga, Reação de %s): atacar %s" % [unidade(resultado["reator"]).nome, atacante.nome]
	return ""


func heroi_reagir() -> bool:
	var r := reacao_disponivel()
	if r == "castigo":
		var h := unidade(resultado["reator"])
		var alvo_c := atacante
		h.carta_com("castigo").pagar(1)
		h.acoes_reacao -= 1
		resultado["reacao"] = ""
		_log("Castigo: %s ataca %s por ter atacado um aliado." % [h.nome, alvo_c.nome])
		_novo_ataque(h, alvo_c, {"habilidade": "Castigo"})
		return true
	if r != "postura-da-cascavel":
		return false
	var u := defensor
	var c = u.carta_com("postura-da-cascavel")
	if c == null or not c.pode_pagar(1) or u.acoes_reacao <= 0 or not atacante.viva():
		return false
	c.pagar(1)
	u.acoes_reacao -= 1
	var dano := maxi(u.dano + u.atributo_dano - atacante.resistencia_total(), 0)
	_aplicar_dano_inimigo(atacante, dano)
	_log("Postura da Cascavel: %s revida e causa %d de dano em %s." % [u.nome, dano, atacante.nome])
	eventos.append({"tipo": "dano", "id": atacante.id, "valor": dano})
	resultado["reacao"] = ""
	_verificar_fim()
	return true


# --- Testes de 21 do herói ---------------------------------------------------

## Ficha de Foco no teste (Lucas, 0.20): com Foco, a 2ª carta (fechada) espera; o herói
## pode gastar o Foco para ver a próxima (scry 1) antes de recebê-la.
func _adiar_fechada(u: Unidade, defesa := false) -> bool:
	return u.eh_heroi() and perguntar_escolhas and u.fichas_total("Foco") > 0 and not (defesa and defesa_automatica)


func foco_no_teste_disponivel() -> bool:
	var t := teste_do_heroi()
	var h := heroi_dono_do_teste()
	return t != null and t.fechada_pendente and h != null and h.fichas_total("Foco") > 0 and not h.baralho.baralho.is_empty()


func heroi_foco_no_teste() -> bool:
	if not foco_no_teste_disponivel():
		return false
	var h := heroi_dono_do_teste()
	h.tirar_fichas("Foco", 1)
	_log("%s gasta 1 ficha de Foco antes da carta fechada: scry 1." % h.nome)
	scry(h, 1)
	return true


func heroi_receber_fechada() -> bool:
	var t := teste_do_heroi()
	if t == null or not t.fechada_pendente:
		return false
	t.receber_fechada()
	if t.estourou:
		_avancar_apos_teste(t)
	return true


func teste_do_heroi() -> Teste21:
	if fase == Fase.INTERACAO_TESTE:
		return teste_pericia
	if fase == Fase.HEROI_ATACANDO:
		return teste_ataque
	if fase == Fase.HEROI_DEFENDENDO and not defesa_automatica:
		return teste_defesa
	return null


func heroi_dono_do_teste() -> Unidade:
	if fase == Fase.INTERACAO_TESTE:
		return ativa()
	if fase == Fase.HEROI_ATACANDO:
		return atacante
	if fase == Fase.HEROI_DEFENDENDO:
		return defensor
	return null


func puxar() -> bool:
	foco_marcial_visto = -1
	var t := teste_do_heroi()
	if t == null or not t.puxar():
		return false
	_depois_do_lance_do_heroi(t)
	return true


func jogar_da_mao(carta: int) -> bool:
	var t := teste_do_heroi()
	if t == null or not t.jogar_da_mao(carta):
		return false
	_depois_do_lance_do_heroi(t)
	return true


func parar() -> bool:
	var t := teste_do_heroi()
	if t == null:
		return false
	t.parar()
	_depois_do_lance_do_heroi(t)
	return true


func continuar() -> bool:
	if fase == Fase.INTERACAO_RESOLVIDA:
		_continuar_interacao()
		return true
	if fase != Fase.RESOLVIDO:
		return false
	if _verificar_fim():
		return true
	var u := ativa()
	if not ctx.get("area_fila", []).is_empty() and _proximo_alvo_da_area():
		return true
	if ctx.get("labareda", false):
		ctx.erase("labareda")
		var feridos: Array = ctx.get("danificados", [])
		if not feridos.is_empty() and not atacante.baralho.mao.is_empty() and atacante.viva():
			fase = Fase.HEROI_ESCOLHE if u.eh_heroi() else Fase.IA_TURNO
			perguntar("labareda", "Labareda Voraz: descartar uma carta da mão (a de menor valor) para pôr 3 fichas de Fogo em quem sofreu dano?",
				[["sim", "Descartar e pôr Fogo"], ["nao", "Não descartar"]], {"quem": atacante.id, "alvos": feridos})
			return true
	if u.eh_heroi() and not u.viva():
		movimento_pendente = {}
		_proximo_turno()
		return true
	fase = Fase.HEROI_ESCOLHE if u.eh_heroi() else Fase.IA_TURNO
	if not movimento_pendente.is_empty():
		_continuar_movimento()
	if not ataque_pendente.is_empty() and fase == Fase.HEROI_ESCOLHE:
		var ap := ataque_pendente
		ataque_pendente = {}
		var alvo := unidade(ap["alvo"])
		if u.viva() and alvo != null and alvo.viva() and motivo_alcance(u, alvo, u.pos) == "":
			_novo_ataque(u, alvo, ap["ctx"])
	return true


# --- Passos automáticos -----------------------------------------------------

func fase_automatica() -> bool:
	return fase in [Fase.IA_DEFENDENDO, Fase.IA_ATACANDO, Fase.IA_TURNO] \
		or (fase == Fase.HEROI_DEFENDENDO and defesa_automatica)


func passo_automatico() -> bool:
	match fase:
		Fase.IA_TURNO:
			_passo_turno_ia(ativa())
			return true
		Fase.IA_DEFENDENDO:
			return _passo_teste(teste_defesa, teste_ataque, false, defensor.parada_defesa, defensor.risco, baralho_inimigos)
		Fase.IA_ATACANDO:
			return _passo_teste(teste_ataque, teste_defesa, true, atacante.parada_ataque, atacante.risco, baralho_inimigos)
		Fase.HEROI_DEFENDENDO:
			return _passo_teste(teste_defesa, teste_ataque, false, PARADA_DEFESA_AUTOMATICA, RISCO_DEFESA_AUTOMATICA, defensor.baralho)
	return false


func _passo_teste(t: Teste21, oponente: Teste21, ataca: bool, parada: int, risco: float, fonte: Baralho) -> bool:
	if not t.encerrado and IA.quer_puxar(t, oponente, ataca, parada, risco, fonte.baralho) and t.puxar():
		var heroi := defensor if defensor.eh_heroi() else atacante
		if heroi.eh_heroi() and not heroi.viva():
			if not _verificar_fim():
				t.parar()
				_avancar_apos_teste(t)
		elif t.estourou:
			_avancar_apos_teste(t)
		return true
	t.parar()
	if t.vantagem:
		t.vantagem_automatica()
	_avancar_apos_teste(t)
	return false


# --- IA dos inimigos no mapa ------------------------------------------------

func _passo_turno_ia(u: Unidade) -> void:
	if u == null or not u.viva() or herois_ativos().is_empty() or inerte(u):
		_proximo_turno()
		return
	if not u.alerta:
		_ia_vigiar(u)
		_proximo_turno()
		return
	if u.efeitos.has("caido") and (u.acoes_mov > 0 or u.acoes_padrao > 0):
		_levantar(u)
		return
	if not u.efeitos.has("engajou"):
		u.efeitos["engajou"] = {}
	if _ia_habilidades(u):
		if fase == Fase.IA_TURNO:
			_proximo_turno()
		return
	if fase != Fase.IA_TURNO:
		return
	if _ia_escolta(u):
		return
	if u.cura_aliado > 0 and u.acoes_padrao > 0 and not u.efeitos.has("curou"):
		var feridos := inimigos_vivos().filter(func(o): return o.vida * 10 <= o.vida_max * 6 and Grade.distancia(o.pos, u.pos) <= 4 and not o.efeitos.has("sem_cura") \
			and grade.linha_de_visao(o.pos, u.pos))
		if not feridos.is_empty():
			feridos.sort_custom(func(a, b2): return a.vida * b2.vida_max < b2.vida * a.vida_max)
			var f: Unidade = feridos[0]
			u.acoes_padrao -= 1
			u.efeitos["curou"] = {"ate": "inicio_turno"}
			var antes := f.vida
			f.vida = mini(f.vida + u.cura_aliado, f.vida_max)
			_log("%s cura %s (+%d)." % [u.nome, f.nome, f.vida - antes])
			eventos.append({"tipo": "cura", "id": f.id, "valor": f.vida - antes})
			return
	if u.efeitos.has("isca"):
		var pos_isca: Vector2i = u.efeitos["isca"]["pos"]
		u.efeitos.erase("isca")
		if not preso(u) and _ia_andar(u, func(p): return -Grade.distancia(p, pos_isca), true):
			_log("%s gasta a movimentação indo até a isca." % u.nome)
			u.acoes_mov = 0
			u.deslocamento = 0
			return
	var alvo := _alvo_do_turno(u)
	if alvo == null:
		return   # esperando o jogador decidir se gasta Sombra
	if agarrado(u) and motivo_alcance(u, alvo, u.pos) != "" and _ia_escapar(u):
		return
	if _ia_limpar_com_movimento(u, alvo):
		return
	if not u.magias.is_empty() and u.acoes_padrao > 0 and _ia_conjurar(u, alvo):
		return
	# Sem como atacar neste turno (preso, ou atirador cego): gasta a ação para tirar uma ficha.
	if u.acoes_padrao > 0 and ((preso(u) and motivo_sem_ataque(u, alvo) != "") or (u.a_distancia and u.fichas.has("Cegueira"))):
		_ia_sacudir_ficha(u)
		return
	if u.a_distancia:
		_ia_atirador(u, alvo)
	else:
		_ia_corpo_a_corpo(u, alvo)


## Inimigo desatento: só percebe um herói a até "vigia" quadrados, com linha de visão.
## Inimigos não viram cartas: para tirar uma ficha, gastam uma ação Padrão.
const FICHAS_SACUDIVEIS := ["Imobilizar", "Cegueira", "Penalidade", "Medo", "Ferimento", "Atormentado"]


func _ia_sacudir_ficha(u: Unidade) -> bool:
	var ordem_f := ["Imobilizar", "Cegueira", "Penalidade", "Medo", "Ferimento", "Atormentado"]
	if preso(u):
		ordem_f = ["Imobilizar"] + ordem_f
	elif u.a_distancia:
		ordem_f = ["Cegueira"] + ordem_f
	for f in ordem_f:
		if u.fichas.has(f) and u.acoes_padrao > 0:
			u.acoes_padrao -= 1
			u.tirar_fichas(f, 1)
			_log("%s gasta uma ação para se livrar de 1 ficha de %s." % [u.nome, f])
			if f == "Ferimento":
				_dano_direto(u, 1, "Ferimento")
			return true
	return false


## 0.22: o monstro que não precisa andar neste turno (já alcança o alvo) usa a ação de
## Movimento para se livrar de uma ficha, em vez de deixá-la para depois.
## Escolta (Lucas, 0.23): fica perto do líder até ele entrar na luta.
func _ia_escolta(u: Unidade) -> bool:
	if u.escolta == "":
		return false
	var l := unidade(u.escolta)
	if l == null or not l.viva() or l.efeitos.has("engajou"):
		return false
	if herois_ativos().any(func(h): return Grade.adjacentes(h.pos, u.pos)):
		return false
	if Grade.distancia(u.pos, l.pos) > 2 and u.acoes_mov > 0 and not preso(u):
		var lp := l.pos
		if _ia_andar(u, func(p):
			var dh := 99
			for h in herois_ativos():
				dh = mini(dh, Grade.distancia(p, h.pos))
			return -Grade.distancia(p, lp) * 10.0 + mini(dh, 6), true):
			return true
	_log("%s fica para trás, guardando %s." % [nome_visto(u), nome_visto(l)])
	_proximo_turno()
	return true


func _ia_limpar_com_movimento(u: Unidade, alvo: Unidade) -> bool:
	if u.acoes_mov <= 0 or u.efeitos.has("confuso") or motivo_alcance(u, alvo, u.pos) != "":
		return false
	if u.a_distancia and (Grade.distancia(u.pos, alvo.pos) <= 1 or not faixa_entre(u, alvo) in u.faixas_ideais):
		return false
	var ordem_f := ["Cegueira", "Penalidade", "Medo", "Atormentado", "Imobilizar", "Ferimento"] if u.a_distancia \
		else ["Penalidade", "Medo", "Atormentado", "Cegueira", "Imobilizar", "Ferimento"]
	for f in ordem_f:
		if u.fichas.get(f, 0) > 0:
			u.acoes_mov = 0
			u.deslocamento = 0
			u.tirar_fichas(f, 1)
			_log("%s fica no lugar e usa o movimento para se livrar de 1 ficha de %s." % [nome_visto(u), f])
			if f == "Ferimento":
				_dano_direto(u, 1, "Ferimento")
			return true
	return false


# --- Planos dos monstros (0.22) ---------------------------------------------
##
## No fim do turno dos monstros, o jogo avisa o que cada inimigo à vista pretende
## fazer no próximo turno. Quando um monstro muda de estratégia (de atacar para
## fugir, de atirar para conjurar...), aparece um aviso em cima dele.

var intencoes: Array = []   # últimas intenções anunciadas (texto)

const CATEGORIA_PLANO := {"avancar": "atacar", "recuar": "atirar"}
const TEXTO_ESTRATEGIA := {
	"atacar": "parte para o ataque", "atirar": "passa a atirar de longe", "magia": "passa a conjurar",
	"fugir": "vai fugir", "curar": "passa a cuidar dos aliados", "muro": "vai derrubar o muro",
	"provocado": "foi provocado", "confuso": "está confuso", "soltar": "tenta se soltar", "esperar": "espera",
}


## O que o inimigo pretende fazer no próximo turno: {"id", "alvo", "texto"}.
func plano_do_inimigo(u: Unidade) -> Dictionary:
	if u == null or u.eh_heroi() or not u.viva():
		return {}
	var nome := nome_visto(u)
	if not u.alerta:
		return {"id": "vigiar", "alvo": "", "texto": "%s ainda não percebeu o grupo." % nome}
	var total := unidades.size() - herois().size()
	if u.perfil == "Covarde" and total > 1 and inimigos_vivos().size() == 1:
		return {"id": "fugir", "alvo": "", "texto": "%s está sozinho e vai tentar fugir." % nome}
	if u.cura_aliado > 0:
		var feridos := inimigos_vivos().filter(func(o): return o.vida * 10 <= o.vida_max * 6 and Grade.distancia(o.pos, u.pos) <= 4)
		if not feridos.is_empty():
			return {"id": "curar", "alvo": feridos[0].id, "texto": "%s vai curar %s." % [nome, nome_visto(feridos[0])]}
	# Prevê o alvo sem a lista de quem já atacou neste turno (ela vale só dentro do turno).
	var guardado_a = u.efeitos.get("atacados")
	var guardado_t = u.efeitos.get("alvo_turno")
	u.efeitos.erase("atacados")
	u.efeitos.erase("alvo_turno")
	var alvo := _escolher_alvo(u)
	if guardado_a != null:
		u.efeitos["atacados"] = guardado_a
	if guardado_t != null:
		u.efeitos["alvo_turno"] = guardado_t
	if alvo == null:
		return {"id": "esperar", "alvo": "", "texto": "%s espera." % nome}
	var n := alvo.nome
	if u.efeitos.has("provocado") and u.efeitos["provocado"].get("por", "") == alvo.id:
		return {"id": "provocado", "alvo": alvo.id, "texto": "%s foi provocado e vai atrás de %s." % [nome, n]}
	if u.efeitos.has("confuso"):
		return {"id": "confuso", "alvo": alvo.id, "texto": "%s está confuso e vai atrás de %s." % [nome, n]}
	if preso(u) and motivo_alcance(u, alvo, u.pos) != "":
		return {"id": "soltar", "alvo": alvo.id, "texto": "%s está preso e vai tentar se soltar." % nome}
	if not u.magias.is_empty():
		return {"id": "magia", "alvo": alvo.id, "texto": "%s prepara uma magia contra %s." % [nome, n]}
	if u.a_distancia:
		if Grade.distancia(u.pos, alvo.pos) <= 1:
			return {"id": "recuar", "alvo": alvo.id, "texto": "%s quer abrir distância de %s para atirar." % [nome, n]}
		return {"id": "atirar", "alvo": alvo.id, "texto": "%s mira em %s." % [nome, n]}
	if zonas.any(func(z): return z["tipo"] == "muro") and not _muro_no_caminho(u, alvo).is_empty():
		return {"id": "muro", "alvo": alvo.id, "texto": "%s vai derrubar o muro para chegar a %s." % [nome, n]}
	if motivo_alcance(u, alvo, u.pos) == "":
		return {"id": "atacar", "alvo": alvo.id, "texto": "%s vai atacar %s." % [nome, n]}
	return {"id": "avancar", "alvo": alvo.id, "texto": "%s vai avançar sobre %s." % [nome, n]}


## Alvo de treino (boneco): não age nem anuncia planos.
func inerte(u: Unidade) -> bool:
	return not u.eh_heroi() and u.padrao_por_turno <= 0 and u.mov_por_turno <= 0


## Recalcula o plano; avisa se a estratégia mudou.
func _atualizar_plano(u: Unidade) -> Dictionary:
	var p := plano_do_inimigo(u)
	if p.is_empty():
		return p
	var cat: String = CATEGORIA_PLANO.get(p["id"], p["id"])
	var antiga := u.estrategia
	u.estrategia = cat
	u.intencao = p["texto"]
	p["mudou_alvo"] = u.alvo_plano != "" and p["alvo"] != "" and p["alvo"] != u.alvo_plano
	if p["alvo"] != "":
		u.alvo_plano = p["alvo"]
	if antiga != "" and antiga != "vigiar" and antiga != cat and cat != "vigiar" and unidade_visivel(u):
		var txt: String = TEXTO_ESTRATEGIA.get(cat, cat)
		_log("Mudança de estratégia: %s %s." % [nome_visto(u), txt])
		eventos.append({"tipo": "estrategia", "id": u.id, "texto": txt})
	return p


## Fim do turno dos monstros: o que cada inimigo à vista pretende fazer.
func _anunciar_intencoes() -> void:
	var linhas := []
	for o in inimigos_vivos():
		if not o.alerta or not unidade_visivel(o) or inerte(o):
			continue
		var p := _atualizar_plano(o)
		if p.is_empty():
			continue
		linhas.append(p["texto"] + (" (trocou de alvo)" if p.get("mudou_alvo", false) else ""))
	intencoes = linhas
	if linhas.is_empty():
		return
	_log("Os inimigos se preparam: " + " ".join(PackedStringArray(linhas)))
	eventos.append({"tipo": "intencoes", "linhas": linhas})


## Levantar-se: uma ação de movimento completa. Provoca ataque de oportunidade.
func _levantar(u: Unidade) -> void:
	if u.acoes_mov > 0:
		u.acoes_mov -= 1
	else:
		u.acoes_padrao -= 1
	u.deslocamento = 0
	u.efeitos.erase("caido")
	_log("%s se levanta." % u.nome)
	eventos.append({"tipo": "levantar", "id": u.id})
	var reator := _reator_de_oportunidade(u, u.pos, u.pos)
	if reator != null and reator.eh_heroi() and perguntar_escolhas:
		perguntar("oportunidade", "%s se levanta ao lado de %s. Usar a Reação para um Golpe de Oportunidade?" % [u.nome, reator.nome],
			[["sim", "Atacar (Golpe de Oportunidade, Reação)"], ["nao", "Deixar"]], {"reator": reator.id, "alvo": u.id})
		return
	if reator != null:
		reator.acoes_reacao -= 1
		_log("%s se levanta ao lado de %s e provoca um ataque de oportunidade!" % [u.nome, reator.nome])
		_novo_ataque(reator, u, {"habilidade": "Ataque de oportunidade", "oportunidade": true})


func heroi_levantar() -> bool:
	var u := ativa()
	if not vez_do_heroi() or not u.efeitos.has("caido") or (u.acoes_mov <= 0 and u.acoes_padrao <= 0):
		return false
	_levantar(u)
	return true


## Fica Caído: ataques corpo a corpo contra ele têm vantagem; anda 1 por ação; levantar custa a ação de movimento.
func derrubar(u: Unidade) -> void:
	if not u.viva() or u.efeitos.has("caido"):
		return
	u.efeitos["caido"] = {}
	u.deslocamento = mini(u.deslocamento, 1)
	_log("%s fica Caído." % u.nome)
	eventos.append({"tipo": "caido", "id": u.id})


## Até onde um inimigo desatento percebe este herói: vigia + Percepção do inimigo,
## menos metade da Furtividade do herói (mínimo 1).
func raio_de_percepcao(o: Unidade, h: Unidade) -> int:
	return maxi(o.vigia + o.percepcao - int(int(h.pericias.get("Furtividade", 0)) / 2), 1)


func _ia_vigiar(u: Unidade) -> void:
	for h in herois_ativos():
		if Grade.distancia(u.pos, h.pos) <= raio_de_percepcao(u, h) and grade.linha_de_visao(u.pos, h.pos):
			_log("%s avista %s e dá o alarme!" % [u.nome, h.nome])
			_alertar_inimigos(u.grupo)
			return


## Alerta os inimigos de um grupo ("" = todos).
func _alertar_inimigos(grupo := "") -> void:
	for o in unidades:
		if not o.eh_heroi() and not o.alerta and o.viva() and (grupo == "" or o.grupo == grupo):
			o.alerta = true
			if o.grupo != "":
				grupos_alertados[o.grupo] = true
			eventos.append({"tipo": "alerta", "id": o.id})


var acoes_longas_automaticas := true   # a tela desliga: pergunta a cada turno
var conjurando: Unidade = null   # herói conjurando uma magia agora (curas do Cálice da Vida)
var scry_de := ""                # quem está fazendo scry 1 (Escrituras de Maftoné)
var perguntar_sombra := false   # a tela liga: pergunta se o herói escolhido gasta Sombra
var sombra_pendente := {}


## O inimigo decide o alvo uma vez por turno. Se o escolhido tem Sombra, ele pode
## gastá-la para não ser o alvo; aí o inimigo escolhe outro (e pergunta de novo).
## Se todos gastarem, vale a primeira escolha (é como se ninguém tivesse gastado).
func _alvo_do_turno(u: Unidade) -> Unidade:
	var guardado := unidade(u.efeitos.get("alvo_turno", {}).get("id", ""))
	if guardado != null and guardado.viva():
		return guardado
	var primeiro := _escolher_alvo(u)
	return _oferecer_sombra(u, primeiro, primeiro, [])


func _oferecer_sombra(u: Unidade, alvo: Unidade, primeiro: Unidade, excluidos: Array) -> Unidade:
	if alvo != null and alvo.eh_heroi() and alvo.fichas_total("Sombra") > 0 and not alvo.id in excluidos \
			and not u.efeitos.has("confuso") and perguntar_sombra:
		sombra_pendente = {"inimigo": u.id, "heroi": alvo.id, "primeiro": primeiro.id, "excluidos": excluidos}
		fase = Fase.SOMBRA_ESCOLHA
		_log("%s escolhe %s como alvo." % [u.nome, alvo.nome])
		return null
	if alvo != null:
		u.efeitos["alvo_turno"] = {"id": alvo.id, "ate": "inicio_turno"}
	return alvo


func texto_sombra() -> String:
	if fase != Fase.SOMBRA_ESCOLHA:
		return ""
	return "%s escolheu %s como alvo. Gastar 1 ficha de Sombra para não ser o alvo?" % [
		unidade(sombra_pendente["inimigo"]).nome, unidade(sombra_pendente["heroi"]).nome]


func heroi_sombra(gastar: bool) -> bool:
	if fase != Fase.SOMBRA_ESCOLHA:
		return false
	var p := sombra_pendente
	sombra_pendente = {}
	fase = Fase.IA_TURNO
	var u := unidade(p["inimigo"])
	var h := unidade(p["heroi"])
	var excl: Array = p["excluidos"]
	excl.append(h.id)
	if not gastar:
		u.efeitos["alvo_turno"] = {"id": h.id, "ate": "inicio_turno"}
		return true
	h.tirar_fichas("Sombra", 1)
	_gastou_sombra(h)
	_log("%s gasta 1 ficha de Sombra e some das vistas de %s." % [h.nome, u.nome])
	var prox := _escolher_alvo(u, excl)
	var primeiro := unidade(p["primeiro"])
	if prox == null or prox.id in excl:
		prox = primeiro
		_log("Todos se esconderam: %s volta à primeira escolha, %s." % [u.nome, primeiro.nome])
	_oferecer_sombra(u, prox, primeiro, excl)
	return true


func _escolher_alvo(u: Unidade, excluidos: Array = []) -> Unidade:
	var alvos := herois_ativos().filter(func(h): return not h.id in excluidos)
	if alvos.is_empty():
		return null
	# Elite e chefe: cada ataque do turno num herói diferente, se houver outro.
	var ja: Array = u.efeitos.get("atacados", {}).get("ids", [])
	var outros := alvos.filter(func(h): return not h.id in ja)
	if not outros.is_empty():
		alvos = outros
	# Ocultos só são escolhidos se não houver outro alvo.
	var visiveis := alvos.filter(func(h): return not h.efeitos.has("oculto"))
	if not visiveis.is_empty():
		alvos = visiveis
	if u.efeitos.has("confuso"):
		var c := unidade(u.efeitos["confuso"]["alvo"])
		if c != null and c.viva():
			return c
	if u.efeitos.has("provocado"):
		var p := unidade(u.efeitos["provocado"]["por"])
		if p != null and p.viva():
			return p
	if u.perfil == "Covarde":
		alvos.sort_custom(func(a, b): return a.baralho.baralho.size() < b.baralho.baralho.size())
	else:
		alvos.sort_custom(func(a, b): return Grade.distancia(u.pos, a.pos) < Grade.distancia(u.pos, b.pos))
	return alvos[0]


func _ia_corpo_a_corpo(u: Unidade, alvo: Unidade) -> void:
	var total_inimigos := unidades.size() - herois().size()
	if u.perfil == "Covarde" and total_inimigos > 1 and inimigos_vivos().size() == 1 and u.acoes_mov > 0 and not preso(u):
		if _ia_andar(u, func(p): return Grade.distancia(p, alvo.pos), true):
			_log("%s, sozinho, tenta fugir!" % u.nome)
			u.acoes_padrao = 0
			u.deslocamento = 0
			return
	if motivo_sem_ataque(u, alvo) == "":
		u.acoes_padrao -= 1
		_novo_ataque(u, alvo, {})
		return
	var muro := _muro_no_caminho(u, alvo)
	if not muro.is_empty() and _ia_quebrar_muro(u, muro):
		return
	if pode_ganhar_deslocamento(u) or u.deslocamento > 0:
		if _ia_andar(u, func(p): return -Grade.distancia(p, alvo.pos), false, alvo):
			return
	if _ia_sacudir_ficha(u):
		return
	_proximo_turno()


## Muro (Lucas, 0.19): tem pontos de vida; o inimigo que só chega ao alvo
## passando pelo muro vai até ele e o quebra a golpes.
func _muro_no_caminho(u: Unidade, alvo: Unidade) -> Dictionary:
	var muros := zonas.filter(func(z): return z["tipo"] == "muro")
	if muros.is_empty() or preso(u):
		return {}
	var chega := func() -> bool:
		var m := grade.alcance(u.pos, 80, _ocupadas(u), {}, modo_de_andar(u))
		for p in m:
			if Grade.adjacentes(p, alvo.pos):
				return true
		return false
	if chega.call():
		return {}
	var guardado := grade.bloqueio_extra.duplicate()
	for z in muros:
		for c in z["celulas"]:
			grade.bloqueio_extra.erase(c)
	var sem_muro: bool = chega.call()
	grade.bloqueio_extra = guardado
	if not sem_muro:
		return {}
	var melhor: Dictionary = muros[0]
	for z in muros:
		for c in z["celulas"]:
			if Grade.distancia(c, u.pos) < Grade.distancia(melhor["celulas"][0], u.pos):
				melhor = z
	return melhor


func _ia_quebrar_muro(u: Unidade, z: Dictionary) -> bool:
	var perto: bool = z["celulas"].any(func(c): return Grade.adjacentes(c, u.pos))
	if perto and u.acoes_padrao > 0:
		u.acoes_padrao -= 1
		var dano: int = maxi(int(u.dano) + int(u.atributo_dano), 1)
		_log("%s golpeia o %s." % [u.nome, z["nome"]])
		dano_no_muro(z, dano, u.nome)
		return true
	if not perto and (pode_ganhar_deslocamento(u) or u.deslocamento > 0):
		var cels: Array = z["celulas"]
		return _ia_andar(u, func(p):
			var d := 99
			for c in cels:
				d = mini(d, Grade.distancia(p, c))
			return -d, false)
	return false


## Dano num muro: quando a vida acaba, ele desmorona e abre a passagem.
func dano_no_muro(z: Dictionary, dano: int, fonte: String) -> void:
	if not z in zonas:
		return
	z["vida"] = int(z.get("vida", 12)) - dano
	if int(z["vida"]) <= 0:
		_remover_zona(z, "%s o derrubou" % fonte)
		eventos.append({"tipo": "zonas"})
	else:
		_log("%s: %d de dano (%s); restam %d pontos de vida." % [z["nome"], dano, fonte, int(z["vida"])])
		eventos.append({"tipo": "zonas"})


func muro_em(p: Vector2i) -> Dictionary:
	for z in zonas:
		if z["tipo"] == "muro" and p in z["celulas"]:
			return z
	return {}


func _ia_atirador(u: Unidade, alvo: Unidade) -> void:
	var dist := Grade.distancia(u.pos, alvo.pos)
	if dist == 1 and u.acoes_mov > 0 and not preso(u):
		if _ia_andar(u, func(p): return Grade.distancia(p, alvo.pos) * 10 + (5 if grade.linha_de_visao(p, alvo.pos) else 0), true):
			return
	var ideal: bool = faixa_entre(u, alvo) in u.faixas_ideais and not impedido(u)
	if motivo_sem_ataque(u, alvo) == "" and ideal:
		u.acoes_padrao -= 1
		_novo_ataque(u, alvo, {})
		return
	if u.acoes_mov > 0 and not preso(u):
		var nota := func(p):
			var d := Grade.distancia(p, alvo.pos)
			var bom: bool = grade.linha_de_visao(p, alvo.pos) and Combate.faixa(d) in u.faixas_ideais and d >= 2
			return (100 if bom else 0) - absi(d - 6)
		if _ia_andar(u, nota, true):
			return
	if motivo_sem_ataque(u, alvo) == "":
		u.acoes_padrao -= 1
		_novo_ataque(u, alvo, {})
		return
	_proximo_turno()


func _ia_andar(u: Unidade, nota: Callable, so_mov: bool, alvo: Unidade = null) -> bool:
	if u.deslocamento == 0:
		if so_mov and u.acoes_mov <= 0:
			return false
		if not pode_ganhar_deslocamento(u):
			return false
	var mapa: Dictionary = alcance_movimento(u)["mapa"]
	var melhor := u.pos
	var melhor_nota: float = nota.call(u.pos)
	# Zonas perigosas (inteligência 1+): o inimigo atravessa se for o jeito de
	# atacar o alvo neste turno; se não alcança de qualquer forma, vai pelo seguro.
	var cuidado: bool = u.inteligencia >= 1 and (not zonas.is_empty() or not chamas.is_empty())
	var expulso_por := unidade(u.efeitos.get("expulso", {}).get("por", ""))
	for p in mapa:
		var n: float = nota.call(p)
		if expulso_por != null and Grade.distancia(p, expulso_por.pos) < Grade.distancia(u.pos, expulso_por.pos):
			continue   # Expulsar: não pode se aproximar de quem o expulsou
		if cuidado:
			var perigo := casa_perigosa_para(u, p)
			for q in Grade.caminho(mapa, p):
				perigo = perigo or casa_perigosa_para(u, q)
			if perigo:
				var ataca: bool = alvo != null and motivo_alcance(u, alvo, p) == ""
				n -= 0.5 if ataca else 100.0
		if n > melhor_nota:
			melhor_nota = n
			melhor = p
	if melhor == u.pos:
		return false
	return _mover(u, melhor)


# --- Interno: movimento ------------------------------------------------------

func _mover(u: Unidade, destino: Vector2i) -> bool:
	var info := alcance_movimento(u)
	var mapa: Dictionary = info["mapa"]
	if not mapa.has(destino):
		return false
	u.moveu_no_turno = true
	if info["precisa_acao"]:
		var passos := passos_por_acao(u)
		if u.acoes_mov > 0:
			u.acoes_mov -= 1
		else:
			u.acoes_padrao -= 1
		u.deslocamento = passos
	mapa = grade.alcance(u.pos, u.deslocamento, _ocupadas(u), _perigos(u), modo_de_andar(u))
	var caminho := Grade.caminho(mapa, destino)
	return _percorrer(u, caminho, true)


## Anda o caminho passo a passo. Antes de cada passo, confere se alguém faz um
## ataque de oportunidade; se fizer, o movimento para, o ataque acontece e o
## resto do caminho fica guardado (continua depois do ataque).
func _percorrer(u: Unidade, caminho: Array, gasta_deslocamento: bool) -> bool:
	var perigos := _perigos(u)
	var feitos := []
	if not caminho.is_empty():
		for z in zonas.duplicate():
			if z["tipo"] == "covil" and z["dono"] == u.id:
				_remover_zona(z, "%s se moveu" % u.nome)
	for i in caminho.size():
		var passo: Vector2i = caminho[i]
		var reator := _reator_de_oportunidade(u, u.pos, passo)
		if reator != null:
			if not feitos.is_empty():
				eventos.append({"tipo": "mover", "id": u.id, "caminho": feitos})
			movimento_pendente = {"id": u.id, "caminho": caminho.slice(i), "gasta": gasta_deslocamento}
			if reator.eh_heroi() and perguntar_escolhas:
				# Reação do herói (Lucas, 0.19): sempre pergunta.
				perguntar("oportunidade", "%s sai de perto de %s. Usar a Reação para um Golpe de Oportunidade?" % [u.nome, reator.nome],
					[["sim", "Atacar (Golpe de Oportunidade, Reação)"], ["nao", "Deixar passar"]], {"reator": reator.id, "alvo": u.id})
				return true
			reator.acoes_reacao -= 1
			_log("%s sai de perto de %s e provoca um ataque de oportunidade!" % [u.nome, reator.nome])
			_novo_ataque(reator, u, {"habilidade": "Ataque de oportunidade", "oportunidade": true})
			return true
		u.pos = passo
		feitos.append(passo)
		if gasta_deslocamento:
			u.deslocamento -= 1 + (0 if u.efeitos.has("passo_leve") or u.efeitos.has("saltando") else int(grade.custo_extra.get(passo, 0)))
			if perigos.has(passo):
				u.deslocamento = 0
		var parou := _entrar_na_casa(u, passo)
		u.deslocamento = maxi(u.deslocamento, 0)
		if not u.viva() or parou:
			if gasta_deslocamento:
				u.deslocamento = 0
			break
	if gasta_deslocamento and u.deslocamento <= 0:
		u.deslocamento = 0
		u.ignora_impedimento = false
		_fim_da_corrida(u)
	oportunidade_recusada.erase(u.id)   # quem deixou passar não é perguntado de novo no mesmo movimento
	if not feitos.is_empty():
		eventos.append({"tipo": "mover", "id": u.id, "caminho": feitos})
		_zonas_seguem(u)
	if u.eh_heroi() and not feitos.is_empty():
		_verificar_avistamentos()
	if impedido(u):
		_log("%s anda e fica impedido." % u.nome)
	var jur: String = u.efeitos.get("juramento", {}).get("alvo", "")
	if jur != "" and unidade(jur) != null and Grade.adjacentes(unidade(jur).pos, u.pos):
		u.dar_ficha("Foco")
		_log("Palavra de Aço: %s chega ao lado do alvo do juramento e ganha 1 Foco." % u.nome)
	return true


var movimento_pendente: Dictionary = {}   # caminho interrompido por um ataque de oportunidade
var oportunidade_recusada: Dictionary = {}   # id de quem anda -> [heróis que deixaram passar neste passo]


## Quem faz um ataque de oportunidade se "u" sair de "de" para "para" (ou null).
## Só quem tem a habilidade (inimigos com "ataque_oportunidade"; heróis com Golpe
## de Oportunidade), tem Reação e alcança o quadrado de onde "u" sai.
func _reator_de_oportunidade(u: Unidade, de: Vector2i, para: Vector2i) -> Unidade:
	if u.efeitos.has("desengajar") or u.efeitos.has("passo_sem_reacao"):
		return null
	if u.eh_heroi() and u.ativo("tomar-a-posicao"):
		var perto := inimigos_vivos().any(func(o): return Grade.distancia(para, o.pos) < Grade.distancia(de, o.pos))
		if perto:
			return null
	for r in oponentes(u):
		if not r.viva() or r.acoes_reacao <= 0 or r.a_distancia:
			continue
		if not r.eh_heroi():
			if not r.ataque_oportunidade or not r.alerta or sem_reacoes_ate != "":
				continue
			if Grade.distancia(r.pos, de) > r.alcance_corpo:
				continue
		else:
			if not r.ativo("golpe-de-oportunidade") or not Grade.adjacentes(r.pos, de):
				continue
			if r.id in oportunidade_recusada.get(u.id, []):
				continue
		return r
	return null


func _continuar_movimento() -> void:
	var m := movimento_pendente
	movimento_pendente = {}
	var u := unidade(m["id"])
	if u == null or not u.viva() or preso(u):
		return
	var caminho: Array = m["caminho"]
	# O caminho guardado só continua se as casas ainda estiverem livres.
	var livre := []
	for p in caminho:
		if na_posicao(p) != null and na_posicao(p) != u:
			break
		livre.append(p)
	_percorrer(u, livre, m["gasta"])


## Movimento dado por habilidade (não gasta ação nem deslocamento). Provoca ataque
## de oportunidade, a não ser que a habilidade diga que não. Devolve true se foi
## interrompido por um ataque de oportunidade.
func _andar_para(u: Unidade, destino: Vector2i) -> bool:
	if destino == u.pos or destino == Vector2i(-99, -99):
		return false
	var mapa := grade.alcance(u.pos, 3, _ocupadas(u), _perigos(u), modo_de_andar(u))
	var caminho := Grade.caminho(mapa, destino)
	var antes := fase
	_percorrer(u, caminho, false)
	return fase != antes


var ataque_pendente := {}   # ataque de uma habilidade que esperou um ataque de oportunidade


## Habilidade que anda e depois ataca: se a andada provocou, o ataque espera.
func _andar_e_atacar(u: Unidade, destino: Vector2i, alvo: Unidade, contexto: Dictionary) -> void:
	if _andar_para(u, destino):
		ataque_pendente = {"alvo": alvo.id, "ctx": contexto}
		return
	_novo_ataque(u, alvo, contexto)


# --- Interno: ataques --------------------------------------------------------

func _novo_ataque(atk: Unidade, dfs: Unidade, contexto: Dictionary) -> void:
	atacante = atk
	defensor = dfs
	ctx = contexto
	if ctx.get("magico", false) and not ctx.has("tipo_dano") and tipo_da_magia_atual != "":
		ctx["tipo_dano"] = tipo_da_magia_atual
	resultado = {}
	atk.atacou_nesta_rodada = true
	atk.efeitos.erase("oculto")
	var desvantagem := false
	if atk.a_distancia and not ctx.get("magico", false) and impedido(atk):
		desvantagem = true
	var no_escuro := not ve_de(atk, atk.pos, dfs.pos)
	var fora := niveis_fora_da_distancia(atk, dfs) if not ctx.get("magico", false) else 0
	var cobertura := cobertura_de(atk, dfs)
	if dfs.eh_heroi() and (atk.a_distancia or Grade.distancia(atk.pos, dfs.pos) > 1) and cobertura == 0 \
			and herois_ativos().any(func(h): return h != dfs and h.efeitos.has("escudo_agil") and Grade.adjacentes(h.pos, dfs.pos)):
		cobertura = 1
		_log("Escudo Ágil: %s tem cobertura parcial." % dfs.nome)
	var niveis := fora + cobertura
	if no_escuro:
		# Escuro completo (Lucas): ataca só com 1 carta.
		niveis = maxi(niveis, 2)
		_log("%s ataca no escuro, sem enxergar %s: só 1 carta." % [atk.nome, dfs.nome])
	if niveis > 0:
		_log("%s: %s — o ataque %s." % [atk.nome,
			", ".join(PackedStringArray(([] if fora == 0 else ["%d faixa(s) fora da distância ideal" % fora]) + ([] if cobertura == 0 else ["alvo com cobertura parcial"]))),
			"usa só as 2 cartas iniciais (pode jogar da mão)" if niveis == 1 else "usa só 1 carta do baralho (pode jogar da mão)"])
	var a_distancia: bool = atk.a_distancia or Grade.distancia(atk.pos, dfs.pos) > 1
	if a_distancia and atk.fichas_total("Cegueira") > 0:
		desvantagem = true
		_log("%s está cego: ataca à distância só com as 2 cartas iniciais." % atk.nome)
	var vantagem_contra: bool = dfs.fichas_total("Cegueira") > 0 or (dfs.efeitos.has("caido") and not a_distancia)
	if vantagem_contra:
		_log("%s está %s: o ataque tem vantagem." % [dfs.nome, "cego" if dfs.fichas_total("Cegueira") > 0 else "caído"])
	elif dfs.efeitos.has("correu") or (dfs.efeitos.has("saltando") and ctx.get("oportunidade", false)):
		vantagem_contra = true
		_log("%s está %s: o ataque tem vantagem." % [dfs.nome, "correndo" if dfs.efeitos.has("correu") else "no meio do salto"])
	if not atk.eh_heroi() and atk.espalha_ataques:
		if not atk.efeitos.has("atacados"):
			atk.efeitos["atacados"] = {"ids": [], "ate": "inicio_turno"}
		atk.efeitos["atacados"]["ids"].append(dfs.id)
		atk.efeitos.erase("alvo_turno")
	if atk.efeitos.get("confuso", {}).get("alvo", "") == dfs.id:
		atk.efeitos.erase("confuso")
		atk.tirar_fichas("Confusão")
	if dfs.eh_heroi():
		_tut("defendeu")
	var b_atk: Baralho = atk.baralho if atk.eh_heroi() else baralho_inimigos
	var b_dfs: Baralho = dfs.baralho if dfs.eh_heroi() else baralho_inimigos
	var surpreso := not dfs.eh_heroi() and not dfs.alerta
	if surpreso:
		_log("%s é pego de surpresa: defende só com as 2 cartas iniciais." % dfs.nome)
	if not dfs.eh_heroi():
		_alertar_inimigos(dfs.grupo)
	var lim_atk := _limite_ataque(atk) - atk.fichas_total("Penalidade")
	var lim_dfs := _limite_defesa(dfs) - dfs.fichas_total("Penalidade") - int(ctx.get("limite_defensor", 0))
	if ctx.get("magico", false) and atk.eh_heroi():
		lim_atk += int(atk.foco.get("limite_magia", 0))
	if not atk.eh_heroi() and dfs.eh_heroi() and dfs.ativo("alvo-dificil") and not atk.a_distancia and Origens.maior(atk, dfs):
		lim_atk -= 1
	var vantagem_atk: bool = (atk.eh_heroi() and atk.ativo("matador-de-gigante") and Origens.maior(dfs, atk)) or vantagem_contra
	if (no_alto(atk) and not no_alto(dfs)) or grade.nivel(atk.pos) > grade.nivel(dfs.pos):
		vantagem_atk = true
		_log("%s ataca do alto: vantagem." % atk.nome)
	# Ficha de Vantagem na arma (O Martelo da Luz): o próximo ataque com a arma tem vantagem.
	if atk.eh_heroi() and not ctx.get("magico", false) and atk.efeitos.has("vantagem_na_arma"):
		atk.efeitos.erase("vantagem_na_arma")
		vantagem_atk = true
		_log("%s gasta a ficha de Vantagem da arma." % atk.nome)
	if atk.efeitos.has("finta"):
		vantagem_atk = true
		_log("Finta: o ataque de %s tem vantagem." % atk.nome)
	if dfs.efeitos.has("olha_la") and vantagem_atk:
		vantagem_atk = false
		_log("Olha Lá!: %s não tem vantagem contra %s." % [atk.nome, dfs.nome])
	teste_ataque = Teste21.new(b_atk, 0, lim_atk, vantagem_atk, desvantagem, 2 if niveis <= 1 else 1, _adiar_fechada(atk))
	if niveis >= 1:
		teste_ataque.sem_puxar = true
	var por_baixo: bool = atk.efeitos.has("ponto_de_vantagem") and (atk.a_distancia or Grade.distancia(atk.pos, dfs.pos) > 1) \
		and (grade.nivel(atk.pos) > grade.nivel(dfs.pos) or (no_alto(atk) and not no_alto(dfs)))
	if por_baixo:
		_log("Ponto de Vantagem: %s defende com desvantagem." % dfs.nome)
	teste_defesa = Teste21.new(b_dfs, 0, lim_dfs, false, surpreso or por_baixo, 2, _adiar_fechada(dfs, true))
	if ctx.get("resultado_fixo", 0) > 0:
		# Tiro Perfeito: sem revelar cartas, o ataque vale o valor fixo.
		for c in teste_ataque.cartas:
			b_atk.baralho.append(c)
		teste_ataque.cartas.clear()
		teste_ataque.parar()
	if dfs.eh_heroi() and (dfs.ativo("postura-do-leao") or (dfs.arma.get("tamanho", "") == "pequeno" and dfs.atacou_nesta_rodada)):
		teste_defesa.revelado = true
	if dfs.luz == "tocha":
		teste_defesa.revelado = true
		_log("%s segura uma tocha acesa: defende com as cartas reveladas." % dfs.nome)
	if atk.eh_heroi() and (atk.percepcao >= 3 or dfs.fichas_total("Marcado") > 0):
		teste_defesa.revelado = true
	if atk.eh_heroi() and atk.percepcao >= 5 and not b_dfs.baralho.is_empty():
		_log("Percepção 5: %s vê o topo do baralho do defensor: %s." % [atk.nome, Carta.nome(b_dfs.baralho[-1])])
	var nome_hab: String = ctx.get("habilidade", "")
	_log("%s ataca %s%s%s." % [atk.nome, dfs.nome, (" com " + nome_hab) if nome_hab != "" else "",
		" (com inimigo ao lado: só as 2 cartas iniciais)" if desvantagem else ""])
	eventos.append({"tipo": "ataque", "atacante": atk.id, "defensor": dfs.id, "magia": ctx.get("magico", false),
		"tipo_dano": str(ctx.get("tipo_dano", "")), "distancia": atk.a_distancia or ctx.get("magico", false)})
	fase = Fase.HEROI_ATACANDO if atk.eh_heroi() else Fase.IA_ATACANDO
	var caiu := (atk.eh_heroi() and not atk.viva()) or (dfs.eh_heroi() and not dfs.viva())
	if caiu:
		if not _verificar_fim():
			teste_ataque.parar()
			teste_defesa.parar()
			_resolver()
	elif desvantagem or ctx.get("resultado_fixo", 0) > 0:
		teste_ataque.parar()
		_avancar_apos_teste(teste_ataque)


## Quantas faixas de distância o alvo está fora do alcance ideal da arma de tiro.
func niveis_fora_da_distancia(atk: Unidade, dfs: Unidade) -> int:
	if not atk.a_distancia or atk.faixas_ideais.is_empty():
		return 0
	if atk.eh_heroi() and atk.ativo("talento-com-o-arco") and str(atk.arma.get("nome", "")).contains("Arco"):
		return 0
	var f := int(faixa_entre(atk, dfs))
	var covil := zona_em(atk.pos, "covil")
	if not covil.is_empty() and covil["dono"] == atk.id and f != int(Combate.Faixa.CURTO) \
			and not unidades.any(func(o): return o != atk and o.viva() and o.pos in covil["celulas"]):
		return 0
	var menor := 99
	for ideal in atk.faixas_ideais:
		menor = mini(menor, absi(f - int(ideal)))
	return menor


## Objetos que dão cobertura parcial (o alvo fica atrás deles, colado).
const COBERTURA_PARCIAL := ["tronco", "cerca", "saco", "poco", "fogueira_apagada", "fogueira", "agua_pedras", "sarcofago", "mesa", "fonte", "altar"]


## 1 se o alvo tem cobertura parcial contra este ataque à distância: um objeto
## baixo no quadrado colado ao alvo, do lado de quem ataca.
func cobertura_de(atk: Unidade, dfs: Unidade) -> int:
	var d := atk.pos - dfs.pos
	if Grade.distancia(atk.pos, dfs.pos) <= 1:
		return 0
	var frente := dfs.pos + Vector2i(signi(d.x), signi(d.y))
	if grade.obstaculos.get(frente, "") in COBERTURA_PARCIAL:
		return 1
	# Penumbra (0.15): quem está na penumbra tem cobertura parcial contra ataques de longe.
	if escuro and nivel_visto_por(atk, dfs.pos) == 1:
		return 1
	# Névoa e fumaça: quem está dentro tem cobertura parcial contra quem está fora.
	for z in zonas_em(dfs.pos):
		if int(z.get("cobertura", 0)) > 0 and not atk.pos in z["celulas"]:
			return 1
	return 0


func _limite_ataque(u: Unidade) -> int:
	var lim := 21 + u.bonus_limite_ataque
	if u.ativo("postura-da-tartaruga"):
		lim -= 2
	if u.a_distancia and u.ativo("parabola-intuitiva"):
		lim += 1
	return lim


func _limite_defesa(u: Unidade) -> int:
	var lim := 21
	if u.ativo("postura-da-tartaruga"):
		lim += 2
	if u.armadura.get("classe", "") == "pesada" and u.vida_armadura > 0:
		lim += 1
	lim += int(u.foco.get("limite_defesa", 0))
	for o in unidades:
		if o != u and o.viva() and o.eh_heroi() == u.eh_heroi() and o.ativo("ombro-de-aco"):
			lim += 1
	return lim


func _depois_do_lance_do_heroi(t: Teste21) -> void:
	var dono := heroi_dono_do_teste()
	if dono != null and not dono.viva():
		if not _verificar_fim():
			t.parar()
			_avancar_apos_teste(t)
		return
	if t.encerrado:
		if t.vantagem and not t.estourou:
			if dono != null and not dono.baralho.mao.is_empty():
				return   # espera o jogador trocar uma carta ou confirmar
			t.confirmar()
		_avancar_apos_teste(t)


func _avancar_apos_teste(t: Teste21) -> void:
	_ajustes_no_estouro(t)
	if t == teste_pericia and fase == Fase.INTERACAO_TESTE:
		_concluir_teste_pericia()
		return
	if t.estourou:
		var dono := atacante if t == teste_ataque else defensor
		_log("%s estourou." % dono.nome)
	match fase:
		Fase.HEROI_ATACANDO:
			fase = Fase.IA_DEFENDENDO if not defensor.eh_heroi() else Fase.HEROI_DEFENDENDO
		Fase.IA_ATACANDO:
			fase = Fase.HEROI_DEFENDENDO if defensor.eh_heroi() else Fase.IA_DEFENDENDO
		_:
			_resolver()


func _resolver() -> void:
	var atk := teste_ataque.resultado()
	if ctx.get("resultado_fixo", 0) > 0:
		atk = int(ctx["resultado_fixo"])
	var dfs := teste_defesa.resultado()
	var acerto := Combate.acertou(atk, dfs)
	# Azar Alheio: uma vez por cena, o inimigo que acertou refaz o ataque.
	if acerto and not atacante.eh_heroi() and defensor.ativo("azar-alheio") and not defensor.efeitos.has("azar_usado"):
		defensor.efeitos["azar_usado"] = {}
		var novo := Teste21.new(baralho_inimigos, 0, _limite_ataque(atacante))
		while not novo.encerrado and IA.quer_puxar(novo, teste_defesa, true, atacante.parada_ataque, atacante.risco, baralho_inimigos.baralho):
			if not novo.puxar():
				break
		novo.parar()
		_log("Azar Alheio: %s obriga %s a refazer o ataque (%d → %d)." % [defensor.nome, atacante.nome, atk, novo.resultado()])
		teste_ataque = novo
		atk = novo.resultado()
		acerto = Combate.acertou(atk, dfs)
	var u := atacante
	var alvo := defensor
	var partes := []   # [rótulo, valor] para a tela explicar a conta
	var dano := 0
	var reducao := 0
	var magico: bool = ctx.get("magico", false)
	if acerto and magico:
		# Ataque mágico: como um ataque normal (diferença + atributo de conjuração),
		# com o dano do foco no lugar da arma, mais o dano extra da magia.
		dano = atk - dfs
		partes.append(["diferença", atk - dfs])
		var dano_foco := int(u.foco.get("dano", 0))
		if dano_foco > 0:
			dano += dano_foco
			partes.append([u.foco.get("nome", "foco"), dano_foco])
		var at_mag := atributo_de_magia(u)
		if at_mag != 0:
			dano += at_mag
			partes.append([NOMES_ATRIBUTO.get(ATRIBUTO_MAGIA.get(u.classe, "sabedoria"), ""), at_mag])
		if u.efeitos.has("varinha_de_cristal"):
			var vc := maxi(u.raciocinio, u.sabedoria)
			dano += vc
			partes.append(["Varinha de Cristal", vc])
		if u.efeitos.has("escrituras_espirito"):
			u.efeitos.erase("escrituras_espirito")
			dano += u.espirito
			partes.append(["Escrituras de Maftoné (Espírito)", u.espirito])
		if u.foco.get("id", "") == "marca_da_punicao":
			dano += 2
			partes.append(["Marca da Punição", 2])
			ctx["ao_acertar"] = ctx.get("ao_acertar", []) + [{"ficha": "Ferimento"}]
	elif acerto:
		dano = atk - dfs
		partes.append(["diferença", atk - dfs])
		var dano_arma := u.dano * int(ctx.get("multiplicar_arma", 1))
		dano += dano_arma
		partes.append([("arma ×%d" % int(ctx["multiplicar_arma"])) if ctx.has("multiplicar_arma") else ("arma" if u.eh_heroi() else "dano"), dano_arma])
		if u.atributo_dano != 0:
			dano += u.atributo_dano
			partes.append([_nome_atributo_dano(u), u.atributo_dano])
	elif not magico and u.forca >= 3 and _nome_atributo_dano(u) == "Força":
		# Força +3: dano igual à Força mesmo errando · Força +5: Força + arma.
		dano = u.forca + (u.dano if u.forca >= 5 else 0)
		partes.append(["Força (mesmo errando)", dano])
	if dano > 0:
		if u.eh_heroi() and u.ativo("postura-do-leao"):
			dano += 2
			partes.append(["Postura do Leão", 2])
		var bonus_res: int = ctx.get("bonus_res_armadura", 0)
		if bonus_res > 0 and u.resistencia_armadura() > 0:
			dano += bonus_res * u.resistencia_armadura()
			partes.append(["resistência da armadura" + (" ×2" if bonus_res == 2 else ""), bonus_res * u.resistencia_armadura()])
		if ctx.get("bonus", 0) > 0:
			dano += ctx["bonus"]
			partes.append(["aliados", ctx["bonus"]])
		for extra in _bonus_de_dano(u, alvo, acerto):
			dano += extra[1]
			partes.append(extra)
		for extra in _bonus_por_tipo(u, alvo, acerto):
			dano += extra[1]
			partes.append(extra)
		if acerto and alvo.categoria in ctx.get("dobra_contra", []):
			partes.append(["%s ×2 (%s)" % [ctx.get("habilidade", "magia"), Devocoes.CATEGORIAS.get(alvo.categoria, "")], dano])
			dano *= 2
		var penit := zona_em(alvo.pos, "penitencia")
		if acerto and magico and not penit.is_empty() and penit["dono"] == u.id:
			partes.append(["Zona da Penitência ×2", dano])
			dano *= 2
		if acerto and magico and u.efeitos.has("sobrecarga"):
			u.efeitos.erase("sobrecarga")
			partes.append(["Sobrecarga Arcana ×2", dano])
			dano *= 2
		if ctx.get("metade", false):
			partes.append(["metade (Flecha de Rede)", -int(dano / 2)])
			dano -= int(dano / 2)
		var res := _resistencia_de(alvo)
		if alvo.categoria in ctx.get("ignora_res_contra", []):
			partes.append(["resistência ignorada (%s)" % ctx.get("habilidade", ""), 0])
			res = 0
		elif u.efeitos.has("ignora_reducao") or ctx.get("ignora_resistencia", false) or (u.eh_heroi() and u.arma.get("ignora_resistencia", false) and not magico):
			partes.append(["resistência ignorada", 0])
			res = 0
		elif u.ativo("folha-de-carvalho") and alvo.imobilizado():
			partes.append(["resistência ignorada (Folha de Carvalho)", 0])
			res = 0
		reducao = mini(res, dano)
		if res > 0:
			partes.append(["resistência", -res])
		dano = maxi(dano - res, 0)
		if u.efeitos.has("veneno_acido"):
			dano += 2
			partes.append(["Veneno Ácido", 2])
		var ferimentos := 0 if (alvo.eh_heroi() and alvo.ativo("ignorar-a-dor")) else alvo.fichas_total("Ferimento")
		if ferimentos > 0:
			dano += ferimentos
			partes.append(["Ferimento", ferimentos])
		var medo := u.fichas_total("Medo")
		if medo > 0:
			partes.append(["Medo", -mini(medo, dano)])
			dano = maxi(dano - medo, 0)
	if u.efeitos.has("ignora_reducao") or u.efeitos.has("veneno_acido"):
		u.efeitos.erase("ignora_reducao")
		u.efeitos.erase("veneno_acido")

	resultado = {"atacante": u.id, "defensor": alvo.id, "ataque": atk, "defesa": dfs, "acertou": acerto,
		"dano": dano, "partes": partes, "critico_ataque": teste_ataque.critico(), "critico_defesa": teste_defesa.critico(),
		"reacao": ""}

	if dano > 0:
		if not alvo.eh_heroi():
			_aplicar_dano_inimigo(alvo, dano)
			eventos.append({"tipo": "dano", "id": alvo.id, "valor": dano})
	elif not acerto:
		eventos.append({"tipo": "errou", "id": alvo.id})
	_log("%s %s %s: %d contra %d%s." % [u.nome, "acerta" if acerto else "erra", alvo.nome, atk, dfs,
		(", %d de dano" % dano) if dano > 0 else ""])

	if not u.eh_heroi() and acerto and alvo.viva():
		var efs_inimigo: Array = u.ao_acertar + ctx.get("ao_acertar", [])
		for ef in efs_inimigo:
			if ef.has("max") and alvo.fichas_total(ef["ficha"]) >= int(ef["max"]):
				continue
			if alvo.efeitos.has("hino"):
				_log("Hino de Coragem: %s não recebe %s." % [alvo.nome, ef["ficha"]])
				continue
			alvo.dar_ficha(ef["ficha"], int(ef.get("qtd", 1)))
			_log("%s põe %d ficha(s) de %s em %s." % [u.nome, int(ef.get("qtd", 1)), ef["ficha"], alvo.nome])
		if not efs_inimigo.is_empty():
			fichas_de_inimigo(alvo, u)
	if not u.eh_heroi() and alvo.eh_heroi():
		_reacao_ao_atacar(u, alvo, acerto)
	var primeiro_da_area := int(ctx.get("area_n", 0)) == 0
	if ctx.get("area", false) and dano > 0 and alvo.eh_heroi() and alvo.efeitos.has("metade_area"):
		alvo.efeitos.erase("metade_area")
		_log("Larápio: %s sofre só metade do ataque em área (%d → %d)." % [alvo.nome, dano, dano - int(dano / 2)])
		dano -= int(dano / 2)
		resultado["dano"] = dano
	elif ctx.get("area", false) and dano > 0 and alvo.eh_heroi() and _larapio_disponivel(alvo):
		# Larápio (Lucas, 0.20): o jogo pergunta na hora do dano em área.
		if perguntar_escolhas:
			larapio_pendente = {"id": alvo.id, "dano": dano}
	if ctx.get("area", false) and dano > 0:
		if not ctx.has("danificados"):
			ctx["danificados"] = []
		ctx["danificados"].append(alvo.id)
	if u.eh_heroi() and not alvo.eh_heroi():
		var just_a := zona_em(u.pos, "justica")
		if not just_a.is_empty() and alvo.pos in just_a["celulas"] and _zona_aliada(just_a, u):
			u.dar_ficha("Foco")
			_log("Halo da Justiça: %s ganha 1 ficha de Foco." % u.nome)
	if u.eh_heroi() and u.atributo("mentira") >= 3 and primeiro_da_area:
		_mentira_devolve(u, teste_ataque)
	if u.eh_heroi() and not magico and ctx.get("habilidade", "") != "Ataque de oportunidade":
		if u.arma.get("fica_no_alvo", false):
			_largar_arma(u, alvo.pos)
		elif u.arma.get("recarregar", false):
			u.efeitos["descarregada"] = {}
	if u.eh_heroi() and not alvo.eh_heroi():
		var sem: Dictionary = u.efeitos.get("sem_reacao_inimiga", {})
		var bloqueia: bool = not sem.is_empty() and (not sem.get("so_distancia", false) or u.a_distancia or Grade.distancia(u.pos, alvo.pos) > 1)
		if bloqueia:
			u.efeitos.erase("sem_reacao_inimiga")
			if not alvo.reacoes.is_empty():
				_log("%s não consegue reagir (%s)." % [alvo.nome, sem.get("nome", "")])
		else:
			_reacao_do_inimigo(alvo, u)
	if alvo.eh_heroi() and not acerto and alvo.destreza >= 5 and alvo.viva():
		resultado["passo"] = alvo.id
	if u.eh_heroi():
		_depois_do_ataque_do_heroi(u, alvo, acerto, dano)
		if reducao > 0 and u.ativo("foco-mortal"):
			u.carta_heroi().dar_ficha("Foco")
			_log("Foco Mortal: o dano foi reduzido, %s ganha 1 ficha de Foco." % u.nome)
		if ctx.get("imobilizar_se_dano", false) and dano > 0 and alvo.viva():
			alvo.fichas["Imobilizar"] = 1
			_log("%s fica imobilizado." % alvo.nome)
		if ctx.has("imobiliza_atacante"):
			ctx["imobiliza_atacante"].dar_ficha("Imobilizar")
			_log("%s fica imobilizado (ficha na carta Avalanche)." % u.nome)
		if ctx.get("depois_mover", 0) > 0:
			u.deslocamento += ctx["depois_mover"]
			_log("%s pode se mover %d quadrado sem gastar ação." % [u.nome, ctx["depois_mover"]])
		if not acerto and primeiro_da_area and not ctx.get("magico", false):
			_efeito_ao_errar(u)
	if alvo.eh_heroi() and not acerto:
		_defendeu_bem(alvo)
	if alvo.eh_heroi() and not u.eh_heroi() and resultado.get("reacao", "") == "" and u.viva():
		for h in herois_ativos():
			var c = h.carta_com("castigo")
			if h != alvo and c != null and c.pode_pagar(1) and h.acoes_reacao > 0 and Grade.adjacentes(h.pos, u.pos):
				resultado["reacao"] = "castigo"
				resultado["reator"] = h.id
				break
	for heroi in [u, alvo]:
		if heroi.eh_heroi() and (heroi != u or primeiro_da_area):
			var t := teste_ataque if heroi == u else teste_defesa
			if t.critico():
				_critico(heroi)
	fase = Fase.RESOLVIDO
	if dano > 0 and alvo.eh_heroi():
		_dano_no_heroi(alvo, dano, "ataque", Fase.RESOLVIDO)
	if not _verificar_fim():
		_oferecer_reacao()


## Reações dos heróis (Lucas, 0.19): quando uma pode ser usada, aparece a pergunta.
func _oferecer_reacao() -> void:
	if fase != Fase.RESOLVIDO or not perguntar_escolhas or reacao_disponivel() == "" or resultado.get("reacao_perguntada", false):
		return
	resultado["reacao_perguntada"] = true
	perguntar("reacao", texto_reacao() + "?", [["sim", "Reagir"], ["nao", "Não reagir"]])


## Braço de Labuta: +1 de Força (no dano e nos testes).
func _ajustar_forca(u: Unidade, delta: int) -> void:
	u.forca += delta
	u.atributos["forca"] = int(u.atributos.get("forca", 0)) + delta
	if Itens.atributo_da_arma(u.arma) == "forca":
		u.atributo_dano += delta


## Valor que um inimigo opõe a um teste ("vs Espírito", "vs Força"...): 2 cartas
## do baralho dos inimigos + o atributo dele.
func valor_resistido(o: Unidade, atributo: String) -> int:
	var total := 0
	for i in 2:
		var c := baralho_inimigos.puxar_topo()
		if c >= 0:
			total += 11 if Carta.eh_as(c) and total + 11 <= 21 else Carta.valor(c)
			baralho_inimigos.descartar([c] as Array[int])
	var at := 0
	if atributo in o:
		at = int(o.get(atributo))
	return total + at


func _gastou_sombra(u: Unidade) -> void:
	sombra_usada = true
	if u.ativo("sempre-uma-saida"):
		u.dar_ficha("Preparo")
		_log("Sempre uma Saída: gastar Sombra dá 1 ficha de Preparo.")


## Ação que não é de movimento (Fôlego de Viajante).
func _agiu(u: Unidade) -> void:
	u.so_moveu = false


func atributo_de_magia(u: Unidade) -> int:
	if not u.eh_heroi():
		return u.sabedoria
	return int(u.atributos.get(ATRIBUTO_MAGIA.get(u.classe, "sabedoria"), 0))


## Resistência com os bônus que dependem do campo (aliados, bênçãos).
func _resistencia_de(u: Unidade) -> int:
	var r := u.resistencia_total()
	r += int(u.efeitos.get("resistencia_extra", {}).get("valor", 0))
	if u.eh_heroi():
		r += int(u.foco.get("resistencia", 0))
		if u.ativo("ombro-a-ombro") and aliados_adjacentes(u, u.pos) > 0:
			r += 1
		if u.efeitos.has("bencao_dos_salmos"):
			r += 1
		if u.efeitos.has("circulo_de_protecao") and atacante != null and atacante.categoria in ["morto-vivo", "demonio"]:
			r += 2
		if u.ativo("resistencia-da-fe"):
			r += 1
		if u.efeitos.has("couro_grosso"):
			r += 1
		if u.efeitos.has("aguentem"):
			r += 1
		if int(u.escudo.get("vida", 0)) > 0:
			for h in herois_ativos():
				if h != u and Grade.adjacentes(h.pos, u.pos) and int(h.escudo.get("vida", 0)) > 0 and (u.ativo("parede-de-escudos") or h.ativo("parede-de-escudos")):
					r += 2
					break
	return r


## Bônus de dano de cartas e efeitos do atacante (herói), já com rótulo.
func _bonus_de_dano(u: Unidade, alvo: Unidade, acerto: bool) -> Array:
	var lista := []
	if not u.eh_heroi():
		var bc: Dictionary = u.efeitos.get("bonus_contra", {})
		if bc.get("id", "") == alvo.id:
			u.efeitos.erase("bonus_contra")
			lista.append(["reação", int(bc["valor"])])
		var insp: Dictionary = u.efeitos.get("inspirado", {})
		if not insp.is_empty():
			u.efeitos.erase("inspirado")
			lista.append([insp.get("nome", "inspirado"), int(insp["valor"])])
		return lista
	var magico: bool = ctx.get("magico", false)
	var sombras := u.fichas_total("Sombra")
	if u.ativo("lamina-na-manga") and sombras > 0 and not magico:
		lista.append(["Lâmina na Manga", sombras])
	if u.ativo("bote-fatal") and sombras > 0 and not magico and not u.a_distancia:
		alvo.dar_ficha("Ferimento", sombras)
	if u.ativo("presa-ferida") and u.a_distancia and not magico:
		var tipos := 0
		if not alvo.eh_heroi():
			tipos = alvo.fichas.size()
		if tipos > 0:
			lista.append(["Presa Ferida", tipos])
	if magico and u.ativo("poder-de-combate"):
		lista.append(["Poder de Combate", 2])
	if magico and u.efeitos.has("mente_belica"):
		u.efeitos.erase("mente_belica")
		lista.append(["Mente Bélica", 3])
	if not magico and u.efeitos.has("arma_encantada"):
		lista.append(["arma encantada", int(u.efeitos["arma_encantada"].get("valor", 0))])
	if acerto and ctx.has("bonus_dano"):
		lista.append([ctx.get("rotulo_bonus", "habilidade"), int(ctx["bonus_dano"])])
	if acerto:
		for extra in ctx.get("bonus_extra", []):
			lista.append(extra)
	if u.efeitos.has("sede_de_sangue") and not u.a_distancia and not magico:
		lista.append(["Sede de Sangue", 2])
	if u.ativo("o-oportunista") and ["Penalidade", "Confusão", "Cegueira", "Medo"].any(func(f): return alvo.fichas_total(f) > 0):
		lista.append(["O Oportunista", 2])
	var horda := herois_ativos().any(func(h): return h.ativo("brado-da-horda") and Grade.distancia(h.pos, u.pos) <= 4)
	if horda and herois_ativos().filter(func(h): return Grade.adjacentes(h.pos, alvo.pos)).size() >= 2:
		lista.append(["Brado da Horda (cercado)", 1])
	return lista


## Efeitos depois do ataque de um herói: fichas no alvo, Mira, empurrões...
func _depois_do_ataque_do_heroi(u: Unidade, alvo: Unidade, acerto: bool, dano: int) -> void:
	Extras.depois_do_ataque(self, u, alvo, acerto)
	if acerto:
		for ef in ctx.get("ao_acertar", []):
			if ef.has("ficha") and alvo.viva():
				alvo.dar_ficha(ef["ficha"], int(ef.get("qtd", 1)))
				_log("%s recebe %d ficha(s) de %s." % [alvo.nome, int(ef.get("qtd", 1)), ef["ficha"]])
			if ef.has("empurrar") and alvo.viva():
				_empurrar(alvo, u.pos, int(ef["empurrar"]))
			if ef.get("derrubar", false) and alvo.viva():
				derrubar(alvo)
			if ef.get("desarmar", false) and alvo.viva():
				desarmar(alvo)
		if ctx.get("sem_cura_ao_acertar", false) and alvo.viva():
			alvo.efeitos["sem_cura"] = {"ate_turno_de": u.id}
			_log("Golpe da Punição: %s não pode se curar até o próximo turno de %s." % [alvo.nome, u.nome])
		var adi: Dictionary = ctx.get("ao_dano_inimigo", {})
		if not adi.is_empty() and dano > 0 and not alvo.eh_heroi() and alvo.viva():
			if int(adi.get("dano", 0)) > 0:
				_dano_direto(alvo, int(adi["dano"]), adi.get("rotulo", "efeito"))
			if int(adi.get("empurrar", 0)) > 0 and alvo.viva():
				_empurrar(alvo, u.pos, int(adi["empurrar"]))
		if u.a_distancia and not ctx.get("magico", false) and u.ativo("folha-de-carvalho"):
			u.dar_ficha("Mira")
			_log("Folha de Carvalho: %s ganha 1 ficha de Mira." % u.nome)
	if dano > 0 and alvo.viva():
		if u.efeitos.has("torcer_a_lamina") and not u.a_distancia:
			u.efeitos.erase("torcer_a_lamina")
			alvo.dar_ficha("Sangramento")
			_log("Torcer a Lâmina: %s começa a sangrar." % alvo.nome)
		if u.efeitos.has("folha_imobilizar"):
			u.efeitos.erase("folha_imobilizar")
			alvo.dar_ficha("Imobilizar")
			_log("Folha de Carvalho: %s fica imobilizado." % alvo.nome)
		if u.efeitos.has("folha_ferimento"):
			u.efeitos.erase("folha_ferimento")
			alvo.dar_ficha("Ferimento")
			_log("Folha de Carvalho: %s recebe 1 Ferimento." % alvo.nome)
	if ctx.get("marcar_depois", false) and alvo.viva():
		alvo.dar_ficha("Marcado")
		_log("%s fica marcado." % alvo.nome)
	if ctx.get("atordoa_no_critico", false) and teste_ataque.critico() and alvo.viva():
		alvo.dar_ficha("Atordoamento")
		_log("Crítico: %s fica atordoado." % alvo.nome)
	if ctx.has("virar_depois"):
		_virar(u, ctx["virar_depois"])
	if not alvo.viva() and ctx.has("ao_matar"):
		var am: Dictionary = ctx["ao_matar"]
		u.acoes_padrao += int(am.get("padrao", 0))
		if am.has("ficha"):
			u.dar_ficha(am["ficha"])
		_log("%s: o alvo caiu, %s ganha uma ação Padrão e 1 ficha de Mira." % [ctx.get("habilidade", ""), u.nome])


## Dano direto num inimigo (sem teste e sem redução).
## Dano de impacto (empurrão): no herói, o escudo e depois a armadura seguram
## primeiro (a sugestão de distribuição, sem abrir a janela); o resto vai ao baralho.
func _dano_de_impacto(u: Unidade, dano: int, fonte: String) -> void:
	if not u.eh_heroi():
		_dano_direto(u, dano, fonte)
		return
	var esc := mini(u.vida_escudo, dano)
	u.vida_escudo -= esc
	var arm := mini(u.vida_armadura, dano - esc)
	u.vida_armadura -= arm
	var resto := dano - esc - arm
	if esc + arm > 0:
		_log("%s: o escudo segura %d e a armadura %d." % [fonte, esc, arm])
	if resto > 0:
		_dano_direto(u, resto, fonte)


## Dano no baralho do herói. Diplomacia 5: com o baralho zerado, o dano no
## descarte exila só metade das cartas (arredondando para cima).
func _dano_no_baralho(u: Unidade, pontos: int) -> void:
	if u.atributo("diplomacia") >= 5 and u.baralho.baralho.is_empty() and pontos > 1:
		_log("Diplomacia 5: %s, inconsciente, exila só metade (%d → %d)." % [u.nome, pontos, pontos - int(pontos / 2)])
		pontos -= int(pontos / 2)
	u.baralho.sofrer_dano(pontos)


func _dano_direto(alvo: Unidade, dano: int, fonte: String) -> void:
	if alvo.eh_heroi():
		_dano_no_baralho(alvo, dano)
		_log("%s: %s perde %d carta(s)." % [fonte, alvo.nome, dano])
		eventos.append({"tipo": "dano", "id": alvo.id, "valor": dano})
		_verificar_queda_heroi_sem_turno(alvo)
		return
	if alvo.fraquezas.has(fonte):
		dano += int(alvo.fraquezas[fonte])
		_descobrir(alvo, "fraquezas", fonte, int(alvo.fraquezas[fonte]))
		_log("%s é fraco contra %s: +%d." % [alvo.nome, fonte, int(alvo.fraquezas[fonte])])
	_aplicar_dano_inimigo(alvo, dano)
	_log("%s: %d de dano em %s." % [fonte, dano, alvo.nome])
	eventos.append({"tipo": "dano", "id": alvo.id, "valor": dano})


## Empurra "alvo" para longe de "origem", quadrado a quadrado, enquanto houver espaço.
func _empurrar(alvo: Unidade, origem: Vector2i, n: int, dano_batida := -1) -> void:
	var d := alvo.pos - origem
	var dir := Vector2i(signi(d.x), signi(d.y))
	if dir == Vector2i.ZERO:
		return
	var caminho := []
	var batida: Unidade = null
	for i in n:
		var q := alvo.pos + dir
		if not grade.dentro(q) or grade.bloqueado(q) or na_posicao(q) != null:
			batida = na_posicao(q) if grade.dentro(q) else null
			break
		alvo.pos = q
		caminho.append(q)
	if not caminho.is_empty():
		eventos.append({"tipo": "mover", "id": alvo.id, "caminho": caminho})
		_log("%s é empurrado %d quadrado(s)." % [alvo.nome, caminho.size()])
	# Bateu antes de terminar: 2 de dano por quadrado que faltou (em quem bateu e em quem foi atingido).
	var faltou := n - caminho.size()
	if faltou > 0 and alvo.viva():
		var dano_b := 2 * faltou if dano_batida < 0 else dano_batida
		var q_bate := alvo.pos + dir
		var muro := muro_em(q_bate)
		_dano_de_impacto(alvo, dano_b, "Empurrão (bateu em %s)" % (batida.nome if batida != null else (muro["nome"] if not muro.is_empty() else "um obstáculo")))
		if batida != null and batida.viva():
			_dano_de_impacto(batida, dano_b, "Empurrão (%s bateu nele)" % alvo.nome)
		elif not muro.is_empty():
			dano_no_muro(muro, dano_b, "%s bateu nele" % alvo.nome)


func _nome_atributo_dano(u: Unidade) -> String:
	if not u.eh_heroi():
		return "Destreza" if u.a_distancia else "Força"
	return {"destreza": "Destreza", "forca": "Força", "nenhum": "—"}.get(Itens.atributo_da_arma(u.arma), "Força")


func _efeito_ao_errar(u: Unidade) -> void:
	match u.arma.get("peso", ""):
		"leve":
			var usadas := teste_ataque.cartas.filter(func(c): return c in u.baralho.descarte)
			if not usadas.is_empty():
				var c: int = usadas[0]
				u.baralho.descarte.erase(c)
				u.baralho.baralho.insert(0, c)
				_log("Arma leve: ao errar, %s devolve uma carta do ataque ao baralho." % u.nome)
		"pesada":
			var c := u.baralho.puxar_topo()
			if c >= 0:
				u.baralho.descarte.append(c)
			u.efeitos["lento"] = {"ate": "fim_proximo_turno", "turnos": 2}
			_log("Arma pesada: ao errar, %s tritura 1 carta e fica com Velocidade −1." % u.nome)
			_verificar_queda_heroi_sem_turno(u)


func _defendeu_bem(u: Unidade) -> void:
	var usadas := teste_defesa.cartas.filter(func(c): return c in u.baralho.descarte)
	if not usadas.is_empty():
		var classe: String = u.armadura.get("classe", "nenhuma")
		if classe == "nenhuma" or (classe == "leve" and u.vida_armadura > 0):
			var c: int = usadas[0] if classe == "nenhuma" else usadas[rng.randi_range(0, usadas.size() - 1)]
			u.baralho.descarte.erase(c)
			u.baralho.baralho.insert(0, c)
			_log("%s: ao se defender bem, uma carta da defesa volta ao baralho." % ("Sem armadura" if classe == "nenhuma" else u.armadura["nome"]))
	var c = u.carta_com("postura-da-cascavel")
	if c != null and c.pode_pagar(1) and u.acoes_reacao > 0 and atacante.viva():
		resultado["reacao"] = "postura-da-cascavel"


func _critico(u: Unidade) -> void:
	_log("21 natural: crítico de %s!" % u.nome)
	var h = u.carta_heroi()
	if h == null:
		return
	match h.slug():
		"foco-mortal":
			for c in u.cartas:
				c.dar_ficha("Foco")
			_log("Foco Mortal: uma ficha de Foco em cada carta.")
		"a-muralha":
			u.vida_armadura = int(u.armadura.get("vida", 0))
			u.vida_escudo = int(u.escudo.get("vida", 0))
			_log("A Muralha: armadura e escudo totalmente reparados.")
		"incansavel":
			_curar(u, u.constituicao, "recupera o fôlego (crítico)")
			for c in u.cartas:
				c.fadiga = maxi(c.fadiga - 1, 0)
			_log("Incansável: −1 de fadiga em cada carta.")
		"tomar-a-posicao":
			h.dar_ficha("Preparo")
			h.dar_ficha("Foco")
			_log("Tomar a Posição: 1 ficha de Preparo e 1 de Foco na carta de herói.")
		"ombro-a-ombro":
			h.dar_ficha("Guarda")
			for o in herois_ativos():
				if o != u and Grade.adjacentes(o.pos, u.pos):
					o.dar_ficha("Guarda")
			_log("Ombro a Ombro: 1 ficha de Guarda para você e cada aliado adjacente.")
		_:
			Classes.critico(self, u, h.slug())


# --- Dano no herói: o jogador distribui -------------------------------------
##
## O dano (já reduzido pela resistência) vai para escudo, armadura e baralho na
## proporção que o jogador escolher. Escudo e armadura só recebem até a vida que
## têm. A Cota de Malha ainda não salva na cena aceita o dano todo (fica com 1).
## A ficha de Bloqueio corta o dano à metade antes da escolha.

## Começa a distribuição. "volta": a fase depois de distribuir.
var larapio_pendente := {}


func _larapio_disponivel(h: Unidade) -> bool:
	var c = h.carta_heroi()
	return c != null and c.slug() == "larapio" and pode_pagar_fadiga(h, c, 2)


func _dano_no_heroi(u: Unidade, dano: int, origem: String, volta: Fase) -> void:
	if not larapio_pendente.is_empty() and larapio_pendente["id"] == u.id and origem == "ataque":
		larapio_pendente = {}
		perguntar("larapio", "Larápio: %s vai sofrer %d de dano deste ataque em área. Pagar 2 de fadiga para sofrer só metade (%d)?" % [u.nome, dano, dano - int(dano / 2)],
			[["sim", "Sim, pagar 2 de fadiga"], ["nao", "Não"]], {"quem": u.id, "dano": dano, "origem": origem, "volta": volta})
		return
	_dano_no_heroi_agora(u, dano, origem, volta)


func _dano_no_heroi_agora(u: Unidade, dano: int, origem: String, volta: Fase) -> void:
	var resto := dano
	for c in u.cartas:
		if resto > 0 and c.tirar_ficha("Bloqueio"):
			resto = int(ceil(resto / 2.0))
			_log("Ficha de Bloqueio: o dano cai pela metade (%d)." % resto)
			break
	dano_pendente = {"id": u.id, "dano": resto, "origem": origem, "volta": volta}
	var lim := limites_distribuicao()
	if not dano_na_armadura or (lim["escudo"] == 0 and lim["armadura"] == 0):
		_aplicar_distribuicao(0, 0)
	elif distribuicao_automatica:
		var s := sugestao_distribuicao()
		_aplicar_distribuicao(s["escudo"], s["armadura"])
	else:
		fase = Fase.DISTRIBUINDO_DANO


## Quanto cabe em cada destino agora.
func limites_distribuicao() -> Dictionary:
	if dano_pendente.is_empty():
		return {"escudo": 0, "armadura": 0}
	var u := unidade(dano_pendente["id"])
	var d: int = dano_pendente["dano"]
	# Cota de Malha (Lucas, 0.20): a armadura só recebe até a vida que tem; o efeito é só
	# voltar para 1 na primeira vez que chega a 0.
	var arm := mini(u.vida_armadura, d)
	return {"escudo": mini(u.vida_escudo, d), "armadura": arm}


## Sugestão (a ordem da 0.5): escudo, depois armadura, depois baralho.
func sugestao_distribuicao() -> Dictionary:
	var lim := limites_distribuicao()
	var d: int = dano_pendente.get("dano", 0)
	var e := mini(lim["escudo"], d)
	var a := mini(lim["armadura"], d - e)
	return {"escudo": e, "armadura": a, "vida": d - e - a}


func heroi_distribuir_dano(escudo: int, armadura: int) -> bool:
	if fase != Fase.DISTRIBUINDO_DANO:
		return false
	var lim := limites_distribuicao()
	var d: int = dano_pendente["dano"]
	if escudo < 0 or armadura < 0 or escudo > lim["escudo"] or armadura > lim["armadura"] or escudo + armadura > d:
		return false
	_aplicar_distribuicao(escudo, armadura)
	return true


func _cota_disponivel(u: Unidade) -> bool:
	return u.armadura.get("nome", "") == "Cota de Malha" and not u.armadura_salvou_na_cena


func _aplicar_distribuicao(escudo: int, armadura: int) -> void:
	var u := unidade(dano_pendente["id"])
	var d: int = dano_pendente["dano"]
	var vida := d - escudo - armadura
	if escudo > 0:
		u.vida_escudo -= escudo
		if u.vida_escudo == 0:
			_log("O escudo de %s quebrou." % u.nome)
	if armadura > 0:
		if armadura >= u.vida_armadura and _cota_disponivel(u):
			u.armadura_salvou_na_cena = true
			u.vida_armadura = 1
			_log("Cota de Malha: confiável, a armadura fica com 1 de vida em vez de quebrar.")
		else:
			u.vida_armadura -= armadura
			if u.vida_armadura == 0:
				_log("A armadura de %s quebrou." % u.nome)
	if (escudo > 0 or armadura > 0) and u.ativo("a-muralha"):
		u.carta_heroi().dar_ficha("Guarda")
	if vida > 0:
		_dano_no_baralho(u, vida)
	if d > 0:
		_furia(u)
	var dist := {"escudo": escudo, "armadura": armadura, "vida": vida}
	_log("%s distribui %d de dano: escudo %d · armadura %d · baralho %d." % [u.nome, d, escudo, armadura, vida])
	if dano_pendente["origem"] == "ataque":
		resultado["distribuicao"] = dist
	eventos.append({"tipo": "dano", "id": u.id, "valor": d})
	var volta: Fase = dano_pendente["volta"]
	dano_pendente = {}
	fase = volta
	if volta == Fase.RESOLVIDO and u.viva():
		_oferecer_reacao()
	if u.viva():
		return
	if volta == Fase.HEROI_ESCOLHE and ativa() == u:
		_verificar_queda_heroi(u)
	else:
		_verificar_queda_heroi_sem_turno(u)
		_verificar_fim()


func _aplicar_dano_inimigo(u: Unidade, dano: int) -> void:
	var estava_vivo := u.vida > 0
	if dano > 0 and u.efeitos.has("postura_defensiva"):
		dano = ceili(dano / 2.0)
		_log("%s está em guarda: sofre só metade (%d)." % [u.nome, dano])
	if dano > 0 and u.protegido_por.any(func(id): return unidade(id) != null and unidade(id).viva()):
		dano = ceili(dano / 2.0)
		_log("%s está protegido: sofre só metade (%d). Destruam o que o protege!" % [u.nome, dano])
	if dano > 0:
		u.efeitos["engajou"] = {}
	u.vida = maxi(u.vida - dano, 0)
	if dano > 0 and atacante != null and atacante.eh_heroi():
		_furia(atacante)
	if u.vida == 0 and estava_vivo:
		_log("%s cai." % u.nome)
		eventos.append({"tipo": "morte", "id": u.id})
		_desativar_interacao_da_unidade(u.id)
		_inimigo_caiu(u)
		_reacao_ao_morrer(u)


func _furia(h: Unidade) -> void:
	var c = h.carta_com("furia-crescente")
	if c != null:
		c.dar_ficha("Fúria")


## Desencadeadas quando um inimigo cai.
func _inimigo_caiu(o: Unidade) -> void:
	for h in herois_ativos():
		if h.ativo("sede-de-sangue") and Grade.distancia(h.pos, o.pos) <= 4:
			h.efeitos["sede_de_sangue"] = {"turnos": 2}
			_log("Sede de Sangue: %s causa +2 de dano corpo a corpo até o fim do próximo turno." % h.nome)
		if h.ativo("brado-da-horda"):
			_curar(h, 3, "ruge com a queda do inimigo")
			_tirar_fadiga(h, 3)
	if atacante != null and atacante.eh_heroi() and atacante.ativo("matador-de-gigante") and Origens.maior(o, atacante):
		for h in herois_ativos():
			h.dar_ficha("Foco")
			h.dar_ficha("Preparo")
		_log("Matador de Gigante: o grupo ganha Foco e Preparo.")


func _curar(u: Unidade, pontos: int, verbo: String) -> void:
	if u.ativo("o-sobrevivente"):
		pontos += 1
	if conjurando != null and conjurando.foco.get("id", "") == "calice_da_vida":
		pontos += 1
		_log("Cálice da Vida: a magia cura 1 a mais.")
	if u.eh_heroi() and u.constituicao >= 5 and not u.baralho.exilio.is_empty():
		var do_exilio := 0
		while do_exilio < pontos and not u.baralho.exilio.is_empty():
			u.baralho.baralho.insert(0, u.baralho.exilio.pop_back())
			do_exilio += 1
		var resto := u.baralho._devolver_do_descarte(pontos - do_exilio) if pontos > do_exilio else 0
		u.baralho._verificar_queda()
		_log("%s %s: %d voltam do exílio e %d do descarte (Constituição 5)." % [u.nome, verbo, do_exilio, resto])
		eventos.append({"tipo": "cura", "id": u.id, "valor": do_exilio + resto})
		return
	var voltaram := u.baralho.curar(pontos)
	_log("%s %s: 1 carta exilada, %d voltam ao baralho." % [u.nome, verbo, voltaram])
	eventos.append({"tipo": "cura", "id": u.id, "valor": voltaram})


func _tirar_fadiga(u: Unidade, qtd: int) -> int:
	var tirada := 0
	for i in qtd:
		var maior = null
		for c in u.cartas:
			if c.fadiga > 0 and (maior == null or c.fadiga > maior.fadiga):
				maior = c
		if maior == null:
			break
		maior.fadiga -= 1
		tirada += 1
	return tirada


# --- Interações no mapa (exploração) ----------------------------------------
##
## Cada ponto de interação tem uma posição, um texto e opções. Uma opção pode
## pedir um teste de atributo (21 com o atributo como modificador; a perícia
## entra quando existir) e traz faixas de resultado: o valor do teste escolhe
## o resultado, e cada resultado aplica efeitos. Sem teste, aplica direto.
## Testes de movimento sofrem a penalidade de armadura (limite 19 na média,
## 17 na pesada). Itens dão vantagem, são exigidos ou são gastos.

const NOMES_ATRIBUTO := {"forca": "Força", "destreza": "Destreza", "constituicao": "Constituição", "percepcao": "Percepção",
	"sabedoria": "Sabedoria", "raciocinio": "Raciocínio", "espirito": "Espírito", "mentira": "Mentira", "diplomacia": "Diplomacia"}


func interacao(id: String) -> Dictionary:
	for it in interacoes:
		if it["id"] == id:
			return it
	return {}


func interacoes_ativas() -> Array:
	return interacoes.filter(func(it): return it.get("ativa", true))


func interacao_em(p: Vector2i) -> Dictionary:
	for it in interacoes_ativas():
		if it["pos"] == p:
			return it
	return {}


func ao_alcance(u: Unidade, it: Dictionary) -> bool:
	return Grade.distancia(u.pos, it["pos"]) <= int(it.get("alcance", 1))


func opcao_da_interacao(it: Dictionary, opcao_id: String) -> Dictionary:
	for op in it["opcoes"]:
		if op["id"] == opcao_id:
			return op
	return {}


func _movimentos_disponiveis(u: Unidade) -> int:
	if preso(u):
		return 0
	return u.acoes_mov + u.acoes_padrao


func motivo_sem_opcao(u: Unidade, it: Dictionary, op: Dictionary) -> String:
	if not vez_do_heroi() or ativa() != u:
		return "não é a sua vez"
	if u.efeitos.has("confuso"):
		return "confuso: só pode ir atrás do alvo e atacá-lo"
	if not ao_alcance(u, it) or (op.has("alcance") and Grade.distancia(u.pos, it["pos"]) > int(op["alcance"])):
		return "chegue mais perto"
	# Opções de classe e de carta (0.23): só quem tem a carta (lado ativo) ou a classe.
	if op.has("requer_carta") and not op["requer_carta"].any(func(sl): return u.ativo(sl)):
		return "só quem tem %s" % " ou ".join(PackedStringArray(op["requer_carta"].map(func(sl): return preload("res://core/catalogo.gd").habilidade_por_slug(sl))))
	if op.has("requer_classe") and not u.classe in op["requer_classe"]:
		return "só %s" % " ou ".join(PackedStringArray(op["requer_classe"]))
	if op.has("requer_combates") and combates_vencidos() < int(op["requer_combates"]):
		return "seguro só depois de vencer %d combates (vocês venceram %d)" % [int(op["requer_combates"]), combates_vencidos()]
	var custo: Dictionary = op.get("custo", {})
	if custo.get("turno", false) and (u.acoes_mov < 1 or u.acoes_padrao < 2):
		return "precisa do turno inteiro (Movimento e 2 Padrão)"
	if u.acoes_padrao < int(custo.get("padrao", 0)) and u.efeitos.get("interacoes_gratis", {}).get("valor", 0) == 0:
		return "sem ação Padrão"
	if custo.has("movimento"):
		if preso(u):
			return "imobilizado"
		if _movimentos_disponiveis(u) < int(custo["movimento"]):
			return "precisa de %d ações de movimento" % int(custo["movimento"])
	if op.has("requer") and not u.tem_item(op["requer"]):
		return "precisa de %s" % _nome_item(op["requer"])
	if op.has("consome") and not u.tem_item(op["consome"]):
		return "sem %s" % _nome_item(op["consome"])
	for comp in op.get("exige", {}):
		if valor_componente(u, comp) < int(op["exige"][comp]):
			return "precisa de %s %d" % [nome_componente(comp), int(op["exige"][comp])]
	if op.get("travessia", false) and destino_travessia(u, it) == Vector2i(-1, -1):
		return "fique na beira, de frente para o outro lado"
	var sem_alerta = op.get("sem_alerta", false)
	if sem_alerta is String or (sem_alerta is bool and sem_alerta):
		var grupo_alerta: String = sem_alerta if sem_alerta is String else ""
		for o in inimigos_vivos():
			if o.alerta and (grupo_alerta == "" or o.grupo == grupo_alerta):
				return "há inimigos em alerta"
	if op.has("sem_inimigos_perto") and inimigo_perto(it["pos"], int(op["sem_inimigos_perto"])):
		return "há inimigos por perto: limpe a área antes"
	if op.has("sem_inimigos_perto") and heroi_em_combate() != "":
		return heroi_em_combate()
	return ""


## Lucas (0.20): um herói está em combate se é o alvo de algum inimigo no próximo turno
## (inimigo em alerta que escolheria atacá-lo). Devolve o motivo, ou "".
func heroi_em_combate() -> String:
	for o in inimigos_vivos():
		if not o.alerta:
			continue
		var alvo := _escolher_alvo(o)
		if alvo != null:
			return "%s está em combate (%s vai atrás dele)" % [alvo.nome, nome_visto(o)]
	return ""


# --- Pontos de descanso e salvar no meio da missão (Lucas, 0.19) -------------------
##
## Ponto de descanso: interação com "descanso": true (um símbolo no chão). Só abre sem
## inimigos vivos por perto (opção "sem_inimigos_perto": raio). Descansar faz o descanso
## curto do grupo e libera salvar o jogo ali (ui/janela_saves.gd + core/instantaneo.gd).

const RAIO_DESCANSO_SEGURO := 9
var descansos_usados := {}   # id da interação -> true


## Pedra alta (0.19): quem está em cima ataca com vantagem quem está embaixo.
func no_alto(u: Unidade) -> bool:
	return grade.obstaculos.get(u.pos, "") == "pedra_alta"


## Fichas em heróis (0.20): para onde a ficha pode ir (cartas sem esse tipo) e mover.
func cartas_para_ficha(u: Unidade, ficha: String, atual: int) -> Array:
	var lista := [atual]
	for i in u.cartas.size():
		if i != atual and u.cartas[i].pode_receber(ficha):
			lista.append(i)
	return lista


func mover_ficha(u: Unidade, ficha: String, de: int, para: int) -> bool:
	if de == para:
		return true
	if de < 0 or para < 0 or de >= u.cartas.size() or para >= u.cartas.size():
		return false
	if not u.cartas[de].tem_ficha(ficha) or not u.cartas[para].pode_receber(ficha):
		return false
	u.cartas[de].tirar_ficha(ficha)
	u.cartas[para].dar_ficha(ficha)
	_log("%s põe a ficha de %s em %s." % [u.nome, ficha, u.cartas[para].nome()])
	return true


## Coloca uma ficha numa carta escolhida pelo jogador (pergunta "ficha_carta").
func _por_ficha_na_carta(u: Unidade, c, ficha: String) -> void:
	if c.pode_receber(ficha):
		c.dar_ficha(ficha)


func inimigo_perto(p: Vector2i, raio: int) -> bool:
	for o in inimigos_vivos():
		if Grade.distancia(o.pos, p) <= raio:
			return true
	return false


## O ponto de descanso está liberado (sem inimigos por perto)?
func descanso_liberado(it: Dictionary) -> bool:
	return not inimigo_perto(it["pos"], RAIO_DESCANSO_SEGURO) and heroi_em_combate() == ""


## Pode salvar agora? "" = sim. Na vez de um herói, perto de um ponto de descanso já
## usado, sem inimigos por perto nem em alerta.
func motivo_salvar() -> String:
	if fase != Fase.HEROI_ESCOLHE or not vez_do_heroi():
		return "Só dá para salvar na vez de um herói, sem nada acontecendo."
	if exploracao_livre and not inimigos_vivos().any(func(o): return o.alerta):
		return ""   # vila andável: salva em qualquer lugar
	for o in inimigos_vivos():
		if o.alerta:
			return "Há inimigos em alerta."
	for it in interacoes:
		if it.get("descanso", false) and descansos_usados.has(it["id"]):
			for h in herois_ativos():
				if Grade.distancia(h.pos, it["pos"]) <= 3:
					return "" if descanso_liberado(it) else "Há inimigos por perto do ponto de descanso."
	return "Para salvar no meio da missão, descanse num ponto de descanso (o símbolo no chão) e fique perto dele."


## "dificuldade" vira duas faixas: falha abaixo, sucesso a partir dela (o valor
## alvo; atingir já basta).
## Escala de dificuldade: a seco (só cartas) vai de muito fácil 12 a muito
## difícil 20; cada componente (atributo ou perícia) soma +3.
const NIVEIS := {"muito_facil": 12, "facil": 14, "medio": 16, "dificil": 18, "muito_dificil": 20}
const NOMES_NIVEL := {"muito_facil": "muito fácil", "facil": "fácil", "medio": "médio", "dificil": "difícil", "muito_dificil": "muito difícil"}


static func dificuldade_do_nivel(nivel: String, componentes: int) -> int:
	return int(NIVEIS[nivel]) + 3 * clampi(componentes, 0, 2)


static func _normalizar_teste(op: Dictionary) -> void:
	var n := componentes_do_teste(op.get("teste", {})).size()
	if op.has("nivel") and not op.has("dificuldade"):
		op["dificuldade"] = dificuldade_do_nivel(op["nivel"], n)
	if op.has("dificuldade") and not op.has("faixas"):
		op["faixas"] = [[0, "falha"], [int(op["dificuldade"]), "sucesso"]]
	for f in op.get("faixas", []):
		if f[0] is String:
			f[0] = dificuldade_do_nivel(f[0], n)


## O que soma no teste: atributos e/ou perícias. Aceita {"somar": [...]} ou o
## formato antigo {"atributo", "pericia"}.
static func componentes_do_teste(t: Dictionary) -> Array:
	if t.has("somar"):
		return t["somar"]
	var lista := []
	if t.has("atributo"):
		lista.append(t["atributo"])
	if t.has("pericia"):
		lista.append(t["pericia"])
	return lista


static func nome_componente(c: String) -> String:
	return NOMES_ATRIBUTO.get(c, c)


func valor_componente(u: Unidade, c: String) -> int:
	var v := int(u.atributos.get(c, 0)) if NOMES_ATRIBUTO.has(c) else int(u.pericias.get(c, 0))
	# Escolhas da criação (Mente Maleável, Aprendiz Silencioso, Mil Ofícios...).
	for chave in u.escolhas:
		var e: Dictionary = Personagem.ESCOLHAS.get(chave, {})
		if e.has("bonus") and c in u.escolhas[chave] and u.ativo(e.get("carta", chave)):
			v += int(e["bonus"])
	if u.ativo("erudito-das-estradas") and c in ["História", "Natureza", "Investigação"]:
		v += 1
	return v


## Tipo de um atributo ou perícia: "fisico", "mental" ou "social".
static func tipo_componente(c: String) -> String:
	if c in ["forca", "destreza", "constituicao"]:
		return "fisico"
	if c in ["percepcao", "sabedoria", "raciocinio"]:
		return "mental"
	if c in ["espirito", "mentira", "diplomacia"]:
		return "social"
	for grupo in Personagem.PERICIAS:
		if c in Personagem.PERICIAS[grupo]:
			return {"Físico": "fisico", "Mental": "mental", "Social": "social"}[grupo]
	return ""


func _usa(t: Dictionary, nomes: Array) -> bool:
	for c in componentes_do_teste(t):
		if c in nomes:
			return true
	return false


func tem_vantagem_na_opcao(u: Unidade, op: Dictionary) -> String:
	for item in op.get("vantagem_com", []):
		if u.tem_item(item):
			return item
	var t: Dictionary = op.get("teste", {})
	if u.efeitos.has("fe_inabalavel") and _usa(t, ["espirito", "sabedoria"]):
		return "Fé Inabalável"
	if u.ativo("de-volta-ao-basico") and _usa(t, ["raciocinio", "percepcao", "sabedoria"]):
		return "De Volta ao Básico"
	var tags: Array = op.get("tags", [])
	if op.get("teste", {}).get("movimento", false):
		for h in herois_ativos():
			if h.ativo("conhecedor-do-terreno") and Grade.distancia(h.pos, u.pos) <= 4:
				return "Conhecedor do Terreno"
	var por_carta := {
		"visao-elfica": ["percepcao"], "heranca-feerica": ["Arcanismo", "Intuição"],
		"memoria-ancestral": ["História", "Política", "Religião"], "passos-leves": ["Furtividade"], "maos-leves": ["Furtividade", "Ladinagem"],
		"coragem-miuda": ["espirito"], "atento-aos-desejos": ["Intuição"], "passar-despercebido": ["Atuação"],
	}
	for slug in por_carta:
		if u.ativo(slug) and _usa(t, por_carta[slug]):
			return preload("res://core/catalogo.gd").habilidade_por_slug(slug)
	if u.ativo("olho-para-o-minerio") and "caverna" in tags and _usa(t, ["percepcao", "sabedoria"]):
		return "Olho para o Minério"
	if u.ativo("giria-dos-ladroes") and "criminosos" in tags:
		return "Gíria dos Ladrões"
	if u.ativo("postura-firme") and "comando" in tags and _usa(t, ["diplomacia", "Intimidação"]):
		return "Postura Firme"
	return ""


func limite_do_teste(u: Unidade, op: Dictionary) -> int:
	var t: Dictionary = op.get("teste", {})
	var lim := 21 - u.fichas_total("Penalidade") + int(op.get("manobra_limite", 0))
	var louvor := zona_em(u.pos, "louvor")
	if not louvor.is_empty() and _zona_aliada(louvor, u):
		lim += 1
	if u.ativo("impostor") and _usa(t, ["mentira"]):
		lim = 23
	if u.ativo("teologia") and _usa(t, ["Religião"]):
		lim += 1
	if u.ativo("saber-sagrado") and _usa(t, ["Religião", "História"]):
		lim += 2
	if u.ativo("forasteiro-bem-vindo") and "novo_local" in op.get("tags", []) and _usa(t, ["diplomacia"]):
		lim += 2
	var maestria: Array = u.escolhas.get("maestria-de-uma-vida", [])
	if u.ativo("maestria-de-uma-vida") and not maestria.is_empty() and _usa(t, maestria):
		lim += 2
	if not t.get("movimento", false) or u.efeitos.has("trabalhador"):
		return lim
	match u.armadura.get("classe", "nenhuma"):
		"media":
			return lim - 2
		"pesada":
			return lim - 4
	return lim


func modificador_do_teste(u: Unidade, op: Dictionary) -> int:
	var t: Dictionary = op.get("teste", {})
	var total := 0
	for c in componentes_do_teste(t):
		total += valor_componente(u, c)
	# Larápio: +1 em Furtividade e Ladinagem por ficha de Sombra.
	if u.ativo("larapio") and _usa(t, ["Furtividade", "Ladinagem"]):
		total += u.fichas_total("Sombra")
	var tags: Array = op.get("tags", [])
	if u.ativo("forca-das-montanhas") and _usa(t, ["forca"]) and (_usa(t, ["Escalada"]) or tags.any(func(x): return x in ["quebrar", "empurrar", "carregar", "escalar"])):
		total += 1
	if u.efeitos.has("astucia_de_rua") and "armadilha" in tags:
		total += 1
	if u.efeitos.has("seguidor_da_noite"):
		total += 2
	return total


## Texto curto do teste: "Natação 2 + Força 3 = +5 · limite 19 · vantagem (Corda)".
func descricao_do_teste(u: Unidade, op: Dictionary) -> String:
	var t: Dictionary = op.get("teste", {})
	if t.is_empty():
		return "sem teste"
	var partes := PackedStringArray()
	var somas := PackedStringArray()
	for c in componentes_do_teste(t):
		somas.append("%s %d" % [nome_componente(c), valor_componente(u, c)])
	var mod := modificador_do_teste(u, op)
	partes.append(("%s = %+d" % [" + ".join(somas), mod]) if somas.size() > 1 or mod != valor_componente(u, componentes_do_teste(t)[0]) else "%s %+d" % [nome_componente(componentes_do_teste(t)[0]), mod])
	var lim := limite_do_teste(u, op)
	if lim != 21:
		partes.append("limite %d" % lim)
	var v := tem_vantagem_na_opcao(u, op)
	if v != "":
		partes.append("vantagem (%s)" % _nome_item(v))
	if op.has("dificuldade"):
		partes.append(("dificuldade %d (%s)" % [int(op["dificuldade"]), NOMES_NIVEL[op["nivel"]]]) if op.has("nivel") else "dificuldade %d" % int(op["dificuldade"]))
	return " · ".join(partes)


## "Natação + Força": o que entra como modificador no teste.
func nome_do_modificador(op: Dictionary) -> String:
	var nomes := PackedStringArray()
	for c in componentes_do_teste(op.get("teste", {})):
		nomes.append(nome_componente(c))
	return " + ".join(nomes) if not nomes.is_empty() else "atributo"


## Faixas legíveis: "2–8 afunda · 9–10 não sai do lugar · 11+ atravessa".
func descricao_das_faixas(op: Dictionary) -> String:
	var faixas: Array = op.get("faixas", [])
	var partes := PackedStringArray()
	for i in faixas.size():
		var de: int = maxi(int(faixas[i][0]), 2)
		var rotulo: String = op["resultados"][faixas[i][1]].get("rotulo", faixas[i][1])
		if i + 1 < faixas.size():
			var ate: int = int(faixas[i + 1][0]) - 1
			partes.append(("%d–%d %s" % [de, ate, rotulo]) if ate > de else ("%d %s" % [de, rotulo]))
		else:
			partes.append("%d+ %s" % [de, rotulo])
	return " · ".join(partes)


## A opção do teste em andamento (ou o teste de amortecer uma queda).
func opcao_atual() -> Dictionary:
	if interacao_atual.has("op_teste"):
		return interacao_atual["op_teste"]
	return opcao_da_interacao(interacao(interacao_atual.get("id", "")), interacao_atual.get("opcao", ""))


func _faixa(op: Dictionary, valor: int) -> String:
	var escolhido: String = op["faixas"][0][1]
	for f in op["faixas"]:
		if valor >= int(f[0]):
			escolhido = f[1]
	return escolhido


## A opção com a abordagem escolhida (perícia/atributo, dificuldade e efeitos próprios).
func opcao_com_abordagem(op: Dictionary, abordagem: String) -> Dictionary:
	if not op.has("abordagens"):
		return op
	for ab in op["abordagens"]:
		if ab["id"] == abordagem:
			var ef := op.duplicate()
			ef.erase("abordagens")
			ef.erase("faixas")
			ef.erase("resultados")
			ef.merge(ab, true)
			ef["texto"] = "%s (%s)" % [op.get("texto", "teste"), ab.get("texto", ab["id"])]
			return ef
	return {}


func heroi_interagir(id: String, opcao_id: String, abordagem := "") -> bool:
	var u := ativa()
	var it := interacao(id)
	if it.is_empty() or not it.get("ativa", true):
		return false
	var base := opcao_da_interacao(it, opcao_id)
	if base.is_empty() or not base.get("ativa", true) or motivo_sem_opcao(u, it, base) != "":
		return false
	var op := opcao_com_abordagem(base, abordagem)
	if op.is_empty() or motivo_sem_opcao(u, it, op) != "":
		return false
	var custo: Dictionary = op.get("custo", {})
	_agiu(u)
	if custo.get("turno", false):
		u.acoes_mov = 0
		u.acoes_padrao = 0
		u.deslocamento = 0
	var gratis: int = u.efeitos.get("interacoes_gratis", {}).get("valor", 0)
	if int(custo.get("padrao", 0)) > 0 and gratis > 0:
		u.efeitos["interacoes_gratis"]["valor"] = gratis - 1
	else:
		u.acoes_padrao -= int(custo.get("padrao", 0))
	for i in int(custo.get("movimento", 0)):
		if u.acoes_mov > 0:
			u.acoes_mov -= 1
		else:
			u.acoes_padrao -= 1
		u.deslocamento = 0
	if op.has("consome"):
		u.consumiveis.erase(op["consome"])
		u.gastos.append(op["consome"])
		if u.ativo("mestre-das-cavernas"):
			u.dar_ficha("Preparo")
		_log("%s gasta %s." % [u.nome, _nome_item(op["consome"])])
	if int(custo.get("turnos", 1)) > 1:
		u.efeitos["acao_longa"] = {"id": id, "opcao": opcao_id, "abordagem": abordagem, "faltam": int(custo["turnos"]) - 1,
			"nome": op.get("texto", it["nome"])}
		_log("%s começa: %s (mais %d turno(s))." % [u.nome, op.get("texto", it["nome"]), int(custo["turnos"]) - 1])
		return true
	_executar_interacao(u, it, base, op, id, opcao_id)
	return true


func _executar_interacao(u: Unidade, it: Dictionary, base: Dictionary, op: Dictionary, id: String, opcao_id: String) -> void:
	interacao_atual = {"id": id, "opcao": opcao_id, "dano": 0, "vitoria": ""}
	if base.has("abordagens"):
		interacao_atual["op_teste"] = op
	_log("%s: %s." % [it["nome"], op.get("texto", "teste")])
	if not op.has("teste"):
		_resolver_interacao(-1)
		return
	_comecar_teste_pericia(u, op)


## Ação de vários turnos: a cada turno, o jogador decide se continua.
func texto_acao_longa() -> String:
	var a: Dictionary = ativa().efeitos.get("acao_longa", {})
	if fase != Fase.ACAO_LONGA or a.is_empty():
		return ""
	return "%s está no meio de: %s. Faltam %d turno(s). Continuar gasta este turno inteiro; parar perde o que foi feito." % [
		ativa().nome, a["nome"], int(a["faltam"])]


func heroi_acao_longa(continuar_acao: bool) -> bool:
	var u := ativa()
	if fase != Fase.ACAO_LONGA or not u.efeitos.has("acao_longa"):
		return false
	var a: Dictionary = u.efeitos["acao_longa"]
	fase = Fase.HEROI_ESCOLHE
	if not continuar_acao:
		u.efeitos.erase("acao_longa")
		_log("%s abandona: %s." % [u.nome, a["nome"]])
		return true
	u.acoes_mov = 0
	u.acoes_padrao = 0
	u.deslocamento = 0
	a["faltam"] = int(a["faltam"]) - 1
	if a["faltam"] > 0:
		_log("%s continua: %s (faltam %d)." % [u.nome, a["nome"], a["faltam"]])
		return true
	u.efeitos.erase("acao_longa")
	var it := interacao(a["id"])
	var base := opcao_da_interacao(it, a["opcao"])
	if it.is_empty() or base.is_empty():
		return true
	_executar_interacao(u, it, base, opcao_com_abordagem(base, a["abordagem"]), a["id"], a["opcao"])
	return true


func _comecar_teste_pericia(u: Unidade, op: Dictionary) -> void:
	var vant := tem_vantagem_na_opcao(u, op)
	teste_pericia = Teste21.new(u.baralho, modificador_do_teste(u, op), limite_do_teste(u, op), vant != "", false, 2, _adiar_fechada(u))
	fase = Fase.INTERACAO_TESTE
	_log("Teste: %s." % descricao_do_teste(u, op))
	if not u.viva() or teste_pericia.encerrado:
		if not u.viva():
			teste_pericia.parar()
			teste_pericia.confirmar()
		_avancar_apos_teste(teste_pericia)


## Teste pedido por uma carta ou ação (não por um ponto do mapa): usa a mesma
## mesa e o mesmo diálogo de resultado das interações.
func teste_de_acao(u: Unidade, op: Dictionary, alvo: Unidade = null) -> void:
	_normalizar_teste(op)
	interacao_atual = {"id": "", "opcao": "", "dano": 0, "vitoria": "", "op_teste": op, "alvo": alvo.id if alvo != null else ""}
	_log("%s: %s." % [u.nome, op.get("titulo", op.get("texto", "teste"))])
	if not op.has("teste"):
		_resolver_interacao(-1)
		return
	_comecar_teste_pericia(u, op)


# --- Tratar sangramento ------------------------------------------------------

## Quem o herói da vez pode tratar: ele mesmo ou um aliado adjacente com Sangramento.
func alvos_de_tratar(u: Unidade) -> Array:
	return herois().filter(func(h): return h.baralho.estado != Baralho.Estado.MORTO and h.fichas_total("Sangramento") > 0 \
		and (h == u or Grade.adjacentes(h.pos, u.pos)))


## Ação Padrão: teste de Medicina + Sabedoria (médio). Passou, o sangramento estanca.
func heroi_tratar(alvo: Unidade) -> bool:
	var u := ativa()
	if not vez_do_heroi() or u.acoes_padrao <= 0 or not alvo in alvos_de_tratar(u) or u.efeitos.has("confuso"):
		return false
	u.acoes_padrao -= 1
	_agiu(u)
	teste_de_acao(u, {"titulo": "Tratar o sangramento de %s" % alvo.nome, "texto": "Tratar o sangramento",
		"teste": {"somar": ["Medicina", "sabedoria"]},
		"faixas": [[0, "falha"], [19, "um"], [21, "dois"], [23, "sucesso"]],
		"resultados": {
			"falha": {"rotulo": "não estanca", "texto": "O sangue continua escorrendo por entre os panos."},
			"um": {"rotulo": "1 ficha", "texto": "Você aperta o ferimento pior; o resto ainda sangra.",
				"efeitos": [{"tipo": "tirar_fichas_alvo", "fichas": ["Sangramento"], "qtd": 1}]},
			"dois": {"rotulo": "2 fichas", "texto": "Você enfaixa quase tudo.",
				"efeitos": [{"tipo": "tirar_fichas_alvo", "fichas": ["Sangramento"], "qtd": 2}]},
			"sucesso": {"rotulo": "estancado", "texto": "Você aperta, enfaixa e o sangramento para.",
				"efeitos": [{"tipo": "tirar_fichas_alvo", "fichas": ["Sangramento"]}]},
		}}, alvo)
	return true


## Vantagem: depois de parar, o jogador pode trocar uma carta usada por uma da mão.
## Vale para testes de atributo e para ataques do herói (ex.: Matador de Gigante).
func vantagem_pendente() -> bool:
	var t := teste_do_heroi()
	return t != null and t.encerrado and t.vantagem and not t.estourou


## A carta usada que, trocada pela carta da mão, deixa o teste mais alto (−1 = nenhuma melhora).
func melhor_troca_vantagem(carta_mao: int) -> int:
	var t := teste_do_heroi()
	if t == null:
		return -1
	var atual := t.resultado()
	var melhor := -1
	var melhor_valor := atual
	for i in t.cartas.size():
		var antiga: int = t.cartas[i]
		t.cartas[i] = carta_mao
		var soma := t.soma_cartas()
		if soma <= t.limite and soma + t.modificador > melhor_valor:
			melhor_valor = soma + t.modificador
			melhor = antiga
		t.cartas[i] = antiga
	return melhor


func heroi_vantagem_trocar(carta_mao: int) -> bool:
	if not vantagem_pendente():
		return false
	var t := teste_do_heroi()
	var usada := melhor_troca_vantagem(carta_mao)
	if usada < 0 or not t.trocar_com_vantagem(usada, carta_mao):
		return false
	_log("Vantagem: troca %s por %s." % [Carta.nome(usada), Carta.nome(carta_mao)])
	t.confirmar()
	_avancar_apos_teste(t)
	return true


func heroi_vantagem_confirmar() -> bool:
	if not vantagem_pendente():
		return false
	var t := teste_do_heroi()
	t.confirmar()
	_avancar_apos_teste(t)
	return true


func _concluir_teste_pericia() -> void:
	var u := ativa()
	if teste_pericia.vantagem and teste_pericia.encerrado and not teste_pericia.estourou and u.viva() and not u.baralho.mao.is_empty():
		return   # espera o jogador trocar ou confirmar
	teste_pericia.confirmar()
	_resolver_interacao(teste_pericia.resultado())


## Dono (herói) de um teste em andamento, ou null.
func _dono_do_teste(t: Teste21) -> Unidade:
	var u: Unidade = null
	if t == teste_pericia:
		u = ativa()
	elif t == teste_ataque:
		u = atacante
	elif t == teste_defesa:
		u = defensor
	return u if u != null and u.eh_heroi() else null


## Cartas que mexem no resultado quando o herói estoura.
func _ajustes_no_estouro(t: Teste21) -> void:
	var u := _dono_do_teste(t)
	if u == null or not t.estourou or t.resultado_forcado >= 0:
		return
	if u.ativo("sorte-dos-pequenos") and not u.efeitos.has("sorte_usada"):
		u.efeitos["sorte_usada"] = {}
		t.resultado_forcado = 21
		_log("Sorte dos Pequenos: %s estourou, mas o resultado vale 21." % u.nome)
		return
	if u.ativo("a-boa-estrela") and t != teste_pericia:
		t.resultado_forcado = 5
		_log("A Boa Estrela: em vez de estourar, o teste de %s vale 5." % u.nome)
		return
	if t == teste_pericia and u.ativo("passo-firme") and _usa(opcao_atual().get("teste", {}), ["Atletismo"]):
		var extra := u.baralho.puxar_topo()
		if extra >= 0:
			u.baralho.descarte.append(extra)
			if Carta.valor(extra) > Carta.valor(t.carta_do_estouro):
				t.carta_do_estouro = extra
			_log("Passo Firme: %s puxa duas cartas no estouro e fica com a melhor." % u.nome)


func _resolver_interacao(valor: int) -> void:
	var u := ativa()
	var it := interacao(interacao_atual["id"])
	var op := opcao_atual()
	if it.is_empty():
		it = {"id": "", "nome": op.get("titulo", "Teste"), "pos": u.pos, "opcoes": []}
	interacao_atual.erase("op_teste")
	var rid: String = _faixa(op, valor) if op.has("teste") else op.get("resultado", "")
	var res: Dictionary = op["resultados"][rid]
	if valor >= 0:
		_log("Resultado do teste: %d (%s)." % [valor, res.get("rotulo", rid)])
	# Falhou e há carta que permite refazer: espera a escolha antes dos efeitos.
	if valor >= 0 and not resultado_e_sucesso(op, rid) and not interacao_atual.get("refeito", false):
		var ops := opcoes_de_refazer(u, op)
		if not ops.is_empty():
			interacao_atual["pendente"] = {"op": op, "valor": valor, "rid": rid, "it": it}
			resultado_interacao = {"titulo": "%s · %s" % [it["nome"], op.get("texto", "teste")], "texto": res.get("texto", ""),
				"atributo": nome_do_modificador(op), "valor": valor, "rotulo": res.get("rotulo", ""),
				"efeitos": PackedStringArray(), "refazer": ops, "pendente": true, "critico": false}
			fase = Fase.INTERACAO_RESOLVIDA
			return
	_aplicar_resultado(u, it, op, valor, rid)


## O resultado é um sucesso? Um resultado pode dizer "sucesso": true/false; sem
## isso, só a última faixa (a melhor) conta como sucesso.
static func resultado_e_sucesso(op: Dictionary, rid: String) -> bool:
	var res: Dictionary = op.get("resultados", {}).get(rid, {})
	if res.has("sucesso"):
		return res["sucesso"]
	var faixas: Array = op.get("faixas", [])
	return faixas.is_empty() or rid == faixas[-1][1]


## Cartas que deixam refazer um teste que falhou.
func opcoes_de_refazer(u: Unidade, op: Dictionary) -> Array:
	var t: Dictionary = op.get("teste", {})
	var lista := []
	var tem_pericia := componentes_do_teste(t).any(func(c): return not NOMES_ATRIBUTO.has(c))
	var c = u.carta_com("persistencia-humana")
	if c != null and c.pode_pagar(3) and tem_pericia:
		lista.append({"slug": "persistencia-humana", "texto": "Persistência Humana (3 de fadiga)"})
	c = u.carta_com("olhar-esperto")
	if c != null and c.pode_pagar(1) and "procurar" in op.get("tags", []):
		lista.append({"slug": "olhar-esperto", "texto": "Olhar Esperto (1 de fadiga)"})
	c = u.carta_com("mas-veja-bem")
	if c != null and _usa(t, ["diplomacia", "mentira"]):
		lista.append({"slug": "mas-veja-bem", "texto": "Mas Veja Bem (vira a carta)"})
	if u.ativo("impostor") and _usa(t, ["mentira"]) and not u.efeitos.has("impostor_usado") and not u.baralho.mao.is_empty():
		lista.append({"slug": "impostor", "texto": "Impostor (descarta uma carta da mão; uma vez por cena)"})
	return lista


func heroi_refazer(slug: String) -> bool:
	var u := ativa()
	if fase != Fase.INTERACAO_RESOLVIDA or not interacao_atual.has("pendente"):
		return false
	var p: Dictionary = interacao_atual["pendente"]
	if not opcoes_de_refazer(u, p["op"]).any(func(o): return o["slug"] == slug):
		return false
	match slug:
		"persistencia-humana":
			u.carta_com(slug).pagar(3)
		"olhar-esperto":
			u.carta_com(slug).pagar(1)
		"mas-veja-bem":
			_virar(u, u.carta_com(slug))
		"impostor":
			u.efeitos["impostor_usado"] = {}
			var menor: int = u.baralho.mao[0]
			for carta in u.baralho.mao:
				if Carta.valor(carta) < Carta.valor(menor):
					menor = carta
			u.baralho.tirar_da_mao(menor)
			u.baralho.descarte.append(menor)
	_log("%s refaz o teste (%s)." % [u.nome, preload("res://core/catalogo.gd").habilidade_por_slug(slug)])
	interacao_atual.erase("pendente")
	interacao_atual["refeito"] = true
	interacao_atual["op_teste"] = p["op"]
	_comecar_teste_pericia(u, p["op"])
	return true


func _aplicar_resultado(u: Unidade, it: Dictionary, op: Dictionary, valor: int, rid: String) -> void:
	var res: Dictionary = op["resultados"][rid]
	var linhas := PackedStringArray()
	if valor >= 0:
		var sucesso := resultado_e_sucesso(op, rid)
		var tst: Dictionary = op.get("teste", {})
		var comps := componentes_do_teste(tst)
		if sucesso and u.ativo("dedos-de-seda") and _usa(tst, ["Ladinagem"]):
			u.dar_ficha("Preparo")
			linhas.append("Dedos de Seda: +1 ficha de Preparo.")
		if sucesso and u.ativo("rastrear") and _usa(tst, ["Sobrevivência"]):
			u.dar_ficha("Foco")
			linhas.append("Rastrear: +1 ficha de Foco.")
		if sucesso and u.ativo("nervos-de-aco") and _usa(tst, ["espirito"]):
			linhas.append("Nervos de Aço: −%d de fadiga." % _tirar_fadiga(u, 1))
		if not sucesso and u.ativo("crenca-da-provacao") and _usa(tst, ["forca"]):
			linhas.append("Crença da Provação: −%d de fadiga." % _tirar_fadiga(u, 1))
		if sucesso and u.ativo("resposta-criativa") and comps.size() >= 2:
			var tipos := {}
			for comp in comps:
				tipos[tipo_componente(comp)] = true
			if tipos.size() >= 2:
				u.baralho.comprar_para_mao(1)
				linhas.append("Resposta Criativa: compra 1 carta.")
		if sucesso and u.ativo("trabalhador") and teste_pericia != null and not teste_pericia.da_mao.is_empty():
			u.baralho.comprar_para_mao(1)
			linhas.append("Trabalhador: compra 1 carta.")
		if u.ativo("conhecedor-do-terreno") and it.get("id", "") != "":
			u.dar_ficha("Foco")
			linhas.append("Conhecedor do Terreno: +1 ficha de Foco.")
		if teste_pericia != null and teste_pericia.critico():
			_critico(u)
	interacao_atual["valor_teste"] = valor
	for ef in res.get("efeitos", []):
		var linha := _aplicar_efeito(u, it, ef)
		if linha != "":
			linhas.append(linha)
	resultado_interacao = {"titulo": "%s · %s" % [it["nome"], op.get("texto", "teste")], "texto": res.get("texto", ""),
		"atributo": nome_do_modificador(op),
		"valor": valor, "rotulo": res.get("rotulo", ""), "efeitos": linhas,
		"critico": valor >= 0 and teste_pericia != null and teste_pericia.critico()}
	if res.has("texto"):
		_log(res["texto"])
	fase = Fase.INTERACAO_RESOLVIDA
	if not u.viva():
		_log("%s cai inconsciente." % u.nome)


## Queda de mais de 2 quadrados: o herói pode testar Acrobacia para cortar o
## dano pela metade (dificuldade 15 + quadrados; passa quem tira mais que ela).
func queda_pendente() -> int:
	return int(interacao_atual.get("queda", 0)) if fase == Fase.INTERACAO_RESOLVIDA else 0


static func dano_de_queda(quadrados: int) -> int:
	return 0 if quadrados <= 1 else 3 * (quadrados - 1)


func opcao_de_amortecer(quadrados: int) -> Dictionary:
	var dano := dano_de_queda(quadrados)
	var metade := int(ceil(dano / 2.0))
	return {"id": "amortecer", "texto": "Amortecer a queda",
		"teste": {"atributo": "destreza", "pericia": "Acrobacia", "movimento": true},
		"dificuldade": 15 + quadrados,
		"faixas": [[0, "falha"], [15 + quadrados, "amortece"]],
		"resultados": {
			"falha": {"rotulo": "cai de mau jeito", "texto": "Você não consegue se ajeitar no ar e bate no chão com tudo.",
				"efeitos": [{"tipo": "dano", "valor": dano}]},
			"amortece": {"rotulo": "amortece (metade do dano)", "texto": "Você gira o corpo, rola ao tocar o chão e espalha o impacto.",
				"efeitos": [{"tipo": "dano", "valor": metade}]},
		}}


## tentar = true: faz o teste de Acrobacia; false: aceita o dano inteiro.
func heroi_amortecer_queda(tentar: bool) -> bool:
	var n := queda_pendente()
	if n <= 0:
		return false
	interacao_atual.erase("queda")
	var u := ativa()
	if not tentar:
		interacao_atual["dano"] = int(interacao_atual.get("dano", 0)) + dano_de_queda(n)
		_log("%s cai %d quadrados sem tentar amortecer." % [u.nome, n])
		_continuar_interacao()
		return true
	var op := opcao_de_amortecer(n)
	interacao_atual["op_teste"] = op
	teste_pericia = Teste21.new(u.baralho, modificador_do_teste(u, op), limite_do_teste(u, op), false, false, 2, _adiar_fechada(u))
	fase = Fase.INTERACAO_TESTE
	_log("%s tenta amortecer a queda: %s, dificuldade %d." % [u.nome, descricao_do_teste(u, op), op["dificuldade"]])
	if not u.viva() or teste_pericia.encerrado:
		if not u.viva():
			teste_pericia.parar()
		_avancar_apos_teste(teste_pericia)
	return true


func _continuar_interacao() -> void:
	if interacao_atual.has("pendente"):
		# Aceitou o resultado sem refazer: agora os efeitos acontecem.
		var p: Dictionary = interacao_atual["pendente"]
		interacao_atual.erase("pendente")
		_aplicar_resultado(ativa(), p["it"], p["op"], p["valor"], p["rid"])
		return
	if queda_pendente() > 0:
		heroi_amortecer_queda(false)
		return
	var u := ativa()
	var dano: int = interacao_atual.get("dano", 0)
	var vitoria: String = interacao_atual.get("vitoria", "")
	interacao_atual = {}
	if vitoria != "":
		fase = Fase.VITORIA
		mensagem_fim = vitoria
		_log("Missão cumprida: " + vitoria)
		return
	fase = Fase.HEROI_ESCOLHE
	if not u.viva():
		if not _verificar_fim():
			_proximo_turno()
		return
	if dano > 0:
		_dano_no_heroi(u, dano, "interacao", Fase.HEROI_ESCOLHE)


## Aplica um efeito e devolve a linha que a tela mostra ("" = nada a dizer).
func _aplicar_efeito(u: Unidade, it: Dictionary, ef: Dictionary) -> String:
	match ef["tipo"]:
		"atravessar":
			var alvo_travessia := destino_travessia(u, it)
			if alvo_travessia == Vector2i(-1, -1):
				return "Não há espaço livre do outro lado."
			u.pos = alvo_travessia
			eventos.append({"tipo": "mover", "id": u.id, "caminho": [alvo_travessia]})
			return ""
		"desativar_opcao":
			opcao_da_interacao(it, ef["opcao"])["ativa"] = false
			return ""
		"molhar":
			return _molhar(u)
		"desengajar":
			u.efeitos["desengajar"] = {"ate": "inicio_turno"}
			u.ignora_impedimento = true
			return "Você pode se mover sem provocar ataques de oportunidade neste turno."
		"fichas_alvo", "tirar_fichas_alvo", "empurrar_alvo", "provocar_alvo", "derrubar_alvo":
			var alvo_t := unidade(interacao_atual.get("alvo", ""))
			if alvo_t == null:
				return ""
			match ef["tipo"]:
				"fichas_alvo":
					alvo_t.dar_ficha(ef["ficha"], int(ef.get("qtd", 1)))
					return "%s recebe %d ficha(s) de %s." % [alvo_t.nome, int(ef.get("qtd", 1)), ef["ficha"]]
				"tirar_fichas_alvo":
					var n := 0
					for f in ef["fichas"]:
						n += alvo_t.tirar_fichas(f, int(ef.get("qtd", 999)))
					return "%s perde %d ficha(s) de %s." % [alvo_t.nome, n, " e ".join(PackedStringArray(ef["fichas"]))]
				"empurrar_alvo":
					_empurrar(alvo_t, u.pos, int(ef["valor"]))
					return "%s é empurrado." % alvo_t.nome
				"derrubar_alvo":
					derrubar(alvo_t)
					return "%s fica Caído." % alvo_t.nome
				"provocar_alvo":
					alvo_t.efeitos["provocado"] = {"por": u.id, "turnos": 2}
					return "%s só vai atacar %s até o próximo turno dele." % [alvo_t.nome, u.nome]
			return ""
		"mover":
			var destino := _casa_livre_perto(ef["para"])
			if destino == Vector2i(-1, -1):
				return "Não há espaço livre do outro lado."
			u.pos = destino
			eventos.append({"tipo": "mover", "id": u.id, "caminho": [destino]})
			return ef.get("texto", "")
		"dano":
			interacao_atual["dano"] = int(interacao_atual.get("dano", 0)) + int(ef["valor"])
			return "Sofre %d de dano (você escolhe como distribuir)." % int(ef["valor"])
		"queda":
			var n := int(ef["quadrados"])
			if n <= 1:
				return "Cai de 1 quadrado de altura: sem dano."
			derrubar(u)
			if n == 2:
				interacao_atual["dano"] = int(interacao_atual.get("dano", 0)) + dano_de_queda(n)
				return "Cai 2 quadrados: %d de dano (você escolhe como distribuir)." % dano_de_queda(n)
			interacao_atual["queda"] = n
			return "Vai cair %d quadrados: %d de dano. Dá para tentar amortecer a queda com Acrobacia (dificuldade %d) e sofrer só a metade." % [n, dano_de_queda(n), 15 + n]
		"item":
			for i in int(ef.get("qtd", 1)):
				u.consumiveis.append(ef["item"])
			_log("%s pega %s." % [u.nome, _nome_item(ef["item"])])
			return "Ganha: %s%s." % [_nome_item(ef["item"]), (" ×%d" % int(ef["qtd"])) if int(ef.get("qtd", 1)) > 1 else ""]
		"desativar":
			var alvo := interacao(ef.get("id", it["id"]))
			alvo["ativa"] = false
			return ""
		"ativar":
			interacao(ef["id"])["ativa"] = true
			return ef.get("texto", "")
		"abrir_caminho":
			for p in ef["celulas"]:
				grade.obstaculos.erase(p)
				if ef.has("chao"):
					decoracao[p] = ef["chao"]
			eventos.append({"tipo": "mapa"})
			return ef.get("texto", "O caminho está aberto.")
		"alertar":
			var grupo: String = ef.get("grupo", "")
			if inimigos_vivos().any(func(o): return not o.alerta and (grupo == "" or o.grupo == grupo)):
				_alertar_inimigos(grupo)
				var txt: String = ef.get("texto", "O barulho alerta os inimigos!")
				_log(txt)
				return txt
			return ""
		"retirar":
			var ids: Array = ef.get("ids", [])
			if ef.has("grupo"):
				ids = ids + unidades.filter(func(o): return not o.eh_heroi() and o.grupo == ef["grupo"]).map(func(o): return o.id)
			for id in ids:
				var o := unidade(id)
				if o != null and o.viva():
					o.vida = 0
					o.alerta = false
					eventos.append({"tipo": "sumir", "id": id})
			_log(ef.get("texto", "Os inimigos vão embora."))
			return ef.get("texto", "Os inimigos vão embora.")
		"marcar":
			var o := unidade(ef["id"])
			if o != null and o.viva():
				o.dar_ficha("Marcado")
				return "%s fica marcado: a carta fechada da defesa dele fica à vista." % o.nome
			return ""
		"fichas_grupo":
			for h in herois_ativos():
				if Grade.distancia(h.pos, it["pos"]) <= 4:
					h.dar_ficha(ef["ficha"])
			return "Cada herói por perto ganha 1 ficha de %s." % ef["ficha"]
		"parar":
			u.deslocamento = 0
			u.acoes_mov = 0
			return "Você perde o resto do movimento neste turno."
		"deslocamento":
			u.deslocamento += int(ef["valor"])
			return "Ainda pode andar %d quadrado(s) sem gastar ação." % int(ef["valor"])
		"ficha":
			var c = u.carta_heroi() if u.carta_heroi() != null else (u.cartas[0] if not u.cartas.is_empty() else null)
			if c == null:
				return ""
			c.dar_ficha(ef["ficha"])
			return "Ganha 1 ficha de %s (em %s)." % [ef["ficha"], c.nome()]
		"fadiga":
			var tirada := _tirar_fadiga(u, int(ef["valor"]))
			return "Recupera %d de fadiga." % tirada
		"descanso_curto":
			if it.get("descanso", false):
				descansos_usados[it["id"]] = true
			var linhas_d := PackedStringArray()
			for h in herois():
				if h.baralho.estado != Baralho.Estado.MORTO and Grade.distancia(h.pos, it["pos"]) <= 4:
					linhas_d.append("%s — %s" % [h.nome, _descanso_curto(h)])
			return "\n".join(linhas_d)
		"vitoria":
			interacao_atual["vitoria"] = ef["texto"]
			return ef["texto"]
		"subir":
			# Escalar uma pedra alta (0.19): o herói fica em cima dela.
			var de := u.pos
			u.pos = it["pos"]
			eventos.append({"tipo": "mover", "id": u.id, "caminho": [u.pos]})
			_log("%s sobe em %s (estava em %s)." % [u.nome, it["nome"], str(de)])
			_tut("subiu")
			return "Lá de cima, os ataques têm vantagem contra quem está embaixo. Para descer, é só andar."
		"correr":
			return _efeito_correr(u, ef, false)
		"saltar":
			return _efeito_correr(u, ef, true)
		"manobra":
			return _efeito_manobra(u, ef, int(interacao_atual.get("valor_teste", 0)))
		"revelar_armadilha":
			return _revelar_armadilha(ef["id"])
		"desarmar_armadilha":
			_desarmar_armadilha(ef["id"])
			return ""
		"levantar_aliado":
			return _efeito_levantar(unidade(interacao_atual.get("alvo", "")), int(ef.get("cura", 0)))
		"matar_unidade":
			var mu := unidade(ef["id"])
			if mu != null and mu.viva():
				mu.vida = 0
				_log("%s se desfaz." % mu.nome)
				eventos.append({"tipo": "sumir", "id": mu.id})
				_desativar_interacao_da_unidade(mu.id)
			return ""
		"abrir_vila":
			eventos.append({"tipo": "abrir_vila", "aba": ef["aba"]})
			return ""
		"narrar":
			_narrar(ef.get("titulo", ""), ef["texto"])
			return ""
		"desbloquear":
			# Pista que abre outra missão no quadro da guilda (campanha, 0.19).
			if not ef["missao"] in missoes_desbloqueadas:
				missoes_desbloqueadas.append(ef["missao"])
			return ef.get("texto", "Uma nova missão vai aparecer no quadro da guilda.")
		"lore":
			# Texto de história achado no cenário (livros, inscrições, cartas): fica no registro.
			_log("História: %s" % ef["texto"])
			lore_achada.append(ef["texto"])
			return ""
		"ouro":
			ouro_ganho += int(ef["valor"])
			_log("O grupo encontra %d moedas de ouro." % int(ef["valor"]))
			return "O grupo ganha %d de ouro." % int(ef["valor"])
	return ""


## Descanso curto: exila 1 do descarte e devolve até 10; a Ração de Viagem tira
## 3 de fadiga; o Kit de Reparos devolve até 3 de vida à armadura e ao escudo.
func _descanso_curto(u: Unidade) -> String:
	var linhas := PackedStringArray()
	var voltaram := u.baralho.descanso_curto()
	linhas.append("Descanso curto: 1 carta exilada, %d voltam ao baralho." % voltaram)
	var do_exilio := 0
	while do_exilio < u.espirito and not u.baralho.exilio.is_empty():
		u.baralho.descarte.append(u.baralho.exilio.pop_front())
		do_exilio += 1
	if do_exilio > 0:
		linhas.append("Espírito %d: %d carta(s) voltam do exílio para o descarte." % [u.espirito, do_exilio])
	if "racao_de_viagem" in u.consumiveis:
		u.consumiveis.erase("racao_de_viagem")
		linhas.append("Come a Ração de Viagem: −%d de fadiga." % _tirar_fadiga(u, 3))
	if u.ativo("maos-de-forja"):
		var arm := mini(u.sabedoria, int(u.armadura.get("vida", 0)) - u.vida_armadura)
		u.vida_armadura += arm
		var esc := mini(u.sabedoria - arm, int(u.escudo.get("vida", 0)) - u.vida_escudo)
		u.vida_escudo += esc
		if arm + esc > 0:
			linhas.append("Mãos de Forja: armadura +%d, escudo +%d." % [arm, esc])
	if "kit_de_reparos" in u.equipamentos:
		var pontos := 3
		var arm := mini(pontos, int(u.armadura.get("vida", 0)) - u.vida_armadura)
		u.vida_armadura += arm
		pontos -= arm
		var esc := mini(pontos, int(u.escudo.get("vida", 0)) - u.vida_escudo)
		u.vida_escudo += esc
		if arm + esc > 0:
			linhas.append("Kit de Reparos: armadura +%d, escudo +%d." % [arm, esc])
	for l in linhas:
		_log(l)
	if voltaram > 0:
		eventos.append({"tipo": "cura", "id": u.id, "valor": voltaram})
	return "\n".join(linhas)


## Atravessar (rio, paredão, ponte): segue em linha reta do herói rumo ao
## marcador, passa pelas casas bloqueadas e para na primeira livre depois delas.
func destino_travessia(u: Unidade, it: Dictionary) -> Vector2i:
	var d: Vector2i = it["pos"] - u.pos
	var dir := Vector2i(signi(d.x), signi(d.y))
	if dir == Vector2i.ZERO:
		return Vector2i(-1, -1)
	var q := u.pos + dir
	if not grade.dentro(q) or not grade.bloqueado(q):
		return Vector2i(-1, -1)
	while grade.dentro(q) and grade.bloqueado(q):
		q += dir
	if not grade.dentro(q):
		return Vector2i(-1, -1)
	return _casa_livre_perto(q)


## Opções que ainda aparecem no diálogo.
func opcoes_visiveis(it: Dictionary) -> Array:
	return it["opcoes"].filter(func(op): return op.get("ativa", true))


func _casa_livre_perto(p: Vector2i) -> Vector2i:
	if grade.dentro(p) and not grade.bloqueado(p) and na_posicao(p) == null:
		return p
	for d in Grade.DIRECOES:
		var q: Vector2i = p + d
		if grade.dentro(q) and not grade.bloqueado(q) and na_posicao(q) == null:
			return q
	return Vector2i(-1, -1)


func _nome_item(id: String) -> String:
	if Itens.CONSUMIVEIS.has(id):
		return Itens.CONSUMIVEIS[id]["nome"]
	if Itens.NAO_CONSUMIVEIS.has(id):
		return Itens.NAO_CONSUMIVEIS[id]["nome"]
	return id


# --- Turnos -----------------------------------------------------------------

func _fim_de_turno_heroi(u: Unidade, esc: Dictionary) -> void:
	var op := opcoes_fim_de_turno(u)
	# Fadiga: cada ponto sai da carta escolhida (Lucas: só 1 por carta, a não ser que haja mais pontos).
	var pedidas: Array = esc.get("fadiga", [])
	for k in int(op["pontos"]):
		var com_fadiga := cartas_com_fadiga(u)
		if com_fadiga.is_empty():
			break
		var i: int = int(pedidas[k]) if k < pedidas.size() and int(pedidas[k]) in com_fadiga else com_fadiga[0]
		u.cartas[i].fadiga -= 1
		_log("Fim do turno: −1 de fadiga em %s%s." % [u.cartas[i].nome(), " (Fôlego de Viajante / fadiga a mais)" if k > 0 else ""])
	Origens.fim_do_turno(self, u)
	for id in esc.get("opcionais", []):
		if id == "bencao-persistente":
			_bencao_persistente(u)
	if u.foco.get("id", "") == "turibulo_das_bencaos":
		var n_t := _tirar_fadiga(u, 1)
		for h in herois_ativos():
			if h != u and Grade.adjacentes(h.pos, u.pos):
				n_t += _tirar_fadiga(h, 1)
		if n_t > 0:
			_log("Turíbulo das Bênçãos: −1 de fadiga em %s e nos aliados ao lado." % u.nome)
	var resp: Array = esc.get("respirar", [])
	for n in u.recuperar_fadiga_no_fim:
		var dona = u.carta_com("respirar-fundo")
		var alvo_c = null
		if n < resp.size() and int(resp[n]) < u.cartas.size() and u.cartas[int(resp[n])] != dona and u.cartas[int(resp[n])].fadiga > 0:
			alvo_c = u.cartas[int(resp[n])]
		for c in u.cartas:
			if alvo_c == null and c != dona and c.fadiga > 0:
				alvo_c = c
		if alvo_c != null:
			alvo_c.fadiga -= 1
			_log("Respirar Fundo: −1 de fadiga em %s." % alvo_c.nome())
	u.recuperar_fadiga_no_fim = 0
	if u.armadura.get("classe", "") in ["media", "pesada"] and u.vida_armadura > 0 and not u.baralho.descarte.is_empty():
		u.baralho.exilio.append(u.baralho.descarte.pop_back())
		_log("%s pesa: 1 carta do descarte vai para o exílio." % u.armadura["nome"])
	for nome_ef in u.efeitos.keys():
		var ef: Dictionary = u.efeitos[nome_ef]
		if ef.has("turnos"):
			ef["turnos"] -= 1
			if ef["turnos"] <= 0:
				u.efeitos.erase(nome_ef)
	u.deslocamento = 0
	u.ignora_impedimento = false
	_fim_da_corrida(u)


## Bênção Persistente (texto da carta): no fim do turno, 1 de fadiga nesta carta; você e
## cada aliado ao alcance curto exilam 1 carta do descarte e curam 1.
func _bencao_persistente(u: Unidade) -> void:
	var c = u.carta_com("bencao-persistente")
	if c == null or not c.pode_pagar(1):
		return
	c.pagar(1)
	for h in herois():
		if h.baralho.estado != Baralho.Estado.MORTO and Grade.distancia(h.pos, u.pos) <= 4:
			_curar(h, 1, "recebe a Bênção Persistente")   # toda cura já exila 1 do descarte antes
	_log("Bênção Persistente de %s." % u.nome)


func _verificar_fim() -> bool:
	var morto := ""
	for h in herois():
		if h.baralho.estado == Baralho.Estado.MORTO:
			morto = h.nome
	if herois_ativos().is_empty() or morto != "":
		for t in [teste_ataque, teste_defesa, teste_pericia]:
			if t != null:
				t.parar()
				t.confirmar()
		fase = Fase.DERROTA
		mensagem_fim = ("%s morreu." % morto) if morto != "" else "Todos os heróis caíram."
		_log(mensagem_fim + " Derrota.")
		return true
	if not vitoria_se_morrer.is_empty() and vitoria_se_morrer.all(func(id): return not unidade(id).viva()):
		fase = Fase.VITORIA
		mensagem_fim = mensagem_vitoria
		_log("Missão cumprida: " + mensagem_vitoria)
		return true
	if inimigos_vivos().is_empty() and vitoria_ao_derrotar_todos:
		fase = Fase.VITORIA
		mensagem_fim = "Todos os inimigos caíram."
		_log("Todos os inimigos caíram. Vitória!")
		return true
	return false


func _verificar_queda_heroi(u: Unidade) -> void:
	if not u.viva():
		_log("%s cai inconsciente." % u.nome)
		if not _verificar_fim():
			_proximo_turno()


func _verificar_queda_heroi_sem_turno(u: Unidade) -> void:
	if not u.viva():
		_log("%s cai inconsciente." % u.nome)


func _comecar_turno() -> void:
	var u := ativa()
	_limpar_zonas_de_caidos()
	u.novo_turno()
	for o in unidades:
		for nome_ef in o.efeitos.keys():
			if o.efeitos[nome_ef].get("ate_turno_de", "") == u.id:
				o.efeitos.erase(nome_ef)
	var simbolo = u.carta_com("simbolo-sagrado") if u.eh_heroi() else null
	if simbolo != null and simbolo.fadiga > 0:
		simbolo.fadiga -= 1
		_log("Símbolo Sagrado: −1 de fadiga nele.")
	u.moveu_no_turno = false
	fase = Fase.HEROI_ESCOLHE if u.eh_heroi() else Fase.IA_TURNO
	_log("— Rodada %d: vez de %s." % [rodada, nome_visto(u)])
	# Fichas persistentes que machucam no início do turno: Veneno e Fogo (1 por ficha).
	# Não somem sozinhas: Veneno sai com antídoto; Fogo ao virar a carta ou na água.
	for ficha in ["Veneno", "Fogo"]:
		var n := u.fichas_total(ficha)
		if ficha == "Fogo" and u.ativo("constituicao-de-pedra"):
			n = maxi(n - 2, 0)
		if n > 0:
			_dano_direto(u, n, ficha)
	if u.viva() and u.fichas_total("Fogo") > 0:
		_espalhar_fogo(u)
	_pegar_fogo_de_chamas(u)
	_rito_no_turno(u)
	if not u.viva():
		if not _verificar_fim():
			_proximo_turno()
		return
	var ignora_dor: bool = u.eh_heroi() and u.ativo("ignorar-a-dor")
	if u.fichas_total("Imobilizar") > 0 and not ignora_dor:
		_log("%s está imobilizado: −%d de movimento a cada deslocamento." % [u.nome, u.fichas_total("Imobilizar")])
	if u.fichas_total("Confusão") > 0:
		var possiveis := unidades.filter(func(o): return o != u and o.viva())
		if not possiveis.is_empty():
			var alvo_c: Unidade = possiveis[rng.randi_range(0, possiveis.size() - 1)]
			u.efeitos["confuso"] = {"alvo": alvo_c.id}
			_log("%s está confuso: vai atrás de %s e precisa atacá-lo." % [u.nome, alvo_c.nome])
	var atordoado := 0 if ignora_dor else u.tirar_fichas("Atordoamento")
	if atordoado > 0:
		u.acoes_padrao = maxi(u.acoes_padrao - atordoado, 0)
		_log("%s está atordoado: perde %d ação Padrão." % [u.nome, atordoado])
	if u.eh_heroi():
		_verificar_avistamentos()
		if exploracao_livre and not inimigos_vivos().any(func(o): return o.alerta and not inerte(o)):
			u.deslocamento = 30   # fora de combate, anda à vontade
		if u.constituicao >= 3 and u.baralho.descarte.size() >= 2:
			_curar(u, 1, "regenera (Constituição 3)")
		u.so_moveu = true
		if sem_reacoes_ate == u.id:
			sem_reacoes_ate = ""
		for o in inimigos_vivos():
			if o.efeitos.get("provocado", {}).get("por", "") == u.id:
				o.efeitos.erase("provocado")
		_atualizar_limites(u)
		Classes.inicio_do_turno(self, u)
		Origens.inicio_do_turno(self, u)
		if _sustentar_zonas(u):
			return
		if u.efeitos.has("acao_longa") and fase == Fase.HEROI_ESCOLHE:
			if acoes_longas_automaticas:
				heroi_acao_longa(true)
			else:
				fase = Fase.ACAO_LONGA
	elif u.alerta:
		_atualizar_plano(u)


# --- Névoa de guerra (0.12) ---------------------------------------------------
##
## Os heróis só enxergam o que está no campo de visão do grupo: quadrados a até
## ALCANCE_VISAO com linha de visão de algum herói de pé. O que já foi visto fica
## "explorado" (o mapa aparece escurecido). Inimigos fora da vista ficam escondidos.

const ALCANCE_VISAO := 12
var nevoa_de_guerra := true
var explorado := {}
var _visao := {}
var _visao_chave := ""


func visao_dos_herois() -> Dictionary:
	var olhos := herois_ativos()
	if olhos.is_empty():
		olhos = herois()
	var chave := str(olhos.map(func(h): return h.pos)) + "|" + str(grade.visao_bloqueada.size()) + "|" + str(grade.obstaculos.size()) \
		+ "|" + (str(fontes_de_luz()) if escuro else "")
	if chave == _visao_chave:
		return _visao
	var vis := {}
	for h in olhos:
		for x in range(-ALCANCE_VISAO, ALCANCE_VISAO + 1):
			for y in range(-ALCANCE_VISAO, ALCANCE_VISAO + 1):
				var p: Vector2i = h.pos + Vector2i(x, y)
				if grade.dentro(p) and not vis.has(p) and grade.linha_de_visao(h.pos, p) and ve_de(h, h.pos, p):
					vis[p] = true
	_visao = vis
	_visao_chave = chave
	for p in vis:
		explorado[p] = true
	return vis


## Nome para o registro: quem está fora da vista aparece como "?".
func nome_visto(u: Unidade) -> String:
	return u.nome if unidade_visivel(u) else "?"


func visivel(p: Vector2i) -> bool:
	return not nevoa_de_guerra or visao_dos_herois().has(p)


func unidade_visivel(o: Unidade) -> bool:
	return o.eh_heroi() or visivel(o.pos)


# --- Áreas e zonas (0.11) -----------------------------------------------------
##
## Área: o jogador escolhe o centro (ou a direção, se a área parte dele); a tela
## mostra a prévia. Ataque em área: um teste de ataque contra a defesa de cada alvo,
## aliados incluídos (salvo quando a carta diz "inimigos").
## Zona: área que fica no mapa. Zonas iguais sobrepostas não somam (o efeito conta
## uma vez por tipo); zonas diferentes somam. Zona de magia some se o conjurador
## cair; zona de item fica. Sem "até o fim da cena", dura 10 rodadas. Zonas com
## "sustentar" pedem o pagamento no início do turno do dono.

const DURACAO_PADRAO_ZONA := 10

var zonas: Array = []           # [{"id", "tipo", "nome", "celulas", "dono", "vinculada", "rodadas", "sustentar", "carta", ...}]
var _prox_zona := 1
var area_atual := {}            # área escolhida para a carta que está sendo usada
var sustentar_automatico := true   # a tela desliga: pergunta se paga
var pergunta := {}              # Fase.PERGUNTA: {"id", "texto", "opcoes": [[id, texto]], "dados", "volta"}


## Registro da área de uma carta (ou {} se não for de área).
func spec_area(c) -> Dictionary:
	return _info_lado(c).get("area", {})


## Quadrados atingidos se "u" usar a área "spec" apontando "alvo_cel".
func celulas_da_area(u: Unidade, spec: Dictionary, alvo_cel: Vector2i, rot: int) -> Array:
	if spec.get("forma", "") == "aglomerado":
		return _aglomerado(u, alvo_cel, int(spec.get("maximo", 3))).map(func(o): return o.pos)
	return Areas.celulas(spec, u.pos, alvo_cel, rot, grade)


## "" se dá para apontar a área ali; senão, o motivo.
func motivo_area(u: Unidade, spec: Dictionary, alvo_cel: Vector2i) -> String:
	if not grade.dentro(alvo_cel):
		return "fora do mapa"
	match spec.get("forma", "quadrado"):
		"quadrado", "casa":
			if Grade.distancia(u.pos, alvo_cel) > int(spec.get("alcance", 4)):
				return "fora do alcance"
			if not grade.linha_de_visao(u.pos, alvo_cel) or grade.obstaculos.has(alvo_cel) and not grade.obstaculos[alvo_cel] in Grade.BAIXOS:
				return "sem linha de visão"
			if spec.get("forma", "") == "casa" and (grade.bloqueado(alvo_cel) or na_posicao(alvo_cel) != null):
				return "casa ocupada"
		"aglomerado":
			var o := na_posicao(alvo_cel)
			if o == null or o.eh_heroi() == u.eh_heroi():
				return "aponte um inimigo"
			if Grade.distancia(u.pos, alvo_cel) > int(spec.get("alcance", 4)) or not grade.linha_de_visao(u.pos, alvo_cel):
				return "fora do alcance"
		"linha", "adjacente", "cone":
			if alvo_cel == u.pos:
				return "aponte uma direção"
	return ""


## Inimigos encadeados, adjacentes entre si, a partir do que está em "cel".
func _aglomerado(u: Unidade, cel: Vector2i, maximo: int) -> Array:
	var primeiro := na_posicao(cel)
	if primeiro == null or primeiro.eh_heroi() == u.eh_heroi():
		return []
	var lista := [primeiro]
	var i := 0
	while i < lista.size() and lista.size() < maximo:
		for o in oponentes(u):
			if lista.size() >= maximo:
				break
			if o.viva() and not o in lista and Grade.adjacentes(o.pos, lista[i].pos):
				lista.append(o)
		i += 1
	return lista


## Usa uma carta de área apontando "alvo_cel" (com "rot" para formas que giram).
func heroi_usar_area(indice: int, alvo_cel: Vector2i, rot := 0, opcao := "") -> bool:
	var u := ativa()
	if not vez_do_heroi() or indice < 0 or indice >= u.cartas.size():
		return false
	if opcao != "":
		u.cartas[indice].opcao = opcao
	var spec := spec_area(u.cartas[indice])
	if spec.is_empty() or motivo_area(u, spec, alvo_cel) != "":
		return false
	area_atual = {"celulas": celulas_da_area(u, spec, alvo_cel, rot), "alvo": alvo_cel, "rot": rot, "origem": u.pos}
	eventos.append({"tipo": "area", "celulas": area_atual["celulas"], "tipo_dano": _tipo_da_carta(u.cartas[indice]), "origem": u.id})
	var ok := heroi_usar_carta(indice, null)
	area_atual = {}
	return ok


## Unidades vivas dentro de uma lista de quadrados.
func unidades_em(cels: Array, so_oponentes_de: Unidade = null) -> Array:
	return unidades.filter(func(o): return o.viva() and o.pos in cels and o != so_oponentes_de \
		and (so_oponentes_de == null or o.eh_heroi() != so_oponentes_de.eh_heroi()))


## Ataque em área: um teste de ataque; cada alvo se defende em separado.
func _ataque_em_area(u: Unidade, alvos: Array, contexto: Dictionary) -> void:
	alvos = alvos.filter(func(o): return o != u)
	if alvos.is_empty():
		_log("Ninguém na área.")
		return
	contexto["area"] = true
	contexto["area_fila"] = alvos.slice(1).map(func(o): return o.id)
	contexto["area_n"] = 0
	_novo_ataque(u, alvos[0], contexto)


## Próximo alvo de um ataque em área: só a defesa (o ataque já foi tirado).
func _proximo_alvo_da_area() -> bool:
	var fila: Array = ctx.get("area_fila", [])
	while not fila.is_empty():
		var o := unidade(fila.pop_front())
		if o == null or not o.viva() or not atacante.viva():
			continue
		ctx["area_n"] = int(ctx.get("area_n", 0)) + 1
		defensor = o
		resultado = {}
		var b_dfs: Baralho = o.baralho if o.eh_heroi() else baralho_inimigos
		var surpreso := not o.eh_heroi() and not o.alerta
		if not o.eh_heroi():
			_alertar_inimigos(o.grupo)
		teste_defesa = Teste21.new(b_dfs, 0, _limite_defesa(o) - o.fichas_total("Penalidade"), false, surpreso, 2, _adiar_fechada(o, true))
		if surpreso:
			teste_defesa.parar()
		_log("O mesmo ataque (%d) atinge %s." % [teste_ataque.resultado(), o.nome])
		fase = Fase.HEROI_DEFENDENDO if o.eh_heroi() else Fase.IA_DEFENDENDO
		if surpreso:
			_avancar_apos_teste(teste_defesa)
		return true
	return false


## Cria uma zona. "opcoes": rodadas (−1 = até o fim da cena), sustentar (fadiga),
## carta (slug que paga), vinculada, cobertura, bloqueia_visao, terreno_dificil...
func criar_zona(tipo: String, nome: String, cels: Array, dono: Unidade, opcoes := {}) -> Dictionary:
	var z := {"id": _prox_zona, "tipo": tipo, "nome": nome, "celulas": cels.duplicate(),
		"dono": dono.id if dono != null else "", "vinculada": true, "rodadas": DURACAO_PADRAO_ZONA, "sustentar": 0}
	z.merge(opcoes, true)
	_prox_zona += 1
	zonas.append(z)
	_atualizar_zonas_no_mapa()
	_log("%s: zona criada (%d quadrados)." % [nome, cels.size()])
	return z


func _remover_zona(z: Dictionary, motivo: String) -> void:
	zonas.erase(z)
	_atualizar_zonas_no_mapa()
	_log("%s some (%s)." % [z["nome"], motivo])


## Zonas num quadrado, uma por tipo (zonas iguais sobrepostas não somam).
func zonas_em(p: Vector2i) -> Array:
	var vistos := {}
	var lista := []
	for z in zonas:
		if p in z["celulas"] and not vistos.has(z["tipo"]):
			vistos[z["tipo"]] = true
			lista.append(z)
	return lista


func zona_em(p: Vector2i, tipo: String) -> Dictionary:
	for z in zonas_em(p):
		if z["tipo"] == tipo:
			return z
	return {}


## Lado da zona: as dos heróis ajudam heróis; zonas de item sem dono valem para todos.
func _zona_aliada(z: Dictionary, u: Unidade) -> bool:
	var d := unidade(z["dono"])
	return d == null or d.eh_heroi() == u.eh_heroi()


func _atualizar_zonas_no_mapa() -> void:
	grade.custo_extra.clear()
	grade.visao_bloqueada.clear()
	grade.bloqueio_extra.clear()
	for c in casas_de_armadilha():
		grade.custo_extra[c] = 4   # o caminho automático evita armadilhas achadas
	for z in zonas:
		for c in z["celulas"]:
			if z.get("bloqueia", false):
				grade.bloqueio_extra[c] = true
			if z.get("terreno_dificil", false):
				grade.custo_extra[c] = 1
			if z.get("bloqueia_visao", false):
				grade.visao_bloqueada[c] = true
	eventos.append({"tipo": "zonas"})


## Fim de rodada: zonas com prazo perdem 1 rodada.
func _passar_rodada_zonas() -> void:
	for z in zonas.duplicate():
		if int(z["rodadas"]) > 0 and int(z.get("sustentar", 0)) == 0:
			z["rodadas"] = int(z["rodadas"]) - 1
			if z["rodadas"] <= 0:
				_remover_zona(z, "acabou o tempo")


## Zona de magia some quando o conjurador cai.
func _limpar_zonas_de_caidos() -> void:
	for z in zonas.duplicate():
		var d := unidade(z["dono"])
		if z.get("vinculada", true) and d != null and not d.viva():
			_remover_zona(z, "%s caiu" % d.nome)


## Pisar num quadrado: piche dá Imobilizar; armadilha machuca o primeiro inimigo.
func _entrar_na_casa(u: Unidade, p: Vector2i) -> bool:
	if u.eh_heroi() and _casa_do_heroi(u, p):
		return true
	var parou := false
	for z in zonas_em(p):
		match z["tipo"]:
			"piche":
				u.dar_ficha("Imobilizar")
				_log("%s afunda no piche: +1 Imobilizar." % u.nome)
			"armadilha":
				if not _zona_aliada(z, u):
					_remover_zona(z, "disparou")
					_log("A armadilha pega %s!" % u.nome)
					if u.eh_heroi():
						_dano_de_impacto(u, 6, "Armadilha")
					else:
						_dano_direto(u, 6, "Armadilha")
					u.dar_ficha("Imobilizar")
					parou = true
	return parou


## Fim do turno de "u": Névoa dá Sombra; Halo do Conduíte tira 1 de fadiga.
func _zonas_no_fim_do_turno(u: Unidade) -> void:
	if not u.viva() or not u.eh_heroi():
		return
	for z in zonas_em(u.pos):
		match z["tipo"]:
			"nevoa":
				if u.fichas_total("Sombra") == 0:
					u.dar_ficha("Sombra")
					_log("Névoa: %s ganha 1 ficha de Sombra." % u.nome)
			"conduite":
				if _zona_aliada(z, u) and _tirar_fadiga(u, 1) > 0:
					_log("Halo do Conduíte: %s recupera 1 de fadiga a mais." % u.nome)


## Início do turno do dono: zonas com "sustentar" pedem o pagamento.
## Devolve true se parou para perguntar.
func _sustentar_zonas(u: Unidade) -> bool:
	for z in zonas:
		if z["dono"] != u.id or int(z.get("sustentar", 0)) <= 0 or z.get("sustentada_rodada", -1) == rodada:
			continue
		var c = u.carta_com(z.get("carta", ""))
		var pode: bool = c != null and pode_pagar_fadiga(u, c, int(z["sustentar"]))
		if not pode:
			z["sustentada_rodada"] = rodada
			_remover_zona(z, "não dá para pagar o sustento")
			return _sustentar_zonas(u)
		if sustentar_automatico:
			_pagar_sustento(z, true)
			continue
		perguntar("sustentar", "%s: pagar %d de fadiga (%s) para sustentar a zona?" % [z["nome"], int(z["sustentar"]), c.nome()],
			[["sim", "Sustentar (%d de fadiga)" % int(z["sustentar"])], ["nao", "Deixar a zona sumir"]], {"zona": z["id"]})
		return true
	return false


func _pagar_sustento(z: Dictionary, pagar: bool) -> void:
	z["sustentada_rodada"] = rodada
	if not pagar:
		_remover_zona(z, "não foi sustentada")
		return
	var u := unidade(z["dono"])
	pagar_fadiga(u, u.carta_com(z["carta"]), int(z["sustentar"]))
	_log("%s sustenta %s (%d de fadiga)." % [u.nome, z["nome"], int(z["sustentar"])])


## Pergunta genérica ao jogador (a tela mostra os botões).
var perguntas_na_fila: Array = []   # perguntas que chegaram enquanto outra estava aberta (0.20)


func perguntar(id: String, texto: String, opcoes: Array, dados := {}) -> void:
	if fase == Fase.PERGUNTA:
		perguntas_na_fila.append([id, texto, opcoes, dados])
		return
	pergunta = {"id": id, "texto": texto, "opcoes": opcoes, "dados": dados, "volta": fase}
	fase = Fase.PERGUNTA


func heroi_responder(opcao: String) -> bool:
	if fase != Fase.PERGUNTA:
		return false
	var p := pergunta
	pergunta = {}
	fase = p["volta"]
	match p["id"]:
		"procurar_sala":
			if opcao == "sim":
				var quem := unidade(p["dados"]["quem"])
				if quem != null and quem == ativa():
					_procurar(quem, p["dados"]["sala"])
		"levantar":
			var alvo_l := unidade(p["dados"]["alvo"])
			if alvo_l != null:
				_levantar_aliado(ativa(), alvo_l, "" if opcao == "nada" else opcao)
		"sustentar":
			for z in zonas:
				if z["id"] == p["dados"]["zona"]:
					_pagar_sustento(z, opcao == "sim")
					break
			_sustentar_zonas(ativa())
		"labareda":
			_labareda_fogo(opcao == "sim", p["dados"])
		"arma_petrea":
			_arma_petrea(unidade(p["dados"]["quem"]), opcao)
		"mente_belica":
			_mente_belica(unidade(p["dados"]["quem"]), int(opcao))
		"anular":
			_anular(opcao)
		"oportunidade":
			var r := unidade(p["dados"]["reator"])
			var alvo_o := unidade(p["dados"]["alvo"])
			if opcao == "sim" and r != null and alvo_o != null and r.acoes_reacao > 0:
				r.acoes_reacao -= 1
				_log("%s sai de perto de %s: Golpe de Oportunidade!" % [alvo_o.nome, r.nome])
				_novo_ataque(r, alvo_o, {"habilidade": "Ataque de oportunidade", "oportunidade": true})
			else:
				var lista: Array = oportunidade_recusada.get(p["dados"]["alvo"], [])
				lista.append(p["dados"]["reator"])
				oportunidade_recusada[p["dados"]["alvo"]] = lista
				if not movimento_pendente.is_empty():
					_continuar_movimento()
		"reacao":
			if opcao == "sim":
				heroi_reagir()
			else:
				resultado["reacao"] = ""
		"scry":
			_scry_decidir(opcao)
		"plano":
			_recuperar_consumivel(unidade(p["dados"]["quem"]), opcao)
		"remover_ficha":
			var o := unidade(p["dados"]["alvo"])
			if o != null and o.tirar_fichas(opcao, 1) > 0:
				_log("Bênção dos Salmos: sai 1 ficha de %s de %s." % [opcao, o.nome])
		"segundo_vento":
			_segundo_vento(unidade(p["dados"]["quem"]), opcao)
		"lamina_segundo":
			_lamina_das_sombras(unidade(p["dados"]["quem"]), unidade(p["dados"]["alvo"]), unidade(opcao))
		"estrela_aliado":
			_estrela_aliado(unidade(opcao))
		"larapio":
			var hl := unidade(p["dados"]["quem"])
			var dl := int(p["dados"]["dano"])
			if opcao == "sim" and _larapio_disponivel(hl):
				pagar_fadiga(hl, hl.carta_heroi(), 2)
				_log("Larápio: %s sofre só metade do ataque em área (%d → %d)." % [hl.nome, dl, dl - int(dl / 2)])
				dl -= int(dl / 2)
				resultado["dano"] = dl
			_dano_no_heroi_agora(hl, dl, p["dados"]["origem"], p["dados"]["volta"])
		"estrela_carta", "ficha_carta":
			var h := unidade(p["dados"]["quem"])
			var idx := int(opcao)
			if h != null and idx >= 0 and idx < h.cartas.size():
				if p["id"] == "estrela_carta":
					h.cartas[idx].fadiga = maxi(h.cartas[idx].fadiga - 1, 0)
					_log("Estrela do Amanhecer: −1 de fadiga em %s (%s)." % [h.cartas[idx].nome(), h.nome])
				else:
					_por_ficha_na_carta(h, h.cartas[idx], p["dados"]["ficha"])
	if fase != Fase.PERGUNTA and not perguntas_na_fila.is_empty():
		var q: Array = perguntas_na_fila.pop_front()
		perguntar(q[0], q[1], q[2], q[3])
	return true


## Estrela do Amanhecer (passiva): o aliado escolhido perde 1 de fadiga numa carta que ele escolhe.
func _estrela_aliado(h: Unidade) -> void:
	if h == null:
		return
	var cartas := cartas_com_fadiga(h)
	if cartas.is_empty():
		return
	if cartas.size() == 1 or not perguntar_escolhas:
		var c = h.cartas[cartas[0]]
		c.fadiga -= 1
		_log("Estrela do Amanhecer: %s recupera 1 de fadiga (%s)." % [h.nome, c.nome()])
		return
	perguntar("estrela_carta", "Estrela do Amanhecer: de qual carta de %s sai 1 de fadiga?" % h.nome,
		cartas.map(func(i): return [str(i), "%s (fadiga %d/%d)" % [h.cartas[i].nome(), h.cartas[i].fadiga, h.cartas[i].limite()]]), {"quem": h.id})


## Labareda Voraz: depois do ataque, pode descartar uma carta para pôr 3 Fogo em quem sofreu dano.
func _labareda_fogo(descartar: bool, dados: Dictionary) -> void:
	var u := unidade(dados["quem"])
	if not descartar or u.baralho.mao.is_empty():
		return
	var menor: int = u.baralho.mao[0]
	for carta in u.baralho.mao:
		if Carta.valor(carta) < Carta.valor(menor):
			menor = carta
	u.baralho.tirar_da_mao(menor)
	u.baralho.descarte.append(menor)
	for id in dados["alvos"]:
		var o := unidade(id)
		if o != null and o.viva():
			o.dar_ficha("Fogo", 3)
			_log("Labareda Voraz: %s recebe 3 fichas de Fogo." % o.nome)


## Ciclone: quem está na área testa Escalada (dif. 18 da carta); quem falha sofre
## 3 × Sabedoria e é empurrado 2 para fora da área (+5 se bater em algo).
func _ciclone(u: Unidade, cels: Array) -> void:
	for o in unidades_em(cels):
		if o == u:
			continue
		var valor: int
		if o.eh_heroi():
			valor = _teste_automatico(o, int(o.forca) + int(o.pericias.get("Escalada", 0)))
		else:
			valor = valor_resistido(o, "forca")
		if valor >= 18:
			_log("Ciclone: %s se segura (%d)." % [o.nome, valor])
			continue
		_log("Ciclone: %s é arrastado (%d)." % [o.nome, valor])
		var dano := 3 * u.sabedoria
		if o.eh_heroi():
			_dano_de_impacto(o, dano, "Ciclone")
		else:
			_dano_direto(o, dano, "Ciclone")
		if o.viva():
			var dir := Areas.para_fora(cels, o.pos)
			_empurrar(o, o.pos - dir, 2, 5)


## Teste de um herói fora da mesa (efeitos de área): puxa até 15 ou mais.
func _teste_automatico(h: Unidade, modificador: int) -> int:
	var t := Teste21.new(h.baralho, modificador, 21)
	while not t.encerrado and t.soma_cartas() < 15 and t.puxar():
		pass
	t.parar()
	t.confirmar()
	return t.resultado()


## Usar um item de área (Bomba de Fumaça, Frasco de Piche) apontando o centro.
func heroi_usar_item_area(item: String, alvo_cel: Vector2i) -> bool:
	var u := ativa()
	var spec: Dictionary = Itens.CONSUMIVEIS.get(item, {}).get("area", {})
	if spec.is_empty() or not vez_do_heroi() or u.acoes_padrao <= 0 or not item in u.consumiveis or motivo_area(u, spec, alvo_cel) != "":
		return false
	var cels := celulas_da_area(u, spec, alvo_cel, 0)
	u.acoes_padrao -= 1
	_agiu(u)
	u.consumiveis.erase(item)
	u.gastos.append(item)
	match item:
		"bomba_de_fumaca":
			criar_zona("fumaca", "Fumaça", cels, null, {"vinculada": false, "cobertura": 1})
		"frasco_de_piche":
			criar_zona("piche", "Piche", cels, null, {"vinculada": false, "terreno_dificil": true, "inflamavel": true})
	_log("%s usa %s." % [u.nome, _nome_item(item)])
	return true


## Zonas que um inimigo prefere evitar (piche, penitência, chamas).
func casa_perigosa_para(u: Unidade, p: Vector2i) -> bool:
	if chamas.has(p):
		return true
	for z in zonas_em(p):
		if z["tipo"] in ["piche", "penitencia"] and not _zona_aliada(z, u):
			return true
	return false


# --- Fogo ---------------------------------------------------------------------
##
## Quem está com Fogo, no início do turno: passa 1 ficha para outra carta sua
## sem Fogo (heróis), para cada unidade adjacente sem Fogo e incendeia objetos
## inflamáveis ao lado. Objetos em chamas queimam por 3 rodadas e põem Fogo em
## quem começa o turno ao lado deles; depois viram cinzas (o caminho abre).

const INFLAMAVEIS := ["feno", "tenda", "saco", "cerca"]
var chamas := {}   # Vector2i -> rodadas restantes


func _espalhar_fogo(u: Unidade) -> void:
	if u.ativo("seguidor-da-chama"):
		return
	if u.eh_heroi():
		for c in u.cartas:
			if not c.tem_ficha("Fogo"):
				c.dar_ficha("Fogo")
				_log("O fogo se espalha para %s, outra carta de %s." % [c.nome(), u.nome])
				break
	for o in unidades:
		if o != u and o.viva() and Grade.adjacentes(o.pos, u.pos) and o.fichas_total("Fogo") == 0 and not o.ativo("seguidor-da-chama"):
			o.dar_ficha("Fogo")
			_log("O fogo de %s pega em %s!" % [u.nome, o.nome])
	for d in Grade.DIRECOES:
		var p: Vector2i = u.pos + d
		if grade.obstaculos.get(p, "") in INFLAMAVEIS and not chamas.has(p):
			chamas[p] = 3
			_log("O fogo pega no %s." % grade.obstaculos[p])
			eventos.append({"tipo": "mapa"})


func _pegar_fogo_de_chamas(u: Unidade) -> void:
	if not u.viva() or u.fichas_total("Fogo") > 0 or u.ativo("seguidor-da-chama"):
		return
	for p in chamas:
		if Grade.adjacentes(p, u.pos):
			u.dar_ficha("Fogo")
			_log("%s está ao lado das chamas e pega fogo." % u.nome)
			return


func _queimar_objetos() -> void:
	for p in chamas.keys():
		chamas[p] -= 1
		if chamas[p] <= 0:
			chamas.erase(p)
			grade.obstaculos.erase(p)
			_log("O fogo apaga; só sobram cinzas.")
			eventos.append({"tipo": "mapa"})


## Água apaga o fogo do personagem.
func _molhar(u: Unidade) -> String:
	if u.tirar_fichas("Fogo") > 0:
		_log("A água apaga o fogo de %s." % u.nome)
		return "A água apaga o fogo."
	return ""


## Controlador do Arcano: +1 no limite de fadiga de todas as cartas.
func _atualizar_limites(u: Unidade) -> void:
	var bonus := 1 if u.ativo("controlador-do-arcano") else 0
	for c in u.cartas:
		c.bonus_limite = bonus


func _proximo_turno() -> void:
	if _verificar_fim():
		return
	# Sangramento: machuca no fim do turno de quem sangra.
	var saindo := ativa()
	if saindo != null:
		_zonas_no_fim_do_turno(saindo)
		_rito_no_turno(saindo)
	if saindo != null and saindo.viva() and saindo.fichas_total("Sangramento") > 0:
		_dano_direto(saindo, saindo.fichas_total("Sangramento"), "Sangramento")
		if _verificar_fim():
			return
	for i in ordem.size():
		indice_vez += 1
		if indice_vez >= ordem.size():
			indice_vez = 0
			rodada += 1
		if indice_vez == 0:
			_remontar_mortos()
			_queimar_objetos()
			_passar_rodada_zonas()
		if unidade(ordem[indice_vez]).viva():
			break
	if saindo != null and not saindo.eh_heroi():
		_anunciar_intencao(saindo)
	_comecar_turno()


func _nomes(cartas: Array) -> String:
	return ", ".join(PackedStringArray(cartas.map(func(c): return Carta.nome(c))))


func _log(texto: String) -> void:
	registro.append(texto)
	# Brilho (0.21): mensagem que começa com o nome de uma carta de herói ("Folha de
	# Carvalho: ...") avisa a tela que aquela carta disparou.
	var dois := texto.find(":")
	if dois > 0 and dois < 40:
		var nome := texto.substr(0, dois).to_lower()
		for h in herois():
			for i in h.cartas.size():
				if h.cartas[i].nome().to_lower() == nome:
					eventos.append({"tipo": "brilho", "id": h.id, "carta": i, "nome": h.cartas[i].nome()})
					return


# --- Repertório (0.14): as opções das cartas de Aprendiz ----------------------

## Nado Avançado atravessa água; Passo Leve ignora terreno difícil.
func modo_de_andar(u: Unidade) -> Dictionary:
	var aliados := {}
	if u.eh_heroi():
		for h in herois():
			if h != u and h.viva():
				aliados[h.pos] = true
	return {"nada": u.efeitos.has("nado") or u.flutua or u.tipo == "afogado", "sem_terreno": u.efeitos.has("passo_leve") or u.efeitos.has("saltando") or u.flutua, "aliados": aliados,
		"escalar": u.efeitos.has("escalando") or u.flutua}


## Inimigos com arma natural (animais) não largam a arma.
const ARMA_NATURAL := ["toupeira"]


## Desarmar (Chicote de Água): o herói larga a arma no chão; o inimigo fica sem ela até o fim da cena.
func desarmar(o: Unidade) -> void:
	if o.efeitos.has("sem_arma"):
		return
	if o.eh_heroi():
		if not o.arma.is_empty() and o.arma.get("nome", "") != DESARMADO["nome"]:
			_largar_arma(o, o.pos)
		return
	if o.tipo in ARMA_NATURAL:
		_log("%s não tem arma para largar." % o.nome)
		return
	o.efeitos["sem_arma"] = {}
	o.dano = 0
	o.atributo_dano = o.forca if o.forca >= 3 else 0
	_log("%s fica desarmado." % o.nome)


## Põe uma arma na mão do herói (Arma Pétrea).
func _equipar(u: Unidade, arma: Dictionary) -> void:
	u.arma = arma.duplicate(true)
	u.dano = int(arma["dano"])
	var at := Itens.atributo_da_arma(arma)
	u.atributo_dano = int(u.get(at)) if at in u else 0
	u.a_distancia = arma.get("distancia", false)
	u.faixas_ideais = arma.get("ideais", [])
	u.alcance_corpo = Itens.alcance_corpo(arma)
	u.efeitos.erase("sem_arma")
	eventos.append({"tipo": "mapa"})


## Armas corpo a corpo comuns que a Arma Pétrea pode criar.
static func armas_petreas() -> Array:
	var lista := []
	for id in Itens.ARMAS:
		var a: Dictionary = Itens.ARMAS[id]
		if not a.get("distancia", false):
			lista.append(id)
	return lista


func _arma_petrea(u: Unidade, id: String) -> void:
	if u == null or not Itens.ARMAS.has(id):
		return
	var arma: Dictionary = Itens.ARMAS[id].duplicate(true)
	arma["nome"] = "%s de Pedra" % arma["nome"]
	# Concussão ou Perfurante, à escolha: as de ponta ficam perfurantes; as outras, de concussão.
	arma["tipo_dano"] = "Perfuração" if arma["tipo_dano"] == "Perfuração" else "Concussão"
	arma["petrea"] = true
	if not u.efeitos.has("arma_original"):
		u.efeitos["arma_original"] = {"arma": u.arma.duplicate(true)}
	_equipar(u, arma)
	_log("Arma Pétrea: %s cria %s (dano %d) até o fim da cena." % [u.nome, arma["nome"], arma["dano"]])


## Lâmina das Sombras: um alvo adjacente; descartando uma carta, um segundo alvo adjacente.
func _lamina_das_sombras(u: Unidade, alvo: Unidade, segundo: Unidade) -> void:
	var ctx_l := {"habilidade": "Lâmina das Sombras", "magico": true, "ao_acertar": [{"ficha": "Medo"}]}
	if segundo == null or not segundo.viva() or u.baralho.mao.is_empty():
		_novo_ataque(u, alvo, ctx_l)
		return
	var menor: int = u.baralho.mao[0]
	for carta in u.baralho.mao:
		if Carta.valor(carta) < Carta.valor(menor):
			menor = carta
	u.baralho.tirar_da_mao(menor)
	u.baralho.descarte.append(menor)
	_log("Lâmina das Sombras: %s descarta %s para atingir também %s." % [u.nome, Carta.nome(menor), segundo.nome])
	_ataque_em_area(u, [alvo, segundo], ctx_l)


## Teste de resistência fora da mesa: inimigo com 2 cartas + atributo; herói puxando até 15.
func _resiste(o: Unidade, atributo: String, dificuldade: int) -> bool:
	var valor: int
	if o.eh_heroi():
		valor = _teste_automatico(o, int(o.get(atributo)) if atributo in o else 0)
	else:
		valor = valor_resistido(o, atributo)
	# 0.23: o resultado aparece em cima de quem resistiu (efeitos em área ficavam invisíveis).
	eventos.append({"tipo": "flutuar", "id": o.id, "texto": "%s %d/%d" % ["resiste" if valor >= dificuldade else "falha", valor, dificuldade],
		"cor": "c9c4b8" if valor >= dificuldade else "ff9d5c"})
	return valor >= dificuldade


## Efeitos das opções de repertório que não são um ataque simples.
func usar_repertorio(u: Unidade, c, alvo: Unidade) -> void:
	if not c.slug().begins_with("aprendiz-de"):
		usar_opcao(u, c, alvo)
		return
	match c.opcao:
		"chama-nenem":
			_novo_ataque(u, alvo, {"habilidade": "Chama Neném", "magico": true, "ao_acertar": [{"ficha": "Fogo"}]})
		"manipular-chama":
			# Inimigo: recebe 1 Fogo. Aliado: as fichas de Fogo dele se apagam.
			if alvo.eh_heroi() == u.eh_heroi():
				var n := alvo.fichas_total("Fogo")
				alvo.tirar_fichas("Fogo", n)
				_log("Manipular Chama: o fogo de %s se apaga (%d ficha(s))." % [alvo.nome, n])
			else:
				alvo.dar_ficha("Fogo")
				_log("Manipular Chama: %s recebe 1 ficha de Fogo." % alvo.nome)
		"nuvem-de-brasas":
			for o in unidades_em(area_atual["celulas"]):
				if o == u:
					continue
				if _resiste(o, "destreza", 16):
					_log("Nuvem de Brasas: %s escapa das brasas." % o.nome)
				else:
					o.dar_ficha("Fogo")
					_log("Nuvem de Brasas: %s recebe 1 ficha de Fogo." % o.nome)
		"nado-avancado":
			u.efeitos["nado"] = {}
			_log("Nado Avançado: até o fim da cena, %s anda na água sem penalidade." % u.nome)
		"lava-jato":
			_novo_ataque(u, alvo, {"habilidade": "Lava Jato", "magico": true, "ao_acertar": [{"empurrar": 3}]})
		"chicote-de-agua":
			_novo_ataque(u, alvo, {"habilidade": "Chicote de Água", "magico": true, "ao_acertar": [{"desarmar": true}]})
		"arma-petrea":
			var ops := []
			for id in armas_petreas():
				var a: Dictionary = Itens.ARMAS[id]
				ops.append([id, "%s (dano %d)" % [a["nome"], a["dano"]]])
			perguntar("arma_petrea", "Arma Pétrea: que arma corpo a corpo criar?", ops, {"quem": u.id})
		"muro":
			var cels: Array = area_atual["celulas"].filter(func(p): return not grade.bloqueado(p) and na_posicao(p) == null)
			criar_zona("muro", "Muro de Rocha", cels, u, {"bloqueia": true, "bloqueia_visao": true, "vinculada": false, "vida": 12})
		"enterrar-na-fissura":
			_novo_ataque(u, alvo, {"habilidade": "Enterrar na Fissura", "magico": true, "ao_acertar": [{"ficha": "Imobilizar"}]})
		"passo-leve":
			u.efeitos["passo_leve"] = {}
			_log("Passo Leve: até o fim da cena, %s ignora terreno difícil." % u.nome)
		"rajada":
			_novo_ataque(u, alvo, {"habilidade": "Rajada", "magico": true, "ao_acertar": [{"empurrar": 2}]})
		"ventos-cortantes":
			_novo_ataque(u, alvo, {"habilidade": "Ventos Cortantes", "magico": true, "bonus_dano": 2, "rotulo_bonus": "Ventos Cortantes",
				"ao_acertar": [{"ficha": "Sangramento"}]})
		"lanterna-palida":
			criar_luz(area_atual["alvo"], 4, 4, "Lanterna Pálida", u)
		"clarao-revelador":
			for o in unidades:
				if o.viva() and o != u and Grade.distancia(o.pos, u.pos) <= 4 and o.eh_heroi() != u.eh_heroi():
					o.efeitos.erase("oculto")
					o.efeitos["revelado"] = {"ate_turno_de": u.id}
			_log("Clarão Revelador: quem se escondia perto de %s fica à vista até o próximo turno dele." % u.nome)
		"flecha-de-luz":
			_novo_ataque(u, alvo, {"habilidade": "Flecha de Luz", "magico": true, "ao_acertar": [{"ficha": "Cegueira"}]})
		"veu":
			u.efeitos["oculto"] = {}
			_log("Véu: %s fica oculto até atacar." % u.nome)
		"lamina-das-sombras":
			var outros: Array = inimigos_vivos().filter(func(o): return o != alvo and Grade.adjacentes(o.pos, u.pos)) \
				if u.eh_heroi() else []
			if outros.is_empty() or u.baralho.mao.is_empty():
				_lamina_das_sombras(u, alvo, null)
			else:
				var ops := [["", "Só %s (não descartar)" % alvo.nome]]
				for o in outros:
					ops.append([o.id, "Descartar 1 carta e atingir também %s" % o.nome])
				perguntar("lamina_segundo", "Lâmina das Sombras: descartar a carta de menor valor da mão para afetar 2 alvos?", ops,
					{"quem": u.id, "alvo": alvo.id})
		"terror-abismal":
			for o in unidades:
				if not o.viva() or o == u or Grade.distancia(o.pos, u.pos) > ALCANCE_VISAO or not grade.linha_de_visao(o.pos, u.pos):
					continue
				if _resiste(o, "espirito", 18):
					_log("Terror Abismal: %s resiste." % o.nome)
				else:
					o.dar_ficha("Medo")
					_log("Terror Abismal: %s recebe 1 ficha de Medo." % o.nome)


## A tela liga: perguntas de escolha (qual carta descartar, que item recuperar...).
## Desligado (testes e simulação), o jogo escolhe a opção mais simples.
var perguntar_escolhas := false


func eh_fera(o: Unidade) -> bool:
	return o.tipo in ARMA_NATURAL


## Bônus das magias que não são ataque (dano direto): Poder de Combate e Mente Bélica.
func _bonus_de_magia_direta(u: Unidade) -> int:
	var b := 2 if u.ativo("poder-de-combate") else 0
	if u.efeitos.has("mente_belica"):
		u.efeitos.erase("mente_belica")
		b += 3
	return b


## Desencadeada de O Martelo da Luz: um efeito inimigo pôs fichas nas cartas do herói.
func fichas_de_inimigo(h: Unidade, responsavel: Unidade) -> void:
	if h.eh_heroi() and h.ativo("o-martelo-da-luz") and responsavel != null and responsavel.viva() and h.sabedoria > 0:
		_dano_direto(responsavel, h.sabedoria, "O Martelo da Luz")


func _menor_da_mao(u: Unidade) -> int:
	var menor: int = u.baralho.mao[0]
	for carta in u.baralho.mao:
		if Carta.valor(carta) < Carta.valor(menor):
			menor = carta
	return menor


func _mente_belica(u: Unidade, carta: int) -> void:
	if not carta in u.baralho.mao:
		carta = _menor_da_mao(u)
	u.baralho.tirar_da_mao(carta)
	u.baralho.descarte.append(carta)
	u.efeitos["mente_belica"] = {}
	_log("Mente Bélica: %s descarta %s; a próxima magia causa +3." % [u.nome, Carta.nome(carta)])


func _recuperar_consumivel(u: Unidade, item: String) -> void:
	if not item in u.gastos:
		item = u.gastos.back()
	u.gastos.erase(item)
	u.consumiveis.append(item)
	u.efeitos["plano_usado"] = {}
	_log("Sempre um Plano: %s recupera %s." % [u.nome, _nome_item(item)])


func _segundo_vento(u: Unidade, opcao: String) -> void:
	if opcao == "curar" or not opcao.is_valid_int() or int(opcao) >= u.cartas.size():
		_curar(u, u.constituicao, "sente o Segundo Vento")
		return
	var alvo_c = u.cartas[int(opcao)]
	var tirou := mini(alvo_c.fadiga, u.espirito)
	alvo_c.fadiga -= tirou
	_log("Segundo Vento: %d de fadiga sai de %s." % [tirou, alvo_c.nome()])


## Mísseis Mágicos: "ids" diz quem leva cada míssil (até 3 alvos, repetir vale).
var misseis_atual: Array = []


func heroi_usar_misseis(indice: int, ids: Array) -> bool:
	var u := ativa()
	if indice < 0 or indice >= u.cartas.size() or ids.is_empty() or ids.size() > 3:
		return false
	var validos := alvos_de_habilidade(u, u.cartas[indice]).map(func(o): return o.id)
	if not ids.all(func(i): return i in validos):
		return false
	misseis_atual = ids.duplicate()
	var ok := heroi_usar_carta(indice, unidade(ids[0]))
	misseis_atual = []
	return ok


## Opções de cartas que não são do repertório de Aprendiz (Bênção dos Salmos, Salmos
## da Ira, Óleos e Iscas, Sempre um Plano) e cartas com escolha (Mente Bélica, Mísseis).
func usar_opcao(u: Unidade, c, alvo: Unidade) -> void:
	match c.slug():
		"mente-belica":
			if u.baralho.mao.size() > 1 and perguntar_escolhas:
				var ops := []
				for carta in u.baralho.mao:
					ops.append([str(carta), Carta.nome(carta)])
				perguntar("mente_belica", "Mente Bélica: que carta da mão descartar?", ops, {"quem": u.id})
			else:
				_mente_belica(u, _menor_da_mao(u))
			return
		"misseis-magicos":
			var ids: Array = misseis_atual if not misseis_atual.is_empty() else [alvo.id, alvo.id, alvo.id]
			var por_alvo := {}
			for id in ids:
				por_alvo[id] = int(por_alvo.get(id, 0)) + 1
			var extra := _bonus_de_magia_direta(u)
			for id in por_alvo:
				var o := unidade(id)
				if o != null and o.viva():
					_dano_direto(o, int(por_alvo[id]) + extra, "Mísseis Mágicos")
					extra = 0
			return
	match c.opcao:
		"recuperar":
			var itens := []
			for item in u.gastos:
				if not itens.has(item):
					itens.append(item)
			if itens.size() > 1 and perguntar_escolhas:
				perguntar("plano", "Sempre um Plano: que consumível recuperar?", itens.map(func(i): return [i, _nome_item(i)]), {"quem": u.id})
			else:
				_recuperar_consumivel(u, u.gastos.back())
		"comprar":
			u.baralho.comprar_para_mao(1)
			_log("Sempre um Plano: %s compra uma carta." % u.nome)
		"resistencia":
			alvo.efeitos["bencao_dos_salmos"] = {"ate": "inicio_turno"}
			_log("Bênção dos Salmos: %s ganha resistência 1 até o início do próximo turno." % alvo.nome)
		"curar":
			_curar(alvo, 3, "recebe a Bênção dos Salmos")
		"remover":
			var fichas := []
			for f in Classes.FICHAS_RUINS + ["Atormentado", "Marcado"]:
				if alvo.fichas_total(f) > 0 and not fichas.has(f):
					fichas.append(f)
			if fichas.is_empty():
				_log("Bênção dos Salmos: %s não tem fichas para remover." % alvo.nome)
			elif fichas.size() > 1 and perguntar_escolhas:
				perguntar("remover_ficha", "Bênção dos Salmos: que ficha remover de %s?" % alvo.nome, fichas.map(func(f): return [f, f]), {"alvo": alvo.id})
			else:
				alvo.tirar_fichas(fichas[0], 1)
				_log("Bênção dos Salmos: sai 1 ficha de %s de %s." % [fichas[0], alvo.nome])
		"dano":
			_dano_direto(alvo, 2 + _bonus_de_magia_direta(u), "Salmos da Ira")
		"cegueira":
			alvo.dar_ficha("Cegueira")
			_log("Salmos da Ira: %s fica cego (1 ficha de Cegueira)." % alvo.nome)
		"cone":
			_ataque_em_area(u, unidades_em(area_atual["celulas"]), {"habilidade": "Salmos da Ira", "magico": true})
		"oleo-1", "oleo-2", "oleo-3":
			var n := int(c.opcao.right(1))
			alvo.dar_ficha("Fogo", n)
			_log("Óleo Inflamável: %s pega fogo (%d ficha(s) de Fogo)." % [alvo.nome, n])
		"isca":
			var cel: Vector2i = area_atual["alvo"]
			var feras := inimigos_vivos().filter(func(o): return eh_fera(o) and Grade.distancia(o.pos, u.pos) <= 8)
			feras.sort_custom(func(a, b2): return Grade.distancia(a.pos, cel) < Grade.distancia(b2.pos, cel))
			var f: Unidade = feras[0]
			if valor_resistido(f, "espirito") >= DIFICULDADE_ISCA:
				_log("Isca: %s não se interessa." % f.nome)
			else:
				f.efeitos["isca"] = {"pos": cel}
				_log("Isca: %s vai gastar a próxima movimentação indo até a isca." % f.nome)
		"oleo-area":
			for p in area_atual["celulas"]:
				var o := na_posicao(p)
				if o != null:
					o.dar_ficha("Fogo")
					_log("Óleo Inflamável: %s pega fogo." % o.nome)
				elif not grade.bloqueado(p):
					grade.obstaculos[p] = "fogueira"
					chamas[p] = 3
			_log("Óleo Inflamável: as chamas tomam a área (queimam por 3 rodadas).")
			eventos.append({"tipo": "mapa"})
		"dano-sagrado":
			_dano_direto(alvo, 2 + _bonus_de_magia_direta(u), "Água Benta")
		"iluminar":
			u.efeitos["luz_da_verdade"] = {"raio": maxi(u.espirito, 1), "ate_turno_de": u.id}
			_log("Luz da Verdade: %s ilumina ao redor (alcance %d) até o próximo turno." % [u.nome, maxi(u.espirito, 1)])
			eventos.append({"tipo": "mapa"})
		"tirar-sombra":
			var n_s := alvo.tirar_fichas("Sombra")
			alvo.efeitos.erase("oculto")
			_log("Luz da Verdade: %s perde %d ficha(s) de Sombra e fica à vista." % [alvo.nome, n_s])
		"antidoto":
			var n := alvo.tirar_fichas("Veneno")
			_log("Antídoto: sai(em) %d ficha(s) de Veneno de %s." % [n, alvo.nome])
		"emplastro":
			alvo.tirar_fichas("Sangramento", 1)
			alvo.tirar_fichas("Ferimento", 1)
			_log("Emplastro: sai 1 Sangramento e 1 Ferimento de %s." % alvo.nome)


## A carta não diz a dificuldade de resistir à Isca: 16, como a Nuvem de Brasas.
const DIFICULDADE_ISCA := 16


# --- Conjuração (0.15): a fadiga da magia pode ir para outras cartas ----------

## Cartas com o símbolo de Conjuração (tag "Conjuração" na planilha): o custo de
## fadiga pode ser pago com o espaço livre de outras cartas do herói.
static func eh_conjuracao(c) -> bool:
	return "Conjuração" in c.lado_ativo().get("tags", [])


func espaco_de_fadiga(u: Unidade, c) -> int:
	if not eh_conjuracao(c):
		return c.espaco()
	var total := 0
	for outra in u.cartas:
		total += maxi(outra.espaco(), 0)
	return total


func pode_pagar_fadiga(u: Unidade, c, custo: int) -> bool:
	return custo <= espaco_de_fadiga(u, c)


## Paga primeiro na própria carta; o que sobrar vai para as outras com mais espaço.
## Quanto da fadiga não cabe na própria carta (Conjuração): o jogador espalha.
func sobra_de_fadiga(u: Unidade, c, custo: int) -> int:
	if not eh_conjuracao(c):
		return 0
	return maxi(custo - maxi(c.espaco(), 0), 0)


## Cartas que podem receber a sobra: [{"indice", "nome", "espaco"}].
func cartas_para_fadiga(u: Unidade, c) -> Array:
	var lista := []
	for i in u.cartas.size():
		var outra = u.cartas[i]
		if outra != c and outra.espaco() > 0:
			lista.append({"indice": i, "nome": outra.nome(), "espaco": outra.espaco()})
	return lista


## A tela põe aqui a escolha do jogador antes de usar a carta: {índice da carta: fadiga}.
var fadiga_escolhida := {}


func pagar_fadiga(u: Unidade, c, custo: int) -> void:
	var cheias := []
	var resto := custo
	var aqui := mini(resto, maxi(c.espaco(), 0)) if eh_conjuracao(c) else resto
	c.pagar(aqui)
	resto -= aqui
	if c.limite() > 0 and c.fadiga >= c.limite():
		cheias.append(c)
	# Escolha do jogador (Lucas: espalha como o dano entre escudo, armadura e baralho).
	var escolha := fadiga_escolhida
	fadiga_escolhida = {}
	for idx in escolha:
		var i := int(idx)
		if resto <= 0 or i < 0 or i >= u.cartas.size() or u.cartas[i] == c:
			continue
		var alvo_c = u.cartas[i]
		var n := mini(mini(int(escolha[idx]), resto), maxi(alvo_c.espaco(), 0))
		if n <= 0:
			continue
		alvo_c.pagar(n)
		resto -= n
		_log("Conjuração: %d de fadiga vai para %s." % [n, alvo_c.nome()])
		if alvo_c.fadiga >= alvo_c.limite():
			cheias.append(alvo_c)
	while resto > 0:
		var melhor = null
		for outra in u.cartas:
			if outra != c and outra.espaco() > 0 and (melhor == null or outra.espaco() > melhor.espaco()):
				melhor = outra
		if melhor == null:
			break
		var n := mini(resto, melhor.espaco())
		melhor.pagar(n)
		resto -= n
		_log("Conjuração: %d de fadiga vai para %s." % [n, melhor.nome()])
		if melhor.fadiga >= melhor.limite():
			cheias.append(melhor)
	if u.ativo("controlador-do-arcano"):
		for cheia in cheias:
			u.carta_heroi().dar_ficha("Foco")
			_log("Controlador do Arcano: %s encheu de fadiga, %s ganha 1 ficha de Foco." % [cheia.nome(), u.nome])


# --- Tipos de dano e devoções (0.15) -------------------------------------------

var tipo_da_magia_atual := ""   # tipo do dano da carta sendo usada (tags da planilha)


## Tipo do dano de uma magia pelas tags da carta: Radiante e Luz = Radiante; Fogo; Terra = Concussão.
## Magia divina sem tipo usa a devoção do Clérigo; o resto é Arcano.
func _tipo_da_carta(c) -> String:
	var tags: Array = c.lado_ativo().get("tags", [])
	if "Radiante" in tags or "Luz" in tags:
		return "Radiante"
	if "Fogo" in tags:
		return "Fogo"
	if "Terra" in tags:
		return "Concussão"
	return ""


## Tipos do dano de um ataque: o da magia, ou o da arma; O Martelo da Luz soma o da devoção.
func tipos_de_dano(u: Unidade, contexto: Dictionary) -> Array:
	var tipos := []
	if contexto.has("tipo_dano"):
		tipos.append(contexto["tipo_dano"])
	elif contexto.get("magico", false):
		tipos.append(Devocoes.de(u.divindade)["tipo_dano"] if u.classe == "Clérigo" else "Arcano")
	elif u.eh_heroi():
		tipos.append(u.arma.get("tipo_dano", "Concussão"))
	else:
		tipos.append(u.tipo_dano)
	for t in contexto.get("tipos_extra", []):
		tipos.append(t)
	if u.eh_heroi() and not contexto.get("magico", false) and u.efeitos.has("martelo_da_luz"):
		tipos.append(Devocoes.de(u.divindade)["tipo_dano"])
	return tipos


## Fraquezas e resistências por tipo do alvo; bônus contra categorias; devoção.
## Fraquezas e resistências que os heróis já descobriram, por tipo de inimigo (0.21: a
## ficha do monstro só mostra o que foi descoberto). {tipo: {"fraquezas": {}, "resistencias": {}}}
var descobertas := {}


func _descobrir(alvo: Unidade, chave: String, tipo_dano: String, valor: int) -> void:
	if alvo.eh_heroi():
		return
	if not descobertas.has(alvo.tipo):
		descobertas[alvo.tipo] = {"fraquezas": {}, "resistencias": {}}
	descobertas[alvo.tipo][chave][tipo_dano] = valor


func _bonus_por_tipo(u: Unidade, alvo: Unidade, acerto: bool) -> Array:
	var lista := []
	var tipos := tipos_de_dano(u, ctx)
	var fraq := 0
	var tipo_fraco := ""
	for t in tipos:
		if int(alvo.fraquezas.get(t, 0)) > fraq:
			fraq = int(alvo.fraquezas[t])
			tipo_fraco = t
	if fraq > 0:
		lista.append(["fraqueza a %s" % tipo_fraco, fraq])
		_descobrir(alvo, "fraquezas", tipo_fraco, fraq)
	# Resistência ao tipo só vale se todos os tipos do dano forem resistidos (o melhor tipo passa).
	var menor := 999
	for t in tipos:
		menor = mini(menor, int(alvo.resiste_tipo.get(t, 0)))
	if menor > 0 and menor < 999:
		lista.append(["resiste a %s" % "/".join(tipos), -menor])
		if u.eh_heroi() and u.ativo("olho-de-veterano") and not alvo.fraquezas.is_empty():
			var tf: String = alvo.fraquezas.keys()[0]
			_descobrir(alvo, "fraquezas", tf, int(alvo.fraquezas[tf]))
			_log("Olho de Veterano: %s descobre que %s é fraco contra %s." % [u.nome, alvo.nome, tf])
		for t in tipos:
			_descobrir(alvo, "resistencias", t, int(alvo.resiste_tipo.get(t, 0)))
	if acerto:
		for b in ctx.get("bonus_contra", []):
			if alvo.categoria in b["cats"]:
				lista.append([b["rotulo"], int(b["valor"])])
	if u.eh_heroi() and u.ativo("o-martelo-da-luz") and Devocoes.inimigo_da_devocao(u.divindade, alvo.categoria):
		lista.append(["O Martelo da Luz (inimigo da devoção)", 3])
	return lista


# --- Luz e escuro (0.15) ---------------------------------------------------------
##
## Três níveis de luz: 2 = claro, 1 = penumbra, 0 = escuro. Cenários sem "escuro"
## são claros em todo lugar. No escuro só se enxerga o que está iluminado (ou
## penumbra), o que está ao lado, ou tudo como penumbra para quem tem visão no escuro.
## - Atacar quem você não enxerga: só corpo a corpo, com desvantagem (2 cartas).
## - Alvo na penumbra: cobertura parcial contra ataques de longe.
## - Quem segura uma tocha acesa defende com as cartas reveladas (texto da Tocha).
## Fontes: [claro, penumbra] em quadrados, com linha de visão a partir da fonte.

var escuro := false
var luz_ambiente := 0      # noite de lua: 1 (tudo pelo menos penumbra)
var piso := "grama"        # aparência do chão: "grama" ou "pedra"
var recompensa := 0        # ouro pago pelo contrato, na vitória (vila)
var ouro_ganho := 0        # ouro achado durante a missão
var missoes_desbloqueadas: Array = []   # efeito "desbloquear" (campanha)
var lore_achada: Array = []             # efeito "lore"
var luzes: Array = []   # luzes postas: {"pos", "claro", "penumbra", "nome", "segue": id, "ate_turno_de": id}
const LUZES := {"tocha": [4, 8], "lanterna": [4, 4], "fogueira": [3, 6], "tocha_parede": [3, 6],
	"chamas": [2, 4], "fogo": [1, 2], "lanterna_da_fe": [4, 4]}
var _luz_cache := {}
var _luz_chave := ""


func fontes_de_luz() -> Array:
	var lista := []
	for l in luzes:
		var p: Vector2i = l.get("pos", Vector2i.ZERO)
		if l.get("segue", "") != "":
			var dono := unidade(l["segue"])
			if dono == null or not dono.viva():
				continue
			p = dono.pos
		lista.append([p, int(l["claro"]), int(l["penumbra"])])
	for u in unidades:
		if not u.viva():
			continue
		if u.luz != "" and LUZES.has(u.luz):
			lista.append([u.pos, LUZES[u.luz][0], LUZES[u.luz][1]])
		if u.efeitos.has("lanterna_da_fe"):
			lista.append([u.pos, 4, 4])
		if u.efeitos.has("luz_da_verdade"):
			var r := int(u.efeitos["luz_da_verdade"].get("raio", 1))
			lista.append([u.pos, r, r])
		if u.fichas_total("Fogo") > 0:
			lista.append([u.pos, LUZES["fogo"][0], LUZES["fogo"][1]])
	for p in grade.obstaculos:
		var t: String = grade.obstaculos[p]
		if t in ["fogueira", "tocha_parede"]:
			lista.append([p, LUZES[t][0], LUZES[t][1]])
	for p in chamas:
		lista.append([p, LUZES["chamas"][0], LUZES["chamas"][1]])
	return lista


func mapa_de_luz() -> Dictionary:
	var fontes := fontes_de_luz()
	var chave := str(fontes) + "|" + str(grade.visao_bloqueada.size()) + "|" + str(grade.obstaculos.size())
	if chave == _luz_chave:
		return _luz_cache
	var m := {}
	for f in fontes:
		var origem: Vector2i = f[0]
		var r: int = maxi(f[1], f[2])
		for x in range(-r, r + 1):
			for y in range(-r, r + 1):
				var p := origem + Vector2i(x, y)
				if not grade.dentro(p):
					continue
				var d := Grade.distancia(origem, p)
				var nivel := 2 if d <= int(f[1]) else 1
				if int(m.get(p, 0)) >= nivel or not grade.linha_de_visao(origem, p):
					continue
				m[p] = nivel
	_luz_cache = m
	_luz_chave = chave
	return m


func nivel_de_luz(p: Vector2i) -> int:
	if not escuro:
		return 2
	return maxi(int(mapa_de_luz().get(p, 0)), luz_ambiente)


func enxerga_no_escuro(u: Unidade) -> bool:
	return u.visao_no_escuro or u.ativo("visao-elfica") or u.ativo("filho-da-pedra") or u.ativo("mestre-das-cavernas")


## Nível de luz como "u" percebe: com visão no escuro, o escuro vale como penumbra.
func nivel_visto_por(u: Unidade, p: Vector2i) -> int:
	var n := nivel_de_luz(p)
	if n == 0 and enxerga_no_escuro(u):
		return 1
	return n


## "u", parado em "de", enxerga o quadrado "p"? (distância e linha de visão à parte)
func ve_de(u: Unidade, de: Vector2i, p: Vector2i) -> bool:
	if not escuro or Grade.distancia(de, p) <= 1:
		return true
	return nivel_visto_por(u, p) >= 1


## Mãos livres: a arma ocupa 1 (2 se for de duas mãos), o escudo 1, o foco as dele.
func maos_livres(u: Unidade) -> int:
	var ocupadas := 0
	if not u.arma.is_empty() and u.arma.get("nome", "") != DESARMADO["nome"]:
		ocupadas += 2 if u.arma.get("duas_maos", false) or u.arma.get("tamanho", "") == "grande" else 1
	if not u.escudo.is_empty() and u.escudo.get("nome", "Sem escudo") != "Sem escudo":
		ocupadas += 1
	ocupadas += int(u.foco.get("maos", 0))
	return 2 - ocupadas   # pode ficar negativo (sobrou coisa nas mãos)


## Acender ou apagar a luz que o herói carrega. Tocha: gasta 1 tocha dos consumíveis,
## a ação Padrão (texto do item: "AÇÃO: Acender") e uma mão livre. Lanterna: ação de
## movimento; presa ao cinto, não ocupa as mãos (planilha: "com as mãos livres"). Apagar é livre.
func motivo_luz(u: Unidade, tipo: String) -> String:
	if u.luz == tipo:
		return ""
	if u.luz != "":
		return "já carrega uma luz acesa"
	if tipo == "tocha" and maos_livres(u) <= 0 and u.luz != "tocha":
		return "precisa de uma mão livre"
	if tipo == "tocha":
		if not "tocha" in u.consumiveis:
			return "sem tocha"
		if u.acoes_padrao <= 0:
			return "sem ação padrão"
	elif tipo == "lanterna":
		if not "lanterna" in u.equipamentos:
			return "sem lanterna"
		if u.acoes_mov <= 0 and u.acoes_padrao <= 0:
			return "sem ação de movimento"
	return ""


func heroi_luz(tipo: String) -> bool:
	var u := ativa()
	if not vez_do_heroi() or motivo_luz(u, tipo) != "":
		return false
	if u.luz == tipo:
		u.luz = ""
		_log("%s apaga a %s." % [u.nome, "tocha" if tipo == "tocha" else "lanterna"])
	elif tipo == "tocha":
		u.consumiveis.erase("tocha")
		u.gastos.append("tocha")
		u.acoes_padrao -= 1
		u.luz = "tocha"
		_log("%s acende uma tocha (ilumina ao alcance curto; penumbra até o médio)." % u.nome)
	else:
		if u.acoes_mov > 0:
			u.acoes_mov -= 1
		else:
			u.acoes_padrao -= 1
		u.luz = "lanterna"
		_log("%s acende a lanterna (ilumina ao alcance curto)." % u.nome)
	eventos.append({"tipo": "mapa"})
	return true


## Luz posta num ponto (Lanterna Pálida): até o fim da cena.
func criar_luz(pos: Vector2i, claro: int, penumbra: int, nome: String, dono: Unidade = null) -> void:
	luzes.append({"pos": pos, "claro": claro, "penumbra": penumbra, "nome": nome, "dono": dono.id if dono != null else ""})
	_log("%s: luz no mapa." % nome)
	eventos.append({"tipo": "mapa"})


## Quadrados a até "r" de "p" (para zonas centradas em alguém).
func celulas_ao_redor(p: Vector2i, r: int) -> Array:
	var lista := []
	for x in range(-r, r + 1):
		for y in range(-r, r + 1):
			var c := p + Vector2i(x, y)
			if grade.dentro(c):
				lista.append(c)
	return lista


## Zonas que andam com o dono (Rito de Purificação).
func _zonas_seguem(u: Unidade) -> void:
	var mudou := false
	for z in zonas:
		if z.get("segue", "") == u.id:
			z["celulas"] = celulas_ao_redor(u.pos, int(z.get("raio", 4)))
			mudou = true
	if mudou:
		_atualizar_zonas_no_mapa()


## Rito de Purificação: morto-vivo ou demônio que começa ou termina o turno na área
## ganha 1 Penalidade e sofre 1 de dano que não pode ser reduzido.
func _rito_no_turno(u: Unidade) -> void:
	if not u.viva() or not u.categoria in ["morto-vivo", "demonio"]:
		return
	var z := zona_em(u.pos, "rito")
	if z.is_empty() or _zona_aliada(z, u):
		return
	u.dar_ficha("Penalidade")
	_dano_direto(u, 1, "Rito de Purificação")


## Entra uma unidade no meio da cena (horda da simulação, reforços): vai para o fim da iniciativa.
func adicionar_unidade(cfg: Dictionary) -> Unidade:
	var u: Unidade = Unidade.criar(cfg, rng)
	unidades.append(u)
	ordem.append(u.id)
	eventos.append({"tipo": "entrar", "id": u.id})
	return u



# --- Ficha de Foco: descarte para scry 1 (glossário) --------------------------------

## Scry: olha as cartas do topo do baralho, uma a uma, e escolhe deixar ou mandar ao fundo.
var scry_pendente := {}   # {"quem", "faltam"}


func heroi_usar_foco() -> bool:
	var u := ativa()
	if not vez_do_heroi() or u.fichas_total("Foco") <= 0 or u.baralho.baralho.is_empty():
		return false
	u.tirar_fichas("Foco", 1)
	_log("%s descarta 1 ficha de Foco: scry 1." % u.nome)
	scry(u, 1)
	return true


func scry(u: Unidade, n: int) -> void:
	var cartas := []
	for k in mini(n, u.baralho.baralho.size()):
		cartas.append(u.baralho.baralho.pop_back())   # cartas[0] = a do topo
	scry_pendente = {"quem": u.id, "cartas": cartas, "ficam": []}
	_scry_proxima()


func _scry_proxima() -> void:
	var u := unidade(scry_pendente["quem"])
	var cartas: Array = scry_pendente["cartas"]
	if cartas.is_empty():
		var ficam: Array = scry_pendente["ficam"]
		for k in range(ficam.size() - 1, -1, -1):
			u.baralho.baralho.append(ficam[k])   # voltam ao topo na mesma ordem
		scry_pendente = {}
		return
	var c: int = cartas[0]
	if not perguntar_escolhas:
		_scry_decidir("fundo" if Carta.valor(c) <= 5 else "topo")
		return
	perguntar("scry", "Scry: %s (carta %d do topo). Deixar no topo ou mandar para o fundo do baralho?" % [Carta.nome(c), scry_pendente["ficam"].size() + 1],
		[["topo", "Deixar no topo"], ["fundo", "Mandar para o fundo"]], {})


func _scry_decidir(opcao: String) -> void:
	var u := unidade(scry_pendente["quem"])
	var c: int = scry_pendente["cartas"].pop_front()
	if opcao == "fundo":
		u.baralho.baralho.insert(0, c)
		_log("%s manda %s para o fundo do baralho." % [u.nome, Carta.nome(c)])
	else:
		scry_pendente["ficam"].append(c)
	_scry_proxima()



# --- Mãos e troca de arma (0.16) ------------------------------------------------------

## O que está em cada mão: [mão principal, outra mão]. "" = livre.
func maos_de(u: Unidade) -> Array:
	var maos := ["", ""]
	var tem_arma: bool = not u.arma.is_empty() and u.arma.get("nome", "") != DESARMADO["nome"]
	if tem_arma:
		maos[0] = u.arma["nome"]
		if u.arma.get("duas_maos", false) or u.arma.get("tamanho", "") == "grande":
			maos[1] = u.arma["nome"] + " (duas mãos)"
	var outros := []
	if not u.escudo.is_empty() and u.escudo.get("nome", "Sem escudo") != "Sem escudo":
		outros.append(u.escudo["nome"])
	for k in int(u.foco.get("maos", 0)):
		outros.append(u.foco.get("nome", "foco"))
	if u.luz == "tocha":
		outros.append("Tocha acesa")
	for o in outros:
		if maos[1] == "":
			maos[1] = o
		elif maos[0] == "":
			maos[0] = o
	return maos


## Trocar de arma (guarda a da mão e pega a reserva): ação de movimento (ou Padrão);
## arma grande na troca custa duas ações (texto do PDF). Bandoleira de Armas: duas trocas
## por cena sem custo. Se a nova arma não deixar mão para a tocha, a tocha apaga.
## Troca de arma (Lucas, 0.19): 1 ação Padrão; de ou para arma grande, 2 ações Padrão.
## Bandoleira de Armas: 2 trocas por cena sem custo, no máximo 1 por turno.
func custo_troca(u: Unidade) -> int:
	if u.efeitos.has("troca_livre"):
		return 0
	# Devorador de Grimórios (ativada): uma troca por rodada é ação livre.
	if u.eh_heroi() and u.ativo("devorador-de-grimorios") and int(u.efeitos.get("devorador_troca", {}).get("rodada", -1)) != rodada:
		return 0
	if "bandoleira_de_armas" in u.equipamentos and int(u.efeitos.get("bandoleira", {}).get("usos", 0)) < 2 \
			and int(u.efeitos.get("bandoleira", {}).get("rodada", -1)) != rodada:
		return 0
	var grande: bool = u.arma.get("tamanho", "") == "grande" or u.arma_reserva.get("tamanho", "") == "grande"
	return 2 if grande else 1


func motivo_troca(u: Unidade) -> String:
	if u.arma_reserva.is_empty():
		return "sem segunda arma"
	var custo := custo_troca(u)
	if u.acoes_padrao < custo:
		return "precisa de %d ação(ões) Padrão" % custo
	return ""


func heroi_trocar_arma() -> bool:
	var u := ativa()
	if not vez_do_heroi() or motivo_troca(u) != "":
		return false
	var custo := custo_troca(u)
	if custo == 0 and u.ativo("devorador-de-grimorios") and int(u.efeitos.get("devorador_troca", {}).get("rodada", -1)) != rodada:
		u.efeitos["devorador_troca"] = {"rodada": rodada}
	elif custo == 0:
		u.efeitos["bandoleira"] = {"usos": int(u.efeitos.get("bandoleira", {}).get("usos", 0)) + 1, "rodada": rodada}
	u.acoes_padrao -= custo
	u.efeitos.erase("troca_livre")
	for ca in u.cartas:
		if ca.tipo == "arma" and ca.lados.size() > 1:
			ca.virar()   # a carta de arma vira junto (apaga as fichas dela, como virar qualquer carta)
	var na_mao := {} if u.efeitos.has("sem_arma") else u.arma.duplicate(true)
	var nova := u.arma_reserva.duplicate(true)
	u.arma_reserva = na_mao
	_equipar(u, nova)
	_log("%s troca de arma: agora usa %s%s." % [u.nome, nova["nome"], " (Bandoleira: sem custo)" if custo == 0 else ""])
	if u.luz == "tocha" and maos_livres(u) < 1:
		u.luz = ""
		_log("Sem mão para a tocha: ela apaga.")
	return true



# --- Inimigos que conjuram (0.17) -----------------------------------------------------
##
## "magias" do inimigo: [{"id", "nome", "tipo": "ataque"|"ficha", "alcance", "ficha", "qtd", "resistir", "dif"}].
## Antes de a magia acontecer, um herói que pode reagir é perguntado:
## - Mana Densa (o alvo descarta uma carta da mão: anula a magia que tem ele como alvo);
## - Contramagia (1 fadiga, Reação: Raciocínio contra a Sabedoria do conjurador).
## Sem tela (testes e simulação), ninguém reage.

var magia_pendente := {}   # {"conjurador", "alvo", "magia"}


func _ia_conjurar(u: Unidade, alvo: Unidade) -> bool:
	var escolhida := {}
	for m in u.magias:
		var alc := int(m.get("alcance", 8))
		if Grade.distancia(u.pos, alvo.pos) > alc or not grade.linha_de_visao(u.pos, alvo.pos) or not ve_de(u, u.pos, alvo.pos):
			continue
		if m.get("tipo", "") == "ficha" and alvo.fichas_total(m.get("ficha", "")) > 0:
			continue   # não repete a maldição em quem já tem
		escolhida = m
		break
	if escolhida.is_empty():
		return false
	u.acoes_padrao -= 1
	_log("%s conjura %s em %s!" % [u.nome, escolhida["nome"], alvo.nome])
	magia_pendente = {"conjurador": u.id, "alvo": alvo.id, "magia": escolhida}
	var ops := opcoes_de_anular(alvo, u)
	if ops.size() > 1 and perguntar_escolhas:
		perguntar("anular", "%s conjura %s em %s. Reagir?" % [u.nome, escolhida["nome"], alvo.nome], ops, {})
		return true
	_executar_magia_inimiga()
	return true


## Quem pode anular a magia: [[id, texto]]; o primeiro é sempre "deixar".
func opcoes_de_anular(alvo: Unidade, conjurador: Unidade) -> Array:
	var ops := [["nao", "Deixar a magia acontecer"]]
	if alvo.eh_heroi() and alvo.ativo("mana-densa") and not alvo.baralho.mao.is_empty():
		ops.append(["mana:" + alvo.id, "Mana Densa (%s descarta 1 carta da mão e anula)" % alvo.nome])
	for h in herois_ativos():
		var c = h.carta_com("contramagia")
		if c != null and pode_pagar_fadiga(h, c, 1) and h.acoes_reacao > 0 and Grade.distancia(h.pos, conjurador.pos) <= 12:
			ops.append(["contra:" + h.id, "Contramagia de %s (1 fadiga, Reação: teste de Raciocínio contra o teste de Sabedoria de %s, Sabedoria %d)" % [h.nome, conjurador.nome, conjurador.sabedoria]])
	return ops


func _anular(opcao: String) -> void:
	var m := magia_pendente
	var conj := unidade(m["conjurador"])
	if opcao.begins_with("mana:"):
		var h := unidade(opcao.substr(5))
		var carta := _menor_da_mao(h)
		h.baralho.tirar_da_mao(carta)
		h.baralho.descarte.append(carta)
		_log("Mana Densa: %s descarta %s e anula %s." % [h.nome, Carta.nome(carta), m["magia"]["nome"]])
		magia_pendente = {}
		return
	if opcao.begins_with("contra:"):
		var h := unidade(opcao.substr(7))
		pagar_fadiga(h, h.carta_com("contramagia"), 1)
		h.acoes_reacao -= 1
		# Lucas (0.19): o conjurador também testa com cartas (Sabedoria), e não um valor fixo.
		var meu := _teste_automatico(h, h.raciocinio)
		var dele := valor_resistido(conj, "sabedoria")
		if meu >= dele:
			_log("Contramagia de %s (%d contra %d): %s é anulada!" % [h.nome, meu, dele, m["magia"]["nome"]])
			magia_pendente = {}
			return
		_log("Contramagia de %s (%d contra %d): falha." % [h.nome, meu, dele])
	_executar_magia_inimiga()


func _executar_magia_inimiga() -> void:
	var m := magia_pendente
	magia_pendente = {}
	if m.is_empty():
		return
	var u := unidade(m["conjurador"])
	var alvo := unidade(m["alvo"])
	var mg: Dictionary = m["magia"]
	if u == null or alvo == null or not u.viva() or not alvo.viva():
		return
	match mg.get("tipo", "ataque"):
		"ataque":
			_novo_ataque(u, alvo, {"habilidade": mg["nome"], "magico": true, "tipo_dano": mg.get("tipo_dano", "Necrótico"),
				"ao_acertar": [{"ficha": mg["ficha"], "qtd": int(mg.get("qtd", 1))}] if mg.has("ficha") else []})
		"ficha":
			if mg.has("resistir") and _resiste(alvo, mg["resistir"], int(mg.get("dif", 16))):
				_log("%s resiste a %s." % [alvo.nome, mg["nome"]])
				return
			alvo.dar_ficha(mg["ficha"], int(mg.get("qtd", 1)))
			_log("%s: %s recebe %d ficha(s) de %s." % [mg["nome"], alvo.nome, int(mg.get("qtd", 1)), mg["ficha"]])
			fichas_de_inimigo(alvo, u)

# --- 0.23: cenas, salas, armadilhas, procurar, levantar caídos, chefes ----------
##
## Gatilhos ("gatilhos" no cenário): ao pisar numa das casas, uma vez, mostra um texto
## (evento "narrativa"), aplica efeitos e pode oferecer procurar armadilhas na sala.
## Grupos ("grupos"): texto quando os heróis veem o grupo pela primeira vez; o grupo
## entra na luta na hora (é uma cena de combate).
## Armadilhas ("armadilhas"): {"id", "sala", "nome", "celulas", "dif_achar", "dif_evitar",
## "dif_desarmar", "dano", "ficha", "texto"}. Escondidas até alguém procurar; quem pisa
## numa armadilha ativa faz um teste para escapar.

var gatilhos: Array = []
var gatilhos_feitos := {}
var armadilhas: Array = []
var textos_de_grupo := {}
var grupos_vistos := {}
var grupos_alertados := {}
var exploracao_livre := false
var salas_procuradas := {}
var abertura := {}


func _iniciar_cenas(cenario: Dictionary) -> void:
	gatilhos = cenario.get("gatilhos", []).duplicate(true)
	armadilhas = cenario.get("armadilhas", []).duplicate(true)
	textos_de_grupo = cenario.get("grupos", {}).duplicate(true)
	exploracao_livre = cenario.get("exploracao_livre", false)
	abertura = cenario.get("abertura", {})
	for p in cenario.get("niveis", {}):
		grade.niveis[p] = int(cenario["niveis"][p])
	for p in cenario.get("escadas", {}):
		grade.escadas[p] = true


## Combates vencidos: grupos que entraram na luta e não têm mais ninguém de pé.
func combates_vencidos() -> int:
	var grupos := {}
	for o in unidades:
		if o.eh_heroi() or o.grupo == "" or inerte(o):
			continue
		if not grupos.has(o.grupo):
			grupos[o.grupo] = true
		if o.viva():
			grupos[o.grupo] = false
	var n := 0
	for g in grupos:
		if grupos[g] and grupos_alertados.has(g):
			n += 1
	return n


## Herói entrou numa casa: armadilha e gatilho. Devolve true se o movimento para.
func _casa_do_heroi(u: Unidade, p: Vector2i) -> bool:
	for a in armadilhas:
		if a.get("ativa", true) and p in a["celulas"]:
			_disparar_armadilha(u, a)
			return true
	for g in gatilhos:
		if gatilhos_feitos.has(g["id"]) or not p in g["celulas"]:
			continue
		gatilhos_feitos[g["id"]] = true
		_narrar(g.get("titulo", ""), g.get("texto", ""))
		for ef in g.get("efeitos", []):
			_aplicar_efeito(u, {"id": "", "nome": g.get("titulo", ""), "pos": p}, ef)
		if g.get("procurar", false) and perguntar_escolhas:
			perguntar("procurar_sala", "Vocês podem examinar %s antes de seguir. Procurar armadilhas e coisas escondidas? (Percepção + Investigação; não gasta ação)" % g.get("titulo", "a sala").to_lower(),
				[["sim", "Procurar com cuidado"], ["nao", "Seguir em frente"]], {"sala": g.get("sala", g["id"]), "quem": u.id})
		return g.get("parar", true)
	return false


func _narrar(titulo: String, texto: String) -> void:
	if texto == "":
		return
	_log("%s%s" % [(titulo + ". ") if titulo != "" else "", texto])
	eventos.append({"tipo": "narrativa", "titulo": titulo, "texto": texto})


## Os heróis veem um grupo pela primeira vez: texto e o grupo entra na luta.
func _verificar_avistamentos() -> void:
	for o in inimigos_vivos():
		if o.grupo == "" or grupos_vistos.has(o.grupo) or not unidade_visivel(o):
			continue
		grupos_vistos[o.grupo] = true
		var g: Dictionary = textos_de_grupo.get(o.grupo, {})
		if g.is_empty():
			continue
		_narrar(g.get("titulo", "Inimigos!"), g.get("texto", ""))
		if g.get("alerta", true):
			_alertar_inimigos(o.grupo)


## Procurar: Percepção + Investigação. Acha as armadilhas e as coisas escondidas
## ("oculta") da sala ou a até 5 casas. Sem nada a achar, a resposta é a mesma de uma falha.
func _procurar(u: Unidade, sala: String) -> void:
	var achaveis := []
	for a in armadilhas:
		if a.get("ativa", true) and not a.get("revelada", false) and (a.get("sala", "") == sala if sala != "" else a["celulas"].any(func(c): return Grade.distancia(c, u.pos) <= 5)):
			achaveis.append(a)
	var ocultas := interacoes.filter(func(it): return it.get("oculta", false) and not it.get("ativa", true) \
		and (it.get("sala", "") == sala if sala != "" else Grade.distancia(it["pos"], u.pos) <= 5))
	var dif := 16
	for a in achaveis:
		dif = maxi(dif, int(a.get("dif_achar", 16)))
	for it in ocultas:
		dif = maxi(dif, int(it.get("dif_achar", 16)))
	var nada := "Vocês examinam tudo com cuidado e não acham nada de estranho. (Pode ser que não haja nada... ou que tenha passado.)"
	var achados := []
	for a in achaveis:
		achados.append({"tipo": "revelar_armadilha", "id": a["id"]})
	for it in ocultas:
		achados.append({"tipo": "ativar", "id": it["id"], "texto": "Achado: %s." % it["nome"]})
	teste_de_acao(u, {"titulo": "Procurar", "texto": "Procurar", "teste": {"somar": ["percepcao", "Investigação"]}, "dificuldade": dif,
		"tags": ["procurar"], "faixas": [[0, "falha"], [dif, "sucesso"]],
		"resultados": {
			"falha": {"rotulo": "nada", "texto": nada},
			"sucesso": {"rotulo": "atento", "texto": nada if achados.is_empty() else "Olhos treinados acham o que estava escondido.", "efeitos": achados},
		}})


func heroi_procurar() -> bool:
	var u := ativa()
	if not vez_do_heroi() or u.acoes_padrao <= 0 or u.efeitos.has("confuso"):
		return false
	u.acoes_padrao -= 1
	_agiu(u)
	_procurar(u, "")
	return true


func _revelar_armadilha(id: String) -> String:
	for a in armadilhas:
		if a["id"] == id and not a.get("revelada", false):
			a["revelada"] = true
			interacoes.append({"id": "armadilha_" + id, "nome": a["nome"], "pos": a["celulas"][0], "alcance": 1, "armadilha": id,
				"texto": a.get("texto", "Uma armadilha.") + " Casas marcadas em vermelho: quem pisar nelas a dispara.",
				"opcoes": [{"id": "desarmar", "texto": "Desarmar (Ladinagem + Destreza)", "custo": {"padrao": 1},
					"teste": {"somar": ["Ladinagem", "destreza"]}, "dificuldade": int(a.get("dif_desarmar", 16)),
					"faixas": [[0, "falha"], [int(a.get("dif_desarmar", 16)), "sucesso"]],
					"resultados": {
						"falha": {"rotulo": "dispara!", "texto": "Um clique errado e o mecanismo dispara em você.",
							"efeitos": [{"tipo": "dano", "valor": int(a.get("dano", 4))}, {"tipo": "desarmar_armadilha", "id": id}, {"tipo": "desativar"}]},
						"sucesso": {"rotulo": "desarmada", "texto": "Você trava o mecanismo. As casas estão seguras.",
							"efeitos": [{"tipo": "desarmar_armadilha", "id": id}, {"tipo": "desativar"}, {"tipo": "ouro", "valor": 5}]},
					}}]})
			_atualizar_zonas_no_mapa()
			eventos.append({"tipo": "mapa"})
			return "Armadilha encontrada: %s." % a["nome"]
	return ""


func _desarmar_armadilha(id: String) -> void:
	for a in armadilhas:
		if a["id"] == id:
			a["ativa"] = false
	_atualizar_zonas_no_mapa()


func _disparar_armadilha(u: Unidade, a: Dictionary) -> void:
	a["ativa"] = false
	_atualizar_zonas_no_mapa()
	var dif := int(a.get("dif_evitar", 16))
	_log("%s pisa em %s!" % [u.nome, a["nome"]])
	var efs_falha := [{"tipo": "dano", "valor": int(a.get("dano", 4))}]
	if a.has("ficha"):
		efs_falha.append({"tipo": "fichas_alvo", "ficha": a["ficha"]})
	teste_de_acao(u, {"titulo": a["nome"], "texto": "Escapar da armadilha", "teste": {"somar": ["Acrobacia", "destreza"], "movimento": true},
		"dificuldade": dif, "faixas": [[0, "falha"], [dif, "sucesso"]],
		"resultados": {
			"falha": {"rotulo": "pego", "texto": a.get("texto_disparo", "O mecanismo dispara e pega você em cheio."), "efeitos": efs_falha},
			"sucesso": {"rotulo": "escapa", "texto": "Você ouve o clique e se joga para o lado a tempo."},
		}}, u)


## Casas que os heróis veem como perigosas: armadilhas reveladas e marcas de chefe.
func casas_de_armadilha() -> Array:
	var l := []
	for a in armadilhas:
		if a.get("ativa", true) and a.get("revelada", false):
			l.append_array(a["celulas"])
	return l


# --- Levantar um caído (Medicina) ----------------------------------------------
##
## Lucas (0.23): dificuldade de 17 (40 ou mais cartas no descarte) a 25 (menos de 5).
## Gastar uma cura (poção, kit, carta que cura) soma ao limite: +1 a cada 2 de cura.
## Passou: o caído volta com 20% do descarte + a cura usada.

const CURAS_DE_ITEM := {"pocao_de_cura_pequena": 5, "frutas_silvestres": 2, "kit_medico": 2}


static func dificuldade_de_levantar(descarte: int) -> int:
	return 25 - mini(int(descarte / 5), 8)


func alvos_de_levantar(u: Unidade) -> Array:
	return herois().filter(func(h): return h != u and h.baralho.estado == Baralho.Estado.INCONSCIENTE and Grade.adjacentes(h.pos, u.pos))


## Curas que o herói pode gastar no teste: [id, texto, cura].
func curas_para_levantar(u: Unidade) -> Array:
	var l := []
	for item in CURAS_DE_ITEM:
		if item in u.consumiveis:
			l.append(["item:" + item, "%s (cura %d, +%d no limite)" % [_nome_item(item), CURAS_DE_ITEM[item], ceili(CURAS_DE_ITEM[item] / 2.0)], CURAS_DE_ITEM[item]])
	for i in u.cartas.size():
		var c = u.cartas[i]
		var cura := 0
		match c.slug():
			"toque-restaurador":
				cura = 3 + u.sabedoria
			"primeiros-socorros":
				cura = 1
			"ressurgir":
				cura = u.sabedoria
		if cura > 0 and c.pode_pagar(_custo_fadiga(u, c)):
			l.append(["carta:%d" % i, "%s (%d de fadiga; cura %d, +%d no limite)" % [c.nome(), _custo_fadiga(u, c), cura, ceili(cura / 2.0)], cura])
	return l


func heroi_levantar_aliado(alvo: Unidade) -> bool:
	var u := ativa()
	if not vez_do_heroi() or u.acoes_padrao <= 0 or alvo == null or not alvo in alvos_de_levantar(u):
		return false
	var curas := curas_para_levantar(u)
	var dif := dificuldade_de_levantar(alvo.baralho.descarte.size())
	if curas.is_empty() or not perguntar_escolhas:
		_levantar_aliado(u, alvo, "")
		return true
	var ops := [["nada", "Só o teste (dificuldade %d)" % dif]]
	for c in curas:
		ops.append([c[0], "Usar " + c[1]])
	perguntar("levantar", "Levantar %s: Medicina + Sabedoria, dificuldade %d (%d cartas no descarte). Gastar uma cura ajuda?" % [alvo.nome, dif, alvo.baralho.descarte.size()],
		ops, {"alvo": alvo.id})
	return true


func _levantar_aliado(u: Unidade, alvo: Unidade, fonte: String) -> void:
	u.acoes_padrao -= 1
	_agiu(u)
	var cura := 0
	var nome_fonte := ""
	if fonte.begins_with("item:"):
		var item := fonte.substr(5)
		if item in u.consumiveis:
			u.consumiveis.erase(item)
			u.gastos.append(item)
			cura = int(CURAS_DE_ITEM.get(item, 0))
			nome_fonte = _nome_item(item)
	elif fonte.begins_with("carta:"):
		var c = u.cartas[int(fonte.substr(6))]
		var custo := _custo_fadiga(u, c)
		if c.pode_pagar(custo):
			c.pagar(custo)
			match c.slug():
				"toque-restaurador":
					cura = 3 + u.sabedoria
				"primeiros-socorros":
					cura = 1
				"ressurgir":
					cura = u.sabedoria
			nome_fonte = c.nome()
	var dif := dificuldade_de_levantar(alvo.baralho.descarte.size())
	var bonus := ceili(cura / 2.0)
	if nome_fonte != "":
		_log("%s usa %s para ajudar: +%d no limite do teste." % [u.nome, nome_fonte, bonus])
	teste_de_acao(u, {"titulo": "Levantar %s" % alvo.nome, "texto": "Levantar o caído", "teste": {"somar": ["Medicina", "sabedoria"]},
		"dificuldade": dif, "manobra_limite": bonus, "faixas": [[0, "falha"], [dif, "sucesso"]],
		"resultados": {
			"falha": {"rotulo": "não acorda", "texto": "%s não reage. Ainda dá para tentar de novo." % alvo.nome},
			"sucesso": {"rotulo": "de pé", "texto": "%s abre os olhos e se levanta, tonto." % alvo.nome, "efeitos": [{"tipo": "levantar_aliado", "cura": cura}]},
		}}, alvo)


func _efeito_levantar(alvo: Unidade, cura: int) -> String:
	if alvo == null or alvo.baralho.estado != Baralho.Estado.INCONSCIENTE:
		return ""
	var n := maxi(int(alvo.baralho.descarte.size() * 0.2) + cura, 1)
	var voltou := alvo.baralho._devolver_do_descarte(n)
	alvo.efeitos.erase("caido")
	eventos.append({"tipo": "reviver", "id": alvo.id})
	return "%s volta com %d carta(s) no baralho (20%% do descarte%s)." % [alvo.nome, voltou, (" + %d da cura" % cura) if cura > 0 else ""]


# --- Ações especiais de monstros e chefes (0.23) ----------------------------
##
## Unidade.habilidades: lista de {"tipo", ...}. Feitas no começo do turno do monstro,
## sem gastar as ações de ataque (é a "ação a mais" dos chefes):
##   "marcar_area": marca casas em volta de um herói; no próximo turno do monstro, quem
##       ainda estiver nelas sofre "dano" (e "ficha"/"derrubar"). A marca fica vermelha no mapa.
##   "ovo": põe um Ovo do Pântano a ~4 casas; se o ovo viver até o próximo turno do dono,
##       choca e vira uma Cria do Pântano (inimigo médio). Atacar quebra; interagir dá a gema.
##   "teleporte": cercado por heróis, some e reaparece longe, sem ataque de oportunidade.
##   "cavar": some na terra e sai ao lado do herói mais longe (sem impedimento).
##   "muralha": levanta um muro de ossos entre si e o herói mais distante.
##   "defensivo": turno sim, turno não, fica em guarda: não ataca, regenera e sofre metade do dano.
##   "a_cada": de quantos em quantos turnos (padrão 2).

func _ia_habilidades(u: Unidade) -> bool:
	if u.habilidades.is_empty() or u.efeitos.has("hab_turno"):
		return false
	u.efeitos["hab_turno"] = {"ate": "inicio_turno"}
	var cont: Dictionary = u.efeitos.get("turnos_ia", {"n": 0})
	cont["n"] = int(cont["n"]) + 1
	u.efeitos["turnos_ia"] = cont
	var n: int = cont["n"]
	var acabou := false
	for h in u.habilidades:
		var a_cada := int(h.get("a_cada", 2))
		match h["tipo"]:
			"marcar_area":
				var pend: Dictionary = u.efeitos.get("marca_" + str(h.get("nome", "")), {})
				if not pend.is_empty():
					_resolver_marca(u, h, pend)
					u.efeitos.erase("marca_" + str(h.get("nome", "")))
				elif n % a_cada == 0:
					_marcar_area(u, h)
			"ovo":
				for o in unidades:
					if o.viva() and o.efeitos.get("ovo_de", {}).get("dono", "") == u.id and int(o.efeitos["ovo_de"]["turno"]) < n:
						_chocar_ovo(o, h)
				if n % a_cada == 1 or a_cada == 1:
					_por_ovo(u, h)
			"teleporte":
				# Recarga: no máximo uma vez a cada "a_cada" turnos, e só quando está cercado.
				var ultimo := int(u.efeitos.get("teleporte_em", {}).get("n", -99))
				if n - ultimo >= a_cada and herois_ativos().any(func(x): return Grade.adjacentes(x.pos, u.pos)):
					u.efeitos["teleporte_em"] = {"n": n}
					_teleportar_longe(u, h)
			"cavar":
				if n % a_cada == 0:
					_cavar(u, h)
			"muralha":
				if n % a_cada == 0:
					_muralha(u, h)
			"defensivo":
				if n % 2 == 0:
					u.efeitos["postura_defensiva"] = {"ate": "inicio_turno"}
					var antes := u.vida
					u.vida = mini(u.vida + int(h.get("regen", 6)), u.vida_max)
					_narrar(u.nome, h.get("texto", "%s se fecha em guarda: não ataca neste turno e se recompõe." % u.nome))
					eventos.append({"tipo": "cura", "id": u.id, "valor": u.vida - antes})
					eventos.append({"tipo": "reacao_monstro", "id": u.id, "nome": "em guarda"})
					acabou = true
				elif n > 1:
					_log("%s sai da guarda e parte para cima!" % u.nome)
	return acabou


func _marcar_area(u: Unidade, h: Dictionary) -> void:
	var alvo := _escolher_alvo(u)
	if alvo == null:
		return
	var r := int(h.get("raio", 1))
	var cels := []
	for x in range(-r, r + 1):
		for y in range(-r, r + 1):
			var p: Vector2i = alvo.pos + Vector2i(x, y)
			if grade.dentro(p) and not grade.bloqueado(p):
				cels.append(p)
	var z := criar_zona("marca", h.get("nome", "Golpe marcado"), cels, u, {"rodadas": -1, "vinculada": false})
	u.efeitos["marca_" + str(h.get("nome", ""))] = {"zona": z["id"], "celulas": cels}
	_narrar(u.nome, h.get("aviso", "%s se prepara para um golpe devastador: as casas marcadas em vermelho vão ser atingidas no próximo turno dele. Saiam dali!" % u.nome))


func _resolver_marca(u: Unidade, h: Dictionary, pend: Dictionary) -> void:
	for z in zonas.duplicate():
		if z["id"] == pend["zona"]:
			_remover_zona(z, "")
	var cels: Array = pend["celulas"]
	eventos.append({"tipo": "area", "celulas": cels, "tipo_dano": h.get("tipo_dano", "Concussão")})
	var pegos := herois_ativos().filter(func(x): return x.pos in cels)
	if pegos.is_empty():
		_log("%s: %s atinge o vazio. Ninguém ficou na área." % [u.nome, h.get("nome", "o golpe")])
		return
	for x in pegos:
		_dano_direto(x, int(h.get("dano", 6)), h.get("nome", "Golpe"))
		if h.has("ficha"):
			x.dar_ficha(h["ficha"])
		if h.get("derrubar", false):
			derrubar(x)


func _casa_livre_a(centro: Vector2i, minimo: int, maximo: int, perto_de: Vector2i) -> Vector2i:
	var melhor := Vector2i(-1, -1)
	var melhor_d := 999
	for x in range(-maximo, maximo + 1):
		for y in range(-maximo, maximo + 1):
			var p: Vector2i = centro + Vector2i(x, y)
			var d := Grade.distancia(p, centro)
			if d < minimo or d > maximo or not grade.dentro(p) or grade.bloqueado(p) or na_posicao(p) != null:
				continue
			if grade.nivel(p) != grade.nivel(centro):
				continue
			var dd := Grade.distancia(p, perto_de)
			if dd < melhor_d:
				melhor_d = dd
				melhor = p
	return melhor


func _por_ovo(u: Unidade, h: Dictionary) -> void:
	var alvo := _escolher_alvo(u)
	var casa := _casa_livre_a(u.pos, 3, 5, alvo.pos if alvo != null else u.pos)
	if casa == Vector2i(-1, -1):
		return
	var id := "ovo_%d" % unidades.size()
	var o: Unidade = Unidade.criar({"id": id, "nome": "Ovo do Pântano", "lado": "inimigo", "tipo": "ovo", "pos": casa,
		"vida": 6, "dano": 0, "mov_por_turno": 0, "padrao_por_turno": 0, "reacao_por_turno": 0, "alerta": false,
		"grupo": "", "categoria": "fera", "tamanho": "pequeno"}, rng)
	o.efeitos["ovo_de"] = {"dono": u.id, "turno": int(u.efeitos["turnos_ia"]["n"])}
	unidades.append(o)
	interacoes.append({"id": "it_" + id, "nome": "Ovo do Pântano", "pos": casa, "alcance": 1, "unidade": id,
		"texto": "Um ovo escuro, do tamanho de uma cabeça, pulsa no lodo. Se chocar, sai uma cria. Atacar quebra fácil; com cuidado, dá para tirar a gema que ele guarda.",
		"opcoes": [{"id": "gema", "texto": "Abrir com cuidado e tirar a gema (Natureza + Sabedoria)", "custo": {"padrao": 1},
			"teste": {"somar": ["Natureza", "sabedoria"]}, "dificuldade": 16, "faixas": [[0, "falha"], [16, "sucesso"]],
			"resultados": {
				"falha": {"rotulo": "a casca resiste", "texto": "A casca é mais dura do que parece. O ovo continua inteiro."},
				"sucesso": {"rotulo": "gema", "texto": "A casca abre num estalo e a cria morre antes de nascer. A gema escura brilha: vale um bom dinheiro na vila.",
					"efeitos": [{"tipo": "item", "item": "gema_do_pantano"}, {"tipo": "matar_unidade", "id": id}, {"tipo": "desativar"}]},
			}}]})
	eventos.append({"tipo": "surgir", "id": id})
	eventos.append({"tipo": "mapa"})
	_narrar(u.nome, h.get("texto", "%s cospe um ovo escuro no lodo. Se ele não for destruído até o próximo turno dela, algo vai nascer." % u.nome))


func _chocar_ovo(o: Unidade, h: Dictionary) -> void:
	var dono := unidade(o.efeitos["ovo_de"]["dono"])
	o.vida = 0
	eventos.append({"tipo": "sumir", "id": o.id})
	_desativar_interacao_da_unidade(o.id)
	var cfg: Dictionary = h.get("cria", {}).duplicate(true)
	var id := "cria_%d" % unidades.size()
	cfg.merge({"id": id, "nome": "Cria do Pântano", "lado": "inimigo", "tipo": "afogado", "pos": o.pos, "vida": 15, "dano": 5,
		"atributo_dano": 0, "alerta": true, "grupo": dono.grupo if dono != null else "", "categoria": "fera", "velocidade": 3,
		"parada_ataque": 15, "parada_defesa": 15, "risco": 0.3, "mov_por_turno": 1, "padrao_por_turno": 1}, false)
	var c: Unidade = Unidade.criar(cfg, rng)
	unidades.append(c)
	ordem.insert(indice_vez + 1, id)
	eventos.append({"tipo": "surgir", "id": id})
	_narrar("O ovo choca", "A casca se parte e uma cria do pântano se arrasta para fora, faminta.")


func _desativar_interacao_da_unidade(id: String) -> void:
	for it in interacoes:
		if it.get("unidade", "") == id:
			it["ativa"] = false
	eventos.append({"tipo": "mapa"})


func _teleportar_longe(u: Unidade, h: Dictionary) -> void:
	var perto := herois_ativos()
	perto.sort_custom(func(a, b2): return Grade.distancia(a.pos, u.pos) < Grade.distancia(b2.pos, u.pos))
	if perto.is_empty():
		return
	var longe := _casa_livre_a(u.pos, 4, 6, u.pos)
	var melhor := Vector2i(-1, -1)
	var melhor_n := -999
	for x in range(-6, 7):
		for y in range(-6, 7):
			var p: Vector2i = u.pos + Vector2i(x, y)
			if not grade.dentro(p) or grade.bloqueado(p) or na_posicao(p) != null or Grade.distancia(p, u.pos) < 3:
				continue
			var d_min := 99
			for x2 in perto:
				d_min = mini(d_min, Grade.distancia(p, x2.pos))
			var nota := mini(d_min, 6) * 10 + (5 if grade.linha_de_visao(p, perto[0].pos) else 0) - Grade.distancia(p, u.pos)
			if nota > melhor_n:
				melhor_n = nota
				melhor = p
	if melhor == Vector2i(-1, -1):
		melhor = longe
	if melhor == Vector2i(-1, -1):
		return
	u.pos = melhor
	u.efeitos["teleportou"] = {"ate": "inicio_turno"}
	eventos.append({"tipo": "teleporte", "id": u.id})
	_narrar(u.nome, h.get("texto", "%s se desfaz e reaparece longe, fora do alcance das lâminas." % u.nome))


func _cavar(u: Unidade, h: Dictionary) -> void:
	var lista := herois_ativos()
	if lista.is_empty():
		return
	lista.sort_custom(func(a, b2): return Grade.distancia(a.pos, u.pos) > Grade.distancia(b2.pos, u.pos))
	var alvo: Unidade = lista[0]
	var casa := _casa_livre_a(alvo.pos, 1, 1, alvo.pos)
	if casa == Vector2i(-1, -1):
		return
	u.pos = casa
	u.efeitos["alvo_turno"] = {"id": alvo.id, "ate": "inicio_turno"}
	eventos.append({"tipo": "teleporte", "id": u.id})
	_narrar(u.nome, h.get("texto", "%s afunda na terra... e o chão explode ao lado de %s!" % [u.nome, alvo.nome]))


func _muralha(u: Unidade, h: Dictionary) -> void:
	var lista := herois_ativos()
	if lista.is_empty():
		return
	lista.sort_custom(func(a, b2): return Grade.distancia(a.pos, u.pos) > Grade.distancia(b2.pos, u.pos))
	var alvo: Unidade = lista[0]
	if Grade.distancia(alvo.pos, u.pos) < 3:
		return
	var meio: Vector2i = (u.pos + alvo.pos) / 2
	var d := alvo.pos - u.pos
	var perp := Vector2i(0, 1) if absi(d.x) >= absi(d.y) else Vector2i(1, 0)
	var cels := []
	for k in [-1, 0, 1]:
		var p: Vector2i = meio + perp * k
		if grade.dentro(p) and not grade.bloqueado(p) and na_posicao(p) == null:
			cels.append(p)
	if cels.is_empty():
		return
	criar_zona("muro", h.get("nome", "Muralha de Ossos"), cels, u, {"bloqueia": true, "bloqueia_visao": true, "vinculada": false, "vida": int(h.get("vida", 8)), "rodadas": 4})
	_narrar(u.nome, h.get("texto", "%s bate o escudo no chão: ossos brotam da pedra e fecham o caminho até %s." % [u.nome, alvo.nome]))


# --- Intenção do monstro, em tom de narração (Lucas, 0.23) ---------------------

const DICAS := {
	"atacar": ["%s fixa os olhos em %s e aperta a arma.", "%s rosna baixo, sem tirar os olhos de %s.", "%s ajeita os pés, pronto para cair sobre %s."],
	"avancar": ["%s mede a distância até %s.", "%s começa a contornar a luta, de olho em %s.", "%s farejou %s."],
	"atirar": ["%s puxa outra flecha, procurando %s.", "%s semicerra os olhos na direção de %s."],
	"recuar": ["%s recua um passo, procurando espaço longe de %s.", "%s olha por cima do ombro, fugindo do alcance de %s."],
	"magia": ["%s começa a murmurar, olhando para %s.", "O ar em volta de %s fica pesado. Os olhos dele estão em %s."],
	"fugir": ["%s olha para os lados, procurando uma saída.%s"],
	"curar": ["%s se volta para os feridos do bando.%s"],
	"muro": ["%s mede o muro com os olhos.%s"],
	"provocado": ["%s só tem olhos para %s."],
	"confuso": ["%s balança a cabeça, perdido. Parece mirar %s."],
	"soltar": ["%s puxa com força, tentando se soltar.%s"],
}


func _anunciar_intencao(o: Unidade) -> void:
	if o == null or o.eh_heroi() or not o.viva() or not o.alerta or inerte(o) or not unidade_visivel(o):
		return
	var p := _atualizar_plano(o)
	if p.is_empty() or not DICAS.has(p["id"]):
		return
	var frases: Array = DICAS[p["id"]]
	var frase: String = frases[(rodada + o.id.length()) % frases.size()]
	var alvo := unidade(p.get("alvo", ""))
	var texto := frase % [nome_visto(o), alvo.nome if alvo != null else ""]
	o.intencao = texto
	_log(texto)
	eventos.append({"tipo": "intencao", "id": o.id, "texto": texto})
