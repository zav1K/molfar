class_name FloatingToken
extends Control
## A single ingredient unit bobbing in the cauldron liquid. Not a real
## physics body — a light procedural drift (idle rotation + a sine bob)
## plus a share of the cauldron's current stir speed, so tokens visibly
## get caught in the current while the player stirs.

const DRIFT_SPEED := 0.15 # rad/s baseline idle rotation, always active
const STIR_FOLLOW := 0.5 # fraction of the cauldron's stir speed tokens pick up
const BOB_AMPLITUDE := 4.0
const BOB_SPEED := 2.2

var center: Vector2
var radius: float
var angle: float
var cauldron: StirCauldron
var _bob_phase: float

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bob_phase = randf() * TAU

func setup(ingredient: Ingredient, p_center: Vector2, p_radius: float, p_cauldron: StirCauldron) -> void:
	center = p_center
	radius = p_radius
	cauldron = p_cauldron
	angle = randf() * TAU
	if ingredient.bundle_icon != null:
		var icon := TextureRect.new()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.texture = ingredient.bundle_icon
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(22, 22)
		icon.position = Vector2(-11, -11)
		add_child(icon)
	else:
		var panel := Panel.new()
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = ingredient.placeholder_color
		style.set_corner_radius_all(8)
		panel.add_theme_stylebox_override("panel", style)
		panel.custom_minimum_size = Vector2(16, 16)
		panel.position = Vector2(-8, -8)
		add_child(panel)

func _process(delta: float) -> void:
	var stir_speed := cauldron.stir_influence if cauldron else 0.0
	angle += (DRIFT_SPEED + stir_speed * STIR_FOLLOW) * delta
	var bob := sin(Time.get_ticks_msec() / 1000.0 * BOB_SPEED + _bob_phase) * BOB_AMPLITUDE
	position = center + Vector2.RIGHT.rotated(angle) * radius + Vector2(0.0, bob)
