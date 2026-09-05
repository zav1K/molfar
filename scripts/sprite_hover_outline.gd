extends CanvasItem
## Tweens sprite_outline.gdshader's `highlight` uniform 0..1 while the
## parent InteractionZone is hovered — the silhouette-outline equivalent
## of hover_glow.gd's modulate.a fade, for a zone with real cutout art
## (a TextureRect whose own material uses that shader) instead of a
## generic overlay rect. Attach directly to the sprite itself, not a
## separate "Visual" child — the shader reads that same sprite's texture.

@export var fade_time: float = 0.15

@onready var zone: InteractionZone = get_parent()
@onready var _material: ShaderMaterial = material

func _ready() -> void:
	zone.hover_started.connect(_on_hover_started)
	zone.hover_ended.connect(_on_hover_ended)

func _on_hover_started(_zone: InteractionZone) -> void:
	create_tween().tween_property(_material, "shader_parameter/highlight", 1.0, fade_time)

func _on_hover_ended(_zone: InteractionZone) -> void:
	create_tween().tween_property(_material, "shader_parameter/highlight", 0.0, fade_time)
