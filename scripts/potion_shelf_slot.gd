extends Control
## Shows brewed potions sitting on the shelf beside the cauldron, mirroring
## PlayerInventory the same way beam_bundle.gd mirrors it for drying herbs.
## One icon per potion currently held, side by side. Name and count only
## show on hover (tooltip), matching how the beam bundles behave.

@onready var row: HBoxContainer = $Row

func _ready() -> void:
	PlayerInventory.changed.connect(_on_inventory_changed)
	_refresh()

func _on_inventory_changed(changed_id: StringName) -> void:
	if PotionDatabase.get_potion(changed_id) != null:
		_refresh()

func _refresh() -> void:
	for child in row.get_children():
		child.queue_free()
	var any := false
	for potion in PotionDatabase.get_all():
		var count := PlayerInventory.get_count(potion.id)
		if count <= 0:
			continue
		any = true
		row.add_child(_build_icon(potion, count))
	visible = any

func _build_icon(potion: Potion, count: int) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = potion.icon
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(30, 65)
	icon.mouse_filter = Control.MOUSE_FILTER_STOP
	icon.tooltip_text = "%s ×%d" % [potion.display_name, count]
	return icon
