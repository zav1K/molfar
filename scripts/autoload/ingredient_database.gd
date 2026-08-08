extends Node
## Autoload. Loads every Ingredient resource from data/ingredients/ and indexes it by id.

const INGREDIENTS_DIR := "res://data/ingredients/"

var _ingredients: Dictionary = {} # StringName -> Ingredient

func _ready() -> void:
	_load_all()

func _load_all() -> void:
	var dir := DirAccess.open(INGREDIENTS_DIR)
	if dir == null:
		push_warning("IngredientDatabase: cannot open %s" % INGREDIENTS_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res := load(INGREDIENTS_DIR + file_name)
			if res is Ingredient:
				_ingredients[res.id] = res
		file_name = dir.get_next()
	dir.list_dir_end()

func get_ingredient(id: StringName) -> Ingredient:
	return _ingredients.get(id)

func get_all() -> Array:
	return _ingredients.values()

func get_available_on_day(day_of_year: int) -> Array:
	return _ingredients.values().filter(func(ing: Ingredient) -> bool:
		return ing.season_start_day <= day_of_year and day_of_year <= ing.season_end_day
	)
