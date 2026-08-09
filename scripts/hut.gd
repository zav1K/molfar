extends Node2D
## Root controller for the molfar's hut: three fixed camera panels
## (казан+піч / стіл+двері / скриня+полиці+вікно-город), navigated by
## arrow keys or on-screen buttons, plus zone click routing.

const PANEL_WIDTH := 960.0
const PANEL_HEIGHT := 540.0
const PANEL_COUNT := 3
const TWEEN_TIME := 0.45
const DOOR_ZOOM := 1.6
const PATIENCE_SECONDS := 60.0 ## how long a waiting visitor sticks around before giving up.

## Zones that are portals to another scene, keyed by zone_id.
const ZONE_SCENES := {
	&"garden_window": "res://scenes/Garden.tscn",
}

@onready var camera: Camera2D = $Camera2D
@onready var nav_left: Button = $UI/NavLeft
@onready var nav_right: Button = $UI/NavRight
@onready var door: Door = $PanelCenter/Zones/Door
@onready var threshold_dialogue: ThresholdDialogue = $ThresholdDialogue
@onready var reception_ui: ReceptionUI = $ReceptionUI
@onready var brewing_ui: BrewingUI = $BrewingUI
@onready var potion_shelf: PotionShelf = $PanelLeft/PotionShelf
@onready var potion_detail_popup: PotionDetailPopup = $PotionDetailPopup
@onready var carving_ui: CarvingUI = $CarvingUI
@onready var waiting_indicator: Button = $UI/WaitingIndicator
@onready var waiting_visitor_display: WaitingVisitorDisplay = $PanelCenter/WaitingVisitorDisplay

@onready var zones: Array[InteractionZone] = [
	$PanelLeft/Zones/Cauldron,
	$PanelRight/Zones/Shelves,
	$PanelRight/Zones/Chest,
	$PanelRight/Zones/GardenWindow,
	$PanelCenter/Zones/Desk,
]

var current_panel: int = 1 # start centered on the desk
var _waiting_visitor: Visitor
var _wait_token: int = 0

func _ready() -> void:
	for zone in zones:
		zone.activated.connect(_on_zone_activated)
	door.visitor_engaged.connect(_on_visitor_engaged)
	threshold_dialogue.resolved.connect(_on_visitor_resolved)
	reception_ui.closed.connect(_on_reception_closed)
	reception_ui.wait_requested.connect(_on_visitor_wait_requested)
	waiting_indicator.pressed.connect(_on_waiting_indicator_pressed)
	waiting_visitor_display.clicked.connect(_on_waiting_indicator_pressed)
	brewing_ui.closed.connect(_on_brewing_closed)
	carving_ui.closed.connect(_on_carving_closed)
	potion_shelf.potion_clicked.connect(potion_detail_popup.show_potion)
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
		PlayerInventory.add(&"wormwood", 3)
	if not PlayerInventory.has(&"mint"):
		PlayerInventory.add(&"mint", 2)
	if not PlayerInventory.has(&"dream_grass"):
		PlayerInventory.add(&"dream_grass", 3)

	# DEBUG: hang a garlic ward so the door hint hook is testable too.
	if WardRack.get_slot(0) == &"":
		WardRack.hang(0, &"garlic")

	_knock_with_random_visitor()

func _unhandled_input(event: InputEvent) -> void:
	if threshold_dialogue.visible or brewing_ui.visible or potion_detail_popup.visible or carving_ui.visible or reception_ui.visible:
		return
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
	create_tween().tween_property(camera, "position", _panel_center(current_panel), TWEEN_TIME)
	_update_nav_buttons()

func _panel_center(panel_index: int) -> Vector2:
	return Vector2(panel_index * PANEL_WIDTH + PANEL_WIDTH / 2.0, PANEL_HEIGHT / 2.0)

func _update_nav_buttons() -> void:
	nav_left.disabled = current_panel == 0
	nav_right.disabled = current_panel == PANEL_COUNT - 1

func _on_zone_activated(zone: InteractionZone) -> void:
	if zone.zone_id == &"cauldron":
		nav_left.visible = false
		nav_right.visible = false
		brewing_ui.open()
		return
	if zone.zone_id == &"desk_carving":
		nav_left.visible = false
		nav_right.visible = false
		carving_ui.open()
		return
	if ZONE_SCENES.has(zone.zone_id):
		get_tree().change_scene_to_file(ZONE_SCENES[zone.zone_id])
		return
	# TODO: route remaining zones to their mechanic once those scenes exist.
	print("Zone activated: %s (%s)" % [zone.zone_label, zone.zone_id])

func _on_brewing_closed() -> void:
	nav_left.visible = true
	nav_right.visible = true

func _on_carving_closed() -> void:
	nav_left.visible = true
	nav_right.visible = true

func _on_visitor_engaged(engaged_door: Door, visitor: Visitor) -> void:
	nav_left.visible = false
	nav_right.visible = false
	var tw := create_tween().set_parallel(true)
	tw.tween_property(camera, "position", engaged_door.global_position, TWEEN_TIME)
	tw.tween_property(camera, "zoom", Vector2(DOOR_ZOOM, DOOR_ZOOM), TWEEN_TIME)
	tw.finished.connect(func() -> void: threshold_dialogue.show_visitor(visitor), CONNECT_ONE_SHOT)

func _on_visitor_resolved(invited: bool) -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(camera, "position", _panel_center(current_panel), TWEEN_TIME)
	tw.tween_property(camera, "zoom", Vector2.ONE, TWEEN_TIME)
	if invited:
		var visitor := door.current_visitor
		door.clear()
		reception_ui.show_visitor(visitor)
		return
	door.clear()
	nav_left.visible = true
	nav_right.visible = true
	_schedule_next_knock()

func _on_reception_closed() -> void:
	nav_left.visible = true
	nav_right.visible = true
	_waiting_visitor = null
	_wait_token += 1
	waiting_indicator.visible = false
	waiting_visitor_display.hide_visitor()
	_schedule_next_knock()

func _on_visitor_wait_requested(visitor: Visitor) -> void:
	nav_left.visible = true
	nav_right.visible = true
	_waiting_visitor = visitor
	waiting_indicator.text = "Клієнт чекає: %s" % visitor.display_name
	waiting_indicator.visible = true
	waiting_visitor_display.show_visitor(visitor)
	_wait_token += 1
	_run_patience_timer(_wait_token)

func _on_waiting_indicator_pressed() -> void:
	if _waiting_visitor == null:
		return
	waiting_indicator.visible = false
	waiting_visitor_display.hide_visitor()
	nav_left.visible = false
	nav_right.visible = false
	_wait_token += 1 # invalidate the running patience timer while they're served again
	reception_ui.show_visitor(_waiting_visitor)

func _run_patience_timer(token: int) -> void:
	await get_tree().create_timer(PATIENCE_SECONDS).timeout
	if token != _wait_token:
		return
	# Gave up waiting — leaves unhelped, same as an explicit refusal.
	_waiting_visitor = null
	waiting_indicator.visible = false
	waiting_visitor_display.hide_visitor()
	_schedule_next_knock()

func _schedule_next_knock() -> void:
	await get_tree().create_timer(2.0).timeout
	_knock_with_random_visitor()

func _knock_with_random_visitor() -> void:
	var visitor := VisitorDatabase.get_random()
	if visitor == null:
		return
	door.knock(visitor, WardRack.check_visitor(visitor))
