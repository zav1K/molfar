class_name CarvingUI
extends CanvasLayer
## Carving interface: pick a known sigil from the list, then draw it from
## memory in CarvingCanvas — no guide is shown there anymore, only the
## reference book here (book_grid) with every known sigil's clean shape,
## so the player can look one up without it being handed to them stroke
## by stroke. No ingredient cost — carving is a pure skill loop, so
## failed attempts are free to retry, same reasoning as why picking the
## wrong brewing combo costs nothing. A successful attempt adds the
## carved sigil (ward or curse) to the player's inventory.
##
## Pass/fail only, no quality tiers: with the on-canvas guide gone, even
## a correctly-remembered shape won't land pixel-perfect the way tracing
## it did, so grading it into "weak/normal/good" bands read as noise
## rather than a meaningful signal. PASS_ERROR is deliberately looser
## than the old tracing thresholds for the same reason.

const PASS_ERROR := 30.0
const PATTERN_ICON_SIZE := Vector2(72, 72)
const BOOK_TILE_WIDTH := 96.0

signal closed

@onready var sigil_list: VBoxContainer = $Panel/SigilList
@onready var book_grid: GridContainer = $Panel/Book/BookGrid
@onready var status_label: Label = $Panel/StatusLabel
@onready var back_button: Button = $Panel/BackButton
@onready var cancel_button: Button = $Panel/CancelButton
@onready var carving_canvas: CarvingCanvas = $Panel/CarvingCanvas

var _current_sigil: Sigil

func _ready() -> void:
	visible = false
	back_button.pressed.connect(_on_back_pressed)
	cancel_button.pressed.connect(_show_list_phase)
	carving_canvas.finished.connect(_on_carving_finished)
	_rebuild_book() # static per SigilDatabase's contents — built once, not per open().

func open() -> void:
	status_label.text = ""
	_show_list_phase()
	visible = true

## Every known sigil's clean template shape, independent of the list of
## what to carve next — a lookup aid, not a picker (tapping a tile does
## nothing).
func _rebuild_book() -> void:
	for child in book_grid.get_children():
		child.queue_free()
	for sigil in SigilDatabase.get_all():
		book_grid.add_child(_build_book_tile(sigil))

func _build_book_tile(sigil: Sigil) -> VBoxContainer:
	var tile := VBoxContainer.new()
	tile.custom_minimum_size.x = BOOK_TILE_WIDTH

	var icon := SigilPatternIcon.new()
	icon.custom_minimum_size = PATTERN_ICON_SIZE
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.setup(sigil)
	tile.add_child(icon)

	var label := Label.new()
	label.text = sigil.display_name
	label.custom_minimum_size.x = BOOK_TILE_WIDTH
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_font_size_override("font_size", 11)
	tile.add_child(label)

	return tile

func _rebuild_sigil_list() -> void:
	for child in sigil_list.get_children():
		child.queue_free()
	for sigil in SigilDatabase.get_all():
		sigil_list.add_child(_build_sigil_row(sigil))

func _build_sigil_row(sigil: Sigil) -> HBoxContainer:
	var row := HBoxContainer.new()

	var kind_text := "оберіг" if sigil.kind == Sigil.Kind.WARD else "клеймо"
	var name_label := Label.new()
	name_label.custom_minimum_size.x = 220
	name_label.text = "%s (%s)" % [sigil.display_name, kind_text]
	row.add_child(name_label)

	var carve_button := Button.new()
	carve_button.text = "Різьбити"
	carve_button.pressed.connect(_start_carving.bind(sigil))
	row.add_child(carve_button)

	return row

func _start_carving(sigil: Sigil) -> void:
	_current_sigil = sigil
	status_label.text = ""
	_show_carving_phase()
	carving_canvas.start(sigil)

func _on_carving_finished(avg_error: float, _coverage: float, stroke: PackedVector2Array) -> void:
	if avg_error >= PASS_ERROR:
		status_label.text = "Рука зірвалась — знак не вийшов, спробуй ще."
	else:
		PlayerInventory.add(_current_sigil.id)
		CarvedSigilRegistry.add_instance(_current_sigil.id, stroke)
		status_label.text = "Вирізьблено: %s" % _current_sigil.display_name
	_show_list_phase()

func _show_list_phase() -> void:
	sigil_list.visible = true
	back_button.visible = true
	cancel_button.visible = false
	carving_canvas.visible = false
	_rebuild_sigil_list()

func _show_carving_phase() -> void:
	sigil_list.visible = false
	back_button.visible = false
	cancel_button.visible = true
	carving_canvas.visible = true

func _on_back_pressed() -> void:
	visible = false
	closed.emit()
