class_name SigilPatternIcon
extends Control
## Clean line-drawing preview of a sigil's canonical path_points, on a
## plain parchment swatch — used by CarvingUI's reference book so the
## player can look up what a shape actually looks like. Deliberately
## unrelated to any specific carved instance's wood block or traced
## stroke (see SigilIcon for that); this only ever draws the template.

const PAPER_COLOR := Color(0.86, 0.78, 0.6)
const INK_COLOR := Color(0.15, 0.1, 0.06, 0.9)
const MARGIN_FRACTION := 0.14 ## keeps the drawn shape off the swatch's edges

var _sigil: Sigil

func setup(sigil: Sigil) -> void:
	_sigil = sigil
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PAPER_COLOR)
	if _sigil == null or _sigil.path_points.size() < 2:
		return
	# Same normalization CarvingCanvas.start() uses for the (now hidden)
	# target path, so a memorized shape here maps onto the carving
	# surface without looking subtly different.
	var pattern_scale: float = minf(size.x, size.y) * (1.0 - MARGIN_FRACTION * 2.0)
	var center := size / 2.0
	var points := PackedVector2Array()
	points.resize(_sigil.path_points.size())
	for i in _sigil.path_points.size():
		points[i] = center + (_sigil.path_points[i] - Vector2(0.5, 0.5)) * pattern_scale
	draw_polyline(points, INK_COLOR, 2.0, true)
