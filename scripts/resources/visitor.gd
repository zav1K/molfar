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

func is_human() -> bool:
	return true_threat == Threat.Type.NONE
