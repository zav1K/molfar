class_name GardenPlot
extends InteractionZone
## Thin view over GardenState's plot at `plot_index` — the actual state
## lives in that autoload (see its docstring for why), this node just
## renders it and turns clicks into GardenState calls.

const EMPTY_COLOR := Color(0.4, 0.3, 0.2, 1)
const GROWING_COLOR := Color(0.35, 0.55, 0.25, 1)
const READY_COLOR := Color(0.8, 0.75, 0.2, 1)
const LOCKED_COLOR := Color(0.25, 0.25, 0.25, 1)

@export var plot_index: int = 0

## Emitted on click when this plot is empty and unlocked — garden.gd opens
## PlantingUI for it, then calls refresh() once planting succeeds.
signal planting_requested(plot: GardenPlot)
signal harvested(plot: GardenPlot, ingredient_id: StringName)

@onready var visual: ColorRect = $Visual
@onready var label: Label = $Label

func _ready() -> void:
	super._ready()
	activated.connect(_on_activated)
	GameCalendar.day_changed.connect(func(_d: int) -> void: refresh())
	refresh()

func _on_activated(_zone: InteractionZone) -> void:
	if not GardenState.is_plot_unlocked(plot_index):
		return
	var plot := GardenState.get_plot(plot_index)
	match plot.stage:
		GardenState.Stage.EMPTY:
			planting_requested.emit(self)
		GardenState.Stage.GROWING:
			GardenState.water(plot_index)
			refresh()
		GardenState.Stage.READY:
			var ingredient_id := GardenState.harvest(plot_index)
			harvested.emit(self, ingredient_id)
			refresh()

func refresh() -> void:
	if not GardenState.is_plot_unlocked(plot_index):
		visual.color = LOCKED_COLOR
		label.text = "Заблоковано"
		return
	var plot := GardenState.get_plot(plot_index)
	match plot.stage:
		GardenState.Stage.EMPTY:
			visual.color = EMPTY_COLOR
			label.text = "Порожньо"
		GardenState.Stage.GROWING:
			visual.color = GROWING_COLOR
			var watered_today := plot.last_watered_day == GameCalendar.current_day
			label.text = "Росте... (%d/%d)%s" % [plot.days_grown, plot.growth_days_required, " 💧" if watered_today else ""]
		GardenState.Stage.READY:
			visual.color = READY_COLOR
			label.text = "Готово!"
