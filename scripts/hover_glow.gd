extends CanvasItem
## Fades this node in while the parent InteractionZone is hovered, out otherwise.
## Attach to a plain ColorRect/Label/ReferenceRect sitting on top of a
## background region — no separate art file needed, the region itself IS
## the background art. Every zone's "Visual" child is a ReferenceRect
## (a border only, no fill) using this — a thin outline around the
## clickable area reads clearly at rest-state invisible, hover-visible,
## without covering the art the way a translucent full-rect fill did.

@export var fade_time: float = 0.15
@export var max_alpha: float = 0.9

@onready var zone: InteractionZone = get_parent()

func _ready() -> void:
	modulate.a = 0.0
	zone.hover_started.connect(_on_hover_started)
	zone.hover_ended.connect(_on_hover_ended)

func _on_hover_started(_zone: InteractionZone) -> void:
	create_tween().tween_property(self, "modulate:a", max_alpha, fade_time)

func _on_hover_ended(_zone: InteractionZone) -> void:
	create_tween().tween_property(self, "modulate:a", 0.0, fade_time)
