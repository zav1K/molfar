class_name GardenPlot
extends InteractionZone
## Placeholder garden bed: click an empty plot to plant, click again once it's
## ready to harvest. Growth is a flat timer for now — real season/weather rules
## come later.

enum State { EMPTY, GROWING, READY }

const STATE_COLOR := {
	State.EMPTY: Color(0.4, 0.3, 0.2, 1),
	State.GROWING: Color(0.35, 0.55, 0.25, 1),
	State.READY: Color(0.8, 0.75, 0.2, 1),
}
const STATE_TEXT := {
	State.EMPTY: "Порожньо",
	State.GROWING: "Росте...",
	State.READY: "Готово!",
}

@export var ingredient_id: StringName = &"mint"
@export var growth_seconds: float = 5.0

signal harvested(plot: GardenPlot, ingredient_id: StringName)

@onready var visual: ColorRect = $Visual
@onready var label: Label = $Label

var state: State = State.EMPTY

func _ready() -> void:
	super._ready()
	activated.connect(_on_activated)
	_refresh_visual()

func _on_activated(_zone: InteractionZone) -> void:
	match state:
		State.EMPTY:
			_plant()
		State.READY:
			_harvest()
		State.GROWING:
			pass

func _plant() -> void:
	state = State.GROWING
	_refresh_visual()
	get_tree().create_timer(growth_seconds).timeout.connect(_on_grown)

func _on_grown() -> void:
	state = State.READY
	_refresh_visual()

func _harvest() -> void:
	harvested.emit(self, ingredient_id)
	state = State.EMPTY
	_refresh_visual()

func _refresh_visual() -> void:
	visual.color = STATE_COLOR[state]
	label.text = STATE_TEXT[state]
