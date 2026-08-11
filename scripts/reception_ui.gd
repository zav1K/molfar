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
##
## Once satisfied, whatever the visitor was already offering (payment_type)
## is granted automatically — voluntary thanks, not a price (see
## CONCEPT.md). DemandMoneyButton is the one deliberate override: pressuring
## someone into money instead of what they actually offered nudges
## PathBalance toward the black path, whether or not they had anything to
## give in the first place.

signal closed
signal wait_requested(visitor: Visitor)

const DEMAND_MONEY_ITEM_ID := &"groshi"

@onready var portrait: TextureRect = $Panel/Portrait
@onready var name_label: Label = $Panel/NameLabel
@onready var problem_label: Label = $Panel/ProblemLabel
@onready var item_list: VBoxContainer = $Panel/ItemList
@onready var take_button: Button = $Panel/TakeButton
@onready var send_away_button: Button = $Panel/SendAwayButton
@onready var wait_button: Button = $Panel/WaitButton
@onready var result_label: Label = $Panel/ResultLabel
@onready var demand_money_button: Button = $Panel/DemandMoneyButton
@onready var finish_button: Button = $Panel/FinishButton

var _visitor: Visitor
var _resolved: bool = false
var _satisfied: bool = false
var _payment_settled: bool = false ## true once the natural (or demanded) payment has been granted

func _ready() -> void:
	visible = false
	take_button.pressed.connect(_on_take_pressed)
	send_away_button.pressed.connect(_on_send_away_pressed)
	wait_button.pressed.connect(_on_wait_pressed)
	demand_money_button.pressed.connect(_on_demand_money_pressed)
	finish_button.pressed.connect(_on_finish_pressed)

func show_visitor(visitor: Visitor) -> void:
	_visitor = visitor
	_resolved = false
	_satisfied = false
	_payment_settled = false
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
	demand_money_button.visible = _resolved and _satisfied and not _payment_settled and _visitor.payment_type != Visitor.PaymentType.MONEY
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
	_satisfied = satisfied
	result_label.text = _visitor.satisfied_text if satisfied else _visitor.unhelped_text
	if satisfied and _visitor.payment_flavor_text != "":
		result_label.text += "\n(%s)" % _visitor.payment_flavor_text
	if not satisfied and _visitor.refusal_loot_chance > 0.0 and randf() < _visitor.refusal_loot_chance:
		PlayerInventory.add(_visitor.refusal_loot_item_id, 1)
		result_label.text += "\n(Відходячи, лишає по собі щось із награбованого.)"
	_rebuild_item_list()

## Whatever they were already offering — deferred until Finish so
## DemandMoneyButton has a window to override it first.
func _grant_natural_payment() -> void:
	match _visitor.payment_type:
		Visitor.PaymentType.MATERIAL, Visitor.PaymentType.MONEY:
			if _visitor.payment_item_id != &"":
				PlayerInventory.add(_visitor.payment_item_id, _visitor.payment_amount)
			if _visitor.payment_is_deceptive:
				_steal_random_item()
		Visitor.PaymentType.INFORMATION:
			StoryFlags.set_flag(_visitor.payment_flag_id)
		Visitor.PaymentType.NOTHING:
			pass

## Looks like ordinary barter, but something else quietly disappears too
## — never what was just handed over, and only from what the player
## already had before this visit.
func _steal_random_item() -> void:
	var held := PlayerInventory.get_held_ids()
	held.erase(_visitor.payment_item_id)
	if held.is_empty():
		return
	var stolen_id: StringName = held[randi() % held.size()]
	PlayerInventory.remove(stolen_id, 1)

func _on_demand_money_pressed() -> void:
	PlayerInventory.add(DEMAND_MONEY_ITEM_ID, 1)
	PathBalance.shift(PathBalance.DEMAND_MONEY_SHIFT)
	_payment_settled = true
	result_label.text += "\n(Ти наполіг на платі грошима замість того, що пропонували.)"
	_rebuild_item_list()

func _on_finish_pressed() -> void:
	if _satisfied and not _payment_settled:
		_grant_natural_payment()
		_payment_settled = true
	visible = false
	closed.emit()
