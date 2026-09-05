extends Node
## Autoload. Loads every Visitor resource from data/visitors/ (and its
## special/ subfolder — scripted story beats, see below) and hands out
## random picks for the door to knock with — each one at most once per
## reset_seen() call (see that function) so the same face doesn't knock
## twice in a row. hut.gd calls reset_seen() on every day/night phase
## flip (see GameCalendar), allowing repeat visits again, per
## CONCEPT.md's "постійні клієнти" — just not within the same phase.
##
## data/visitors/special/ holds one-time story beats (gated by
## required_flag/knocked_sets_flag on Visitor) rather than ordinary
## repeating clients — kept in their own subfolder just so they're easy
## to tell apart from the regular rotation while browsing the data.

const VISITORS_DIR := "res://data/visitors/"
const SPECIAL_VISITORS_DIR := "res://data/visitors/special/"

var _visitors: Array[Visitor] = []
var _seen: Array[Visitor] = []

func _ready() -> void:
	_load_dir(VISITORS_DIR)
	_load_dir(SPECIAL_VISITORS_DIR)

func _load_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("VisitorDatabase: cannot open %s" % path)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res := load(path + file_name)
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
##
## Story-gated visitors (required_flag set) are additionally filtered
## to those whose flag is already set, and a story visitor whose own
## knocked_sets_flag is already set is excluded outright — their beat
## already happened once, it doesn't repeat like an ordinary client's.
## knocked_sets_flag itself is set here, the moment they're picked —
## same "seen at the door is enough" reasoning as problem_text playing
## regardless of invite/refuse.
func get_random(night: bool) -> Visitor:
	var available := _visitors.filter(func(v: Visitor) -> bool:
		return v.night_visitor == night and not _seen.has(v) \
			and (v.required_flag == &"" or StoryFlags.has_flag(v.required_flag)) \
			and (v.knocked_sets_flag == &"" or not StoryFlags.has_flag(v.knocked_sets_flag)))
	if available.is_empty():
		return null
	var visitor: Visitor = available[randi() % available.size()]
	_seen.append(visitor)
	if visitor.knocked_sets_flag != &"":
		StoryFlags.set_flag(visitor.knocked_sets_flag)
	return visitor

## Clears the seen-list so everyone can knock again — called by hut.gd
## on every day/night phase flip.
func reset_seen() -> void:
	_seen.clear()
