class_name CutsceneLayer
extends Resource
## One picture inside a cutscene shot, and how it moves.
##
## The whole format assumes semi-static shots: a painted background that
## never moves, and a handful of cut-out elements drifting over it. So a
## layer is one PNG with transparency, placed by its centre and given a
## single kind of motion. Nothing here interpolates between keyframes —
## that would be an animation tool, and an animation tool needs an editor
## to be worth anything. These are four numbers a person can reason about.
##
## A layer whose texture is missing is skipped rather than drawn as a
## placeholder, so a shot can be written before its art exists and played
## today with whatever parts have arrived. Same reasoning as the visitor
## silhouette, with the opposite answer: there is nothing to click here,
## so an empty frame under the caption is honest rather than broken.

enum Motion {
	STILL, ## the background, and anything else that holds position
	DRIFT, ## travels in a straight line — clouds, smoke leaving frame
	SWAY, ## swings back and forth — branches, a hanging charm
	RISE, ## travels up while fading out — hearth smoke, breath
	PULSE, ## breathes in opacity — firelight on a wall, a lit window
	ZOOM, ## creeps in or out — the slow push on a background
}

@export var texture: Texture2D

## Where the layer's centre sits in the frame, 0..1 across and down.
@export var anchor: Vector2 = Vector2(0.5, 0.5)

## Multiplies the size the texture would be drawn at when fitted to the
## frame's height. 1.0 fills it.
@export var scale_factor: float = 1.0

@export var motion: Motion = Motion.STILL

## What `motion` does with this depends on the kind:
##   DRIFT — pixels per second, x and y
##   SWAY  — how far it swings, x and y
##   RISE  — y is pixels per second upward; x adds a slow lean
##   PULSE — x is how much the opacity swings, 0..1
##   ZOOM  — x is the scale change per second (negative pulls back)
@export var amount: Vector2 = Vector2.ZERO

## Cycles per second, for the motions that repeat (SWAY, PULSE).
@export_range(0.0, 4.0, 0.01) var speed: float = 0.25

## Offsets the cycle so two layers of the same kind don't move as one.
@export_range(0.0, 1.0, 0.01) var phase: float = 0.0

@export_range(0.0, 1.0, 0.01) var opacity: float = 1.0
@export var tint: Color = Color.WHITE

## Seconds into the shot before this layer appears, and how long it takes
## to fade in and out. A layer with no fade is simply there.
@export var appear_at: float = 0.0
@export var fade_in: float = 0.0
@export var fade_out: float = 0.0
