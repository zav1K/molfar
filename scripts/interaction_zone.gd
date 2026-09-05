class_name InteractionZone
extends Area2D
## A clickable hotspot in the hut (cauldron, garden window, shelves, entrance, ...).
## Placeholder-friendly: visuals are just a ColorRect + Label until final art lands.

signal activated(zone: InteractionZone)
signal hover_started(zone: InteractionZone)
signal hover_ended(zone: InteractionZone)

@export var zone_id: StringName
@export var zone_label: String

func _ready() -> void:
	input_pickable = true
	input_event.connect(_on_input_event)
	mouse_entered.connect(func() -> void: hover_started.emit(self))
	mouse_exited.connect(func() -> void: hover_ended.emit(self))

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		activated.emit(self)
