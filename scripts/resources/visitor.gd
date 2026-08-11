class_name Visitor
extends Resource
## Someone knocking at the hut door.

@export var display_name: String = "Подорожній"
@export_multiline var problem_text: String = "..."

## Hidden from the player — wards check against this, nothing else should
## read it directly. Folklore beat: упирі/нечисть traditionally can't cross
## a threshold without being invited, so the invite/refuse choice needs to
## have real consequences tied to this once that mechanic exists.
@export var true_threat: Threat.Type = Threat.Type.NONE

## Selects which rotation this visitor is drawn from: day clients vs. the
## night cycle's нечисть/nocturnal callers. See GameCalendar/hut.gd's
## day-night knock logic and VisitorDatabase.get_random().
@export var night_visitor: bool = false

## What would actually help them — a Potion or Sigil id. No "reading the
## client" mechanic yet (see CONCEPT.md's diagnosis-via-details idea) —
## for now this is just what ReceptionUI checks a given item against.
@export var desired_result_id: StringName = &""

## Reversed direction: a Keepsake (or any item) id this visitor is trying
## to hand OFF to the player instead of asking for something — e.g.
## found_doll's Солом'яна лялька. Optional either way, never a fail
## state: ReceptionUI shows a Взяти/Відправити choice, satisfied_text
## plays on taking it, unhelped_text on declining. Empty for every
## ordinary give-an-item visitor.
@export var offers_item_id: StringName = &""

@export_multiline var satisfied_text: String = "Дякую, мольфаре. Мені вже легше."
@export_multiline var unhelped_text: String = "...це не те, що мені було треба."

## Shown in ThresholdDialogue while deciding whether to invite them in.
@export var portrait_door: Texture2D

## Shown in ReceptionUI once they're waiting inside for a potion/ward.
## Falls back to portrait_door until a second pose exists — see
## get_waiting_portrait().
@export var portrait_waiting: Texture2D

## Normalized (0..1) content bounding box of the *waiting* portrait,
## ignoring transparent canvas padding — measured offline (see
## scratchpad png_bbox.py) rather than at runtime because these
## generated portraits carry a faint alpha haze across nearly the whole
## canvas that defeats Godot's Image.get_used_rect() (it treats any
## nonzero alpha as "used", so it barely trims anything). Used by
## WaitingVisitorDisplay to size/crop the figure against the table line.
## Defaults to the full canvas (no cropping) until measured.
@export var waiting_portrait_content_rect: Rect2 = Rect2(0, 0, 1, 1)

func is_human() -> bool:
	return true_threat == Threat.Type.NONE

func get_waiting_portrait() -> Texture2D:
	return portrait_waiting if portrait_waiting != null else portrait_door
