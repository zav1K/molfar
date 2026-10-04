class_name TypewriterLabel
extends ScrollContainer
## Reveals text a character at a time inside a fixed-height box instead
## of all at once, auto-scrolling to follow — long dialogue scrolls
## internally as it prints instead of overflowing into whatever's laid
## out below it (buttons, the next panel...). Click anywhere on it (or
## any button underneath it) to skip straight to the full text.
##
## horizontal_scroll_mode must stay disabled (set in the scene) so the
## inner Label is forced to this container's width and only grows
## vertically — same ScrollContainer-locks-the-cross-axis setup already
## used by GrimoireUI's/InventoryPanel's lists, just with one Label
## instead of a list of rows.

const CHARS_PER_SECOND := 45.0
const MAX_SCROLL := 1000000 ## larger than any real content height — ScrollContainer clamps.

@onready var label: Label = $Label

var _full_text: String = ""
var _elapsed: float = 0.0
var _revealing: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(false)

func show_text(new_text: String) -> void:
	_full_text = new_text
	label.text = ""
	_elapsed = 0.0
	_revealing = true
	scroll_vertical = 0
	set_process(true)

## Shows the text straight away, no animation — for text the player
## already just read a moment ago elsewhere (e.g. ReceptionUI's
## problem_label repeating what ThresholdDialogue's just showed at the
## door), where re-typing it again reads as stalling, not drama.
func show_instant(new_text: String) -> void:
	_full_text = new_text
	label.text = new_text
	_elapsed = new_text.length()
	_revealing = false
	set_process(false)
	scroll_vertical = 0

## Replaces the fully-revealed text outright (no re-animation) — for a
## reaction appended well after the original line already finished
## printing, where re-typing the whole thing from scratch would just
## make the player wait to re-read what they already read.
func append_instant(suffix: String) -> void:
	_full_text += suffix
	label.text = _full_text
	_revealing = false
	set_process(false)
	scroll_vertical = MAX_SCROLL

func _process(delta: float) -> void:
	_elapsed += delta * CHARS_PER_SECOND
	var count := mini(int(_elapsed), _full_text.length())
	label.text = _full_text.substr(0, count)
	scroll_vertical = MAX_SCROLL
	if count >= _full_text.length():
		_revealing = false
		set_process(false)

func _gui_input(event: InputEvent) -> void:
	if _revealing and event is InputEventMouseButton and event.pressed:
		label.text = _full_text
		_revealing = false
		set_process(false)
		scroll_vertical = MAX_SCROLL
		accept_event()
