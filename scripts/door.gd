class_name Door
extends InteractionZone
## The hut's front door. A Visitor can be "knocking" (pending) or the door
## can be empty — clicking only opens the threshold sequence while someone
## is actually there.

signal visitor_engaged(door: Door, visitor: Visitor)

@onready var visual: ColorRect = $Visual
@onready var label: Label = $Label

var current_visitor: Visitor

func _ready() -> void:
	super._ready()
	activated.connect(_on_activated)
	_refresh()

func knock(visitor: Visitor) -> void:
	current_visitor = visitor
	_refresh()

func clear() -> void:
	current_visitor = null
	_refresh()

func _on_activated(_zone: InteractionZone) -> void:
	if current_visitor != null:
		visitor_engaged.emit(self, current_visitor)

func _refresh() -> void:
	if current_visitor != null:
		label.text = "Двері — хтось стукає!"
		visual.color = Color(0.55, 0.35, 0.15, 0.45)
	else:
		label.text = "Двері"
		visual.color = Color(0.3, 0.22, 0.15, 0.25)
