class_name IngredientDragIcon
extends TextureRect
## Small draggable icon on a brewing ingredient row. Dragging it onto the
## cauldron adds one unit, same effect as pressing the row's + button —
## only shown for ingredients that have bundle art (see beam_bundle.gd
## for the same "no art yet, stay out of the way" precedent).

var ingredient_id: StringName

func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview := TextureRect.new()
	preview.texture = texture
	preview.custom_minimum_size = Vector2(32, 32)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)
	return {"ingredient_id": ingredient_id}
