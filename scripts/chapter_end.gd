class_name ChapterEnd
extends Control
## Розділ І's closing screen. Three jobs, in this order: close the
## chapter, show the player the game was listening, leave the hook.
##
## It is NOT a "thanks for playing" card. The chronicle is written in the
## molfar's own voice, the same diary voice as GrimoireUI, and every line
## after the first is conditional on what the player actually did — so a
## player who sheltered нечисть and a player who turned everyone away
## read two genuinely different endings.
##
## The last block is deliberately in someone else's hand, dated later,
## speaking about him in the third person, and it never explains itself.
## Played once it should just be unsettling; played after the full game
## (which is about the heir who finds this hut — see Molfar) it should be
## recognisable as whose hand that was. The chapter's real twist, the
## church's part in the murder, stays unspoken here on purpose.
##
## The demo footer sits below a rule, in a different colour and size,
## outside the fiction — the chronicle must not know it's a demo, or the
## tone the preceding seven days built collapses in one line.
##
## Reached two ways: straight from hut.gd when night 7 ends (autoload
## state is still live), or from the menu's "Продовжити" on a finished
## save (SaveGame.pending_load set, so the snapshot is pulled in here).

const MENU_SCENE := "res://scenes/MainMenu.tscn"

## Paced so the whole chronicle is up in a handful of seconds. The first
## version took 1.2s per block with 0.9s between, which on fourteen
## blocks meant nearly half a minute of an almost-black screen with a
## dead button — indistinguishable from the game having crashed, which
## is exactly how it was read in testing.
const LINE_FADE_SECONDS := 0.45
const LINE_DELAY_SECONDS := 0.22
## Grace period before the Back button accepts a click. A player who
## clicks twice to hurry the reveal along would otherwise land the
## second click on the button the first one just enabled, and be thrown
## out to the menu without reading a word.
const BUTTON_GRACE_SECONDS := 0.6

const CHRONICLE_FONT_SIZE := 15
const CHRONICLE_COLOR := Color(0.88, 0.83, 0.70)
## Cooler and paler than the chronicle — the visual cue that the closing
## block is another person's handwriting, before a single word of it is read.
const FOUND_NOTE_FONT_SIZE := 14
const FOUND_NOTE_COLOR := Color(0.60, 0.67, 0.77)
const TITLE_FONT_SIZE := 26
const TITLE_COLOR := Color(0.95, 0.85, 0.55)
const FOOTER_FONT_SIZE := 11
const FOOTER_COLOR := Color(0.55, 0.50, 0.42)
const RULE_COLOR := Color(0.45, 0.40, 0.32, 0.7)

@onready var chronicle: VBoxContainer = $Scroll/Chronicle
@onready var menu_button: Button = $MenuButton
@onready var skip_hint: Label = $SkipHint

## Every faded-in block, so a click can finish them all at once.
var _blocks: Array[Control] = []
var _reveal_tween: Tween
var _revealing: bool = false

func _ready() -> void:
	if SaveGame.pending_load:
		# Came from the menu rather than from the end of night 7, so the
		# autoloads are still at their startup defaults — pull the
		# finished save in before reading any of it below.
		SaveGame.pending_load = false
		SaveGame.load_game()
	menu_button.pressed.connect(_on_menu_pressed)
	# Transparent is still clickable, so it has to be disabled too, or a
	# stray click during the reveal silently leaves for the menu.
	menu_button.modulate.a = 0.0
	menu_button.disabled = true
	_build()

func _build() -> void:
	for line in _chronicle_lines():
		_add_text(line, CHRONICLE_FONT_SIZE, CHRONICLE_COLOR)
	_add_rule()
	_add_text("Кінець розділу І", TITLE_FONT_SIZE, TITLE_COLOR, HORIZONTAL_ALIGNMENT_CENTER)
	for line in _found_note_lines():
		_add_text(line, FOUND_NOTE_FONT_SIZE, FOUND_NOTE_COLOR)
	_add_rule()
	for line in _footer_lines():
		_add_text(line, FOOTER_FONT_SIZE, FOOTER_COLOR, HORIZONTAL_ALIGNMENT_CENTER)
	AudioDirector.play_music(&"trembita")
	_start_reveal()

## The molfar's own last entries. First line is unconditional — the
## murder happened whatever the player did — everything after it reads
## back a decision. Kept to five or six lines total: a longer list reads
## as a stats screen, and each line stops landing.
func _chronicle_lines() -> Array[String]:
	var lines: Array[String] = []
	lines.append("Миколу поховали на третій день по тому, як знайшли. Гріб несли четверо, п'ятого не знайшлося.")

	# The hidden upyr — the one visitor the chapter actually asks the
	# player to decide about. Silence if they never met her at all.
	if StoryFlags.has_flag(&"helped_hidden_upyr"):
		lines.append("Та, що просила навчити її здаватися людиною, навчилася. Прийшла востаннє в ніч перед обходами — не ховатися, а попередити мене. Більше я її не бачив, і добре, що не бачив.")
	elif StoryFlags.has_flag(&"misled_hidden_upyr"):
		lines.append("Я навчив її виходити на люди й знав, що роблю. На Стрітення в церкві був крик, а потім довго не було нічого. Я не питав. Мені й не казали — знали, що не питатиму.")
	elif StoryFlags.has_flag(&"met_hidden_upyr"):
		lines.append("Я не впустив її. Уранці під вікном лежав пучок барвінку, перев'язаний ниткою. Не мій.")

	# Whether the player ends the chapter able to doubt the priest, or
	# with nothing to set against him. The heart of the whole thing.
	if StoryFlags.has_flag(&"upyr_curse_origin_known"):
		lines.append("Я знаю, звідки взялося їхнє прокляття. З тим, що казав священник, це не збігається ніяк, і він знає, що не збігається.")
	else:
		lines.append("Я так і не дізнався, за що його вбили. Лишилося тільки те, що сказав священник, і перевірити це нічим.")

	var suspicion := VillageSuspicion.level()
	if suspicion == VillageSuspicion.Level.MARKED:
		lines.append("У селі знають, хто відчиняє двері після заходу сонця. Коваль цього тижня тричі не підняв на мене очей.")
	elif suspicion == VillageSuspicion.Level.NOTICED:
		lines.append("Хтось почав лічити, скільки разів у моєму вікні горіло світло вночі. Питають обережно, наче між іншим.")
	elif VillageSuspicion.sheltered == 0:
		lines.append("За сім ночей я не відчинив жодному з них. Село спокійне, і я разом із ним. Тільки сни стали коротші.")

	# The craft axis, read here and nowhere else — the player never sees a
	# number for it, only this one line at the end (see PathBalance).
	var leaning := PathBalance.leaning()
	if leaning == PathBalance.Leaning.DARK:
		lines.append("Я брав плату з тих, кому платити було нічим. Казав собі, що ремесло теж їсти хоче. Це теж пам'ятають.")
	elif leaning == PathBalance.Leaning.LIGHT:
		lines.append("Я не взяв нічого з тих, хто не мав. Скриня від того не повнішає, зате й дивитися людям в очі легше.")

	if StoryFlags.has_flag(&"let_lisovyk_mislead"):
		lines.append("Я дозволив лісовикові поводити їх стежками. Вони вернулися вранці й розказали всім, що в лісі щось є. Тепер уже не поодинці ходять.")

	if StoryFlags.has_flag(&"named_name_to_mara"):
		lines.append("Я назвав мару ім'я. Своє не назвав — назвав чуже, і то за одну ніч без задухи. Дешево ж воно вийшло.")

	if StoryFlags.has_flag(&"likho_confronted"):
		lines.append("Лихо так і не відчепилося остаточно. Воно вміє чекати довше за людину.")

	lines.append("Обходи хат почалися наступного тижня. Спершу в долині, потім вище.")
	return lines

## Someone else's hand, later, about him. Explains nothing.
func _found_note_lines() -> Array[String]:
	return [
		"На третю неділю посту я піднявся до хати на горі.",
		"Двері стояли відчинені. У казані — холодна вода, дрова складені рівно, наче %s збирався вертатися того ж вечора." % Molfar.NAME,
		"Записів його я не спалив.",
	]

func _footer_lines() -> Array[String]:
	return [
		"Демо-версія. Дякуємо, що пограли.",
		"Повна версія — про того, хто прийшов після нього.",
	]

func _add_text(text: String, font_size: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = align
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_constant_override(&"line_spacing", 4)
	label.modulate.a = 0.0
	chronicle.add_child(label)
	_blocks.append(label)

func _add_rule() -> void:
	var rule := ColorRect.new()
	rule.color = RULE_COLOR
	rule.custom_minimum_size = Vector2(0, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule.modulate.a = 0.0
	chronicle.add_child(rule)
	_blocks.append(rule)

## Staggered fade rather than a typewriter: these are separate diary
## entries, not one speech, and a per-block fade is what lets the closing
## block be visually a different hand (see FOUND_NOTE_COLOR).
##
## The first block starts already visible: fading in from nothing, on a
## backdrop this dark, means the screen is genuinely blank for the first
## second of what is supposed to be the chapter's last beat.
func _start_reveal() -> void:
	if _blocks.is_empty():
		_finish_reveal()
		return
	_blocks[0].modulate.a = 1.0
	skip_hint.modulate.a = 1.0
	_revealing = true
	_reveal_tween = create_tween()
	for i in range(1, _blocks.size()):
		_reveal_tween.tween_property(_blocks[i], "modulate:a", 1.0, LINE_FADE_SECONDS)
		_reveal_tween.tween_interval(LINE_DELAY_SECONDS)
	_reveal_tween.tween_property(menu_button, "modulate:a", 1.0, LINE_FADE_SECONDS)
	_reveal_tween.finished.connect(_finish_reveal)

## Anywhere, any button, any key — the whole chronicle can be several
## screens of slow fades, and a player on a second playthrough shouldn't
## have to sit through it. _input rather than _gui_input because the
## ScrollContainer over most of the screen would otherwise eat the click.
func _input(event: InputEvent) -> void:
	if not _revealing:
		return
	var clicked: bool = event is InputEventMouseButton and (event as InputEventMouseButton).pressed
	if clicked or event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"ui_cancel"):
		if _reveal_tween != null:
			_reveal_tween.kill()
		for block in _blocks:
			block.modulate.a = 1.0
		_finish_reveal()
		get_viewport().set_input_as_handled()

func _finish_reveal() -> void:
	_revealing = false
	skip_hint.visible = false
	menu_button.modulate.a = 1.0
	# Deliberately not enabled on the same frame — see BUTTON_GRACE_SECONDS.
	await get_tree().create_timer(BUTTON_GRACE_SECONDS).timeout
	menu_button.disabled = false

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)
