class_name ThresholdDialogue
extends CanvasLayer
## Full-screen "visitor on the threshold" overlay: shows their stated
## problem and asks whether to invite them in. Both outcomes are
## placeholders for now — see Door/Visitor for why the choice matters later.
##
## Portrait is scaled to fill PortraitBox's height (the doorway is tall
## and narrow, so height is the meaningful constraint) using the visitor's
## own measured content rect (its own when the door portrait is a
## separate image, otherwise the waiting one) — same underlying data as
## WaitingVisitorDisplay. Width is allowed to modestly overflow into the
## door frame on either side, which reads naturally for a figure standing
## in a narrow doorway; portrait_box clips it so wide portraits (e.g. two
## people side by side) don't spill past the frame entirely. The dialogue
## text sits in its own translucent panel added after (so drawn on top of)
## the door art and portrait, the same way a real speech panel would sit
## in front of a scene rather than squeezed below it.

signal resolved(invited: bool)

const MAX_FIT_FRACTION := 0.98 ## small margin so the figure doesn't touch the box edges.

@onready var portrait_box: Control = $Panel/PortraitBox
@onready var portrait_icon: TextureRect = $Panel/PortraitBox/Icon
@onready var name_label: Label = $Panel/DialogueBox/NameLabel
@onready var problem_label: TypewriterLabel = $Panel/DialogueBox/ProblemLabel
@onready var invite_button: Button = $Panel/DialogueBox/InviteButton
@onready var refuse_button: Button = $Panel/DialogueBox/RefuseButton

func _ready() -> void:
	visible = false
	invite_button.pressed.connect(func() -> void: _resolve(true))
	refuse_button.pressed.connect(func() -> void: _resolve(false))

## `aside`, when given, is an extra paragraph after what they came about
## — currently the village's growing unease about who the molfar lets in
## after dark (see VillageSuspicion). Passed in rather than written into
## the Visitor, because Visitor resources are shared and cached: editing
## problem_text on one would stick for the rest of the playthrough.
func show_visitor(visitor: Visitor, aside: String = "") -> void:
	var tex := visitor.portrait_door
	portrait_icon.visible = tex != null
	if tex != null:
		portrait_icon.texture = tex
		_fit_portrait(visitor, tex)
	name_label.text = visitor.display_name
	problem_label.show_text(compose_problem_text(visitor, aside))
	visible = true

## Shared with ReceptionUI so the door and the table show the same words
## — the aside has to survive being invited in, or the text visibly
## changes under the player between one screen and the next.
static func compose_problem_text(visitor: Visitor, aside: String) -> String:
	if aside == "":
		return visitor.problem_text
	return "%s\n\n%s" % [visitor.problem_text, aside]

## Scales the measured content rect to fill portrait_box's height — the
## doorway is tall and narrow, so a "fit entirely inside" scale is always
## width-bound and leaves the figure tiny with empty space above/below.
## Filling by height instead lets the figure stand full-height in the
## doorway; any width overflow past the box just gets clipped by
## portrait_box (clip_contents = true), which reads naturally as the
## frame cropping a person standing in a narrow opening.
func _fit_portrait(visitor: Visitor, tex: Texture2D) -> void:
	var rect := visitor.get_door_content_rect()
	var tex_size := Vector2(tex.get_width(), tex.get_height())
	var content_size := Vector2(rect.size.x * tex_size.x, rect.size.y * tex_size.y)
	var box_size := portrait_box.size * MAX_FIT_FRACTION
	var content_scale: float = (box_size.y * visitor.figure_height_scale) / content_size.y
	portrait_icon.size = tex_size * content_scale
	# Centred across, but standing ON the floor rather than floating in
	# the middle of it — which only shows once someone is shorter than
	# the doorway (see Visitor.figure_height_scale).
	var scaled := content_size * content_scale
	var offset := Vector2((portrait_box.size.x - scaled.x) / 2.0, portrait_box.size.y - scaled.y)
	portrait_icon.position = offset - Vector2(rect.position.x * tex_size.x, rect.position.y * tex_size.y) * content_scale

func _resolve(invited: bool) -> void:
	visible = false
	resolved.emit(invited)
