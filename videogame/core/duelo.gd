## Duelo de teste: um herói contra um inimigo, só com ataques.
##
## Ordem dos turnos pela iniciativa simulada. No turno do herói, cada ação
## padrão pode virar um ataque. Em todo ataque, atacante e defensor compram 2
## cartas (Aberta e Fechada); o atacante joga primeiro, depois o defensor.
## O herói joga seus testes à mão (ataque e defesa); a defesa pode ficar
## automática por opção. O inimigo segue o critério de parada do seu perfil.
##
## A tela chama os métodos do herói (atacar, puxar, jogar_da_mao, parar,
## encerrar_turno, continuar) e, enquanto fase_automatica() for verdadeira,
## chama passo_automatico() com uma pausa entre as chamadas.
extends RefCounted

const Baralho := preload("res://core/baralho.gd")
const BaralhoInimigo := preload("res://core/baralho_inimigo.gd")
const Teste21 := preload("res://core/teste21.gd")
const Combate := preload("res://core/combate.gd")
const Iniciativa := preload("res://core/iniciativa.gd")
const IA := preload("res://core/ia_inimigo.gd")

enum Fase { HEROI_ESCOLHE, HEROI_ATACANDO, IA_DEFENDENDO, IA_ATACANDO, HEROI_DEFENDENDO, RESOLVIDO, VITORIA, DERROTA }

## Parada usada quando a defesa do herói está no automático.
const PARADA_DEFESA_AUTOMATICA := 17

var rng := RandomNumberGenerator.new()
var semente: int
var heroi: Dictionary
var inimigo: Dictionary
var baralho_heroi: Baralho
var baralho_inimigo: BaralhoInimigo
var vida_inimigo: int

var fase: Fase = Fase.HEROI_ESCOLHE
var vez := ""             # "heroi" ou "inimigo"
var ordem: Array = []     # ordem de iniciativa
var rodada := 1
var acoes_restantes := 0
var atacante := ""
var teste_ataque: Teste21
var teste_defesa: Teste21
var resultado: Dictionary = {}
var defesa_automatica := false
var registro: Array[String] = []


func _init(cfg_heroi: Dictionary, cfg_inimigo: Dictionary, semente_inicial: int) -> void:
	semente = semente_inicial
	rng.seed = semente
	heroi = cfg_heroi
	inimigo = cfg_inimigo
	vida_inimigo = inimigo["vida"]
	baralho_heroi = Baralho.new(rng)
	baralho_inimigo = BaralhoInimigo.new(rng)


func iniciar() -> void:
	baralho_heroi.iniciar_cena(heroi["sabedoria"])
	_log("Início da cena: você compra %d cartas para a mão." % baralho_heroi.mao.size())
	ordem = Iniciativa.ordenar([
		{"id": "heroi", "destreza": heroi["destreza"], "iniciativa": heroi["iniciativa"]},
		{"id": "inimigo", "destreza": inimigo["destreza"], "iniciativa": inimigo["iniciativa"]},
	], rng)
	_log("Iniciativa: %s age primeiro." % _nome(ordem[0]))
	_comecar_turno(ordem[0])


# --- Ações do herói ---------------------------------------------------------

func pode_atacar() -> bool:
	return fase == Fase.HEROI_ESCOLHE and acoes_restantes > 0


func atacar() -> bool:
	if not pode_atacar():
		return false
	_novo_ataque("heroi")
	return true


func encerrar_turno() -> bool:
	if fase != Fase.HEROI_ESCOLHE:
		return false
	_log("Você encerra o turno.")
	_proximo_turno()
	return true


func teste_do_heroi() -> Teste21:
	if fase == Fase.HEROI_ATACANDO:
		return teste_ataque
	if fase == Fase.HEROI_DEFENDENDO and not defesa_automatica:
		return teste_defesa
	return null


func puxar() -> bool:
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
	if fase != Fase.RESOLVIDO:
		return false
	acoes_restantes -= 1
	if acoes_restantes > 0:
		if atacante == "heroi":
			fase = Fase.HEROI_ESCOLHE
		else:
			_novo_ataque("inimigo")
	else:
		_proximo_turno()
	return true


# --- Passos automáticos (IA e defesa automática) -----------------------------

func fase_automatica() -> bool:
	return fase == Fase.IA_DEFENDENDO or fase == Fase.IA_ATACANDO \
		or (fase == Fase.HEROI_DEFENDENDO and defesa_automatica)


## Executa um lance automático: puxa uma carta ou para. Retorna true se puxou.
func passo_automatico() -> bool:
	var t: Teste21
	var parada: int
	match fase:
		Fase.IA_DEFENDENDO:
			t = teste_defesa
			parada = inimigo["parada_defesa"]
		Fase.IA_ATACANDO:
			t = teste_ataque
			parada = inimigo["parada_ataque"]
		Fase.HEROI_DEFENDENDO:
			t = teste_defesa
			parada = PARADA_DEFESA_AUTOMATICA
		_:
			return false
	if not t.encerrado and IA.quer_puxar(t, null, true, parada, 1.0, []) and t.puxar():
		if baralho_heroi.estado != Baralho.Estado.ATIVO:
			_terminar_derrota()
		elif t.estourou:
			_avancar_apos_teste(t)
		return true
	t.parar()
	_avancar_apos_teste(t)
	return false


# --- Interno ----------------------------------------------------------------

func _comecar_turno(quem: String) -> void:
	vez = quem
	if quem == "heroi":
		acoes_restantes = heroi["ataques_por_turno"]
		fase = Fase.HEROI_ESCOLHE
		_log("— Rodada %d: seu turno (%d ações padrão)." % [rodada, acoes_restantes])
	else:
		acoes_restantes = inimigo["ataques_por_turno"]
		_log("— Rodada %d: turno do %s." % [rodada, inimigo["nome"]])
		_novo_ataque("inimigo")


func _proximo_turno() -> void:
	var i := ordem.find(vez)
	var proximo: int = (i + 1) % ordem.size()
	if proximo == 0:
		rodada += 1
	_comecar_turno(ordem[proximo])


func _novo_ataque(quem: String) -> void:
	atacante = quem
	resultado = {}
	if quem == "heroi":
		teste_ataque = Teste21.new(baralho_heroi, heroi["ataque"])
		teste_defesa = Teste21.new(baralho_inimigo, inimigo["defesa"])
		fase = Fase.HEROI_ATACANDO
		_log("Você ataca.")
	else:
		teste_ataque = Teste21.new(baralho_inimigo, inimigo["ataque"])
		teste_defesa = Teste21.new(baralho_heroi, heroi["defesa"])
		fase = Fase.IA_ATACANDO
		_log("%s ataca!" % inimigo["nome"])
	if baralho_heroi.estado != Baralho.Estado.ATIVO:
		_terminar_derrota()


func _depois_do_lance_do_heroi(t: Teste21) -> void:
	if baralho_heroi.estado != Baralho.Estado.ATIVO:
		_terminar_derrota()
		return
	if t.encerrado and t.vantagem == false:
		_avancar_apos_teste(t)


func _avancar_apos_teste(t: Teste21) -> void:
	if t.estourou:
		_log("%s estourou." % ("Você" if _dono(t) == "heroi" else inimigo["nome"]))
	if fase == Fase.HEROI_ATACANDO:
		fase = Fase.IA_DEFENDENDO
	elif fase == Fase.IA_ATACANDO:
		fase = Fase.HEROI_DEFENDENDO
	else:
		_resolver()


func _dono(t: Teste21) -> String:
	return "heroi" if t.baralho == baralho_heroi else "inimigo"


func _resolver() -> void:
	var atk := teste_ataque.resultado()
	var dfs := teste_defesa.resultado()
	var acerto := Combate.acertou(atk, dfs)
	var dano := 0
	if atacante == "heroi":
		dano = Combate.calcular_dano(atk, dfs, heroi["dano_arma"], heroi["atributo_dano"], inimigo["resistencia"])
		resultado = {"atacante": "heroi", "ataque": atk, "defesa": dfs, "acertou": acerto, "dano": dano,
			"arma": heroi["dano_arma"], "atributo": heroi["atributo_dano"], "resistencia": inimigo["resistencia"],
			"critico": teste_ataque.critico()}
		if acerto:
			vida_inimigo = maxi(vida_inimigo - dano, 0)
			_log("Você acertou: %d contra %d, %d de dano." % [atk, dfs, dano])
		else:
			_log("Você errou: %d contra %d." % [atk, dfs])
	else:
		dano = Combate.calcular_dano(atk, dfs, inimigo["dano"], 0, heroi["resistencia"])
		resultado = {"atacante": "inimigo", "ataque": atk, "defesa": dfs, "acertou": acerto, "dano": dano,
			"arma": inimigo["dano"], "atributo": 0, "resistencia": heroi["resistencia"],
			"critico": teste_ataque.critico()}
		if acerto:
			baralho_heroi.sofrer_dano(dano)
			_log("%s acertou: %d contra %d, você perde %d cartas." % [inimigo["nome"], atk, dfs, dano])
		else:
			_log("Você se defendeu: %d contra %d." % [atk, dfs])
	if resultado["critico"]:
		_log("21 natural: crítico!")
	fase = Fase.RESOLVIDO
	if vida_inimigo <= 0:
		fase = Fase.VITORIA
		_log("%s foi derrotado. Vitória!" % inimigo["nome"])
	elif baralho_heroi.estado != Baralho.Estado.ATIVO:
		_terminar_derrota()


func _terminar_derrota() -> void:
	# Fecha os testes em andamento para as cartas deles irem ao descarte.
	for t in [teste_ataque, teste_defesa]:
		if t != null:
			t.parar()
			t.confirmar()
	fase = Fase.DERROTA
	_log("Seu baralho acabou: você cai inconsciente. Derrota.")


func _nome(id: String) -> String:
	return "Você" if id == "heroi" else inimigo["nome"]


func _log(texto: String) -> void:
	registro.append(texto)
