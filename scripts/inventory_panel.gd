class_name InventoryPanel
extends CanvasLayer
## Stock-list overlay for glancing at held herbs, potions, or carved
## sigils — instanced three times in Hut.tscn (one per `kind`), each
## opened by its own decorative trigger zone (drying beam for herbs,
## potion shelf for potions, a spot on the desk for sigils). All three
## zones are purely decorative, not physical per-item displays: no
## drag-and-drop, no per-slot anchors, no slot-count/equipment-
## progression bookkeeping. The chest on the right panel is meant to
## become the actual full-stockpile screen later — these are just the
## quick-glance versions for their own atmospheric hotspots.

enum Kind { INGREDIENTS, POTIONS, SIGILS }

@export var kind: Kind = Kind.INGREDIENTS

signal closed
signal potion_selected(potion: Potion)

@onready var title_label: Label = $Panel/Title
@onready var list: VBoxContainer = $Panel/List
@onready var close_button: Button = $Panel/CloseButton

func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close_pressed)
	match kind:
		Kind.INGREDIENTS:
			title_label.text = "Трави"
		Kind.POTIONS:
			title_label.text = "Зілля"
		Kind.SIGILS:
			title_label.text = "Обереги"

func open() -> void:
	_rebuild()
	visible = true

func _rebuild() -> void:
	for child in list.get_children():
		child.queue_free()
	match kind:
		Kind.INGREDIENTS:
			for ingredient in IngredientDatabase.get_all():
				var count := PlayerInventory.get_count(ingredient.id)
				if count > 0:
					list.add_child(_build_icon_row(ingredient.bundle_icon, ingredient.display_name, count))
		Kind.POTIONS:
			for potion in PotionDatabase.get_all():
				var count := PlayerInventory.get_count(potion.id)
				if count > 0:
					list.add_child(_build_potion_row(potion, count))
		Kind.SIGILS:
			# One row per physical carved object, not grouped by type+count —
			# each shows that specific instance's own traced stroke (see
			# CarvedSigilRegistry), so two of "the same" sigil can look
			# different, which is the whole point.
			for sigil in SigilDatabase.get_all():
				for instance in CarvedSigilRegistry.peek_instances(sigil.id):
					list.add_child(_build_sigil_row(sigil, instance))

func _build_icon_row(icon_texture: Texture2D, label_text: String, count: int) -> HBoxContainer:
	var row := HBoxContainer.new()

	if icon_texture != null:
		var icon := TextureRect.new()
		icon.texture = icon_texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(28, 28)
		row.add_child(icon)

	var label := Label.new()
	label.text = "%s ×%d" % [label_text, count]
	row.add_child(label)

	return row

func _build_sigil_row(sigil: Sigil, instance: CarvedSigilInstance) -> HBoxContainer:
	var row := HBoxContainer.new()

	var icon := SigilIcon.new()
	icon.custom_minimum_size = Vector2(36, 36)
	icon.setup(sigil, instance.stroke_points)
	row.add_child(icon)

	var label := Label.new()
	label.text = sigil.display_name
	row.add_child(label)

	return row

func _build_potion_row(potion: Potion, count: int) -> Button:
	var button := Button.new()
	button.text = "%s ×%d" % [potion.display_name, count]
	button.pressed.connect(func() -> void: potion_selected.emit(potion))
	return button

func _on_close_pressed() -> void:
	visible = false
	closed.emit()
