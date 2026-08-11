extends Node
## Autoload. Owns garden plot state so it survives leaving the garden —
## Garden.tscn's GardenPlot nodes are destroyed on every scene change
## (change_scene_to_file), but growth has to keep advancing on the
## calendar whether or not the player is standing there looking at it.
## GardenPlot is just a thin view over whichever Plot this holds for its
## own plot_index.

## empty → dug → sprout (freshly planted) → growing (mid-stage) → mature
## (ready to harvest) → back to empty. dug is itself a persisted stage,
## not just a UI step — digging costs nothing, so leaving a hole
## unplanted and coming back to it later is harmless.
enum Stage { EMPTY, DUG, SPROUT, GROWING, MATURE }

const PLOT_COUNT := 3 ## matches the 3 plots baked into the garden background art.
const WATER_BONUS_DAYS := 1

class Plot:
	var stage: Stage = Stage.EMPTY
	var ingredient_id: StringName = &""
	var days_grown: int = 0
	var days_to_growing: int = 0 ## sprout -> growing threshold, in days_grown
	var days_to_mature: int = 0  ## growing -> mature threshold, in days_grown
	var last_watered_day: int = -1

var _plots: Array[Plot] = []

func _ready() -> void:
	for i in PLOT_COUNT:
		_plots.append(Plot.new())
	GameCalendar.day_changed.connect(_on_day_changed)

func _on_day_changed(_day_of_year: int) -> void:
	for plot in _plots:
		if plot.stage == Stage.SPROUT or plot.stage == Stage.GROWING:
			plot.days_grown += 1
			_advance_stage(plot)

func get_plot(index: int) -> Plot:
	return _plots[index]

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

## First planting step: empty -> dug. Free — no inventory cost — so this
## is safe to call the moment the player clicks "Копати", independent of
## whether they go on to actually plant anything.
func dig(index: int) -> bool:
	var plot := _plots[index]
	if plot.stage != Stage.EMPTY:
		return false
	plot.stage = Stage.DUG
	return true

## dug -> sprout. Call only after check_plantable() allowed it; consuming
## the seed from PlayerInventory is the caller's job (PlantingUI).
func plant(index: int, ingredient: Ingredient, penalty: bool) -> bool:
	var plot := _plots[index]
	if plot.stage != Stage.DUG:
		return false
	var total_days: int = ingredient.base_growth_days * (2 if penalty else 1)
	plot.ingredient_id = ingredient.id
	plot.days_grown = 0
	plot.days_to_growing = max(1, total_days / 2)
	plot.days_to_mature = max(1, total_days - plot.days_to_growing)
	plot.stage = Stage.SPROUT
	plot.last_watered_day = -1
	return true

func _advance_stage(plot: Plot) -> void:
	if plot.stage == Stage.SPROUT and plot.days_grown >= plot.days_to_growing:
		plot.stage = Stage.GROWING
	if plot.stage == Stage.GROWING and plot.days_grown >= plot.days_to_growing + plot.days_to_mature:
		plot.stage = Stage.MATURE

## Returns false if already watered today or not growing — watering twice
## in one day just does nothing, same "free experimentation" rule as
## every other minigame in this project. Also drives the brief wet-soil
## visual (GardenPlot checks last_watered_day == today after calling this).
func water(index: int) -> bool:
	var plot := _plots[index]
	if (plot.stage != Stage.SPROUT and plot.stage != Stage.GROWING) or plot.last_watered_day == GameCalendar.current_day:
		return false
	plot.last_watered_day = GameCalendar.current_day
	plot.days_grown += WATER_BONUS_DAYS
	_advance_stage(plot)
	return true

func harvest(index: int) -> StringName:
	var plot := _plots[index]
	var id := plot.ingredient_id
	plot.stage = Stage.EMPTY
	plot.ingredient_id = &""
	plot.days_grown = 0
	plot.days_to_growing = 0
	plot.days_to_mature = 0
	plot.last_watered_day = -1
	return id
