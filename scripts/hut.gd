extends Node2D
## Root controller for the molfar's hut: three fixed camera panels
## (казан+піч / стіл+двері / скриня+полиці+вікно-город), navigated by
## arrow keys or on-screen buttons, plus zone click routing.

const PANEL_WIDTH := 960.0
const PANEL_HEIGHT := 540.0
const PANEL_COUNT := 3
const TWEEN_TIME := 0.45
const DOOR_ZOOM := 1.6
## The old molfar's standing stock. Low on purpose: the point is that it
## runs out. At ten of every brew and every sigil the whole chapter could
## be played without lighting the cauldron once, which is half the game
## skipped. Three covers the opening days and then the player has to
## make things. See the seeding block in _ready().
## Enough of every herb to keep brewing; see the seeding block.
const STARTING_HERBS := 10
const STARTING_STOCK := 3
const DAY_VISITOR_CAP := 5 ## how many day clients knock before night falls.
const NIGHT_VISITOR_MIN := 3 ## night нечисть quota is rolled fresh each night, in this range —
const NIGHT_VISITOR_MAX := 5 ## only outside the Розділ 1 script below (freeplay after it ends).
const SCRIPTED_NIGHT_CAP := 3 ## default night_cap for a scripted night — see CHAPTER1_SCRIPT.
const CHAPTER1_LAST_DAY := 7 ## after this night the chapter ends — see _end_chapter().
const CHAPTER_END_SCENE := "res://scenes/ChapterEnd.tscn"

## Day and night were visually identical — the only cue was a toast that
## had already faded by the time the first night visitor knocked. The
## tint is a CanvasModulate on the root Node2D, so it colours the hut
## and everything in it while leaving the UI alone: CanvasLayers each
## have their own canvas and are not touched, which is exactly what we
## want, since dialogue has to stay readable at midnight.
const DAY_TINT := Color(1.0, 0.98, 0.94)
const NIGHT_TINT := Color(0.52, 0.60, 0.80)
## Long enough to feel like dusk rather than a light switch. It runs
## alongside the ambience crossfade, which is the same length.
const TINT_FADE_SECONDS := 2.5

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
## for that day/night only. Most scripted nights use the default (a
## couple of ordinary нечисть before tonight's scripted one, not
## night-then-immediately-morning).
##
## "<phase>_opens": a list of beats filling the phase's FIRST slots, one
## each from slot 0, where "day"/"night" above fill the LAST one. Only
## Day 7 uses it, and it is what makes that day work at all.
##
## Everything that reacts to Лісник's death is gated behind the flag the
## Вісник sets when he announces it — and he is Day 7's own beat, with no
## day 8 after him. Left as a closing beat he arrived last, so the
## elder's warning about the hunt, the widow with tar on her gate and the
## upyr running from it could never appear at all: one of them
## (hail_elder_followup) even feeds a diary entry that was therefore
## unreachable. So Day 7 opens with the news and then spends three slots
## on the village reacting to it, and its night fits one more нечусть
## before the priest arrives to forbid helping exactly that kind of
## visitor. Scripted rather than pooled because these are the story, and
## the pool would only seat each of them some of the time.
const CHAPTER1_SCRIPT := {
	1: {"day": "res://data/visitors/special/forest_warden_day1.tres", "night": "res://data/visitors/special/mavka_night1.tres"},
	2: {"day": "res://data/visitors/special/forest_warden_day2.tres", "night": "res://data/visitors/upyr_brutal_male.tres"},
	3: {"day": "res://data/visitors/special/forest_warden_day3.tres", "night": "res://data/visitors/special/nichnytsia_night3.tres"},
	4: {"day": "res://data/visitors/special/forest_warden_day4.tres", "night": "res://data/visitors/upyr_hidden_female.tres"},
	5: {"day": "res://data/visitors/special/forest_warden_day5.tres", "night": "res://data/visitors/upyr_seeking_cure.tres"},
	# night_cap 2, not the usual 3: tonight's beat is the same упир the
	# player knows, so his whole group is blocked for the phase, and the
	# leftover pool this late could not fill two random slots without
	# handing out the same woman twice. A quiet night also reads right
	# for the one before Лісник is found dead.
	6: {"night": "res://data/visitors/special/upyr_night6_strange.tres", "night_cap": 2},
	7: {
		"day_opens": [
			"res://data/visitors/special/visnyk_day7.tres",
			"res://data/visitors/special/hail_elder_followup.tres",
			"res://data/visitors/accused_widow.tres",
		],
		"day_cap": 4,
		"night_opens": [
			"res://data/visitors/upyr_fleeing_hunt.tres",
			"res://data/visitors/vurdalak_lisnyk.tres",
		],
		"night": "res://data/visitors/special/priest_day7.tres",
		"night_cap": 3,
	},
}

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
@onready var day_night_tint: CanvasModulate = $DayNightTint

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
var _day_visitor_count: int = 0
var _night_visitor_count: int = 0
var _night_quota: int = NIGHT_VISITOR_MIN
## Today's suspicion aside, held between the knock and both screens that
## show it — see _take_suspicion_remark and ThresholdDialogue.
var _pending_aside: String = ""
var _suspicion_remark_day: int = 0 ## _story_day that already spent its one remark.
## Cost of the night just passed, charged against tomorrow — see
## _current_day_cap for why it only moves across at dawn.
var _pending_day_penalty: int = 0
var _day_penalty: int = 0
## Set by _end_chapter; see _schedule_next_knock for why a flag and not
## just an is_inside_tree() check.
var _chapter_over: bool = false

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
	VillageSuspicion.level_changed.connect(_on_suspicion_level_changed)
	GameCalendar.phase_changed.connect(_on_phase_changed_tint)
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

	AudioDirector.start_loop(&"fire_loop")
	var restored := _restore_from_save()
	# Straight to the right colour, no fade: a restored night should
	# already be night on the first frame, not dawn turning into it.
	day_night_tint.color = _tint_for(GameCalendar.phase)
	_update_calendar_label()
	if restored:
		# A loaded game already has whatever the player actually held —
		# topping it back up would hand back exactly the potions they
		# just spent, so the debug seeding below is for fresh games only.
		_knock_with_random_visitor()
		return

	# What forty years in the trade leaves on the shelves. The player is
	# the OLD molfar, so a full drying beam is characterisation, not a
	# debug shortcut — gathering herbs is the HEIR's problem and belongs
	# to the full game, where the hut starts bare (see Molfar and
	# CONCEPT.md's "Демка — це приквел").
	#
	# Herbs are plentiful and finished work is not, which is the whole
	# shape of it: having herbs is what makes the player brew, having
	# brews is what stops them. At ten of every remedy the chapter could
	# be played start to finish without lighting the cauldron once.
	# Measured against one playthrough's actual demand, three leaves the
	# cleansing remedy four short, the calming one three short and the
	# spiral ward one short — so the cauldron and the knife both become
	# necessary somewhere around the third day.
	for ingredient in IngredientDatabase.get_all():
		if not PlayerInventory.has(ingredient.id):
			PlayerInventory.add(ingredient.id, STARTING_HERBS)
	for potion in PotionDatabase.get_all():
		if not PlayerInventory.has(potion.id):
			PlayerInventory.add(potion.id, STARTING_STOCK)
	for sigil in SigilDatabase.get_all():
		if not PlayerInventory.has(sigil.id):
			PlayerInventory.add(sigil.id, STARTING_STOCK)

	# A garlic ward is already hanging: a man who has worked nights for
	# decades would not leave the door bare. Also what makes the door
	# hint visible from the first knock.
	if WardRack.get_slot(0) == &"":
		WardRack.hang(0, &"garlic")

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
	AudioDirector.play(&"floorboard")
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
	AudioDirector.play(&"door_open")
	var tw := create_tween().set_parallel(true)
	tw.tween_property(camera, "position", engaged_door.global_position, TWEEN_TIME)
	tw.tween_property(camera, "zoom", Vector2(DOOR_ZOOM, DOOR_ZOOM), TWEEN_TIME)
	tw.finished.connect(func() -> void: threshold_dialogue.show_visitor(visitor, _pending_aside), CONNECT_ONE_SHOT)

func _on_visitor_resolved(invited: bool) -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(camera, "position", _panel_center(current_panel), TWEEN_TIME)
	tw.tween_property(camera, "zoom", Vector2.ONE, TWEEN_TIME)
	var visitor := door.current_visitor
	# Either answer ends with the door shutting — behind them if they
	# were let in, in their face if they were not. Opening already played
	# when the player engaged the door (see _on_visitor_engaged).
	AudioDirector.play(&"door_close")
	var consequence := _apply_threshold_consequences(visitor, invited)
	if invited:
		if not visitor.is_human():
			# Counted on crossing the threshold, not on being served:
			# what the village would notice is someone being let in at
			# all, the same "seen at the door is enough" reasoning behind
			# Visitor.knocked_sets_flag. Any нечисть counts, day or
			# night — the priest's charge on day 7 is helping them, not
			# specifically after dark.
			VillageSuspicion.record_sheltered()
		door.clear()
		# The consequence replaces the suspicion aside rather than
		# stacking with it: what just happened in the hut outranks what
		# a neighbour was muttering about on the doorstep. Stored rather
		# than passed, because the reception screen no longer opens here.
		if consequence != "":
			_pending_aside = consequence
		# Inviting someone in does NOT start the conversation. The
		# dialogue closes, the camera pulls back, and they are simply
		# standing in the hut — the player gets a beat to look at who
		# they just let in before any business starts. Click them to
		# talk. It matters most for the вурдалаки, whose whole scene is
		# the gap between the thing at the door and the thing inside.
		_show_visitor_inside(visitor, false)
		return
	door.clear()
	if consequence != "":
		# Refusing opens no ReceptionUI, so the toast is the only place
		# left to say why tomorrow is going to be a short day.
		day_night_toast.show_message(consequence)
	nav_left.visible = true
	nav_right.visible = true
	_schedule_next_knock()

## Resolves everything a Visitor does at the invite/refuse choice itself
## rather than in ReceptionUI — see the threshold block in visitor.gd.
## Returns a line describing what happened, for whichever channel the
## caller has available, or "" when this visitor does nothing special.
func _apply_threshold_consequences(visitor: Visitor, invited: bool) -> String:
	if not invited:
		if visitor.refused_shortens_next_day > 0:
			_pending_day_penalty += visitor.refused_shortens_next_day
			return "Воно шкреблося до світанку. Ти не спав."
		return ""

	var lines: Array[String] = []
	if visitor.invited_sets_flag != &"":
		StoryFlags.set_flag(visitor.invited_sets_flag)
		if visitor.invited_flavor_text != "":
			lines.append(visitor.invited_flavor_text)
	if visitor.invited_destroys_ward:
		var burnt := WardRack.consume_against(visitor)
		if burnt != &"":
			var ingredient := IngredientDatabase.get_ingredient(burnt)
			var what: String = ingredient.display_name if ingredient != null else String(burnt)
			lines.append("Оберіг над дверима (%s) почорнів і розсипався." % what)
	if visitor.invited_steals_count > 0:
		var taken := _ransack(visitor.invited_steals_count)
		if taken > 0:
			lines.append("Поки воно було в хаті, зі скрині зникло: %d." % taken)
	if visitor.invited_shortens_next_day > 0:
		_pending_day_penalty += visitor.invited_shortens_next_day
		lines.append("Завтра піде на те, щоб скласти хату докупи.")
	return "\n".join(lines)

## Takes up to `count` items from whatever the player actually holds,
## never more than one of each, so a single stack can't be wiped out.
## Returns how many were taken.
func _ransack(count: int) -> int:
	var held := PlayerInventory.get_held_ids()
	held.shuffle()
	var taken := 0
	for item_id in held:
		if taken >= count:
			break
		PlayerInventory.remove(item_id, 1)
		taken += 1
	return taken

func _on_reception_closed() -> void:
	nav_left.visible = true
	nav_right.visible = true
	_waiting_visitor = null
	waiting_indicator.visible = false
	waiting_visitor_display.hide_visitor()
	_schedule_next_knock()

func _on_visitor_wait_requested(visitor: Visitor) -> void:
	_show_visitor_inside(visitor, true)

## Puts a visitor on their feet in the hut and hands the player back
## control, for the two moments that look the same on screen: just
## invited in, and asked to wait while something gets brewed.
##
## Nobody ever leaves on their own. A visitor used to give up after a
## minute, which quietly pushed the player to hurry — wrong for a game
## whose whole appetite is standing still and reading a face. They stay
## until they are dealt with, however long that takes.
##
## `asked_to_wait` only changes the label, so the player can tell a
## request they have already heard from one they have not.
func _show_visitor_inside(visitor: Visitor, asked_to_wait: bool) -> void:
	nav_left.visible = true
	nav_right.visible = true
	_waiting_visitor = visitor
	waiting_indicator.text = ("Клієнт чекає: %s" if asked_to_wait else "У хаті: %s") % visitor.display_name
	waiting_indicator.visible = true
	waiting_visitor_display.show_visitor(visitor)

func _on_waiting_indicator_pressed() -> void:
	if _waiting_visitor == null:
		return
	waiting_indicator.visible = false
	waiting_visitor_display.hide_visitor()
	nav_left.visible = false
	nav_right.visible = false
	reception_ui.show_visitor(_waiting_visitor, _pending_aside)

func _schedule_next_knock() -> void:
	_advance_visitor_slot()
	# _advance_visitor_slot may have just ended the chapter, which swaps
	# ChapterEnd in and frees this node. Both checks are needed: the
	# scene change is deferred, so right here the tree is still valid and
	# only the flag knows, while after the await the node itself is gone
	# and get_tree() would return null.
	if _chapter_over:
		return
	await get_tree().create_timer(2.0).timeout
	if _chapter_over or not is_inside_tree():
		return
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
			_day_penalty = _pending_day_penalty
			_pending_day_penalty = 0
			_story_day += 1
			GameCalendar.set_phase(GameCalendar.Phase.DAY)
			day_night_toast.show_message("День %d" % _story_day)
			SaveGame.save(_story_day)

## Розділ І is over — there is no day 8. Writes the finished save (so the
## menu's "Продовжити" can bring the player back to their own chronicle
## rather than to a hut with nothing left to happen in it) and hands over
## to ChapterEnd, which reads the live autoload state directly.
func _end_chapter() -> void:
	_chapter_over = true
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
	_day_penalty = 0
	_pending_day_penalty = 0
	if GameCalendar.phase == GameCalendar.Phase.NIGHT:
		_night_visitor_count = 0
		_night_forced_used = false
		_night_quota = _roll_night_quota()
	else:
		_day_visitor_count = 0
		_day_forced_used = false
	return true

## Today's cap, already reduced by whatever last night cost (see
## _apply_threshold_consequences). The penalty is only ever moved in at
## dawn, never mid-phase: _pop_forced_visitor positions the day's beat
## against this number, so changing it under a running day would move
## the beat's slot out from under it.
##
## The floor keeps a punished day from eating the chapter: never below
## one ordinary caller after however many scripted beats open the day,
## or Day 7's widow and elder would simply be cut.
func _current_day_cap() -> int:
	var script: Dictionary = CHAPTER1_SCRIPT.get(_story_day, {})
	var cap: int = script.get("day_cap", DAY_VISITOR_CAP)
	var opens: Array = script.get("day_opens", [])
	return maxi(opens.size() + 1, cap - _day_penalty)

## How many visitors tonight gets. A scripted night is a fixed number
## (the beat has to land on the last slot, so it can't be random); an
## unscripted freeplay night rolls fresh, which is why this is a roll
## stored in _night_quota rather than a cap recomputed on demand.
func _roll_night_quota() -> int:
	var script: Dictionary = CHAPTER1_SCRIPT.get(_story_day, {})
	return script.get("night_cap", SCRIPTED_NIGHT_CAP) if script.has("night") \
		else randi_range(NIGHT_VISITOR_MIN, NIGHT_VISITOR_MAX)

## At most one suspicion aside per day, and only from an ordinary human
## client in daylight: нечисть has no reason to gossip about the molfar
## sheltering нечисть, and a remark on every visitor stops reading as
## pointed and starts reading as filler. Empty string means "nothing to
## say" — either the village hasn't noticed yet, or today's remark is
## already spent.
func _take_suspicion_remark(visitor: Visitor) -> String:
	if GameCalendar.phase == GameCalendar.Phase.NIGHT or not visitor.is_human():
		return ""
	if _suspicion_remark_day == _story_day:
		return ""
	var remark := VillageSuspicion.random_remark()
	if remark != "":
		_suspicion_remark_day = _story_day
	return remark

func _tint_for(phase: int) -> Color:
	return NIGHT_TINT if phase == GameCalendar.Phase.NIGHT else DAY_TINT

func _on_phase_changed_tint(phase: int) -> void:
	create_tween().tween_property(day_night_tint, "color", _tint_for(phase), TINT_FADE_SECONDS)

## The village crossing into talking about him, or into having made up
## its mind. Toast + diary entry rather than a number on screen: the
## player should feel the room cool, not read a counter.
func _on_suspicion_level_changed(level: VillageSuspicion.Level) -> void:
	if level == VillageSuspicion.Level.NOTICED:
		StoryFlags.set_flag(&"village_noticed_nechyst")
		day_night_toast.show_message("У селі почали говорити")
	elif level == VillageSuspicion.Level.MARKED:
		StoryFlags.set_flag(&"village_marked_nechyst")
		day_night_toast.show_message("Село вирішило, хто ти")

func _knock_with_random_visitor() -> void:
	var is_night := GameCalendar.phase == GameCalendar.Phase.NIGHT
	var visitor := _pop_forced_visitor(is_night)
	if visitor == null:
		# Keep the random slots off every story beat still to come, and
		# off today's beat's whole recurring_group — see get_random's doc
		# for why those two scopes differ. Plain load()s, not
		# _load_forced_visitor(): just peeks for identity comparison, no
		# knocked_sets_flag side effects yet.
		var exclude := _forced_from_today_on(is_night)
		var exclude_groups: Array[StringName] = []
		var todays_forced := _peek_forced_path(is_night)
		if todays_forced != "":
			var todays: Visitor = load(todays_forced)
			if todays.recurring_group != &"":
				exclude_groups.append(todays.recurring_group)
		visitor = VisitorDatabase.get_random(is_night, exclude, exclude_groups)
	if visitor == null:
		# Nobody eligible this slot — VisitorDatabase's own fallback tier
		# should make this rare, but a silent door with nothing scheduled
		# to follow it is a hard freeze (nothing left to call
		# _advance_visitor_slot again), so treat it as an empty knock and
		# keep the day/night moving instead of just stopping dead here.
		_schedule_next_knock()
		return
	_pending_aside = _take_suspicion_remark(visitor)
	# The door is only announced once the knocking has finished: with
	# samples up to 3.6s long, offering the door on the first thump let
	# the player answer a knock still in progress, which read as the hut
	# opening itself.
	var knock_seconds := AudioDirector.play(&"knock")
	if knock_seconds > 0.0:
		await get_tree().create_timer(knock_seconds).timeout
		if _chapter_over or not is_inside_tree():
			return
	door.knock(visitor, WardRack.check_visitor(visitor))

## Every forced story beat for this phase on today or any later day —
## the set the ordinary random rotation must not spoil. See get_random.
func _forced_from_today_on(is_night: bool) -> Array[Visitor]:
	var out: Array[Visitor] = []
	var key := "night" if is_night else "day"
	for day in CHAPTER1_SCRIPT:
		if day < _story_day:
			continue
		var script: Dictionary = CHAPTER1_SCRIPT[day]
		var path: String = script.get(key, "")
		if path != "":
			out.append(load(path))
		for opening: String in script.get(key + "_opens", []):
			out.append(load(opening))
	return out

func _peek_forced_path(is_night: bool) -> String:
	var script: Dictionary = CHAPTER1_SCRIPT.get(_story_day, {})
	return script.get("night" if is_night else "day", "")

## Розділ 1's deterministic override of the ordinary random pool — see
## CHAPTER1_SCRIPT. Returns null (falls back to VisitorDatabase.get_random)
## whenever today/tonight has no scripted visitor, it's already been used,
## or this isn't yet that phase's last slot (cap - 1).
func _pop_forced_visitor(is_night: bool) -> Visitor:
	var script: Dictionary = CHAPTER1_SCRIPT.get(_story_day, {})
	var key := "night" if is_night else "day"
	# Opening beats first, one per slot from 0 — these are scripted
	# rather than left to the pool because they are the chapter's story,
	# and the pool would only give each one a slot some of the time.
	var opens: Array = script.get(key + "_opens", [])
	var opening_slot := _night_visitor_count if is_night else _day_visitor_count
	if opening_slot < opens.size():
		var opening: Visitor = load(opens[opening_slot])
		# An opening beat can be conditional: the hidden upyr comes back
		# on the last night to warn the molfar only if he sheltered her
		# in the first place. An unmet condition falls through to the
		# ordinary pool rather than leaving the slot empty.
		if opening.required_flag == &"" or StoryFlags.has_flag(opening.required_flag):
			return _load_forced_visitor(opens[opening_slot])
		return null
	if not script.has(key):
		return null
	if _night_forced_used if is_night else _day_forced_used:
		return null
	var slot := _night_visitor_count if is_night else _day_visitor_count
	var quota := _night_quota if is_night else _current_day_cap()
	if slot != quota - 1:
		return null
	if is_night:
		_night_forced_used = true
	else:
		_day_forced_used = true
	return _load_forced_visitor(script[key])

## Loads a scripted visitor and replicates get_random()'s knocked_sets_flag
## side effect — forced visitors bypass VisitorDatabase entirely, so
## nothing else sets it for them. The priest's finale line also depends on
## how the Day 4 упириця encounter went, which satisfied_sets_flag already
## recorded regardless of how this visitor is reached — so that part needs
## no special-casing here, just a duplicate + append once it's loaded.
const PRIEST_DAY7_PATH := "res://data/visitors/special/priest_day7.tres"

func _load_forced_visitor(path: String) -> Visitor:
	var visitor: Visitor = load(path)
	if path == PRIEST_DAY7_PATH:
		visitor = _tailor_priest(visitor)
	if visitor.knocked_sets_flag != &"":
		StoryFlags.set_flag(visitor.knocked_sets_flag)
	VisitorDatabase.register_shown(visitor)
	return visitor

## The chapter's last scene, rewritten to match how the player actually
## played it. The base resource is the general warning — what the priest
## says to a molfar he has nothing on. The more нечисть the player
## sheltered, the less it is a warning and the more it is a move against
## him specifically, which is what should make the player doubt the man
## without a word of the real twist being spoken.
##
## Always on a duplicate: Visitor resources are cached and shared, so
## editing the loaded one would leave the tailored text in place for the
## rest of the session.
func _tailor_priest(base: Visitor) -> Visitor:
	var extra: Array[String] = []
	if StoryFlags.has_flag(&"helped_hidden_upyr"):
		extra.append("Хтось у селі вже казав, що бачив тебе з нею.")
	var suspicion := VillageSuspicion.level()
	if suspicion == VillageSuspicion.Level.MARKED:
		extra.append("І не думай, що я не знаю, скільком ти відчиняв. Поки що я говорю з тобою без людей. Поки що.")
	elif suspicion == VillageSuspicion.Level.NOTICED:
		extra.append("Про тебе теж уже говорять. Не давай людям більше причин.")
	if extra.is_empty():
		return base
	var visitor: Visitor = base.duplicate()
	# problem_text ends with a closing quote mark (speech-styled, like
	# every other visitor's) — trim it, append inside the speech, and
	# re-close, rather than tacking text on after the quote.
	visitor.problem_text = "%s %s\"" % [visitor.problem_text.trim_suffix("\""), " ".join(extra)]
	return visitor

## Розділ 1 is a fixed 7-day span, not tied to any real festival date, so
## the label just counts chapter days instead of showing GameCalendar's
## season/festival calendar (see CalendarPanel, dropped from `zones`
## below for the same reason — nothing in this chapter uses it).
func _update_calendar_label(_arg = null) -> void:
	var phase_text := "ніч" if GameCalendar.phase == GameCalendar.Phase.NIGHT else "день"
	calendar_label.text = "День %d — %s" % [_story_day, phase_text]
