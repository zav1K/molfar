class_name CalendarPanel
extends CanvasLayer
## Diegetic wall calendar: a 3-week grid (7×DAYS_PER_SEASON days) for the
## current season, marking festival days by name and highlighting today.
## Opened by the Calendar zone on PanelCenter — same click-to-open pattern
## as InventoryPanel.

signal closed

const COLUMNS := 7
const CELL_SIZE := Vector2(78, 84)
const TODAY_COLOR := Color(0.55, 0.42, 0.16, 0.9)
const FESTIVAL_COLOR := Color(0.4, 0.16, 0.14, 0.85)
const DEFAULT_COLOR := Color(0.16, 0.13, 0.09, 0.6)
const BORDER_COLOR := Color(0.9, 0.8, 0.5)

@onready var title_label: Label = $Panel/Title
@onready var grid: GridContainer = $Panel/Grid
@onready var close_button: Button = $Panel/CloseButton

func _ready() -> void:
	visible = false
	grid.columns = COLUMNS
	close_button.pressed.connect(_on_close_pressed)

func open() -> void:
	_rebuild()
	visible = true

func _rebuild() -> void:
	for child in grid.get_children():
		child.queue_free()

	var season := GameCalendar.get_season()
	title_label.text = "Календар — %s" % GameCalendar.SEASON_NAMES[season]

	var start_day := GameCalendar.get_season_start_day(season)
	var today_of_season := GameCalendar.get_day_of_season()
	for i in GameCalendar.DAYS_PER_SEASON:
		var day_of_season := i + 1
		var festival := GameCalendar.get_festival_on_day(start_day + i)
		grid.add_child(_build_day_cell(day_of_season, festival, day_of_season == today_of_season))

func _build_day_cell(day_of_season: int, festival: GameCalendar.Festival, is_today: bool) -> Control:
	var cell := PanelContainer.new()
	cell.custom_minimum_size = CELL_SIZE

	var style := StyleBoxFlat.new()
	style.bg_color = FESTIVAL_COLOR if festival != null else (TODAY_COLOR if is_today else DEFAULT_COLOR)
	if is_today:
		style.set_border_width_all(2)
		style.border_color = BORDER_COLOR
	cell.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	cell.add_child(box)

	var day_label := Label.new()
	day_label.text = str(day_of_season)
	day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(day_label)

	if festival != null:
		var festival_label := Label.new()
		festival_label.text = festival.display_name
		festival_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		festival_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		festival_label.add_theme_font_size_override("font_size", 11)
		box.add_child(festival_label)

	return cell

func _on_close_pressed() -> void:
	visible = false
	closed.emit()
