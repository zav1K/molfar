extends Node
## Autoload. Loads every Visitor resource from data/visitors/ and hands
## out random picks for the door to knock with — each one at most once
## per reset_seen() call (see that function) so the same face doesn't
## knock twice in a row. hut.gd calls reset_seen() on every day/night
## phase flip (see GameCalendar), allowing repeat visits again, per
## CONCEPT.md's "постійні клієнти" — just not within the same phase.

const VISITORS_DIR := "res://data/visitors/"

var _visitors: Array[Visitor] = []
var _seen: Array[Visitor] = []

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

## Picks a visitor from the day or night rotation (per night_visitor)
## that hasn't knocked yet since the last reset_seen(). Returns null
## once everyone in that rotation's been seen — the door just stays
## quiet rather than repeating anyone within the same phase.
func get_random(night: bool) -> Visitor:
	var available := _visitors.filter(func(v: Visitor) -> bool: return v.night_visitor == night and not _seen.has(v))
	if available.is_empty():
		return null
	var visitor: Visitor = available[randi() % available.size()]
	_seen.append(visitor)
	return visitor

## Clears the seen-list so everyone can knock again — called by hut.gd
## on every day/night phase flip.
func reset_seen() -> void:
	_seen.clear()
