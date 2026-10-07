class_name SettingsPanel
extends CanvasLayer
## The screen behind the "Налаштування" button, which was disabled right
## up until there was something real for it to change. Instanced in both
## MainMenu and PauseMenu, so the same panel serves before and during a
## playthrough.
##
## Volume lives on the audio buses (see AudioDirector), which persist to
## user://settings.cfg — deliberately NOT part of the save file, since
## deleting a playthrough or starting a new game must not reset someone's
## volume.

signal closed

const BUS_ROWS := [
	{bus = &"Master", label = "Загальна"},
	{bus = &"Ambience", label = "Атмосфера"},
	{bus = &"SFX", label = "Звуки"},
	{bus = &"Music", label = "Музика"},
]

@onready var rows: VBoxContainer = $Shade/Panel/Rows
@onready var fullscreen_check: CheckBox = $Shade/Panel/Rows/Fullscreen
@onready var close_button: Button = $Shade/Panel/Rows/Close

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # usable from the pause menu
	visible = false
	_build_sliders()
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	close_button.pressed.connect(close)

## Built in code rather than laid out in the scene so the bus list above
## stays the single place a bus is named.
func _build_sliders() -> void:
	for i in BUS_ROWS.size():
		var entry: Dictionary = BUS_ROWS[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 12)

		var label := Label.new()
		label.text = entry.label
		label.custom_minimum_size = Vector2(110, 0)
		label.add_theme_font_size_override(&"font_size", 14)
		row.add_child(label)

		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.custom_minimum_size = Vector2(200, 0)
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slider.value = AudioDirector.get_bus_volume(entry.bus)
		var bus: StringName = entry.bus
		slider.value_changed.connect(func(v: float) -> void: AudioDirector.set_bus_volume(bus, v))
		row.add_child(slider)

		rows.add_child(row)
		# After the title, before the fullscreen toggle and Back.
		rows.move_child(row, i + 1)

func open() -> void:
	# Re-read on every open: the volume may have been changed from the
	# other copy of this panel (menu vs pause) since this one was built.
	var index := 0
	for child in rows.get_children():
		if child is HBoxContainer and index < BUS_ROWS.size():
			var slider := (child as HBoxContainer).get_child(1) as HSlider
			slider.set_value_no_signal(AudioDirector.get_bus_volume(BUS_ROWS[index].bus))
			index += 1
	visible = true
	close_button.grab_focus()

func close() -> void:
	visible = false
	closed.emit()

func _on_fullscreen_toggled(on: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
