class_name WardSlot
extends InteractionZone
## A hook above the door. Click to cycle through ingredients that can ward
## against something — a placeholder assignment UI until there's a proper
## inventory screen to drag wards from.

@export var slot_index: int = 0

@onready var visual: ColorRect = $Visual
@onready var label: Label = $Label

func _ready() -> void:
	super._ready()
	activated.connect(_on_activated)
	WardRack.changed.connect(_on_rack_changed)
	_refresh()

func _on_activated(_zone: InteractionZone) -> void:
	var options := _wardable_ingredient_ids()
	if options.is_empty():
		return
	var next_index := options.find(WardRack.get_slot(slot_index)) + 1
	if next_index >= options.size():
		WardRack.clear_slot(slot_index)
	else:
		WardRack.hang(slot_index, options[next_index])

func _on_rack_changed(changed_index: int) -> void:
	if changed_index == slot_index:
		_refresh()

func _refresh() -> void:
	var occupant := WardRack.get_slot(slot_index)
	if occupant == &"":
		label.text = "Гачок"
		visual.color = Color(0.3, 0.22, 0.15, 0.2)
	else:
		var ingredient := IngredientDatabase.get_ingredient(occupant)
		label.text = ingredient.display_name if ingredient else str(occupant)
		visual.color = Color(0.45, 0.35, 0.15, 0.4)

func _wardable_ingredient_ids() -> Array[StringName]:
	var ids: Array[StringName] = [&""]
	for ingredient in IngredientDatabase.get_all():
		if ingredient.ward_threat != Threat.Type.NONE:
			ids.append(ingredient.id)
	return ids
