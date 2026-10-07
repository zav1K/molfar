class_name Door
extends InteractionZone
## The hut's front door. A Visitor can be "knocking" (pending) or the door
## can be empty — clicking only opens the threshold sequence while someone
## is actually there. Ward hints (from WardRack) are rolled at knock time —
## before the player ever clicks — and shown right on the door label, so
## they inform the decision to engage at all, not just the invite choice.

signal visitor_engaged(door: Door, visitor: Visitor)

@onready var visual: ColorRect = $Visual
@onready var label: Label = $Label

var current_visitor: Visitor
var current_hints: Array[String] = []

func _ready() -> void:
	super._ready()
	activated.connect(_on_activated)
	_refresh()

func knock(visitor: Visitor, hints: Array[String] = []) -> void:
	current_visitor = visitor
	current_hints = hints
	_refresh()

func clear() -> void:
	current_visitor = null
	current_hints = []
	_refresh()

func _on_activated(_zone: InteractionZone) -> void:
	if current_visitor != null:
		visitor_engaged.emit(self, current_visitor)

func _refresh() -> void:
	if current_visitor == null:
		label.text = "Двері"
		visual.color = Color(0.3, 0.22, 0.15, 0.25)
		return
	var text := "Двері — хтось стукає!"
	for hint in current_hints:
		text += "\n" + hint
	label.text = text
	visual.color = Color(0.55, 0.35, 0.15, 0.45)
