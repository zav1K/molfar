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

## The uploaded block art turned out to be saved on an oversized blank
## white canvas (looks like an unintentional sprite-sheet export — each
## file only has one variant's disc drawn somewhere in it, the rest is
## empty) rather than tightly cropped to the block itself. Drawing the
## raw texture verbatim squishes the actual disc into a corner. Measured
## once per texture at load time instead — same reasoning as Visitor's
## offline-measured waiting_portrait_content_rect, except this can be done
## at runtime since it's a flat white background, not a translucent haze.
const WHITE_THRESHOLD := 0.97 ## 0..1 (Color channel scale); anything lighter counts as background.
const SCAN_STRIDE := 4 ## px; coarse sample, plenty for a bounding box.

## Each block is a wood disc with a thin rope loop knotted through a hole
## near its top — the rope leans off to one side, so a plain "bounding
## box of every non-white pixel" pulls that corner out to include it.
## Stretched to fill a square canvas, that squeezes/offsets the actual
## disc badly enough that the guide template no longer sits on it and
## the disc itself renders warped. Instead, measure the widest row and
## tallest column (the disc's own cross-section) and only count rows/
## columns whose extent is at least this fraction of that peak — the
## rope's rows/columns fall well short and get excluded, so the
## resulting rect tracks the disc's body, not the rope.
const BODY_EXTENT_FRACTION := 0.4

class BlockVariant:
	var texture: Texture2D
	var content_rect: Rect2 # normalized 0..1

var _instances: Dictionary = {} # StringName -> Array[CarvedSigilInstance]
var _block_variants: Array[BlockVariant] = []

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
				var variant := BlockVariant.new()
				variant.texture = tex
				variant.content_rect = _measure_content_rect(tex.get_image())
				_block_variants.append(variant)
		file_name = dir.get_next()
	dir.list_dir_end()

func _measure_content_rect(image: Image) -> Rect2:
	var w := image.get_width()
	var h := image.get_height()

	# Per-row and per-column non-white extent, sampled on the same grid.
	var row_min := PackedInt32Array()
	var row_max := PackedInt32Array()
	row_min.resize(h)
	row_max.resize(h)
	for i in h:
		row_min[i] = w
		row_max[i] = -1
	var col_min := PackedInt32Array()
	var col_max := PackedInt32Array()
	col_min.resize(w)
	col_max.resize(w)
	for i in w:
		col_min[i] = h
		col_max[i] = -1

	var y := 0
	while y < h:
		var x := 0
		while x < w:
			var c := image.get_pixel(x, y)
			if c.a > 0.05 and not (c.r > WHITE_THRESHOLD and c.g > WHITE_THRESHOLD and c.b > WHITE_THRESHOLD):
				row_min[y] = mini(row_min[y], x)
				row_max[y] = maxi(row_max[y], x)
				col_min[x] = mini(col_min[x], y)
				col_max[x] = maxi(col_max[x], y)
			x += SCAN_STRIDE
		y += SCAN_STRIDE

	var peak_row_width := 0
	for ry in h:
		if row_max[ry] >= 0:
			peak_row_width = maxi(peak_row_width, row_max[ry] - row_min[ry])
	var peak_col_height := 0
	for cx in w:
		if col_max[cx] >= 0:
			peak_col_height = maxi(peak_col_height, col_max[cx] - col_min[cx])
	if peak_row_width == 0 or peak_col_height == 0:
		return Rect2(0, 0, 1, 1) # nothing found (shouldn't happen) — fall back to uncropped.

	var row_threshold := peak_row_width * BODY_EXTENT_FRACTION
	var col_threshold := peak_col_height * BODY_EXTENT_FRACTION

	var min_y := h
	var max_y := -1
	for ry2 in h:
		if row_max[ry2] >= 0 and (row_max[ry2] - row_min[ry2]) >= row_threshold:
			min_y = mini(min_y, ry2)
			max_y = maxi(max_y, ry2)
	var min_x := w
	var max_x := -1
	for cx2 in w:
		if col_max[cx2] >= 0 and (col_max[cx2] - col_min[cx2]) >= col_threshold:
			min_x = mini(min_x, cx2)
			max_x = maxi(max_x, cx2)

	if max_x < 0 or max_y < 0:
		return Rect2(0, 0, 1, 1)
	return Rect2(float(min_x) / w, float(min_y) / h, float(max_x - min_x) / w, float(max_y - min_y) / h)

func add_instance(sigil_id: StringName, stroke_points: PackedVector2Array) -> void:
	if not _instances.has(sigil_id):
		_instances[sigil_id] = []
	var instance := CarvedSigilInstance.new()
	instance.sigil_id = sigil_id
	instance.stroke_points = stroke_points
	var variant := _pick_random_block()
	if variant != null:
		instance.block_texture = variant.texture
		instance.block_content_rect = variant.content_rect
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

## For CarvingCanvas's live-tracing background — a non-consuming random
## sample, distinct from the pick baked into an instance on a successful
## carve (which may land on a different variant).
func get_random_block_variant() -> BlockVariant:
	return _pick_random_block()

func _pick_random_block() -> BlockVariant:
	if _block_variants.is_empty():
		return null
	return _block_variants[randi() % _block_variants.size()]
