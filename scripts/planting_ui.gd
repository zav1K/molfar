class_name PlantingUI
extends CanvasLayer
## The 4-step tactile planting minigame: dig, choose a seed, cover, water.
## Digging is free and immediately persisted to GardenState (empty->dug)
## the moment that step is clicked — closing the UI right after leaves
## the hole there for next time, same as real digging would. Choosing a
## seed is still UI-local; the actual seed cost and dug->sprout
## transition only commit on the Cover click, and Water is just
## GardenState's normal watering call made once, right after planting.

signal closed

enum Step { DIG, SEED, COVER, WATER }

const STEP_TITLES := {
	Step.DIG: "Крок 1/4: викопай ямку",
	Step.SEED: "Крок 2/4: обери насіння",
	Step.COVER: "Крок 3/4: загорни землею",
	Step.WATER: "Крок 4/4: полий",
}

@onready var step_label: Label = $Panel/StepLabel
@onready var dig_button: Button = $Panel/DigButton
@onready var seed_list: VBoxContainer = $Panel/SeedList
@onready var cover_button: Button = $Panel/CoverButton
@onready var water_button: Button = $Panel/WaterButton
@onready var warning_label: Label = $Panel/WarningLabel
@onready var close_button: Button = $Panel/CloseButton

var _plot_index: int = -1
var _step: Step = Step.DIG
var _selected_ingredient: Ingredient
var _penalty: bool = false

func _ready() -> void:
	visible = false
	dig_button.pressed.connect(_on_dig_pressed)
	cover_button.pressed.connect(_on_cover_pressed)
	water_button.pressed.connect(_on_water_pressed)
	close_button.pressed.connect(_on_close_pressed)

func open(plot_index: int) -> void:
	_plot_index = plot_index
	_selected_ingredient = null
	_penalty = false
	warning_label.text = ""
	# Resume where a previous visit left off — dug is itself a persisted
	# GardenState stage, so a plot already dug skips straight to seed
	# choice instead of re-digging.
	if GardenState.get_plot(plot_index).stage == GardenState.Stage.DUG:
		_step = Step.SEED
		_build_seed_list()
	else:
		_step = Step.DIG
	_refresh()
	visible = true

func _refresh() -> void:
	step_label.text = STEP_TITLES[_step]
	dig_button.visible = _step == Step.DIG
	seed_list.visible = _step == Step.SEED
	cover_button.visible = _step == Step.COVER
	water_button.visible = _step == Step.WATER

func _on_dig_pressed() -> void:
	GardenState.dig(_plot_index)
	_build_seed_list()
	_step = Step.SEED
	_refresh()

func _build_seed_list() -> void:
	for child in seed_list.get_children():
		child.queue_free()
	for ingredient in IngredientDatabase.get_all():
		if ingredient.source != Ingredient.Source.GARDEN:
			continue
		var count := PlayerInventory.get_count(ingredient.id)
		if count <= 0:
			continue
		var button := Button.new()
		button.text = "%s ×%d" % [ingredient.display_name, count]
		button.pressed.connect(_on_seed_selected.bind(ingredient))
		seed_list.add_child(button)
	if seed_list.get_child_count() == 0:
		var empty_label := Label.new()
		empty_label.text = "Немає насіння для посадки."
		seed_list.add_child(empty_label)

func _on_seed_selected(ingredient: Ingredient) -> void:
	var check := GardenState.check_plantable(ingredient)
	if not check.allowed:
		warning_label.text = check.reason
		return
	_selected_ingredient = ingredient
	_penalty = check.penalty
	warning_label.text = check.reason
	_step = Step.COVER
	_refresh()

func _on_cover_pressed() -> void:
	PlayerInventory.remove(_selected_ingredient.id, 1)
	GardenState.plant(_plot_index, _selected_ingredient, _penalty)
	_step = Step.WATER
	_refresh()

func _on_water_pressed() -> void:
	GardenState.water(_plot_index)
	visible = false
	closed.emit()

func _on_close_pressed() -> void:
	visible = false
	closed.emit()
