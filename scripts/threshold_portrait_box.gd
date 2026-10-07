class_name ThresholdPortraitBox
extends Control
## The doorway frame in ThresholdDialogue. Exists only so the box can
## paint a stand-in when the visitor has no portrait — otherwise the
## doorway is simply empty, which reads as a broken scene rather than as
## art that isn't drawn yet. See VisitorSilhouette.
##
## Harmless at the door (the dialogue's text and both buttons are there
## regardless), unlike in the hut, where the figure is the only thing to
## click. Matched here so the same visitor doesn't appear as a silhouette
## on one screen and as nothing on the next.

var _silhouette: bool = false

func set_silhouette(on: bool) -> void:
	if _silhouette == on:
		return
	_silhouette = on
	queue_redraw()

func _draw() -> void:
	if _silhouette:
		VisitorSilhouette.draw_into(self, size)
