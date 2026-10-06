class_name MenuBackdrop
extends Control
## The main menu's background, which plays a looping video when one
## exists and falls back to the still image otherwise.
##
## Written fallback-first on purpose, same as AudioDirector: the video is
## an experiment that may not survive contact with a seamless loop, and
## the menu has to look finished either way. Drop menu_loop.ogv in and it
## takes over; delete it and the still comes back. Nothing to change in
## the scene.
##
## Godot plays only Ogg Theora, so whatever a generator produces has to
## be converted — see assets/video/README.md.

const VIDEO_PATH := "res://assets/video/menu_loop.ogv"

@onready var still: TextureRect = $Still

var _video: VideoStreamPlayer

func _ready() -> void:
	if not ResourceLoader.exists(VIDEO_PATH):
		return
	var stream := load(VIDEO_PATH) as VideoStream
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

## True when the video actually took over, for anything that wants to
## know whether to add its own motion on top of a still frame.
func is_animated() -> bool:
	return _video != null
