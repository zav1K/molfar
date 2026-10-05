extends Node
## Autoload. Which ingredient (if any) hangs on each hook above the door,
## and whether each hung ward reacts to a knocking visitor's hidden nature.
## Persists like PlayerInventory — this is the player's protective setup,
## not scene-local state.

signal changed(slot_index: int)

const SLOT_COUNT := 3
## Chance a correctly-matched ward actually gives a signal. Deliberately
## short of certain — silence never confirms "human" and a signal never
## confirms "not human" on its own.
const SIGNAL_CHANCE := 0.6

var _slots: Array[StringName] = []

func _ready() -> void:
	_slots.resize(SLOT_COUNT)
	_slots.fill(&"")

func hang(slot_index: int, ingredient_id: StringName) -> void:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return
	_slots[slot_index] = ingredient_id
	changed.emit(slot_index)

func clear_slot(slot_index: int) -> void:
	hang(slot_index, &"")

func get_slot(slot_index: int) -> StringName:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return &""
	return _slots[slot_index]

## Rolls every hung ward against a visitor's hidden nature. Returns the
## ambiguous hint text for each ward that reacted — an empty result does
## NOT mean the visitor is safe, since SIGNAL_CHANCE is under 1.
func check_visitor(visitor: Visitor) -> Array[String]:
	var hints: Array[String] = []
	for ingredient_id in _slots:
		if ingredient_id == &"":
			continue
		var ingredient := IngredientDatabase.get_ingredient(ingredient_id)
		if ingredient == null or ingredient.ward_threat == Threat.Type.NONE:
			continue
		if ingredient.ward_threat == visitor.true_threat and randf() < SIGNAL_CHANCE:
			hints.append(ingredient.ward_hint_text)
	return hints

func save_state() -> Array:
	var out: Array = []
	for ingredient_id in _slots:
		out.append(String(ingredient_id))
	return out

func load_state(data: Array) -> void:
	for i in SLOT_COUNT:
		var ingredient_id: StringName = StringName(data[i]) if i < data.size() else &""
		_slots[i] = ingredient_id
		changed.emit(i)

## Burns the first hung ward that counters this visitor, returning the
## ingredient id that was lost (or &"" if nothing on the rack matched).
## For the visitors that destroy the protection on their way in — the
## ward did its job and was spent doing it, which also means the next
## one of these gets no warning. See Visitor.invited_destroys_ward.
func consume_against(visitor: Visitor) -> StringName:
	if visitor.true_threat == Threat.Type.NONE:
		return &""
	for i in SLOT_COUNT:
		var ingredient_id := _slots[i]
		if ingredient_id == &"":
			continue
		var ingredient := IngredientDatabase.get_ingredient(ingredient_id)
		if ingredient != null and ingredient.ward_threat == visitor.true_threat:
			clear_slot(i)
			return ingredient_id
	return &""
