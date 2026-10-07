extends Node
## Dev tool: measures where the painted figure actually sits inside each
## portrait PNG and prints the .tres lines for it.
##
## These portraits carry a faint alpha haze across nearly the whole
## canvas, so Image.get_used_rect() is useless here — it counts any
## nonzero alpha as content and trims almost nothing (see Visitor's
## waiting_portrait_content_rect). This thresholds instead. At alpha 16
## it reproduces all 69 of the hand-measured rects exactly, which is how
## the threshold was chosen.
##
## Run it after dropping in new art. It only reports; nothing is written,
## so the numbers go into the .tres by hand and stay reviewable.
##
## Watch for the second-pose trap. get_door_content_rect() falls back to
## the waiting rect while a visitor has one picture, which is correct —
## but the moment portrait_waiting becomes a DIFFERENT image, the door
## needs its own door_portrait_content_rect or it will be framed by the
## other pose's measurements. This flags exactly that.
##
## PORTRAIT_ALPHA overrides the threshold (0-255).

const DEFAULT_ALPHA := 16
const TOLERANCE := 0.01 ## a stored rect this close counts as agreeing.
const UNSET := Rect2(0, 0, 1, 1)

func _ready() -> void:
	var threshold := DEFAULT_ALPHA
	if OS.get_environment("PORTRAIT_ALPHA") != "":
		threshold = int(OS.get_environment("PORTRAIT_ALPHA"))
	print("поріг альфи: %d\n" % threshold)
	var agree := 0
	var todo := 0
	var missing := 0
	for path in _all("res://data/visitors/"):
		var v = load(path)
		if v == null or not (v is Visitor):
			continue
		var door: Texture2D = v.portrait_door
		var waiting: Texture2D = v.portrait_waiting
		if door == null and waiting == null:
			missing += 1
			print("— %s\n   портрета нема взагалі (малюється силует)\n   %s" % [v.display_name, path])
			continue

		var lines: Array[String] = []
		# Two different pictures: each needs its own measurement, and the
		# door's own field must be set or it inherits the other pose's.
		var two_poses: bool = waiting != null and waiting != door
		if two_poses:
			var want_waiting := _measure(waiting, threshold)
			if not _close(want_waiting, v.waiting_portrait_content_rect):
				lines.append(_line("waiting_portrait_content_rect", want_waiting))
			if door != null:
				var want_door := _measure(door, threshold)
				if v.door_portrait_content_rect == UNSET:
					lines.append("# двері досі міряються позою очікування — дописати:")
					lines.append(_line("door_portrait_content_rect", want_door))
				elif not _close(want_door, v.door_portrait_content_rect):
					lines.append(_line("door_portrait_content_rect", want_door))
		else:
			var want := _measure(v.get_waiting_portrait(), threshold)
			if not _close(want, v.waiting_portrait_content_rect):
				lines.append(_line("waiting_portrait_content_rect", want))

		if lines.is_empty():
			agree += 1
			continue
		todo += 1
		print("— %s%s\n   %s" % [v.display_name, "  (дві пози)" if two_poses else "", path])
		for line in lines:
			print("   %s" % line)

	print("\nзбігається: %d   треба поправити: %d   без портрета: %d" % [agree, todo, missing])
	get_tree().quit()

func _line(field: String, r: Rect2) -> String:
	return "%s = Rect2(%f, %f, %f, %f)" % [field, r.position.x, r.position.y, r.size.x, r.size.y]

func _close(a: Rect2, b: Rect2) -> bool:
	return maxf(
		maxf(absf(a.position.x - b.position.x), absf(a.position.y - b.position.y)),
		maxf(absf(a.size.x - b.size.x), absf(a.size.y - b.size.y))) <= TOLERANCE

## Normalized bounding box of everything at or above the alpha threshold.
func _measure(tex: Texture2D, threshold: int) -> Rect2:
	var image := tex.get_image()
	if image.is_compressed():
		image.decompress()
	var w := image.get_width()
	var h := image.get_height()
	var min_x := w
	var min_y := h
	var max_x := -1
	var max_y := -1
	for y in h:
		for x in w:
			if image.get_pixel(x, y).a8 < threshold:
				continue
			if x < min_x: min_x = x
			if x > max_x: max_x = x
			if y < min_y: min_y = y
			if y > max_y: max_y = y
	if max_x < 0:
		return UNSET
	return Rect2(float(min_x) / w, float(min_y) / h,
		float(max_x - min_x + 1) / w, float(max_y - min_y + 1) / h)

func _all(d: String) -> Array:
	var out := []
	for f in DirAccess.get_files_at(d):
		if f.ends_with(".tres"): out.append(d + f)
	for sub in DirAccess.get_directories_at(d):
		out.append_array(_all(d + sub + "/"))
	return out
