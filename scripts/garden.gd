extends Node2D
## Interactive garden plot map, reached through the hut's garden-window portal.

## 3 sub-plots per bed × 3 beds baked into the garden background art —
## order matches GardenState's plot_index (0-2 = bed 1, 3-5 = bed 2,
## 6-8 = bed 3), see GardenPlot.plot_index on each node.
@onready var plots: Array[GardenPlot] = [
	$Plots/Bed1Plot1, $Plots/Bed1Plot2, $Plots/Bed1Plot3,
	$Plots/Bed2Plot1, $Plots/Bed2Plot2, $Plots/Bed2Plot3,
	$Plots/Bed3Plot1, $Plots/Bed3Plot2, $Plots/Bed3Plot3,
]
@onready var exit_zone: InteractionZone = $ExitZone
@onready var planting_ui: PlantingUI = $PlantingUI

var _planting_plot: GardenPlot

func _ready() -> void:
	for plot in plots:
		plot.harvested.connect(_on_plot_harvested)
		plot.planting_requested.connect(_on_planting_requested)
	exit_zone.activated.connect(_on_exit_activated)
	planting_ui.closed.connect(_on_planting_closed)

func _on_plot_harvested(plot: GardenPlot, ingredient_id: StringName) -> void:
	PlayerInventory.add(ingredient_id, 1)

func _on_planting_requested(plot: GardenPlot) -> void:
	_planting_plot = plot
	planting_ui.open(plot.plot_index)

func _on_planting_closed() -> void:
	if _planting_plot != null:
		_planting_plot.refresh()
	_planting_plot = null

func _on_exit_activated(_zone: InteractionZone) -> void:
	get_tree().change_scene_to_file("res://scenes/Hut.tscn")
