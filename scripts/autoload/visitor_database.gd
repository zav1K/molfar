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
## Two separate exclusion scopes, because they guard two different
## things and conflating them breaks one or the other:
##
## `exclude` drops those exact Visitors. hut.gd passes every forced story
## beat still scheduled for today OR LATER (see CHAPTER1_SCRIPT), not
## just today's. Today's matters so a random slot earlier in the same
## phase can't hand out the same person twice; the later ones matter
## because a beat drawn early plays its whole dialogue as an ordinary
## visitor, and then its scripted night repeats that dialogue verbatim as
## the "first meeting" — which is what used to happen to both упириці
## every single playthrough (the day-4 hidden upyr turning up on night 2,
## the day-5 repentant one on night 1). Beats already past are NOT
## excluded: once the scripted night has happened, those visitors are
## ordinary recurring нечисть again and should rotate normally.
##
## `exclude_groups` drops whole recurring_groups, and hut.gd passes only
## TODAY's forced visitor's group. That one is needed because a group's
## other variants are the same person: without it an earlier random slot
## could hand out upyr_brutal_male_lost and the forced upyr_brutal_male
## would still arrive later the same night. It deliberately does NOT
## extend to later days' beats — the variants are not the beat, so
## blocking the whole group for days beforehand would strip three of the
## night pool's six faces out of the earlier nights for nothing.
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
func get_random(night: bool, exclude: Array[Visitor] = [], exclude_groups: Array[StringName] = []) -> Visitor:
	var base_filter := func(v: Visitor) -> bool:
		return v.night_visitor == night and not exclude.has(v) \
			and not (v.recurring_group != &"" and exclude_groups.has(v.recurring_group)) \
			and _is_eligible(v) \
			and (v.recurring_group == &"" or _group_pending.get(v.recurring_group, [v]).has(v))
	var available := _visitors.filter(func(v: Visitor) -> bool:
		return base_filter.call(v) and not _seen.has(v) and not _seen_groups.has(v.recurring_group))
	if available.is_empty():
		available = _visitors.filter(func(v: Visitor) -> bool: return base_filter.call(v) and not _seen.has(v))
	if available.is_empty():
		return null
	var visitor := _pick_fairly(available)
	_seen.append(visitor)
	if visitor.recurring_group != &"":
		_seen_groups.append(visitor.recurring_group)
		_advance_group_cycle(visitor)
	if visitor.knocked_sets_flag != &"":
		StoryFlags.set_flag(visitor.knocked_sets_flag)
	return visitor

## Picks uniformly over PEOPLE, then over that person's eligible
## variants — not uniformly over resources, which is the obvious
## implementation and is wrong here.
##
## A recurring_group is one person with several things to say, so a
## flat pick made a 3-variant person three times likelier to knock than
## a one-off. Simulating the whole chapter showed exactly that: Упир
## came 4.2 times a playthrough against his 3 written variants, and
## Мисливець/Коваль/Господиня crowded out the one-off clients the same
## way — so the pool looked repetitive while half the cast sat unused.
## Weighting by person instead spreads the slots over everyone and gets
## more value out of the dialogue already written than adding more
## would.
func _pick_fairly(available: Array) -> Visitor:
	var by_person := {}
	for v: Visitor in available:
		# One-offs have no group, so each is its own "person".
		var key: String = String(v.recurring_group) if v.recurring_group != &"" else v.resource_path
		if not by_person.has(key):
			by_person[key] = []
		by_person[key].append(v)
	var keys := by_person.keys()
	var variants: Array = by_person[keys[randi() % keys.size()]]
	return variants[randi() % variants.size()]

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
## Could the rotation hand this visitor out at all right now — story gate
## satisfied, and their one-time beat not already spent? Shared with
## _advance_group_cycle so the cycle only ever tracks visitors that can
## actually come up. Without that it stalls: a group holding one member
## the pool can never draw (a sentinel-gated scripted beat, or a
## two-visit chain's spent first half) never empties, so the reset below
## never fires and every OTHER member of the group goes quiet too.
func _is_eligible(v: Visitor) -> bool:
	return (v.required_flag == &"" or StoryFlags.has_flag(v.required_flag)) \
		and (v.knocked_sets_flag == &"" or not StoryFlags.has_flag(v.knocked_sets_flag))

func _advance_group_cycle(visitor: Visitor) -> void:
	var group := visitor.recurring_group
	if not _group_pending.has(group):
		_group_pending[group] = _group_members(group, null)
	_group_pending[group].erase(visitor)
	if _group_pending[group].is_empty():
		_group_pending[group] = _group_members(group, visitor)

## A group's drawable members, minus `just_shown` (so the member that just
## went can't also open the next cycle). An empty result means the group is
## finished for good — right for a two-visit chain once both halves are
## spent, and harmless for an ordinary group, whose members carry no
## knocked_sets_flag and so stay drawable forever.
func _group_members(group: StringName, just_shown: Visitor) -> Array:
	return _visitors.filter(func(v: Visitor) -> bool:
		return v.recurring_group == group and v != just_shown and _is_eligible(v))

## Clears the seen-list so everyone can knock again — called by hut.gd
## on every day/night phase flip.
func reset_seen() -> void:
	_seen.clear()
	_seen_groups.clear()

## Forgets everything, including the cross-playthrough group cycle that
## reset_seen deliberately keeps — a new game has met nobody.
func reset() -> void:
	_seen.clear()
	_seen_groups.clear()
	_group_pending.clear()

## Only the cross-playthrough part is worth saving: _seen/_seen_groups
## are cleared on every phase flip anyway, and SaveGame only writes at a
## phase flip, so they're empty at save time by construction. Visitor
## objects themselves are saved as resource paths.
func save_state() -> Dictionary:
	var out := {}
	for group in _group_pending:
		var paths: Array = []
		for visitor in _group_pending[group]:
			paths.append(visitor.resource_path)
		out[String(group)] = paths
	return out

func load_state(data: Dictionary) -> void:
	_group_pending.clear()
	for group in data:
		var members: Array[Visitor] = []
		for path in data[group]:
			for visitor in _visitors:
				if visitor.resource_path == path:
					members.append(visitor)
					break
		_group_pending[StringName(group)] = members
