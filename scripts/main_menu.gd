class_name MainMenu
extends Control
## Title screen. Background is a stand-in — PanelCenter's hut art,
## darkened — rather than its own piece, so the menu looks like the game
## it opens instead of a flat placeholder colour, without needing new art.
##
## There is no "Зберегти" button by design, and no save slots: saving is
## automatic and single-slot (see SaveGame), written at every day/night
## flip, so the only save-related thing a player ever needs here is
## "Продовжити". It's disabled, not hidden, when no save file exists —
## a missing button is more confusing than a greyed-out one that says
## what it would do.
##
## Налаштування is still disabled because there is nothing behind it yet
## (no volume, no resolution, no language options exist to settle). A
## button that looks live and does nothing is worse than one that plainly
## says "not yet" — re-enable it in _ready() once that screen exists.

const HUT_SCENE := "res://scenes/Hut.tscn"
const CHAPTER_END_SCENE := "res://scenes/ChapterEnd.tscn"

@onready var continue_button: Button = $Panel/Buttons/Continue
@onready var new_game_button: Button = $Panel/Buttons/NewGame
@onready var continue_hint: Label = $Panel/Buttons/ContinueHint
@onready var settings_button: Button = $Panel/Buttons/Settings
@onready var quit_button: Button = $Panel/Buttons/Quit

func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	settings_button.disabled = true

	var has_save := SaveGame.has_save()
	continue_button.disabled = not has_save
	continue_hint.visible = not has_save
	if has_save and SaveGame.peek_chapter_complete():
		# "Продовжити" would be a lie — there's nothing left to play on a
		# finished save, it only reopens the chronicle.
		continue_button.text = "Прочитати хроніку"
	if has_save:
		continue_button.grab_focus()
	else:
		new_game_button.grab_focus()

func _on_continue_pressed() -> void:
	# The receiving scene's _ready() reads this once and pulls the
	# snapshot in itself — the actual load can't happen here, because
	# half of what's restored (the visitor slot counters, the forced-beat
	# bookkeeping) lives on the Hut scene that doesn't exist yet at this
	# point. A finished save has no day left to play, so it goes to the
	# chronicle instead; see SaveGame.save's chapter_complete.
	SaveGame.pending_load = true
	var target := CHAPTER_END_SCENE if SaveGame.peek_chapter_complete() else HUT_SCENE
	get_tree().change_scene_to_file(target)

func _on_new_game_pressed() -> void:
	# Deliberately does NOT wipe the existing save: the next day/night
	# flip overwrites it anyway, and a player who hits "Нова гра" by
	# mistake can still back out to the menu before that first flip.
	SaveGame.pending_load = false
	get_tree().change_scene_to_file(HUT_SCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()
