class_name MenuBackdrop
extends Control
## The main menu's background: the hut as the player left it. A save
## written at night brings up the night loop, a daylight save the day
## one, and a fresh install starts in daylight because that is where the
## chapter starts.
##
## Falls back at every step, the same way AudioDirector does, because
## these files arrive one at a time: the phase-specific video, then the
## unsuffixed one, then the matching still, then the plain still. Any
## subset of them is a valid state and the menu looks finished
## throughout — delete every video and it is a still menu again, with
## nothing to change in the scene.
##
## Godot plays only Ogg Theora, so whatever a generator produces has to
## be converted — see assets/video/README.md.

const VIDEO_DIR := "res://assets/video/"
const STILL_DIR := "res://assets/hut/"

@onready var still: TextureRect = $Still

var _video: VideoStreamPlayer

func _ready() -> void:
	# A finished chapter ends on night 7, so that save shows the night
	# hut — which is also the right note for a player coming back to
	# re-read the chronicle.
	var night := SaveGame.peek_phase() == GameCalendar.Phase.NIGHT
	_apply_still(night)
	_apply_video(night)

func _apply_still(night: bool) -> void:
	var texture := _first_existing(STILL_DIR, [
		"menu_backdrop_night.png" if night else "menu_backdrop_day.png",
		"menu_backdrop.png",
	]) as Texture2D
	if texture != null:
		still.texture = texture

func _apply_video(night: bool) -> void:
	var stream := _first_existing(VIDEO_DIR, [
		"menu_loop_night.ogv" if night else "menu_loop_day.ogv",
		"menu_loop.ogv",
	]) as VideoStream
	if stream == null:
		return
	_video = VideoStreamPlayer.new()
	_video.stream = stream
	_video.expand = true
	_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Muted: the menu's sound belongs to AudioDirector, and a video
	# carrying its own audio track would play over it uncontrolled.
	_video.volume_db = -80.0
	add_child(_video)
	move_child(_video, 0)
	# VideoStreamPlayer's own loop flag has moved between Godot versions,
	# so restart on finished instead — works the same everywhere, and a
	# one-frame gap is invisible against a backdrop.
	_video.finished.connect(_video.play)
	_video.play()
	still.visible = false

func _first_existing(dir: String, names: Array) -> Resource:
	for name: String in names:
		var path := dir + name
		if ResourceLoader.exists(path):
			return load(path)
	return null

## True when a video actually took over, for anything that wants to know
## whether to add its own motion on top of a still frame.
func is_animated() -> bool:
	return _video != null
