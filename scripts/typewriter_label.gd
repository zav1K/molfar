class_name TypewriterLabel
extends ScrollContainer
## Reveals text a character at a time inside a fixed-height box instead
## of all at once, auto-scrolling to follow — long dialogue scrolls
## internally as it prints instead of overflowing into whatever's laid
## out below it (buttons, the next panel...). Click anywhere on it (or
## any button underneath it) to skip straight to the full text.
##
## Visitor text mixes two registers: what the visitor SAYS, wrapped in
## quotes, and prose describing what they do while saying it. Set in one
## uniform size they run together and the eye has nothing to grab, which
## is how it read in testing. So speech keeps the full size and prose is
## typeset smaller and cooler — see _format, which does it automatically
## from the quote marks rather than asking forty .tres files to mark
## themselves up.
##
## That split is why this is a RichTextLabel rather than a plain Label:
## two sizes in one block need per-run formatting. The reveal rides on
## RichTextLabel's own visible_characters, which counts parsed
## characters and ignores the BBCode tags, so the tags never show and
## never cost reveal time.
##
## horizontal_scroll_mode must stay disabled (set in the scene) so the
## inner label is forced to this container's width and only grows
## vertically — same ScrollContainer-locks-the-cross-axis setup already
## used by GrimoireUI's/InventoryPanel's lists.

const CHARS_PER_SECOND := 45.0
const MAX_SCROLL := 1000000 ## larger than any real content height — ScrollContainer clamps.

## Prose size as a fraction of the speech size. The ask was "at least
## 1.5x smaller"; 0.62 lands a 16px body on 10px prose, which is the
## smallest that still reads comfortably at this window size.
const PROSE_SCALE := 0.62
const SPEECH_COLOR := Color(0.93, 0.90, 0.82)
const PROSE_COLOR := Color(0.68, 0.66, 0.62)

@onready var label: RichTextLabel = $Label

var _full_text: String = ""
var _plain_length: int = 0
var _elapsed: float = 0.0
var _revealing: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Hidden characters keep their space instead of being dropped before
	# the line is shaped. Without this the block is only as tall as the
	# part already typed, so with fit_content on it grows line by line as
	# it reveals — the text reflows under itself while the player reads
	# it, and get_content_height() reads 0 on the first frame.
	label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	set_process(false)

func show_text(new_text: String) -> void:
	_apply(new_text)
	label.visible_characters = 0
	_elapsed = 0.0
	_revealing = true
	scroll_vertical = 0
	set_process(true)

## Shows the text straight away, no animation — for text the player
## already just read a moment ago elsewhere (e.g. ReceptionUI's
## problem_label repeating what ThresholdDialogue's just showed at the
## door), where re-typing it again reads as stalling, not drama.
func show_instant(new_text: String) -> void:
	_apply(new_text)
	label.visible_characters = -1
	_elapsed = _plain_length
	_revealing = false
	set_process(false)
	scroll_vertical = 0

## Replaces the fully-revealed text outright (no re-animation) — for a
## reaction appended well after the original line already finished
## printing, where re-typing the whole thing from scratch would just
## make the player wait to re-read what they already read.
func append_instant(suffix: String) -> void:
	_apply(_full_text + suffix)
	label.visible_characters = -1
	_revealing = false
	set_process(false)
	scroll_vertical = MAX_SCROLL

func _apply(new_text: String) -> void:
	_full_text = new_text
	label.text = _format(new_text)
	# Parsed length, so the reveal paces by characters the player can
	# actually see rather than by the markup wrapped around them.
	_plain_length = label.get_parsed_text().length()

## Splits on the quote marks: odd segments are inside quotes and are
## speech, even ones are the prose around them. A visitor who never uses
## quotes (pure description, like Полудениця's arrival) comes out as one
## even segment and is typeset as prose throughout, which is right.
func _format(raw: String) -> String:
	var out := ""
	var segments := raw.split("\"")
	for i in segments.size():
		var segment: String = segments[i]
		if segment.is_empty():
			continue
		if i % 2 == 1:
			out += "[color=#%s]\"%s\"[/color]" % [SPEECH_COLOR.to_html(false), segment]
		else:
			out += "[font_size=%d][color=#%s]%s[/color][/font_size]" % [
				maxi(1, roundi(_base_font_size() * PROSE_SCALE)),
				PROSE_COLOR.to_html(false), segment]
	return out

func _base_font_size() -> int:
	var size := label.get_theme_font_size(&"normal_font_size")
	return size if size > 0 else 16

func _process(delta: float) -> void:
	_elapsed += delta * CHARS_PER_SECOND
	label.visible_characters = mini(int(_elapsed), _plain_length)
	scroll_vertical = MAX_SCROLL
	if label.visible_characters >= _plain_length:
		label.visible_characters = -1
		_revealing = false
		set_process(false)

func _gui_input(event: InputEvent) -> void:
	if _revealing and event is InputEventMouseButton and event.pressed:
		label.visible_characters = -1
		_revealing = false
		set_process(false)
		scroll_vertical = MAX_SCROLL
		accept_event()
