extends Node
## Autoload. Loads every Keepsake resource from data/keepsakes/ and indexes it by id.

const KEEPSAKES_DIR := "res://data/keepsakes/"

var _keepsakes: Dictionary = {} # StringName -> Keepsake

func _ready() -> void:
	_load_all()

func _load_all() -> void:
	var dir := DirAccess.open(KEEPSAKES_DIR)
	if dir == null:
		push_warning("KeepsakeDatabase: cannot open %s" % KEEPSAKES_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res := load(KEEPSAKES_DIR + file_name)
			if res is Keepsake:
				_keepsakes[res.id] = res
		file_name = dir.get_next()
	dir.list_dir_end()

func get_keepsake(id: StringName) -> Keepsake:
	return _keepsakes.get(id)

func get_all() -> Array:
	return _keepsakes.values()
