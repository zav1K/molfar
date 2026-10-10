class_name DayNightToast
extends CanvasLayer
## Transient "День N" / "Ніч N" banner — hut.gd calls show_message()
## right when a day/night phase flip actually happens (see
## _advance_visitor_slot()), so finishing that day's/night's last
## scripted visitor gets a clear beat instead of the knock queue just
## quietly continuing into the next phase.

const FADE_TIME := 0.4
const HOLD_TIME := 1.6

@onready var panel: PanelContainer = $Panel
@onready var label: Label = $Panel/Label

var _tween: Tween

func _ready() -> void:
	panel.modulate.a = 0.0

func show_message(text: String) -> void:
	label.text = text
	if _tween != null and _tween.is_valid():
		_tween.kill()
	panel.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(panel, "modulate:a", 1.0, FADE_TIME)
	_tween.tween_interval(HOLD_TIME)
	_tween.tween_property(panel, "modulate:a", 0.0, FADE_TIME)
