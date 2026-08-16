class_name CarvingCanvas
extends Control
## Trace-the-symbol carving gesture: a target sigil's stroke path is shown
## as a faint guide; the player holds and drags the mouse to trace it in
## one continuous stroke. On release both paths are resampled to the same
## point count and compared — average deviation plus how much of the
## guide was actually covered decide carving quality (read by
## carving_ui.gd, same spirit as stir_cauldron.gd's rotation/evenness
## split for brewing).

## normalized_stroke: the player's own traced path, 0..1 unit square —
## same space as Sigil.path_points, kept for whatever ends up carved
## (see CarvedSigilRegistry) so it displays as what THIS attempt drew.
signal finished(avg_error: float, coverage: float, normalized_stroke: PackedVector2Array)

const RESAMPLE_COUNT := 40
const MIN_COVERAGE_TO_COUNT := 0.15 ## below this, a release is a misclick, not an attempt.
const MIN_POINT_SPACING := 3.0 ## px; drops points closer than this to keep arrays small.

var _target_sigil: Sigil
var _target_path: PackedVector2Array # in local pixel space
var _target_length: float = 0.0
var _drawn_points: PackedVector2Array
var _drawing: bool = false
var _background_block: CarvedSigilRegistry.BlockVariant

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func start(sigil: Sigil) -> void:
	_target_sigil = sigil
	# Just a preview of what carving generally looks like — the block an
	# actual success lands on is picked independently (see
	# CarvedSigilRegistry.add_instance), so this can differ from the
	# result. Better than showing no wood at all while tracing.
	_background_block = CarvedSigilRegistry.get_random_block_variant()
	# Sigil.path_points are authored against a square "disc surface", but
	# the drawn background is the whole pendant (rope included, see
	# _draw()) — mapping path_points onto the full pendant would land
	# some of them on the rope instead of the disc. Map onto disc_dest,
	# the disc's own sub-region within the rendered pendant, instead.
	#
	# Scaled *uniformly* (not stretched independently per axis) so the
	# pattern's own proportions stay the same shape on every block variant
	# — some discs are round, some noticeably more triangular/oval, and a
	# non-uniform stretch to exactly fill each one's differently-shaped
	# disc_rect warped the same zigzag into a visibly different shape
	# depending on which pendant it landed on.
	var dest := _disc_dest_rect()
	var pattern_scale: float = minf(dest.size.x, dest.size.y)
	var pattern_center := dest.position + dest.size / 2.0
	_target_path.clear()
	for p in sigil.path_points:
		_target_path.append(pattern_center + (p - Vector2(0.5, 0.5)) * pattern_scale)
	_target_length = _path_length(_target_path)
	_drawn_points.clear()
	_drawing = false
	queue_redraw()

## Where the block's content_rect (the whole pendant) lands once scaled
## uniformly (preserving its own proportions) and centered in this
## control — used by _draw() to actually paint it there.
func _block_dest_rect() -> Rect2:
	if _background_block == null:
		return Rect2(Vector2.ZERO, size)
	var tex_size := _background_block.texture.get_size()
	var content_px := _background_block.content_rect.size * tex_size
	var block_scale: float = minf(size.x / content_px.x, size.y / content_px.y)
	var dest_size := content_px * block_scale
	return Rect2((size - dest_size) / 2.0, dest_size)

## Where disc_rect (just the disc, excluding the rope) lands within the
## rendered pendant — content_rect and disc_rect share the same texture,
## so disc_rect's position as a fraction *of content_rect* carries over
## directly onto _block_dest_rect() without a separate scale computation.
func _disc_dest_rect() -> Rect2:
	if _background_block == null:
		return Rect2(Vector2.ZERO, size)
	var content_rect := _background_block.content_rect
	var disc_rect := _background_block.disc_rect
	var local := Rect2(
		(disc_rect.position - content_rect.position) / content_rect.size,
		disc_rect.size / content_rect.size)
	var bg := _block_dest_rect()
	return Rect2(bg.position + local.position * bg.size, local.size * bg.size)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_drawing = true
			_drawn_points.clear()
			_drawn_points.append(mb.position)
			queue_redraw()
		elif _drawing:
			_drawing = false
			_on_release()
	elif event is InputEventMouseMotion and _drawing:
		var mm := event as InputEventMouseMotion
		if _drawn_points.is_empty() or _drawn_points[-1].distance_to(mm.position) >= MIN_POINT_SPACING:
			_drawn_points.append(mm.position)
			queue_redraw()

func _on_release() -> void:
	var drawn_length := _path_length(_drawn_points)
	var coverage := 0.0 if _target_length <= 0.0 else clampf(drawn_length / _target_length, 0.0, 1.0)
	if coverage < MIN_COVERAGE_TO_COUNT:
		# Not a real attempt (misclick/twitch) — let the player try again for free.
		_drawn_points.clear()
		queue_redraw()
		return
	var resampled_target := _resample(_target_path, RESAMPLE_COUNT)
	var resampled_drawn := _resample(_drawn_points, RESAMPLE_COUNT)
	var total_error := 0.0
	for i in RESAMPLE_COUNT:
		total_error += resampled_target[i].distance_to(resampled_drawn[i])
	var normalized_stroke := PackedVector2Array()
	normalized_stroke.resize(_drawn_points.size())
	for i in _drawn_points.size():
		normalized_stroke[i] = _drawn_points[i] / size
	finished.emit(total_error / RESAMPLE_COUNT, coverage, normalized_stroke)

func _draw() -> void:
	if _background_block != null:
		# content_rect isn't square (the disc is taller than it is wide),
		# so stretching it to fill this square canvas would distort the
		# disc into a rounder shape than it actually is, on top of
		# leaving its bounding box's own transparent corners visible.
		# _block_dest_rect() scales it uniformly instead (a "contain" fit)
		# so the disc keeps its real proportions, letterboxed on two
		# sides rather than stretched into all four corners; a solid
		# backing first closes both the letterbox bars and the disc's
		# own transparent corners so the panel's translucent background
		# doesn't show through.
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.05, 0.05, 0.85))
		var tex := _background_block.texture
		var tex_size := tex.get_size()
		var rect := _background_block.content_rect
		var src := Rect2(rect.position * tex_size, rect.size * tex_size)
		draw_texture_rect_region(tex, _block_dest_rect(), src)
	if _target_path.size() >= 2:
		# The old warm tan guide was close enough to the wood's own light
		# grain color to nearly disappear against it. A cool, high-contrast
		# color reads clearly against warm wood regardless of how light or
		# dark that particular patch of grain is; a dark outline underneath
		# guarantees contrast against the lightest parts too.
		draw_polyline(_target_path, Color(0, 0, 0, 0.45), 5.0, true)
		draw_polyline(_target_path, Color(0.3, 0.8, 1.0, 0.95), 2.5, true)
		for p in _target_path:
			draw_circle(p, 5.0, Color(0, 0, 0, 0.45))
			draw_circle(p, 3.5, Color(0.3, 0.8, 1.0, 0.95))
	if _drawn_points.size() >= 2:
		draw_polyline(_drawn_points, Color(0.95, 0.85, 0.4, 0.9), 3.0, true)

func _path_length(points: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, points.size()):
		total += points[i - 1].distance_to(points[i])
	return total

## Resamples a polyline to exactly n points evenly spaced along its
## arc-length. Used to compare two paths of different point counts.
func _resample(points: PackedVector2Array, n: int) -> PackedVector2Array:
	var result := PackedVector2Array()
	result.resize(n)
	if points.size() < 2:
		var fallback: Vector2 = points[0] if points.size() == 1 else Vector2.ZERO
		for i in n:
			result[i] = fallback
		return result

	var cumulative := PackedFloat32Array()
	cumulative.append(0.0)
	var total := 0.0
	for i in range(1, points.size()):
		total += points[i - 1].distance_to(points[i])
		cumulative.append(total)

	var seg := 0
	for i in n:
		var target_dist: float = total * float(i) / float(n - 1)
		while seg < points.size() - 2 and cumulative[seg + 1] < target_dist:
			seg += 1
		var seg_len: float = cumulative[seg + 1] - cumulative[seg]
		var t: float = 0.0 if seg_len <= 0.0 else (target_dist - cumulative[seg]) / seg_len
		result[i] = points[seg].lerp(points[seg + 1], t)
	return result
