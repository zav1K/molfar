class_name CarvedSigilInstance
extends RefCounted
## One physical carved object — not authored data, generated at runtime
## each time a player successfully carves a symbol. Holds their actual
## traced stroke (normalized 0..1, same space as Sigil.path_points) plus
## the specific wood-block variant randomly assigned to it, so the
## object can be rendered as what that specific player carved on that
## specific block — never a template. See CarvedSigilRegistry.

var sigil_id: StringName
var stroke_points: PackedVector2Array
var block_texture: Texture2D

## Normalized (0..1) content bounds within block_texture, ignoring
## whatever oversized blank canvas surrounds the actual block art — see
## CarvedSigilRegistry._measure_content_rect(). Defaults to the full
## texture (no cropping) if that measurement ever comes back empty.
var block_content_rect: Rect2 = Rect2(0, 0, 1, 1)
