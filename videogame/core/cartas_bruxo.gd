## Classe Bruxo (0.25): os 10 pactos e as 18 cartas gerais da "Proposta v02" do Lucas.
##
## Cartas em data/cartas/bruxo.json (tools/gerar_bruxo.py). O herói leva três cartas do pacto
## pleno: a metade de herói do patrono, a carta de PACTO (guarda as fichas de Pacto; não tem
## espaço de fadiga) e a habilidade inicial A/B (de graça). Começo da cena: 2N fichas de Pacto
## (N = nível do pacto); o Pacto Menor (carta geral) recebe N na reserva menor. As reservas
## acabam no fim da cena (recomeçam na próxima). Espírito é o atributo das magias do Bruxo.
##
## Custos "X Pactos" viram opções da carta (como os repertórios): o jogador escolhe quanto gastar.
## Reações com fichas de Pacto são automáticas quando valem a pena (o log conta o que aconteceu).
## Cobranças de mesa (não mentir, aceitar rendições...) ficam com o mestre; as que o jogo mede
## (posição, movimento, fadiga, estouro, mão inicial) suspendem o pacto, e a carta de pacto tem
## a ação "Reparar o pacto".
extends RefCounted

const Grade := preload("res://core/grade.gd")
const Carta := preload("res://core/carta.gd")
const Catalogo := preload("res://core/catalogo.gd")
const IA := preload("res://core/ia_inimigo.gd")

const FICHA := "Pacto"


# --- Registro das cartas ----------------------------------------------------------------------

static func _xs(base: Dictionary, prefixo: String, nome: String, de: int, ate: int, extra := {}) -> Array:
	var lista := []
	for x in range(de, ate + 1):
		var op := base.duplicate(true)
		op.merge(extra, true)
		op["id"] = "%s%d" % [prefixo, x]
		op["nome"] = nome % x if nome.contains("%d") else nome
		op["pactos"] = x
		lista.append(op)
	return lista


static var LADOS := _montar_lados()


static func _montar_lados() -> Dictionary:
	var magia_curta := {"alvo": "inimigo_magico", "alcance": 4, "ataque_magico": true, "magia": true, "custo": {"fadiga": 1, "acao": "padrao"}}
	var r := {
		# Fênix
		"ave-fenix": {"uso": "ativada", "magia": true, "pacto": "fenix",
			"opcoes": _xs(magia_curta, "x", "Ave Fênix + %d Pacto(s)", 0, 3)},
		"absorver-as-chamas": {"uso": "ativada", "magia": true, "pacto": "fenix",
			"opcoes": _xs({"alvo": "nenhum", "custo": {"fadiga": 2, "acao": "padrao"}}, "x", "Absorver + %d Pacto(s)", 0, 3)},
		# Abismo
		"sangrar-o-veu": {"uso": "ativada", "magia": true, "pacto": "abismo",
			"opcoes": _xs(magia_curta, "e", "Sangrar o Véu: exilar %d do topo", 0, 5).map(func(o): o["pactos"] = 0; o["exilar"] = int(o["id"].substr(1)); return o)},
		"ultima-oferta": {"uso": "passiva", "pacto": "abismo", "nota": "automática: ao estourar uma defesa, troca a carta final (2 de fadiga e a Reação)"},
		# Última Porta
		"vigilia-da-porta": {"uso": "ativada", "alvo": "nenhum", "magia": true, "pacto": "ultima-porta", "custo": {"fadiga": 1, "acao": "padrao"}},
		"punho-da-sentinela": {"uso": "ativada", "alvo": "inimigo_magico", "alcance": 4, "ataque_magico": true, "magia": true, "pacto": "ultima-porta",
			"custo": {"fadiga": 2, "acao": "padrao"}, "exige_atacou_protegido": true},
		# Olho Descoberto
		"olhar-que-despe": {"uso": "ativada", "alvo": "inimigo_magico", "alcance": 4, "magia": true, "pacto": "olho-descoberto", "custo": {"fadiga": 1, "acao": "movimento"}},
		"veredito-antecipado": {"uso": "ativada", "alvo": "inimigo_magico", "alcance": 4, "ataque_magico": true, "magia": true, "pacto": "olho-descoberto",
			"custo": {"fadiga": 1, "acao": "padrao"}, "exige_marca": true},
		# Caminhos Roubados
		"mao-alem-do-limiar": {"uso": "ativada", "magia": true, "pacto": "caminhos-roubados",
			"opcoes": _xs(magia_curta, "e", "Mão Além do Limiar: empurrar 2 + %d", 0, 2) + _xs(magia_curta, "p", "Mão Além do Limiar: puxar 2 + %d", 0, 2)},
		"passagem-indevida": {"uso": "ativada", "magia": true, "pacto": "caminhos-roubados", "opcoes": [
			{"id": "aliado", "nome": "Trocar de lugar com um aliado (1 Pacto)", "alvo": "aliado", "alcance": 4, "sem_si": true, "pactos": 1, "custo": {"fadiga": 1, "acao": "movimento"}},
			{"id": "inimigo", "nome": "Trocar de lugar com um inimigo (2 Pactos, Espírito contra Espírito)", "alvo": "inimigo_magico", "alcance": 4, "pactos": 2, "custo": {"fadiga": 1, "acao": "movimento"}}]},
		# Grilhões Vivos
		"grilhao-de-sombra": {"uso": "ativada", "magia": true, "pacto": "grilhoes-vivos", "opcoes": [
			{"id": "x0", "nome": "Grilhão de Sombra", "pactos": 0}.merged(magia_curta),
			{"id": "x1", "nome": "Grilhão de Sombra + Atormentado (1 Pacto)", "pactos": 1}.merged(magia_curta)]},
		"peso-da-sentenca": {"uso": "ativada", "alvo": "inimigo_magico", "alcance": 4, "magia": true, "pacto": "grilhoes-vivos", "pactos": 1,
			"custo": {"fadiga": 2, "acao": "padrao"}, "exige_grilhao": true},
		# Mesa Vazia
		"fermento-da-fome": {"uso": "ativada", "magia": true, "pacto": "mesa-vazia",
			"opcoes": [{"id": "x0", "nome": "Fermento da Fome", "pactos": 0}.merged(magia_curta)] + _xs(magia_curta, "x", "Fermento + %d Pacto(s) (alvo Atormentado)", 1, 3, {"exige_atormentado": true})},
		"devorar-o-esforco": {"uso": "ativada", "alvo": "inimigo_magico", "alcance": 4, "magia": true, "pacto": "mesa-vazia",
			"custo": {"fadiga": 1, "acao": "padrao"}, "exige_fadiga_alvo": true},
		# Trovão Cativo
		"fagulha-cativa": {"uso": "ativada", "magia": true, "pacto": "trovao-cativo",
			"opcoes": _xs({"alvo": "inimigo_magico", "alcance": 8, "ataque_magico": true, "magia": true, "custo": {"fadiga": 1, "acao": "padrao"}}, "x", "Fagulha Cativa + descarga de %d Pacto(s)", 0, 2)},
		"descarregar-a-tormenta": {"uso": "reacao", "pacto": "trovao-cativo", "nota": "oferecida depois que um inimigo a até 4 casas ataca você"},
		# Sonhos Roubados
		"semeadura-do-pesadelo": {"uso": "ativada", "magia": true, "pacto": "sonhos-roubados", "alvo": "inimigo_magico", "alcance": 4, "ataque_magico": true,
			"custo": {"fadiga": 1, "acao": "padrao"}},
		"colher-o-sonho": {"uso": "ativada", "magia": true, "pacto": "sonhos-roubados",
			"opcoes": _xs({"alvo": "inimigo_magico", "alcance": 4, "custo": {"fadiga": 2, "acao": "padrao"}, "exige_atormentado_meu": true}, "x", "Colher o Sonho (olhar 3 + %d)", 0, 2)},
		# Inverno Imóvel
		"sopro-da-geada": {"uso": "ativada", "magia": true, "pacto": "inverno-imovel", "alvo": "inimigo_magico", "alcance": 4, "ataque_magico": true,
			"custo": {"fadiga": 1, "acao": "padrao"}},
		"coracao-do-inverno": {"uso": "ativada", "magia": true, "pacto": "inverno-imovel",
			"opcoes": _xs({"alvo": "inimigo_magico", "alcance": 4, "ataque_magico": true, "custo": {"fadiga": 2, "acao": "padrao"}}, "t", "Coração do Inverno: transferir %d de fadiga", 0, 2).map(func(o): o["pactos"] = 0; o["transferir"] = int(o["id"].substr(1)); return o)},
		# --- Gerais ---
		"pacto-menor": {"uso": "ativada", "alvo": "nenhum", "custo": {"fadiga": 0, "acao": "movimento"}, "pactos_menor": 1,
			"nota": "o benefício menor de cada patrono é automático; só o dos Caminhos Roubados (andar 1) é uma ação"},
		"procuracao": {"uso": "ativada", "alvo": "nenhum", "custo": {"fadiga": 0, "acao": "movimento"}, "pactos_menor": 2},
		"manter-o-canal": {"uso": "fora", "nota": "inimigos ainda não viram cartas de herói"},
		"desatar-o-no": {"uso": "ativada", "alvo": "nenhum", "pactos": 1, "custo": {"fadiga": 1, "acao": "movimento"}},
		"patrono-presente": {"uso": "fora", "nota": "inimigos ainda não anulam magias"},
		"canal-sem-ruido": {"uso": "ativada", "alvo": "nenhum", "pactos": 1, "custo": {"fadiga": 1, "acao": null}},
		"oferenda-selada": {"uso": "ativada", "alvo": "nenhum", "custo": {"fadiga": 0, "acao": "movimento"}},
		"resgatar-o-penhor": {"uso": "ativada", "alvo": "nenhum", "pactos": 2, "custo": {"fadiga": 0, "acao": "padrao"}},
		"testemunho-do-feito": {"uso": "passiva", "nota": "automático: descarta a menor carta da mão por +1 Pacto (uma vez por turno)"},
		"o-patrono-lembra": {"uso": "passiva", "nota": "automático: depois de estourar um ataque do pacto, 1 carta do teste volta à mão (1 fadiga e 1 Pacto)"},
		"emprestar-a-vontade": {"uso": "fora", "nota": "teste de perícia ligado à cobrança: com o mestre"},
		"ouvir-a-reprimenda": {"uso": "fora", "nota": "teste de perícia ligado à cobrança: com o mestre"},
		"concentrar-a-manifestacao": {"uso": "ativada", "alvo": "nenhum", "pactos": 1, "custo": {"fadiga": 1, "acao": null}},
		"estender-o-sinal": {"uso": "ativada", "alvo": "nenhum", "pactos": 1, "custo": {"fadiga": 2, "acao": null}},
		"pressagio-do-patrono": {"uso": "ativada", "alvo": "nenhum", "custo": {"fadiga": 1, "acao": "movimento"}},
		"ler-o-destino": {"uso": "na_mesa", "nota": "durante o seu ataque do pacto: troca a carta Aberta"},
		"nominar-o-devedor": {"uso": "ativada", "alvo": "inimigo_magico", "alcance": 4, "custo": {"fadiga": 1, "acao": "movimento"}},
		"executar-a-clausula": {"uso": "na_mesa", "nota": "durante o seu ataque do pacto contra um Marcado: troca uma carta do defensor"},
		"ouvir-o-chamado": {"uso": "ativada", "alvo": "nenhum", "custo": {"fadiga": 1, "acao": null}},
		"selo-de-continuidade": {"uso": "ativada", "alvo": "nenhum", "pactos": 1, "custo": {"fadiga": 0, "acao": null}},
		"segredo-entre-as-cartas": {"uso": "passiva", "nota": "no jogo as duas cartas iniciais já ficam à sua vista"},
		"favor-de-ultima-hora": {"uso": "ativada", "alvo": "nenhum", "custo": {"fadiga": 0, "acao": null}},
		"passo-do-emissario": {"uso": "ativada", "alvo": "nenhum", "pactos": 1, "custo": {"fadiga": 0, "acao": null}},
		"o-patrono-nao-desperdica": {"uso": "passiva", "nota": "automático ao errar um ataque do pacto (1 Pacto)"},
		"manifestacao-dupla": {"uso": "ativada", "alvo": "nenhum", "pactos": 3, "custo": {"fadiga": 2, "acao": "padrao"}},
		"descanso-da-voz": {"uso": "ao_virar"},
		"assinatura-vital": {"uso": "passiva", "nota": "um custo de Pacto de 2 ou mais pode trocar 1 ficha por 1 carta do topo (uma vez por turno)"},
		"quitar-a-divida": {"uso": "ativada", "alvo": "nenhum", "pactos": 3, "custo": {"fadiga": 0, "acao": "padrao"}},
		"intercessao-do-patrono": {"uso": "ativada", "alvo": "nenhum", "pactos": 2, "custo": {"fadiga": 0, "acao": null}},
		"retirar-o-nome": {"uso": "passiva", "nota": "automática: num golpe de 3 ou mais, converte o dano em fadiga nas cartas livres (2 Pactos, Reação; exila a carta)"},
	}
	return r


## Ativadas das metades de herói dos patronos.
const ATIVADAS_HEROI := {
	"a-fenix": {"uso": "ativada", "opcoes": [
		{"id": "x1", "nome": "Curar 3 (1 Pacto)", "pactos": 1, "alvo": "aliado", "alcance": 4, "custo": {"fadiga": 0, "acao": null}},
		{"id": "x2", "nome": "Curar 6 (2 Pactos)", "pactos": 2, "alvo": "aliado", "alcance": 4, "custo": {"fadiga": 0, "acao": null}},
		{"id": "x3", "nome": "Curar 9 (3 Pactos)", "pactos": 3, "alvo": "aliado", "alcance": 4, "custo": {"fadiga": 0, "acao": null}}]},
	"a-rainha-da-ultima-geada": {"uso": "ativada", "alvo": "nenhum", "pactos": 1, "custo": {"fadiga": 0, "acao": null}},
}

## O que cada metade de herói faz no jogo (nota da criação).
const NOTAS_HEROI := {
	"a-fenix": "ativada: cura 3 por Pacto; desencadeada: cada ficha de Fogo causa 2 (em todos); crítico: Pactos = nível",
	"malgor-o-credor-do-ultimo-folego": "ativada automática ao estourar (carta final melhor entre 3); desencadeada: −1 de fadiga no Sangrar o Véu com exílio",
	"a-sentinela-que-nunca-recuou": "ativada automática: reduz 3 por Pacto o dano no protegido; o passo junto ao protegido ainda não",
	"a-testemunha-sem-rosto": "ativada automática: revela a carta fechada do inimigo que ataca você; desencadeada: Foco ao vencer com a carta revelada",
	"a-serpente-entre-as-portas": "desencadeada: anda 1 depois de deslocar um inimigo; a ativada (aliado anda 1 ao ser alvo) ainda não",
	"o-carcereiro-sem-chave": "ativada e desencadeada automáticas quando o inimigo gasta ação para tirar seu Imobilizar",
	"vorga-a-boca-sob-o-lago": "a ativada é a opção \"+X Pactos\" do Fermento da Fome; desencadeada automática",
	"a-serpente-de-cobre-que-circunda-a-tormenta": "a ativada é a opção \"descarga\" da Fagulha Cativa; desencadeada automática",
	"nimeria-a-dama-dos-sonhos-inacabados": "ativada automática: confunde o inimigo atormentado que vai atacar",
	"a-rainha-da-ultima-geada": "ativada: passa 1 de fadiga para a carta de herói; desencadeada: Bloqueio quando a habilidade inicial enche",
}


## Cartas de pacto (reserva) e seus botões: reparar o pacto, trocar o protegido.
const LADO_PACTO := {"uso": "ativada", "opcoes": [
	{"id": "reparar", "nome": "Reparar o pacto", "alvo": "nenhum", "custo": {"fadiga": 0, "acao": null}},
	{"id": "protegido", "nome": "Trocar o protegido (descarta a reserva)", "alvo": "aliado", "alcance": 12, "sem_si": true, "custo": {"fadiga": 0, "acao": "padrao"}}]}


static func registro(c) -> Dictionary:
	var s: String = c.slug()
	if c.tipo == "pacto":
		return LADO_PACTO
	if c.tipo == "heroi":
		return ATIVADAS_HEROI.get(s, {})
	return LADOS.get(s, {})


static func eh_do_bruxo(s: String) -> bool:
	return LADOS.has(s) or ATIVADAS_HEROI.has(s)


# --- Reserva e nível --------------------------------------------------------------------------

static func carta_pacto(u):
	for c in u.cartas:
		if c.tipo == "pacto":
			return c
	return null


static func carta_menor(u):
	for c in u.cartas:
		if c.slug() in ["pacto-menor", "procuracao"]:
			return c
	return null


static func carta_inicial(u):
	for c in u.cartas:
		if str(c.id).begins_with("pacto.") and str(c.id).ends_with(".inicial"):
			return c
	return null


static func pactos(u, menor := false) -> int:
	var c = carta_menor(u) if menor else carta_pacto(u)
	return int(c.fichas.get(FICHA, 0)) if c != null else 0


static func suspenso(u, menor := false) -> bool:
	return u.efeitos.has("suspenso_menor" if menor else "suspenso")


static func pode_gastar(u, n: int, menor := false) -> bool:
	if n <= 0:
		return true
	if suspenso(u, menor):
		return false
	var tem := pactos(u, menor)
	# Assinatura Vital: um custo de 2 ou mais pode trocar 1 ficha por 1 carta do topo.
	if not menor and n >= 2 and u.ativo("assinatura-vital") and not u.efeitos.has("assinatura_usada") and u.baralho.baralho.size() > 1:
		return tem >= n - 1
	return tem >= n


static func gastar(b, u, n: int, menor := false) -> bool:
	if n <= 0:
		return true
	if not pode_gastar(u, n, menor):
		return false
	var c = carta_menor(u) if menor else carta_pacto(u)
	var tem: int = int(c.fichas.get(FICHA, 0))
	if not menor and tem < n:
		u.efeitos["assinatura_usada"] = {"ate": "inicio_turno"}
		u.baralho.exilio.append(u.baralho.puxar_topo())
		b._log("Assinatura Vital: %s exila 1 carta do topo no lugar de uma ficha de Pacto." % u.nome)
		n -= 1
	c.tirar_ficha(FICHA, n)
	if not menor:
		u.efeitos["gastou_pacto"] = {"ate": "inicio_turno"}
	return true


static func ganhar(b, u, n: int, motivo: String, cumprimento := false, menor := false) -> void:
	if n <= 0 or suspenso(u, menor):
		return
	var c = carta_menor(u) if menor else carta_pacto(u)
	if c == null:
		return
	c.dar_ficha(FICHA, n)
	b._log("%s: %s ganha %d ficha(s) de Pacto." % [motivo, u.nome, n])
	if cumprimento and u.ativo("testemunho-do-feito") and not u.efeitos.has("testemunho_usado") and not u.baralho.mao.is_empty():
		u.efeitos["testemunho_usado"] = {"ate": "inicio_turno"}
		var menor_c: int = b._menor_da_mao(u)
		u.baralho.mao.erase(menor_c)
		u.baralho.descarte.append(menor_c)
		c.dar_ficha(FICHA, 1)
		b._log("Testemunho do Feito: %s descarta %s e ganha mais 1 Pacto." % [u.nome, Carta.nome(menor_c)])


static func bruxos(b, pacto := "") -> Array:
	return b.herois_ativos().filter(func(h): return h.pacto != "" and (pacto == "" or h.pacto == pacto))


static func uma_vez(u, chave: String, por := "rodada") -> bool:
	## true na primeira vez (e marca); por "rodada" (até o próximo turno do Bruxo) ou "turno".
	if u.efeitos.has(chave):
		return false
	u.efeitos[chave] = {"ate": "inicio_turno"}
	return true


# --- Cena ---------------------------------------------------------------------------------

static func inicio_da_cena(b, u) -> void:
	if u.pacto == "":
		return
	var cp = carta_pacto(u)
	if cp != null:
		cp.fichas.erase(FICHA)
		cp.dar_ficha(FICHA, 2 * u.nivel_pacto)
		b._log("%s: %s começa a cena com %d fichas de Pacto." % [cp.nome(), u.nome, 2 * u.nivel_pacto])
	var cm = carta_menor(u)
	if cm != null and u.pacto_menor != "":
		cm.fichas.erase(FICHA)
		cm.dar_ficha(FICHA, u.nivel_pacto)
	match u.pacto:
		"sonhos-roubados":
			# Cobrança: exila 1 carta da mão inicial (a menor) como o sonho entregue.
			if not u.baralho.mao.is_empty():
				var c: int = b._menor_da_mao(u)
				u.baralho.mao.erase(c)
				u.baralho.exilio.append(c)
				b._log("Sonhos Roubados: %s entrega %s à patrona (exílio)." % [u.nome, Carta.nome(c)])
		"ultima-porta":
			if u.protegido == "" or b.unidade(u.protegido) == null:
				var outros: Array = b.herois().filter(func(h): return h != u)
				if not outros.is_empty():
					u.protegido = outros[0].id
			if u.protegido != "":
				b._log("Última Porta: %s jura proteger %s." % [u.nome, b.unidade(u.protegido).nome])
	if u.pacto_menor == "sonhos-roubados" and not u.baralho.mao.is_empty():
		var c2: int = b._menor_da_mao(u)
		u.baralho.mao.erase(c2)
		u.baralho.exilio.append(c2)
		b._log("Sonhos Roubados (pacto menor): %s entrega %s à patrona." % [u.nome, Carta.nome(c2)])


# --- Uso das cartas ---------------------------------------------------------------------------

static func motivo(b, u, c) -> String:
	var info: Dictionary = b._info_lado(c)
	var s: String = c.slug()
	if c.tipo == "pacto":
		match info.get("opcao", ""):
			"reparar":
				return motivo_reparar(b, u)
			"protegido":
				if u.pacto != "ultima-porta":
					return "só no Pacto da Última Porta"
		return ""
	if info.has("pacto") and u.pacto != info["pacto"]:
		return "precisa do %s" % Catalogo.pactos().get(info["pacto"], {}).get("nome", "pacto")
	if int(info.get("pactos", 0)) > 0:
		if suspenso(u):
			return "pacto suspenso (repare na carta de pacto)"
		if not pode_gastar(u, int(info["pactos"])):
			return "precisa de %d ficha(s) de Pacto" % int(info["pactos"])
	if int(info.get("pactos_menor", 0)) > 0:
		if u.pacto_menor == "":
			return "escolha o patrono do Pacto Menor na criação"
		if suspenso(u, true):
			return "reserva menor suspensa"
		if pactos(u, true) < int(info["pactos_menor"]):
			return "precisa de %d Pacto(s) da reserva menor" % int(info["pactos_menor"])
	if int(info.get("exilar", 0)) > u.espirito:
		return "exila no máximo o seu Espírito (%d)" % u.espirito
	if int(info.get("exilar", 0)) >= u.baralho.baralho.size():
		return "baralho curto demais"
	if info.get("ataque_magico", false) and int(u.foco.get("maos", 0)) == 0:
		return "precisa de um foco"
	match s:
		"pacto-menor":
			if u.pacto_menor != "caminhos-roubados":
				return "o benefício do seu pacto menor é automático"
		"procuracao":
			if u.efeitos.has("procuracao_usada"):
				return "uma vez por turno"
			var ini = carta_inicial(u)
			if ini == null or ini.fadiga <= 0:
				return "a habilidade inicial está sem fadiga"
		"desatar-o-no":
			if carta_inicial(u) == null:
				return "sem habilidade inicial"
		"canal-sem-ruido":
			var ini2 = carta_inicial(u)
			if ini2 == null or not (ini2.tem_ficha("Penalidade") or ini2.tem_ficha("Atormentado")):
				return "a habilidade inicial não tem Penalidade nem Atormentado"
			if u.efeitos.has("canal_usado"):
				return "uma vez por turno"
		"oferenda-selada":
			if u.efeitos.has("oferenda_usada"):
				return "uma vez por cena"
			if u.baralho.descarte.size() < 2:
				return "precisa de 2 cartas no descarte"
			if suspenso(u):
				return "pacto suspenso"
		"resgatar-o-penhor":
			if u.baralho.exilio.is_empty():
				return "exílio vazio"
		"concentrar-a-manifestacao":
			if u.efeitos.has("concentrar"):
				return "já preparada"
		"estender-o-sinal":
			if u.efeitos.has("estender"):
				return "já preparada"
		"selo-de-continuidade":
			var ini3 = carta_inicial(u)
			if ini3 == null or ini3.fadiga <= 0:
				return "a habilidade inicial está sem fadiga"
			if u.efeitos.has("selo_usado"):
				return "uma vez por turno"
		"favor-de-ultima-hora":
			if u.efeitos.has("favor_usado"):
				return "uma vez por cena"
			if suspenso(u):
				return "pacto suspenso"
		"passo-do-emissario":
			if u.efeitos.has("passo_emissario"):
				return "uma vez por turno"
		"manifestacao-dupla":
			if u.efeitos.has("manifestacao"):
				return "já ativa"
		"intercessao-do-patrono":
			if not u.efeitos.has("intercessao_ok"):
				return "só logo depois de errar um ataque da habilidade inicial"
		"a-rainha-da-ultima-geada":
			if u.efeitos.has("geada_heroi"):
				return "uma vez por turno"
			if c.espaco() <= 0 or not u.cartas.any(func(x): return x != c and x.fadiga > 0):
				return "sem fadiga para passar (ou carta de herói cheia)"
		"vigilia-da-porta":
			pass
		"devorar-o-esforco", "peso-da-sentenca":
			pass
	return ""


static func motivo_reparar(b, u) -> String:
	if not suspenso(u):
		return "o pacto não está suspenso"
	match u.pacto:
		"abismo":
			return "" if u.baralho.baralho.size() > 2 else "baralho curto demais"
		"ultima-porta":
			var p = b.unidade(u.protegido)
			if p == null or not Grade.adjacentes(p.pos, u.pos):
				return "fique ao lado do protegido"
			return "" if u.acoes_padrao > 0 else "sem ação Padrão"
		"mesa-vazia":
			if u.acoes_padrao <= 0:
				return "sem ação Padrão"
			return "" if u.baralho.mao.size() >= 2 else "precisa de 2 cartas na mão"
		"trovao-cativo":
			var h = u.carta_heroi()
			var ini = carta_inicial(u)
			if (h == null or h.espaco() <= 0) and (ini == null or ini.espaco() <= 0):
				return "sem espaço de fadiga"
			return "" if (u.acoes_mov > 0 or u.acoes_padrao > 0) else "sem ação de movimento"
		"sonhos-roubados":
			if u.acoes_padrao <= 0:
				return "sem ação Padrão"
			return "" if not u.baralho.mao.is_empty() else "sem carta na mão"
		"caminhos-roubados", "inverno-imovel":
			return "repara sozinho no fim de um turno que cumpra a reparação"
	return "a reparação deste pacto é com o mestre"


## Paga os Pactos do lado (já conferidos em motivo) e faz o efeito.
static func usar(b, u, c, alvo) -> void:
	var info: Dictionary = b._info_lado(c)
	var s: String = c.slug()
	gastar(b, u, int(info.get("pactos", 0)))
	gastar(b, u, int(info.get("pactos_menor", 0)), true)
	var esp: int = u.espirito
	var ctx_m := {"habilidade": c.nome(), "magico": true, "magia_do_pacto": true}
	if c.tipo == "pacto":
		match info.get("opcao", ""):
			"reparar":
				_reparar(b, u)
			"protegido":
				u.protegido = alvo.id
				var cp = carta_pacto(u)
				cp.fichas.erase(FICHA)
				b._log("Última Porta: %s jura proteger %s (a reserva se perde)." % [u.nome, alvo.nome])
		return
	if u.efeitos.has("concentrar") and info.get("ataque_magico", false):
		u.efeitos.erase("concentrar")
		ctx_m["concentrar"] = true
	if u.efeitos.has("estender") and info.get("ataque_magico", false):
		u.efeitos.erase("estender")
		ctx_m["estender"] = true
	match s:
		"a-fenix":
			b._curar(alvo, 3 * int(info["pactos"]), "é curado pelas chamas da Fênix")
		"ave-fenix":
			var x := int(info["pactos"])
			b._novo_ataque(u, alvo, ctx_m.merged({"tipo_dano": "Fogo", "ave_fenix": x, "bonus_dano": 2 * x,
				"rotulo_bonus": "Ave Fênix (%d Pacto)" % x, "ao_acertar": [{"ficha": "Fogo"}]}))
		"absorver-as-chamas":
			var f := 0
			for o in b.unidades:
				if o.viva() and Grade.distancia(o.pos, u.pos) <= 4:
					f += o.tirar_fichas("Fogo")
			var cura := f + 2 * int(info["pactos"])
			if cura > 0:
				b._curar(u, cura, "absorve as chamas")
			b._log("Absorver as Chamas: %d ficha(s) de Fogo apagadas." % f)
		"sangrar-o-veu":
			var k := int(info.get("exilar", 0))
			for i in k:
				u.baralho.exilio.append(u.baralho.puxar_topo())
			if k > 0:
				b._log("Sangrar o Véu: %s exila %d carta(s) do topo." % [u.nome, k])
				if uma_vez(u, "abismo_cumprimento"):
					ganhar(b, u, 1, "Pacto do Abismo (exílio voluntário)", true)
				if u.ativo("malgor-o-credor-do-ultimo-folego") and uma_vez(u, "abismo_desencadeada") and c.fadiga > 0:
					c.fadiga -= 1
					b._log("Malgor: −1 de fadiga no Sangrar o Véu.")
			b._novo_ataque(u, alvo, ctx_m.merged({"tipo_dano": "Necrótico", "bonus_dano": 2 * k, "rotulo_bonus": "Sangrar o Véu (%d exiladas)" % k}))
		"vigilia-da-porta":
			var h = u.carta_heroi()
			if h != null and not u.cartas.any(func(x): return x.tem_ficha("Guarda")):
				h.dar_ficha("Guarda")
				b._log("Vigília da Porta: %s ganha 1 Guarda." % u.nome)
			var p = b.unidade(u.protegido)
			if p != null and p.viva() and Grade.distancia(p.pos, u.pos) <= 4 and not p.cartas.any(func(x): return x.tem_ficha("Bloqueio")):
				p.cartas[0].dar_ficha("Bloqueio")
				b._log("Vigília da Porta: %s ganha 1 Bloqueio." % p.nome)
		"punho-da-sentinela":
			b._novo_ataque(u, alvo, ctx_m.merged({"tipo_dano": "Radiante", "bonus_dano": esp, "rotulo_bonus": "Punho da Sentinela (Espírito de novo)"}))
		"olhar-que-despe":
			if _vence(b, u, esp, alvo, "mentira"):
				alvo.dar_ficha("Marcado")
				b._log("Olhar que Despe: %s fica marcado." % alvo.nome)
			else:
				b._log("Olhar que Despe: %s resiste." % alvo.nome)
		"veredito-antecipado":
			b._novo_ataque(u, alvo, ctx_m.merged({"tipo_dano": "Radiante", "defesa_primeiro": true}))
		"mao-alem-do-limiar":
			var op: String = info["opcao"]
			b._novo_ataque(u, alvo, ctx_m.merged({"tipo_dano": "Concussão", "deslocar": 2 + int(info["pactos"]), "puxar": op.begins_with("p")}))
		"passagem-indevida":
			if info["opcao"] == "inimigo" and not _vence(b, u, esp, alvo, "espirito"):
				b._log("Passagem Indevida: %s resiste à troca." % alvo.nome)
				return
			var a: Vector2i = u.pos
			u.pos = alvo.pos
			alvo.pos = a
			b.eventos.append({"tipo": "teleporte", "id": u.id, "de": a, "para": u.pos})
			b.eventos.append({"tipo": "teleporte", "id": alvo.id, "de": u.pos, "para": a})
			b._log("Passagem Indevida: %s e %s trocam de lugar." % [u.nome, alvo.nome])
		"grilhao-de-sombra":
			b._novo_ataque(u, alvo, ctx_m.merged({"tipo_dano": "Necrótico", "grilhao": true, "atormentar": int(info["pactos"]) > 0}))
		"peso-da-sentenca":
			if _vence(b, u, esp, alvo, "espirito"):
				alvo.tirar_fichas("Imobilizar", 1)
				alvo.dar_ficha("Atordoamento")
				b._log("Peso da Sentença: o grilhão de %s vira Atordoamento." % alvo.nome)
			else:
				b._log("Peso da Sentença: %s resiste." % alvo.nome)
		"fermento-da-fome":
			var x2 := int(info["pactos"])
			b._novo_ataque(u, alvo, ctx_m.merged({"tipo_dano": "Dreno", "atormentar": true, "bonus_dano": 2 * x2,
				"rotulo_bonus": "Vorga (%d Pacto)" % x2, "cura_vorga": x2}))
		"devorar-o-esforco":
			if _vence(b, u, esp, alvo, "espirito"):
				var n: int = alvo.tirar_fichas("Fadiga", esp)
				if n > 0:
					b._dano_direto(alvo, 2 * n, "Devorar o Esforço (Dreno)")
				_fadiga_removida(b, u, n)
			else:
				b._log("Devorar o Esforço: %s resiste." % alvo.nome)
		"fagulha-cativa":
			b._novo_ataque(u, alvo, ctx_m.merged({"tipo_dano": "Raio", "descarga": int(info["pactos"])}))
		"semeadura-do-pesadelo":
			b._novo_ataque(u, alvo, ctx_m.merged({"tipo_dano": "Psíquico", "pesadelo": true}))
		"colher-o-sonho":
			alvo.tirar_fichas("Atormentado", 1)
			var olhar := 3 + int(info["pactos"])
			var vistas := []
			for i in olhar:
				var cc: int = u.baralho.puxar_topo()
				if cc < 0:
					break
				vistas.append(cc)
			vistas.sort_custom(func(x, y): return (11 if Carta.eh_as(x) else Carta.valor(x)) > (11 if Carta.eh_as(y) else Carta.valor(y)))
			for i in vistas.size():
				if i < 2:
					u.baralho.mao.append(vistas[i])
				else:
					u.baralho.baralho.insert(0, vistas[i])
			b._log("Colher o Sonho: %s olha %d cartas e guarda 2 na mão." % [u.nome, vistas.size()])
		"sopro-da-geada":
			b._novo_ataque(u, alvo, ctx_m.merged({"tipo_dano": "Gelo", "geada": true}))
		"coracao-do-inverno":
			var t := 0
			for outra in u.cartas:
				while t < int(info.get("transferir", 0)) and outra != c and outra.fadiga > 0 and c.espaco() > 0:
					outra.fadiga -= 1
					c.fadiga += 1
					t += 1
			if t > 0:
				b._log("Coração do Inverno: %d de fadiga passa para a carta." % t)
			b._novo_ataque(u, alvo, ctx_m.merged({"tipo_dano": "Gelo", "bonus_dano": 2 * t, "rotulo_bonus": "Coração do Inverno (%d transferidas)" % t}))
		"a-rainha-da-ultima-geada":
			u.efeitos["geada_heroi"] = {"ate": "inicio_turno"}
			for outra in u.cartas:
				if outra != c and outra.fadiga > 0:
					outra.fadiga -= 1
					c.fadiga += 1
					b._log("A Rainha da Última Geada: 1 de fadiga passa de %s para a carta de herói." % outra.nome())
					break
		"pacto-menor":
			u.deslocamento += 1
			u.ignora_impedimento = true
			u.efeitos["desengajar"] = {"ate": "inicio_turno"}
			b._log("Caminhos Roubados (menor): %s pode andar 1 quadrado sem impedimento." % u.nome)
		"procuracao":
			u.efeitos["procuracao_usada"] = {"ate": "inicio_turno"}
			carta_inicial(u).fadiga -= 1
			b._log("Procuração: −1 de fadiga na habilidade inicial.")
		"desatar-o-no":
			b._virar(u, carta_inicial(u))
			u.deslocamento += 1
			u.ignora_impedimento = true
			u.efeitos["desengajar"] = {"ate": "inicio_turno"}
			b._log("Desatar o Nó: a habilidade inicial vira e %s pode andar 1." % u.nome)
		"canal-sem-ruido":
			u.efeitos["canal_usado"] = {"ate": "inicio_turno"}
			var ini = carta_inicial(u)
			if not ini.tirar_ficha("Penalidade"):
				ini.tirar_ficha("Atormentado")
			b._log("Canal sem Ruído: a habilidade inicial fica limpa.")
		"oferenda-selada":
			u.efeitos["oferenda_usada"] = {}
			for i in 2:
				u.baralho.exilio.append(u.baralho.descarte.pop_back())
			ganhar(b, u, 2, "Oferenda Selada")
		"resgatar-o-penhor":
			u.baralho.descarte.append(u.baralho.exilio.pop_back())
			b._log("Resgatar o Penhor: 1 carta volta do exílio para o descarte.")
		"concentrar-a-manifestacao":
			u.efeitos["concentrar"] = {"ate": "inicio_turno"}
			b._log("Concentrar a Manifestação: a próxima magia do pacto atinge só o alvo e soma o Espírito de novo.")
		"estender-o-sinal":
			u.efeitos["estender"] = {"ate": "inicio_turno"}
			b._log("Estender o Sinal: as fichas da próxima magia do pacto podem pular para um inimigo ao lado do alvo.")
		"pressagio-do-patrono":
			u.efeitos["scry_restante"] = {"n": 2}
			b.comecar_scry(u)
		"nominar-o-devedor":
			if _vence(b, u, esp, alvo, "espirito"):
				alvo.dar_ficha("Marcado")
				b._log("Nominar o Devedor: %s fica marcado." % alvo.nome)
			else:
				b._log("Nominar o Devedor: %s resiste." % alvo.nome)
		"ouvir-o-chamado":
			b.comecar_scry(u)
		"selo-de-continuidade":
			u.efeitos["selo_usado"] = {"ate": "inicio_turno"}
			carta_inicial(u).fadiga -= 1
			b._log("Selo de Continuidade: −1 de fadiga na habilidade inicial.")
		"favor-de-ultima-hora":
			u.efeitos["favor_usado"] = {}
			u.baralho.exilio.append(u.baralho.puxar_topo())
			ganhar(b, u, 1, "Favor de Última Hora")
		"passo-do-emissario":
			u.efeitos["passo_emissario"] = {"ate": "inicio_turno"}
			u.deslocamento += 1
			u.ignora_impedimento = true
			u.efeitos["desengajar"] = {"ate": "inicio_turno"}
		"manifestacao-dupla":
			u.efeitos["manifestacao"] = {"usos": 2, "ate_turno_de": u.id}
			b._log("Manifestação Dupla: as próximas 2 magias da habilidade inicial não gastam ação.")
		"quitar-a-divida":
			var ini4 = carta_inicial(u)
			var tirou := mini(3, ini4.fadiga)
			ini4.fadiga -= tirou
			b._log("Quitar a Dívida: −%d de fadiga na habilidade inicial." % tirou)
			b._virar(u, c)
		"intercessao-do-patrono":
			u.efeitos.erase("intercessao_ok")
			u.acoes_padrao += 1
			u.efeitos["sem_acao_inicial"] = {"ate": "inicio_turno"}
			u.cartas.erase(c)
			b._log("Intercessão do Patrono: %s conjura de novo (a carta sai do jogo nesta cena)." % u.nome)


static func _reparar(b, u) -> void:
	match u.pacto:
		"abismo":
			for i in 2:
				u.baralho.exilio.append(u.baralho.puxar_topo())
		"ultima-porta", "sonhos-roubados":
			u.acoes_padrao -= 1
			if u.pacto == "sonhos-roubados":
				var c: int = b._menor_da_mao(u)
				u.baralho.mao.erase(c)
				u.baralho.exilio.append(c)
		"mesa-vazia":
			u.acoes_padrao -= 1
			for i in 2:
				var c2: int = b._menor_da_mao(u)
				u.baralho.mao.erase(c2)
				u.baralho.descarte.append(c2)
		"trovao-cativo":
			if u.acoes_mov > 0:
				u.acoes_mov -= 1
			else:
				u.acoes_padrao -= 1
			var h = u.carta_heroi()
			if h != null and h.espaco() > 0:
				h.fadiga += 1
			else:
				carta_inicial(u).fadiga += 1
	u.efeitos.erase("suspenso")
	b._log("%s repara o pacto." % u.nome)


static func suspender(b, u, motivo_txt: String, menor := false) -> void:
	if suspenso(u, menor):
		return
	u.efeitos["suspenso_menor" if menor else "suspenso"] = {}
	b._log("%s: %s quebra a cobrança e o %s fica suspenso. %s" % [motivo_txt, u.nome, "pacto menor" if menor else "pacto",
		"" if menor else "(Reparar: botão na carta de pacto.)"])


## Teste contestado: Espírito do Bruxo (cartas, automático) contra o atributo do alvo.
static func _vence(b, u, valor: int, alvo, atributo: String) -> bool:
	var meu: int = b._teste_automatico(u, valor)
	var dele: int = b.valor_resistido(alvo, atributo)
	b.eventos.append({"tipo": "flutuar", "id": alvo.id, "texto": "%d × %d" % [meu, dele], "cor": "c9c4b8" if meu > dele else "ff9d5c"})
	return meu > dele


static func _fadiga_removida(b, u, n: int) -> void:
	if n <= 0:
		return
	if u.ativo("vorga-a-boca-sob-o-lago") and uma_vez(u, "vorga_desencadeada"):
		if b._tirar_fadiga(u, 1) > 0:
			b._log("Vorga: %s retira 1 de fadiga de uma carta." % u.nome)
	if n >= 2 and uma_vez(u, "mesa_cumprimento"):
		ganhar(b, u, 1, "Pacto da Mesa Vazia (banquete)", true)


# --- Ganchos da batalha -----------------------------------------------------------------------

## Antes de pagar uma carta: guarda a fadiga (Trovão Cativo mede quem chega ao limite).
static func antes_de_pagar(u) -> Array:
	return u.cartas.map(func(x): return x.fadiga)


static func depois_de_pagar(b, u, c, antes: Array) -> void:
	if u.pacto == "":
		return
	var info: Dictionary = b._info_lado(c)
	if info.get("pacto", "") == u.pacto:
		u.efeitos["conjurou_pacto"] = {"ate": "inicio_turno"}
	if u.pacto == "trovao-cativo" and info.get("pacto", "") == "trovao-cativo":
		for i in mini(antes.size(), u.cartas.size()):
			var x = u.cartas[i]
			if x.limite() > 0 and int(antes[i]) < x.limite() and x.fadiga == x.limite():
				if uma_vez(u, "trovao_cumprimento"):
					ganhar(b, u, 1, "Pacto do Trovão Cativo (carta carregada)", true)
				if u.ativo("a-serpente-de-cobre-que-circunda-a-tormenta") and u.acoes_reacao <= 0 and uma_vez(u, "trovao_reacao"):
					u.acoes_reacao += 1
					b._log("A Serpente de Cobre: %s ganha 1 Reação." % u.nome)
				break


## Bônus de dano nas magias do pacto (Concentrar a Manifestação, Fênix menor).
static func bonus_de_dano(b, u, alvo, acerto: bool) -> Array:
	var lista := []
	if not acerto or not b.ctx.get("magia_do_pacto", false):
		return lista
	if b.ctx.get("concentrar", false):
		lista.append(["Concentrar a Manifestação (Espírito)", u.espirito])
	if u.pacto_menor == "fenix" and pactos(u, true) > 0 and not suspenso(u, true) and uma_vez(u, "fenix_menor"):
		gastar(b, u, 1, true)
		lista.append(["Fênix (pacto menor)", 1])
	return lista


## Começo do ataque (as duas cartas iniciais já saíram).
static func inicio_do_ataque(b, atk, dfs) -> void:
	if b.ctx.get("defesa_primeiro", false) and not dfs.eh_heroi():
		# Veredito Antecipado: o defensor conclui a defesa antes de o Bruxo decidir.
		while not b.teste_defesa.encerrado and IA.quer_puxar(b.teste_defesa, b.teste_ataque, false, dfs.parada_defesa, dfs.risco, b.baralho_inimigos.baralho):
			if not b.teste_defesa.puxar():
				break
		b.teste_defesa.parar()
		b.teste_defesa.revelado = true
		b._log("Veredito Antecipado: %s fecha a defesa em %d antes de %s decidir." % [dfs.nome, b.teste_defesa.resultado(), atk.nome])
	# Olho Descoberto: a carta fechada do inimigo que ataca o Bruxo fica à vista (1 Pacto, Reação).
	if dfs.eh_heroi() and not atk.eh_heroi() and dfs.pacto == "olho-descoberto" and dfs.ativo("a-testemunha-sem-rosto") \
			and dfs.acoes_reacao > 0 and pode_gastar(dfs, 1) and Grade.distancia(atk.pos, dfs.pos) <= 4:
		gastar(b, dfs, 1)
		dfs.acoes_reacao -= 1
		b.teste_ataque.revelado = true
		b._log("A Testemunha: %s vê a carta fechada de %s." % [dfs.nome, atk.nome])
	# Olho Descoberto (menor): olha a fechada do defensor ao atacar.
	if atk.eh_heroi() and atk.pacto_menor == "olho-descoberto" and not b.teste_defesa.revelado and atk.acoes_reacao > 0 \
			and pactos(atk, true) > 0 and not suspenso(atk, true) and Grade.distancia(atk.pos, dfs.pos) <= 4:
		gastar(b, atk, 1, true)
		atk.acoes_reacao -= 1
		b.teste_defesa.revelado = true
		b._log("Olho Descoberto (menor): %s vê a carta fechada de %s." % [atk.nome, dfs.nome])


## Depois do ataque resolvido (os dois lados).
static func resolvido(b, atk, dfs, acerto: bool) -> void:
	for lado in [atk, dfs]:
		if not lado.eh_heroi() or lado.pacto != "olho-descoberto":
			continue
		var outro = dfs if lado == atk else atk
		var venceu: bool = acerto if lado == atk else not acerto
		var t_outro = b.teste_defesa if lado == atk else b.teste_ataque
		if venceu and t_outro.revelado and lado.ativo("a-testemunha-sem-rosto") and uma_vez(lado, "olho_foco"):
			lado.dar_ficha("Foco")
			b._log("A Testemunha: %s ganha 1 Foco." % lado.nome)
		if t_outro.estourou and outro.fichas_total("Marcado") > 0 and uma_vez(lado, "olho_cumprimento"):
			ganhar(b, lado, 1, "Pacto do Olho Descoberto (o marcado estourou)", true)


## Depois do ataque de um herói (Bruxo ou aliado).
static func depois_do_ataque(b, u, alvo, acerto: bool, dano: int) -> void:
	var ctx: Dictionary = b.ctx
	if dano > 0 and not alvo.eh_heroi():
		alvo.efeitos["ferido_por_" + u.id] = {}
	# Grilhões (menor): aliado acerta inimigo ao lado do Bruxo -> Penalidade.
	if acerto and alvo.viva() and not alvo.eh_heroi():
		for br in bruxos(b):
			if br != u and br.pacto_menor == "grilhoes-vivos" and Grade.adjacentes(br.pos, alvo.pos) and br.acoes_reacao > 0 \
					and pactos(br, true) > 0 and not suspenso(br, true):
				gastar(b, br, 1, true)
				br.acoes_reacao -= 1
				alvo.dar_ficha("Penalidade")
				b._log("Grilhões (menor): %s põe 1 Penalidade em %s." % [br.nome, alvo.nome])
				break
	if not ctx.get("magia_do_pacto", false):
		return
	if not acerto:
		var ini = carta_inicial(u)
		if ini != null and ctx.get("habilidade", "") == ini.nome():
			u.efeitos["intercessao_ok"] = {"ate": "inicio_turno"}
		if u.ativo("o-patrono-nao-desperdica") and pode_gastar(u, 1) and b.teste_ataque != null:
			for c in b.teste_ataque.cartas:
				if c in u.baralho.descarte:
					gastar(b, u, 1)
					u.baralho.descarte.erase(c)
					u.baralho.baralho.insert(0, c)
					b._log("O Patrono Não Desperdiça: %s volta para o fundo do baralho." % Carta.nome(c))
					break
	if b.teste_ataque != null and b.teste_ataque.estourou and u.ativo("o-patrono-lembra") and pode_gastar(u, 1):
		var cl = u.carta_com("o-patrono-lembra")
		if cl != null and cl.pode_pagar(1):
			for c2 in b.teste_ataque.cartas:
				if c2 in u.baralho.descarte:
					cl.pagar(1)
					gastar(b, u, 1)
					u.baralho.descarte.erase(c2)
					u.baralho.mao.append(c2)
					b._log("O Patrono Lembra: %s volta para a mão." % Carta.nome(c2))
					break
	if not acerto or not alvo.viva():
		return
	var fichas_postas := []
	if ctx.has("ave_fenix"):
		var x := int(ctx["ave_fenix"])
		fichas_postas.append("Fogo")
		if not ctx.get("concentrar", false):
			for o in b.oponentes(u):
				if o != alvo and o.viva() and Grade.adjacentes(o.pos, alvo.pos):
					o.dar_ficha("Fogo")
					if x > 0:
						b._dano_direto(o, 1 + 2 * x, "Ave Fênix (chamas ao redor)")
	if ctx.get("grilhao", false) and dano > 0:
		alvo.dar_ficha("Imobilizar")
		alvo.efeitos["grilhao_de"] = {"id": u.id}
		fichas_postas.append("Imobilizar")
		if ctx.get("atormentar", false):
			alvo.dar_ficha("Atormentado")
			alvo.efeitos["atormentado_de"] = {"id": u.id}
			fichas_postas.append("Atormentado")
		b._log("Grilhão de Sombra: %s fica preso." % alvo.nome)
	elif ctx.get("atormentar", false) and not ctx.get("grilhao", false):
		alvo.dar_ficha("Atormentado")
		alvo.efeitos["atormentado_de"] = {"id": u.id}
		fichas_postas.append("Atormentado")
		b._log("%s: %s fica atormentado." % [ctx.get("habilidade", ""), alvo.nome])
	if int(ctx.get("cura_vorga", 0)) > 0 and dano > 0:
		b._curar(u, int(ctx["cura_vorga"]), "se alimenta (Vorga)")
	if ctx.get("pesadelo", false) and dano > 0 and alvo.efeitos.get("atormentado_de", {}).get("id", "") != u.id:
		alvo.dar_ficha("Atormentado")
		alvo.efeitos["atormentado_de"] = {"id": u.id}
		fichas_postas.append("Atormentado")
		b._log("Semeadura do Pesadelo: %s fica atormentado." % alvo.nome)
	if ctx.get("geada", false) and dano > 0:
		alvo.efeitos["geada"] = {"ate_turno_de": u.id}
		b._log("Sopro da Geada: o próximo movimento de %s rende só 1 quadrado." % alvo.nome)
	if int(ctx.get("deslocar", 0)) > 0:
		var antes_adj: Array = b.herois_ativos().filter(func(h): return h != u and Grade.adjacentes(h.pos, alvo.pos))
		if ctx.get("puxar", false):
			for i in int(ctx["deslocar"]):
				var d: Vector2i = u.pos - alvo.pos
				var q: Vector2i = alvo.pos + Vector2i(signi(d.x), signi(d.y))
				if q == u.pos or not b.grade.dentro(q) or b.grade.bloqueado(q) or b.na_posicao(q) != null:
					break
				alvo.pos = q
				b.eventos.append({"tipo": "mover", "id": alvo.id, "caminho": [q]})
		else:
			b._empurrar(alvo, u.pos, int(ctx["deslocar"]), 0)
		var novo_adj: Array = b.herois_ativos().filter(func(h): return h != u and Grade.adjacentes(h.pos, alvo.pos) and not h in antes_adj)
		if not novo_adj.is_empty() and uma_vez(u, "caminhos_cumprimento"):
			ganhar(b, u, 1, "Pacto dos Caminhos Roubados (inimigo levado ao aliado)", true)
		if u.ativo("a-serpente-entre-as-portas") and uma_vez(u, "caminhos_passo"):
			u.deslocamento += 1
			u.ignora_impedimento = true
			u.efeitos["desengajar"] = {"ate": "inicio_turno"}
			b._log("A Serpente Entre as Portas: %s pode andar 1 quadrado." % u.nome)
	if int(ctx.get("descarga", 0)) > 0:
		for o in b.oponentes(u):
			if o != alvo and o.viva() and Grade.adjacentes(o.pos, alvo.pos):
				gastar(b, u, int(ctx["descarga"]))
				b._dano_direto(o, 2 * int(ctx["descarga"]), "Descarga da Serpente de Cobre (Raio)")
				break
	if ctx.get("tipo_dano", "") == "Raio" and u.pacto_menor == "trovao-cativo" and pactos(u, true) > 0 and uma_vez(u, "trovao_menor"):
		var ini2 = carta_inicial(u)
		for outra in u.cartas:
			if ini2 != null and ini2.fadiga > 0 and outra != ini2 and outra.espaco() > 0:
				gastar(b, u, 1, true)
				ini2.fadiga -= 1
				outra.fadiga += 1
				b._log("Trovão Cativo (menor): 1 de fadiga passa para %s." % outra.nome())
				break
	if u.pacto_menor == "mesa-vazia" and alvo.fichas_total("Fadiga") > 0 and pactos(u, true) > 0 and uma_vez(u, "mesa_menor"):
		gastar(b, u, 1, true)
		alvo.tirar_fichas("Fadiga", 1)
		b._tirar_fadiga(u, 1)
		b._log("Mesa Vazia (menor): %s devora 1 de Fadiga de %s." % [u.nome, alvo.nome])
	if ctx.get("estender", false) and not fichas_postas.is_empty():
		for o in b.oponentes(u):
			if o != alvo and o.viva() and Grade.adjacentes(o.pos, alvo.pos):
				if _vence(b, u, u.espirito, o, "sabedoria"):
					o.dar_ficha(fichas_postas[0])
					b._log("Estender o Sinal: %s também recebe %s." % [o.nome, fichas_postas[0]])
				break
	# Inverno: a habilidade inicial encheu -> Bloqueio na carta de herói.
	var ini3 = carta_inicial(u)
	if u.pacto == "inverno-imovel" and u.ativo("a-rainha-da-ultima-geada") and ini3 != null and ini3.fadiga >= ini3.limite() and ini3.limite() > 0 \
			and not u.cartas.any(func(x): return x.tem_ficha("Bloqueio")) and uma_vez(u, "inverno_bloqueio"):
		u.carta_heroi().dar_ficha("Bloqueio")
		b._log("A Rainha da Última Geada: %s ganha 1 Bloqueio." % u.nome)


## Um inimigo caiu: a Fênix ganha Pacto se ajudou a matar (feriu o monstro ou ele queimava).
static func inimigo_caiu(b, o) -> void:
	for br in bruxos(b, "fenix"):
		if o.efeitos.has("ferido_por_" + br.id) or o.fichas_total("Fogo") > 0:
			ganhar(b, br, 1, "Pacto da Fênix (morte presenciada)", true)


## A Fênix: cada ficha de Fogo causa 2 (todas, inclusive as hostis).
static func dano_do_fogo(b, n: int) -> int:
	for br in bruxos(b, "fenix"):
		if br.ativo("a-fenix"):
			return n * 2
	return n


## Início do turno de um inimigo: Atormentado vira Fadiga; Sonhos Roubados confunde.
static func inicio_turno_inimigo(b, o) -> void:
	var at: int = o.fichas_total("Atormentado")
	if at > 0:
		o.dar_ficha("Fadiga", at)
		b._log("%s está atormentado: +%d de Fadiga." % [o.nome, at])
		var dono = b.unidade(o.efeitos.get("atormentado_de", {}).get("id", ""))
		if dono != null and dono.pacto == "sonhos-roubados" and uma_vez(dono, "sonhos_cumprimento"):
			ganhar(b, dono, 1, "Pacto dos Sonhos Roubados (o pesadelo pesa)", true)
	if at > 0 and o.fichas_total("Confusão") == 0:
		for br in bruxos(b):
			if Grade.distancia(br.pos, o.pos) > 4 or br.acoes_reacao <= 0:
				continue
			var pleno: bool = br.pacto == "sonhos-roubados" and br.ativo("nimeria-a-dama-dos-sonhos-inacabados") and pode_gastar(br, 2)
			var menor: bool = br.pacto_menor == "sonhos-roubados" and pactos(br, true) > 0 and not suspenso(br, true)
			if not (pleno or menor):
				continue
			if pleno:
				gastar(b, br, 2)
			else:
				gastar(b, br, 1, true)
			br.acoes_reacao -= 1
			if _vence(b, br, br.espirito, o, "espirito"):
				o.dar_ficha("Confusão")
				b._log("Sonhos Roubados: %s embaralha os pensamentos de %s (Confusão)." % [br.nome, o.nome])
			else:
				b._log("Sonhos Roubados: %s resiste ao pesadelo." % o.nome)
			break


## O inimigo gastou uma ação para tirar uma ficha.
static func inimigo_tirou_ficha(b, o, ficha: String) -> void:
	if ficha in ["Imobilizar", "Atordoamento"]:
		var dono = b.unidade(o.efeitos.get("grilhao_de", {}).get("id", ""))
		if dono != null and dono.pacto == "grilhoes-vivos" and dono.viva():
			if uma_vez(dono, "grilhoes_cumprimento"):
				ganhar(b, dono, 1, "Pacto dos Grilhões Vivos (pagou para escapar)", true)
			if dono.ativo("o-carcereiro-sem-chave"):
				if uma_vez(dono, "grilhoes_foco"):
					dono.dar_ficha("Foco")
					b._log("O Carcereiro: %s ganha 1 Foco." % dono.nome)
				if dono.acoes_reacao > 0 and pode_gastar(dono, 1) and Grade.distancia(dono.pos, o.pos) <= 4:
					gastar(b, dono, 1)
					dono.acoes_reacao -= 1
					o.dar_ficha("Penalidade")
					b._log("O Carcereiro: %s recebe 1 Penalidade por se soltar." % o.nome)
	if ficha == "Atormentado":
		var dono2 = b.unidade(o.efeitos.get("atormentado_de", {}).get("id", ""))
		if dono2 != null and dono2.pacto == "sonhos-roubados" and dono2.ativo("nimeria-a-dama-dos-sonhos-inacabados") and uma_vez(dono2, "sonhos_foco"):
			dono2.dar_ficha("Foco")
			b._log("Niméria: %s ganha 1 Foco." % dono2.nome)


## Dano de ataque num herói: Última Porta reduz no protegido; menores reduzem no aliado ao lado.
static func reduzir_dano(b, alvo, dano: int) -> int:
	for br in bruxos(b):
		if dano <= 0:
			break
		if br.pacto == "ultima-porta" and br.protegido == alvo.id and br.ativo("a-sentinela-que-nunca-recuou") and br.acoes_reacao > 0 \
				and Grade.distancia(br.pos, alvo.pos) <= 4 and dano >= 3 and pode_gastar(br, 1):
			var x := mini(ceili(dano / 3.0), pactos(br))
			gastar(b, br, x)
			br.acoes_reacao -= 1
			b._log("A Sentinela: %s gasta %d Pacto(s) e o dano em %s cai %d." % [br.nome, x, alvo.nome, mini(3 * x, dano)])
			dano = maxi(dano - 3 * x, 0)
		elif br.pacto_menor == "ultima-porta" and br != alvo and Grade.adjacentes(br.pos, alvo.pos) and br.acoes_reacao > 0 \
				and dano >= 2 and pactos(br, true) > 0 and not suspenso(br, true):
			gastar(b, br, 1, true)
			br.acoes_reacao -= 1
			b._log("Última Porta (menor): %s reduz em 2 o dano em %s." % [br.nome, alvo.nome])
			dano = maxi(dano - 2, 0)
	# Retirar o Nome: o próprio Bruxo converte o golpe em fadiga.
	if alvo.pacto != "" and alvo.ativo("retirar-o-nome") and dano >= 3 and alvo.acoes_reacao > 0 and pode_gastar(alvo, 2):
		var livres := 0
		for c in alvo.cartas:
			livres += maxi(c.espaco(), 0)
		var conv := mini(livres, dano)
		if conv > 0:
			gastar(b, alvo, 2)
			alvo.acoes_reacao -= 1
			var resto := conv
			for c in alvo.cartas:
				var n := mini(resto, maxi(c.espaco(), 0))
				c.fadiga += n
				resto -= n
			alvo.cartas.erase(alvo.carta_com("retirar-o-nome"))
			b._log("Retirar o Nome: %s converte %d de dano em fadiga (a carta sai do jogo)." % [alvo.nome, conv])
			dano -= conv
	return dano


## Herói sofreu dano de ataque (depois de distribuir): Inverno menor desacelera o atacante.
static func heroi_atacado(b, atk, alvo, dano: int) -> void:
	if dano > 0 and alvo.pacto_menor == "inverno-imovel" and atk != null and not atk.eh_heroi() and Grade.distancia(atk.pos, alvo.pos) <= 4 \
			and alvo.acoes_reacao > 0 and pactos(alvo, true) > 0 and not suspenso(alvo, true):
		gastar(b, alvo, 1, true)
		alvo.acoes_reacao -= 1
		atk.efeitos["geada"] = {"ate_turno_de": alvo.id}
		b._log("Inverno (menor): o próximo movimento de %s rende só 1 quadrado." % atk.nome)


## Estouro num teste do Bruxo: intervenções do Abismo e a cobrança (carta final ao exílio).
static func no_estouro(b, u, t, defesa: bool) -> void:
	if u.pacto != "abismo" and u.pacto_menor != "abismo":
		return
	var final: int = t.carta_do_estouro
	if final < 0:
		return
	var interveio := false
	var fraca: bool = Carta.valor(final) < 7 and not Carta.eh_as(final)
	if fraca and u.pacto == "abismo" and u.ativo("malgor-o-credor-do-ultimo-folego") and pode_gastar(u, 2):
		gastar(b, u, 2)
		var vistas := [final]
		u.baralho.descarte.erase(final)
		for i in 2:
			var c: int = u.baralho.puxar_topo()
			if c >= 0:
				vistas.append(c)
		vistas.sort_custom(func(x, y): return (11 if Carta.eh_as(x) else Carta.valor(x)) > (11 if Carta.eh_as(y) else Carta.valor(y)))
		t.carta_do_estouro = vistas[0]
		for i in range(1, vistas.size()):
			u.baralho.exilio.append(vistas[i])
		u.baralho.descarte.append(vistas[0])
		b._log("Malgor: %s olha 3 cartas e fica com %s como carta final (exila as outras)." % [u.nome, Carta.nome(vistas[0])])
		interveio = true
	elif fraca and defesa and u.pacto == "abismo" and u.ativo("ultima-oferta") and u.acoes_reacao > 0:
		var c_uo = u.carta_com("ultima-oferta")
		if c_uo != null and c_uo.pode_pagar(2):
			c_uo.pagar(2)
			u.acoes_reacao -= 1
			interveio = _substituir_final(b, u, t, "Última Oferta")
	if not interveio and fraca and u.pacto_menor == "abismo" and not u.efeitos.has("abismo_menor") and pactos(u, true) > 0 and not suspenso(u, true):
		u.efeitos["abismo_menor"] = {}
		gastar(b, u, 1, true)
		_substituir_final(b, u, t, "Abismo (pacto menor)")
	# Cobrança: a carta final vai para o exílio.
	if not suspenso(u) and u.pacto == "abismo" or (u.pacto_menor == "abismo" and not suspenso(u, true)):
		if t.carta_do_estouro in u.baralho.descarte:
			u.baralho.descarte.erase(t.carta_do_estouro)
			u.baralho.exilio.append(t.carta_do_estouro)
			b._log("Cobrança de Malgor: %s vai para o exílio." % Carta.nome(t.carta_do_estouro))


static func _substituir_final(b, u, t, nome: String) -> bool:
	var velha: int = t.carta_do_estouro
	var nova: int = u.baralho.puxar_topo()
	if nova < 0:
		return false
	u.baralho.descarte.erase(velha)
	u.baralho.exilio.append(velha)
	u.baralho.descarte.append(nova)
	t.carta_do_estouro = nova
	b._log("%s: %s troca a carta final (%s → %s)." % [nome, u.nome, Carta.nome(velha), Carta.nome(nova)])
	return true


## Fim do turno do Bruxo: cobranças que o jogo mede e reparações automáticas.
static func fim_do_turno(b, u, conservou: bool) -> void:
	if u.pacto == "":
		return
	var inicio: Vector2i = u.efeitos.get("pos_inicio", {}).get("pos", u.pos)
	match u.pacto:
		"ultima-porta":
			var p = b.unidade(u.protegido)
			if p != null and p.viva() and Grade.distancia(p.pos, u.pos) > 4 and not b.preso(u):
				suspender(b, u, "Última Porta (protegido longe)")
		"caminhos-roubados":
			if u.efeitos.has("conjurou_pacto") and u.pos == inicio and b.passos_por_acao(u) > 0:
				suspender(b, u, "Caminhos Roubados (ficou no mesmo lugar)")
			elif suspenso(u) and u.pos != inicio and not u.efeitos.has("conjurou_pacto"):
				u.efeitos.erase("suspenso")
				b._log("Caminhos Roubados: %s terminou em outro lugar; o pacto volta." % u.nome)
		"trovao-cativo":
			var h = u.carta_heroi()
			var ini = carta_inicial(u)
			var carga: int = (h.fadiga if h != null else 0) + (ini.fadiga if ini != null else 0)
			if u.efeitos.has("conjurou_pacto") and carga <= 0:
				suspender(b, u, "Trovão Cativo (descarregou tudo)")
		"inverno-imovel":
			if u.efeitos.has("gastou_pacto") and u.moveu_no_turno:
				suspender(b, u, "Inverno Imóvel (gastou Pacto e se moveu)")
			elif conservou:
				var ini2 = carta_inicial(u)
				if suspenso(u) and not u.moveu_no_turno and ini2 != null and ini2.fadiga > 0:
					u.efeitos.erase("suspenso")
					b._log("Inverno Imóvel: %s se mantém imóvel; o pacto volta." % u.nome)
				elif uma_vez(u, "inverno_cumprimento"):
					ganhar(b, u, 1, "Pacto do Inverno Imóvel (conservou a fadiga)", true)
	if u.efeitos.has("suspenso_menor") and u.pacto_menor in ["caminhos-roubados", "inverno-imovel"]:
		u.efeitos.erase("suspenso_menor")


## Opção do fim de turno: conservar a fadiga (Inverno Imóvel).
static func pode_conservar(u) -> bool:
	return u.pacto == "inverno-imovel" and u.cartas.any(func(x): return x.fadiga > 0)


## Crítico com a metade do patrono à vista: Pactos iguais ao nível.
static func critico(b, u) -> bool:
	var h = u.carta_heroi()
	if h == null or u.pacto == "":
		return false
	var hid: String = Catalogo.pactos().get(u.pacto, {}).get("heroi", "")
	if Catalogo.slug(Catalogo.heroi(hid).get("nome", "")) != h.slug():
		return false
	ganhar(b, u, u.nivel_pacto, "Crítico do patrono")
	return true


## Reação oferecida ao Bruxo atacado (Descarregar a Tormenta).
static func reacao_disponivel(b, atk, dfs) -> String:
	if dfs.eh_heroi() and dfs.ativo("descarregar-a-tormenta") and atk.viva() and not atk.eh_heroi() and dfs.acoes_reacao > 0 \
			and Grade.distancia(atk.pos, dfs.pos) <= 4 and int(dfs.foco.get("maos", 0)) > 0:
		var c = dfs.carta_com("descarregar-a-tormenta")
		if c != null and c.pode_pagar(1):
			return "descarregar-a-tormenta"
	return ""


static func reagir_descarga(b, h, atk) -> void:
	var c = h.carta_com("descarregar-a-tormenta")
	c.pagar(1)
	h.acoes_reacao -= 1
	var tirou := 0
	for outra in h.cartas:
		while outra != c and outra.fadiga > 0 and tirou < h.espirito:
			outra.fadiga -= 1
			tirou += 1
	b._log("Descarregar a Tormenta: %s solta %d de fadiga numa descarga contra %s." % [h.nome, tirou, atk.nome])
	b._novo_ataque(h, atk, {"habilidade": "Descarregar a Tormenta", "magico": true, "magia_do_pacto": true, "tipo_dano": "Raio",
		"bonus_dano": 2 * tirou, "rotulo_bonus": "descarga (%d de fadiga)" % tirou})
