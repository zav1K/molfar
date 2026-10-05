extends Node
## Dev harness, not shipped content: plays Розділ І from the first knock
## to the closing chronicle through the real Hut scene and the real
## signal flow, at 60x speed, answering the door at random.
##
## Run it headless and watch stderr:
##     godot --headless --path . res://tools/ChapterPlaythrough.tscn
##
## Worth keeping because it exercises what no parse check can: the knock
## loop, the threshold decision, the reception screen, the day/night
## flips and the chapter ending, in the order a player meets them. It
## earned its place by catching an error spew in _schedule_next_knock
## that only happened on the final night, after the chapter had already
## swapped the scene out.
##
## Nothing here calls into private methods for convenience' sake — the
## two it does touch (Door._on_activated, ReceptionUI's button handlers)
## stand in for mouse clicks that headless has no way to deliver.

const TIME_SCALE := 60.0
const DEADLINE_SECONDS := 25.0 ## wall clock, see _ready
const FRAME_LIMIT := 20000
const INVITE_CHANCE := 0.55

var hut: Node2D
var clicked: Visitor
var knocks := 0
var frames := 0
var days_seen := {}

func _ready() -> void:
	Engine.time_scale = TIME_SCALE
	hut = load("res://scenes/Hut.tscn").instantiate()
	add_child(hut)
	# Ending the chapter frees this node along with the current scene, so
	# nothing here can stop the run afterwards. ignore_time_scale, or the
	# 60x would eat the deadline too.
	get_tree().create_timer(DEADLINE_SECONDS, true, false, true).timeout.connect(
		func() -> void:
			print("[playthrough] deadline reached")
			get_tree().quit())

func _process(_delta: float) -> void:
	frames += 1
	if frames > FRAME_LIMIT:
		push_error("[playthrough] stalled at %s" % _state())
		get_tree().quit()
		return
	if not is_instance_valid(hut) or hut.get_parent() == null:
		return
	if not days_seen.has(hut._story_day):
		days_seen[hut._story_day] = true
		print("[playthrough] day %d (knocks so far: %d)" % [hut._story_day, knocks])

	# The door only opens the dialogue when clicked — and exactly once
	# per visitor: every click starts a camera tween, so clicking each
	# frame while that tween runs buries the engine in them.
	if hut.door.current_visitor != null and not hut.threshold_dialogue.visible \
			and not hut.reception_ui.visible:
		if hut.door.current_visitor != clicked:
			clicked = hut.door.current_visitor
			hut.door._on_activated(null)
		return
	if hut.threshold_dialogue.visible:
		knocks += 1
		hut.threshold_dialogue._resolve(randf() < INVITE_CHANCE)
		return
	if hut.reception_ui.visible:
		if hut.reception_ui._resolved:
			hut.reception_ui._on_finish_pressed()
		else:
			hut.reception_ui._on_send_away_pressed()
		return
	if hut._story_day > 7:
		push_error("[playthrough] reached day 8 — the chapter never ended")
		get_tree().quit()

func _state() -> String:
	return "day %d, phase %s, slots %d/%d, knocks %d" % [
		hut._story_day, GameCalendar.phase,
		hut._day_visitor_count, hut._night_visitor_count, knocks]

func _exit_tree() -> void:
	print("[playthrough] days reached: %s, knocks: %d" % [days_seen.keys(), knocks])
