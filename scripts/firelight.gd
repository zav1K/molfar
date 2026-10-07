class_name Firelight
extends Sprite2D
## The glow under the cauldron. The hearth has had a sound since the
## audio pass but no light at all, so the one thing burning in the hut
## was invisible.
##
## An additive sprite rather than a PointLight2D: 2D lights want normal
## maps and light masks to look like anything, and the panels are
## painted flat. A warm radial blob on add blend does the whole job and
## costs nothing.
##
## Brighter at night on purpose. DayNightTint multiplies the whole
## canvas toward cold blue after dark, which would otherwise drain the
## fire exactly when it should be the only warm thing left in the room —
## so the night level more than compensates.

const DAY_ENERGY := 0.34
const NIGHT_ENERGY := 0.85
const ENERGY_FADE := 2.5 ## matches the tint and ambience crossfades

## Flicker is two detuned sines rather than noise: a real hearth breathes
## slowly with small catches in it, while raw noise reads as a flickering
## bulb. Deliberately gentle — this sits behind dialogue the player is
## reading, and anything stronger pulls the eye off the text.
const SLOW_RATE := 0.9
const FAST_RATE := 3.7
const FLICKER_DEPTH := 0.13
const SCALE_DEPTH := 0.05

var _energy: float = DAY_ENERGY
var _time: float = 0.0

func _ready() -> void:
	GameCalendar.phase_changed.connect(_on_phase_changed)
	_energy = _energy_for(GameCalendar.phase)
	_time = randf() * 100.0 # so it isn't in phase with anything else

func _process(delta: float) -> void:
	_time += delta
	var flicker := sin(_time * SLOW_RATE) * 0.6 + sin(_time * FAST_RATE) * 0.4
	modulate.a = _energy * (1.0 + flicker * FLICKER_DEPTH)
	var s := 1.0 + flicker * SCALE_DEPTH
	scale = Vector2(s, s)

func _energy_for(phase: int) -> float:
	return NIGHT_ENERGY if phase == GameCalendar.Phase.NIGHT else DAY_ENERGY

func _on_phase_changed(phase: int) -> void:
	create_tween().tween_property(self, "_energy", _energy_for(phase), ENERGY_FADE)
