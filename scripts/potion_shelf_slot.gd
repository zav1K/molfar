extends Control
## Shows a brewed potion sitting on the shelf beside the cauldron, mirroring
## PlayerInventory the same way beam_bundle.gd mirrors it for drying herbs.
## No potion art exists yet, so this is a text label instead of an icon —
## swap in a TextureRect once Potion.icon is set.

@export var potion_id: StringName

@onready var label: Label = $Label

func _ready() -> void:
	PlayerInventory.changed.connect(_on_inventory_changed)
	_refresh()

func _on_inventory_changed(changed_id: StringName) -> void:
	if changed_id == potion_id:
		_refresh()

func _refresh() -> void:
	var count := PlayerInventory.get_count(potion_id)
	visible = count > 0
	var potion := PotionDatabase.get_potion(potion_id)
	label.text = "%s ×%d" % [potion.display_name if potion else String(potion_id), count]
