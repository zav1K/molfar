extends TextureRect
## A drying-herb bundle hanging on the сволок. Visible only while the player
## actually holds that ingredient — this is meant to mirror inventory state,
## not decorate unconditionally.

@export var ingredient_id: StringName

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	PlayerInventory.changed.connect(_on_inventory_changed)
	_refresh()

func _on_inventory_changed(changed_id: StringName) -> void:
	if changed_id == ingredient_id:
		_refresh()

func _refresh() -> void:
	visible = PlayerInventory.has(ingredient_id)
