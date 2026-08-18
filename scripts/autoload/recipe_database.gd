extends Node
## Autoload. Loads every Recipe resource from data/recipes/ and matches a
## player's ingredient selection against them by exact multiset.

const RECIPES_DIR := "res://data/recipes/"

var _recipes: Array[Recipe] = []

func _ready() -> void:
	_load_all()

func _load_all() -> void:
	var dir := DirAccess.open(RECIPES_DIR)
	if dir == null:
		push_warning("RecipeDatabase: cannot open %s" % RECIPES_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res := load(RECIPES_DIR + file_name)
			if res is Recipe:
				_recipes.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()

## For GrimoireUI's reverse lookups (which recipe makes this potion, which
## recipes use this herb) — find_recipe() only matches forward, by exact
## selection.
func get_all() -> Array[Recipe]:
	return _recipes

## selection: Dictionary of ingredient_id (StringName) -> count (int).
## Returns null if nothing matches exactly.
func find_recipe(selection: Dictionary) -> Recipe:
	for recipe in _recipes:
		if _matches(recipe.ingredients, selection):
			return recipe
	return null

func _matches(required: Dictionary, selection: Dictionary) -> bool:
	if required.size() != selection.size():
		return false
	for ingredient_id in required:
		if selection.get(ingredient_id, 0) != required[ingredient_id]:
			return false
	return true
