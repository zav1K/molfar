class_name GrimoireUI
extends CanvasLayer
## The molfar's own diary and reference shelf on PanelRight's desk. In
## Розділ І the player IS the old molfar (see Molfar), so this is his
## book, written as he goes — and it is the same book CONCEPT.md lists as
## a full-game feature, "щоденники попереднього мольфара", found and read
## by the heir who comes after him. Whatever the player opens here is
## what that heir will later find, which is why the Щоденник tab is
## written in his voice rather than as UI copy.
##
## It doubles as a standing reference for all three guidebooks
## (GUIDEBOOKS.md is the source-of-truth content this reads off of):
## what each brew is for,
## which herbs go into it, what each sigil is for. Same tabbed-panel
## pattern as InventoryPanel's Kind.ALL "Chest" screen — one tab per
## section, content rebuilt into a scrollable list on tab switch.
##
## Three of the four tabs are purely a lookup aid, same spirit as
## CarvingUI's reference book — nothing there is clickable/selectable,
## it only reads the databases. The fourth, "Щоденник", is different: a
## short in-fiction note per story beat (see STORY.md), appearing once
## its StoryFlags flag is set — the one place in the game a player can
## actually notice the scripted visitor chain is A Thing, rather than
## just more one-off vignettes indistinguishable from everyone else's.

enum Section { POTIONS, INGREDIENTS, SIGILS, DIARY }
const SECTION_TITLES := {
	Section.POTIONS: "Відвари",
	Section.INGREDIENTS: "Трави",
	Section.SIGILS: "Обереги",
	Section.DIARY: "Щоденник",
}

## Paper and ink, matching SigilPatternIcon — which has drawn its
## patterns on parchment since before this screen existed, and is the
## reason the grimoire reads as a book rather than as another dark
## panel. Everything else in the hut's UI is dark because it is the hut
## at night; this is a thing the molfar is holding.
const PAPER := Color(0.82, 0.74, 0.57)
const PAPER_EDGE := Color(0.46, 0.38, 0.27)
const INK := Color(0.16, 0.11, 0.07)
const INK_FADED := Color(0.40, 0.32, 0.23)
const RULE := Color(0.50, 0.42, 0.30, 0.55)

const TITLE_FONT_SIZE := 22
const ENTRY_TITLE_FONT_SIZE := 17
const ENTRY_SUBTITLE_FONT_SIZE := 12
const BODY_FONT_SIZE := 13
const DIARY_FONT_SIZE := 14
const DAY_STAMP_FONT_SIZE := 11

const ICON_SIZE := Vector2(54, 54)
const DAY_STAMP_WIDTH := 62.0

const NO_RECIPE_TEXT := "рецепт ще невідомий"
const UNUSED_INGREDIENT_TEXT := "не входить у жоден відвар"
const EMPTY_DIARY_TEXT := "Поки що записувати нічого."
const UNDATED_TEXT := "—"

## Curated, not a raw flag dump — StoryFlags accumulates all sorts of
## small barter-for-information flags too, not every one of them is a
## diary-worthy beat. Shown in this fixed order, skipping any flag not
## yet set — so this reads as notes accumulating over the playthrough,
## never a spoiler list of what's still to come.
const DIARY_ENTRIES: Array[Dictionary] = [
	{flag = &"lisnyk_saw_digging", text = "Микола бачив вогник там, де вогню бути не мало. Каже, хтось копав за старою стежкою."},
	{flag = &"met_hidden_upyr", text = "Ночами в селі ховається не лише нечисть — дехто серед людей теж боїться вигону."},
	{flag = &"upyr_curse_origin_known", text = "Упириця обмовилась, звідки насправді взялося їхнє прокляття."},
	{flag = &"lisnyk_decided_to_tell", text = "Микола вирішив розповісти священнику, що бачив. Сказав, що вперше за тижні спить спокійно."},
	{flag = &"strange_night_before_death", text = "Цієї ночі нечисть сама просила зачинити двері міцніше. Не питала нічого, не просила нічого."},
	{flag = &"village_noticed_nechyst", text = "Люди почали питати, чому в мене вночі світло. Питають обережно, наче між іншим, і не слухають, що відповідаю."},
	{flag = &"lisnyk_found_dead", text = "Миколу знайшли мертвим під старим дубом. Село вже каже — то нечисть."},
	{flag = &"village_marked_nechyst", text = "Коваль не підняв на мене очей. Мене вже не питають — про мене вже вирішили."},
	{flag = &"knows_vurdalak_mimicry", text = "Та, що гріла руки в мене коло печі, сказала річ, якої не знає ніхто в селі: є такі, що вивчають чийсь голос і стукають ним уночі. Між словами вони не дихають."},
	{flag = &"met_vurdalak", text = "Воно стояло під дверима й кликало мене на ім'я голосом живої людини. Живої — я перевірив уранці."},
	{flag = &"vurdalak_wore_lisnyk", text = "Цієї ночі воно прийшло його голосом. Казало, що ще не все мені розповіло. Воно й не знало, що саме, — просто повторювало."},
	{flag = &"let_vurdalak_in", text = "Я відчинив. Я сорок років кажу людям не відчиняти, і я відчинив."},
	{flag = &"priest_forbade_nechyst", text = "Священник заборонив допомагати нечисті й тим, хто її переховує. Поспішав, наче сам боявся питань."},
	{flag = &"elder_hunt_warning", text = "Староста каже — людей уже не стримати, хочуть обходити хати й шукати, хто не такий, як усі."},
	{flag = &"soldier_stories_heard", text = "Вояк розповів дещо про дороги, якими йшов додому."},
	{flag = &"likho_confronted", text = "Лихо приходило вночі питати, чому я втрутився. Не знаю, чи правильно відповів."},
]

signal closed

@onready var tab_bar: HBoxContainer = $Panel/TabBar
@onready var list: VBoxContainer = $Panel/ScrollContainer/List
@onready var close_button: Button = $Panel/CloseButton

var _active_section: Section = Section.POTIONS

func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close_pressed)
	_build_tab_buttons()

func open() -> void:
	_rebuild()
	visible = true

func _build_tab_buttons() -> void:
	for section in Section.values():
		var button := Button.new()
		button.text = SECTION_TITLES[section]
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_color_override(&"font_color", INK_FADED)
		button.add_theme_color_override(&"font_pressed_color", INK)
		button.add_theme_color_override(&"font_hover_color", INK)
		button.add_theme_color_override(&"font_focus_color", INK)
		# Tabs as ribbons on the page rather than as buttons over it: the
		# unselected ones are bare paper, the selected one is the only
		# thing with an edge under it.
		button.add_theme_stylebox_override(&"normal", _tab_style(false))
		button.add_theme_stylebox_override(&"hover", _tab_style(false))
		button.add_theme_stylebox_override(&"pressed", _tab_style(true))
		button.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
		button.pressed.connect(func() -> void:
			_active_section = section
			_rebuild())
		tab_bar.add_child(button)

func _tab_style(active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(PAPER.r, PAPER.g, PAPER.b, 0.0 if not active else 0.55)
	style.border_width_bottom = 2 if active else 1
	style.border_color = PAPER_EDGE if active else Color(PAPER_EDGE.r, PAPER_EDGE.g, PAPER_EDGE.b, 0.3)
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style

func _refresh_tab_buttons() -> void:
	for i in tab_bar.get_child_count():
		(tab_bar.get_child(i) as Button).button_pressed = (i == _active_section)

func _rebuild() -> void:
	# Detached before freeing, not just queued: queue_free is deferred, so
	# the old rows still answer get_child_count() while the new ones are
	# being added — which gave every rebuilt tab a stray rule above its
	# first entry (see _add_ruled).
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	_refresh_tab_buttons()
	match _active_section:
		Section.POTIONS:
			for potion in PotionDatabase.get_all():
				_add_ruled(_build_potion_entry(potion))
		Section.INGREDIENTS:
			for ingredient in IngredientDatabase.get_all():
				_add_ruled(_build_ingredient_entry(ingredient))
		Section.SIGILS:
			for sigil in SigilDatabase.get_all():
				_add_ruled(_build_sigil_entry(sigil))
		Section.DIARY:
			_build_diary()

## Appends an entry with a hairline above it, except for the first —
## what separates entries on a page is a rule, not a gap.
func _add_ruled(entry: Control) -> void:
	if list.get_child_count() > 0:
		list.add_child(_rule())
	list.add_child(entry)

func _build_potion_entry(potion: Potion) -> Control:
	var recipe_lines: Array[String] = []
	for recipe in RecipeDatabase.get_all():
		if recipe.light_result_id == potion.id:
			recipe_lines.append("%s — по сонцю" % _ingredients_text(recipe.ingredients))
		if recipe.dark_result_id == potion.id:
			recipe_lines.append("%s — проти сонця" % _ingredients_text(recipe.ingredients))
	var subtitle := ", ".join(recipe_lines) if not recipe_lines.is_empty() else NO_RECIPE_TEXT
	return _build_entry(_texture_icon(potion.icon), potion.display_name, subtitle, potion.description)

func _build_ingredient_entry(ingredient: Ingredient) -> Control:
	var uses: Array[String] = []
	for recipe in RecipeDatabase.get_all():
		if not recipe.ingredients.has(ingredient.id):
			continue
		if recipe.light_result_id != &"":
			uses.append(_potion_name(recipe.light_result_id))
		if recipe.dark_result_id != &"":
			uses.append(_potion_name(recipe.dark_result_id))
	var subtitle := "Відвари: %s" % ", ".join(uses) if not uses.is_empty() else UNUSED_INGREDIENT_TEXT
	return _build_entry(_texture_icon(ingredient.bundle_icon), ingredient.display_name, subtitle, ingredient.description)

## Sigils carry no icon texture and need none: SigilPatternIcon draws
## the path_points the player will actually trace with the knife, so the
## reference shows the real shape rather than a picture of one.
func _build_sigil_entry(sigil: Sigil) -> Control:
	var pattern := SigilPatternIcon.new()
	pattern.custom_minimum_size = ICON_SIZE
	pattern.setup(sigil)
	var subtitle := "оберіг" if sigil.kind == Sigil.Kind.WARD else "клеймо (прокляття)"
	return _build_entry(pattern, sigil.display_name, subtitle, sigil.description)

func _build_diary() -> void:
	var shown := 0
	for entry in DIARY_ENTRIES:
		if StoryFlags.has_flag(entry.flag):
			if shown > 0:
				list.add_child(_rule())
			list.add_child(_build_diary_entry(entry.text, StoryFlags.get_flag_day(entry.flag)))
			shown += 1
	if shown == 0:
		list.add_child(_build_diary_entry(EMPTY_DIARY_TEXT, 0))

## Dated in the margin, the way the entries themselves are written — the
## diary is the one tab that is the molfar's own hand rather than a
## reference, so it gets no icon, no title and no boxed row.
func _build_diary_entry(text: String, day: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 14)

	var stamp := Label.new()
	stamp.custom_minimum_size.x = DAY_STAMP_WIDTH
	stamp.text = ("День %d" % day) if day > 0 else UNDATED_TEXT
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stamp.add_theme_font_size_override(&"font_size", DAY_STAMP_FONT_SIZE)
	stamp.add_theme_color_override(&"font_color", INK_FADED)
	row.add_child(stamp)

	var body := Label.new()
	body.text = text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override(&"font_size", DIARY_FONT_SIZE)
	body.add_theme_color_override(&"font_color", INK)
	body.add_theme_constant_override(&"line_spacing", 4)
	row.add_child(body)
	return row

func _ingredients_text(ingredients: Dictionary) -> String:
	var parts: Array[String] = []
	for ingredient_id in ingredients:
		var ingredient := IngredientDatabase.get_ingredient(ingredient_id)
		var display_name: String = ingredient.display_name if ingredient != null else String(ingredient_id)
		parts.append("%s ×%d" % [display_name, ingredients[ingredient_id]])
	return ", ".join(parts)

func _potion_name(potion_id: StringName) -> String:
	var potion := PotionDatabase.get_potion(potion_id)
	return potion.display_name if potion != null else String(potion_id)

## One reference row: the thing on the left, what it is on the right.
## No panel and no border — a boxed card per entry reads as a list of
## widgets, and the point of this screen is that it reads as a page.
func _build_entry(icon: Control, title: String, subtitle: String, body: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 14)

	icon.custom_minimum_size = ICON_SIZE
	icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(icon)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override(&"separation", 2)
	row.add_child(box)

	box.add_child(_text(title, ENTRY_TITLE_FONT_SIZE, INK))
	box.add_child(_text(subtitle, ENTRY_SUBTITLE_FONT_SIZE, INK_FADED))
	var body_label := _text(body, BODY_FONT_SIZE, INK)
	body_label.add_theme_constant_override(&"line_spacing", 3)
	box.add_child(body_label)
	return row

func _text(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	return label

## A TextureRect for an icon that exists, or an empty spacer for one that
## does not — every potion and ingredient has art today, but a new one
## added tomorrow should leave a gap, not break the row.
func _texture_icon(texture: Texture2D) -> Control:
	if texture == null:
		return Control.new()
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return rect

func _rule() -> Control:
	var line := ColorRect.new()
	line.color = RULE
	line.custom_minimum_size = Vector2(0, 1)
	return line

## Closes the overlay and reports it, so the hut can put the nav
## arrows back. Public because Esc routes through here too (see
## hut.gd's _unhandled_input), not just the on-screen button.
func close() -> void:
	visible = false
	closed.emit()

func _on_close_pressed() -> void:
	close()
