class_name WaitingVisitorDisplay
extends Control
## The currently-waiting visitor, shown standing in the hut beside the
## door (not just an abstract "client is waiting" button) while the
## player goes off to brew or carve what they need. Click them to
## reopen ReceptionUI and finish the interaction.
##
## Fills this control's width and anchors the image to the top, so the
## face always stays visible and only the bottom (legs/feet, or empty
## canvas padding) gets clipped against the table line. Godot's built-in
## STRETCH_KEEP_ASPECT_COVERED crops centered on both edges instead,
## which was cutting heads off — this computes the child Icon's size
## from the actual texture's aspect ratio and clips it against this
## control's clip_contents instead.

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
	var aspect := float(tex.get_width()) / float(tex.get_height())
	icon.position = Vector2.ZERO
	icon.size = Vector2(size.x, size.x / aspect)

func hide_visitor() -> void:
	visible = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit()
