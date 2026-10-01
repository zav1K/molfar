class_name BrewingUI
extends CanvasLayer
## Brewing interface: the ingredient list and the cauldron are visible
## together. Add ingredients by pressing a row's + button or by dragging
## its icon into the cauldron (see ingredient_drag_icon.gd / stir_cauldron.gd)
## — either way spawns a token floating in the liquid. Stirring the
## cauldron in a circle resolves the brew: direction picks the matched
## recipe's white/black path result, rotation count and rhythm evenness
## grade its quality. Ingredients only leave the inventory once a real
## recipe is actually stirred — an unrecognized combination costs
## nothing, so picking ingredients stays free to experiment with; only
## the physical stir carries real stakes.

const MAX_INGREDIENTS := 3

## Rotation/evenness thresholds that grade a stir. Evenness is a
## coefficient of variation of angular speed — lower is steadier.
const MIN_ROTATIONS := 1.0
const GOOD_ROTATIONS := 2.5
const MAX_ROTATIONS := 6.0
const EVEN_CV_GOOD := 0.35
const EVEN_CV_SPOILED := 0.9

enum Quality { WEAK, NORMAL, GOOD, SPOILED }
const QUALITY_LABEL := {
	Quality.WEAK: "слабке",
	Quality.NORMAL: "звичайне",
	Quality.GOOD: "добре",
}

signal closed

@onready var ingredient_list: VBoxContainer = $Panel/IngredientListScroll/IngredientList
@onready var reset_button: Button = $Panel/BrewButton
@onready var back_button: Button = $Panel/BackButton
@onready var status_label: Label = $Panel/StatusLabel
@onready var stir_cauldron: StirCauldron = $Panel/StirCauldron

var _selected: Dictionary = {} # StringName -> int

func _ready() -> void:
	visible = false
	reset_button.text = "Скинути"
	reset_button.pressed.connect(_on_reset_pressed)
	back_button.pressed.connect(_on_back_pressed)
	stir_cauldron.finished.connect(_on_stir_finished)
	stir_cauldron.ingredient_dropped.connect(_add_ingredient)

func open() -> void:
	_selected.clear()
	status_label.text = ""
	stir_cauldron.clear_tokens()
	stir_cauldron.reset_liquid()
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
	_update_reset_button()

func _build_ingredient_row(ingredient: Ingredient, held: int) -> HBoxContainer:
	var picked: int = _selected.get(ingredient.id, 0)

	var row := HBoxContainer.new()

	if ingredient.bundle_icon != null:
		var drag_icon := IngredientDragIcon.new()
		drag_icon.ingredient_id = ingredient.id
		drag_icon.texture = ingredient.bundle_icon
		drag_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		drag_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		drag_icon.custom_minimum_size = Vector2(24, 24)
		drag_icon.tooltip_text = "Перетягни в казан"
		row.add_child(drag_icon)

	var name_label := Label.new()
	name_label.custom_minimum_size.x = 160
	name_label.text = "%s (є %d)" % [ingredient.display_name, held]
	row.add_child(name_label)

	var minus_button := Button.new()
	minus_button.text = "-"
	minus_button.disabled = picked <= 0
	minus_button.pressed.connect(_remove_ingredient.bind(ingredient.id))
	row.add_child(minus_button)

	var count_label := Label.new()
	count_label.custom_minimum_size.x = 30
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.text = str(picked)
	row.add_child(count_label)

	var plus_button := Button.new()
	plus_button.text = "+"
	plus_button.disabled = picked >= held or _total_selected() >= MAX_INGREDIENTS
	plus_button.pressed.connect(_add_ingredient.bind(ingredient.id))
	row.add_child(plus_button)

	return row

func _add_ingredient(ingredient_id: StringName) -> void:
	var held := PlayerInventory.get_count(ingredient_id)
	var current: int = _selected.get(ingredient_id, 0)
	if current >= held or _total_selected() >= MAX_INGREDIENTS:
		return
	_selected[ingredient_id] = current + 1
	stir_cauldron.add_token(IngredientDatabase.get_ingredient(ingredient_id))
	_rebuild_ingredient_list()

func _remove_ingredient(ingredient_id: StringName) -> void:
	var current: int = _selected.get(ingredient_id, 0)
	if current <= 0:
		return
	if current == 1:
		_selected.erase(ingredient_id)
	else:
		_selected[ingredient_id] = current - 1
	stir_cauldron.remove_token(ingredient_id)
	_rebuild_ingredient_list()

func _total_selected() -> int:
	var total := 0
	for count in _selected.values():
		total += count
	return total

func _update_reset_button() -> void:
	reset_button.disabled = _selected.is_empty()

func _on_reset_pressed() -> void:
	_selected.clear()
	stir_cauldron.clear_tokens()
	status_label.text = ""
	_rebuild_ingredient_list()

func _on_stir_finished(direction: int, rotations: float, evenness: float) -> void:
	var recipe := RecipeDatabase.find_recipe(_selected)
	if recipe == null:
		status_label.text = "Невідома комбінація — спробуй інше поєднання."
		return

	var quality := _resolve_quality(rotations, evenness)
	for ingredient_id in _selected:
		PlayerInventory.remove(ingredient_id, _selected[ingredient_id])

	if quality == Quality.SPOILED:
		status_label.text = "Розмішування вийшло занадто хаотичним — зілля зіпсоване."
	else:
		var result_id: StringName = recipe.light_result_id if direction >= 0 else recipe.dark_result_id
		var path_name := "світлого" if direction >= 0 else "темного"
		if result_id == &"":
			status_label.text = "Цей рецепт не має %s шляху (поки що) — зілля зіпсоване." % path_name
		else:
			PlayerInventory.add(result_id)
			var potion := PotionDatabase.get_potion(result_id)
			var potion_name := potion.display_name if potion else String(result_id)
			status_label.text = "Готово (%s): %s" % [QUALITY_LABEL[quality], potion_name]

	_selected.clear()
	stir_cauldron.clear_tokens()
	stir_cauldron.reset_liquid()
	_rebuild_ingredient_list()

func _resolve_quality(rotations: float, evenness: float) -> Quality:
	if rotations > MAX_ROTATIONS or evenness >= EVEN_CV_SPOILED:
		return Quality.SPOILED
	if rotations < MIN_ROTATIONS:
		return Quality.WEAK
	if rotations >= GOOD_ROTATIONS and evenness < EVEN_CV_GOOD:
		return Quality.GOOD
	return Quality.NORMAL

func _on_back_pressed() -> void:
	visible = false
	closed.emit()
