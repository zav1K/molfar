extends Node
## Autoload. Tracks how far the player's choices have leaned toward the
## white or black молфар path — separate from a single brew's light/dark
## stir choice (see Recipe), this is cumulative across the whole
## playthrough. Moved by ReceptionUI's "demand money" override (insisting
## on payment a visitor wasn't already offering), by a Visitor's own
## satisfied/unhelped shifts, and by the post-resolution choices.
##
## Read at the end of the chapter, by ChapterEnd's chronicle — through
## leaning() rather than the raw number, because the player should never
## be shown a morality score. There is no mid-game readout on purpose.
##
## Distinct from VillageSuspicion, which is sympathy for нечисть: see
## that autoload's doc for why the two axes are kept apart.

signal changed(value: int)

const DEMAND_MONEY_SHIFT := -1 ## negative = darker

## How far the number has to drift before it's worth remarking on. Tuned
## against the chapter's length: roughly thirty visitors across seven
## days, most carrying no shift at all, so four in one direction means
## the player kept choosing it rather than drifting there.
const LEANING_THRESHOLD := 4

enum Leaning { DARK, EVEN, LIGHT }

var value: int = 0

func leaning() -> Leaning:
	if value <= -LEANING_THRESHOLD:
		return Leaning.DARK
	if value >= LEANING_THRESHOLD:
		return Leaning.LIGHT
	return Leaning.EVEN

func shift(amount: int) -> void:
	value += amount
	changed.emit(value)

func save_state() -> int:
	return value

func load_state(saved_value: int) -> void:
	value = saved_value
	changed.emit(value)
