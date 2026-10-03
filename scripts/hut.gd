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
const DAY_VISITOR_CAP := 5 ## how many day clients knock before night falls.
const NIGHT_VISITOR_MIN := 3 ## night нечисть quota is rolled fresh each night, in this range —
const NIGHT_VISITOR_MAX := 5 ## only outside the Розділ 1 script below, which forces exactly one.

## Розділ 1 ("Поріг") — deterministic day-by-day script, see STORY.md.
## Keyed by _story_day (1-based, counting from a fresh playthrough — see
## _story_day below). A day not listed here (8+, once the chapter ends)
## falls back to fully random day/night rotation, same as before this
## chapter existed.
##
## "day": forced as the LAST day-phase knock (day_visitor_count reaches
## day_cap - 1) rather than the first, so it reads as Лісник/Вісник
## showing up toward evening, after the ordinary day's clients — see
## STORY.md's "Увечері" framing. With day_cap 1 (Day 7) that's also the
## only knock, so "last" and "first" coincide.
## "day_cap": overrides DAY_VISITOR_CAP for that day only; omitted means
## the normal cap applies.
## "night": forced as the night phase's only visitor (quota forced to 1
## instead of the usual random NIGHT_VISITOR_MIN..MAX range). A day with
## no "night" entry (none in this chapter) would fall back to normal.
const CHAPTER1_SCRIPT := {
	1: {"day": "res://data/visitors/special/forest_warden_day1.tres", "night": "res://data/visitors/special/mavka_night1.tres"},
	2: {"day": "res://data/visitors/special/forest_warden_day2.tres", "night": "res://data/visitors/upyr_brutal_male.tres"},
	3: {"day": "res://data/visitors/special/forest_warden_day3.tres", "night": "res://data/visitors/special/nichnytsia_night3.tres"},
	4: {"day": "res://data/visitors/special/forest_warden_day4.tres", "night": "res://data/visitors/upyr_hidden_female.tres"},
	5: {"day": "res://data/visitors/special/forest_warden_day5.tres", "night": "res://data/visitors/upyr_seeking_cure.tres"},
	6: {"night": "res://data/visitors/special/upyr_night6_strange.tres"},
	7: {"day": "res://data/visitors/special/visnyk_day7.tres", "day_cap": 1, "night": "res://data/visitors/special/priest_day7.tres"},
}

## Zones that are portals to another scene, keyed by zone_id.
const ZONE_SCENES := {
	&"garden_window": "res://scenes/Garden.tscn",
}

## DEBUG: the 16 herbs added for the new recipe batch — none have any
## acquisition path yet (no gathering mechanic), so seed 10 of each for
## testing. See the seeding block in _ready().
const NEW_TEST_HERBS: Array[StringName] = [
	&"calendula", &"chamomile", &"deadnettle", &"dill", &"elderberry",
	&"hawthorn", &"lovage", &"marigold",
	&"nettle", &"oregano", &"parsley", &"rosehip", &"st_johns_wort", &"thyme",
]

@onready var camera: Camera2D = $Camera2D
@onready var nav_left: Button = $UI/NavLeft
@onready var nav_right: Button = $UI/NavRight
@onready var door: Door = $PanelCenter/Zones/Door
@onready var threshold_dialogue: ThresholdDialogue = $ThresholdDialogue
@onready var reception_ui: ReceptionUI = $ReceptionUI
@onready var brewing_ui: BrewingUI = $BrewingUI
@onready var ingredient_inventory_panel: InventoryPanel = $IngredientInventoryPanel
@onready var potion_inventory_panel: InventoryPanel = $PotionInventoryPanel
@onready var sigil_inventory_panel: InventoryPanel = $SigilInventoryPanel
@onready var calendar_panel: CalendarPanel = $CalendarPanel
@onready var chest_panel: InventoryPanel = $ChestPanel
@onready var potion_detail_popup: PotionDetailPopup = $PotionDetailPopup
@onready var carving_ui: CarvingUI = $CarvingUI
@onready var grimoire_ui: GrimoireUI = $GrimoireUI
@onready var waiting_indicator: Button = $UI/WaitingIndicator
@onready var waiting_visitor_display: WaitingVisitorDisplay = $PanelCenter/WaitingVisitorDisplay
@onready var calendar_label: Label = $UI/CalendarLabel

## Calendar deliberately excluded — see _update_calendar_label. The zone
## node itself is also hidden in _ready() rather than deleted from the
## scene, so it's a one-line revert whenever a later chapter wants it back.
@onready var zones: Array[InteractionZone] = [
	$PanelLeft/Zones/Cauldron,
	$PanelLeft/Zones/DryingBeam,
	$PanelLeft/Zones/PotionShelf,
	$PanelRight/Zones/Shelves,
	$PanelRight/Zones/Chest,
	$PanelRight/Zones/GardenWindow,
	$PanelRight/Zones/Grimoire,
	$PanelCenter/Zones/Desk,
	$PanelCenter/Zones/SigilShelf,
]

var current_panel: int = 1 # start centered on the desk
var _waiting_visitor: Visitor
var _wait_token: int = 0
var _day_visitor_count: int = 0
var _night_visitor_count: int = 0
var _night_quota: int = NIGHT_VISITOR_MIN

## DEBUG: bump _story_day to jump straight into a later day of Розділ 1
## instead of playing days 1..N for real — see CHAPTER1_SCRIPT. Each
## later day assumes everything before it already happened; nothing else
## needs hand-setting anymore (no StoryFlags to jump, unlike the old
## flag-jump block this replaced). The forced day visitor still only
## shows up as that day's LAST knock (see CHAPTER1_SCRIPT's doc) — also
## set _day_visitor_count to _current_day_cap() - 1 (5 - 1 = 4 for every
## day but 7) if you want it to be the very first knock instead of
## clicking through that day's ordinary rotation first.
var _story_day: int = 1
var _day_forced_used: bool = false
var _night_forced_used: bool = false

func _ready() -> void:
	for zone in zones:
		zone.activated.connect(_on_zone_activated)
	$PanelCenter/Zones/Calendar.visible = false
	door.visitor_engaged.connect(_on_visitor_engaged)
	threshold_dialogue.resolved.connect(_on_visitor_resolved)
	reception_ui.closed.connect(_on_reception_closed)
	reception_ui.wait_requested.connect(_on_visitor_wait_requested)
	waiting_indicator.pressed.connect(_on_waiting_indicator_pressed)
	waiting_visitor_display.clicked.connect(_on_waiting_indicator_pressed)
	brewing_ui.closed.connect(_on_brewing_closed)
	carving_ui.closed.connect(_on_carving_closed)
	ingredient_inventory_panel.closed.connect(_on_inventory_panel_closed)
	potion_inventory_panel.closed.connect(_on_inventory_panel_closed)
	potion_inventory_panel.potion_selected.connect(potion_detail_popup.show_potion)
	sigil_inventory_panel.closed.connect(_on_inventory_panel_closed)
	calendar_panel.closed.connect(_on_inventory_panel_closed)
	chest_panel.closed.connect(_on_inventory_panel_closed)
	chest_panel.potion_selected.connect(potion_detail_popup.show_potion)
	grimoire_ui.closed.connect(_on_inventory_panel_closed)
	nav_left.pressed.connect(_go_left)
	nav_right.pressed.connect(_go_right)
	GameCalendar.day_changed.connect(_update_calendar_label)
	GameCalendar.phase_changed.connect(_update_calendar_label)
	GameCalendar.season_changed.connect(_update_calendar_label)
	camera.position = _panel_center(current_panel)
	_update_nav_buttons()
	_update_calendar_label()

	# DEBUG: seed the inventory so there's something to see in InventoryPanel
	# and to brew/give until the garden/gathering loop actually grants
	# ingredients. Remove once that exists.
	if not PlayerInventory.has(&"garlic"):
		PlayerInventory.add(&"garlic", 3)
	if not PlayerInventory.has(&"wormwood"):
		PlayerInventory.add(&"wormwood", 3)
	if not PlayerInventory.has(&"mint"):
		PlayerInventory.add(&"mint", 2)
	if not PlayerInventory.has(&"dream_grass"):
		PlayerInventory.add(&"dream_grass", 3)

	# DEBUG: seed 10 of each newly-added herb so the new recipes are
	# testable without a gathering mechanic yet either. Remove alongside
	# the block above once that exists.
	for herb_id in NEW_TEST_HERBS:
		if not PlayerInventory.has(herb_id):
			PlayerInventory.add(herb_id, 10)

	# DEBUG: hang a garlic ward so the door hint hook is testable too.
	if WardRack.get_slot(0) == &"":
		WardRack.hang(0, &"garlic")

	# DEBUG: seed one of every potion so the inventory grid has something
	# to show for every icon/no-icon case while testing. Remove once
	# brewing is the only way potions actually enter the inventory.
	for potion in PotionDatabase.get_all():
		if not PlayerInventory.has(potion.id):
			PlayerInventory.add(potion.id, 1)

	_knock_with_random_visitor()

func _unhandled_input(event: InputEvent) -> void:
	if threshold_dialogue.visible or brewing_ui.visible or potion_detail_popup.visible or carving_ui.visible or reception_ui.visible or ingredient_inventory_panel.visible or potion_inventory_panel.visible or sigil_inventory_panel.visible or calendar_panel.visible or chest_panel.visible or grimoire_ui.visible:
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
	if zone.zone_id == &"drying_beam":
		nav_left.visible = false
		nav_right.visible = false
		ingredient_inventory_panel.open()
		return
	if zone.zone_id == &"potion_shelf":
		nav_left.visible = false
		nav_right.visible = false
		potion_inventory_panel.open()
		return
	if zone.zone_id == &"sigil_shelf":
		nav_left.visible = false
		nav_right.visible = false
		sigil_inventory_panel.open()
		return
	if zone.zone_id == &"calendar":
		nav_left.visible = false
		nav_right.visible = false
		calendar_panel.open()
		return
	if zone.zone_id == &"chest":
		nav_left.visible = false
		nav_right.visible = false
		chest_panel.open()
		return
	if zone.zone_id == &"grimoire":
		nav_left.visible = false
		nav_right.visible = false
		grimoire_ui.open()
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

func _on_inventory_panel_closed() -> void:
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
	_advance_visitor_slot()
	await get_tree().create_timer(2.0).timeout
	_knock_with_random_visitor()

## Called once per resolved visitor (refused, served, or given up on) —
## the single chokepoint before the next knock. Counts the slot against
## the current phase's cap and flips day<->night once that cap is hit.
func _advance_visitor_slot() -> void:
	if GameCalendar.phase == GameCalendar.Phase.DAY:
		_day_visitor_count += 1
		if _day_visitor_count >= _current_day_cap():
			var script: Dictionary = CHAPTER1_SCRIPT.get(_story_day, {})
			_night_quota = 1 if script.has("night") else randi_range(NIGHT_VISITOR_MIN, NIGHT_VISITOR_MAX)
			_night_visitor_count = 0
			_night_forced_used = false
			GameCalendar.set_phase(GameCalendar.Phase.NIGHT)
	else:
		_night_visitor_count += 1
		if _night_visitor_count >= _night_quota:
			GameCalendar.advance_day()
			VisitorDatabase.reset_seen()
			_day_visitor_count = 0
			_day_forced_used = false
			_story_day += 1
			GameCalendar.set_phase(GameCalendar.Phase.DAY)

func _current_day_cap() -> int:
	var script: Dictionary = CHAPTER1_SCRIPT.get(_story_day, {})
	return script.get("day_cap", DAY_VISITOR_CAP)

func _knock_with_random_visitor() -> void:
	var is_night := GameCalendar.phase == GameCalendar.Phase.NIGHT
	var visitor := _pop_forced_visitor(is_night)
	if visitor == null:
		visitor = VisitorDatabase.get_random(is_night)
	if visitor == null:
		return
	door.knock(visitor, WardRack.check_visitor(visitor))

## Розділ 1's deterministic override of the ordinary random pool — see
## CHAPTER1_SCRIPT. Returns null (falls back to VisitorDatabase.get_random)
## whenever today/tonight has no scripted visitor, it's already been used,
## or — for the day phase only — this isn't yet the last slot before night.
func _pop_forced_visitor(is_night: bool) -> Visitor:
	var script: Dictionary = CHAPTER1_SCRIPT.get(_story_day, {})
	if is_night:
		if _night_forced_used or not script.has("night"):
			return null
		_night_forced_used = true
		return _load_forced_visitor(script["night"])
	if _day_forced_used or not script.has("day"):
		return null
	if _day_visitor_count != _current_day_cap() - 1:
		return null
	_day_forced_used = true
	return _load_forced_visitor(script["day"])

## Loads a scripted visitor and replicates get_random()'s knocked_sets_flag
## side effect — forced visitors bypass VisitorDatabase entirely, so
## nothing else sets it for them. The priest's finale line also depends on
## how the Day 4 упириця encounter went, which satisfied_sets_flag already
## recorded regardless of how this visitor is reached — so that part needs
## no special-casing here, just a duplicate + append once it's loaded.
func _load_forced_visitor(path: String) -> Visitor:
	var visitor: Visitor = load(path)
	if path == "res://data/visitors/special/priest_day7.tres" and StoryFlags.has_flag(&"helped_hidden_upyr"):
		visitor = visitor.duplicate()
		# problem_text ends with a closing quote mark (speech-styled, like
		# every other visitor's) — trim it, append the extra sentence, and
		# re-close, rather than just tacking text on after the quote.
		visitor.problem_text = visitor.problem_text.trim_suffix("\"") \
			+ " Хтось у селі вже казав, що бачив тебе з нею. Подумай, на чиєму ти боці, мольфаре.\""
	if visitor.knocked_sets_flag != &"":
		StoryFlags.set_flag(visitor.knocked_sets_flag)
	return visitor

## Розділ 1 is a fixed 7-day span, not tied to any real festival date, so
## the label just counts chapter days instead of showing GameCalendar's
## season/festival calendar (see CalendarPanel, dropped from `zones`
## below for the same reason — nothing in this chapter uses it).
func _update_calendar_label(_arg = null) -> void:
	var phase_text := "ніч" if GameCalendar.phase == GameCalendar.Phase.NIGHT else "день"
	calendar_label.text = "День %d — %s" % [_story_day, phase_text]
