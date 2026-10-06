class_name PauseMenu
extends CanvasLayer
## Esc menu for the hut. Until this existed there was no way out of the
## game at all short of killing the window — see TODO_DEMO.md.
##
## Actually pauses the tree, which is what makes leaving safe: the
## pending-knock timer hangs off get_tree().create_timer, so it stops
## with everything else instead of firing behind the menu and bringing
## someone to the door while the player is reading this. The node itself
## runs with PROCESS_MODE_ALWAYS so it stays interactive on both sides
## of that pause.
##
## Leaving for the menu is safe but not free: autosave only writes at
## day/night flips (see SaveGame), so whatever happened since the last
## flip is lost. The hint line says so rather than letting the player
## find out.

signal resumed

const MENU_SCENE := "res://scenes/MainMenu.tscn"

@onready var resume_button: Button = $Shade/Panel/Buttons/Resume
@onready var menu_button: Button = $Shade/Panel/Buttons/ToMenu
@onready var settings_button: Button = $Shade/Panel/Buttons/Settings
@onready var quit_button: Button = $Shade/Panel/Buttons/Quit
@onready var settings_panel: SettingsPanel = $SettingsPanel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(close)
	menu_button.pressed.connect(_on_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	settings_button.pressed.connect(settings_panel.open)

func open() -> void:
	visible = true
	get_tree().paused = true
	resume_button.grab_focus()

func close() -> void:
	get_tree().paused = false
	visible = false
	resumed.emit()

## Esc backs out again, same as the Resume button — the menu shouldn't be
## a one-way door. Handled here rather than in hut.gd because hut.gd
## stops receiving input the moment the tree is paused. Skipped while the
## settings panel is up, so Esc closes that first and the player doesn't
## get thrown two screens back in one press.
func _unhandled_input(event: InputEvent) -> void:
	if visible and not settings_panel.visible and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _on_menu_pressed() -> void:
	# Unpause first: the flag lives on the SceneTree, not the scene, so it
	# would otherwise carry over and leave the main menu frozen.
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()
