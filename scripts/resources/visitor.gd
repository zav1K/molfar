class_name Visitor
extends Resource
## Someone knocking at the hut door.

@export var display_name: String = "Подорожній"
@export_multiline var problem_text: String = "..."

## Hidden from the player — wards check against this, nothing else should
## read it directly. Folklore beat: упирі/нечисть traditionally can't cross
## a threshold without being invited, so the invite/refuse choice needs to
## have real consequences tied to this once that mechanic exists.
@export var true_threat: Threat.Type = Threat.Type.NONE

## Selects which rotation this visitor is drawn from: day clients vs. the
## night cycle's нечисть/nocturnal callers. See GameCalendar/hut.gd's
## day-night knock logic and VisitorDatabase.get_random().
@export var night_visitor: bool = false

## What would actually help them — a Potion or Sigil id. No "reading the
## client" mechanic yet (see CONCEPT.md's diagnosis-via-details idea) —
## for now this is just what ReceptionUI checks a given item against.
@export var desired_result_id: StringName = &""

## A second acceptable answer, equally "correct" — for the rare visitor
## whose own words support two different readings (e.g. jealous_wife's
## "зніми з нього ті чари, або... поверни мені, що моє" is literally two
## asks in one line). Same satisfied_text plays either way; the point
## isn't different flavor text, it's that the player had to actually
## decide which reading fit instead of pattern-matching one fixed id.
## Empty (the default) means there's only one right answer, as before.
@export var alt_desired_result_id: StringName = &""

## Reversed direction: a Keepsake (or any item) id this visitor is trying
## to hand OFF to the player instead of asking for something — e.g.
## found_doll's Солом'яна лялька. Optional either way, never a fail
## state: ReceptionUI shows a Взяти/Відправити choice, satisfied_text
## plays on taking it, unhelped_text on declining. Empty for every
## ordinary give-an-item visitor.
@export var offers_item_id: StringName = &""

@export_multiline var satisfied_text: String = "Дякую, мольфаре. Мені вже легше."
@export_multiline var unhelped_text: String = "...це не те, що мені було треба."

## Voluntary thanks/barter, not a price — per CONCEPT.md, молфар doesn't
## charge money directly (that pulls toward the black path). Granted
## automatically by ReceptionUI once the visitor is actually satisfied
## (item given/taken, never on refusal or being sent away unhelped).
enum PaymentType { NOTHING, MATERIAL, MONEY, INFORMATION }
@export var payment_type: PaymentType = PaymentType.NOTHING

## Item id granted for MATERIAL/MONEY payment — an Ingredient, Keepsake,
## an equipment-progression material (mat_metal/mat_wood/mat_goods), or
## &"groshi" for money. Unused for NOTHING/INFORMATION.
@export var payment_item_id: StringName = &""
@export var payment_amount: int = 1

## Flavor line describing what changes hands, appended to satisfied_text
## in ReceptionUI. E.g. "домашній хліб, вишитий рушник".
@export var payment_flavor_text: String = ""

## StoryFlags key set when payment_type == INFORMATION — a hook for a
## future story thread, not read by anything yet.
@export var payment_flag_id: StringName = &""

## The barter looks ordinary, but something else quietly goes missing
## from the player's own holdings at the same time — e.g. upyr_hidden's
## thanks. Only meaningful alongside payment_type MATERIAL/MONEY.
@export var payment_is_deceptive: bool = false

## Chance (0..1) of leaving behind loot when refused/sent away instead of
## helped — dirtier "payment" for driving off something dangerous rather
## than helping it (upyr_brutal_*, who have no desired_result_id and so
## can never actually be satisfied — refusal is their only real outcome).
## Never checked on an ordinary unhelped resolution otherwise (0 by default).
@export_range(0.0, 1.0) var refusal_loot_chance: float = 0.0
@export var refusal_loot_item_id: StringName = &""

## Shown in ThresholdDialogue while deciding whether to invite them in.
@export var portrait_door: Texture2D

## Shown in ReceptionUI once they're waiting inside for a potion/ward.
## Falls back to portrait_door until a second pose exists — see
## get_waiting_portrait().
@export var portrait_waiting: Texture2D

## Story gating, for scripted one-time beats rather than the ordinary
## repeating rotation (see VisitorDatabase.get_random()). Empty (the
## default) means always eligible, same as every ordinary client today.
## required_flag: won't turn up at all until StoryFlags has this set.
## knocked_sets_flag: set the moment this visitor knocks (not on a
## successful resolution — being seen at the door is enough to have
## "happened," same as problem_text playing regardless of invite/refuse).
## Also doubles as this visitor's own once-only guard: once their own
## knocked_sets_flag is set, they stop being eligible too, so a scripted
## beat never repeats the way an ordinary client does.
@export var required_flag: StringName = &""
@export var knocked_sets_flag: StringName = &""

## Moves PathBalance the moment this visitor resolves — satisfied_path_shift
## on a successful give/take/listen, unhelped_path_shift on refusal/wrong
## item/sent away. Zero (the default, for nearly everyone) means this
## particular visitor doesn't carry moral weight either way; DemandMoneyButton's
## override in ReceptionUI is separate and always applies regardless of this.
@export var satisfied_path_shift: int = 0
@export var unhelped_path_shift: int = 0

## Optional post-resolution moral beat, shown instead of the plain Finish
## button once satisfied — for the rare "thank you" that deserves an
## actual response from the player rather than just closing the window
## (currently only priest_secret_visit's confession). Empty choice_prompt
## (the default) means no such beat; ReceptionUI just shows Finish as
## normal. Both choices are equally valid — this isn't a right/wrong
## quiz, it's another PathBalance-weighted fork like the shifts above.
@export var choice_prompt: String = ""
@export var choice_a_label: String = ""
@export var choice_a_response: String = ""
@export var choice_a_path_shift: int = 0
@export var choice_b_label: String = ""
@export var choice_b_response: String = ""
@export var choice_b_path_shift: int = 0

## Normalized (0..1) content bounding box of the *waiting* portrait,
## ignoring transparent canvas padding — measured offline (see
## scratchpad png_bbox.py) rather than at runtime because these
## generated portraits carry a faint alpha haze across nearly the whole
## canvas that defeats Godot's Image.get_used_rect() (it treats any
## nonzero alpha as "used", so it barely trims anything). Used by
## WaitingVisitorDisplay to size/crop the figure against the table line.
## Defaults to the full canvas (no cropping) until measured.
@export var waiting_portrait_content_rect: Rect2 = Rect2(0, 0, 1, 1)

func is_human() -> bool:
	return true_threat == Threat.Type.NONE

func get_waiting_portrait() -> Texture2D:
	return portrait_waiting if portrait_waiting != null else portrait_door
