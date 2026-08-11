class_name ThresholdDialogue
extends CanvasLayer
## Full-screen "visitor on the threshold" overlay: shows their stated
## problem and asks whether to invite them in. Both outcomes are
## placeholders for now — see Door/Visitor for why the choice matters later.
##
## Portrait is fit (not cropped) inside PortraitBox using the visitor's
## own measured waiting_portrait_content_rect — same underlying data as
## WaitingVisitorDisplay, but scaled to show the whole figure rather than
## overflow-and-clip at a table line, since there's no table here. The
## dialogue text sits in its own translucent panel added after (so drawn
## on top of) the door art and portrait, the same way a real speech
## panel would sit in front of a scene rather than squeezed below it.

signal resolved(invited: bool)

const MAX_FIT_FRACTION := 0.96 ## small margin so the figure doesn't touch the box edges.

@onready var portrait_box: Control = $Panel/PortraitBox
@onready var portrait_icon: TextureRect = $Panel/PortraitBox/Icon
@onready var name_label: Label = $Panel/DialogueBox/NameLabel
@onready var problem_label: Label = $Panel/DialogueBox/ProblemLabel
@onready var invite_button: Button = $Panel/DialogueBox/InviteButton
@onready var refuse_button: Button = $Panel/DialogueBox/RefuseButton

func _ready() -> void:
	visible = false
	invite_button.pressed.connect(func() -> void: _resolve(true))
	refuse_button.pressed.connect(func() -> void: _resolve(false))

func show_visitor(visitor: Visitor) -> void:
	var tex := visitor.portrait_door
	portrait_icon.visible = tex != null
	if tex != null:
		portrait_icon.texture = tex
		_fit_portrait(visitor, tex)
	name_label.text = visitor.display_name
	problem_label.text = visitor.problem_text
	visible = true

## Scales the measured content rect to fit entirely inside portrait_box
## (unlike WaitingVisitorDisplay, which deliberately overflows to get
## clipped at a table line) — here we want the whole figure visible,
## standing in the doorway.
func _fit_portrait(visitor: Visitor, tex: Texture2D) -> void:
	var rect := visitor.waiting_portrait_content_rect
	var tex_size := Vector2(tex.get_width(), tex.get_height())
	var content_size := Vector2(rect.size.x * tex_size.x, rect.size.y * tex_size.y)
	var box_size := portrait_box.size * MAX_FIT_FRACTION
	var content_scale := minf(box_size.x / content_size.x, box_size.y / content_size.y)
	portrait_icon.size = tex_size * content_scale
	var centering := (portrait_box.size - content_size * content_scale) / 2.0
	portrait_icon.position = centering - Vector2(rect.position.x * tex_size.x, rect.position.y * tex_size.y) * content_scale

func _resolve(invited: bool) -> void:
	visible = false
	resolved.emit(invited)
