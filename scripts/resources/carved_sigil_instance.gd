class_name CarvedSigilInstance
extends RefCounted
## One physical carved object — not authored data, generated at runtime
## each time a player successfully carves a symbol. Holds their actual
## traced stroke (normalized 0..1, same space as Sigil.path_points) so
## the object can be rendered as what that specific player carved,
## never a template. See CarvedSigilRegistry.

var sigil_id: StringName
var stroke_points: PackedVector2Array
