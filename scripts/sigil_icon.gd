class_name SigilIcon
extends Control
## Renders one carved sigil the way that specific player actually
## carved it: the wood-block variant CarvedSigilRegistry randomly
## assigned it (or a flat color placeholder while no block art exists
## yet) with that object's own recorded stroke drawn on top — never the
## canonical path_points template. Two instances of the same symbol
## type can and will look different, in both block and line.

const WARD_COLOR := Color(0.82, 0.68, 0.35)
const CURSE_COLOR := Color(0.32, 0.08, 0.12)
const LINE_COLOR := Color(0.18, 0.1, 0.05, 0.9)

var _sigil: Sigil
var _instance: CarvedSigilInstance

func setup(sigil: Sigil, instance: CarvedSigilInstance) -> void:
	_sigil = sigil
	_instance = instance
	queue_redraw()

func _draw() -> void:
	if _sigil == null or _instance == null:
		return
	if _instance.block_texture != null:
		var tex_size := _instance.block_texture.get_size()
		var rect := _instance.block_content_rect
		var content_px := rect.size * tex_size
		# content_rect isn't square — stretching it to fill this square
		# icon would distort the round disc and leave its bounding box's
		# transparent corners visible (see CarvingCanvas, same fix).
		# Scale uniformly ("contain") and back-fill first so any
		# letterbox/corner gaps read as a clean border, not a see-through.
		var block_scale: float = minf(size.x / content_px.x, size.y / content_px.y)
		var dest_size := content_px * block_scale
		var content_rect := Rect2((size - dest_size) / 2.0, dest_size)
		draw_rect(Rect2(Vector2.ZERO, size), WARD_COLOR.darkened(0.85) if _sigil.kind == Sigil.Kind.WARD else CURSE_COLOR.darkened(0.85))
		var src := Rect2(rect.position * tex_size, content_px)
		draw_texture_rect_region(_instance.block_texture, content_rect, src)
	else:
		var color := WARD_COLOR if _sigil.kind == Sigil.Kind.WARD else CURSE_COLOR
		draw_rect(Rect2(Vector2.ZERO, size), color)

	var stroke_points := _instance.stroke_points
	if stroke_points.size() < 2:
		return
	# stroke_points are normalized against the full CarvingCanvas square
	# the player actually traced on (see carving_canvas.gd's _on_release),
	# not against content_rect's letterboxed sub-region — map onto this
	# icon's own full square the same way, independent of wherever the
	# (possibly different, randomly-assigned) pendant art landed.
	var scaled := PackedVector2Array()
	scaled.resize(stroke_points.size())
	for i in stroke_points.size():
		scaled[i] = stroke_points[i] * size
	draw_polyline(scaled, LINE_COLOR, 2.0, true)
