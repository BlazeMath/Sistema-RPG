## Miniaturas de equipamentos no mercado e no inventário.
extends RefCounted

const Itens := preload("res://core/itens.gd")
const PASTA := "res://assets/itens/"


static func adicionar(linha: HBoxContainer, item: Dictionary, tamanho: Vector2) -> void:
	var codigo := str(item.get("eq", ""))
	if codigo.is_empty() and item.has("id"):
		# Itens equipados de salvamentos antigos podem trazer apenas o id interno.
		codigo = str(Itens.item(str(item["id"])).get("eq", ""))
	if codigo.length() != 6 or not codigo.begins_with("EQ-") or not codigo.right(3).is_valid_int():
		return
	var caminho := PASTA + codigo + ".webp"
	if not ResourceLoader.exists(caminho, "Texture2D"):
		return
	var textura := ResourceLoader.load(caminho, "Texture2D") as Texture2D
	if textura == null:
		return
	var miniatura := TextureRect.new()
	miniatura.texture = textura
	miniatura.custom_minimum_size = tamanho
	miniatura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	miniatura.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	miniatura.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	miniatura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	linha.add_child(miniatura)
