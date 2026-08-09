extends Node
## Autoload. Loads every Sigil resource from data/sigils/ and indexes it by id.

const SIGILS_DIR := "res://data/sigils/"

var _sigils: Dictionary = {} # StringName -> Sigil

func _ready() -> void:
	_load_all()

func _load_all() -> void:
	var dir := DirAccess.open(SIGILS_DIR)
	if dir == null:
		push_warning("SigilDatabase: cannot open %s" % SIGILS_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res := load(SIGILS_DIR + file_name)
			if res is Sigil:
				_sigils[res.id] = res
		file_name = dir.get_next()
	dir.list_dir_end()

func get_sigil(id: StringName) -> Sigil:
	return _sigils.get(id)

func get_all() -> Array:
	return _sigils.values()
