class_name StirCauldron
extends Control
## Circular stirring gesture: hold and drag the mouse around the cauldron.
## Direction picks the recipe's white/black path (посолонь = clockwise =
## light, проти сонця = counter-clockwise = dark); total rotation and
## rhythm evenness (read by brewing_ui.gd) decide brew quality.

signal finished(direction: int, rotations: float, evenness: float)

const DEAD_ZONE_RADIUS := 20.0
const CAULDRON_RADIUS := 140.0
const MIN_ROTATIONS_TO_COUNT := 0.05 ## below this, a release is treated as a misclick, not an attempt.

const LIQUID_BASE_COLOR := Color(0.35, 0.4, 0.22)
const LIQUID_LIGHT_COLOR := Color(0.85, 0.7, 0.3)
const LIQUID_DARK_COLOR := Color(0.25, 0.05, 0.3)

@onready var progress_label: Label = $ProgressLabel

var _center: Vector2
var _dragging: bool = false
var _last_angle: float = 0.0
var _last_sample_time: float = 0.0
var _cumulative_angle: float = 0.0
var _speed_samples: PackedFloat32Array = []
var _liquid_color: Color = LIQUID_BASE_COLOR
var _stick_angle: float = 0.0

func _ready() -> void:
	_center = size / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP

func start() -> void:
	_dragging = false
	_cumulative_angle = 0.0
	_speed_samples.clear()
	_liquid_color = LIQUID_BASE_COLOR
	progress_label.text = "Затисни і веди мишею по колу"
	visible = true
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var offset := event.position - _center
			if offset.length() < DEAD_ZONE_RADIUS:
				return
			_dragging = true
			_last_angle = offset.angle()
			_last_sample_time = Time.get_ticks_msec() / 1000.0
		elif _dragging:
			_dragging = false
			_on_release()
	elif event is InputEventMouseMotion and _dragging:
		var offset: Vector2 = event.position - _center
		if offset.length() < DEAD_ZONE_RADIUS * 0.5:
			return
		var angle := offset.angle()
		var delta := wrapf(angle - _last_angle, -PI, PI)
		_cumulative_angle += delta
		var now := Time.get_ticks_msec() / 1000.0
		var dt := now - _last_sample_time
		if dt > 0.001:
			_speed_samples.append(absf(delta) / dt)
		_last_angle = angle
		_last_sample_time = now
		_stick_angle = angle
		_update_progress()
		queue_redraw()

func _update_progress() -> void:
	var rotations := absf(_cumulative_angle) / TAU
	var direction_text := "посолонь" if _cumulative_angle >= 0.0 else "проти сонця"
	progress_label.text = "Оберти: %.1f (%s)" % [rotations, direction_text]
	var t := clampf(rotations / 3.0, 0.0, 1.0)
	var target := LIQUID_LIGHT_COLOR if _cumulative_angle >= 0.0 else LIQUID_DARK_COLOR
	_liquid_color = LIQUID_BASE_COLOR.lerp(target, t)

func _on_release() -> void:
	var rotations := absf(_cumulative_angle) / TAU
	if rotations < MIN_ROTATIONS_TO_COUNT:
		# Not a real attempt (misclick/twitch) — let the player try again for free.
		progress_label.text = "Затисни і веди мишею по колу"
		return
	var direction := signi(_cumulative_angle)
	finished.emit(direction, rotations, _compute_evenness())

func _compute_evenness() -> float:
	if _speed_samples.size() < 2:
		return 0.0
	var mean := 0.0
	for s in _speed_samples:
		mean += s
	mean /= _speed_samples.size()
	if mean <= 0.0:
		return 0.0
	var variance := 0.0
	for s in _speed_samples:
		variance += (s - mean) * (s - mean)
	variance /= _speed_samples.size()
	return sqrt(variance) / mean # coefficient of variation; lower = steadier rhythm

func _draw() -> void:
	draw_circle(_center, CAULDRON_RADIUS, _liquid_color)
	draw_arc(_center, CAULDRON_RADIUS, 0.0, TAU, 64, Color(0.15, 0.1, 0.05), 4.0)
	if _dragging:
		var stick_pos: Vector2 = _center + Vector2.RIGHT.rotated(_stick_angle) * (CAULDRON_RADIUS - 20.0)
		draw_circle(stick_pos, 10.0, Color(0.9, 0.9, 0.85))
