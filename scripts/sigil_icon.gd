class_name SigilIcon
extends Control
## Renders one carved sigil the way that specific player actually
## carved it: Sigil.block_texture (or a flat color placeholder while
## that art doesn't exist yet) with the object's own recorded stroke
## drawn on top — never the canonical path_points template. Two
## instances of the same symbol type can and will look different.

const WARD_COLOR := Color(0.82, 0.68, 0.35)
const CURSE_COLOR := Color(0.32, 0.08, 0.12)
const LINE_COLOR := Color(0.18, 0.1, 0.05, 0.9)

var _sigil: Sigil
var _stroke_points: PackedVector2Array

func setup(sigil: Sigil, stroke_points: PackedVector2Array) -> void:
	_sigil = sigil
	_stroke_points = stroke_points
	queue_redraw()

func _draw() -> void:
	if _sigil == null:
		return
	if _sigil.block_texture != null:
		draw_texture_rect(_sigil.block_texture, Rect2(Vector2.ZERO, size), false)
	else:
		var color := WARD_COLOR if _sigil.kind == Sigil.Kind.WARD else CURSE_COLOR
		draw_rect(Rect2(Vector2.ZERO, size), color)

	if _stroke_points.size() < 2:
		return
	var scaled := PackedVector2Array()
	scaled.resize(_stroke_points.size())
	for i in _stroke_points.size():
		scaled[i] = _stroke_points[i] * size
	draw_polyline(scaled, LINE_COLOR, 2.0, true)
