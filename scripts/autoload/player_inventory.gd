extends Node
## Autoload. Tracks how many of each ingredient the player currently holds.
## Drives visuals that mirror game state (e.g. drying herb bundles on the beam).

signal changed(ingredient_id: StringName)

var _counts: Dictionary = {} # StringName -> int

func add(ingredient_id: StringName, amount: int = 1) -> void:
	_counts[ingredient_id] = get_count(ingredient_id) + amount
	changed.emit(ingredient_id)

func remove(ingredient_id: StringName, amount: int = 1) -> void:
	var left := get_count(ingredient_id) - amount
	if left <= 0:
		_counts.erase(ingredient_id)
	else:
		_counts[ingredient_id] = left
	changed.emit(ingredient_id)

func get_count(ingredient_id: StringName) -> int:
	return _counts.get(ingredient_id, 0)

func has(ingredient_id: StringName) -> bool:
	return get_count(ingredient_id) > 0

func get_held_ids() -> Array:
	return _counts.keys()

## JSON-friendly snapshot for SaveGame (String keys, not StringName —
## JSON has no StringName, and keys come back as plain String anyway).
func save_state() -> Dictionary:
	var out := {}
	for id in _counts:
		out[String(id)] = _counts[id]
	return out

func load_state(data: Dictionary) -> void:
	_counts.clear()
	for id in data:
		_counts[StringName(id)] = int(data[id])
		changed.emit(StringName(id))
