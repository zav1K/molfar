class_name InventoryPanel
extends CanvasLayer
## Stock-list overlay for glancing at held herbs, potions, carved sigils,
## or (kind ALL only) everything at once. Instanced four times in
## Hut.tscn: three single-category quick-glance panels opened by their
## own decorative trigger zone (drying beam for herbs, potion shelf for
## potions, a spot on the desk for sigils), plus the chest on the right
## panel showing kind ALL — the actual full-stockpile screen, sectioned
## by category with a header per section. No drag-and-drop, no per-slot
## anchors, no slot-count/equipment-progression bookkeeping anywhere here.

enum Kind { INGREDIENTS, POTIONS, SIGILS, ALL }

const SECTION_TITLES := {
	Kind.INGREDIENTS: "Трави",
	Kind.POTIONS: "Зілля",
	Kind.SIGILS: "Обереги",
}
const KEEPSAKES_SECTION_TITLE := "Речі"

@export var kind: Kind = Kind.INGREDIENTS

signal closed
signal potion_selected(potion: Potion)

@onready var title_label: Label = $Panel/Title
@onready var list: VBoxContainer = $Panel/ScrollContainer/List
@onready var close_button: Button = $Panel/CloseButton

func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close_pressed)
	title_label.text = "Скриня" if kind == Kind.ALL else SECTION_TITLES[kind]

func open() -> void:
	_rebuild()
	visible = true

func _rebuild() -> void:
	for child in list.get_children():
		child.queue_free()
	if kind == Kind.ALL:
		_add_section(SECTION_TITLES[Kind.INGREDIENTS], _ingredient_rows())
		_add_section(SECTION_TITLES[Kind.POTIONS], _potion_rows())
		_add_section(SECTION_TITLES[Kind.SIGILS], _sigil_rows())
		_add_section(KEEPSAKES_SECTION_TITLE, _keepsake_rows())
		return
	match kind:
		Kind.INGREDIENTS:
			for row in _ingredient_rows():
				list.add_child(row)
		Kind.POTIONS:
			for row in _potion_rows():
				list.add_child(row)
		Kind.SIGILS:
			for row in _sigil_rows():
				list.add_child(row)

func _add_section(title: String, rows: Array) -> void:
	if rows.is_empty():
		return
	var header := Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 16)
	list.add_child(header)
	for row in rows:
		list.add_child(row)

func _ingredient_rows() -> Array:
	var rows: Array = []
	for ingredient in IngredientDatabase.get_all():
		var count := PlayerInventory.get_count(ingredient.id)
		if count > 0:
			rows.append(_build_icon_row(ingredient.bundle_icon, ingredient.placeholder_color, ingredient.display_name, count))
	return rows

func _potion_rows() -> Array:
	var rows: Array = []
	for potion in PotionDatabase.get_all():
		var count := PlayerInventory.get_count(potion.id)
		if count > 0:
			rows.append(_build_potion_row(potion, count))
	return rows

func _sigil_rows() -> Array:
	var rows: Array = []
	# One row per physical carved object, not grouped by type+count —
	# each shows that specific instance's own traced stroke (see
	# CarvedSigilRegistry), so two of "the same" sigil can look
	# different, which is the whole point.
	for sigil in SigilDatabase.get_all():
		for instance in CarvedSigilRegistry.peek_instances(sigil.id):
			rows.append(_build_sigil_row(sigil, instance))
	return rows

func _keepsake_rows() -> Array:
	var rows: Array = []
	for keepsake in KeepsakeDatabase.get_all():
		var count := PlayerInventory.get_count(keepsake.id)
		if count > 0:
			rows.append(_build_icon_row(keepsake.icon, keepsake.placeholder_color, keepsake.display_name, count))
	return rows

func _build_icon_row(icon_texture: Texture2D, placeholder_color: Color, label_text: String, count: int) -> HBoxContainer:
	var row := HBoxContainer.new()

	if icon_texture != null:
		var icon := TextureRect.new()
		icon.texture = icon_texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(28, 28)
		row.add_child(icon)
	else:
		var swatch := ColorRect.new()
		swatch.color = placeholder_color
		swatch.custom_minimum_size = Vector2(20, 20)
		row.add_child(swatch)

	var label := Label.new()
	label.text = "%s ×%d" % [label_text, count]
	row.add_child(label)

	return row

func _build_sigil_row(sigil: Sigil, instance: CarvedSigilInstance) -> HBoxContainer:
	var row := HBoxContainer.new()

	var icon := SigilIcon.new()
	icon.custom_minimum_size = Vector2(36, 36)
	icon.setup(sigil, instance)
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
