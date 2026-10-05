extends Node
## Autoload. Autosave only — there is no manual save, by design: the game
## writes one slot at every day/night flip (hut.gd calls save() from
## _advance_visitor_slot), and the menu's "Продовжити" reads it back.
## A knock already in progress is deliberately not part of the snapshot —
## the flip is the one moment where the visitor queue is between people
## and every slot counter is at a known-clean value, so the rest of
## hut.gd's state rebuilds from _story_day and the calendar phase alone.
##
## Not saved, knowingly: CarvedSigilRegistry's traced strokes. Sigil
## COUNTS live in PlayerInventory and survive fine — only each carving's
## own hand-drawn stroke art is lost, and the give-list already falls
## back to a generic icon when an instance has no stroke (see
## ReceptionUI._rebuild_item_list), so a loaded game degrades to plain
## icons rather than breaking.

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1

## Set by the menu before switching to Hut.tscn, read once by hut.gd's
## _ready(): true means "restore the snapshot", false means "fresh game".
var pending_load: bool = false

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save(story_day: int) -> void:
	var data := {
		version = SAVE_VERSION,
		story_day = story_day,
		calendar = GameCalendar.save_state(),
		inventory = PlayerInventory.save_state(),
		flags = StoryFlags.save_state(),
		path_balance = PathBalance.save_state(),
		wards = WardRack.save_state(),
		garden = GardenState.save_state(),
		visitor_cycles = VisitorDatabase.save_state(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("SaveGame: cannot write %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

## Returns the saved story_day, or 0 if there was nothing usable to load
## — caller treats 0 as "start a fresh game instead".
func load_game() -> int:
	if not has_save():
		return 0
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("SaveGame: cannot read %s" % SAVE_PATH)
		return 0
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveGame: %s is not valid save data" % SAVE_PATH)
		return 0
	var data: Dictionary = parsed
	if int(data.get("version", 0)) != SAVE_VERSION:
		# Older/newer layout — refuse rather than half-restore into a
		# shape this build doesn't understand.
		push_warning("SaveGame: unsupported save version, ignoring")
		return 0
	GameCalendar.load_state(data.get("calendar", {}))
	PlayerInventory.load_state(data.get("inventory", {}))
	StoryFlags.load_state(data.get("flags", []))
	PathBalance.load_state(int(data.get("path_balance", 0)))
	WardRack.load_state(data.get("wards", []))
	GardenState.load_state(data.get("garden", []))
	VisitorDatabase.load_state(data.get("visitor_cycles", {}))
	return int(data.get("story_day", 1))

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
