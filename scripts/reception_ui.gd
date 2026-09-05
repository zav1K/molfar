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
## A visitor with neither desired_result_id nor offers_item_id (e.g.
## drowned_woman_night, forest_warden) isn't asking for anything material
## at all — being invited in and heard out is the whole interaction, so
## the give-list is replaced with a single "Вислухати" button instead.
##
## Once satisfied, whatever the visitor was already offering (payment_type)
## is granted automatically — voluntary thanks, not a price (see
## CONCEPT.md). DemandMoneyButton is the one deliberate override: pressuring
## someone into money instead of what they actually offered nudges
## PathBalance toward the black path, whether or not they had anything to
## give in the first place.
##
## A visitor can also carry its own PathBalance weight independent of
## money (satisfied_path_shift/unhelped_path_shift — e.g. mara_night: help
## her and it costs something, refuse her and that's worth something too),
## and, rarer still, a post-resolution choice (choice_prompt and friends)
## for the one "thank you" that deserves an actual response instead of
## just closing the window — see _on_choice_a_pressed/_on_choice_b_pressed.

signal closed
signal wait_requested(visitor: Visitor)

const DEMAND_MONEY_ITEM_ID := &"groshi"
const ICON_SIZE := Vector2(64, 64)
## Sigil pendant art is consistently portrait (~0.6 width/height, rope
## included) — a square box leaves it small with wide empty margins on
## both sides. Same rough area as ICON_SIZE, shaped to match instead.
const SIGIL_ICON_SIZE := Vector2(50, 82)
const TILE_WIDTH := 130.0

@onready var portrait: TextureRect = $Panel/Portrait
@onready var name_label: Label = $Panel/NameLabel
@onready var problem_label: Label = $Panel/ProblemLabel
@onready var item_list: GridContainer = $Panel/ItemListScroll/ItemList
@onready var take_button: Button = $Panel/TakeButton
@onready var send_away_button: Button = $Panel/SendAwayButton
@onready var wait_button: Button = $Panel/WaitButton
@onready var result_label: Label = $Panel/ResultLabel
@onready var demand_money_button: Button = $Panel/DemandMoneyButton
@onready var finish_button: Button = $Panel/FinishButton
@onready var listen_button: Button = $Panel/ListenButton
@onready var choice_prompt_label: Label = $Panel/ChoicePromptLabel
@onready var choice_a_button: Button = $Panel/ChoiceAButton
@onready var choice_b_button: Button = $Panel/ChoiceBButton

var _visitor: Visitor
var _resolved: bool = false
var _satisfied: bool = false
var _payment_settled: bool = false ## true once the natural (or demanded) payment has been granted
var _choice_made: bool = false ## true once choice_a/b picked, for a visitor that has one at all

func _ready() -> void:
	visible = false
	take_button.pressed.connect(_on_take_pressed)
	send_away_button.pressed.connect(_on_send_away_pressed)
	wait_button.pressed.connect(_on_wait_pressed)
	demand_money_button.pressed.connect(_on_demand_money_pressed)
	finish_button.pressed.connect(_on_finish_pressed)
	listen_button.pressed.connect(_on_listen_pressed)
	choice_a_button.pressed.connect(_on_choice_a_pressed)
	choice_b_button.pressed.connect(_on_choice_b_pressed)

func show_visitor(visitor: Visitor) -> void:
	_visitor = visitor
	_resolved = false
	_satisfied = false
	_payment_settled = false
	_choice_made = false
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
	# Awaiting a post-resolution choice takes over the Finish/DemandMoney
	# row entirely until it's answered — see class doc.
	var awaiting_choice := _resolved and _satisfied and _visitor.choice_prompt != "" and not _choice_made
	send_away_button.visible = not _resolved
	wait_button.visible = not _resolved
	finish_button.visible = _resolved and not awaiting_choice
	take_button.visible = not _resolved and _visitor.offers_item_id != &""
	listen_button.visible = not _resolved and _visitor.offers_item_id == &"" and _visitor.desired_result_id == &""
	demand_money_button.visible = _resolved and _satisfied and not _payment_settled and _visitor.payment_type != Visitor.PaymentType.MONEY and not awaiting_choice
	choice_prompt_label.visible = awaiting_choice
	choice_a_button.visible = awaiting_choice
	choice_b_button.visible = awaiting_choice
	if awaiting_choice:
		choice_prompt_label.text = _visitor.choice_prompt
		choice_a_button.text = _visitor.choice_a_label
		choice_b_button.text = _visitor.choice_b_label
	if _resolved:
		return
	if _visitor.offers_item_id != &"":
		# Reversed direction — they're handing something to the player, not
		# asking for one, so the normal give-list doesn't apply here.
		take_button.text = "Взяти: %s" % _item_display_name(_visitor.offers_item_id)
		return
	if _visitor.desired_result_id == &"":
		# Nothing material to give or take — listen_button covers this case.
		return
	for potion in PotionDatabase.get_all():
		var count := PlayerInventory.get_count(potion.id)
		if count > 0:
			var icon_node := _make_icon_node(potion.icon)
			item_list.add_child(_build_give_tile(icon_node, "%s (є %d)" % [potion.display_name, count], potion.id))
	for sigil in SigilDatabase.get_all():
		var count := PlayerInventory.get_count(sigil.id)
		if count > 0:
			# Whichever physical instance happens to be first — which one
			## gets shown doesn't matter, same reasoning as take_instance()
			# picking "whichever's handiest" when the give actually happens.
			var instances := CarvedSigilRegistry.peek_instances(sigil.id)
			var icon_node := _make_sigil_icon_node(sigil, instances[0]) if not instances.is_empty() else _make_icon_node(null)
			item_list.add_child(_build_give_tile(icon_node, "%s (є %d)" % [sigil.display_name, count], sigil.id))

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

## Both dimensions get shrink-to-center explicitly — a GridContainer row
## stretches every cell to the tallest one in that row (varying label
## line-wrap heights), and a plain icon left to SIZE_FILL vertically
## would get stretched tall along with it, distorting square art.
func _make_icon_node(icon_texture: Texture2D) -> Control:
	if icon_texture == null:
		var swatch := ColorRect.new()
		swatch.color = Color(0.35, 0.3, 0.25)
		swatch.custom_minimum_size = ICON_SIZE
		swatch.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return swatch
	var icon := TextureRect.new()
	icon.texture = icon_texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = ICON_SIZE
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return icon

func _make_sigil_icon_node(sigil: Sigil, instance: CarvedSigilInstance) -> Control:
	var icon := SigilIcon.new()
	icon.custom_minimum_size = SIGIL_ICON_SIZE
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.setup(sigil, instance)
	return icon

func _build_give_tile(icon_node: Control, label_text: String, item_id: StringName) -> VBoxContainer:
	var tile := VBoxContainer.new()
	tile.custom_minimum_size.x = TILE_WIDTH
	tile.add_child(icon_node)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = TILE_WIDTH
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_font_size_override("font_size", 12)
	tile.add_child(label)

	var give_button := Button.new()
	give_button.text = "Дати"
	give_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	give_button.pressed.connect(_on_give_pressed.bind(item_id))
	tile.add_child(give_button)

	return tile

func _on_give_pressed(item_id: StringName) -> void:
	var matches := item_id == _visitor.desired_result_id \
		or (_visitor.alt_desired_result_id != &"" and item_id == _visitor.alt_desired_result_id)
	if not matches:
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

func _on_listen_pressed() -> void:
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
	var shift := _visitor.satisfied_path_shift if satisfied else _visitor.unhelped_path_shift
	if shift != 0:
		PathBalance.shift(shift)
	_rebuild_item_list()

func _on_choice_a_pressed() -> void:
	_apply_choice(_visitor.choice_a_response, _visitor.choice_a_path_shift)

func _on_choice_b_pressed() -> void:
	_apply_choice(_visitor.choice_b_response, _visitor.choice_b_path_shift)

func _apply_choice(response: String, shift: int) -> void:
	_choice_made = true
	if response != "":
		result_label.text += "\n\n%s" % response
	if shift != 0:
		PathBalance.shift(shift)
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
