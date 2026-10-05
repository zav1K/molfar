class_name MainMenu
extends Control
## Title screen. Background is a stand-in — PanelCenter's hut art,
## darkened — rather than its own piece, so the menu looks like the game
## it opens instead of a flat placeholder colour, without needing new art.
##
## Save/Load/Settings are deliberately disabled, not fake: there is no
## save system yet (nothing in the game serializes PlayerInventory,
## StoryFlags, hut.gd's _story_day...). A button that looks live and does
## nothing is worse than one that plainly says "not yet" — re-enable each
## in _ready() once the thing behind it exists.

const HUT_SCENE := "res://scenes/Hut.tscn"

@onready var new_game_button: Button = $Panel/Buttons/NewGame
@onready var save_button: Button = $Panel/Buttons/Save
@onready var load_button: Button = $Panel/Buttons/Load
@onready var settings_button: Button = $Panel/Buttons/Settings
@onready var quit_button: Button = $Panel/Buttons/Quit

func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	save_button.disabled = true
	load_button.disabled = true
	settings_button.disabled = true
	new_game_button.grab_focus()

func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file(HUT_SCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()
