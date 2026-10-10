class_name CutsceneShot
extends Resource
## One held frame of a cutscene: a stack of layers and a line of text.
##
## Shots are the unit the player advances through, not the seconds. The
## duration below is how long a shot waits before moving on by itself;
## a click moves on sooner, because a reader who has finished reading
## should never be made to sit and wait for a timer they cannot see.

## The generated clip for this shot, when there is one. Godot plays Ogg
## Theora and nothing else, so whatever the generator produces has to be
## converted — see assets/video/README.md.
##
## Deliberately without its own words. A caption baked into the picture
## is the wrong size on half of screens, cannot be proofread without
## re-rendering the clip, and cannot be translated at all — so the clip
## carries the image and the engine draws the text over it.
@export var video: VideoStream

## Drawn when there is no video: a still background with a few cut-out
## pieces moving over it (see CutsceneLayer). Not a lesser version of
## the same shot — it is how a shot is written and timed before its clip
## has been generated, and how one that never gets generated still plays.
@export var layers: Array[CutsceneLayer] = []

@export_multiline var caption: String = ""

## Seconds the shot holds after its caption has finished printing. It is
## a ceiling, not a pace: clicking moves on at once, and a shot playing a
## video moves on when the video ends if that comes first.
@export var duration: float = 6.0

## Holds the clip's last frame instead of cutting away when it ends, for
## a shot whose caption is still being read. Off means the shot ends with
## the video.
@export var hold_last_frame: bool = true

## Seconds to crossfade from the shot before this one.
@export var fade_from_previous: float = 1.0

## Story gating, so one cutscene can read back what the player did
## instead of a second cutscene existing to say the other thing. A shot
## whose condition fails is skipped entirely; empty means always shown.
@export var required_flag: StringName = &""
@export var forbidden_flag: StringName = &""

## Played once as the shot opens — an AudioDirector id, not a file.
@export var sound_id: StringName = &""

func is_eligible() -> bool:
	if required_flag != &"" and not StoryFlags.has_flag(required_flag):
		return false
	if forbidden_flag != &"" and StoryFlags.has_flag(forbidden_flag):
		return false
	return true
