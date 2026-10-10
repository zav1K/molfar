class_name TutorialHints
extends CanvasLayer
## Three one-time lines telling the player how the screen works.
##
## Scoped hard, on purpose. The molfar is an old master, so nothing may
## explain his own craft to him — a tutorial through a character who
## doesn't know things is impossible in this chapter (see TODO_DEMO.md).
## These stay at the level of the interface: which parts of the screen
## move, which buttons exist, where an item comes from. Never what a
## потерча is, never which відвар to brew.
##
## Each fires once ever and is remembered in StoryFlags, so it survives
## a reload and comes back on a new game (StoryFlags is cleared by
## SaveGame.reset_for_new_game). Deliberately not gated to day 1: if the
## player somehow reaches the cauldron for the first time on day three,
## that is exactly when the line is worth reading.
##
## Sits above the day/night toast and anchors to the bottom, so the two
## never fight for the same strip of screen.

const FADE_TIME := 0.5
const HOLD_TIME := 4.5 ## a sentence to read, against the toast's 1.6s glance.
const FLAG_PREFIX := "hint_"

@onready var panel: PanelContainer = $Panel
@onready var label: Label = $Panel/Label

var _queue: Array[String] = []
var _tween: Tween

func _ready() -> void:
	panel.modulate.a = 0.0

## Shows `text` the first time it is asked for under `id`, and never
## again. Returns whether it actually showed, which callers ignore —
## it's there for the probe.
func show_once(id: StringName, text: String) -> bool:
	var flag := StringName(FLAG_PREFIX + String(id))
	if StoryFlags.has_flag(flag):
		return false
	StoryFlags.set_flag(flag)
	_queue.append(text)
	if _tween == null or not _tween.is_valid():
		_play_next()
	return true

## Queued rather than replaced: two hints can be earned by one click
## (opening the door for the first time also being the first visitor),
## and the second overwriting the first mid-fade would show neither
## long enough to read.
func _play_next() -> void:
	if _queue.is_empty():
		return
	label.text = _queue.pop_front()
	panel.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(panel, "modulate:a", 1.0, FADE_TIME)
	_tween.tween_interval(HOLD_TIME)
	_tween.tween_property(panel, "modulate:a", 0.0, FADE_TIME)
	_tween.finished.connect(_play_next, CONNECT_ONE_SHOT)
