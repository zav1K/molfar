class_name Sigil
extends Resource
## A carvable symbol — a ward (protection/blessing) or a curse mark, per
## CONCEPT.md's "різьблення клейм/оберегів" (inspired by Worshipers of
## Cthulhu's branding system). Distinct from WardRack's door-hook wards
## (hanging a raw ingredient like garlic for a threat hint) — this is a
## crafted item the player carves and can later give to a visitor or
## hang as hut decoration.

enum Kind { WARD, CURSE }

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var kind: Kind = Kind.WARD

## The stroke path the player traces to carve this symbol: an ordered
## polyline in a normalized 0..1 unit square, single continuous stroke
## (no pen lifts — matches how the carving gesture is captured).
@export var path_points: PackedVector2Array

## Note: the blank wood-block a carved instance sits on isn't chosen
## per symbol — CarvedSigilRegistry picks randomly from a shared pool
## of block art (assets/hut/sigil_blocks/) each time something is
## carved, and remembers the pick on that CarvedSigilInstance. The
## carved *line* itself is never templated art either: it's the
## specific player's own traced stroke for that specific object, not
## this symbol's canonical path_points — so no two carved instances of
## the same sigil look alike, in block or in line.
