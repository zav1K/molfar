extends Node
## Dev probe: checks each tutorial hint fires exactly once, in the place
## it belongs, and never again — including across a reload, since they
## are remembered in StoryFlags.

func _ready() -> void:
	var hut: Node = load("res://scenes/Hut.tscn").instantiate()
	get_tree().root.add_child.call_deferred(hut)
	await get_tree().process_frame
	await get_tree().process_frame
	var hints = hut.tutorial_hints
	var failures := 0

	# _ready already fired the panels hint on a fresh StoryFlags.
	failures += _say("панелі: показано при вході", StoryFlags.has_flag(&"hint_panels"))
	failures += _say("панелі: вдруге не показує",
		not hints.show_once(&"panels", "ще раз"))

	var v: Visitor = load("res://data/visitors/coughing_child_mother.tres")
	hut.threshold_dialogue.show_visitor(v)
	hints.show_once(&"refusing", "відмова")
	failures += _say("відмова: прапорець стоїть", StoryFlags.has_flag(&"hint_refusing"))

	hut._show_visitor_inside(v, false)
	await get_tree().process_frame
	failures += _say("очікування: показано, коли гість у хаті",
		StoryFlags.has_flag(&"hint_waiting"))

	hut._on_waiting_indicator_pressed()
	await get_tree().process_frame
	failures += _say("виготовлення: показано тому, хто просить річ",
		StoryFlags.has_flag(&"hint_making"))

	# A visitor who came with a question must NOT get the cauldron hint.
	StoryFlags.load_state({})
	hut.reception_ui.visible = false
	var asker: Visitor = load("res://data/visitors/special/mavka_night1.tres")
	hut._show_visitor_inside(asker, false)
	await get_tree().process_frame
	hut._on_waiting_indicator_pressed()
	await get_tree().process_frame
	failures += _say("виготовлення: НЕ показано тому, хто просить відповідь",
		not StoryFlags.has_flag(&"hint_making"))

	print("\nпомилок: %d" % failures)
	if failures > 0:
		push_error("[hints probe] %d hint(s) misbehave" % failures)
	get_tree().quit()

func _say(what: String, ok: bool) -> int:
	print("   %s  %s" % ["ok " if ok else "ЗЛАМАНО", what])
	return 0 if ok else 1
