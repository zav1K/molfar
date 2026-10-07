extends Node
## Dev tool: pulls every line of visitor dialogue into one editable file
## and puts it back again.
##
## The texts live across ~70 .tres resources, one or two speeches each,
## so rewriting the chapter's voice means opening seventy files and never
## seeing two characters side by side. This makes the whole script one
## document and the edit one pass.
##
## DIALOGUE_MODE picks what it does:
##   export (default) — writes dialogue.md from the resources
##   import           — reads dialogue.md back into the resources
##   verify           — round-trips in memory and reports any loss,
##                      touching nothing on disk
##
## Import patches the .tres as TEXT rather than re-saving the resource.
## ResourceSaver.save() would rewrite each file wholesale — reordering
## properties, renumbering sub-resources and dropping anything it does
## not model — which turns a two-word fix into an unreadable diff. This
## replaces the one line that changed and leaves the file otherwise
## byte-identical.
##
## The delimiters (===, @, #) were checked against all 420 existing text
## fields before being chosen; none of them starts a line with any of
## these. Export re-checks that every time and refuses to write a file it
## could not read back.

const OUT_PATH := "res://dialogue.md"

## Plain fields on Visitor, in the order they are written out.
const FIELDS := [
	"display_name",
	"problem_text",
	"satisfied_text",
	"unhelped_text",
	"payment_flavor_text",
	"invited_flavor_text",
	"choice_prompt",
	"choice_a_label",
	"choice_a_response",
	"choice_b_label",
	"choice_b_response",
]

const HEADER := """# Репліки «Молфара» — усі тексти відвідувачів в одному файлі.
#
# Правити можна ТІЛЬКИ текст під заголовками «@поле».
# Рядки «=== шлях», «@поле» і «#» — службові, їх не чіпати й не додавати.
# Порожній рядок усередині репліки зберігається; порожні в кінці — ні.
#
# Згенеровано: tools/DialogueIO.tscn (DIALOGUE_MODE=export)
# Розкласти назад:                   DIALOGUE_MODE=import
"""

func _ready() -> void:
	var mode := OS.get_environment("DIALOGUE_MODE")
	if mode == "":
		mode = "export"
	match mode:
		"export": _export()
		"import": _import()
		"verify": _verify()
		_:
			push_error("[dialogue] невідомий DIALOGUE_MODE: %s" % mode)
	get_tree().quit()

# --- export ---------------------------------------------------------

func _export() -> void:
	var text := _compose()
	var unreadable := _collisions(text)
	if not unreadable.is_empty():
		for line in unreadable:
			push_error("[dialogue] текст починається зі службового символу: %s" % line)
		push_error("[dialogue] експорт скасовано — такий файл не прочитається назад")
		return
	var file := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[dialogue] не вдалося записати %s" % OUT_PATH)
		return
	file.store_string(text)
	file.close()
	print("записано %s" % ProjectSettings.globalize_path(OUT_PATH))
	print("відвідувачів: %d, полів: %d" % [_paths().size(), _count_fields(text)])

func _compose() -> String:
	var out := HEADER
	for path in _paths():
		var v = load(path)
		if v == null or not (v is Visitor):
			continue
		out += "\n\n=== %s\n" % path
		out += "# %s%s\n" % [v.display_name, "  — ніч" if v.night_visitor else "  — день"]
		for field in FIELDS:
			var value := String(v.get(field))
			if value.is_empty():
				continue
			out += "\n@%s\n%s\n" % [field, value]
		for i in v.replies.size():
			var reply: VisitorReply = v.replies[i]
			if reply == null:
				continue
			out += "\n@reply%d.label\n%s\n" % [i, reply.label]
			out += "\n@reply%d.response\n%s\n" % [i, reply.response]
	return out

# --- import ---------------------------------------------------------

func _import() -> void:
	if not FileAccess.file_exists(OUT_PATH):
		push_error("[dialogue] нема %s — спершу зроби export" % OUT_PATH)
		return
	var blocks := _parse(FileAccess.get_file_as_string(OUT_PATH))
	if blocks.is_empty():
		push_error("[dialogue] у файлі не знайдено жодного блоку «=== шлях»")
		return
	var changed := 0
	var untouched := 0
	var failed := 0
	for path in blocks:
		var result := _apply(path, blocks[path])
		match result:
			"changed": changed += 1
			"same": untouched += 1
			_:
				failed += 1
				push_error("[dialogue] %s: %s" % [path, result])
	print("змінено: %d   без змін: %d   помилок: %d" % [changed, untouched, failed])
	if failed == 0:
		print("перевір `git diff data/visitors` — має бути видно тільки правлені рядки")

## path -> {field -> text}
func _parse(text: String) -> Dictionary:
	var blocks := {}
	var path := ""
	var field := ""
	var body: Array[String] = []
	var fields := {}
	for raw in text.split("\n"):
		var line: String = raw
		if line.begins_with("=== "):
			_stash(fields, field, body)
			if path != "":
				blocks[path] = fields
			path = line.substr(4).strip_edges()
			fields = {}
			field = ""
			body = []
			continue
		if line.begins_with("@"):
			_stash(fields, field, body)
			field = line.substr(1).strip_edges()
			body = []
			continue
		# A '#' is a comment only outside a field body, so a future line
		# of dialogue that happens to start with one still survives.
		if field == "" and line.begins_with("#"):
			continue
		if field == "" and line.strip_edges().is_empty():
			continue
		body.append(line)
	_stash(fields, field, body)
	if path != "":
		blocks[path] = fields
	return blocks

func _stash(fields: Dictionary, field: String, body: Array[String]) -> void:
	if field == "":
		return
	while not body.is_empty() and body[body.size() - 1].strip_edges().is_empty():
		body.remove_at(body.size() - 1)
	fields[field] = "\n".join(body)

## Rewrites just the changed lines of one .tres. Returns "changed",
## "same", or a message.
func _apply(path: String, fields: Dictionary) -> String:
	if not ResourceLoader.exists(path):
		return "такого ресурсу нема"
	var original := FileAccess.get_file_as_string(path)
	if original.is_empty():
		return "не вдалося прочитати файл"
	var reply_ids := _reply_ids(original)
	var text := original
	for key in fields:
		var field := String(key)
		var value: String = fields[key]
		if field.begins_with("reply"):
			var dot: int = field.find(".")
			if dot < 0:
				return "зіпсований ключ %s" % field
			var index := int(field.substr(5, dot - 5))
			if index >= reply_ids.size():
				return "репліки %d нема в ресурсі" % index
			text = _set_field(text, reply_ids[index], String(field).substr(dot + 1), value)
		elif field in FIELDS:
			text = _set_field(text, "resource", String(field), value)
		else:
			return "невідоме поле %s" % field
	if text == original:
		return "same"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return "не вдалося записати"
	file.store_string(text)
	file.close()
	return "changed"

## SubResource ids in the order the replies array holds them.
func _reply_ids(text: String) -> Array[String]:
	var ids: Array[String] = []
	var regex := RegEx.new()
	regex.compile('replies\\s*=\\s*Array\\[Resource\\]\\(\\[(.*)\\]\\)')
	var found := regex.search(text)
	if found == null:
		return ids
	var inner := RegEx.new()
	inner.compile('SubResource\\("([^"]+)"\\)')
	for m in inner.search_all(found.get_string(1)):
		ids.append(m.get_string(1))
	return ids

## Replaces `field = "..."` inside the given section, adding the line at
## the end of that section if it isn't there yet. Not named _set: that is
## Object's own virtual, and overriding it with a different signature is
## a parse error.
func _set_field(text: String, section: String, field: String, value: String) -> String:
	var lines := Array(text.split("\n"))
	var current := ""
	var section_end := -1
	for i in lines.size():
		var line: String = lines[i]
		if line.begins_with("["):
			if current == section:
				section_end = i
				break
			current = _section_id(line)
			continue
		if current == section and line.begins_with(field + " = "):
			lines[i] = "%s = \"%s\"" % [field, _escape(value)]
			return "\n".join(lines)
	if current == section and section_end < 0:
		section_end = lines.size()
	if section_end < 0:
		return text
	# Back up over the blank lines that sit between sections, so the new
	# line joins the block it belongs to rather than floating after it.
	while section_end > 0 and lines[section_end - 1].strip_edges().is_empty():
		section_end -= 1
	lines.insert(section_end, "%s = \"%s\"" % [field, _escape(value)])
	return "\n".join(lines)

func _section_id(header: String) -> String:
	if header.begins_with("[resource]"):
		return "resource"
	if not header.begins_with("[sub_resource"):
		return ""
	var regex := RegEx.new()
	regex.compile('id="([^"]+)"')
	var found := regex.search(header)
	return found.get_string(1) if found != null else ""

func _escape(value: String) -> String:
	return value.replace("\\", "\\\\").replace("\"", "\\\"") \
		.replace("\n", "\\n").replace("\t", "\\t")

# --- verify ---------------------------------------------------------

## Composes the file and parses it straight back, comparing every field
## against the live resource. Catches a format that cannot survive its
## own round trip without writing anything.
func _verify() -> void:
	var blocks := _parse(_compose())
	var checked := 0
	var lost := 0
	for path in _paths():
		var v = load(path)
		if v == null or not (v is Visitor):
			continue
		if not blocks.has(path):
			lost += 1
			push_error("[dialogue] блок зник: %s" % path)
			continue
		var fields: Dictionary = blocks[path]
		for field in FIELDS:
			var want := String(v.get(field))
			if want.is_empty():
				continue
			checked += 1
			if String(fields.get(field, "")) != want:
				lost += 1
				print("РОЗБІЖНІСТЬ %s %s\n  було:  %s\n  стало: %s" % [
					v.display_name, field, JSON.stringify(want.substr(0, 60)),
					JSON.stringify(String(fields.get(field, "")).substr(0, 60))])
		for i in v.replies.size():
			var reply: VisitorReply = v.replies[i]
			if reply == null:
				continue
			for part in [["label", reply.label], ["response", reply.response]]:
				checked += 1
				var key := "reply%d.%s" % [i, part[0]]
				if String(fields.get(key, "")) != String(part[1]):
					lost += 1
					print("РОЗБІЖНІСТЬ %s %s" % [v.display_name, key])
	print("перевірено полів: %d   втрачено: %d" % [checked, lost])
	if lost > 0:
		push_error("[dialogue] круговий обхід втрачає дані")

# --- shared ---------------------------------------------------------

func _collisions(text: String) -> Array[String]:
	var out: Array[String] = []
	var in_body := false
	for raw in text.split("\n"):
		var line: String = raw
		if line.begins_with("=== ") or line.begins_with("@"):
			in_body = line.begins_with("@")
			continue
		if in_body and (line.begins_with("===") or line.begins_with("@") or line.begins_with("#")):
			out.append(line.substr(0, 50))
	return out

func _count_fields(text: String) -> int:
	var n := 0
	for line in text.split("\n"):
		if String(line).begins_with("@"):
			n += 1
	return n

func _paths() -> Array:
	return _all("res://data/visitors/")

func _all(d: String) -> Array:
	var out := []
	for f in DirAccess.get_files_at(d):
		if f.ends_with(".tres"):
			out.append(d + f)
	out.sort()
	for sub in DirAccess.get_directories_at(d):
		out.append_array(_all(d + sub + "/"))
	return out
