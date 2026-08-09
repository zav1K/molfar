class_name InventoryPanel
extends CanvasLayer
## Stock-list overlay for glancing at held herbs or potions — instanced
## twice in Hut.tscn (one per `kind`), each opened by its own left-panel
## zone (drying beam for herbs, potion shelf for potions). Both zones
## are purely decorative triggers, not physical per-item displays: no
## drag-and-drop, no per-slot anchors, no slot-count/equipment-
## progression bookkeeping for these two spots. The chest on the right
## panel is meant to become the actual full-stockpile screen later —
## these are just the quick-glance versions for two atmospheric
## hotspots.

enum Kind { INGREDIENTS, POTIONS }

@export var kind: Kind = Kind.INGREDIENTS

signal closed
signal potion_selected(potion: Potion)

@onready var title_label: Label = $Panel/Title
@onready var list: VBoxContainer = $Panel/List
@onready var close_button: Button = $Panel/CloseButton

func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close_pressed)
	title_label.text = "Трави" if kind == Kind.INGREDIENTS else "Зілля"

func open() -> void:
	_rebuild()
	visible = true

func _rebuild() -> void:
	for child in list.get_children():
		child.queue_free()
	if kind == Kind.INGREDIENTS:
		for ingredient in IngredientDatabase.get_all():
			var count := PlayerInventory.get_count(ingredient.id)
			if count > 0:
				list.add_child(_build_ingredient_row(ingredient, count))
	else:
		for potion in PotionDatabase.get_all():
			var count := PlayerInventory.get_count(potion.id)
			if count > 0:
				list.add_child(_build_potion_row(potion, count))

func _build_ingredient_row(ingredient: Ingredient, count: int) -> HBoxContainer:
	var row := HBoxContainer.new()

	if ingredient.bundle_icon != null:
		var icon := TextureRect.new()
		icon.texture = ingredient.bundle_icon
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(28, 28)
		row.add_child(icon)

	var label := Label.new()
	label.text = "%s ×%d" % [ingredient.display_name, count]
	row.add_child(label)

	return row

func _build_potion_row(potion: Potion, count: int) -> Button:
	var button := Button.new()
	button.text = "%s ×%d" % [potion.display_name, count]
	button.pressed.connect(func() -> void: potion_selected.emit(potion))
	return button

func _on_close_pressed() -> void:
	visible = false
	closed.emit()
