extends Control
## Shows brewed potions sitting on the shelf beside the cauldron, mirroring
## PlayerInventory the same way beam_bundle.gd mirrors it for drying herbs.
## Lists every potion currently held — no potion art exists yet, so this is
## a text summary instead of icons.

@onready var label: Label = $Label

func _ready() -> void:
	PlayerInventory.changed.connect(_on_inventory_changed)
	_refresh()

func _on_inventory_changed(changed_id: StringName) -> void:
	if PotionDatabase.get_potion(changed_id) != null:
		_refresh()

func _refresh() -> void:
	var lines: Array[String] = []
	for potion in PotionDatabase.get_all():
		var count := PlayerInventory.get_count(potion.id)
		if count > 0:
			lines.append("%s ×%d" % [potion.display_name, count])
	visible = not lines.is_empty()
	label.text = "\n".join(lines)
