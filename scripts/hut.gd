extends Node2D
## Root controller for the molfar's hut scene. Wires up each InteractionZone
## to its (not-yet-built) mechanic: brewing, garden, carving, client visits.

## Zones that are portals to another scene, keyed by zone_id.
const ZONE_SCENES := {
	&"garden_window": "res://scenes/Garden.tscn",
}

@onready var zones: Array[InteractionZone] = [
	$Zones/Cauldron,
	$Zones/GardenWindow,
	$Zones/Shelves,
	$Zones/Chest,
	$Zones/Entrance,
]

func _ready() -> void:
	for zone in zones:
		zone.activated.connect(_on_zone_activated)
	# DEBUG: seed the inventory so the beam bundle has something to react to
	# until the garden/gathering loop actually grants ingredients. Remove once
	# that exists.
	if not PlayerInventory.has(&"garlic"):
		PlayerInventory.add(&"garlic")

func _on_zone_activated(zone: InteractionZone) -> void:
	if ZONE_SCENES.has(zone.zone_id):
		get_tree().change_scene_to_file(ZONE_SCENES[zone.zone_id])
		return
	# TODO: route remaining zones to their mechanic once those scenes exist.
	print("Zone activated: %s (%s)" % [zone.zone_label, zone.zone_id])
