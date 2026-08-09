class_name BrewingUI
extends CanvasLayer
## Minimal brewing interface: pick 2-3 ingredients you currently hold and
## brew them into a single placeholder potion. No tactile Potion-Craft-style
## mechanic and no branching recipe table yet — any valid selection
## produces the same test result. Both land later.

const MIN_INGREDIENTS := 2
const MAX_INGREDIENTS := 3
const RESULT_POTION_ID := &"simple_potion"

signal closed

@onready var ingredient_list: VBoxContainer = $Panel/IngredientList
@onready var brew_button: Button = $Panel/BrewButton
@onready var back_button: Button = $Panel/BackButton
@onready var status_label: Label = $Panel/StatusLabel

var _selected: Array[StringName] = []

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
		var count := PlayerInventory.get_count(ingredient.id)
		if count <= 0:
			continue
		var button := Button.new()
		button.toggle_mode = true
		button.text = "%s ×%d" % [ingredient.display_name, count]
		button.button_pressed = ingredient.id in _selected
		button.toggled.connect(_on_ingredient_toggled.bind(ingredient.id))
		ingredient_list.add_child(button)
	_update_brew_button()

func _on_ingredient_toggled(pressed: bool, ingredient_id: StringName) -> void:
	if pressed:
		if _selected.size() >= MAX_INGREDIENTS:
			# Reject the pick past the cap and resync button states instead
			# of leaving this one visually pressed with nothing behind it.
			_rebuild_ingredient_list()
			return
		_selected.append(ingredient_id)
	else:
		_selected.erase(ingredient_id)
	_update_brew_button()

func _update_brew_button() -> void:
	brew_button.disabled = _selected.size() < MIN_INGREDIENTS or _selected.size() > MAX_INGREDIENTS

func _on_brew_pressed() -> void:
	for ingredient_id in _selected:
		PlayerInventory.remove(ingredient_id)
	PlayerInventory.add(RESULT_POTION_ID)
	var potion := PotionDatabase.get_potion(RESULT_POTION_ID)
	status_label.text = "Готово: %s" % (potion.display_name if potion else String(RESULT_POTION_ID))
	_selected.clear()
	_rebuild_ingredient_list()

func _on_back_pressed() -> void:
	visible = false
	closed.emit()
