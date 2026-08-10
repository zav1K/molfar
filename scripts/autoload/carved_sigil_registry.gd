extends Node
## Autoload. Tracks each individual carved sigil's actual traced stroke
## and which wood-block variant it landed on, separate from
## PlayerInventory's plain id->count, which stays the source of truth
## for "how many do I have" (recipe/give-flow checks keep working
## unchanged). This registry exists purely so each carved object can be
## *displayed* as what the player actually carved instead of a generic
## template — see CarvedSigilInstance.
##
## Every sigil currently only enters the game through CarvingUI's
## success path, which keeps this in sync with PlayerInventory itself
## (add_instance alongside PlayerInventory.add, take_instance alongside
## PlayerInventory.remove). If another path ever grants a sigil without
## going through carving, it just won't have a stroke to show here —
## no reconciliation logic exists for that yet since it can't happen today.

const BLOCK_TEXTURES_DIR := "res://assets/hut/sigil_blocks/"

var _instances: Dictionary = {} # StringName -> Array[CarvedSigilInstance]
var _block_textures: Array[Texture2D] = []

func _ready() -> void:
	_load_block_textures()

func _load_block_textures() -> void:
	var dir := DirAccess.open(BLOCK_TEXTURES_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and (file_name.ends_with(".png") or file_name.ends_with(".PNG")):
			var tex := load(BLOCK_TEXTURES_DIR + file_name)
			if tex is Texture2D:
				_block_textures.append(tex)
		file_name = dir.get_next()
	dir.list_dir_end()

func add_instance(sigil_id: StringName, stroke_points: PackedVector2Array) -> void:
	if not _instances.has(sigil_id):
		_instances[sigil_id] = []
	var instance := CarvedSigilInstance.new()
	instance.sigil_id = sigil_id
	instance.stroke_points = stroke_points
	instance.block_texture = _pick_random_block()
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

func _pick_random_block() -> Texture2D:
	if _block_textures.is_empty():
		return null
	return _block_textures[randi() % _block_textures.size()]
