## Música (0.16): um tocador global (autoload "Musica") com troca suave entre faixas.
## Faixas em assets/musica (geradas por tools/gerar_musica.py). Tecla M liga e desliga.
## Volume e mudo ficam salvos em user://som.json.
extends Node

const FAIXAS := {"menu": "res://assets/musica/menu.ogg", "exploracao": "res://assets/musica/exploracao.ogg",
	"batalha": "res://assets/musica/batalha.ogg", "cripta": "res://assets/musica/cripta.ogg"}
const ARQUIVO := "user://som.json"

var _a: AudioStreamPlayer
var _b: AudioStreamPlayer
var _atual := ""
var volume := 0.6       # 0 a 1
var mudo := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_a = AudioStreamPlayer.new()
	_b = AudioStreamPlayer.new()
	add_child(_a)
	add_child(_b)
	load("res://ui/menu_pausa.gd").aplicar_config_salva()
	if FileAccess.file_exists(ARQUIVO):
		var d = JSON.parse_string(FileAccess.get_file_as_string(ARQUIVO))
		if d is Dictionary:
			volume = float(d.get("volume", volume))
			mudo = bool(d.get("mudo", mudo))


func _db() -> float:
	return -80.0 if mudo or volume <= 0.001 else linear_to_db(volume)


var _troca: Tween
var _tocador_atual: AudioStreamPlayer


func tocar(nome: String) -> void:
	if nome == _atual or not FAIXAS.has(nome):
		return
	_atual = nome
	var s = load(FAIXAS[nome])
	if s == null:
		return
	if s is AudioStreamOggVorbis:
		s.loop = true
	# 0.20: só uma música por vez. A nova entra no tocador que está livre (ou no que
	# está mais baixo); todas as outras saem, mesmo se uma troca ainda estava no meio.
	if _troca != null and _troca.is_valid():
		_troca.kill()
	var novo: AudioStreamPlayer = _a if not _a.playing else (_b if not _b.playing else (_a if _a.volume_db < _b.volume_db else _b))
	var velho: AudioStreamPlayer = _b if novo == _a else _a
	novo.stop()
	novo.stream = s
	novo.volume_db = -40.0
	novo.play()
	_tocador_atual = novo
	_troca = create_tween().set_parallel(true)
	_troca.tween_property(novo, "volume_db", _db(), 1.2)
	if velho.playing:
		_troca.tween_property(velho, "volume_db", -60.0, 1.2)
		_troca.chain().tween_callback(velho.stop)


func alternar_mudo() -> void:
	mudo = not mudo
	_aplicar()


func definir_volume(v: float) -> void:
	volume = clampf(v, 0.0, 1.0)
	_aplicar()


func _aplicar() -> void:
	if _tocador_atual != null and _tocador_atual.playing:
		if _troca != null and _troca.is_valid():
			_troca.kill()
		_tocador_atual.volume_db = _db()
	for p in [_a, _b]:
		if p != _tocador_atual:
			p.stop()
	var f := FileAccess.open(ARQUIVO, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"volume": volume, "mudo": mudo}))


func _unhandled_input(evento: InputEvent) -> void:
	if evento is InputEventKey and evento.pressed and not evento.echo and evento.keycode == KEY_M:
		alternar_mudo()
