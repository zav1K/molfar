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
