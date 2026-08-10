extends Node
## Autoload. Tracks in-game date (day-of-year), day/night phase, and fixed-date
## festivals from the ritual calendar. Movable feasts (Великдень, Вознесіння)
## depend on the Paschal calculation and are intentionally left out until that's added.
##
## The game year is a condensed abstraction, not a real 366-day year:
## DAYS_PER_SEASON days per season × 4 seasons, so a full year is playable
## without acting out 366 individual days. 21 (three weeks) is the current
## preliminary value — see hut.gd for where day_of_year turns into a knock
## count.
##
## NOTE: festivals below still carry their real-calendar day_of_year
## (Ihnatiya=Jan, Ivana Kupala=Jul, etc.) inherited from before the
## condensed year existed. Both this list and each Ingredient's
## season_start_day/season_end_day (data/ingredients/*.tres) are unused by
## any live system yet (get_active_festival() and
## IngredientDatabase.get_available_on_day() have no callers) — they'll
## need remapping onto the DAYS_PER_SEASON scale before either feature
## actually gets wired up.

signal day_changed(day_of_year: int)
signal phase_changed(phase: Phase)
signal season_changed(season: Season)

enum Phase { DAY, NIGHT }
enum Season { SPRING, SUMMER, AUTUMN, WINTER }

const DAYS_PER_SEASON := 21
const SEASON_COUNT := 4 # Season enum has exactly 4 values
const DAYS_PER_YEAR := DAYS_PER_SEASON * SEASON_COUNT

const SEASON_NAMES := {
	Season.SPRING: "Весна",
	Season.SUMMER: "Літо",
	Season.AUTUMN: "Осінь",
	Season.WINTER: "Зима",
}

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
	var previous_season := get_season()
	current_day = wrapi(current_day + 1, 1, DAYS_PER_YEAR + 1)
	day_changed.emit(current_day)
	var new_season := get_season()
	if new_season != previous_season:
		season_changed.emit(new_season)

func set_phase(p_phase: Phase) -> void:
	if phase == p_phase:
		return
	phase = p_phase
	phase_changed.emit(phase)

## Which season current_day falls in, and which day of that season (1-based).
func get_season() -> Season:
	return (((current_day - 1) / DAYS_PER_SEASON) % SEASON_COUNT) as Season

func get_day_of_season() -> int:
	return ((current_day - 1) % DAYS_PER_SEASON) + 1

func get_active_festival() -> Festival:
	for festival in festivals:
		if festival.day_of_year == current_day:
			return festival
	return null
