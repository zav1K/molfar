class_name Recipe
extends Resource
## A brewing recipe: an exact ingredient multiset maps to one potion.
## Matching is exact — {"garlic": 3} only matches selecting exactly 3
## garlic and nothing else. No partial/fuzzy matching yet.

## Ingredient id (StringName key) -> required count (int value), e.g.
## {&"garlic": 3}.
@export var ingredients: Dictionary = {}
@export var result_potion_id: StringName
