class_name VisitorSilhouette
extends RefCounted
## Stand-in figure for a visitor whose portrait is missing.
##
## Without one, a portrait-less visitor is drawn as nothing at all, and
## since the hut's whole interaction is "click the person standing by the
## door", nothing is also nothing to click. The only way on is the status
## bar at the top, which is a Button but reads as a label — so Лихо, the
## one visitor with no art, played as a dead end.
##
## A silhouette keeps the normal interaction working whatever is missing,
## and keeps the failure honest: it plainly isn't finished art, rather
## than an empty doorway that looks like a different bug.

const BODY := Color(0.05, 0.05, 0.07, 0.90)
const RIM := Color(0.78, 0.67, 0.45, 0.33)
const RIM_WIDTH := 1.5

## Draws a head-and-shoulders figure filling `box`, running off the
## bottom edge so whatever clips the real portraits clips this the same
## way — against the table line in the hut, the floor at the door.
static func draw_into(canvas: CanvasItem, box: Vector2) -> void:
	var head_radius: float = box.x * 0.16
	var head_centre := Vector2(box.x * 0.5, box.y * 0.17)
	var shoulder_y: float = head_centre.y + head_radius * 0.7
	var half_width: float = box.x * 0.27
	var body := PackedVector2Array([
		Vector2(head_centre.x - half_width * 0.45, shoulder_y),
		Vector2(head_centre.x - half_width, shoulder_y + box.y * 0.14),
		Vector2(head_centre.x - half_width * 0.92, box.y * 1.05),
		Vector2(head_centre.x + half_width * 0.92, box.y * 1.05),
		Vector2(head_centre.x + half_width, shoulder_y + box.y * 0.14),
		Vector2(head_centre.x + half_width * 0.45, shoulder_y),
	])
	canvas.draw_colored_polygon(body, BODY)
	canvas.draw_circle(head_centre, head_radius, BODY)
	# Rim only down the sides and around the head: a closed outline would
	# draw a line across the bottom and undo the run-off-the-edge read.
	canvas.draw_arc(head_centre, head_radius, 0.0, TAU, 32, RIM, RIM_WIDTH, true)
	canvas.draw_polyline(body.slice(0, 3), RIM, RIM_WIDTH, true)
	var right := PackedVector2Array([body[5], body[4], body[3]])
	canvas.draw_polyline(right, RIM, RIM_WIDTH, true)
