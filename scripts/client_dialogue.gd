extends CanvasLayer
## Placeholder client-visit mode, entered by clicking the desk window.
## Just a back button for now — actual dialogue/diagnosis mechanics land later.

@onready var back_button: Button = $Panel/BackButton

func _ready() -> void:
	visible = false
	back_button.pressed.connect(func() -> void: visible = false)
