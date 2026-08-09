class_name WaitingVisitorDisplay
extends Control
## The currently-waiting visitor, shown standing in the hut beside the
## door (not just an abstract "client is waiting" button) while the
## player goes off to brew or carve what they need. Click them to
## reopen ReceptionUI and finish the interaction.
##
## Fills this control's width with the actual painted figure — not the
## raw canvas, which on these portraits has huge transparent margins
## (~25% on each side, generated-image padding) that made the figure
## render small and floating with a gap above the table line. Image.
## get_used_rect() finds the real non-transparent content bounds; the
## Icon child is scaled and shifted so that content's top-left lands at
## this control's top-left, then clip_contents cuts off whatever
## overflows the bottom (legs) against the table line.

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
	var used := tex.get_image().get_used_rect()
	var content_scale := size.x / float(used.size.x)
	icon.size = Vector2(tex.get_width(), tex.get_height()) * content_scale
	icon.position = -Vector2(used.position) * content_scale

func hide_visitor() -> void:
	visible = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit()
