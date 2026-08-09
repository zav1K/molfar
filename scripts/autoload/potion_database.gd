extends Node
## Autoload. Loads every Potion resource from data/potions/ and indexes it by id.

const POTIONS_DIR := "res://data/potions/"

var _potions: Dictionary = {} # StringName -> Potion

func _ready() -> void:
	_load_all()

func _load_all() -> void:
	var dir := DirAccess.open(POTIONS_DIR)
	if dir == null:
		push_warning("PotionDatabase: cannot open %s" % POTIONS_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res := load(POTIONS_DIR + file_name)
			if res is Potion:
				_potions[res.id] = res
		file_name = dir.get_next()
	dir.list_dir_end()

func get_potion(id: StringName) -> Potion:
	return _potions.get(id)

func get_all() -> Array:
	return _potions.values()
