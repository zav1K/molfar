class_name BrewingUI
extends CanvasLayer
## Brewing interface: pick how many of each ingredient you currently hold
## (2-3 total), then physically stir the cauldron (see stir_cauldron.gd).
## Stir direction picks the recipe's white/black path result; rotation
## count and rhythm evenness decide brew quality. Ingredients only leave
## the inventory once a matched recipe is actually stirred — picking an
## unknown combination costs nothing, so experimentation stays free.

const MIN_INGREDIENTS := 2
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

@onready var ingredient_list: VBoxContainer = $Panel/IngredientList
@onready var brew_button: Button = $Panel/BrewButton
@onready var back_button: Button = $Panel/BackButton
@onready var status_label: Label = $Panel/StatusLabel
@onready var stir_cauldron: StirCauldron = $Panel/StirCauldron

var _selected: Dictionary = {} # StringName -> int
var _pending_recipe: Recipe

func _ready() -> void:
	visible = false
	brew_button.pressed.connect(_on_brew_pressed)
	back_button.pressed.connect(_on_back_pressed)
	stir_cauldron.finished.connect(_on_stir_finished)
	stir_cauldron.visible = false

func open() -> void:
	_selected.clear()
	_pending_recipe = null
	status_label.text = ""
	_show_ingredient_phase()
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
	_pending_recipe = recipe
	_show_stir_phase()
	stir_cauldron.start()

func _on_stir_finished(direction: int, rotations: float, evenness: float) -> void:
	var recipe := _pending_recipe
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
	_pending_recipe = null
	_show_ingredient_phase()
	_rebuild_ingredient_list()

func _resolve_quality(rotations: float, evenness: float) -> Quality:
	if rotations > MAX_ROTATIONS or evenness >= EVEN_CV_SPOILED:
		return Quality.SPOILED
	if rotations < MIN_ROTATIONS:
		return Quality.WEAK
	if rotations >= GOOD_ROTATIONS and evenness < EVEN_CV_GOOD:
		return Quality.GOOD
	return Quality.NORMAL

func _show_ingredient_phase() -> void:
	ingredient_list.visible = true
	brew_button.visible = true
	back_button.visible = true
	stir_cauldron.visible = false

func _show_stir_phase() -> void:
	ingredient_list.visible = false
	brew_button.visible = false
	back_button.visible = false
	status_label.text = ""

func _on_back_pressed() -> void:
	visible = false
	closed.emit()
