class_name BrewingUI
extends CanvasLayer
## Minimal brewing interface: pick how many of each ingredient you currently
## hold (2-3 total), brew, and get whatever RecipeDatabase says that exact
## combination makes — or nothing, if it doesn't match a known recipe. No
## tactile Potion-Craft-style mechanic yet, that's separate future work.

const MIN_INGREDIENTS := 2
const MAX_INGREDIENTS := 3

signal closed

@onready var ingredient_list: VBoxContainer = $Panel/IngredientList
@onready var brew_button: Button = $Panel/BrewButton
@onready var back_button: Button = $Panel/BackButton
@onready var status_label: Label = $Panel/StatusLabel

var _selected: Dictionary = {} # StringName -> int

func _ready() -> void:
	visible = false
	brew_button.pressed.connect(_on_brew_pressed)
	back_button.pressed.connect(_on_back_pressed)

func open() -> void:
	_selected.clear()
	status_label.text = ""
	_rebuild_ingredient_list()
	visible = true

func _rebuild_ingredient_list() -> void:
	for child in ingredient_list.get_children():
		child.queue_free()
	for ingredient in IngredientDatabase.get_all():
		var held := PlayerInventory.get_count(ingredient.id)
		if held <= 0:
			continue
		ingredient_list.add_child(_build_ingredient_row(ingredient, held))
	_update_brew_button()

func _build_ingredient_row(ingredient: Ingredient, held: int) -> HBoxContainer:
	var picked: int = _selected.get(ingredient.id, 0)

	var row := HBoxContainer.new()

	var name_label := Label.new()
	name_label.custom_minimum_size.x = 160
	name_label.text = "%s (є %d)" % [ingredient.display_name, held]
	row.add_child(name_label)

	var minus_button := Button.new()
	minus_button.text = "-"
	minus_button.disabled = picked <= 0
	minus_button.pressed.connect(_on_count_changed.bind(ingredient.id, -1))
	row.add_child(minus_button)

	var count_label := Label.new()
	count_label.custom_minimum_size.x = 30
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.text = str(picked)
	row.add_child(count_label)

	var plus_button := Button.new()
	plus_button.text = "+"
	plus_button.disabled = picked >= held or _total_selected() >= MAX_INGREDIENTS
	plus_button.pressed.connect(_on_count_changed.bind(ingredient.id, 1))
	row.add_child(plus_button)

	return row

func _on_count_changed(ingredient_id: StringName, delta: int) -> void:
	var held := PlayerInventory.get_count(ingredient_id)
	var new_count: int = clampi(int(_selected.get(ingredient_id, 0)) + delta, 0, held)
	if new_count == 0:
		_selected.erase(ingredient_id)
	else:
		_selected[ingredient_id] = new_count
	_rebuild_ingredient_list()

func _total_selected() -> int:
	var total := 0
	for count in _selected.values():
		total += count
	return total

func _update_brew_button() -> void:
	var total := _total_selected()
	brew_button.disabled = total < MIN_INGREDIENTS or total > MAX_INGREDIENTS

func _on_brew_pressed() -> void:
	var recipe := RecipeDatabase.find_recipe(_selected)
	if recipe == null:
		status_label.text = "Невідома комбінація — спробуй інше поєднання."
		return
	for ingredient_id in _selected:
		PlayerInventory.remove(ingredient_id, _selected[ingredient_id])
	PlayerInventory.add(recipe.result_potion_id)
	var potion := PotionDatabase.get_potion(recipe.result_potion_id)
	status_label.text = "Готово: %s" % (potion.display_name if potion else String(recipe.result_potion_id))
	_selected.clear()
	_rebuild_ingredient_list()

func _on_back_pressed() -> void:
	visible = false
	closed.emit()
