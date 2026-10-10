class_name WaitingVisitorDisplay
extends Control
## The currently-waiting visitor, shown standing in the hut beside the
## door (not just an abstract "client is waiting" button) while the
## player goes off to brew or carve what they need. Lives under
## PanelCenter (world space, at the table), not the UI CanvasLayer — only
## visible while looking at that panel, same as the table/door itself;
## WaitingIndicator (in UI, always on screen) is the persistent reminder
## while the player is elsewhere. Click them to reopen ReceptionUI and
## finish the interaction.
##
## Fills this control's width with the actual painted figure — not the
## raw canvas, which on these portraits has huge transparent margins
## (generated-image padding) that made the figure render small and
## floating with a gap above the table line. Uses Visitor's offline-
## measured waiting_portrait_content_rect (see that field's comment for
## why this can't just be computed at runtime) to scale/shift the Icon
## child so the content's top-left lands at this control's top-left,
## then clip_contents cuts off whatever overflows the bottom (legs)
## against the table line.

const WIDTH_FILL := 0.88 ## leaves a small side margin instead of the figure touching the door frame.

## Guarantees the scaled content is always at least this much taller than
## the display, so clip_contents always visibly cuts the legs off at the
## table line. Width-only scaling (the old approach) assumed every
## portrait was a narrow standing figure; wider ones (arms crossed,
## holding a staff out to the side, two people side by side) scaled down
## enough on width alone to fit entirely inside the box with room to
## spare — nothing overflowed, so nothing got clipped, and the figure
## just floated above the table instead of standing behind it.
const MIN_HEIGHT_OVERFLOW := 1.10

## Upper bound on content_scale, as a fraction of this control's width.
## Chasing MIN_HEIGHT_OVERFLOW on a wide portrait (an arm held out, two
## people side by side) pushes the rendered width past the box, and
## clip_contents then trims the sides.
##
## This used to be 1.0 — never wider than the box, so nothing was ever
## trimmed sideways. The cost was that six portraits could not reach the
## height overflow at all and stood short of the table line. The Мавка,
## whose painted figure is narrow and nearly full-canvas tall, was one of
## the few that cleared the cap on her own, which is why she was the one
## that looked right.
##
## 1.40 is the smallest value at which every portrait in the game clears
## it, measured across all of them rather than guessed. The widest then
## renders at 135% of the box and loses about a sixth off each side —
## shoulders and sleeves, against a doorway, which is what standing in a
## doorway looks like.
const MAX_WIDTH_FRACTION := 1.40

signal clicked

@onready var icon: TextureRect = $Icon

var _silhouette: bool = false

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

func show_visitor(visitor: Visitor) -> void:
	var tex := visitor.get_waiting_portrait()
	# Shown either way. A visitor with no portrait used to be drawn as
	# nothing, and since getting on with them means clicking the figure
	# standing by the door, nothing was also nothing to click — see
	# VisitorSilhouette.
	visible = true
	icon.visible = tex != null
	_silhouette = tex == null
	queue_redraw()
	if tex == null:
		return
	icon.texture = tex
	var rect := visitor.waiting_portrait_content_rect
	var tex_size := Vector2(tex.get_width(), tex.get_height())
	var content_width: float = rect.size.x * tex_size.x
	var width_scale := (size.x * WIDTH_FILL) / content_width
	var min_height_scale := (size.y * MIN_HEIGHT_OVERFLOW) / (rect.size.y * tex_size.y)
	var max_safe_scale := (size.x * MAX_WIDTH_FRACTION) / content_width
	var content_scale: float = minf(maxf(width_scale, min_height_scale), max_safe_scale)
	content_scale *= visitor.figure_height_scale
	icon.size = tex_size * content_scale
	var side_margin := (size.x - rect.size.x * tex_size.x * content_scale) / 2.0
	# Head at the top of the doorway, and whatever hangs below the box is
	# clipped against the table — that is the look, and a figure tall
	# enough to overflow on its own gets it from the 0 branch alone.
	#
	# The drop is only for a figure that is NOT that tall: a deliberately
	# short one (потерчата, figure_height_scale < 1) would otherwise hang
	# from the top of the frame with its feet in mid-air. It sinks until
	# its feet sit BELOW the bottom edge — below, not level with it, which
	# is the bit that was missing. Level with the edge means nothing
	# overflows, so clip_contents cuts nothing, and the figure stands with
	# its feet on the tabletop instead of behind it. That is what happened
	# to Маріка й Петрик: the widest portrait in the game, held just under
	# box height by MAX_WIDTH_FRACTION, landed exactly on that edge.
	#
	# maxf keeps the drop from ever applying upward. Without it the rule
	# would raise a figure that overflows a lot — the Мавка is 604px of
	# painted figure in a 314px box — far enough to cut her head off above
	# the door frame, which is the opposite of the intended look.
	var content_height := rect.size.y * tex_size.y * content_scale
	var below_edge := size.y * (MIN_HEIGHT_OVERFLOW - 1.0)
	var top := maxf(0.0, size.y + below_edge - content_height)
	icon.position = Vector2(side_margin, top) \
		- Vector2(rect.position.x * tex_size.x, rect.position.y * tex_size.y) * content_scale

func _draw() -> void:
	if _silhouette:
		VisitorSilhouette.draw_into(self, size)

func hide_visitor() -> void:
	visible = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit()
