extends Node
## Autoload. Counts how many нечисть the player has let across the
## threshold, and what the village has come to think of him for it.
##
## Deliberately NOT folded into PathBalance. PathBalance is the
## white/black craft axis (squeezing payment out of people who had none,
## dark stirs); this is sympathy for нечисть, which is a different thing
## entirely. Mixing them would mean a player who gouged every client but
## turned away every upyr still gets accused of sheltering them by the
## priest on day 7, which reads as a bug rather than as a consequence.
##
## Why this is a cost and not a punishment: нечисть is the only source of
## what actually happened to Лісник (upyr_curse_origin_known and the
## diary entries around it). Turn everyone away and the chapter ends with
## the priest's version of events unchallenged — the player believes him.
## Let them in and the village starts counting your lit windows, but you
## end the chapter able to doubt. Both directions cost something, which
## is the whole point; see STORY.md.
##
## Нечисть can also never hurt the player directly — that's a premise of
## the chapter, so the consequence has to come from people. It shows up
## as the village's tone, not as damage: see hut.gd/ReceptionUI for the
## client-side effects and priest_day7 for the payoff.

signal level_changed(level: Level)

## Thresholds tuned against the chapter's actual night count: 7 nights
## at SCRIPTED_NIGHT_CAP mostly 3 gives roughly 12-18 нечисть at the
## door, so 3 is "a few, by choice" and 6 is "a habit the village can
## see".
const NOTICED_THRESHOLD := 3
const MARKED_THRESHOLD := 6

enum Level {
	QUIET,   ## nothing anyone's noticed
	NOTICED, ## the village has started talking
	MARKED,  ## the village has made up its mind about him
}

var sheltered: int = 0

## Called from hut.gd the moment a non-human visitor is invited in —
## invited, not served: crossing the threshold is the part the village
## would see, exactly as Visitor.knocked_sets_flag fires on being seen at
## the door regardless of what's handed over afterwards.
func record_sheltered() -> void:
	var before := level()
	sheltered += 1
	var now := level()
	if now != before:
		level_changed.emit(now)

func level() -> Level:
	if sheltered >= MARKED_THRESHOLD:
		return Level.MARKED
	if sheltered >= NOTICED_THRESHOLD:
		return Level.NOTICED
	return Level.QUIET

func save_state() -> int:
	return sheltered

func load_state(saved_value: int) -> void:
	sheltered = saved_value
	level_changed.emit(level())
