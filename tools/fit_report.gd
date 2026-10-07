extends Node
## Dev report: where every waiting-visitor portrait lands in its box,
## using the same arithmetic as WaitingVisitorDisplay.show_visitor.
const BOX := Vector2(172.0, 314.0)

func _ready() -> void:
	var rows := []
	for path in _all("res://data/visitors/"):
		var v = load(path)
		if v == null or not (v is Visitor): continue
		var tex: Texture2D = v.get_waiting_portrait()
		if tex == null: continue
		var r: Rect2 = v.waiting_portrait_content_rect
		var ts := Vector2(tex.get_width(), tex.get_height())
		var cw: float = r.size.x * ts.x
		var chr: float = r.size.y * ts.y
		var s: float = minf(maxf(
			(BOX.x * WaitingVisitorDisplay.WIDTH_FILL) / cw,
			(BOX.y * WaitingVisitorDisplay.MIN_HEIGHT_OVERFLOW) / chr),
			(BOX.x * WaitingVisitorDisplay.MAX_WIDTH_FRACTION) / cw)
		s *= v.figure_height_scale
		var top: float = maxf(0.0, BOX.y + BOX.y * (WaitingVisitorDisplay.MIN_HEIGHT_OVERFLOW - 1.0) - chr * s)
		var vis: float = (BOX.y - top) / (chr * s) * 100.0
		rows.append([top, vis, (cw * s) / BOX.x * 100.0, v.figure_height_scale, v.display_name])
	rows.sort_custom(func(a, b): return a[0] > b[0])
	var seen := {}
	print("  верх видно%  шир%  масшт  хто")
	for x in rows:
		if seen.has(x[4]): continue
		seen[x[4]] = true
		print("%6.1f %6.0f %5.0f %6.2f  %s" % x)
	get_tree().quit()

func _all(d: String) -> Array:
	var out := []
	for f in DirAccess.get_files_at(d):
		if f.ends_with(".tres"): out.append(d + f)
	for sub in DirAccess.get_directories_at(d):
		out.append_array(_all(d + sub + "/"))
	return out
