extends TextureRect
## A drying-herb bundle hanging on the сволок. Visible only while the player
## actually holds that ingredient — mirrors inventory state instead of
## decorating unconditionally. Hovering shows how many the player has.

@export var ingredient_id: StringName

var _ingredient: Ingredient

func _ready() -> void:
	_ingredient = IngredientDatabase.get_ingredient(ingredient_id)
	if _ingredient == null or _ingredient.bundle_icon == null:
		# No art for this herb yet — stay hidden instead of showing an empty box.
		visible = false
		return
	texture = _ingredient.bundle_icon
	mouse_filter = Control.MOUSE_FILTER_STOP
	PlayerInventory.changed.connect(_on_inventory_changed)
	_refresh()

func _on_inventory_changed(changed_id: StringName) -> void:
	if changed_id == ingredient_id:
		_refresh()

func _refresh() -> void:
	var count := PlayerInventory.get_count(ingredient_id)
	visible = count > 0
	tooltip_text = "%s ×%d" % [_ingredient.display_name, count]
