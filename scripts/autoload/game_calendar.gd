extends Node
## Autoload. Tracks in-game date (day-of-year), day/night phase, and fixed-date
## festivals from the ritual calendar. Movable feasts (Великдень, Вознесіння)
## depend on the Paschal calculation and are intentionally left out until that's added.

signal day_changed(day_of_year: int)
signal phase_changed(phase: Phase)

enum Phase { DAY, NIGHT }

class Festival:
	var id: StringName
	var display_name: String
	var day_of_year: int

	func _init(p_id: StringName, p_display_name: String, p_day_of_year: int) -> void:
		id = p_id
		display_name = p_display_name
		day_of_year = p_day_of_year

var festivals: Array[Festival] = []
var current_day: int = 1
var phase: Phase = Phase.DAY

func _ready() -> void:
	_register_festivals()

func _register_festivals() -> void:
	festivals = [
		Festival.new(&"ihnatiya", "Ігнатія", 2),
		Festival.new(&"sviatvechir", "Святвечір / Різдво", 6),
		Festival.new(&"malanka", "Маланка", 13),
		Festival.new(&"vasylya", "Василя", 14),
		Festival.new(&"vodokhreshcha", "Водохреща", 19),
		Festival.new(&"stritennya", "Стрітення", 46),
		Festival.new(&"yavdokhy", "Явдохи", 73),
		Festival.new(&"ivana_kupala", "Івана Купала", 188),
		Festival.new(&"andriya", "Андрія", 347),
	]

func advance_day() -> void:
	current_day = wrapi(current_day + 1, 1, 367)
	day_changed.emit(current_day)

func set_phase(p_phase: Phase) -> void:
	if phase == p_phase:
		return
	phase = p_phase
	phase_changed.emit(phase)

func get_active_festival() -> Festival:
	for festival in festivals:
		if festival.day_of_year == current_day:
			return festival
	return null
