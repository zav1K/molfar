extends Node
## Autoload. Owns garden plot state so it survives leaving the garden —
## Garden.tscn's GardenPlot nodes are destroyed on every scene change
## (change_scene_to_file), but growth has to keep advancing on the
## calendar whether or not the player is standing there looking at it.
## GardenPlot is just a thin view over whichever Plot this holds for its
## own plot_index.

enum Stage { EMPTY, GROWING, READY }

const PLOT_COUNT := 6 ## matches the 6 pre-built nodes in Garden.tscn.
const WATER_BONUS_DAYS := 1

## TODO: hook into a shared upgrade system once cauldron/carving-knife/
## shelf upgrades exist — for now this is just a static cap, same as
## those tools have no upgrade path yet either.
var max_plots: int = 3

class Plot:
	var stage: Stage = Stage.EMPTY
	var ingredient_id: StringName = &""
	var days_grown: int = 0
	var growth_days_required: int = 0
	var last_watered_day: int = -1

var _plots: Array[Plot] = []

func _ready() -> void:
	for i in PLOT_COUNT:
		_plots.append(Plot.new())
	GameCalendar.day_changed.connect(_on_day_changed)

func _on_day_changed(_day_of_year: int) -> void:
	for plot in _plots:
		if plot.stage == Stage.GROWING:
			plot.days_grown += 1
			if plot.days_grown >= plot.growth_days_required:
				plot.stage = Stage.READY

func get_plot(index: int) -> Plot:
	return _plots[index]

func is_plot_unlocked(index: int) -> bool:
	return index < max_plots

## Whether `ingredient` may be sown today, and whether it'll ripen slower
## for being sown outside its favorable moon phase. Season window is a
## hard gate; moon phase (only checked for moon-sensitive ingredients) is
## a soft one — NEW/FULL block outright, the "wrong half" of the cycle
## still allows planting but with a growth penalty.
func check_plantable(ingredient: Ingredient) -> Dictionary:
	var day := GameCalendar.current_day
	if day < ingredient.season_start_day or day > ingredient.season_end_day:
		return {allowed = false, penalty = false, reason = "Не той сезон для цієї рослини."}
	if ingredient.favorable_moon_phase == MoonPhase.Phase.ANY:
		return {allowed = true, penalty = false, reason = ""}
	var moon := GameCalendar.get_moon_phase()
	if moon == MoonPhase.Phase.NEW or moon == MoonPhase.Phase.FULL:
		return {allowed = false, penalty = false, reason = "Молодик і повня — невдалі дні для посадки."}
	if moon != ingredient.favorable_moon_phase:
		return {allowed = true, penalty = true, reason = "Не найкраща фаза Місяця — росте повільніше."}
	return {allowed = true, penalty = false, reason = ""}

## Plants and immediately waters (the minigame's last step doubles as day-1
## watering) — call only after check_plantable() allowed it.
func plant(index: int, ingredient: Ingredient, penalty: bool) -> void:
	var plot := _plots[index]
	plot.stage = Stage.GROWING
	plot.ingredient_id = ingredient.id
	plot.days_grown = WATER_BONUS_DAYS
	plot.growth_days_required = ingredient.base_growth_days * (2 if penalty else 1)
	plot.last_watered_day = GameCalendar.current_day
	if plot.days_grown >= plot.growth_days_required:
		plot.stage = Stage.READY

## Returns false if already watered today or not growing — watering twice
## in one day just does nothing, same "free experimentation" rule as
## every other minigame in this project.
func water(index: int) -> bool:
	var plot := _plots[index]
	if plot.stage != Stage.GROWING or plot.last_watered_day == GameCalendar.current_day:
		return false
	plot.last_watered_day = GameCalendar.current_day
	plot.days_grown += WATER_BONUS_DAYS
	if plot.days_grown >= plot.growth_days_required:
		plot.stage = Stage.READY
	return true

func harvest(index: int) -> StringName:
	var plot := _plots[index]
	var id := plot.ingredient_id
	plot.stage = Stage.EMPTY
	plot.ingredient_id = &""
	plot.days_grown = 0
	plot.growth_days_required = 0
	plot.last_watered_day = -1
	return id
