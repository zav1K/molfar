extends Node2D
## Root controller for the molfar's hut: three fixed camera panels
## (казан+піч / стіл+вікно / скриня+полиці+вікно-город), navigated by
## arrow keys or on-screen buttons, plus zone click routing.

const PANEL_WIDTH := 960.0
const PANEL_HEIGHT := 540.0
const PANEL_COUNT := 3
const TWEEN_TIME := 0.45

## Zones that are portals to another scene, keyed by zone_id.
const ZONE_SCENES := {
	&"garden_window": "res://scenes/Garden.tscn",
}

@onready var camera: Camera2D = $Camera2D
@onready var nav_left: Button = $UI/NavLeft
@onready var nav_right: Button = $UI/NavRight
@onready var client_dialogue: CanvasLayer = $ClientDialogue

@onready var zones: Array[InteractionZone] = [
	$PanelLeft/Zones/Cauldron,
	$PanelCenter/Zones/DeskWindow,
	$PanelRight/Zones/Shelves,
	$PanelRight/Zones/Chest,
	$PanelRight/Zones/GardenWindow,
]

var current_panel: int = 1 # start centered on the desk

func _ready() -> void:
	for zone in zones:
		zone.activated.connect(_on_zone_activated)
	nav_left.pressed.connect(_go_left)
	nav_right.pressed.connect(_go_right)
	camera.position = _panel_center(current_panel)
	_update_nav_buttons()

	# DEBUG: seed the inventory so the beam bundles have something to react to
	# until the garden/gathering loop actually grants ingredients. Remove once
	# that exists. dream_grass/kupala_dew have no bundle art yet and aren't
	# seeded here — nothing to show for them regardless of inventory state.
	if not PlayerInventory.has(&"garlic"):
		PlayerInventory.add(&"garlic", 3)
	if not PlayerInventory.has(&"wormwood"):
		PlayerInventory.add(&"wormwood", 2)
	if not PlayerInventory.has(&"mint"):
		PlayerInventory.add(&"mint", 1)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_left"):
		_go_left()
	elif event.is_action_pressed(&"ui_right"):
		_go_right()

func _go_left() -> void:
	if current_panel > 0:
		current_panel -= 1
		_move_camera()

func _go_right() -> void:
	if current_panel < PANEL_COUNT - 1:
		current_panel += 1
		_move_camera()

func _move_camera() -> void:
	create_tween().tween_property(camera, "position", _panel_center(current_panel), TWEEN_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_update_nav_buttons()

func _panel_center(panel_index: int) -> Vector2:
	return Vector2(panel_index * PANEL_WIDTH + PANEL_WIDTH / 2.0, PANEL_HEIGHT / 2.0)

func _update_nav_buttons() -> void:
	nav_left.disabled = current_panel == 0
	nav_right.disabled = current_panel == PANEL_COUNT - 1

func _on_zone_activated(zone: InteractionZone) -> void:
	if zone.zone_id == &"desk_window":
		# TODO: tween the camera in further, per the concept doc, once there's
		# art worth zooming into. For now just switch straight to the mode.
		client_dialogue.visible = true
		return
	if ZONE_SCENES.has(zone.zone_id):
		get_tree().change_scene_to_file(ZONE_SCENES[zone.zone_id])
		return
	# TODO: route remaining zones to their mechanic once those scenes exist.
	print("Zone activated: %s (%s)" % [zone.zone_label, zone.zone_id])
