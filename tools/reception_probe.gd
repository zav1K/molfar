extends Node
## Dev probe: drives ReceptionUI down each of its resolution paths —
## reply, give, take, listen — and prints whether the visitor's closing
## text actually ended up on screen.
##
## Scene-based rather than `--script`, because autoloads only exist under
## a real main loop and ReceptionUI reaches for several of them.
##
## Exists because the result text was invisible for weeks without anyone
## noticing from the code: the node was a RichTextLabel with fit_content
## off, so its height was 0 and it rendered nothing while every string
## and flag behind it stayed perfectly correct. Printing the text that
## _resolve() set would not have caught it, so this reports the measured
## height as well, against ProblemLabel as a known-good control.

const CASES := [
	"res://data/visitors/upyr_hidden_female.tres", # replies
	"res://data/visitors/special/priest_day7.tres", # replies, one gated
	"res://data/visitors/coughing_child_mother.tres", # give a potion
	"res://data/visitors/found_doll.tres", # take an offered item
	"res://data/visitors/mara_night.tres", # plain listen
]

## RichTextLabel needs a couple of layout passes before it reports a
## content height at all.
const SETTLE_FRAMES := 4

func _ready() -> void:
	var hut: Node = load("res://scenes/Hut.tscn").instantiate()
	get_tree().root.add_child.call_deferred(hut)
	await get_tree().process_frame
	await get_tree().process_frame
	var ui = hut.reception_ui
	var failures := 0
	for path in CASES:
		var visitor: Visitor = load(path)
		ui.show_visitor(visitor)
		await get_tree().process_frame
		var how := _resolve_somehow(ui, visitor)
		for _i in SETTLE_FRAMES:
			await get_tree().process_frame
		var result = ui.result_label
		var height: int = result.label.get_content_height()
		var ok: bool = not String(result._full_text).is_empty() and height > 0
		if not ok:
			failures += 1
		print("%s  %s (%s)" % ["ok  " if ok else "ЗЛАМАНО", visitor.display_name, how])
		print("    текст: %s" % JSON.stringify(result._full_text.substr(0, 50)))
		print("    висота %d px, контрольна (ProblemLabel) %d px" % [
			height, ui.problem_label.label.get_content_height()])
	print("\nзламаних шляхів: %d з %d" % [failures, CASES.size()])
	if failures > 0:
		push_error("[reception probe] %d resolution path(s) render no text" % failures)
	get_tree().quit()

## Takes whichever exit this visitor actually offers, so the probe covers
## the branch that visitor represents rather than one fixed button.
func _resolve_somehow(ui, visitor: Visitor) -> String:
	var replies: Array = ui._available_replies()
	if not replies.is_empty():
		ui._on_reply_pressed(replies[0])
		return "репліка"
	if visitor.offers_item_id != &"":
		ui._on_take_pressed()
		return "взяти"
	if visitor.desired_result_id != &"":
		PlayerInventory.add(visitor.desired_result_id, 1)
		ui._on_give_pressed(visitor.desired_result_id)
		return "дати відвар"
	ui._on_listen_pressed()
	return "вислухати"
