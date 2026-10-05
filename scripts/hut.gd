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
const DEBUG_SEED_AMOUNT := 10 ## see the potion/sigil seeding block in _ready().
const DAY_VISITOR_CAP := 5 ## how many day clients knock before night falls.
const NIGHT_VISITOR_MIN := 3 ## night нечисть quota is rolled fresh each night, in this range —
const NIGHT_VISITOR_MAX := 5 ## only outside the Розділ 1 script below (freeplay after it ends).
const SCRIPTED_NIGHT_CAP := 3 ## default night_cap for a scripted night — see CHAPTER1_SCRIPT.
const CHAPTER1_LAST_DAY := 7 ## after this night the chapter ends — see _end_chapter().
const CHAPTER_END_SCENE := "res://scenes/ChapterEnd.tscn"

## Розділ 1 ("Поріг") — deterministic day-by-day script, see STORY.md.
## Keyed by _story_day (1-based, counting from a fresh playthrough — see
## _story_day below). Every day of the chapter is listed; there is no day
## 8, since the end of night 7 hands over to ChapterEnd instead of
## advancing (see _end_chapter). The unscripted-day fallbacks elsewhere
## in this file (_roll_night_quota's random range, get_random's ordinary
## rotation) are therefore unreachable in the chapter as it ships — kept
## because they're what a later chapter's freeplay stretch will use, and
## because a day_cap/night_cap left unset above still falls through them.
##
## "day"/"night": forced as that phase's LAST knock (slot count reaches
## cap - 1) rather than the first, so it reads as Лісник/Вісник/the
## night's нечисть showing up after the ordinary clients already came
## and went — see STORY.md's "Увечері" framing. Earlier slots in that
## same phase are ordinary VisitorDatabase.get_random() picks, same as
## outside this chapter — EXCLUDING today's/tonight's own forced
## visitor specifically, so it can't also turn up early by chance and
## then again when forced (see _knock_with_random_visitor). Every
## special/ Visitor is additionally sentinel-gated out of get_random()
## entirely regardless (see VisitorDatabase) — the exclude param only
## matters for a forced visitor reused from the ordinary pool, like the
## upyr_* ones below.
## "day_cap"/"night_cap": override DAY_VISITOR_CAP/SCRIPTED_NIGHT_CAP
## for that day/night only. Day 7's night_cap is 1 (no random upyr
## before the priest) — every other scripted night defaults to
## SCRIPTED_NIGHT_CAP (a couple of ordinary нечисть before tonight's
## scripted one, not night-then-immediately-morning).
const CHAPTER1_SCRIPT := {
	1: {"day": "res://data/visitors/special/forest_warden_day1.tres", "night": "res://data/visitors/special/mavka_night1.tres"},
	2: {"day": "res://data/visitors/special/forest_warden_day2.tres", "night": "res://data/visitors/upyr_brutal_male.tres"},
	3: {"day": "res://data/visitors/special/forest_warden_day3.tres", "night": "res://data/visitors/special/nichnytsia_night3.tres"},
	4: {"day": "res://data/visitors/special/forest_warden_day4.tres", "night": "res://data/visitors/upyr_hidden_female.tres"},
	5: {"day": "res://data/visitors/special/forest_warden_day5.tres", "night": "res://data/visitors/upyr_seeking_cure.tres"},
	6: {"night": "res://data/visitors/special/upyr_night6_strange.tres"},
	7: {"day": "res://data/visitors/special/visnyk_day7.tres", "day_cap": 1, "night": "res://data/visitors/special/priest_day7.tres", "night_cap": 1},
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
@onready var day_night_toast: DayNightToast = $DayNightToast
@onready var pause_menu: PauseMenu = $PauseMenu

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

	var restored := _restore_from_save()
	_update_calendar_label()
	if restored:
		# A loaded game already has whatever the player actually held —
		# topping it back up would hand back exactly the potions they
		# just spent, so the debug seeding below is for fresh games only.
		_knock_with_random_visitor()
		return

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

	# DEBUG: seed a generous stock of every potion AND every sigil so a
	# full click-through of Розділ 1 never runs dry mid-chapter — several
	# recipes (calming_remedy, cleansing_remedy, zigzag_ward...) get asked
	# for more than once across 7 days, by both the scripted beats and
	# the ordinary background rotation. Remove once brewing/carving are
	# the only way these actually enter the inventory.
	for potion in PotionDatabase.get_all():
		if not PlayerInventory.has(potion.id):
			PlayerInventory.add(potion.id, DEBUG_SEED_AMOUNT)
	for sigil in SigilDatabase.get_all():
		if not PlayerInventory.has(sigil.id):
			PlayerInventory.add(sigil.id, DEBUG_SEED_AMOUNT)

	_knock_with_random_visitor()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_on_cancel_pressed()
		return
	if _any_overlay_open():
		return
	if event.is_action_pressed(&"ui_left"):
		_go_left()
	elif event.is_action_pressed(&"ui_right"):
		_go_right()

## Esc backs out one step at a time rather than always jumping to the
## pause menu: close whatever lookup panel is open, and only pause once
## the hut itself is what's on screen.
##
## The modal activities are deliberately excluded. ThresholdDialogue and
## ReceptionUI are mid-decision — Esc there would be an invisible third
## answer alongside invite/refuse — and BrewingUI/CarvingUI are
## multi-step with their own in-progress state to unwind, so both keep
## their own Back buttons as the only way out.
func _on_cancel_pressed() -> void:
	if threshold_dialogue.visible or reception_ui.visible or brewing_ui.visible or carving_ui.visible:
		return
	# Untyped on purpose: these are four unrelated classes that happen to
	# share visible/close(), not a common base, so the call is dynamic.
	for panel in [potion_detail_popup, ingredient_inventory_panel, potion_inventory_panel,
			sigil_inventory_panel, chest_panel, calendar_panel, grimoire_ui]:
		if panel.visible:
			panel.close()
			return
	pause_menu.open()

func _any_overlay_open() -> bool:
	return threshold_dialogue.visible or brewing_ui.visible or potion_detail_popup.visible \
		or carving_ui.visible or reception_ui.visible or ingredient_inventory_panel.visible \
		or potion_inventory_panel.visible or sigil_inventory_panel.visible \
		or calendar_panel.visible or chest_panel.visible or grimoire_ui.visible

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
		if not visitor.is_human():
			# Counted on crossing the threshold, not on being served:
			# what the village would notice is someone being let in at
			# all, the same "seen at the door is enough" reasoning behind
			# Visitor.knocked_sets_flag. Any нечисть counts, day or
			# night — the priest's charge on day 7 is helping them, not
			# specifically after dark.
			VillageSuspicion.record_sheltered()
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
			_night_quota = _roll_night_quota()
			_night_visitor_count = 0
			_night_forced_used = false
			GameCalendar.set_phase(GameCalendar.Phase.NIGHT)
			day_night_toast.show_message("Ніч %d" % _story_day)
			SaveGame.save(_story_day)
	else:
		_night_visitor_count += 1
		if _night_visitor_count >= _night_quota:
			if _story_day >= CHAPTER1_LAST_DAY:
				_end_chapter()
				return
			GameCalendar.advance_day()
			VisitorDatabase.reset_seen()
			_day_visitor_count = 0
			_day_forced_used = false
			_story_day += 1
			GameCalendar.set_phase(GameCalendar.Phase.DAY)
			day_night_toast.show_message("День %d" % _story_day)
			SaveGame.save(_story_day)

## Розділ І is over — there is no day 8. Writes the finished save (so the
## menu's "Продовжити" can bring the player back to their own chronicle
## rather than to a hut with nothing left to happen in it) and hands over
## to ChapterEnd, which reads the live autoload state directly.
func _end_chapter() -> void:
	SaveGame.save(_story_day, true)
	get_tree().change_scene_to_file(CHAPTER_END_SCENE)

## Pulls the autosave back in, if the menu asked for it. Only _story_day
## and the calendar phase come from the file — every slot counter below
## is rebuilt instead, since SaveGame only ever writes at a day/night
## flip, which is exactly when they're all at their just-reset values.
func _restore_from_save() -> bool:
	if not SaveGame.pending_load:
		return false
	SaveGame.pending_load = false
	var saved_day := SaveGame.load_game()
	if saved_day <= 0:
		return false
	_story_day = saved_day
	if GameCalendar.phase == GameCalendar.Phase.NIGHT:
		_night_visitor_count = 0
		_night_forced_used = false
		_night_quota = _roll_night_quota()
	else:
		_day_visitor_count = 0
		_day_forced_used = false
	return true

func _current_day_cap() -> int:
	var script: Dictionary = CHAPTER1_SCRIPT.get(_story_day, {})
	return script.get("day_cap", DAY_VISITOR_CAP)

## How many visitors tonight gets. A scripted night is a fixed number
## (the beat has to land on the last slot, so it can't be random); an
## unscripted freeplay night rolls fresh, which is why this is a roll
## stored in _night_quota rather than a cap recomputed on demand.
func _roll_night_quota() -> int:
	var script: Dictionary = CHAPTER1_SCRIPT.get(_story_day, {})
	return script.get("night_cap", SCRIPTED_NIGHT_CAP) if script.has("night") \
		else randi_range(NIGHT_VISITOR_MIN, NIGHT_VISITOR_MAX)

func _knock_with_random_visitor() -> void:
	var is_night := GameCalendar.phase == GameCalendar.Phase.NIGHT
	var visitor := _pop_forced_visitor(is_night)
	if visitor == null:
		# Exclude today's/tonight's own forced visitor (if any) from the
		# ordinary random slots leading up to it — see CHAPTER1_SCRIPT's
		# doc. A plain load(), not _load_forced_visitor(): just a peek
		# for identity comparison, no knocked_sets_flag side effect yet.
		var todays_forced := _peek_forced_path(is_night)
		var exclude: Visitor = load(todays_forced) if todays_forced != "" else null
		visitor = VisitorDatabase.get_random(is_night, exclude)
	if visitor == null:
		# Nobody eligible this slot — VisitorDatabase's own fallback tier
		# should make this rare, but a silent door with nothing scheduled
		# to follow it is a hard freeze (nothing left to call
		# _advance_visitor_slot again), so treat it as an empty knock and
		# keep the day/night moving instead of just stopping dead here.
		_schedule_next_knock()
		return
	door.knock(visitor, WardRack.check_visitor(visitor))

func _peek_forced_path(is_night: bool) -> String:
	var script: Dictionary = CHAPTER1_SCRIPT.get(_story_day, {})
	return script.get("night" if is_night else "day", "")

## Розділ 1's deterministic override of the ordinary random pool — see
## CHAPTER1_SCRIPT. Returns null (falls back to VisitorDatabase.get_random)
## whenever today/tonight has no scripted visitor, it's already been used,
## or this isn't yet that phase's last slot (cap - 1).
func _pop_forced_visitor(is_night: bool) -> Visitor:
	var script: Dictionary = CHAPTER1_SCRIPT.get(_story_day, {})
	if is_night:
		if _night_forced_used or not script.has("night"):
			return null
		if _night_visitor_count != _night_quota - 1:
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
	VisitorDatabase.register_shown(visitor)
	return visitor

## Розділ 1 is a fixed 7-day span, not tied to any real festival date, so
## the label just counts chapter days instead of showing GameCalendar's
## season/festival calendar (see CalendarPanel, dropped from `zones`
## below for the same reason — nothing in this chapter uses it).
func _update_calendar_label(_arg = null) -> void:
	var phase_text := "ніч" if GameCalendar.phase == GameCalendar.Phase.NIGHT else "день"
	calendar_label.text = "День %d — %s" % [_story_day, phase_text]
