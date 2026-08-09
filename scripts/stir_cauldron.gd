class_name StirCauldron
extends Control
## The cauldron itself: an always-live circular drop target (drag an
## ingredient icon in to add it) plus a circular stirring gesture. Hold
## and drag the mouse in a circle to stir — direction picks the recipe's
## white/black path (посолонь = clockwise = light, проти сонця =
## counter-clockwise = dark); rotation count and rhythm evenness (read by
## brewing_ui.gd) decide brew quality. Each stir gesture is independent —
## release ends it and the next press starts a fresh one.

signal finished(direction: int, rotations: float, evenness: float)
signal ingredient_dropped(ingredient_id: StringName)

const DEAD_ZONE_RADIUS := 20.0
const CAULDRON_RADIUS := 140.0
const MIN_ROTATIONS_TO_COUNT := 0.05 ## below this, a release is a misclick, not an attempt.
const STIR_FRICTION := 6.0 ## rad/s^2 decay of stir_influence once the drag ends.

const LIQUID_LIGHT_TARGET := 1.0
const LIQUID_DARK_TARGET := -1.0

@onready var progress_label: Label = $ProgressLabel
@onready var liquid: ColorRect = $Liquid
@onready var tokens_root: Control = $Tokens

## Signed angular speed (rad/s) of the current or most recent stir, read
## by FloatingToken so tokens get visibly caught in the current. Decays
## to 0 via friction once dragging stops.
var stir_influence: float = 0.0

var _center: Vector2
var _dragging: bool = false
var _last_angle: float = 0.0
var _last_sample_time: float = 0.0
var _cumulative_angle: float = 0.0
var _speed_samples: PackedFloat32Array = []
var _tokens: Dictionary = {} # StringName -> Array[FloatingToken]

func _ready() -> void:
	_center = size / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	reset_liquid()

func reset_liquid() -> void:
	progress_label.text = "Затисни і веди мишею по колу"
	var mat := liquid.material as ShaderMaterial
	mat.set_shader_parameter("swirl_amount", 0.4)
	mat.set_shader_parameter("direction", 0.0)
	mat.set_shader_parameter("progress", 0.0)

func add_token(ingredient: Ingredient) -> void:
	var token := FloatingToken.new()
	tokens_root.add_child(token)
	var r := randf_range(DEAD_ZONE_RADIUS + 10.0, CAULDRON_RADIUS - 20.0)
	token.setup(ingredient, _center, r, self)
	if not _tokens.has(ingredient.id):
		_tokens[ingredient.id] = []
	_tokens[ingredient.id].append(token)

func remove_token(ingredient_id: StringName) -> void:
	var list: Array = _tokens.get(ingredient_id, [])
	if list.is_empty():
		return
	var token: FloatingToken = list.pop_back()
	token.queue_free()
	if list.is_empty():
		_tokens.erase(ingredient_id)

func clear_tokens() -> void:
	for list in _tokens.values():
		for token in list:
			token.queue_free()
	_tokens.clear()

func _process(delta: float) -> void:
	if not _dragging and stir_influence != 0.0:
		stir_influence = move_toward(stir_influence, 0.0, STIR_FRICTION * delta)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("ingredient_id")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	ingredient_dropped.emit(data["ingredient_id"])

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			var offset: Vector2 = mb.position - _center
			if offset.length() < DEAD_ZONE_RADIUS:
				return
			_dragging = true
			_cumulative_angle = 0.0
			_speed_samples.clear()
			_last_angle = offset.angle()
			_last_sample_time = Time.get_ticks_msec() / 1000.0
		elif _dragging:
			_dragging = false
			_on_release()
	elif event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		var offset: Vector2 = mm.position - _center
		if offset.length() < DEAD_ZONE_RADIUS * 0.5:
			return
		var angle := offset.angle()
		var delta := wrapf(angle - _last_angle, -PI, PI)
		_cumulative_angle += delta
		var now := Time.get_ticks_msec() / 1000.0
		var dt := now - _last_sample_time
		if dt > 0.001:
			var speed := delta / dt
			_speed_samples.append(absf(speed))
			stir_influence = lerpf(stir_influence, speed, 0.5)
		_last_angle = angle
		_last_sample_time = now
		_update_progress()

func _update_progress() -> void:
	var rotations := absf(_cumulative_angle) / TAU
	var direction_text := "посолонь" if _cumulative_angle >= 0.0 else "проти сонця"
	progress_label.text = "Оберти: %.1f (%s)" % [rotations, direction_text]
	var mat := liquid.material as ShaderMaterial
	mat.set_shader_parameter("swirl_amount", clampf(0.4 + absf(stir_influence) * 1.5, 0.4, 4.0))
	mat.set_shader_parameter("direction", LIQUID_LIGHT_TARGET if _cumulative_angle >= 0.0 else LIQUID_DARK_TARGET)
	mat.set_shader_parameter("progress", clampf(rotations / 3.0, 0.0, 1.0))

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
