class_name ThresholdDialogue
extends CanvasLayer
## Full-screen "visitor on the threshold" overlay: shows their stated
## problem and asks whether to invite them in. Both outcomes are
## placeholders for now — see Door/Visitor for why the choice matters later.

signal resolved(invited: bool)

@onready var portrait: TextureRect = $Panel/Portrait
@onready var name_label: Label = $Panel/NameLabel
@onready var problem_label: Label = $Panel/ProblemLabel
@onready var invite_button: Button = $Panel/InviteButton
@onready var refuse_button: Button = $Panel/RefuseButton

func _ready() -> void:
	visible = false
	invite_button.pressed.connect(func() -> void: _resolve(true))
	refuse_button.pressed.connect(func() -> void: _resolve(false))

func show_visitor(visitor: Visitor) -> void:
	portrait.texture = visitor.portrait_door
	portrait.visible = visitor.portrait_door != null
	name_label.text = visitor.display_name
	problem_label.text = visitor.problem_text
	visible = true

func _resolve(invited: bool) -> void:
	visible = false
	resolved.emit(invited)
