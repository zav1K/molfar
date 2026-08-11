class_name ReceptionUI
extends CanvasLayer
## Shown after inviting a visitor inside: give them an item from the
## inventory (a brewed potion or a carved sigil) and see whether it was
## what they actually needed. No "reading the client" diagnosis mechanic
## yet (see CONCEPT.md) — this just checks the given item's id against
## the visitor's hidden desired_result_id. Giving nothing is a valid
## choice too, always available — but so is asking them to wait instead
## of turning them away outright (see hut.gd's patience timer).
##
## A visitor with offers_item_id set runs the reverse: they're handing
## something to the player (e.g. found_doll's straw doll), a small
## take-it-or-not side quest — neither choice is a fail state, they just
## play different flavor text.

signal closed
signal wait_requested(visitor: Visitor)

@onready var portrait: TextureRect = $Panel/Portrait
@onready var name_label: Label = $Panel/NameLabel
@onready var problem_label: Label = $Panel/ProblemLabel
@onready var item_list: VBoxContainer = $Panel/ItemList
@onready var take_button: Button = $Panel/TakeButton
@onready var send_away_button: Button = $Panel/SendAwayButton
@onready var wait_button: Button = $Panel/WaitButton
@onready var result_label: Label = $Panel/ResultLabel
@onready var finish_button: Button = $Panel/FinishButton

var _visitor: Visitor
var _resolved: bool = false

func _ready() -> void:
	visible = false
	take_button.pressed.connect(_on_take_pressed)
	send_away_button.pressed.connect(_on_send_away_pressed)
	wait_button.pressed.connect(_on_wait_pressed)
	finish_button.pressed.connect(_on_finish_pressed)

func show_visitor(visitor: Visitor) -> void:
	_visitor = visitor
	_resolved = false
	var waiting_portrait := visitor.get_waiting_portrait()
	portrait.texture = waiting_portrait
	portrait.visible = waiting_portrait != null
	name_label.text = visitor.display_name
	problem_label.text = visitor.problem_text
	result_label.text = ""
	_rebuild_item_list()
	visible = true

func _rebuild_item_list() -> void:
	for child in item_list.get_children():
		child.queue_free()
	send_away_button.visible = not _resolved
	wait_button.visible = not _resolved
	finish_button.visible = _resolved
	take_button.visible = not _resolved and _visitor.offers_item_id != &""
	if _resolved:
		return
	if _visitor.offers_item_id != &"":
		# Reversed direction — they're handing something to the player, not
		# asking for one, so the normal give-list doesn't apply here.
		take_button.text = "Взяти: %s" % _item_display_name(_visitor.offers_item_id)
		return
	for potion in PotionDatabase.get_all():
		var count := PlayerInventory.get_count(potion.id)
		if count > 0:
			item_list.add_child(_build_row(potion.id, "%s (є %d)" % [potion.display_name, count]))
	for sigil in SigilDatabase.get_all():
		var count := PlayerInventory.get_count(sigil.id)
		if count > 0:
			item_list.add_child(_build_row(sigil.id, "%s (є %d)" % [sigil.display_name, count]))

func _item_display_name(item_id: StringName) -> String:
	var keepsake := KeepsakeDatabase.get_keepsake(item_id)
	if keepsake != null:
		return keepsake.display_name
	var potion := PotionDatabase.get_potion(item_id)
	if potion != null:
		return potion.display_name
	var sigil := SigilDatabase.get_sigil(item_id)
	if sigil != null:
		return sigil.display_name
	var ingredient := IngredientDatabase.get_ingredient(item_id)
	if ingredient != null:
		return ingredient.display_name
	return String(item_id)

func _build_row(item_id: StringName, label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()

	var label := Label.new()
	label.custom_minimum_size.x = 260
	label.text = label_text
	row.add_child(label)

	var give_button := Button.new()
	give_button.text = "Дати"
	give_button.pressed.connect(_on_give_pressed.bind(item_id))
	row.add_child(give_button)

	return row

func _on_give_pressed(item_id: StringName) -> void:
	if item_id != _visitor.desired_result_id:
		# Wrong guess — say so but don't waste the item, same "free to
		# experiment" reasoning as brewing/carving elsewhere.
		result_label.text = "Це не те, що мені треба..."
		return
	PlayerInventory.remove(item_id)
	if SigilDatabase.get_sigil(item_id) != null:
		CarvedSigilRegistry.take_instance(item_id)
	_resolve(true)

func _on_take_pressed() -> void:
	PlayerInventory.add(_visitor.offers_item_id, 1)
	_resolve(true)

func _on_send_away_pressed() -> void:
	_resolve(false)

func _on_wait_pressed() -> void:
	visible = false
	wait_requested.emit(_visitor)

func _resolve(satisfied: bool) -> void:
	_resolved = true
	result_label.text = _visitor.satisfied_text if satisfied else _visitor.unhelped_text
	_rebuild_item_list()

func _on_finish_pressed() -> void:
	visible = false
	closed.emit()
