class_name WaitingVisitorDisplay
extends Control
## The currently-waiting visitor, shown standing in the hut beside the
## door (not just an abstract "client is waiting" button) while the
## player goes off to brew or carve what they need. Click them to
## reopen ReceptionUI and finish the interaction.
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

signal clicked

@onready var icon: TextureRect = $Icon

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

func show_visitor(visitor: Visitor) -> void:
	var tex := visitor.get_waiting_portrait()
	visible = tex != null
	if tex == null:
		return
	icon.texture = tex
	var rect := visitor.waiting_portrait_content_rect
	var tex_size := Vector2(tex.get_width(), tex.get_height())
	var width_scale := (size.x * WIDTH_FILL) / (rect.size.x * tex_size.x)
	var min_height_scale := (size.y * MIN_HEIGHT_OVERFLOW) / (rect.size.y * tex_size.y)
	var content_scale := max(width_scale, min_height_scale)
	icon.size = tex_size * content_scale
	var side_margin := (size.x - rect.size.x * tex_size.x * content_scale) / 2.0
	icon.position = Vector2(side_margin, 0.0) - Vector2(rect.position.x * tex_size.x, rect.position.y * tex_size.y) * content_scale

func hide_visitor() -> void:
	visible = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit()
