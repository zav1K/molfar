class_name CarvingCanvas
extends Control
## Trace-the-symbol carving gesture: a target sigil's stroke path is shown
## as a faint guide; the player holds and drags the mouse to trace it in
## one continuous stroke. On release both paths are resampled to the same
## point count and compared — average deviation plus how much of the
## guide was actually covered decide carving quality (read by
## carving_ui.gd, same spirit as stir_cauldron.gd's rotation/evenness
## split for brewing).

signal finished(avg_error: float, coverage: float)

const RESAMPLE_COUNT := 40
const MIN_COVERAGE_TO_COUNT := 0.15 ## below this, a release is a misclick, not an attempt.
const MIN_POINT_SPACING := 3.0 ## px; drops points closer than this to keep arrays small.

var _target_sigil: Sigil
var _target_path: PackedVector2Array # in local pixel space
var _target_length: float = 0.0
var _drawn_points: PackedVector2Array
var _drawing: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func start(sigil: Sigil) -> void:
	_target_sigil = sigil
	_target_path.clear()
	for p in sigil.path_points:
		_target_path.append(Vector2(p.x * size.x, p.y * size.y))
	_target_length = _path_length(_target_path)
	_drawn_points.clear()
	_drawing = false
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_drawing = true
			_drawn_points.clear()
			_drawn_points.append(mb.position)
			queue_redraw()
		elif _drawing:
			_drawing = false
			_on_release()
	elif event is InputEventMouseMotion and _drawing:
		var mm := event as InputEventMouseMotion
		if _drawn_points.is_empty() or _drawn_points[-1].distance_to(mm.position) >= MIN_POINT_SPACING:
			_drawn_points.append(mm.position)
			queue_redraw()

func _on_release() -> void:
	var drawn_length := _path_length(_drawn_points)
	var coverage := 0.0 if _target_length <= 0.0 else clampf(drawn_length / _target_length, 0.0, 1.0)
	if coverage < MIN_COVERAGE_TO_COUNT:
		# Not a real attempt (misclick/twitch) — let the player try again for free.
		_drawn_points.clear()
		queue_redraw()
		return
	var resampled_target := _resample(_target_path, RESAMPLE_COUNT)
	var resampled_drawn := _resample(_drawn_points, RESAMPLE_COUNT)
	var total_error := 0.0
	for i in RESAMPLE_COUNT:
		total_error += resampled_target[i].distance_to(resampled_drawn[i])
	finished.emit(total_error / RESAMPLE_COUNT, coverage)

func _draw() -> void:
	if _target_path.size() >= 2:
		draw_polyline(_target_path, Color(0.85, 0.75, 0.55, 0.35), 3.0, true)
		for p in _target_path:
			draw_circle(p, 3.0, Color(0.85, 0.75, 0.55, 0.5))
	if _drawn_points.size() >= 2:
		draw_polyline(_drawn_points, Color(0.95, 0.85, 0.4, 0.9), 3.0, true)

func _path_length(points: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, points.size()):
		total += points[i - 1].distance_to(points[i])
	return total

## Resamples a polyline to exactly n points evenly spaced along its
## arc-length. Used to compare two paths of different point counts.
func _resample(points: PackedVector2Array, n: int) -> PackedVector2Array:
	var result := PackedVector2Array()
	result.resize(n)
	if points.size() < 2:
		var fallback: Vector2 = points[0] if points.size() == 1 else Vector2.ZERO
		for i in n:
			result[i] = fallback
		return result

	var cumulative := PackedFloat32Array()
	cumulative.append(0.0)
	var total := 0.0
	for i in range(1, points.size()):
		total += points[i - 1].distance_to(points[i])
		cumulative.append(total)

	var seg := 0
	for i in n:
		var target_dist: float = total * float(i) / float(n - 1)
		while seg < points.size() - 2 and cumulative[seg + 1] < target_dist:
			seg += 1
		var seg_len: float = cumulative[seg + 1] - cumulative[seg]
		var t: float = 0.0 if seg_len <= 0.0 else (target_dist - cumulative[seg]) / seg_len
		result[i] = points[seg].lerp(points[seg + 1], t)
	return result
