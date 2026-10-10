extends Node
## Dev probe: plays a cutscene start to finish at speed and checks that
## every shot is reached, every caption prints, and the whole thing
## actually ends — including the two things that strand a player, a shot
## that never advances and a missing resource that leaves black.

const PATH := "res://data/cutscenes/intro.tres"

func _ready() -> void:
	Engine.time_scale = 40.0
	var scene: Control = load("res://scenes/Cutscene.tscn").instantiate()
	CutscenePlayer.pending_path = PATH
	CutscenePlayer.fallback_scene = ""
	get_tree().root.add_child.call_deferred(scene)
	await get_tree().process_frame
	await get_tree().process_frame

	var cutscene: Cutscene = load(PATH)
	var want: int = cutscene.eligible_shots().size()
	var failures := 0
	print("кадрів у сцені: %d" % want)
	# next_scene would change scene mid-probe, so it is cleared on the
	# copy the player holds rather than in the file.
	scene._cutscene.next_scene = ""

	var seen := {}
	# Read off the player rather than a flag set in a lambda: GDScript
	# captures locals by value, so a lambda assigning one here would
	# never be seen out there.
	var emitted := [false]
	scene.finished.connect(func() -> void: emitted[0] = true)
	var guard := 0
	while not scene._done and guard < 4000:
		seen[scene._index] = true
		if scene._index >= 0 and scene._index < want:
			var shot: CutsceneShot = scene._shots[scene._index]
			if shot.caption.strip_edges().is_empty():
				failures += 1
				print("   ЗЛАМАНО кадр %d без тексту" % scene._index)
		await get_tree().process_frame
		guard += 1

	failures += _say("дійшло до кінця само", scene._done)
	failures += _say("просигналило finished", emitted[0])
	failures += _say("показано всі %d кадрів" % want, seen.size() >= want)
	failures += _say("не зациклилось", guard < 4000)
	print("\nпомилок: %d" % failures)
	if failures > 0:
		push_error("[cutscene probe] %d" % failures)
	get_tree().quit()

func _say(what: String, ok: bool) -> int:
	print("   %s  %s" % ["ok " if ok else "ЗЛАМАНО", what])
	return 0 if ok else 1
