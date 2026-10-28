## 0.22: reações dos monstros (estilo Descent), planos e mudança de estratégia,
## limpeza de fichas com o movimento, Correr, Saltar e manobras de luta.
extends RefCounted

const Batalha := preload("res://core/batalha.gd")
const Grade := preload("res://core/grade.gd")
const TC := preload("res://tests/test_classes.gd")
const Dados := preload("res://core/dados_batalha.gd")
const Reacoes := preload("res://core/reacoes_monstros.gd")


func _b() -> Batalha:
	return TC.new()._grupo_com("Guerreiro", "", "classe.guerreiro.heroi.foco-mortal")


func _reacao(nome: String, i := 0) -> Dictionary:
	return Reacoes.POR_NOME[nome][i].duplicate(true)


func test_tabela_pelo_nome(t) -> void:
	var cfg := Dados.inimigo_de("toupeira", "Toupeira Atroz", "toupeira", Vector2i(1, 1), "elite", "neutro", 4)
	t.igual(cfg["reacoes"].size(), 1, "a Toupeira ganha a Fúria da toca")
	var g := Dados.inimigo_de("g", "Goblin Desordeiro", "goblin", Vector2i(1, 1), "lacaio", "aggro", 4, Dados.FUGA_COVARDE)
	t.igual(g["reacoes"][0]["efeito"], "mover", "quem já tem reação fica com a sua")


func test_investir_e_ferimento(t) -> void:
	var b := _b()
	var h := b.unidade("heroi")
	var o := b.unidade("goblin2")
	o.reacoes = [_reacao("Toupeira Atroz")]
	o.alerta = true
	o.pos = h.pos + Vector2i(3, 0)
	b._reacao_do_inimigo(o, h)
	t.ok(Grade.adjacentes(o.pos, h.pos), "avançou até o atacante")
	t.igual(h.fichas_total("Ferimento"), 1, "e deu 1 Ferimento")
	var antes := o.pos
	o.pos = h.pos + Vector2i(3, 0)
	b._reacao_do_inimigo(o, h)
	t.igual(o.pos, h.pos + Vector2i(3, 0), "uma vez por rodada")
	o.novo_turno()
	b._reacao_do_inimigo(o, h)
	t.ok(o.pos != h.pos + Vector2i(3, 0), "no turno seguinte, de novo")
	t.ok(antes != Vector2i.ZERO, "")


func test_inspirar_da_dano_a_um_aliado(t) -> void:
	var b := _b()
	var h := b.unidade("heroi")
	var o := b.unidade("goblin1")
	o.reacoes = [_reacao("Bruxa Morgana")]
	for x in b.inimigos_vivos():
		x.alerta = true
	b._reacao_do_inimigo(o, h)
	var inspirados := b.inimigos_vivos().filter(func(x): return x.efeitos.has("inspirado"))
	t.igual(inspirados.size(), 1, "um aliado aleatório")
	var a: Object = inspirados[0]
	var lista := b._bonus_de_dano(a, h, true)
	t.ok(lista.any(func(l): return l[1] == 1), "+1 de dano no próximo ataque")
	t.ok(not a.efeitos.has("inspirado"), "gasto")


func test_remontar(t) -> void:
	var b := _b()
	var o := b.unidade("goblin2")
	o.reacoes = [_reacao("Guarda de Ossos")]
	b.atacante = b.unidade("heroi")   # espada: Corte
	b.ctx = {}
	b._aplicar_dano_inimigo(o, 999)
	t.ok(not o.viva(), "caiu")
	t.ok(o.efeitos.has("remontando"), "vai se levantar")
	b._remontar_mortos()
	t.ok(o.viva(), "levantou")
	t.igual(o.vida, maxi(int(o.vida_max / 2), 1), "com metade da vida")
	b._aplicar_dano_inimigo(o, 999)
	t.ok(not o.efeitos.has("remontando"), "só uma vez")


func test_remontar_impedido_por_concussao(t) -> void:
	var b := _b()
	var o := b.unidade("goblin2")
	o.reacoes = [_reacao("Guarda de Ossos")]
	b.atacante = b.unidade("heroi")
	b.ctx = {"tipos_extra": ["Concussão"], "magico": true, "tipo_dano": "Concussão"}
	var tipos: Array = b.tipos_de_dano(b.atacante, b.ctx)
	b._aplicar_dano_inimigo(o, 999)
	t.igual(o.efeitos.has("remontando"), not "Concussão" in tipos, "Concussão quebra os ossos de vez")


func test_estilhacar_machuca_quem_esta_ao_lado(t) -> void:
	var b := _b()
	var h := b.unidade("heroi")
	var o := b.unidade("goblin1")
	o.reacoes = [_reacao("Esqueleto")]
	var antes := h.baralho.baralho.size()
	b._aplicar_dano_inimigo(o, 999)
	t.igual(h.baralho.baralho.size(), antes - 1, "1 de dano no herói ao lado")


func test_plano_e_intencoes(t) -> void:
	var b := _b()
	for x in b.inimigos_vivos():
		x.alerta = true
	var g := b.unidade("goblin1")
	var p := b.plano_do_inimigo(g)
	t.igual(p["id"], "atacar", "ao lado de um herói: vai atacar")
	b._anunciar_intencoes()
	t.ok(b.eventos.any(func(e): return e["tipo"] == "intencoes"), "anuncia as intenções")
	t.ok(g.intencao != "", "guarda o texto na unidade")


func test_mudanca_de_estrategia(t) -> void:
	var b := _b()
	var g := b.unidade("goblin1")
	g.alerta = true
	g.perfil = "Covarde"
	b._atualizar_plano(g)
	t.igual(g.estrategia, "atacar", "começa atacando")
	b.unidade("goblin2").vida = 0
	b.unidade("goblin3").vida = 0
	b.eventos.clear()
	b._atualizar_plano(g)
	t.igual(g.estrategia, "fugir", "sozinho, foge")
	t.ok(b.eventos.any(func(e): return e["tipo"] == "estrategia"), "avisa a mudança")


func test_limpa_ficha_com_o_movimento(t) -> void:
	var b := _b()
	var g := b.unidade("goblin1")
	var h := b.unidade("heroi")
	g.alerta = true
	g.dar_ficha("Penalidade")
	g.novo_turno()
	t.ok(b._ia_limpar_com_movimento(g, h), "já está ao lado: usa o movimento")
	t.igual(g.fichas_total("Penalidade"), 0, "a ficha saiu")
	t.igual(g.acoes_padrao, g.padrao_por_turno, "a ação Padrão continua para atacar")


func test_correr(t) -> void:
	var b := _b()
	var u := b.unidade("heroi")
	t.igual(b.motivo_sem_correr(u, 3), "", "turno cheio: pode correr")
	t.ok(b.heroi_correr(), "corre")
	t.igual(u.acoes_mov + u.acoes_padrao, 0, "gasta as 3 ações de movimento")
	t.igual(b.fase, Batalha.Fase.INTERACAO_TESTE, "teste de Atletismo")
	b.interacao_atual = {"alvo": ""}
	b._efeito_correr(u, {"quadrados": 6}, false)
	t.igual(u.deslocamento, 6, "anda o resultado")
	t.ok(u.ignora_impedimento, "ignora impedimento")
	t.ok(b.alcance_movimento(u)["mapa"].keys().any(func(p): return Grade.distancia(p, u.pos) >= 4), "sai do cerco correndo")
	b.fase = Batalha.Fase.IA_TURNO
	b._novo_ataque(b.unidade("goblin1"), u, {})
	t.ok(b.teste_ataque.vantagem, "inimigos têm vantagem contra quem correu")


func test_saltar_cai(t) -> void:
	var b := _b()
	var u := b.unidade("heroi")
	t.ok(b.heroi_saltar(), "salta")
	t.igual(u.acoes_mov + u.acoes_padrao, 1, "gasta 2 ações de movimento")
	b._efeito_correr(u, {"quadrados": 1, "cai": true}, true)
	b.fase = Batalha.Fase.HEROI_ESCOLHE
	var destino: Vector2i = b.alcance_movimento(u)["mapa"].keys()[0]
	b._mover(u, destino)
	t.ok(u.efeitos.has("caido"), "avança 1 e cai")


func test_manobras(t) -> void:
	var b := _b()
	var u := b.unidade("heroi")
	var g := b.unidade("goblin1")
	t.igual(b.motivo_sem_manobra(u, g, "derrubar"), "", "inimigo ao lado")
	t.ok(b.motivo_sem_manobra(u, b.unidade("goblin3"), "derrubar") != "", "longe não dá")
	t.ok(b.heroi_manobra("derrubar", g), "tenta derrubar")
	t.igual(b.fase, Batalha.Fase.INTERACAO_TESTE, "Luta contra Força")
	var dif := int(b.opcao_atual()["dificuldade"])
	b._efeito_manobra(u, {"manobra": "empurrar", "dif": dif}, dif + 10)
	t.igual(Grade.distancia(u.pos, g.pos), 4, "venceu por 10: empurra 3")
	g.pos = u.pos + Vector2i(1, 0)
	b._efeito_manobra(u, {"manobra": "agarrar", "dif": 10}, 12)
	t.igual(b.passos_por_acao(g), 0, "agarrado não anda")
	u.pos += Vector2i(-3, 0)
	t.ok(b.passos_por_acao(g) > 0, "quem agarrou se afastou: solto")


func test_tutorial_passo_a_passo(t) -> void:
	var Tut := preload("res://core/dados_tutorial.gd")
	var b := Batalha.new(Tut.missao(TC.new()._ficha("Guerreiro", "T", [], ["classe.guerreiro.heroi.foco-mortal"])), 3)
	b.iniciar()
	b.indice_vez = b.ordem.find("heroi")
	b._comecar_turno()
	t.igual(b.tutorial_etapa, 0, "começa na boas-vindas")
	t.ok(b.tutorial_proximo(), "Próximo")
	t.igual(b.etapa_tutorial()["titulo"], "1. Andar", "etapa de andar")
	var h := b.unidade("heroi")
	h.pos = b.unidade("boneco").pos + Vector2i(-1, 0)
	b.avancar_tutorial()
	t.igual(b.etapa_tutorial()["titulo"], "2. Atacar e o teste de 21", "ao lado do boneco: atacar")
	for f in ["atacou", "carta", "acao", "encerrou", "subiu", "saltou"]:
		b._tut(f)
	b.avancar_tutorial()
	t.igual(b.etapa_tutorial()["titulo"], "8. Manobras de luta", "pula o que já foi feito")
	t.ok(b.unidade("goblin_treino1").alerta == false, "goblins presos no curral")
	b._tut("manobra")
	b.avancar_tutorial()
	t.igual(b.etapa_tutorial()["titulo"], "9. Luta de verdade", "luta final")
	t.ok(b.unidade("goblin_treino1").alerta, "o sargento solta os goblins")
	t.ok(not b.grade.obstaculos.has(Vector2i(13, 6)), "portão aberto")
	t.ok(b.inerte(b.unidade("boneco")), "o boneco não age")
	b.unidade("goblin_treino1").vida = 0
	b.unidade("goblin_treino2").vida = 0
	t.ok(b._verificar_fim(), "derrotar os dois termina o treino")
	t.igual(b.fase, Batalha.Fase.VITORIA, "vitória")
