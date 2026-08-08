extends Node2D
## Interactive garden plot map, reached through the hut's garden-window portal.

@onready var plots: Array[GardenPlot] = [
	$Plots/Plot1, $Plots/Plot2, $Plots/Plot3,
	$Plots/Plot4, $Plots/Plot5, $Plots/Plot6,
]
@onready var exit_zone: InteractionZone = $ExitZone

func _ready() -> void:
	for plot in plots:
		plot.harvested.connect(_on_plot_harvested)
	exit_zone.activated.connect(_on_exit_activated)

func _on_plot_harvested(plot: GardenPlot, ingredient_id: StringName) -> void:
	# TODO: route into the player inventory once it exists.
	print("Harvested %s from %s" % [ingredient_id, plot.zone_label])

func _on_exit_activated(_zone: InteractionZone) -> void:
	get_tree().change_scene_to_file("res://scenes/Hut.tscn")
