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
## file only has one variant's pendant drawn somewhere in it, the rest is
## empty) rather than tightly cropped to the block itself. Drawing the
## raw texture verbatim squishes the actual pendant into a corner. Measured
## once per texture at load time instead — same reasoning as Visitor's
## offline-measured waiting_portrait_content_rect, except this can be done
## at runtime since it's a flat white background, not a translucent haze.
const WHITE_THRESHOLD := 0.97 ## 0..1 (Color channel scale); anything lighter counts as background.
const SCAN_STRIDE := 4 ## px; coarse sample, plenty for a bounding box.

## Each block is a wood disc with a thin rope loop knotted through a hole
## near its top. Tried excluding the rope from content_rect entirely (a
## plain bounding box pulls its corner out, off-center) by keeping only
## rows/columns wide enough to be the disc's own body — but the rope's
## thick knot, right where it meets the disc, is wide enough to partly
## pass that test too, so the crop caught half the rope and cut it off
## mid-coil instead of cleanly excluding or including it. Simpler and
## better-looking to just show the whole pendant, rope included, scaled
## to fit without distortion (see CarvingCanvas/SigilIcon) — nothing gets
## cut off mid-shape that way.
##
## grain_rect below is kept separately, purely so the carving guide lands
## on smooth engravable wood — not the disc's own bark rim, which a plain
## "is this part of the disc" test (used for the old disc-only attempt)
## can't tell apart from the grain, since bark is just a darker patch of
## the same disc. Classifies by brightness instead (the grain reads
## noticeably lighter than the bark ring around it) and keeps only rows/
## columns with a wide enough run of it to be the grain's own body, same
## shape of test as before, just seeded from a stricter color check.
const BODY_EXTENT_FRACTION := 0.4
const GRAIN_LUMINANCE_THRESHOLD := 0.667 ## 0..1; grain reads lighter than the bark ring around it.
## Extra uniform shrink on top of the measured grain body — the
## brightness classifier is noisy around tree-ring lines and bark
## highlights, so this errs toward a smaller guide that's confidently on
## wood over a bigger one that risks the bark edge.
const GRAIN_SAFETY_SHRINK := 0.8

class BlockVariant:
	var texture: Texture2D
	var content_rect: Rect2 ## normalized 0..1 — whole pendant (rope + disc), for display.
	var grain_rect: Rect2 ## normalized 0..1 — smooth wood surface only, for guide placement.

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
			var loaded := load(BLOCK_TEXTURES_DIR + file_name)
			if loaded is Texture2D:
				var tex: Texture2D = loaded
				var image: Image = tex.get_image()
				var variant := BlockVariant.new()
				variant.texture = tex
				variant.content_rect = _measure_full_bbox(image)
				variant.grain_rect = _measure_grain_body(image)
				_block_variants.append(variant)
		file_name = dir.get_next()
	dir.list_dir_end()

## Plain bounding box of every non-white pixel — the whole pendant.
func _measure_full_bbox(image: Image) -> Rect2:
	var w := image.get_width()
	var h := image.get_height()
	var min_x := w
	var min_y := h
	var max_x := -1
	var max_y := -1
	var y := 0
	while y < h:
		var x := 0
		while x < w:
			var c := image.get_pixel(x, y)
			if c.a > 0.05 and not (c.r > WHITE_THRESHOLD and c.g > WHITE_THRESHOLD and c.b > WHITE_THRESHOLD):
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
			x += SCAN_STRIDE
		y += SCAN_STRIDE
	if max_x < 0:
		return Rect2(0, 0, 1, 1) # nothing found (shouldn't happen) — fall back to uncropped.
	return Rect2(float(min_x) / w, float(min_y) / h, float(max_x - min_x) / w, float(max_y - min_y) / h)

## Widest row / tallest column of grain-bright pixels (the smooth wood's
## own cross-section) — only rows/columns with a run at least
## BODY_EXTENT_FRACTION of that peak count, same reasoning as the old
## disc-vs-rope test but seeded from a brightness check instead of a
## plain non-white one, so it separates the light grain from the darker
## bark ring around it too. Finished off with a uniform shrink
## (GRAIN_SAFETY_SHRINK) since tree-ring lines and bark highlights make
## the brightness read noisy right at the true edge.
func _measure_grain_body(image: Image) -> Rect2:
	var w := image.get_width()
	var h := image.get_height()

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
			var is_white := c.r > WHITE_THRESHOLD and c.g > WHITE_THRESHOLD and c.b > WHITE_THRESHOLD
			var luminance := (c.r + c.g + c.b) / 3.0
			if c.a > 0.05 and not is_white and luminance > GRAIN_LUMINANCE_THRESHOLD:
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
		return Rect2(0, 0, 1, 1)

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

	var raw_rect := Rect2(float(min_x) / w, float(min_y) / h, float(max_x - min_x) / w, float(max_y - min_y) / h)
	var shrunk_size := raw_rect.size * GRAIN_SAFETY_SHRINK
	return Rect2(raw_rect.position + (raw_rect.size - shrunk_size) / 2.0, shrunk_size)

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
