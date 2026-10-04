class_name GrimoireUI
extends CanvasLayer
## The "щоденник попереднього мольфара" spot on PanelRight's desk —
## a standing reference for all three guidebooks (GUIDEBOOKS.md is the
## source-of-truth content this reads off of): what each brew is for,
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

const ENTRY_TITLE_FONT_SIZE := 16
const ENTRY_SUBTITLE_FONT_SIZE := 12
const ENTRY_SUBTITLE_COLOR := Color(0.85, 0.75, 0.55)
const NO_RECIPE_TEXT := "рецепт ще невідомий"
const UNUSED_INGREDIENT_TEXT := "не використовується у відварах"
const EMPTY_DIARY_TEXT := "Поки що нічого записати."

## Curated, not a raw flag dump — StoryFlags accumulates all sorts of
## small barter-for-information flags too, not every one of them is a
## diary-worthy beat. Shown in this fixed order, skipping any flag not
## yet set — so this reads as notes accumulating over the playthrough,
## never a spoiler list of what's still to come.
const DIARY_ENTRIES: Array[Dictionary] = [
	{flag = &"lisnyk_saw_digging", text = "Лісник бачив вогник там, де вогню бути не мало. Каже, хтось копав за старою стежкою."},
	{flag = &"met_hidden_upyr", text = "Ночами в селі ховається не лише нечисть — дехто серед людей теж боїться вигону."},
	{flag = &"upyr_curse_origin_known", text = "Упириця обмовилась, звідки насправді взялося їхнє прокляття."},
	{flag = &"lisnyk_decided_to_tell", text = "Лісник вирішив розповісти священнику, що бачив. Сказав, що вперше за тижні спить спокійно."},
	{flag = &"strange_night_before_death", text = "Цієї ночі нечисть сама просила зачинити двері міцніше. Не питала нічого, не просила нічого."},
	{flag = &"lisnyk_found_dead", text = "Лісника знайшли мертвим під старим дубом. Село вже каже — то нечисть."},
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
		button.pressed.connect(func() -> void:
			_active_section = section
			_rebuild())
		tab_bar.add_child(button)

func _refresh_tab_buttons() -> void:
	for i in tab_bar.get_child_count():
		(tab_bar.get_child(i) as Button).button_pressed = (i == _active_section)

func _rebuild() -> void:
	for child in list.get_children():
		child.queue_free()
	_refresh_tab_buttons()
	match _active_section:
		Section.POTIONS:
			for potion in PotionDatabase.get_all():
				list.add_child(_build_potion_entry(potion))
		Section.INGREDIENTS:
			for ingredient in IngredientDatabase.get_all():
				list.add_child(_build_ingredient_entry(ingredient))
		Section.SIGILS:
			for sigil in SigilDatabase.get_all():
				list.add_child(_build_sigil_entry(sigil))
		Section.DIARY:
			_build_diary()

func _build_potion_entry(potion: Potion) -> PanelContainer:
	var recipe_lines: Array[String] = []
	for recipe in RecipeDatabase.get_all():
		if recipe.light_result_id == potion.id:
			recipe_lines.append("%s — по сонцю" % _ingredients_text(recipe.ingredients))
		if recipe.dark_result_id == potion.id:
			recipe_lines.append("%s — проти сонця" % _ingredients_text(recipe.ingredients))
	var subtitle := ", ".join(recipe_lines) if not recipe_lines.is_empty() else NO_RECIPE_TEXT
	return _build_entry(potion.display_name, subtitle, potion.description)

func _build_ingredient_entry(ingredient: Ingredient) -> PanelContainer:
	var uses: Array[String] = []
	for recipe in RecipeDatabase.get_all():
		if not recipe.ingredients.has(ingredient.id):
			continue
		if recipe.light_result_id != &"":
			uses.append(_potion_name(recipe.light_result_id))
		if recipe.dark_result_id != &"":
			uses.append(_potion_name(recipe.dark_result_id))
	var subtitle := "Відвари: %s" % ", ".join(uses) if not uses.is_empty() else UNUSED_INGREDIENT_TEXT
	return _build_entry(ingredient.display_name, subtitle, ingredient.description)

func _build_sigil_entry(sigil: Sigil) -> PanelContainer:
	var subtitle := "оберіг" if sigil.kind == Sigil.Kind.WARD else "клеймо (прокляття)"
	return _build_entry(sigil.display_name, subtitle, sigil.description)

func _build_diary() -> void:
	var shown := 0
	for entry in DIARY_ENTRIES:
		if StoryFlags.has_flag(entry.flag):
			list.add_child(_build_diary_entry(entry.text))
			shown += 1
	if shown == 0:
		list.add_child(_build_diary_entry(EMPTY_DIARY_TEXT))

func _build_diary_entry(text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	var body_label := Label.new()
	body_label.text = text
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	panel.add_child(body_label)
	return panel

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

func _build_entry(title: String, subtitle: String, body: String) -> PanelContainer:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	panel.add_child(box)

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", ENTRY_TITLE_FONT_SIZE)
	box.add_child(title_label)

	var subtitle_label := Label.new()
	subtitle_label.text = subtitle
	subtitle_label.add_theme_font_size_override("font_size", ENTRY_SUBTITLE_FONT_SIZE)
	subtitle_label.modulate = ENTRY_SUBTITLE_COLOR
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(subtitle_label)

	var body_label := Label.new()
	body_label.text = body
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(body_label)

	return panel

func _on_close_pressed() -> void:
	visible = false
	closed.emit()
