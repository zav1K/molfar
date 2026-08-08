extends Node2D
## Root controller for the molfar's hut scene. Wires up each InteractionZone
## to its (not-yet-built) mechanic: brewing, garden, carving, client visits.

@onready var zones: Array[InteractionZone] = [
	$Zones/Cauldron,
	$Zones/GardenWindow,
	$Zones/Shelves,
	$Zones/Entrance,
]

func _ready() -> void:
	for zone in zones:
		zone.activated.connect(_on_zone_activated)

func _on_zone_activated(zone: InteractionZone) -> void:
	# TODO: route to the real mechanic once brewing/garden/carving/dialogue scenes exist.
	print("Zone activated: %s (%s)" % [zone.zone_label, zone.zone_id])
