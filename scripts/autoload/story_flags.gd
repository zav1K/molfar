extends Node
## Autoload. The story threads the player has actually touched — set
## when a visitor pays in information (see Visitor.payment_flag_id), when
## one crosses the threshold (invited_sets_flag), or by any scripted
## beat. Read by GrimoireUI's diary, by the closing chronicle, by the
## priest's day 7 variants, and by every visitor with a required_flag.
##
## Each flag remembers the chapter day it was set on, so the diary can
## date its entries — the same reason a real one would. Nothing else
## cares about the day, but it costs one int and it is the difference
## between a list of notes and a journal.

var _flags: Dictionary = {} # StringName -> int (chapter day it was set on)

func set_flag(id: StringName) -> void:
	if id == &"":
		return
	# First time wins: a flag re-set later is still the day it happened.
	if not _flags.has(id):
		_flags[id] = GameCalendar.current_day

func has_flag(id: StringName) -> bool:
	return _flags.has(id)

## The chapter day this flag was set on, or 0 if it isn't set — and also
## 0 for a flag restored from a save written before days were recorded.
func get_flag_day(id: StringName) -> int:
	return int(_flags.get(id, 0))

## Saved as id -> day.
func save_state() -> Dictionary:
	var out := {}
	for id in _flags:
		out[String(id)] = _flags[id]
	return out

## Takes either shape: a dictionary of id -> day, or the flat array of
## ids that older saves hold, which restores the flags with no day
## attached rather than refusing the save over a cosmetic field.
func load_state(data: Variant) -> void:
	_flags.clear()
	if data is Dictionary:
		for id in data:
			_flags[StringName(id)] = int(data[id])
	elif data is Array:
		for id in data:
			_flags[StringName(id)] = 0
