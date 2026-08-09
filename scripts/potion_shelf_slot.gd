extends Control
## Shows brewed potions sitting on the shelf beside the cauldron, mirroring
## PlayerInventory the same way beam_bundle.gd mirrors it for drying herbs.
## Builds one icon+count entry per potion currently held, side by side —
## there can be more than one type at once.

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
		row.add_child(_build_entry(potion, count))
	visible = any

func _build_entry(potion: Potion, count: int) -> VBoxContainer:
	var entry := VBoxContainer.new()

	if potion.icon != null:
		var icon := TextureRect.new()
		icon.texture = potion.icon
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(40, 85)
		entry.add_child(icon)

	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.custom_minimum_size = Vector2(90, 0)
	label.text = "%s ×%d" % [potion.display_name, count]
	entry.add_child(label)

	return entry
