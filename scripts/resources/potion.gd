class_name Potion
extends Resource
## A brewed result. No effect/branching system yet — see brewing_ui.gd.

@export var id: StringName
@export var display_name: String
@export_multiline var description: String

## Art shown on the shelf once brewed. Null until an artist provides one —
## the shelf slot falls back to a text label in that case.
@export var icon: Texture2D
