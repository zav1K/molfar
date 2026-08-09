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

## What would actually help them — a Potion or Sigil id. No "reading the
## client" mechanic yet (see CONCEPT.md's diagnosis-via-details idea) —
## for now this is just what ReceptionUI checks a given item against.
@export var desired_result_id: StringName = &""

@export_multiline var satisfied_text: String = "Дякую, мольфаре. Мені вже легше."
@export_multiline var unhelped_text: String = "...це не те, що мені було треба."

## Shown in ThresholdDialogue while deciding whether to invite them in.
@export var portrait_door: Texture2D

## Shown in ReceptionUI once they're waiting inside for a potion/ward.
## Falls back to portrait_door until a second pose exists — see
## get_waiting_portrait().
@export var portrait_waiting: Texture2D

func is_human() -> bool:
	return true_threat == Threat.Type.NONE

func get_waiting_portrait() -> Texture2D:
	return portrait_waiting if portrait_waiting != null else portrait_door
