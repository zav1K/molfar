extends Node
## Dev probe: walks a visitor with no portrait through knock → threshold
## → invited → waiting → reception, and fails if any step leaves nothing
## for the player to click.
##
## Лихо is the one visitor in the game with no art, and played as a dead
## end because of it: the figure in the hut is what you click to get on
## with someone, a missing portrait drew no figure, and the status bar at
## the top is a Button that reads as a label. Checked against a visitor
## who does have art, so a fix that quietly breaks the normal path shows
## up here too.
##
## PROBE_VISITOR overrides which visitor is walked.

const NO_ART := "res://data/visitors/special/likho_confrontation.tres"
const WITH_ART := "res://data/visitors/special/mavka_night1.tres"

func _ready() -> void:
	var hut: Node = load("res://scenes/Hut.tscn").instantiate()
	get_tree().root.add_child.call_deferred(hut)
	await get_tree().process_frame
	await get_tree().process_frame
	var failures := 0
	var only: String = OS.get_environment("PROBE_VISITOR")
	for path in ([only] if only != "" else [NO_ART, WITH_ART]):
		failures += await _walk(hut, load(path))
	print("\nглухих кутів: %d" % failures)
	if failures > 0:
		push_error("[likho probe] %d step(s) leave nothing to click" % failures)
	get_tree().quit()

func _walk(hut, visitor: Visitor) -> int:
	var failures := 0
	var has_art: bool = visitor.get_waiting_portrait() != null
	print("\n════ %s (арт: %s)" % [visitor.display_name, "є" if has_art else "нема"])

	# Opened directly: door._on_activated depends on camera and panel
	# state this probe does not set up, and the door is not under test.
	hut.door.current_visitor = visitor
	hut.threshold_dialogue.show_visitor(visitor)
	await get_tree().process_frame
	var door = hut.threshold_dialogue
	var door_ok: bool = door.visible and door.invite_button.visible \
		and not door.invite_button.disabled \
		and (door.portrait_icon.visible or door.portrait_box._silhouette)
	failures += _say("поріг: є кого впустити і на що дивитись", door_ok)

	door._resolve(true)
	await get_tree().process_frame
	await get_tree().process_frame
	var figure = hut.waiting_visitor_display
	var figure_ok: bool = figure.visible \
		and figure.mouse_filter == Control.MOUSE_FILTER_STOP \
		and (figure.icon.visible or figure._silhouette)
	failures += _say("у хаті: фігура стоїть і її можна натиснути", figure_ok)
	failures += _say("у хаті: верхня кнопка теж жива",
		hut.waiting_indicator.visible and not hut.waiting_indicator.disabled)

	hut._on_waiting_indicator_pressed()
	await get_tree().process_frame
	failures += _say("розмова відкрилась", hut.reception_ui.visible)
	hut.reception_ui.visible = false
	hut._waiting_visitor = null
	return failures

func _say(what: String, ok: bool) -> int:
	print("   %s  %s" % ["ok " if ok else "ЗЛАМАНО", what])
	return 0 if ok else 1
