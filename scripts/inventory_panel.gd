class_name InventoryPanel
extends CanvasLayer
## Simple stock-list overlay, opened by clicking either the drying beam
## or the potion shelf on the left panel — both are now purely
## decorative triggers into this same shared list instead of separate
## per-item anchored displays (design correction: no drag-and-drop or
## per-slot anchors for these two spots, no slot-count/equipment-
## progression bookkeeping either). Shows every ingredient and potion
## currently held. The chest on the right panel is meant to become the
## actual full-stockpile screen later — this is just the quick-glance
## version for these two atmospheric hotspots.

signal closed
signal potion_selected(potion: Potion)

@onready var ingredient_list: VBoxContainer = $Panel/IngredientList
@onready var potion_list: VBoxContainer = $Panel/PotionList
@onready var close_button: Button = $Panel/CloseButton

func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close_pressed)

func open() -> void:
	_rebuild()
	visible = true

func _rebuild() -> void:
	for child in ingredient_list.get_children():
		child.queue_free()
	for ingredient in IngredientDatabase.get_all():
		var count := PlayerInventory.get_count(ingredient.id)
		if count > 0:
			ingredient_list.add_child(_build_label_row("%s ×%d" % [ingredient.display_name, count]))

	for child in potion_list.get_children():
		child.queue_free()
	for potion in PotionDatabase.get_all():
		var count := PlayerInventory.get_count(potion.id)
		if count > 0:
			potion_list.add_child(_build_potion_row(potion, count))

func _build_label_row(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label

func _build_potion_row(potion: Potion, count: int) -> Button:
	var button := Button.new()
	button.text = "%s ×%d" % [potion.display_name, count]
	button.pressed.connect(func() -> void: potion_selected.emit(potion))
	return button

func _on_close_pressed() -> void:
	visible = false
	closed.emit()
