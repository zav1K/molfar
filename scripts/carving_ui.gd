class_name CarvingUI
extends CanvasLayer
## Carving interface: pick a known sigil from the list, then trace its
## guide path in CarvingCanvas. No ingredient cost — carving is a pure
## skill loop, so failed attempts are free to retry, same reasoning as
## why picking the wrong brewing combo costs nothing. A successful trace
## adds the carved sigil (ward or curse) to the player's inventory.

const GOOD_ERROR := 10.0
const NORMAL_ERROR := 22.0
const FAIL_ERROR := 40.0

enum Quality { WEAK, NORMAL, GOOD, FAILED }
const QUALITY_LABEL := {
	Quality.WEAK: "слабко",
	Quality.NORMAL: "непогано",
	Quality.GOOD: "чисто",
}

signal closed

@onready var sigil_list: VBoxContainer = $Panel/SigilList
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

func open() -> void:
	status_label.text = ""
	_show_list_phase()
	visible = true

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
	var quality := _resolve_quality(avg_error)
	if quality == Quality.FAILED:
		status_label.text = "Рука зірвалась — знак не вийшов, спробуй ще."
	else:
		PlayerInventory.add(_current_sigil.id)
		CarvedSigilRegistry.add_instance(_current_sigil.id, stroke)
		status_label.text = "Вирізьблено (%s): %s" % [QUALITY_LABEL[quality], _current_sigil.display_name]
	_show_list_phase()

func _resolve_quality(avg_error: float) -> Quality:
	if avg_error >= FAIL_ERROR:
		return Quality.FAILED
	if avg_error < GOOD_ERROR:
		return Quality.GOOD
	if avg_error < NORMAL_ERROR:
		return Quality.NORMAL
	return Quality.WEAK

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
