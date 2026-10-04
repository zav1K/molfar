extends Node
## Autoload. Loads every Visitor resource from data/visitors/ (and its
## special/ subfolder — scripted story beats, see below) and hands out
## random picks for the door to knock with — each one at most once per
## reset_seen() call (see that function) so the same face doesn't knock
## twice in a row. hut.gd calls reset_seen() on every day/night phase
## flip (see GameCalendar), allowing repeat visits again, per
## CONCEPT.md's "постійні клієнти" — just not within the same phase.
##
## data/visitors/special/ holds one-time story beats (gated by
## required_flag/knocked_sets_flag on Visitor) rather than ordinary
## repeating clients — kept in their own subfolder just so they're easy
## to tell apart from the regular rotation while browsing the data.
## Розділ 1's beats (see hut.gd's CHAPTER1_SCRIPT) are all loaded by
## direct `load()`/path from hut.gd instead of through get_random() —
## required_flag = &"__chapter1_scripted_only__" on every one of them
## is a deliberately-never-set sentinel keeping them out of this pool
## entirely, since direct load() doesn't check required_flag at all.

const VISITORS_DIR := "res://data/visitors/"
const SPECIAL_VISITORS_DIR := "res://data/visitors/special/"

var _visitors: Array[Visitor] = []
var _seen: Array[Visitor] = []
var _seen_groups: Array[StringName] = [] # recurring_group values already shown this phase
var _group_pending: Dictionary = {} # StringName (recurring_group) -> Array[Visitor], this cycle's not-yet-shown members

func _ready() -> void:
	_load_dir(VISITORS_DIR)
	_load_dir(SPECIAL_VISITORS_DIR)

func _load_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("VisitorDatabase: cannot open %s" % path)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res := load(path + file_name)
			if res is Visitor:
				_visitors.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()

func get_all() -> Array[Visitor]:
	return _visitors

## Picks a visitor from the day or night rotation (per night_visitor)
## that hasn't knocked yet since the last reset_seen(). Returns null
## once everyone in that rotation's been seen — the door just stays
## quiet rather than repeating anyone within the same phase.
##
## Story-gated visitors (required_flag set) are additionally filtered
## to those whose flag is already set, and a story visitor whose own
## knocked_sets_flag is already set is excluded outright — their beat
## already happened once, it doesn't repeat like an ordinary client's.
## knocked_sets_flag itself is set here, the moment they're picked —
## same "seen at the door is enough" reasoning as problem_text playing
## regardless of invite/refuse.
##
## `exclude`, if given, is left out even if otherwise eligible — hut.gd
## passes today's/tonight's already-decided forced visitor (see
## CHAPTER1_SCRIPT) so a random slot earlier in the same phase can't
## accidentally hand out the exact same visitor a second time. If
## `exclude` belongs to a recurring_group (e.g. a scripted Упир beat,
## whose group also has ordinary variants in the ordinary pool), the
## whole group is excluded too — otherwise an earlier random slot could
## hand out upyr_brutal_male_lost, say, and the forced upyr_brutal_male
## would still show up later that same night regardless, which is
## exactly the "same person twice in one night" recurring_group exists
## to prevent.
##
## A visitor with recurring_group set is additionally excluded unless
## it's still "pending" in that group's current cycle — see
## _advance_group_cycle(). That part persists for the whole
## playthrough (unlike _seen_groups): every member of a group (e.g.
## anxious_neighbor's 3 variants) has to come up once before any of
## them can repeat. Separately, picking ANY member of a group marks
## the WHOLE group seen for the rest of this phase (not just that one
## variant, tracked in _seen_groups, cleared by reset_seen alongside
## _seen) — the same person showing up twice in one day, just as a
## different variant, is exactly the thing recurring_group exists to
## prevent.
##
## That whole-group block is a two-tier rule, not absolute: once every
## one-time visitor in a phase's pool has been used up (common by the
## later chapter days — most of the ordinary cast is one-and-done, see
## STORY.md), the only things left standing might be 2-3 recurring
## groups, each already blocked for the rest of THIS phase after a
## single pick — with DAY_VISITOR_CAP higher than that, the door would
## otherwise just go silent for the rest of the day with nothing left
## to knock, and since nothing knocks, hut.gd never advances past it.
## So if the strict pass comes up empty, retry once ignoring the
## whole-group block (still never the exact same Visitor instance
## twice — _seen alone stays absolute) before actually giving up.
func get_random(night: bool, exclude: Visitor = null) -> Visitor:
	var exclude_group: StringName = exclude.recurring_group if exclude != null else &""
	var base_filter := func(v: Visitor) -> bool:
		return v.night_visitor == night and v != exclude \
			and (exclude_group == &"" or v.recurring_group != exclude_group) \
			and (v.required_flag == &"" or StoryFlags.has_flag(v.required_flag)) \
			and (v.knocked_sets_flag == &"" or not StoryFlags.has_flag(v.knocked_sets_flag)) \
			and (v.recurring_group == &"" or _group_pending.get(v.recurring_group, [v]).has(v))
	var available := _visitors.filter(func(v: Visitor) -> bool:
		return base_filter.call(v) and not _seen.has(v) and not _seen_groups.has(v.recurring_group))
	if available.is_empty():
		available = _visitors.filter(func(v: Visitor) -> bool: return base_filter.call(v) and not _seen.has(v))
	if available.is_empty():
		return null
	var visitor: Visitor = available[randi() % available.size()]
	_seen.append(visitor)
	if visitor.recurring_group != &"":
		_seen_groups.append(visitor.recurring_group)
		_advance_group_cycle(visitor)
	if visitor.knocked_sets_flag != &"":
		StoryFlags.set_flag(visitor.knocked_sets_flag)
	return visitor

## For a visitor shown through hut.gd's CHAPTER1_SCRIPT forced dispatch
## instead of get_random() (e.g. Day 2's scripted Упир, reused straight
## from this same ordinary pool) — that path never touches this
## database at all otherwise, so without this call the cross-day
## recurring_group cycle below would have no idea that variant was
## just shown, and could hand the exact same one out again via
## ordinary random rotation a day or two later. A no-op for a visitor
## with no recurring_group.
func register_shown(visitor: Visitor) -> void:
	if visitor.recurring_group != &"":
		_advance_group_cycle(visitor)

## Marks `visitor` as shown this cycle for its recurring_group. Once
## every member of the group has had a turn, starts a fresh cycle —
## minus `visitor` itself, so the member that just finished one cycle
## can't also be the first pick of the next (no back-to-back repeat
## right at the seam between cycles either).
func _advance_group_cycle(visitor: Visitor) -> void:
	var group := visitor.recurring_group
	if not _group_pending.has(group):
		_group_pending[group] = _visitors.filter(func(v: Visitor) -> bool: return v.recurring_group == group)
	_group_pending[group].erase(visitor)
	if _group_pending[group].is_empty():
		_group_pending[group] = _visitors.filter(func(v: Visitor) -> bool:
			return v.recurring_group == group and v != visitor)

## Clears the seen-list so everyone can knock again — called by hut.gd
## on every day/night phase flip.
func reset_seen() -> void:
	_seen.clear()
	_seen_groups.clear()
