class_name SigilWallDisplay
extends Control
## Carved wards and curse-marks hung as hut decoration — a visual record
## of the player's white/black path (see CONCEPT.md), mirroring
## PlayerInventory the same way potion_shelf_slot.gd does for potions.
## No per-sigil carved-icon art yet, so wards show as a warm/gold dot and
## curses as a dark one until real art replaces the placeholder.

const WARD_COLOR := Color(0.82, 0.68, 0.35)
const CURSE_COLOR := Color(0.32, 0.08, 0.12)

@onready var row: HBoxContainer = $Row

func _ready() -> void:
	PlayerInventory.changed.connect(_on_inventory_changed)
	_refresh()

func _on_inventory_changed(changed_id: StringName) -> void:
	if SigilDatabase.get_sigil(changed_id) != null:
		_refresh()

func _refresh() -> void:
	for child in row.get_children():
		child.queue_free()
	var any := false
	for sigil in SigilDatabase.get_all():
		var count := PlayerInventory.get_count(sigil.id)
		if count <= 0:
			continue
		any = true
		row.add_child(_build_icon(sigil, count))
	visible = any

func _build_icon(sigil: Sigil, count: int) -> Control:
	var tooltip := "%s ×%d" % [sigil.display_name, count]
	if sigil.icon != null:
		var icon := TextureRect.new()
		icon.texture = sigil.icon
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(34, 34)
		icon.tooltip_text = tooltip
		icon.mouse_filter = Control.MOUSE_FILTER_STOP
		return icon

	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = WARD_COLOR if sigil.kind == Sigil.Kind.WARD else CURSE_COLOR
	style.set_corner_radius_all(17)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(34, 34)
	panel.tooltip_text = tooltip
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	return panel
