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
## Festival day_of_year values below are remapped onto this condensed
## DAYS_PER_SEASON scale (not real Gregorian/Julian dates) — placed in
## whichever season they folklorically belong to, at a day within it
## chosen to preserve their real relative order and, where it matters,
## their own meaning (e.g. Стрітення sits at the very end of winter,
## since it's literally "the meeting of winter and spring").
##
## Each Ingredient's season_start_day/season_end_day
## (data/ingredients/*.tres) are still on the old real-calendar scale —
## that feature (IngredientDatabase.get_available_on_day()) has no
## caller yet, so it's left as a flagged follow-up rather than guessed at.

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
		# SPRING (days 1-21): Явдохи traditionally marks spring's start.
		Festival.new(&"yavdokhy", "Явдохи", 2),
		# SUMMER (days 22-42): Івана Купала sits at the solstice, mid-season.
		Festival.new(&"ivana_kupala", "Івана Купала", 32),
		# AUTUMN (days 43-63): Андрія, late in the season, on autumn's threshold to winter.
		Festival.new(&"andriya", "Андрія", 61),
		# WINTER (days 64-84): the Різдво/Новий рік cluster near the start,
		# Стрітення right at the end — "the meeting of winter and spring".
		Festival.new(&"ihnatiya", "Ігнатія", 64),
		Festival.new(&"sviatvechir", "Святвечір / Різдво", 66),
		Festival.new(&"malanka", "Маланка", 70),
		Festival.new(&"vasylya", "Василя", 71),
		Festival.new(&"vodokhreshcha", "Водохреща", 74),
		Festival.new(&"stritennya", "Стрітення", 83),
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

## First day_of_year of the given season (1-based).
func get_season_start_day(season: Season) -> int:
	return int(season) * DAYS_PER_SEASON + 1

func get_festival_on_day(day_of_year: int) -> Festival:
	for festival in festivals:
		if festival.day_of_year == day_of_year:
			return festival
	return null

func get_active_festival() -> Festival:
	return get_festival_on_day(current_day)
