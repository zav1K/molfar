class_name PotionDetailPopup
extends CanvasLayer
## Full-screen "zoomed in" look at a brewed potion: enlarged jar art plus
## its name and description, opened by clicking a jar on the shelf.

@onready var icon: TextureRect = $Panel/Icon
@onready var name_label: Label = $Panel/NameLabel
@onready var description_label: Label = $Panel/DescriptionLabel
@onready var close_button: Button = $Panel/CloseButton

func _ready() -> void:
	visible = false
	close_button.pressed.connect(close)

func show_potion(potion: Potion) -> void:
	icon.texture = potion.icon
	name_label.text = potion.display_name
	description_label.text = potion.description
	visible = true
	icon.pivot_offset = icon.size / 2.0
	icon.scale = Vector2(0.7, 0.7)
	create_tween().tween_property(icon, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func close() -> void:
	visible = false
