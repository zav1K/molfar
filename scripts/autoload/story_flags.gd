extends Node
## Autoload. A flat set of story-thread flags, set when a visitor pays in
## information (see Visitor.payment_flag_id) or by any future dialogue/
## quest beat. Nothing reads these yet — this is just the hook so those
## payments aren't lost the moment they're set, ready for whichever
## future story content checks them.

var _flags: Dictionary = {} # StringName -> true

func set_flag(id: StringName) -> void:
	if id == &"":
		return
	_flags[id] = true

func has_flag(id: StringName) -> bool:
	return _flags.get(id, false)
