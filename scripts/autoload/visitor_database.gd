extends Node
## Autoload. Loads every Visitor resource from data/visitors/ and hands
## out random picks for the door to knock with.

const VISITORS_DIR := "res://data/visitors/"

var _visitors: Array[Visitor] = []

func _ready() -> void:
	_load_all()

func _load_all() -> void:
	var dir := DirAccess.open(VISITORS_DIR)
	if dir == null:
		push_warning("VisitorDatabase: cannot open %s" % VISITORS_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res := load(VISITORS_DIR + file_name)
			if res is Visitor:
				_visitors.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()

func get_all() -> Array[Visitor]:
	return _visitors

func get_random() -> Visitor:
	if _visitors.is_empty():
		return null
	return _visitors[randi() % _visitors.size()]
