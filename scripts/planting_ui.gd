class_name PlantingUI
extends CanvasLayer
## Seed picker for a plot that's already dug — GardenPlot._on_activated
## digs an EMPTY plot immediately with no UI (nothing to choose), and
## only opens this once it's DUG. Picking a seed plants it right away;
## there's nothing else to decide here, so no multi-step wizard anymore.
## Watering isn't part of this flow at all — the first watering happens
## the same way every later one does, its own separate click on the plot
## once it's showing a sprout (see GardenState.water(), GardenPlot's
## SPROUT/GROWING case).

signal closed

@onready var title_label: Label = $Panel/StepLabel
@onready var seed_list: VBoxContainer = $Panel/SeedList
@onready var warning_label: Label = $Panel/WarningLabel
@onready var close_button: Button = $Panel/CloseButton

var _plot_index: int = -1

func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close_pressed)

func open(plot_index: int) -> void:
	_plot_index = plot_index
	warning_label.text = ""
	_build_seed_list()
	visible = true

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
	PlayerInventory.remove(ingredient.id, 1)
	GardenState.plant(_plot_index, ingredient, check.penalty)
	visible = false
	closed.emit()

func _on_close_pressed() -> void:
	visible = false
	closed.emit()
