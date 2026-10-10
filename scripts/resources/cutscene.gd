class_name Cutscene
extends Resource
## A sequence of held frames with text over them.
##
## Chosen over video on purpose. The menu backdrop is a real video and
## that is right for a loop nobody reads; a cutscene carries words, and
## words baked into a video are the wrong size on half of screens, cannot
## be proofread without a re-render, and cannot be translated at all.
## These also cost kilobytes instead of megabytes, stay sharp at any
## resolution, and can look at StoryFlags — so the same cutscene can tell
## a player who sheltered нечисть something it does not tell one who
## never opened the door.

@export var shots: Array[CutsceneShot] = []

## Where to go when it ends. Empty hands control back to whoever started
## it instead of changing scene, which is what an in-game beat wants.
@export var next_scene: String = ""

## Looped underneath the whole thing — an AudioDirector id.
@export var ambience_id: StringName = &""

## Shots whose conditions are met, in order.
func eligible_shots() -> Array[CutsceneShot]:
	var out: Array[CutsceneShot] = []
	for shot in shots:
		if shot != null and shot.is_eligible():
			out.append(shot)
	return out
