class_name CutscenePlayer
extends Control
## Plays a Cutscene: a still frame with a few things moving on it, and a
## line of text underneath.
##
## Clicking is deliberately two-stage, which the chronicle screen taught
## the hard way. There, an impatient click during a slow reveal threw the
## player out to the menu — so here the first click finishes printing the
## caption and the second moves on. Skipping the whole cutscene is a
## separate, labelled button, never something a mistimed click can do.
##
## Layers are driven in _process rather than by tweens. Every motion here
## is a function of elapsed time — a drift is a multiply, a sway is a
## sine — so holding the clock and reading it each frame is both shorter
## and the only way a mid-shot skip can land on the right frame instead
## of leaving a half-finished tween behind.
##
## Plays with whatever art exists. A layer with no texture is skipped and
## a shot with no layers at all is a caption on black, so the whole scene
## can be written and timed before a single picture has been generated.

signal finished

const FRAME := Vector2(960.0, 540.0) ## design resolution, as everywhere else

## Which cutscene the next load of this scene should play. Set before
## changing scene, read once in _ready — the same handshake SaveGame
## uses for pending_load, and for the same reason: the scene that will
## do the work does not exist yet at the point the decision is made.
static var pending_path: String = ""

## Where to go if that cutscene cannot be loaded at all. The resource
## carries its own next_scene, but a missing resource cannot — and
## stranding the player on a black screen because a decorative file was
## deleted is the one outcome this must never have.
static var fallback_scene: String = ""

## What `pending_path` falls back to on a scene opened directly from the
## editor, so pressing F6 on Cutscene.tscn plays something.
const DEFAULT_CUTSCENE := "res://data/cutscenes/intro.tres"

@onready var video_player: VideoStreamPlayer = $Frame/Video
@onready var layer_root: Control = $Frame/Layers
@onready var caption_label: TypewriterLabel = $Caption
@onready var skip_button: Button = $SkipButton
@onready var fade: ColorRect = $Fade

var _cutscene: Cutscene
var _shots: Array[CutsceneShot] = []
var _index: int = -1
var _elapsed: float = 0.0
var _sprites: Array[TextureRect] = []
var _layers: Array[CutsceneLayer] = []
var _holding: bool = false ## caption finished; waiting out the shot
var _held: float = 0.0
var _video_ended: bool = false
var _done: bool = false

func _ready() -> void:
	set_process(false)
	skip_button.pressed.connect(_finish)
	video_player.finished.connect(_on_video_finished)
	fade.color = Color(0, 0, 0, 1)
	var path := pending_path if pending_path != "" else DEFAULT_CUTSCENE
	var fallback := fallback_scene
	pending_path = ""
	fallback_scene = ""
	if not ResourceLoader.exists(path):
		push_warning("[cutscene] нема %s — пропускаю" % path)
		if fallback != "":
			get_tree().change_scene_to_file(fallback)
		else:
			_finish()
		return
	play(load(path))

func play(cutscene: Cutscene) -> void:
	_cutscene = cutscene
	_shots = cutscene.eligible_shots()
	_index = -1
	_done = false
	if _cutscene.ambience_id != &"":
		AudioDirector.start_loop(_cutscene.ambience_id)
	_advance()

# --- shots ----------------------------------------------------------

func _advance() -> void:
	_index += 1
	if _index >= _shots.size():
		_finish()
		return
	var shot := _shots[_index]
	_start_picture(shot)
	_elapsed = 0.0
	_held = 0.0
	_holding = false
	_video_ended = false
	caption_label.show_text(shot.caption)
	if shot.sound_id != &"":
		AudioDirector.play(shot.sound_id)
	# The first shot comes up out of black; later ones cross-fade from
	# whatever was on screen, which is already gone by now — so the fade
	# rectangle does both jobs, and neither needs a second frame buffer.
	var seconds: float = shot.fade_from_previous
	fade.color.a = 1.0
	if seconds > 0.0:
		create_tween().tween_property(fade, "color:a", 0.0, seconds)
	else:
		fade.color.a = 0.0
	set_process(true)

## A shot is either a generated clip or a stack of moving cut-outs,
## never both — whichever it has. The clip wins when it is there, the
## same stepping-down MenuBackdrop does, so shots can be swapped from
## layers to video one at a time as they come back from the generator.
func _start_picture(shot: CutsceneShot) -> void:
	var has_video: bool = shot.video != null
	video_player.visible = has_video
	layer_root.visible = not has_video
	if has_video:
		_build_layers(null)
		video_player.stream = shot.video
		# Muted: AudioDirector owns the sound, and a track inside the clip
		# would play past it and past the volume settings.
		video_player.volume_db = -80.0
		video_player.play()
		return
	video_player.stop()
	_build_layers(shot)

func _on_video_finished() -> void:
	_video_ended = true
	# A clip is a few seconds and a caption can outlast it. Cutting to
	# black mid-sentence reads as a bug, so the last frame stays up until
	# the reader is done with it.
	if not _shots[_index].hold_last_frame:
		_advance()

func _build_layers(shot: CutsceneShot) -> void:
	for sprite in _sprites:
		layer_root.remove_child(sprite)
		sprite.queue_free()
	_sprites.clear()
	_layers.clear()
	if shot == null:
		return
	for layer in shot.layers:
		if layer == null or layer.texture == null:
			continue
		var sprite := TextureRect.new()
		sprite.texture = layer.texture
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		# Sized against the frame's height so a layer keeps its proportions
		# whatever canvas it was painted on, then placed by its centre.
		var texture_size := layer.texture.get_size()
		var base: float = FRAME.y / maxf(texture_size.y, 1.0) * layer.scale_factor
		sprite.size = texture_size * base
		sprite.pivot_offset = sprite.size * 0.5
		layer_root.add_child(sprite)
		_sprites.append(sprite)
		_layers.append(layer)

# --- motion ---------------------------------------------------------

## Two clocks, deliberately. _elapsed runs from the start of the shot and
## never restarts, because every layer motion is a function of it and
## resetting it would jolt them all back. _held counts only from the
## moment the caption finished printing, which is what the shot's
## duration is measured against — a long line should not eat the hold.
func _process(delta: float) -> void:
	_elapsed += delta
	for i in _sprites.size():
		_apply(_sprites[i], _layers[i])
	if not _holding:
		if caption_label.is_revealing():
			return
		_holding = true
		_held = 0.0
		return
	_held += delta
	# A clip that has run out with nothing left to read has said its
	# piece; otherwise the shot's own duration is the ceiling.
	if _video_ended or _held >= _shots[_index].duration:
		_advance()

func _apply(sprite: TextureRect, layer: CutsceneLayer) -> void:
	var time: float = _elapsed - layer.appear_at
	if time < 0.0:
		sprite.visible = false
		return
	sprite.visible = true
	var offset := Vector2.ZERO
	var scale_now: float = 1.0
	var alpha: float = layer.opacity
	var cycle: float = (time * layer.speed + layer.phase) * TAU
	match layer.motion:
		CutsceneLayer.Motion.DRIFT:
			offset = layer.amount * time
		CutsceneLayer.Motion.SWAY:
			offset = layer.amount * sin(cycle)
		CutsceneLayer.Motion.RISE:
			offset = Vector2(layer.amount.x * sin(cycle), -absf(layer.amount.y) * time)
			# Smoke thins out as it climbs rather than stopping abruptly.
			alpha *= clampf(1.0 - time / maxf(_shots[_index].duration, 0.001), 0.0, 1.0)
		CutsceneLayer.Motion.PULSE:
			alpha *= clampf(1.0 - layer.amount.x * 0.5 + sin(cycle) * layer.amount.x * 0.5, 0.0, 1.0)
		CutsceneLayer.Motion.ZOOM:
			scale_now = maxf(0.05, 1.0 + layer.amount.x * time)
		CutsceneLayer.Motion.STILL:
			pass
	if layer.fade_in > 0.0:
		alpha *= clampf(time / layer.fade_in, 0.0, 1.0)
	if layer.fade_out > 0.0:
		var left: float = _shots[_index].duration - _held
		alpha *= clampf(left / layer.fade_out, 0.0, 1.0)
	var centre := Vector2(layer.anchor.x * FRAME.x, layer.anchor.y * FRAME.y)
	sprite.scale = Vector2(scale_now, scale_now)
	sprite.position = centre - sprite.size * 0.5 + offset
	sprite.modulate = Color(layer.tint.r, layer.tint.g, layer.tint.b, alpha)

# --- input ----------------------------------------------------------

## First click finishes the caption, second moves on. Never leaves the
## cutscene — that is what the labelled button is for.
func _gui_input(event: InputEvent) -> void:
	if _done or not (event is InputEventMouseButton):
		return
	var click := event as InputEventMouseButton
	if not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	accept_event()
	if caption_label.is_revealing():
		caption_label.reveal_all()
		return
	_advance()

func _finish() -> void:
	if _done:
		return
	_done = true
	set_process(false)
	if _cutscene != null and _cutscene.ambience_id != &"":
		AudioDirector.stop_loop(_cutscene.ambience_id)
	if _cutscene != null and _cutscene.next_scene != "":
		get_tree().change_scene_to_file(_cutscene.next_scene)
		return
	finished.emit()
