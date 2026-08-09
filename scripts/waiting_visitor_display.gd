class_name WaitingVisitorDisplay
extends TextureRect
## The currently-waiting visitor, shown standing in the hut beside the
## door (not just an abstract "client is waiting" button) while the
## player goes off to brew or carve what they need. Click them to
## reopen ReceptionUI and finish the interaction.

signal clicked

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

func show_visitor(visitor: Visitor) -> void:
	var tex := visitor.get_waiting_portrait()
	texture = tex
	visible = tex != null

func hide_visitor() -> void:
	visible = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit()
