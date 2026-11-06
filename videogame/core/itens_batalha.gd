## Efeitos dos equipamentos na batalha (0.25): os 170 itens do Lucas.
##
## A batalha (core/batalha.gd) chama estes ganchos nos pontos certos:
## bonus_de_dano, limite_de_ataque, limite_de_defesa, resistencia, ignora_resistencia,
## depois_do_ataque (herói atacou), defendeu (herói foi atacado), inicio_do_turno, fim_do_turno,
## custo_de_magia, usar_consumivel e as cartas de item (LADOS / motivo / usar).
##
## "Somente o equipamento ativo funciona" (inventário por espaços): arma = a que está na mão
## (u.arma["id"]); escudo e armadura = os vestidos; acessórios, capa, elmo e botas = u.vestidos.
extends RefCounted

const Grade := preload("res://core/grade.gd")
const Carta := preload("res://core/carta.gd")
const Itens := preload("res://core/itens.gd")
const Origens := preload("res://core/cartas_origens.gd")

const PROFANOS := ["morto-vivo", "demonio"]


static func arma(u) -> String:
	return str(u.arma.get("id", ""))


static func custo_fadiga_da_arma(u, custo: int) -> int:
	return custo - 1 if custo > 1 and u.ativo("foco-mortal") else custo


static func corrente_para_lacar(b, u, alvo) -> Dictionary:
	if u == null or alvo == null or not u.eh_heroi() or not u.viva() or u.acoes_reacao <= 0 \
			or arma(u) != "corrente_de_caca" or Origens.maior(alvo, u) or b.motivo_sem_ataque(u, alvo, false) != "":
		return {}
	var c = u.carta_com("arma")
	var custo := custo_fadiga_da_arma(u, 2)
	return {"carta": c, "custo": custo} if c != null and c.pode_pagar(custo) else {}


static func fadiga_do_frenesi(b, u, excesso: int) -> void:
	if excesso <= 0:
		return
	var c = u.carta_com("arma")
	var na_arma := mini(excesso, maxi(c.espaco(), 0)) if c != null else 0
	if na_arma > 0:
		c.pagar(na_arma)
	var exiladas := 0
	var trituradas := 0
	var estava_de_pe: bool = u.viva()
	for i in excesso - na_arma:
		if not u.baralho.descarte.is_empty():
			u.baralho.exilio.append(u.baralho.descarte.pop_back())
		else:
			var carta: int = u.baralho.puxar_topo()
			if carta < 0:
				break
			u.baralho.descarte.append(carta)
			trituradas += 1
			continue
		exiladas += 1
	b._log("Montante do Frenesi: %d de Fadiga, %d na arma, %d carta(s) exilada(s), %d triturada(s)." \
		% [excesso, na_arma, exiladas, trituradas])
	if estava_de_pe:
		b._verificar_queda_heroi_sem_turno(u)


static func veste(u, id: String) -> bool:
	return id in u.vestidos


static func escudo(u) -> String:
	return str(u.escudo.get("id", ""))


static func armadura(u) -> String:
	return str(u.armadura.get("id", ""))


static func _ataque_a_distancia(b, atk, dfs) -> bool:
	return atk.a_distancia or b.ctx.get("magico", false) or Grade.distancia(atk.pos, dfs.pos) > 1


## Vanguarda (Amuleto de Grevha): nenhum aliado está mais perto de um inimigo do que você.
static func vanguarda(b, u) -> bool:
	var inimigos: Array = b.oponentes(u)
	if inimigos.is_empty():
		return false
	var minha := 999
	for o in inimigos:
		minha = mini(minha, Grade.distancia(o.pos, u.pos))
	for h in b.herois_ativos():
		if h == u:
			continue
		for o in inimigos:
			if Grade.distancia(o.pos, h.pos) < minha:
				return false
	return true


# --- Dano ---------------------------------------------------------------------

## Bônus de dano do herói vindos dos itens: [[rótulo, valor], ...].
static func bonus_de_dano(b, u, alvo, acerto: bool) -> Array:
	var lista := []
	var magico: bool = b.ctx.get("magico", false)
	if not magico and acerto:
		match arma(u):
			"adaga_da_mao_vazia":
				var n: int = maxi(0, 5 - u.baralho.mao.size())
				if n > 0:
					lista.append(["Adaga da Mão Vazia (mão vazia)", n])
			"arco_de_teixo":
				if alvo.fichas_total("Marcado") > 0:
					lista.append(["Arco de Teixo (alvo marcado)", u.dano])
			"machado_sedento":
				var figuras := 0
				for c in u.baralho.descarte:
					if Carta.posto(c) >= 11:
						figuras += 1
				if figuras > 0:
					lista.append(["Machado Sedento (figuras no descarte)", mini(figuras, 12)])
	if acerto and not magico:
		if u.efeitos.has("sangue_de_batalha") and not u.a_distancia:
			lista.append(["Sangue de Batalha", 3])
		if u.efeitos.has("esferas"):
			lista.append(["Esferas Compactadas", 3])
		if u.efeitos.has("oleo_antiespectral") and alvo.flutua:
			lista.append(["Óleo Antiespectral", 2])
		var amolada: Dictionary = u.efeitos.get("pedra_de_amolar", {})
		if not amolada.is_empty() and u.arma.get("tipo_dano", "") in ["Corte", "Perfuração"]:
			lista.append(["Pedra de Amolar", 1])
		if u.efeitos.has("bainha"):
			u.efeitos.erase("bainha")
			lista.append(["Bainha Impetuosa", 3])
	if acerto:
		if armadura(u) == "couraca_do_contra_ataque" and u.fichas_total("Ferimento") > 0:
			lista.append(["Couraça do Contra-Ataque (Ferimento)", 2 * u.fichas_total("Ferimento")])
		if veste(u, "amuleto_de_vael") and alvo.fichas_total("Fogo") > 0:
			lista.append(["Amuleto de Vael (alvo em chamas)", 2])
		if veste(u, "amuleto_de_grevha") and vanguarda(b, u):
			lista.append(["Amuleto de Grevha (vanguarda)", 1])
		if u.efeitos.has("cantico_de_guerra"):
			lista.append(["Cântico de Guerra", 2])
	return lista


## O ataque do herói ignora a resistência por causa de um item?
static func ignora_resistencia(b, u, _alvo) -> String:
	if b.ctx.get("magico", false):
		return ""
	if arma(u) == "quebra_elmos":
		return "Quebra-Elmos"
	if arma(u) == "estilete" and b.teste_ataque != null and b.teste_ataque.critico():
		return "Estilete (crítico)"
	if u.efeitos.has("kagen"):
		return "Amuleto de Kagen"
	if u.efeitos.has("veneno_acido"):
		return "Veneno Ácido"
	return ""


# --- Limites do 21 --------------------------------------------------------------

## Ajuste no limite do ataque de "atk" contra "dfs" (itens dos dois lados).
static func limite_de_ataque(b, atk, dfs) -> int:
	var d := 0
	if atk.eh_heroi():
		if arma(atk) == "espada_do_mestre_ferreiro" and not b.ctx.get("magico", false):
			d += 1
		if atk.efeitos.has("cantico_de_guerra"):
			d += 1
	if dfs != null and dfs.eh_heroi():
		var dist: bool = _ataque_a_distancia(b, atk, dfs)
		if escudo(dfs) == "placa_de_luz" and dist and dfs.vida_escudo > 0:
			d -= 2
		if veste(dfs, "amuleto_de_kagen") and atk.flutua:
			d -= 2
		if dfs.efeitos.has("forma_de_vento"):
			d -= 3
	d += _alvorada(b, atk)
	return d


static func limite_de_defesa(b, dfs, atk) -> int:
	var d := 0
	if dfs.eh_heroi():
		if atk != null and veste(dfs, "amuleto_de_pacenas") and _ataque_a_distancia(b, atk, dfs) and not b.ctx.get("magico", false):
			d += 1
		d += int(dfs.efeitos.get("manto_vento", {}).get("valor", 0))
	d += _alvorada(b, dfs)
	return d


## Cântico da Alvorada (A Criação da Luz): aliados na área +1, inimigos −1.
static func _alvorada(b, u) -> int:
	for z in b.zonas_em(u.pos):
		if z["tipo"] == "alvorada":
			var dono = b.unidade(z["dono"])
			if dono == null:
				return 0
			return 1 if dono.eh_heroi() == u.eh_heroi() else -1
	return 0


# --- Resistência e proteção -------------------------------------------------------

## Resistência extra (ou a menos) de "u" pelos itens. "atk" = quem ataca agora (pode ser null).
static func resistencia(b, u, atk) -> int:
	var r := 0
	if u.eh_heroi():
		if escudo(u) == "scutum_da_legiao":
			if b.aliados_adjacentes(u, u.pos) > 0:
				r += 2
			else:
				r -= int(u.escudo.get("resistencia", 0)) if u.vida_escudo > 0 else 0
		for h in b.herois_ativos():
			if h != u and escudo(h) == "scutum_da_legiao" and Grade.adjacentes(h.pos, u.pos):
				r += 2
				break
		if escudo(u) == "placa_de_luz" and u.vida_escudo > 0 and atk != null and not _ataque_a_distancia(b, atk, u):
			r -= int(u.escudo.get("resistencia", 0))
		if veste(u, "amuleto_de_grevha") and vanguarda(b, u):
			r += 1
		if u.efeitos.has("oracao_do_guardiao"):
			r += 2
		for z in b.zonas_em(u.pos) + _zonas_vizinhas(b, u):
			if z["tipo"] == "pira" and z["dono"] == u.id:
				r += 2
				break
	else:
		if u.categoria in PROFANOS:
			for h in b.herois_ativos():
				if armadura(h) == "peitoral_de_dalpnor" and Grade.distancia(h.pos, u.pos) <= 4:
					r -= 1
					break
	return r


static func _zonas_vizinhas(b, u) -> Array:
	var lista := []
	for z in b.zonas:
		if z["tipo"] == "pira" and z["celulas"].any(func(p): return Grade.adjacentes(p, u.pos)):
			lista.append(z)
	return lista


## Quanto do dano pode ir para o escudo agora (Placa de Luz só contra distância e magia;
## Scutum sozinho não protege; Florete do Contragolpe: nada vai para armadura e escudo).
static func limite_no_escudo(b, u, atk) -> bool:
	if arma(u) == "florete_do_contragolpe":
		return false
	if escudo(u) == "placa_de_luz" and atk != null and not _ataque_a_distancia(b, atk, u):
		return false
	if escudo(u) == "scutum_da_legiao" and b.aliados_adjacentes(u, u.pos) == 0:
		return false
	return true


static func limite_na_armadura(_b, u) -> bool:
	return arma(u) != "florete_do_contragolpe"


# --- Depois do ataque do herói --------------------------------------------------------

static func depois_do_ataque(b, u, alvo, acerto: bool, dano: int) -> void:
	var magico: bool = b.ctx.get("magico", false)
	if not magico:
		if arma(u) == "lanca_da_muralha":
			u.dar_ficha("Imobilizar")
			b._log("Lança da Muralha: %s firma os pés (1 Imobilizar)." % u.nome)
		if acerto and alvo.viva():
			match arma(u):
				"maca_estrela":
					alvo.dar_ficha("Ferimento")
					b._log("Maça-Estrela: %s recebe 1 Ferimento." % alvo.nome)
				"chicote":
					_puxar(b, alvo, u.pos)
				"alabarda":
					b._empurrar(alvo, u.pos, 1)
				"machado_barbado":
					for o in b.oponentes(u):
						if o != alvo and o.viva() and Grade.adjacentes(o.pos, u.pos):
							b._dano_direto(o, 2, "Machado Barbado (ignora resistência)")
							break
		if acerto and dano > 0:
			match arma(u):
				"machete_farpado":
					if alvo.viva():
						alvo.dar_ficha("Sangramento")
						b._log("Machete Farpado: %s sangra." % alvo.nome)
				"besta_da_seta_dupla":
					for o in b.oponentes(u):
						if o != alvo and o.viva() and Grade.adjacentes(o.pos, alvo.pos):
							b._dano_direto(o, u.dano, "Besta da Seta Dupla")
							break
				"machado_sedento":
					var c: int = u.baralho.puxar_topo()
					if c >= 0:
						u.baralho.exilio.append(c)
						b._log("Machado Sedento: tritura 1 carta de %s." % u.nome)
		if acerto and escudo(u) == "escudo_de_investida" and int(u.efeitos.get("passos_retos", {}).get("n", 0)) >= 2 and not u.a_distancia and alvo.viva():
			b._empurrar(alvo, u.pos, 1)
			b._log("Escudo de Investida: %s é empurrado." % alvo.nome)
		if u.a_distancia and veste(u, "corda_de_arco_da_penumbra") and (b.nivel_de_luz(u.pos) == 1 or u.efeitos.has("gastou_sombra")):
			b.comecar_scry(u)
			b._log("Corda de Arco da Penumbra: %s faz scry 1." % u.nome)
	if b.ctx.get("gastou_foco", false) and arma(u) == "adaga_balanceada" and not magico:
		u.dar_ficha("Foco")
		b._log("Adaga Balanceada: %s recupera 1 Foco." % u.nome)
	if u.efeitos.has("esferas") and not magico:
		u.efeitos["esferas"]["cargas"] = int(u.efeitos["esferas"]["cargas"]) - 1
		if int(u.efeitos["esferas"]["cargas"]) <= 0:
			u.efeitos.erase("esferas")
	if acerto and u.efeitos.has("foco_crescente") and not u.efeitos.has("foco_crescente_turno"):
		u.efeitos["foco_crescente_turno"] = {"ate": "inicio_turno"}
		u.dar_ficha("Foco")
		b._log("Poção de Foco Crescente: %s ganha 1 Foco." % u.nome)
	if acerto and not alvo.viva() and u.efeitos.has("reflexos_predatorios") and not u.efeitos.has("reflexos_turno"):
		u.efeitos["reflexos_turno"] = {"ate": "inicio_turno"}
		u.acoes_reacao += 1
		b._log("Reflexos Predatórios: %s ganha 1 Reação." % u.nome)


static func _puxar(b, alvo, para: Vector2i) -> void:
	var d: Vector2i = para - alvo.pos
	var q: Vector2i = alvo.pos + Vector2i(signi(d.x), signi(d.y))
	if q == para or not b.grade.dentro(q) or b.grade.bloqueado(q) or b.na_posicao(q) != null:
		alvo.efeitos["nao_se_afasta"] = {"ate_turno_de": b.ativa().id}
		b._log("Chicote: %s não pode se afastar até o próximo turno." % alvo.nome)
		return
	alvo.pos = q
	b.eventos.append({"tipo": "mover", "id": alvo.id, "caminho": [q]})
	b._log("Chicote: %s é puxado 1 quadrado." % alvo.nome)


# --- Herói atacado -------------------------------------------------------------------

## Depois que "atk" atacou o herói "dfs" (resultado já calculado).
static func defendeu(b, atk, dfs, acerto: bool, ataque: int, defesa: int, dano: int) -> void:
	if not dfs.eh_heroi() or atk == null:
		return
	var dist: bool = _ataque_a_distancia(b, atk, dfs)
	if not acerto and arma(dfs) == "florete_do_contragolpe" and defesa - ataque >= 5 and atk.viva():
		b._dano_direto(atk, dfs.dano, "Florete do Contragolpe")
	if acerto and dist and veste(dfs, "pergaminho_ancestral"):
		atk.dar_ficha("Penalidade")
		b._log("Pergaminho Ancestral: %s recebe 1 Penalidade." % atk.nome)
	if dano > 0 and armadura(dfs) == "couraca_do_contra_ataque":
		dfs.dar_ficha("Ferimento")
		b._log("Couraça do Contra-Ataque: %s recebe 1 Ferimento (e bate mais forte)." % dfs.nome)
	if dano > 0 and not dist and dfs.efeitos.has("sangue_caustico") and not dfs.efeitos.has("caustico_turno") and atk.viva():
		dfs.efeitos["caustico_turno"] = {"ate_turno_de": atk.id}
		b._dano_direto(atk, 3, "Sangue Cáustico (Ácido)")
	if dano > 0 and dfs.efeitos.has("regeneracao"):
		dfs.efeitos["regeneracao"]["pular"] = true


## Dano posto na armadura (Brunea de Escamas: inimigo ao lado recebe Ferimento).
static func dano_na_armadura(b, u, atk, valor: int) -> void:
	if valor > 0 and armadura(u) == "brunea_de_escamas" and atk != null and not atk.eh_heroi() and atk.viva() and Grade.adjacentes(atk.pos, u.pos):
		atk.dar_ficha("Ferimento")
		b._log("Brunea de Escamas: %s se fere nas escamas (1 Ferimento)." % atk.nome)


# --- Turno -----------------------------------------------------------------------------

static func inicio_do_turno(b, u) -> void:
	u.efeitos.erase("passos_retos")
	if arma(u) == "quebra_elmos":
		u.acoes_reacao = 0   # Quebra-Elmos: "Você não tem Reação."
	if arma(u) == "gladio_inquietante":
		for c in u.cartas:
			if c.tipo == "habilidade" and c.lados.size() > 1:
				b._virar(u, c)
		b._log("Gládio Inquietante: as cartas de %s viram sozinhas." % u.nome)
	if arma(u) == "adaga_da_mao_vazia" and not u.baralho.mao.is_empty():
		var menor: int = b._menor_da_mao(u)
		u.baralho.mao.erase(menor)
		u.baralho.descarte.append(menor)
		b._log("Adaga da Mão Vazia: %s descarta %s." % [u.nome, Carta.nome(menor)])
	if armadura(u) == "peitoral_de_dalpnor":
		var c2: int = u.baralho.puxar_topo()
		if c2 >= 0:
			u.baralho.exilio.append(c2)
			b._log("Peitoral de Dalpnor (Fardo da Luz): 1 carta do baralho de %s vai para o exílio." % u.nome)
			b._verificar_queda_heroi(u)
	if u.efeitos.has("regeneracao"):
		if u.efeitos["regeneracao"].get("pular", false):
			u.efeitos["regeneracao"]["pular"] = false
			b._log("Poção de Regeneração: %s sofreu dano, esta cura não acontece." % u.nome)
		else:
			b._curar(u, 2, "regenera (Poção de Regeneração)")
	if u.efeitos.has("folego_prolongado"):
		if b._tirar_fadiga(u, 1) > 0:
			b._log("Poção de Fôlego Prolongado: −1 de fadiga em %s." % u.nome)
	if u.efeitos.has("francisca"):
		var f: Dictionary = u.efeitos["francisca"]
		u.efeitos.erase("francisca")
		b._equipar(u, f["arma"])
		b._log("A Francisca volta à mão de %s." % u.nome)


static func fim_do_turno(b, u) -> void:
	if armadura(u) == "armadura_samurai_temperada" and not u.moveu_no_turno:
		u.dar_ficha("Guarda")
		b._log("Armadura Samurai: %s não se moveu e ganha 1 Guarda." % u.nome)
	if armadura(u) == "manto_do_vento":
		if u.atacou_nesta_rodada:
			u.efeitos["manto_vento"] = {"valor": -2, "ate": "inicio_turno"}
		elif u.moveu_no_turno:
			u.efeitos["manto_vento"] = {"valor": 2, "ate": "inicio_turno"}
		else:
			u.efeitos.erase("manto_vento")
	if u.efeitos.has("sangue_de_batalha"):
		var ef: Dictionary = u.efeitos["sangue_de_batalha"]
		ef["rodadas"] = int(ef.get("rodadas", 3)) - 1
		if int(ef["rodadas"]) <= 0:
			u.efeitos.erase("sangue_de_batalha")
			var n := 0
			for k in 8:
				var c: int = u.baralho.puxar_topo()
				if c < 0:
					break
				u.baralho.exilio.append(c)
				n += 1
			b._log("O Sangue de Batalha passa: %s exila %d carta(s) do baralho." % [u.nome, n])
			b._verificar_queda_heroi_sem_turno(u)


## Custo de fadiga de uma magia com os itens (nunca abaixo de 1 se já custava algo).
static func custo_de_magia(b, u, custo: int) -> int:
	var c := custo
	var menos := 0
	if arma(u) == "cajado_do_condutor":
		for ca in u.cartas:
			if ca.tipo == "arma" and ca.fadiga >= 3:
				menos += 1
				break
	for o in b.herois():
		var inc: Dictionary = o.efeitos.get("incenso", {})
		if not inc.is_empty() and Grade.distancia(u.pos, inc["pos"]) <= 4:
			menos += 1
			break
	for z in _zonas_vizinhas(b, u) + b.zonas_em(u.pos):
		if z["tipo"] == "pira" and z["dono"] == u.id:
			menos += 1
			break
	if u.efeitos.has("agua_abencoada"):
		c += 1
	if custo > 0:
		c = maxi(c - menos, 1)
	return c


## Fichas que os itens impedem de receber.
static func imune(u, ficha: String) -> bool:
	if ficha in ["Confusão", "Cegueira"] and "elmo_de_touro" in u.vestidos:
		return true
	if ficha in ["Ferimento", "Atordoamento", "Medo"] and u.efeitos.has("sangue_de_batalha"):
		return true
	if ficha == "Veneno" and u.efeitos.has("sangue_limpo"):
		return true
	if ficha == "Medo" and u.efeitos.has("obediencia"):
		return true
	return false


# --- Consumíveis -----------------------------------------------------------------------

## Quem pode receber um consumível "você ou um aliado adjacente".
static func alvos_do_item(b, u, item: String) -> Array:
	if Itens.CONSUMIVEIS.get(item, {}).get("alvo", "") != "aliado":
		return [u]
	return b.herois_ativos().filter(func(h): return h == u or Grade.adjacentes(h.pos, u.pos))


## "" se dá para usar o consumível agora; senão o motivo.
static func motivo_consumivel(b, u, item: String) -> String:
	match item:
		"pocao_de_cura_pequena":
			if not alvos_do_item(b, u, item).any(func(h): return not h.baralho.descarte.is_empty()):
				return "ninguém para curar"
		"runa_de_fogo", "runa_de_terra", "runa_de_ar":
			if not b.oponentes(u).any(func(o): return Grade.adjacentes(o.pos, u.pos)):
				return "nenhum inimigo ao lado"
		"runa_de_luz":
			if not b.oponentes(u).any(func(o): return Grade.distancia(o.pos, u.pos) <= 4 and b.ve_de(u, u.pos, o.pos)):
				return "nenhum inimigo ao alcance curto"
		"pergaminho_do_desencantamento":
			if b.zonas.is_empty():
				return "nenhuma magia contínua"
			if not b.pode_pagar_fadiga(u, u.carta_heroi() if u.carta_heroi() != null else u.cartas[0], 4) and _espaco_total(u) < 4:
				return "precisa de 4 de fadiga livres"
		"flocos_de_sombras":
			if _casa_de_penumbra(b, u) == Vector2i(-99, -99):
				return "nenhuma penumbra ao alcance médio"
	return ""


static func _espaco_total(u) -> int:
	var t := 0
	for c in u.cartas:
		t += maxi(c.espaco(), 0)
	return t


## Efeito dos consumíveis novos da 0.25. Devolve false se não sabe usar o item.
static func usar_consumivel(b, u, item: String, alvo) -> bool:
	if alvo == null:
		alvo = u
	match item:
		"pocao_de_pele_de_pedra":
			for k in 3:
				u.dar_ficha("Guarda")
			b._log("%s bebe a Poção de Pele de Pedra: 3 fichas de Guarda." % u.nome)
		"pocao_carmim":
			u.acoes_padrao += 2
			u.efeitos["carmim"] = {"ate": "inicio_turno"}
			b._dano_direto(u, 5, "Poção Carmim")
			b._log("Poção Carmim: %s ganha 2 ações para atacar." % u.nome)
		"pocao_turquesa":
			u.acoes_mov += 2
			_fadiga_em_cartas(b, u, 5)
			b._log("Poção Turquesa: %s ganha 2 ações de movimento e 5 de fadiga." % u.nome)
		"incenso_de_jasmim":
			u.efeitos["incenso"] = {"pos": u.pos, "ate": "inicio_turno"}
			b._log("%s acende o Incenso de Jasmim: magias a alcance curto custam 1 a menos até o próximo turno." % u.nome)
		"sangue_de_batalha":
			u.efeitos["sangue_de_batalha"] = {"rodadas": 3}
			b._log("%s bebe Sangue de Batalha: +3 no corpo a corpo e imune a Ferimento, Atordoamento e Medo por 3 rodadas." % u.nome)
		"flocos_de_sombras":
			var casa := _casa_de_penumbra(b, u)
			if casa == Vector2i(-99, -99):
				return false
			b.eventos.append({"tipo": "teleporte", "id": u.id, "de": u.pos, "para": casa})
			u.pos = casa
			u.dar_ficha("Sombra")
			u.dar_ficha("Medo", 2)
			b._log("Flocos de Sombras: %s some e reaparece na penumbra (1 Sombra, 2 Medo)." % u.nome)
		"agua_abencoada":
			u.efeitos["agua_abencoada"] = {"turnos": 2}
			b._log("Água Abençoada: as magias divinas de %s curam 3 nos aliados próximos (e custam 1 a mais)." % u.nome)
		"flecha_explosiva":
			u.efeitos["flecha_explosiva"] = {}
			b._log("%s prepara a Flecha Explosiva: o próximo ataque acerta uma área 2×2." % u.nome)
		"pergaminho_do_desencantamento":
			var melhor = null
			for z in b.zonas:
				var dono = b.unidade(z["dono"])
				if melhor == null or (dono != null and not dono.eh_heroi()):
					melhor = z
			if melhor == null:
				return false
			_fadiga_em_cartas(b, u, 4)
			b._remover_zona(melhor, "desencantada")
			b._log("Pergaminho do Desencantamento: %s se desfaz." % melhor.get("nome", "a magia"))
		"runa_de_fogo":
			var o = _inimigo_ao_lado(b, u)
			o.dar_ficha("Fogo")
			b._log("Runa de Fogo: %s pega fogo." % o.nome)
		"runa_de_agua":
			var n: int = alvo.tirar_fichas("Fogo")
			b._log("Runa de Água: %d ficha(s) de Fogo saem de %s." % [n, alvo.nome])
		"runa_de_terra":
			var o2 = _inimigo_ao_lado(b, u)
			o2.dar_ficha("Imobilizar")
			b._log("Runa de Terra: %s fica preso (1 Imobilizar)." % o2.nome)
		"runa_de_ar":
			var o3 = _inimigo_ao_lado(b, u)
			b._empurrar(o3, u.pos, 1)
		"runa_de_luz":
			for o4 in b.oponentes(u):
				if Grade.distancia(o4.pos, u.pos) <= 4 and b.ve_de(u, u.pos, o4.pos):
					o4.dar_ficha("Cegueira")
					b._log("Runa de Luz: %s fica cego." % o4.nome)
					break
		"runa_de_sombra":
			u.dar_ficha("Sombra")
			b._log("Runa de Sombra: %s ganha 1 Sombra." % u.nome)
		"pocao_de_regeneracao":
			u.efeitos["regeneracao"] = {"turnos": 3}
			b._log("%s bebe a Poção de Regeneração: cura 2 no início dos próximos 3 turnos." % u.nome)
		"pocao_de_folego_prolongado":
			u.efeitos["folego_prolongado"] = {"turnos": 3}
			b._log("%s bebe a Poção de Fôlego Prolongado." % u.nome)
		"pocao_de_visao_noturna":
			u.efeitos["visao_noturna"] = {}
			u.visao_no_escuro = true
			b._log("%s bebe a Poção de Visão Noturna: enxerga no escuro como na penumbra." % u.nome)
		"pocao_de_vigor_lunar":
			u.efeitos["vigor_lunar"] = {"vida": 6}
			b._log("Poção de Vigor Lunar: %s tem uma carta com 6 de vida para receber dano (como uma armadura)." % u.nome)
		"pocao_de_sangue_caustico":
			u.efeitos["sangue_caustico"] = {"turnos": 3}
			b._log("%s bebe a Poção de Sangue Cáustico." % u.nome)
		"pocao_de_reflexos_predatorios":
			u.efeitos["reflexos_predatorios"] = {"turnos": 3}
			b._log("%s bebe a Poção de Reflexos Predatórios (defende com as cartas reveladas)." % u.nome)
		"pocao_de_sangue_limpo":
			var v := 0
			for c in u.cartas:
				while c.tirar_ficha("Veneno"):
					v += 1
			u.efeitos["sangue_limpo"] = {"turnos": 3}
			b._log("%s bebe a Poção de Sangue Limpo: %d Veneno removido(s), imune por 3 turnos." % [u.nome, v])
		"pocao_de_mergulho":
			u.efeitos["mergulho"] = {}
			b._log("%s bebe a Poção de Mergulho: respira debaixo d'água." % u.nome)
		"pocao_de_foco_crescente":
			u.efeitos["foco_crescente"] = {"turnos": 3}
			b._log("%s bebe a Poção de Foco Crescente." % u.nome)
		"pocao_de_amplificacao":
			u.efeitos["amplificacao"] = {"cargas": 2}
			b._log("%s bebe a Poção de Amplificação: as próximas 2 magias de dano ou cura somam 2." % u.nome)
		"pocao_de_purificacao":
			var v2 := 0
			for c in u.cartas:
				while c.tirar_ficha("Veneno"):
					v2 += 1
			for ef in ["regeneracao", "folego_prolongado", "visao_noturna", "vigor_lunar", "sangue_caustico", "reflexos_predatorios",
					"sangue_limpo", "mergulho", "foco_crescente", "amplificacao", "carmim", "agua_abencoada"]:
				u.efeitos.erase(ef)
			if u.efeitos.has("sangue_de_batalha"):
				u.efeitos["sangue_de_batalha"]["rodadas"] = 1
				fim_do_turno(b, u)
			b._log("%s bebe a Poção de Purificação: %d Veneno removido(s) e os efeitos de poções acabam." % [u.nome, v2])
		"oleo_antiespectral":
			u.efeitos["oleo_antiespectral"] = {}
			b._log("%s passa Óleo Antiespectral na arma: acerta intangíveis e causa +2 contra eles." % u.nome)
		_:
			return false
	return true


static func _inimigo_ao_lado(b, u):
	for o in b.oponentes(u):
		if Grade.adjacentes(o.pos, u.pos):
			return o
	return null


static func _casa_de_penumbra(b, u) -> Vector2i:
	var melhor := Vector2i(-99, -99)
	var dist := 99
	for x in range(u.pos.x - 8, u.pos.x + 9):
		for y in range(u.pos.y - 8, u.pos.y + 9):
			var p := Vector2i(x, y)
			if not b.grade.dentro(p) or b.grade.bloqueado(p) or b.na_posicao(p) != null:
				continue
			if b.nivel_de_luz(p) != 1:
				continue
			var d := Grade.distancia(p, u.pos)
			if d >= 2 and d < dist:
				dist = d
				melhor = p
	return melhor


## Põe fadiga nas cartas do herói (a que não couber exila cartas do descarte, como transbordo).
static func _fadiga_em_cartas(b, u, qtd: int) -> void:
	var resto := qtd
	while resto > 0:
		var melhor = null
		for c in u.cartas:
			if c.espaco() > 0 and (melhor == null or c.espaco() > melhor.espaco()):
				melhor = c
		if melhor == null:
			break
		melhor.pagar(1)
		resto -= 1
	for k in resto:
		if not u.baralho.descarte.is_empty():
			u.baralho.exilio.append(u.baralho.descarte.pop_back())
	if resto > 0:
		b._log("%s não tem espaço para %d de fadiga: %d carta(s) do descarte vão para o exílio." % [u.nome, resto, resto])


# --- Cartas de item (ativadas) -------------------------------------------------------------

## Registro das cartas de item (como core/efeitos.gd). As de grimório/texto sagrado têm
## uma opção por magia (montadas em cartas_dos_itens).
const LADOS := {
	"anel-do-iniciado": {"uso": "ativada", "alvo": "nenhum", "custo": {"fadiga": 0, "acao": null}},
	"grevas-do-vazio": {"uso": "ativada", "alvo": "area", "custo": {"fadiga": 2, "acao": null}, "area": {"forma": "casa", "alcance": 4}},
	"amuleto-de-pacenas": {"uso": "ativada", "alvo": "area", "custo": {"fadiga": 0, "acao": "padrao"}, "exige_fichas": {"Sombra": 1},
		"area": {"forma": "quadrado", "tamanho": 2, "alcance": 4}},
	"amuleto-de-grevha": {"uso": "ativada", "alvo": "inimigo_investida", "custo": {"fadiga": 2, "acao": "padrao"}},
	"amuleto-de-vael": {"uso": "ativada", "alvo": "nenhum", "custo": {"fadiga": 2, "acao": "padrao"}},
	"amuleto-de-kanil": {"uso": "ativada", "alvo": "aliado", "alcance": 12, "custo": {"fadiga": 2, "acao": "padrao"}},
	"amuleto-de-kagen": {"uso": "ativada", "alvo": "nenhum", "custo": {"fadiga": 2, "acao": "padrao"}},
	"montante-de-batalha": {"uso": "ativada", "alvo": "nenhum", "custo": {"fadiga": 2, "acao": "padrao"}, "arma": "montante_de_batalha"},
	"lanca-trovejante": {"uso": "ativada", "alvo": "inimigo_distancia", "custo": {"fadiga": 2, "acao": "padrao"}, "arma": "lanca_trovejante"},
	"francisca": {"uso": "ativada", "alvo": "inimigo_magico", "alcance": 3, "custo": {"fadiga": 0, "acao": "padrao"}, "arma": "francisca"},
}

## Itens com carta de ativada: id do item -> slug (acessórios, amuletos, botas e armas).
const CARTAS := {
	"anel_do_iniciado": "anel-do-iniciado", "grevas_do_vazio": "grevas-do-vazio", "amuleto_de_pacenas": "amuleto-de-pacenas",
	"amuleto_de_grevha": "amuleto-de-grevha", "amuleto_de_vael": "amuleto-de-vael", "amuleto_de_kanil": "amuleto-de-kanil",
	"amuleto_de_kagen": "amuleto-de-kagen", "montante_de_batalha": "montante-de-batalha", "lanca_trovejante": "lanca-trovejante",
	"francisca": "francisca",
}


## Cartas de item que a ficha leva para a batalha (0.25).
static func cartas_dos_itens(ficha: Dictionary) -> Array:
	var lista := []
	var vestidos: Array = []
	for chave in ["costas", "cabeca", "pes"]:
		if str(ficha.get(chave, "nenhum")) != "nenhum":
			vestidos.append(ficha[chave])
	vestidos.append_array(ficha.get("acessorios", []))
	for id in vestidos + [ficha.get("arma", ""), ficha.get("arma2", "")]:
		if not CARTAS.has(id):
			continue
		var d: Dictionary = Itens.item(id)
		var lim := int(str(d.get("campos", {}).get("Limite de Fadiga", "0")).to_int())
		var lado: Dictionary = LADOS[CARTAS[id]]
		lista.append({"id": "item." + CARTAS[id], "tipo": "item", "lados": [{"nome": d["nome"], "slug": CARTAS[id], "limite_fadiga": lim,
			"custo": lado["custo"], "texto": d.get("texto", ""), "tags": ["Item"]}]})
	for gid in ficha.get("grimorios", []):
		var g: Dictionary = Itens.GRIMORIOS.get(gid, {})
		if g.is_empty():
			continue
		lista.append({"id": "item.livro." + gid, "tipo": "item", "lados": [{"nome": g["nome"], "slug": "livro-" + gid.replace("_", "-"),
			"limite_fadiga": 0, "custo": {}, "texto": g.get("texto", ""),
			"tags": ["Repertório", "Conjuração", "Grimório" if not g.get("sagrado", false) else "Texto Sagrado"]}]})
	return lista


## Registro de um lado de carta de item (ou {} se não for de item).
static func registro(slug: String) -> Dictionary:
	if LADOS.has(slug):
		return LADOS[slug]
	if slug.begins_with("livro-"):
		return registro_do_livro(slug.trim_prefix("livro-").replace("-", "_"))
	return {}


## Livro de repertório: uma opção por magia, com custo e alvo (MAGIAS).
static func registro_do_livro(gid: String) -> Dictionary:
	var g: Dictionary = Itens.GRIMORIOS.get(gid, {})
	var opcoes := []
	for m in g.get("magias", []):
		var s: String = preload("res://core/catalogo.gd").slug(m["nome"])
		var spec: Dictionary = MAGIAS.get(s, {"fora": true})
		var op := {"id": s, "nome": m["nome"], "custo": {"fadiga": int(m["fadiga"]), "acao": m["acao"] if m["acao"] != "reacao" else null},
			"alvo": spec.get("alvo", "nenhum")}
		for k in ["alcance", "area", "ataque_magico", "exige_fichas"]:
			if spec.has(k):
				op[k] = spec[k]
		if spec.get("fora", false):
			op["motivo_fixo"] = "fora de combate (com o mestre)"
		op["nota_magia"] = spec.get("nota", "")
		opcoes.append(op)
	return {"uso": "ativada", "magia": true, "repertorio": true, "livro": gid, "sagrado": g.get("sagrado", false), "opcoes": opcoes}


static func motivo(b, u, c) -> String:
	var info: Dictionary = b._info_lado(c)
	if info.has("arma") and arma(u) != info["arma"]:
		return "precisa estar com %s na mão" % Itens.nome(info["arma"])
	match c.slug():
		"anel-do-iniciado":
			if u.efeitos.has("anel_usado"):
				return "uma vez por turno"
			if u.baralho.descarte.is_empty():
				return "descarte vazio"
			if not u.cartas.any(func(x): return x.fadiga > 0):
				return "nenhuma carta com fadiga"
		"amuleto-de-vael":
			if not b.unidades.any(func(o): return o.viva() and o.fichas_total("Fogo") > 0 and Grade.distancia(o.pos, u.pos) <= 4):
				return "ninguém em chamas ao alcance curto"
		"amuleto-de-kagen":
			if u.efeitos.has("kagen"):
				return "já ativo neste turno"
		"montante-de-batalha":
			if not b.oponentes(u).any(func(o): return Grade.adjacentes(o.pos, u.pos)):
				return "nenhum inimigo ao lado"
	if info.get("livro", "") != "" and int(u.foco.get("maos", 0)) == 0 and info.get("ataque_magico", false):
		return "precisa de um foco para o ataque mágico"
	return ""


static func usar(b, u, c, alvo) -> bool:
	var nome: String = c.nome()
	var info: Dictionary = b._info_lado(c)
	if info.get("livro", "") != "":
		usar_magia(b, u, info, alvo)
		return true
	match c.slug():
		"anel-do-iniciado":
			u.efeitos["anel_usado"] = {"ate": "inicio_turno"}
			u.baralho.exilio.append(u.baralho.descarte.pop_back())
			b._tirar_fadiga(u, 1)
			b._log("Anel do Iniciado: %s exila 1 carta do descarte e tira 1 de fadiga." % u.nome)
		"grevas-do-vazio":
			var p: Vector2i = b.area_atual.get("alvo", u.pos)
			b.eventos.append({"tipo": "teleporte", "id": u.id, "de": u.pos, "para": p})
			u.pos = p
			b._log("Grevas do Vazio: %s some e reaparece." % u.nome)
			for o in b.oponentes(u):
				if Grade.adjacentes(o.pos, p):
					u.efeitos["finta"] = {"ate": "inicio_turno"}
					b._log("Surge ao lado de %s: o próximo ataque tem vantagem." % o.nome)
					break
		"amuleto-de-pacenas":
			u.tirar_fichas("Sombra", 1)
			b._gastou_sombra(u)
			b.criar_zona("nevoa", nome, b.area_atual["celulas"], u, {"rodadas": -1, "cobertura": 1, "vinculada": false})
		"amuleto-de-grevha":
			b._andar_e_atacar(u, b._destino_para(u, alvo, 3), alvo, {"habilidade": "Romper a linha (Amuleto de Grevha)"})
		"amuleto-de-vael":
			for o in b.unidades:
				if o.viva() and o.fichas_total("Fogo") > 0 and Grade.distancia(o.pos, u.pos) <= 4:
					o.tirar_fichas("Fogo")
					if o.eh_heroi():
						b._curar(o, 1, "é aliviado pelo Amuleto de Vael")
					else:
						o.vida = mini(o.vida + 1, o.vida_max)
			b._log("Amuleto de Vael: as chamas ao redor de %s se apagam." % u.nome)
		"amuleto-de-kanil":
			b._curar(alvo, 3, "é curado pelo Amuleto de Kanil")
			for f in ["Sangramento", "Veneno", "Ferimento"]:
				if alvo.tirar_fichas(f, 1) > 0:
					b._log("Amuleto de Kanil: sai 1 %s de %s." % [f, alvo.nome])
					break
		"amuleto-de-kagen":
			u.efeitos["kagen"] = {"ate": "inicio_turno"}
			b._log("Amuleto de Kagen: até o fim do turno, os ataques de %s ignoram armadura." % u.nome)
		"montante-de-batalha":
			var alvos: Array = b.oponentes(u).filter(func(o): return Grade.adjacentes(o.pos, u.pos))
			u.efeitos["defende_revelado"] = {"ate": "inicio_turno"}
			b._ataque_em_area(u, alvos, {"habilidade": nome})
		"lanca-trovejante":
			var alvos2: Array = [alvo]
			for o in b.unidades:
				if o.viva() and o != alvo and o != u and Grade.adjacentes(o.pos, alvo.pos):
					alvos2.append(o)
			u.efeitos["retorno_trovejante"] = {}
			b._ataque_em_area(u, alvos2, {"habilidade": nome, "tipo_dano": "Raio"})
		"francisca":
			var a_mao: Dictionary = u.arma.duplicate(true)
			b._novo_ataque(u, alvo, {"habilidade": "Francisca (arremesso)", "francisca": a_mao})
		_:
			return false
	return true


# --- Magias dos grimórios e textos sagrados ----------------------------------------------------
##
## Atributo (livro do Lucas): Raciocínio nos grimórios do Mago, Espírito nos textos sagrados.
## "Diferença + X" = ataque mágico com dano extra X (o ataque já soma o foco e o atributo).

const MAGIAS := {
	# Grimório do Fogo
	"impulso-ardente": {"alvo": "area", "area": {"forma": "linha", "comprimento": 3}},
	"bola-de-fogo": {"alvo": "area", "ataque_magico": true, "area": {"forma": "quadrado", "tamanho": 3, "alcance": 8}},
	"respiracao-flamejante": {"alvo": "nenhum"},
	# Grimório da Água
	"disparos-salinos": {"alvo": "inimigo_magico", "alcance": 8, "ataque_magico": true},
	"respiracao-aquatica": {"alvo": "nenhum"},
	"bolha": {"alvo": "inimigo_magico", "alcance": 8, "nota": "o afogamento dentro da bolha ainda não"},
	# Grimório da Terra
	"esferas-compactadas": {"alvo": "nenhum"},
	"sentido-sismico": {"alvo": "nenhum"},
	"disco-de-cascalho": {"alvo": "area", "ataque_magico": true, "area": {"forma": "linha", "comprimento": 8}},
	# Grimório do Ar
	"vendaval": {"alvo": "area", "ataque_magico": true, "area": {"forma": "quadrado", "tamanho": 3, "alcance": 4}},
	"passos-de-vento": {"alvo": "nenhum"},
	"forma-de-vento": {"alvo": "nenhum"},
	# Grimório da Luz
	"raio-radiante": {"alvo": "inimigo_magico", "alcance": 8, "ataque_magico": true},
	"aura-luminosa": {"alvo": "nenhum"},
	"bencao-curativa": {"alvo": "area", "area": {"forma": "quadrado", "tamanho": 3, "alcance": 4}},
	# Grimório da Sombra
	"garra-umbral": {"alvo": "inimigo_magico", "alcance": 8, "ataque_magico": true},
	"veu-de-sombras": {"alvo": "nenhum"},
	"manto-do-terror": {"alvo": "area", "area": {"forma": "quadrado", "tamanho": 3, "alcance": 4}},
	# Códice das Cinzas
	"tempestade-de-brasas": {"alvo": "area", "ataque_magico": true, "area": {"forma": "quadrado", "tamanho": 4, "alcance": 8}, "nota": "sustentar a área ainda não"},
	"sopro-do-inferno": {"alvo": "area", "ataque_magico": true, "area": {"forma": "quadrado", "tamanho": 4, "alcance": 8}},
	# Sussurros do Breu
	"vazio-das-trevas": {"alvo": "area", "area": {"forma": "quadrado", "tamanho": 4, "alcance": 8}},
	"voz-da-noite": {"alvo": "inimigo_magico", "alcance": 8},
	# Códice da Chama Negra
	"chama-negra": {"alvo": "inimigo_magico", "alcance": 4, "ataque_magico": true},
	"drenar-calor": {"alvo": "nenhum"},
	# Grimório do Lodo
	"atoleiro": {"alvo": "area", "area": {"forma": "quadrado", "tamanho": 3, "alcance": 8}},
	"onda-de-lama": {"alvo": "area", "ataque_magico": true, "area": {"forma": "adjacente", "largura": 3, "profundidade": 4}},
	# Estudo de Geofótons e Portfólio do Luar Marinho
	"cavar-e-estruturar": {"fora": true},
	"luz-penetrante": {"fora": true},
	"reflexo-liquido": {"fora": true},
	"nevoa-brilhante": {"alvo": "area", "area": {"forma": "quadrado", "tamanho": 4, "alcance": 8}, "nota": "a explosão da nuvem ainda não"},
	# A Batalha dos Anjos
	"cantico-de-guerra": {"alvo": "nenhum"},
	"oracao-da-lamina": {"alvo": "area", "ataque_magico": true, "area": {"forma": "aglomerado", "maximo": 2, "alcance": 8}},
	"oracao-do-guardiao": {"alvo": "aliado", "alcance": 12},
	# A Criação da Luz
	"cantico-da-alvorada": {"alvo": "area", "area": {"forma": "quadrado", "tamanho": 10, "alcance": 8}},
	"oracao-do-fulgor": {"alvo": "inimigo_magico", "alcance": 8},
	"cantico-da-aurora": {"alvo": "nenhum"},
	# Os Ensinamentos Divinos
	"mandamento-da-justica": {"alvo": "inimigo_magico", "alcance": 8, "ataque_magico": true},
	"mandamento-do-ardor": {"alvo": "aliado", "alcance": 1},
	"mandamento-da-obediencia": {"alvo": "nenhum"},
	# As Leis Fundamentais
	"oracao-do-decreto": {"alvo": "inimigo_visivel", "nota": "o alvo recebe 2 Medo e se afasta (a IA ainda não foge de propósito)"},
	"cantico-da-ordem": {"alvo": "area", "area": {"forma": "quadrado", "tamanho": 3, "alcance": 8}, "nota": "quem começa o turno dentro só anda ou só ataca"},
	"oracao-do-julgamento": {"alvo": "inimigo_visivel", "nota": "a marca está feita; o ataque automático quando ele atacar ainda não"},
	# O Fogo Purificador
	"oracao-da-chama": {"alvo": "inimigo_magico", "alcance": 8, "ataque_magico": true},
	"mao-ardente-de-deus": {"alvo": "qualquer_adjacente"},
	"louvar-da-pira": {"alvo": "area", "area": {"forma": "quadrado", "tamanho": 2, "alcance": 4}},
}


## Atributo de conjuração dos livros: Espírito nos textos sagrados, Raciocínio nos grimórios.
static func atributo_do_livro(u, sagrado: bool) -> int:
	return u.espirito if sagrado else u.raciocinio


static func usar_magia(b, u, info: Dictionary, alvo) -> void:
	var s: String = info["opcao"]
	var nome: String = info.get("nome", s)
	var sagrado: bool = info.get("sagrado", false)
	var at := atributo_do_livro(u, sagrado)
	var ctx_base := {"habilidade": nome, "magico": true, "atributo_magia": at,
		"rotulo_atributo": "Espírito" if sagrado else "Raciocínio"}
	var cels: Array = b.area_atual.get("celulas", [])
	if sagrado and u.efeitos.has("agua_abencoada"):
		for h in b.herois_ativos():
			if Grade.distancia(h.pos, u.pos) <= 4:
				b._curar(h, 3, "é banhado pela Água Abençoada")
	match s:
		"impulso-ardente":
			var fim: Vector2i = u.pos
			for p in cels:
				if b.grade.bloqueado(p) or b.na_posicao(p) != null:
					break
				fim = p
			var caminho := cels.filter(func(p): return Grade.distancia(u.pos, p) <= Grade.distancia(u.pos, fim))
			for o in b.unidades:
				if o.viva() and o != u and caminho.any(func(p): return Grade.adjacentes(p, o.pos)):
					o.dar_ficha("Fogo")
					b._log("Impulso Ardente: %s pega fogo." % o.nome)
			if fim != u.pos:
				b.eventos.append({"tipo": "mover", "id": u.id, "caminho": caminho})
				u.pos = fim
		"bola-de-fogo":
			b._ataque_em_area(u, b.unidades_em(cels), ctx_base.merged({"bonus_dano": 4, "rotulo_bonus": nome, "tipo_dano": "Fogo",
				"ao_falhar_defesa": {"fichas": {"Fogo": 2}}}))
		"respiracao-flamejante":
			u.efeitos["resiste_gelo"] = {}
			b._log("%s: resistência 2 contra Gelo até o fim da cena." % nome)
		"disparos-salinos":
			var extra := 1 + (4 if int(alvo.resistencia) > 0 else 0)
			b._novo_ataque(u, alvo, ctx_base.merged({"bonus_dano": extra, "rotulo_bonus": nome + (" (alvo de armadura)" if extra > 1 else ""), "tipo_dano": "Concussão"}))
		"respiracao-aquatica":
			u.efeitos["nado"] = {}
			b._log("%s: %s respira debaixo d'água." % [nome, u.nome])
		"bolha":
			if _vence(b, u, at, alvo, "destreza"):
				alvo.dar_ficha("Imobilizar", 2)
				b._log("Bolha: %s fica preso numa esfera de água (2 Imobilizar)." % alvo.nome)
		"esferas-compactadas":
			u.efeitos["esferas"] = {"cargas": 4}
			b._log("Esferas Compactadas: os próximos 4 ataques de %s causam +3 de Concussão." % u.nome)
		"sentido-sismico":
			u.visao_no_escuro = true
			b._log("Sentido Sísmico: %s percebe o chão ao redor (enxerga no escuro como penumbra)." % u.nome)
		"disco-de-cascalho":
			b._ataque_em_area(u, b.unidades_em(cels), ctx_base.merged({"bonus_dano": 3, "rotulo_bonus": nome, "tipo_dano": "Concussão",
				"ao_dano_inimigo": {"derrubar": true, "rotulo": nome}}))
		"vendaval":
			b._ataque_em_area(u, b.unidades_em(cels, u), ctx_base.merged({"tipo_dano": "Concussão",
				"ao_dano_inimigo": {"empurrar": 3, "rotulo": nome}}))
		"passos-de-vento":
			u.efeitos["passo_leve"] = {}
			u.efeitos["desengajar_cena"] = {}
			b._log("Passos de Vento: %s ignora terreno difícil e não provoca ataques de oportunidade." % u.nome)
		"forma-de-vento":
			u.efeitos["forma_de_vento"] = {"ate": "inicio_turno"}
			u.ignora_impedimento = true
			b._log("Forma de Vento: %s vira vento até o próximo turno (−3 no limite de quem o ataca; não ataca)." % u.nome)
		"raio-radiante":
			var extra2 := 2 + (4 if alvo.categoria in PROFANOS else 0)
			b._novo_ataque(u, alvo, ctx_base.merged({"bonus_dano": extra2, "rotulo_bonus": nome, "tipo_dano": "Radiante"}))
		"aura-luminosa":
			u.luz = "aura"
			b._log("Aura Luminosa: %s brilha até o alcance médio." % u.nome)
			for o in b.oponentes(u):
				if Grade.distancia(o.pos, u.pos) <= 4:
					o.tirar_fichas("Sombra")
					o.efeitos.erase("oculto")
		"bencao-curativa":
			var cura := maxi(int(at / 2), 2)
			for h in b.herois_ativos():
				if h.pos in cels or h == u:
					b._curar(h, cura + _amplificar(b, u), "recebe a Bênção Curativa")
					h.tirar_fichas("Medo", 1)
		"garra-umbral":
			var oculto: bool = u.efeitos.has("oculto") or b.nivel_de_luz(u.pos) <= 1
			b._novo_ataque(u, alvo, ctx_base.merged({"bonus_dano": 2 + (4 if oculto else 0), "rotulo_bonus": nome + (" (das sombras)" if oculto else "")}))
		"veu-de-sombras":
			u.efeitos["veu_de_sombras"] = {}
			if b.nivel_de_luz(u.pos) <= 1:
				u.efeitos["oculto"] = {}
			b._log("Véu de Sombras: na penumbra e no escuro, %s fica oculto até atacar." % u.nome)
		"manto-do-terror":
			var afetados := 0
			for o in b.unidades_em(cels, u):
				if _vence(b, u, at, o, "espirito"):
					o.dar_ficha("Medo")
					o.dar_ficha("Cegueira")
					afetados += 1
			var tirada: int = b._tirar_fadiga(u, afetados)
			b._log("Manto do Terror: %d inimigo(s) com Medo e Cegueira; %s tira %d de fadiga." % [afetados, u.nome, tirada])
		"tempestade-de-brasas":
			b._ataque_em_area(u, b.unidades_em(cels), ctx_base.merged({"tipo_dano": "Fogo", "ao_dano_inimigo": {"fichas": {"Fogo": 2}, "rotulo": nome}}))
		"sopro-do-inferno":
			b._ataque_em_area(u, b.unidades_em(cels), ctx_base.merged({"tipo_dano": "Fogo",
				"ao_dano_inimigo": {"fichas": {"Fogo": 1}, "empurrar": 3, "dano_batida": at, "rotulo": nome}}))
		"vazio-das-trevas":
			for o in b.unidades_em(cels):
				if o == u:
					continue
				b._dano_direto(o, at, "Vazio das Trevas (Sufocante)")
				if o.viva():
					o.dar_ficha("Medo")
					o.dar_ficha("Cegueira")
		"voz-da-noite":
			alvo.dar_ficha("Medo")
			b._dano_direto(alvo, at * alvo.fichas_total("Medo"), "Voz da Noite")
		"chama-negra":
			b._dano_direto(u, 5, "Chama Negra (custo de vida)")
			b._novo_ataque(u, alvo, ctx_base.merged({"tipo_dano": "Fogo", "chama_negra": true}))
		"drenar-calor":
			var n := 0
			for o in b.unidades:
				if o.viva() and Grade.distancia(o.pos, u.pos) <= 4:
					n += o.tirar_fichas("Fogo")
			if n > 0:
				b._curar(u, 2 * n, "drena o calor")
			b._log("Drenar Calor: %d ficha(s) de Fogo apagadas." % n)
		"atoleiro":
			b.criar_zona("piche", nome, cels, u, {"rodadas": -1, "terreno_dificil": true, "vinculada": false})
		"onda-de-lama":
			b._ataque_em_area(u, b.unidades_em(cels), ctx_base.merged({"tipo_dano": "Concussão",
				"ao_dano_inimigo": {"empurrar": 2, "derrubar": true, "rotulo": nome}}))
		"nevoa-brilhante":
			b.criar_zona("nevoa", nome, cels, u, {"rodadas": -1, "cobertura": 1})
			for o in b.unidades_em(cels):
				if o != u:
					o.dar_ficha("Cegueira")
			b._log("Névoa Brilhante: quem está dentro fica cego.")
		"cantico-de-guerra":
			for h in b.herois_ativos():
				if Grade.distancia(h.pos, u.pos) <= 4:
					h.efeitos["cantico_de_guerra"] = {"ate_turno_de": u.id, "turnos": 2}
			b._log("Cântico de Guerra: +2 de dano e +1 no limite dos ataques para %s e aliados próximos." % u.nome)
		"oracao-da-lamina":
			b._ataque_em_area(u, b.unidades_em(cels, u), ctx_base.merged({"tipo_dano": "Radiante", "dobra_contra_mais3": true,
				"bonus_extra_contra": {"categorias": PROFANOS, "valor": 3}}))
		"oracao-do-guardiao":
			alvo.efeitos["oracao_do_guardiao"] = {"ate_turno_de": u.id}
			b._log("Oração do Guardião: %s tem resistência 2 e não cai até o próximo turno de %s." % [alvo.nome, u.nome])
		"cantico-da-alvorada":
			b.criar_zona("alvorada", nome, cels, u, {"rodadas": 1, "sustentar": 1})
			for o in b.unidades_em(cels):
				o.tirar_fichas("Sombra")
		"oracao-do-fulgor":
			b._dano_direto(alvo, at + _amplificar(b, u), "Oração do Fulgor (Radiante)")
			if alvo.viva():
				alvo.dar_ficha("Cegueira")
		"cantico-da-aurora":
			for h in b.herois_ativos():
				if h != u and Grade.adjacentes(h.pos, u.pos):
					b._curar(h, at + _amplificar(b, u), "recebe o Cântico da Aurora")
		"mandamento-da-justica":
			var feriu: bool = alvo.efeitos.has("feriu_heroi")
			b._novo_ataque(u, alvo, ctx_base.merged({"tipo_dano": "Radiante", "bonus_dano": at if feriu else 0,
				"rotulo_bonus": "Mandamento da Justiça (feriu alguém: 2 × Espírito)"}))
		"mandamento-do-ardor":
			var n2 := 0
			for f in ["Veneno", "Sangramento", "Ferimento"]:
				n2 += alvo.tirar_fichas(f)
			for o in b.oponentes(u):
				if n2 > 0 and Grade.distancia(o.pos, u.pos) <= 4:
					b._dano_direto(o, n2, "Mandamento do Ardor (Radiante)")
			b._log("Mandamento do Ardor: %d ficha(s) removida(s) de %s." % [n2, alvo.nome])
		"mandamento-da-obediencia":
			u.efeitos["obediencia"] = {"ate": "inicio_turno"}
			b._log("Mandamento da Obediência: %s fica imune a Medo até o próximo turno." % u.nome)
		"oracao-do-decreto":
			if _vence(b, u, at, alvo, "espirito"):
				alvo.dar_ficha("Medo", 2)
				b._empurrar(alvo, u.pos, 2)
				b._log("Oração do Decreto: %s recua diante de %s." % [alvo.nome, u.nome])
		"cantico-da-ordem":
			b.criar_zona("ordem", nome, cels, u, {"rodadas": -1})
		"oracao-do-julgamento":
			alvo.dar_ficha("Marcado")
			b._log("Oração do Julgamento: %s está marcado." % alvo.nome)
		"oracao-da-chama":
			b._novo_ataque(u, alvo, ctx_base.merged({"tipo_dano": "Fogo", "ao_acertar_heroi": [{"ficha": "Fogo"}], "dobra_contra": PROFANOS}))
		"mao-ardente-de-deus":
			if alvo.eh_heroi():
				b._curar(alvo, at + _amplificar(b, u), "é tocado pela Mão Ardente de Deus")
			else:
				b._dano_direto(alvo, at + _amplificar(b, u), "Mão Ardente de Deus (Fogo)")
				if alvo.viva():
					alvo.dar_ficha("Ferimento")
		"louvar-da-pira":
			b.criar_zona("pira", nome, cels, u, {"rodadas": -1, "dano_entrar": 2 * at})


## Teste contestado: atributo do herói (cartas, automático) contra o atributo do alvo.
static func _vence(b, u, valor: int, alvo, atributo: String) -> bool:
	var meu: int = b._teste_automatico(u, valor)
	var dele: int = b.valor_resistido(alvo, atributo)
	b.eventos.append({"tipo": "flutuar", "id": alvo.id, "texto": "%d × %d" % [meu, dele], "cor": "c9c4b8" if meu > dele else "ff9d5c"})
	return meu > dele


## Poção de Amplificação: +2 numa magia de dano ou cura (2 vezes).
static func _amplificar(_b, u) -> int:
	var ef: Dictionary = u.efeitos.get("amplificacao", {})
	if ef.is_empty():
		return 0
	ef["cargas"] = int(ef["cargas"]) - 1
	if int(ef["cargas"]) <= 0:
		u.efeitos.erase("amplificacao")
	return 2
