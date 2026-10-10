class_name Recipe
extends Resource
## A brewing recipe: an exact ingredient multiset maps to a potion. Which
## potion depends on stir direction during brewing — посолонь (clockwise)
## follows the "white path", проти сонця (counter-clockwise) the "black
## path" (see CONCEPT.md's мольфар duality). Matching ingredients is
## exact — {"garlic": 3} only matches selecting exactly 3 garlic and
## nothing else. No partial/fuzzy matching yet.

## Ingredient id (StringName key) -> required count (int value), e.g.
## {&"garlic": 3}.
@export var ingredients: Dictionary = {}

## Potion granted when stirred посолонь (clockwise). Empty if this recipe
## has no white-path result.
@export var light_result_id: StringName

## Potion granted when stirred проти сонця (counter-clockwise). Empty if
## this recipe has no black-path result yet — stirring that way just
## spoils the brew.
@export var dark_result_id: StringName
