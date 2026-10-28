## Simulação de balanceamento. Duas IAs de herói (SIM_IA = ingenua, habilidades ou ambas):
## - ingênua: anda até o inimigo mais próximo e ataca (os conjuradores com a magia básica);
## - habilidades (0.15): cura aliados feridos (Clérigo), recupera o fôlego com o baralho
##   abaixo da metade, usa as cartas de ataque e de preparo, as cartas "durante o ataque"
##   na mesa e cartas de área sem pegar aliados.
## Defesa automática parando em 17. Horda (SIM_HORDA != 0): 4 heróis contra lacaios sem fim.
## Rodar: godot --headless --path . -s res://tools/simular_balanceamento.gd
## Variável SIM_N muda o número de combates por cenário (padrão 300).
extends SceneTree

const Batalha := preload("res://core/batalha.gd")
const Dados := preload("res://core/dados_batalha.gd")
const DadosFazenda := preload("res://core/dados_fazenda.gd")
const DadosMasmorra := preload("res://core/dados_masmorra.gd")
const DadosPantano := preload("res://core/dados_pantano.gd")
const Grade := preload("res://core/grade.gd")
const Personagem := preload("res://core/personagem.gd")
const Catalogo := preload("res://core/catalogo.gd")

const CLASSES := ["Guerreiro", "Ladino", "Clérigo", "Caçador", "Mago"]

## Fichas típicas por classe (atributos na distribuição 3,3,2,2,1,1,1,0,0), arma e
## a carta de ataque básica da classe (os conjuradores atacam com magia quando dá).
const MODELOS := {
	"Guerreiro": {"atributos": {"forca": 3, "constituicao": 3, "destreza": 2, "sabedoria": 2, "percepcao": 1, "raciocinio": 1, "espirito": 1, "mentira": 0, "diplomacia": 0},
		"arma": "espada_longa", "armadura": "cota_de_malha", "escudo": "escudo_leve", "cartas": [],
		"cartas_hab": ["classe.guerreiro.ombro-de-ferro", "classe.guerreiro.postura-do-leao"]},
	"Ladino": {"atributos": {"destreza": 3, "percepcao": 3, "sabedoria": 2, "constituicao": 2, "forca": 1, "raciocinio": 1, "mentira": 1, "espirito": 0, "diplomacia": 0},
		"arma": "faca", "armadura": "couro_do_batedor", "escudo": "nenhum", "cartas": [],
		"cartas_hab": ["classe.ladino.ataque-furtivo", "classe.ladino.nunca-visto"]},
	"Clérigo": {"atributos": {"sabedoria": 3, "constituicao": 3, "forca": 2, "espirito": 2, "destreza": 1, "percepcao": 1, "diplomacia": 1, "raciocinio": 0, "mentira": 0},
		"arma": "espada_longa", "armadura": "cota_de_malha", "escudo": "nenhum", "foco": "simbolo_sagrado", "cartas": ["classe.clerigo.feixe-de-luz"],
		"cartas_hab": ["classe.clerigo.feixe-de-luz", "classe.clerigo.toque-restaurador", "classe.clerigo.bencao-dos-salmos"]},
	"Caçador": {"atributos": {"destreza": 3, "percepcao": 3, "constituicao": 2, "sabedoria": 2, "forca": 1, "raciocinio": 1, "espirito": 1, "mentira": 0, "diplomacia": 0},
		"arma": "arco_curto", "armadura": "couro_do_batedor", "escudo": "nenhum", "cartas": [],
		"cartas_hab": ["classe.cacador.flecha-aleijadora", "classe.cacador.flecha-pesada"]},
	"Mago": {"atributos": {"raciocinio": 3, "sabedoria": 3, "destreza": 2, "constituicao": 2, "percepcao": 1, "espirito": 1, "forca": 1, "mentira": 0, "diplomacia": 0},
		"arma": "faca", "armadura": "nenhuma", "escudo": "nenhum", "foco": "varinha_eletrizante", "cartas": ["classe.mago.aprendiz-de-fogo"],
		"cartas_hab": ["classe.mago.aprendiz-de-fogo", "classe.mago.aprendiz-de-terra"], "meias_hab": ["classe.mago.misseis-magicos", "classe.mago.armadura-arcana"]},
}

## Cartas de cura que a IA com habilidades usa (slug do lado -> opção).
const CURAS := {"toque-restaurador": "", "bencao-dos-salmos": "curar"}
## Cartas de preparo sem alvo que valem a pena no turno.
const PREPAROS := ["preparar-o-tiro", "o-martelo-da-luz", "camuflagem"]

var ia := "habilidades"
var usos := {"cartas": 0, "curas": 0, "folego": 0, "na_mesa": 0, "turnos": 0}


func _init() -> void:
	var n := int(OS.get_environment("SIM_N")) if OS.get_environment("SIM_N") != "" else 300
	# SIM_CAL=elite:vida:dano,chefe:vida:dano — testa multiplicadores sem mexer no código.
	for item in OS.get_environment("SIM_CAL").split(",", false):
		var partes := item.split(":")
		preload("res://core/encontros.gd").calibragem[partes[0]] = {"vida": float(partes[1]), "dano": float(partes[2])}
	var linhas := PackedStringArray()
	var modo_ia := OS.get_environment("SIM_IA") if OS.get_environment("SIM_IA") != "" else "ambas"
	var ias: Array = ["ingenua", "habilidades"] if modo_ia == "ambas" else [modo_ia]
	linhas.append("cenario;herois;vitorias_%;rodadas_media;rodadas_p10;rodadas_p90;dano_heroi_por_turno;dano_heroi_por_ataque;acerto_heroi_%;dano_inimigo_por_turno;dano_inimigo_por_ataque;acerto_inimigo_%;vida_restante_%;herois_caidos;dano_recebido_%_da_vida")
	# Dano por classe: um herói contra um boneco de treino (médio, vida infinita), 6 rodadas.
	if OS.get_environment("SIM_TREINO") != "0":
		for ia_t in ias:
			ia = ia_t
			for cl in CLASSES:
				por_classe.clear()
				linhas.append(_rodar("Treino %s [%s]" % [cl, ia], func(f): return _treino(f), 1, maxi(n / 3, 50), 6).split(";").slice(0, 1)[0]
					+ ";" + _linha_classe(cl))
	por_classe.clear()
	var tipos: Array = OS.get_environment("SIM_TIPOS").split(",", false) if OS.get_environment("SIM_TIPOS") != "" \
		else ["obstaculo", "simples", "elite", "elite_escoltado", "chefe"]
	var grupos: Array = [4, 2, 3, 1] if OS.get_environment("SIM_GRUPOS") == "" else Array(OS.get_environment("SIM_GRUPOS").split(",", false)).map(func(x): return int(x))
	var uso_por_ia := {}
	for ia_t in ias:
		ia = ia_t
		usos = {"cartas": 0, "curas": 0, "folego": 0, "na_mesa": 0, "turnos": 0}
		for tipo in tipos:
			for q in grupos:
				linhas.append(_rodar("Encontro %s [%s]" % [tipo, ia], func(f): return Dados.encontro_na_arena(f, tipo), q, n))
		if OS.get_environment("SIM_TIPOS") == "":
			linhas.append(_rodar("X1 (Chefe Goblin, elite) [%s]" % ia, func(f): return Dados.x1(f), 1, n))
			for q in [4, 2]:
				linhas.append(_rodar("Toupeira Atroz (elite) [%s]" % ia, func(f): return _toupeira(f), q, n))
			for q in [4, 2]:
				linhas.append(_rodar("Sir Aldric e a guarda (chefe da cripta, com luz) [%s]" % ia, func(f): return _aldric(f), q, n))
			for q in [4, 2]:
				linhas.append(_rodar("Bruxa Morgana e a escolta (elite do pântano, com luz) [%s]" % ia, func(f): return _grupo_da_missao(f, DadosPantano.missao(f), "bruxa"), q, n, 40))
		uso_por_ia[ia] = usos.duplicate()
	linhas.append("")
	linhas.append("ia;cartas_por_turno;curas_por_turno;folegos_por_turno;cartas_na_mesa_por_turno")
	for k in uso_por_ia:
		var us: Dictionary = uso_por_ia[k]
		var t := maxi(int(us["turnos"]), 1)
		linhas.append("%s;%.2f;%.2f;%.2f;%.2f" % [k, float(us["cartas"]) / t, float(us["curas"]) / t, float(us["folego"]) / t, float(us["na_mesa"]) / t])
	if OS.get_environment("SIM_HORDA") != "0":
		linhas.append("")
		linhas.append("horda;herois;rodadas_ate_cair_todos;rodadas_ate_o_primeiro_cair;lacaios_mortos;mortos_por_rodada;dano_heroi_por_turno;dano_recebido_por_rodada;cartas_usadas_por_turno;curas_por_rodada;folegos_por_rodada")
		for ia_t in ias:
			ia = ia_t
			linhas.append(_horda(4, maxi(n / 6, 20)))
	linhas.append("")
	linhas.append("classe;dano_por_turno;dano_por_ataque;ataques_por_turno")
	for cl in por_classe:
		var v: Array = por_classe[cl]
		linhas.append("%s;%.1f;%.1f;%.2f" % [cl, float(v[0]) / maxi(v[2], 1), float(v[0]) / maxi(v[1], 1), float(v[1]) / maxi(v[2], 1)])
	if not dif_i.is_empty():
		var sd := 0.0
		var sr := 0.0
		for v in dif_i: sd += v
		for v in res_h: sr += v
		linhas.append("")
		linhas.append("diferenca_media_nos_acertos_dos_inimigos;%.2f" % (sd / dif_i.size()))
		linhas.append("resistencia_media_dos_herois_atingidos;%.2f" % (sr / res_h.size()))
	for l in linhas:
		print(l)
	var saida := OS.get_environment("SIM_SAIDA")
	if saida != "":
		var arq := FileAccess.open(saida, FileAccess.WRITE)
		arq.store_string("\n".join(linhas) + "\n")
	quit()


func _ficha(classe: String) -> Dictionary:
	var f := Personagem.nova()
	var m: Dictionary = MODELOS[classe]
	f["nome"] = classe
	f["classe"] = classe
	f["atributos"] = m["atributos"].duplicate()
	f["arma"] = m["arma"]
	f["armadura"] = m["armadura"]
	f["escudo"] = m["escudo"]
	f["foco"] = m.get("foco", "nenhum")
	f["cartas"] = m["cartas"].duplicate()
	f["meias"] = []
	if ia == "habilidades":
		f["cartas"] = m.get("cartas_hab", m["cartas"]).duplicate()
		f["meias"] = m.get("meias_hab", []).duplicate()
	f["herois"] = [Catalogo.herois_de(classe)[0]["id"], "raca.humano.heroi.incansavel"]
	return f


func _treino(fichas) -> Dictionary:
	var c := Dados.x1(fichas)
	c["unidades"] = [c["unidades"][0], Dados.inimigo_de("boneco", "Boneco de treino", "goblin", Vector2i(6, 4), "medio", "neutro", 4, {"vida": 99999, "padrao_por_turno": 0, "mov_por_turno": 0, "velocidade": 0})]
	c["nome"] = "Treino"
	return c


func _linha_classe(cl: String) -> String:
	var v: Array = por_classe.get(cl, [0, 0, 0])
	return "dano/turno %.1f;dano/ataque %.1f;ataques/turno %.2f" % [float(v[0]) / maxi(v[2], 1), float(v[0]) / maxi(v[1], 1), float(v[1]) / maxi(v[2], 1)]


func _toupeira(fichas) -> Dictionary:
	var c := Dados.arena(fichas)
	var missao := DadosFazenda.missao(fichas)
	var t: Dictionary = {}
	for u in missao["unidades"]:
		if u["id"] == "toupeira":
			t = u.duplicate(true)
	t["alerta"] = true
	t["dormindo"] = false
	t["pos"] = Vector2i(9, 5)
	var herois: Array = c["unidades"].filter(func(u): return u["lado"] != "inimigo")
	c["unidades"] = herois + [t]
	c["nome"] = "Toupeira"
	return c


## Um grupo de inimigos de uma missão numa arena clara (sem a exploração).
func _grupo_da_missao(fichas, missao: Dictionary, grupo: String) -> Dictionary:
	var c := Dados.arena(fichas)
	var inimigos := []
	var y := 1
	for u in missao["unidades"]:
		if u.get("grupo", "") == grupo:
			var e: Dictionary = u.duplicate(true)
			e["alerta"] = true
			e["pos"] = Vector2i(10, y)
			y += 2
			inimigos.append(e)
	c["unidades"] = c["unidades"].filter(func(u): return u["lado"] != "inimigo") + inimigos
	return c


## O chefe da cripta e a guarda de ossos numa arena clara (sem a parte da exploração).
func _aldric(fichas) -> Dictionary:
	var c := Dados.arena(fichas)
	var missao := DadosMasmorra.missao(fichas)
	var inimigos := []
	var y := 2
	for u in missao["unidades"]:
		if u.get("grupo", "") == "cripta":
			var e: Dictionary = u.duplicate(true)
			e["alerta"] = true
			e["pos"] = Vector2i(10, y)
			y += 2
			inimigos.append(e)
	c["unidades"] = c["unidades"].filter(func(u): return u["lado"] != "inimigo") + inimigos
	c["nome"] = "Aldric"
	return c


var por_classe := {}   # classe -> [dano de ataques, ataques, turnos]
var dif_i := []        # diferença nos acertos dos inimigos
var res_h := []        # resistência dos heróis atingidos


func _rodar(nome: String, montar: Callable, q: int, n: int, max_rodadas := 0) -> String:
	var vit := 0
	var rodadas := []
	var dano_h := 0
	var dano_i := 0
	var turnos_h := 0
	var turnos_i := 0
	var ataques_h := 0
	var ataques_i := 0
	var acertos_h := 0
	var acertos_i := 0
	var vida := 0.0
	var golpe_h := 0
	var golpe_i := 0
	var caidos := 0
	for s in n:
		var fichas := []
		var classes_sim: Array = CLASSES if OS.get_environment("SIM_CLASSE") == "" else [OS.get_environment("SIM_CLASSE")]
		for i in q:
			fichas.append(_ficha(classes_sim[(s + i) % classes_sim.size()]))
		var b := Batalha.new(montar.call(fichas), s + 1)
		b.defesa_automatica = true
		b.distribuicao_automatica = true
		b.iniciar()
		var vez := Vector2i(-1, -1)
		var visto := {}
		for passo in 20000:
			var agora := Vector2i(b.rodada, b.indice_vez)
			if agora != vez and b.fase in [Batalha.Fase.HEROI_ESCOLHE, Batalha.Fase.IA_TURNO]:
				vez = agora
				if b.ativa().eh_heroi():
					turnos_h += 1
					usos["turnos"] += 1
					if not por_classe.has(b.ativa().classe):
						por_classe[b.ativa().classe] = [0, 0, 0]
					por_classe[b.ativa().classe][2] += 1
				else:
					turnos_i += 1
			if b.resultado.has("acertou") and not is_same(b.resultado, visto):
				visto = b.resultado
				var atk = b.unidade(b.resultado["atacante"])
				if atk != null and atk.eh_heroi():
					var cl: String = atk.classe
					if not por_classe.has(cl):
						por_classe[cl] = [0, 0, 0]
					por_classe[cl][1] += 1
					ataques_h += 1
					acertos_h += 1 if b.resultado["acertou"] else 0
					golpe_h += int(b.resultado["dano"])
				elif atk != null:
					if b.resultado["acertou"]:
						dif_i.append(int(b.resultado["ataque"]) - int(b.resultado["defesa"]))
						res_h.append(b._resistencia_de(b.unidade(b.resultado["defensor"])))
					ataques_i += 1
					acertos_i += 1 if b.resultado["acertou"] else 0
					golpe_i += int(b.resultado["dano"])
			for e in b.eventos:
				if e["tipo"] == "dano":
					var alvo = b.unidade(e["id"])
					if alvo == null:
						continue
					if alvo.eh_heroi():
						dano_i += int(e["valor"])
					else:
						dano_h += int(e["valor"])
						# Dano por classe pelos eventos: conta também magias sem teste (Mísseis, Juízo).
						var quem = b.ativa()
						if quem != null and quem.eh_heroi():
							if not por_classe.has(quem.classe):
								por_classe[quem.classe] = [0, 0, 0]
							por_classe[quem.classe][0] += int(e["valor"])
			b.eventos.clear()
			if b.fase in [Batalha.Fase.VITORIA, Batalha.Fase.DERROTA] or (max_rodadas > 0 and b.rodada > max_rodadas):
				break
			_passo(b)
		rodadas.append(b.rodada)
		if b.fase == Batalha.Fase.VITORIA:
			vit += 1
		for h in b.herois():
			vida += float(h.baralho.baralho.size() + h.baralho.mao.size()) / 52.0
			if not h.viva():
				caidos += 1
	rodadas.sort()
	var media := 0.0
	for r in rodadas:
		media += r
	media /= n
	return "%s;%d;%d;%.1f;%d;%d;%.1f;%.1f;%d;%.1f;%.1f;%d;%d;%.2f" % [nome, q, vit * 100 / n, media,
		rodadas[int(n * 0.1)], rodadas[int(n * 0.9)],
		float(dano_h) / maxi(turnos_h, 1), float(golpe_h) / maxi(ataques_h, 1), acertos_h * 100 / maxi(ataques_h, 1),
		float(dano_i) / maxi(turnos_i, 1), float(golpe_i) / maxi(ataques_i, 1), acertos_i * 100 / maxi(ataques_i, 1),
		int(vida * 100 / (n * q)), float(caidos) / n] + ";%d" % int(dano_i * 100.0 / (n * q * 52))


func _passo(b) -> void:
	match b.fase:
		Batalha.Fase.HEROI_ESCOLHE:
			_turno_heroi(b)
		Batalha.Fase.HEROI_ATACANDO:
			if ia == "habilidades":
				for k in 4:
					var opcoes: Array = b.cartas_durante_ataque()
					if opcoes.is_empty() or not b.heroi_durante_ataque(opcoes[0]["slug"], opcoes[0]["opcao"]):
						break
					usos["na_mesa"] += 1
			if b.teste_ataque.soma_cartas() < 17 and b.teste_ataque.pode_puxar():
				b.puxar()
			else:
				b.parar()
		Batalha.Fase.RESOLVIDO, Batalha.Fase.INTERACAO_RESOLVIDA:
			b.continuar()
		Batalha.Fase.INTERACAO_TESTE:
			b.parar()
		_:
			if b.fase_automatica():
				b.passo_automatico()
			elif b.vantagem_pendente():
				b.heroi_vantagem_confirmar()
			else:
				b.parar()


func _turno_heroi(b) -> void:
	var u = b.ativa()
	if ia == "habilidades" and _turno_habilidades(b, u):
		return
	var alvos: Array = b.inimigos_vivos().filter(func(o): return o.alerta or true)
	if alvos.is_empty():
		b.encerrar_turno()
		return
	alvos.sort_custom(func(x, y): return Grade.distancia(u.pos, x.pos) < Grade.distancia(u.pos, y.pos))
	var alvo = alvos[0]
	# Conjuradores: ataque mágico da carta básica quando dá (fadiga e alcance).
	var opcoes: Array = b.opcoes_cartas(u)
	for i in u.cartas.size():
		var info: Dictionary = b._info_lado(u.cartas[i])
		if info.get("ataque_magico", false) and info.get("alvo", "") == "inimigo_magico" and opcoes[i]["pode"]:
			var alc: Array = b.alvos_de_habilidade(u, u.cartas[i])
			if not alc.is_empty():
				alc.sort_custom(func(x, y): return Grade.distancia(u.pos, x.pos) < Grade.distancia(u.pos, y.pos))
				if b.heroi_usar_carta(i, alc[0]):
					return
	if b.heroi_atacar(alvo):
		return
	if u.acoes_padrao <= 0:
		b.encerrar_turno()
		return
	# Preso sem ninguém ao alcance: vira a carta que segura o Imobilizar (as fichas voláteis saem).
	if b.preso(u) and not u.efeitos.has("virou_preso"):
		for i in u.cartas.size():
			if u.cartas[i].tem_ficha("Imobilizar") and u.cartas[i].lados.size() > 1 and b.heroi_virar(i, "acao"):
				u.efeitos["virou_preso"] = {"ate": "inicio_turno"}
				return
	var info: Dictionary = b.alcance_movimento(u)
	var melhor: Vector2i = u.pos
	# Quem atira não encosta: só chega até ter linha de visão e alcance, a 2+ quadrados.
	var nota := func(p: Vector2i) -> float:
		if not u.a_distancia:
			return -Grade.distancia(p, alvo.pos)
		var d := Grade.distancia(p, alvo.pos)
		return (100.0 if b.grade.linha_de_visao(p, alvo.pos) and d >= 2 and d <= 8 else 0.0) - absf(d - 5)
	for p in info["mapa"]:
		if nota.call(p) > nota.call(melhor):
			melhor = p
	if melhor != u.pos and b.heroi_mover(melhor):
		return
	b.encerrar_turno()


# --- IA com habilidades (0.15) ----------------------------------------------------------

## Uma ação com carta, cura ou fôlego. Devolve true se fez algo (o resto do turno segue
## no próximo passo); false = cai na IA ingênua (atacar ou andar).
func _turno_habilidades(b, u) -> bool:
	if b.inimigos_vivos().is_empty():
		return false
	if _tentar_curar(b, u):
		usos["curas"] += 1
		return true
	var inimigo_ao_lado: bool = b.inimigos_vivos().any(func(o): return Grade.adjacentes(o.pos, u.pos))
	if u.acoes_padrao > 0 and u.baralho.baralho.size() < 22 and u.baralho.descarte.size() >= 6 and not inimigo_ao_lado:
		if b.heroi_recuperar_folego():
			usos["folego"] += 1
			return true
	if _tentar_carta(b, u):
		usos["cartas"] += 1
		return true
	return false


func _perdidas(h) -> int:
	return h.baralho.descarte.size()


## Clérigo (ou quem tiver carta de cura): cura o aliado com mais cartas no descarte (5+).
func _tentar_curar(b, u) -> bool:
	var feridos: Array = b.herois_ativos().filter(func(h): return _perdidas(h) >= 5)
	if feridos.is_empty():
		return false
	feridos.sort_custom(func(x, y): return _perdidas(x) > _perdidas(y))
	var opcoes: Array = b.opcoes_cartas(u)
	for i in u.cartas.size():
		var c = u.cartas[i]
		if not CURAS.has(c.slug()):
			continue
		if CURAS[c.slug()] != "":
			c.opcao = CURAS[c.slug()]
		var op: Dictionary = b.opcoes_cartas(u)[i]
		var pode: bool = op["pode"] if not op.has("opcoes") else op["opcoes"].any(func(o): return o["opcao"] == c.opcao and o["pode"])
		if not pode:
			continue
		var alcance: Array = b.alvos_de_habilidade(u, c).filter(func(h): return h in feridos)
		if not alcance.is_empty():
			alcance.sort_custom(func(x, y): return _perdidas(x) > _perdidas(y))
			if b.heroi_usar_carta(i, alcance[0], c.opcao):
				return true
		# Ninguém ao alcance: anda até o mais ferido (só com o deslocamento ou a ação de movimento).
		if u.acoes_mov > 0 or u.deslocamento > 0:
			var mapa: Dictionary = b.alcance_movimento(u)["mapa"]
			var melhor = null
			for p in mapa:
				if Grade.distancia(p, feridos[0].pos) <= int(b._info_lado(c).get("alcance", 1)) and (melhor == null or mapa[p]["custo"] < mapa[melhor]["custo"]):
					melhor = p
			if melhor != null and not b.alcance_movimento(u)["precisa_acao"] and b.heroi_mover(melhor):
				return true
	return false


## Cartas de ataque (alvo inimigo), de área (sem aliados na área) e de preparo.
func _tentar_carta(b, u) -> bool:
	# Primeiro as cartas que fazem teste de ataque (dano esperado maior); depois as outras.
	for so_ataque in [true, false]:
		if _tentar_carta_passo(b, u, so_ataque):
			return true
	return false


func _tentar_carta_passo(b, u, so_ataque: bool) -> bool:
	var opcoes: Array = b.opcoes_cartas(u)
	for i in u.cartas.size():
		var c = u.cartas[i]
		var op: Dictionary = opcoes[i]
		if op["uso"] != "ativada" or CURAS.has(c.slug()):
			continue
		var escolhas: Array = [""]
		if op.has("opcoes"):
			escolhas = op["opcoes"].filter(func(o): return o["pode"]).map(func(o): return o["opcao"])
		elif not op["pode"]:
			continue
		for escolha in escolhas:
			c.opcao = escolha
			var info: Dictionary = b._info_lado(c)
			var tipo: String = info.get("alvo", "nenhum")
			var com_teste: bool = info.get("ataque_magico", false) or tipo in ["inimigo_corpo", "inimigo_salto", "inimigo_investida", "inimigo_arma", "inimigo_distancia"]
			if com_teste != so_ataque:
				continue
			if tipo.begins_with("inimigo"):
				var alvos: Array = b.alvos_de_habilidade(u, c)
				if alvos.is_empty():
					continue
				alvos.sort_custom(func(x, y): return x.vida < y.vida)
				if b.heroi_usar_carta(i, alvos[0], escolha):
					return true
			elif tipo == "area" and info.get("ataque_magico", false):
				var spec: Dictionary = b.spec_area(c)
				for o in b.inimigos_vivos():
					if b.motivo_area(u, spec, o.pos) != "":
						continue
					var cels: Array = b.celulas_da_area(u, spec, o.pos, 0)
					if b.herois_ativos().any(func(h): return h.pos in cels) or b.unidades_em(cels, u).size() < 2:
						continue
					if b.heroi_usar_area(i, o.pos, 0, escolha):
						return true
			elif tipo == "nenhum" and c.slug() in PREPAROS and not u.efeitos.has("preparou_" + c.slug()):
				if b.heroi_usar_carta(i, null, escolha):
					u.efeitos["preparou_" + c.slug()] = {"ate": "inicio_turno"}
					return true
	return false


# --- Horda (0.15) ------------------------------------------------------------------------

## 4 heróis contra lacaios sem fim: começam 6; no início de cada rodada entram mais 2
## (no máximo 12 vivos). Mede quanto tempo o grupo aguenta (até 60 rodadas).
func _horda(q: int, n: int) -> String:
	var rodadas_total := 0
	var primeiro_total := 0
	var mortos_total := 0
	var dano_h := 0
	var turnos_h := 0
	var dano_i := 0
	usos = {"cartas": 0, "curas": 0, "folego": 0, "na_mesa": 0, "turnos": 0}
	for s in n:
		var fichas := []
		for i in q:
			fichas.append(_ficha(CLASSES[(s + i) % CLASSES.size()]))
		var c := Dados.arena(fichas, false)
		c["unidades"] = c["unidades"].filter(func(u): return u["lado"] != "inimigo")
		c["vitoria_ao_derrotar_todos"] = false
		c["nome"] = "Horda"
		var b := Batalha.new(c, s + 1000)
		b.defesa_automatica = true
		b.distribuicao_automatica = true
		var seq := [0]
		var entrar := func(k: int):
			for j in k:
				if b.inimigos_vivos().size() >= 12:
					return
				seq[0] += 1
				var pos := Vector2i(b.grade.largura - 1, (seq[0] * 3) % b.grade.altura)
				while b.grade.bloqueado(pos) or b.na_posicao(pos) != null:
					pos = Vector2i(b.grade.largura - 1 - randi() % 3, randi() % b.grade.altura)
				b.adicionar_unidade(Dados.inimigo_de("horda%d" % seq[0], "Lacaio da horda", "goblin", pos, "lacaio", "aggro", q, {}))
		entrar.call(6)
		b.iniciar()
		var ultima := b.rodada
		var primeiro := 0
		for passo in 40000:
			if b.rodada != ultima:
				ultima = b.rodada
				entrar.call(2)
				if primeiro == 0 and b.herois_ativos().size() < q:
					primeiro = b.rodada
			for e in b.eventos:
				if e["tipo"] == "dano":
					var alvo = b.unidade(e["id"])
					if alvo != null and alvo.eh_heroi():
						dano_i += int(e["valor"])
					elif alvo != null:
						dano_h += int(e["valor"])
			b.eventos.clear()
			if b.fase in [Batalha.Fase.VITORIA, Batalha.Fase.DERROTA] or b.rodada > 60:
				break
			_passo(b)
		rodadas_total += b.rodada
		primeiro_total += primeiro if primeiro > 0 else b.rodada
		mortos_total += b.unidades.filter(func(o): return not o.eh_heroi() and not o.viva()).size()
		turnos_h += b.rodada * q
	var r := maxf(float(rodadas_total), 1.0)
	return "Horda [%s];%d;%.1f;%.1f;%.1f;%.2f;%.1f;%.1f;%.2f;%.2f;%.2f" % [ia, q, float(rodadas_total) / n, float(primeiro_total) / n,
		float(mortos_total) / n, mortos_total / r, float(dano_h) / maxi(turnos_h, 1), dano_i / r,
		float(usos["cartas"]) / maxi(turnos_h, 1), usos["curas"] / r, usos["folego"] / r]
