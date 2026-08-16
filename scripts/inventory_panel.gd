class_name InventoryPanel
extends CanvasLayer
## Stock-list overlay for glancing at held herbs, potions, carved sigils,
## or (kind ALL only) everything at once. Instanced four times in
## Hut.tscn: three single-category quick-glance panels opened by their
## own decorative trigger zone (drying beam for herbs, potion shelf for
## potions, a spot on the desk for sigils), plus the chest on the right
## panel showing kind ALL — the actual full-stockpile screen, sectioned
## by category with a header per section. Each item is a big icon tile
## with its name/count underneath, laid out in a grid — not a text row.
## No drag-and-drop, no per-slot anchors, no slot-count/equipment-
## progression bookkeeping anywhere here.

enum Kind { INGREDIENTS, POTIONS, SIGILS, ALL }

const SECTION_TITLES := {
	Kind.INGREDIENTS: "Трави",
	Kind.POTIONS: "Зілля",
	Kind.SIGILS: "Обереги",
}
const KEEPSAKES_SECTION_TITLE := "Речі"

const ICON_SIZE := Vector2(112, 112)
const TILE_WIDTH := 132.0
const GRID_SEPARATION := 16
const LABEL_FONT_SIZE := 11

@export var kind: Kind = Kind.INGREDIENTS
@export var columns: int = 6

signal closed
signal potion_selected(potion: Potion)

@onready var title_label: Label = $Panel/Title
@onready var list: VBoxContainer = $Panel/ScrollContainer/List
@onready var close_button: Button = $Panel/CloseButton

func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close_pressed)
	title_label.text = "Скриня" if kind == Kind.ALL else SECTION_TITLES[kind]
	list.add_theme_constant_override("separation", 18)

func open() -> void:
	_rebuild()
	visible = true

func _rebuild() -> void:
	for child in list.get_children():
		child.queue_free()
	if kind == Kind.ALL:
		_add_section(SECTION_TITLES[Kind.INGREDIENTS], _ingredient_tiles())
		_add_section(SECTION_TITLES[Kind.POTIONS], _potion_tiles())
		_add_section(SECTION_TITLES[Kind.SIGILS], _sigil_tiles())
		_add_section(KEEPSAKES_SECTION_TITLE, _keepsake_tiles())
		return
	var grid := _new_grid()
	match kind:
		Kind.INGREDIENTS:
			for tile in _ingredient_tiles():
				grid.add_child(tile)
		Kind.POTIONS:
			for tile in _potion_tiles():
				grid.add_child(tile)
		Kind.SIGILS:
			for tile in _sigil_tiles():
				grid.add_child(tile)
	list.add_child(grid)

func _new_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", GRID_SEPARATION)
	grid.add_theme_constant_override("v_separation", GRID_SEPARATION)
	return grid

## A bordered card per category, not just a header label above a grid —
## Chest mixes four categories in one scroll, and a plain label reads as
## a running list rather than distinct groups once there are enough
## tiles to scroll past.
func _add_section(title: String, tiles: Array) -> void:
	if tiles.is_empty():
		return
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.04)
	style.border_color = Color(1, 1, 1, 0.16)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", style)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	card.add_child(inner)

	var header := Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 16)
	inner.add_child(header)

	var grid := _new_grid()
	for tile in tiles:
		grid.add_child(tile)
	inner.add_child(grid)

	list.add_child(card)

func _ingredient_tiles() -> Array:
	var tiles: Array = []
	for ingredient in IngredientDatabase.get_all():
		var count := PlayerInventory.get_count(ingredient.id)
		if count > 0:
			tiles.append(_build_tile(ingredient.bundle_icon, ingredient.placeholder_color, ingredient.display_name, count))
	return tiles

func _potion_tiles() -> Array:
	var tiles: Array = []
	for potion in PotionDatabase.get_all():
		var count := PlayerInventory.get_count(potion.id)
		if count > 0:
			tiles.append(_build_potion_tile(potion, count))
	return tiles

func _sigil_tiles() -> Array:
	var tiles: Array = []
	# One tile per physical carved object, not grouped by type+count —
	# each shows that specific instance's own traced stroke (see
	# CarvedSigilRegistry), so two of "the same" sigil can look
	# different, which is the whole point.
	for sigil in SigilDatabase.get_all():
		for instance in CarvedSigilRegistry.peek_instances(sigil.id):
			tiles.append(_build_sigil_tile(sigil, instance))
	return tiles

func _keepsake_tiles() -> Array:
	var tiles: Array = []
	for keepsake in KeepsakeDatabase.get_all():
		var count := PlayerInventory.get_count(keepsake.id)
		if count > 0:
			tiles.append(_build_tile(keepsake.icon, keepsake.placeholder_color, keepsake.display_name, count))
	return tiles

## Both dimensions get shrink-to-center explicitly — a GridContainer row
## stretches every cell to the tallest one in that row (varying label
## line-wrap heights), and a plain icon left to SIZE_FILL vertically
## would get stretched tall along with it, distorting square art.
func _build_icon_or_swatch(icon_texture: Texture2D, placeholder_color: Color) -> Control:
	if icon_texture != null:
		var icon := TextureRect.new()
		icon.texture = icon_texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = ICON_SIZE
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return icon
	var swatch := ColorRect.new()
	swatch.color = placeholder_color
	swatch.custom_minimum_size = ICON_SIZE
	swatch.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return swatch

func _build_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = TILE_WIDTH
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	return label

func _build_tile(icon_texture: Texture2D, placeholder_color: Color, label_text: String, count: int) -> VBoxContainer:
	var tile := VBoxContainer.new()
	tile.custom_minimum_size.x = TILE_WIDTH
	tile.add_child(_build_icon_or_swatch(icon_texture, placeholder_color))
	tile.add_child(_build_label("%s ×%d" % [label_text, count]))
	return tile

func _build_sigil_tile(sigil: Sigil, instance: CarvedSigilInstance) -> VBoxContainer:
	var tile := VBoxContainer.new()
	tile.custom_minimum_size.x = TILE_WIDTH

	var icon := SigilIcon.new()
	icon.custom_minimum_size = ICON_SIZE
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.setup(sigil, instance)
	tile.add_child(icon)

	tile.add_child(_build_label(sigil.display_name))
	return tile

## Plain VBoxContainer, same as every other tile — a Button doesn't lay
## out its children (it isn't a Container), so a Button-wrapped tile
## reports a wrong (too small) minimum size and GridContainer overlaps
## its row with the next one. Click detection is a gui_input tap instead
## of Button.pressed.
func _build_potion_tile(potion: Potion, count: int) -> VBoxContainer:
	var tile := VBoxContainer.new()
	tile.custom_minimum_size.x = TILE_WIDTH
	tile.mouse_filter = Control.MOUSE_FILTER_STOP
	tile.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			potion_selected.emit(potion))

	var icon_or_swatch := _build_icon_or_swatch(potion.icon, Color(0.4, 0.32, 0.5))
	icon_or_swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(icon_or_swatch)

	var label := _build_label("%s ×%d" % [potion.display_name, count])
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(label)

	return tile

func _on_close_pressed() -> void:
	visible = false
	closed.emit()
