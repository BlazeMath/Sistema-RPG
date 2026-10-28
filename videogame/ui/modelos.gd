## Modelos 3D animados (0.18): KayKit, de Kay Lousberg (CC0). Ver assets/modelos/CREDITOS.txt.
## Cada tipo de unidade aponta para um modelo, as armas que ficam visíveis, uma cor
## (multiplica a textura) e a escala. Sem modelo, a tela usa as peças simples de antes.
extends RefCounted

const PASTA := "res://assets/modelos/personagens/"
const ARMAS := "res://assets/modelos/armas/"
const ALTURA_PADRAO := 1.25   # altura de um herói em casas

## Tudo o que é arma ou acessório nos modelos (fica escondido se não estiver em "manter").
const ACESSORIOS := ["1H_Sword_Offhand", "Badge_Shield", "Rectangle_Shield", "Round_Shield", "Spike_Shield",
	"1H_Sword", "2H_Sword", "Knife_Offhand", "1H_Crossbow", "2H_Crossbow", "Knife", "Throwable",
	"Spellbook", "Spellbook_open", "1H_Wand", "2H_Staff", "1H_Axe_Offhand", "Barbarian_Round_Shield",
	"1H_Axe", "2H_Axe", "Mug"]

const TIPOS := {
	"guerreiro": {"arq": "Knight", "manter": ["1H_Sword", "Round_Shield"], "ataque": "1H_Melee_Attack_Chop"},
	"clerigo": {"arq": "Knight", "manter": ["1H_Sword", "Badge_Shield"], "esconder": ["Knight_Helmet"],
		"cor": Color(1.0, 0.95, 0.8), "ataque": "1H_Melee_Attack_Slice_Diagonal", "magia": "Spellcast_Raise"},
	"ladino": {"arq": "Rogue_Hooded", "manter": ["Knife", "Knife_Offhand"], "ataque": "Dualwield_Melee_Attack_Stab"},
	"cacador": {"arq": "Rogue", "manter": ["2H_Crossbow", "Knife"], "ataque": "2H_Ranged_Shoot"},
	"mago": {"arq": "Mage", "manter": ["2H_Staff"], "ataque": "Spellcast_Shoot"},
	"goblin": {"arq": "Barbarian", "manter": ["1H_Axe"], "esconder": ["Barbarian_Hat"],
		"cor": Color(0.62, 0.9, 0.45), "escala": 0.78, "ataque": "1H_Melee_Attack_Chop"},
	"goblin_atirador": {"arq": "Rogue", "manter": ["1H_Crossbow"], "cor": Color(0.62, 0.9, 0.45),
		"escala": 0.78, "ataque": "1H_Ranged_Shoot"},
	"goblin_chefe": {"arq": "Barbarian", "manter": ["2H_Axe"], "cor": Color(0.55, 0.82, 0.4),
		"escala": 1.0, "ataque": "2H_Melee_Attack_Chop"},
	"esqueleto": {"arq": "Skeleton_Minion", "arma_d": "Skeleton_Blade", "ataque": "1H_Melee_Attack_Chop"},
	"esqueleto_arqueiro": {"arq": "Skeleton_Rogue", "arma_d": "Skeleton_Crossbow", "ataque": "1H_Ranged_Shoot"},
	"cavaleiro_ossudo": {"arq": "Skeleton_Warrior", "arma_d": "Skeleton_Axe", "arma_e": "Skeleton_Shield_Small_A",
		"escala": 1.25, "ataque": "1H_Melee_Attack_Chop"},
	"afogado": {"arq": "Skeleton_Minion", "cor": Color(0.5, 0.78, 0.66), "ataque": "Unarmed_Melee_Attack_Punch_A"},
	"fantasma": {"arq": "Skeleton_Mage", "cor": Color(0.7, 0.85, 1.0, 0.55), "ataque": "Spellcast_Shoot", "flutua": true},
	"boneco": {"arq": "Skeleton_Minion", "cor": Color(0.95, 0.8, 0.45), "ataque": "Unarmed_Melee_Attack_Punch_A"},
	"bruxa": {"arq": "Mage", "manter": ["1H_Wand", "Spellbook_open"], "cor": Color(0.72, 0.6, 0.85),
		"ataque": "Spellcast_Shoot"},
}

static var _cenas := {}
static var _armas := {}


static func tem_modelo(tipo: String) -> bool:
	return TIPOS.has(tipo) and ResourceLoader.exists(PASTA + TIPOS[tipo]["arq"] + ".glb")


## Cria o modelo do tipo (ou null). O nó guarda metas: "ap" (AnimationPlayer), "cfg", "altura".
static func criar(tipo: String) -> Node3D:
	if not tem_modelo(tipo):
		return null
	var cfg: Dictionary = TIPOS[tipo]
	var arq: String = cfg["arq"]
	if not _cenas.has(arq):
		_cenas[arq] = load(PASTA + arq + ".glb")
	var inst: Node3D = _cenas[arq].instantiate()
	var raiz := Node3D.new()
	raiz.add_child(inst)
	var manter: Array = cfg.get("manter", [])
	var esconder: Array = cfg.get("esconder", [])
	var cor: Color = cfg.get("cor", Color.WHITE)
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		var nome: String = mi.name
		if (nome in ACESSORIOS and not nome in manter) or nome in esconder:
			mi.visible = false
			continue
		if cor != Color.WHITE:
			_tingir(mi, cor)
	var esq: Skeleton3D = inst.find_children("*", "Skeleton3D", true, false).front() if not inst.find_children("*", "Skeleton3D", true, false).is_empty() else null
	if esq != null:
		for lado in [["arma_d", "handslot.r"], ["arma_e", "handslot.l"]]:
			if cfg.has(lado[0]):
				var ba := BoneAttachment3D.new()
				ba.bone_name = lado[1]
				esq.add_child(ba)
				var arma := _arma(cfg[lado[0]])
				if arma != null:
					ba.add_child(arma)
	# Escala: a altura do modelo vira ALTURA_PADRAO casas (vezes a escala do tipo).
	var k := float(cfg.get("escala", 1.0))
	var alt := _altura_do_modelo(inst)
	var s := (ALTURA_PADRAO / alt) * k if alt > 0.01 else 0.5 * k
	inst.scale = Vector3.ONE * s
	if cfg.get("flutua", false):
		inst.position.y = 0.2
	raiz.set_meta("altura", ALTURA_PADRAO * k)
	raiz.set_meta("cfg", cfg)
	var aps := inst.find_children("*", "AnimationPlayer", true, false)
	if not aps.is_empty():
		var ap: AnimationPlayer = aps[0]
		for laco in ["Idle", "Walking_A", "2H_Melee_Idle", "Death_A_Pose", "Lie_Idle"]:
			if ap.has_animation(laco):
				ap.get_animation(laco).loop_mode = Animation.LOOP_LINEAR
		raiz.set_meta("ap", ap)
		tocar(raiz, "Idle", false)
		# Desencontra o "respirar" de quem está parado lado a lado.
		ap.seek(randf() * 1.5, true)
	return raiz


static func _arma(nome: String) -> Node3D:
	if not _armas.has(nome):
		_armas[nome] = load(ARMAS + nome + ".gltf") if ResourceLoader.exists(ARMAS + nome + ".gltf") else null
	return _armas[nome].instantiate() if _armas[nome] != null else null


static func _tingir(mi: MeshInstance3D, cor: Color) -> void:
	if mi.mesh == null:
		return
	for i in mi.mesh.get_surface_count():
		var m = mi.get_active_material(i)
		if m is StandardMaterial3D:
			var n: StandardMaterial3D = m.duplicate()
			n.albedo_color = cor
			if cor.a < 1.0:
				n.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				n.emission_enabled = true
				n.emission = Color(cor.r, cor.g, cor.b) * 0.35
			mi.set_surface_override_material(i, n)


static func _altura_do_modelo(inst: Node3D) -> float:
	var topo := 0.0
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		if not mi.visible or mi.mesh == null:
			continue
		var a: AABB = mi.mesh.get_aabb()
		topo = maxf(topo, a.end.y)
	return topo


## Toca uma animação; "voltar" faz voltar ao Idle quando ela acaba.
static func tocar(modelo: Node3D, nome: String, voltar := true) -> void:
	if modelo == null or not modelo.has_meta("ap"):
		return
	var ap: AnimationPlayer = modelo.get_meta("ap")
	if not ap.has_animation(nome):
		return
	ap.play(nome, 0.15)
	ap.clear_queue()
	if voltar and nome != "Idle":
		ap.queue("Idle")


static func animacao_de_ataque(modelo: Node3D, magia := false) -> String:
	var cfg: Dictionary = modelo.get_meta("cfg", {})
	return cfg.get("magia", "Spellcast_Shoot") if magia and cfg.has("magia") else cfg.get("ataque", "1H_Melee_Attack_Chop")


## Vira o modelo para olhar na direção (x, z) do mundo.
static func encarar(modelo: Node3D, direcao: Vector3) -> void:
	if modelo == null or Vector2(direcao.x, direcao.z).length() < 0.01:
		return
	modelo.rotation.y = atan2(direcao.x, direcao.z)


# --- Cenário (0.18) ----------------------------------------------------------
## Obstáculo -> modelo; "alt" e "larg" são o tamanho máximo em casas (o menor manda).
## "piso": só usa o modelo nesse tipo de chão (as árvores secas só no pântano).
const CENARIO := "res://assets/modelos/cenario/"
const OBJETOS := {
	"pilar": {"arq": "pillar_decorated.glb", "alt": 1.7, "larg": 0.9},
	"sarcofago": {"arq": "coffin_decorated.gltf", "alt": 0.7, "larg": 0.98},
	"mesa": {"arq": "table_medium_decorated_A.glb", "alt": 0.9, "larg": 0.95},
	"altar": {"arq": "shrine_candles.gltf", "alt": 1.3, "larg": 0.9},
	"bau": {"arq": "chest.glb", "alt": 0.6, "larg": 0.7},
	"arvore@lodo": {"arq": ["tree_dead_large.gltf", "tree_dead_medium.gltf"], "alt": 2.4, "larg": 1.6},
	"arvore": {"arq": ["../vila/tree_single_A.gltf", "../vila/tree_single_B.gltf"], "alt": 1.9, "larg": 1.2},
	"casa": {"arq": "../vila/building_home_A_yellow.gltf", "alt": 1.9, "larg": 1.05},
	"celeiro": {"arq": "../vila/building_home_B_red.gltf", "alt": 1.9, "larg": 1.05},
	"poco": {"arq": "../vila/building_well_yellow.gltf", "alt": 1.3, "larg": 0.95},
	"tenda": {"arq": "../vila/tent.gltf", "alt": 1.1, "larg": 0.98},
	"saco": {"arq": "../vila/sack.gltf", "alt": 0.6, "larg": 0.7},
	"saco@lodo": {"arq": "", "alt": 1, "larg": 1},   # no pântano é o casco do barco: fica a peça simples
	"pedra": {"arq": ["../vila/rock_single_A.gltf", "../vila/rock_single_C.gltf"], "alt": 0.8, "larg": 0.9},
	"barril": {"arq": "barrel_large.glb", "alt": 0.8, "larg": 0.6},
	"caixa": {"arq": "box_large.glb", "alt": 0.8, "larg": 0.8},
	"escombro": {"arq": "rubble_large.glb", "alt": 0.5, "larg": 0.95},
	"pedra_alta": {"arq": "../vila/rock_single_C.gltf", "alt": 0.85, "larg": 0.98},
	"estante": {"arq": "shelf_small_candles.glb", "alt": 1.5, "larg": 0.95},
	"saco_de_dormir": {"arq": "bed_floor.glb", "alt": 0.3, "larg": 0.8},
	"velas": {"arq": "candle_triple.glb", "alt": 0.45, "larg": 0.4},
	"lapide": {"arq": ["gravestone.gltf", "grave_A.gltf"], "alt": 0.9, "larg": 0.9},
	"caveira_vela": {"arq": "skull_candle.gltf", "alt": 0.45, "larg": 0.4},
	"lanterna_chao": {"arq": "lantern_standing.gltf", "alt": 0.5, "larg": 0.4},
}

static var _cenas_cenario := {}


## Modelo de cenário para o obstáculo (ou null: aí a tela desenha a peça simples).
static func criar_objeto(tipo: String, celula: Vector2i, piso: String, area := Vector2i.ONE) -> Node3D:
	var chave := tipo + "@" + piso if OBJETOS.has(tipo + "@" + piso) else tipo
	if not OBJETOS.has(chave):
		return null
	var cfg: Dictionary = OBJETOS[chave]
	var arqs: Array = cfg["arq"] if cfg["arq"] is Array else [cfg["arq"]]
	var arq: String = arqs[absi(celula.x * 7 + celula.y * 13) % arqs.size()]
	if not _cenas_cenario.has(arq):
		_cenas_cenario[arq] = load(CENARIO + arq) if ResourceLoader.exists(CENARIO + arq) else null
	if _cenas_cenario[arq] == null:
		return null
	var inst: Node3D = _cenas_cenario[arq].instantiate()
	var caixa := AABB()
	var primeiro := true
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		var a: AABB = mi.transform * mi.mesh.get_aabb()
		caixa = a if primeiro else caixa.merge(a)
		primeiro = false
	var s := 1.0
	if not primeiro:
		s = minf(float(cfg["alt"]) / maxf(caixa.size.y, 0.01), float(cfg["larg"]) / maxf(maxf(caixa.size.x, caixa.size.z), 0.01))
	inst.scale = Vector3.ONE * s
	if area != Vector2i.ONE and not primeiro:
		# Construção de várias casas: um modelo só, esticado para cobrir o bloco.
		var sx := float(area.x) * 0.96 / maxf(caixa.size.x, 0.01)
		var sz := float(area.y) * 0.96 / maxf(caixa.size.z, 0.01)
		inst.scale = Vector3(sx, minf(sx, sz) * 0.85, sz)
		return inst
	inst.rotation.y = deg_to_rad(float((celula.x * 31 + celula.y * 17) % 4) * 90.0) if tipo in ["barril", "caixa", "escombro", "arvore", "lapide", "pedra", "saco"] else 0.0
	return inst
