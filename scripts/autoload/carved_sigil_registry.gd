extends Node
## Autoload. Tracks each individual carved sigil's actual traced stroke,
## separate from PlayerInventory's plain id->count, which stays the
## source of truth for "how many do I have" (recipe/give-flow checks
## keep working unchanged). This registry exists purely so each carved
## object can be *displayed* as what the player actually carved instead
## of a generic template — see CarvedSigilInstance.
##
## Every sigil currently only enters the game through CarvingUI's
## success path, which keeps this in sync with PlayerInventory itself
## (add_instance alongside PlayerInventory.add, take_instance alongside
## PlayerInventory.remove). If another path ever grants a sigil without
## going through carving, it just won't have a stroke to show here —
## no reconciliation logic exists for that yet since it can't happen today.

var _instances: Dictionary = {} # StringName -> Array[CarvedSigilInstance]

func add_instance(sigil_id: StringName, stroke_points: PackedVector2Array) -> void:
	if not _instances.has(sigil_id):
		_instances[sigil_id] = []
	var instance := CarvedSigilInstance.new()
	instance.sigil_id = sigil_id
	instance.stroke_points = stroke_points
	_instances[sigil_id].append(instance)

## Removes and returns one instance of this sigil (whichever's handiest —
## which physical one you hand over doesn't matter). Null if none held.
func take_instance(sigil_id: StringName) -> CarvedSigilInstance:
	var list: Array = _instances.get(sigil_id, [])
	if list.is_empty():
		return null
	return list.pop_back()

func peek_instances(sigil_id: StringName) -> Array:
	return _instances.get(sigil_id, [])
