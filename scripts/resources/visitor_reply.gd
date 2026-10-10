class_name VisitorReply
extends Resource
## One thing the molfar can say back, for a visitor who came asking for
## something that isn't an object.
##
## The day clients don't need this: "корова хворіє" is answered by
## handing over the відвар, and the item IS the molfar's half of the
## conversation. The night callers broke that shape — most of them want
## advice, permission or an answer, so with nothing to hand over they
## all fell through to one generic "Вислухати" button. The upyr who asks
## to be taught to pass as human was thanking the player for pressing it.
##
## A reply resolves the visit outright (see ReceptionUI._resolve): the
## response below replaces satisfied_text/unhelped_text rather than
## stacking with it, and the reply's own flag and path weight replace the
## visitor's. That last part is the point — two replies to the same
## question are only a real choice if they can lead different places.

## What the molfar says, printed on the button. Written as the actual
## line, not as a summary of it ("Не сідай спиною до вогню." rather than
## "Дати пораду") — the button is the dialogue.
@export_multiline var label: String = ""

## What they say back to this reply specifically.
@export_multiline var response: String = ""

## Whether this counts as having helped them — drives payment, the
## refusal-loot roll, and everything else that reads _satisfied. A reply
## that turns someone down sets this false.
@export var satisfies: bool = true

## Set when this reply is chosen. Replaces the visitor's own
## satisfied_sets_flag, which is deliberately NOT set for a visit
## resolved by reply: being helped and being helped *in a particular way*
## are different facts, and the chapter reads both.
@export var sets_flag: StringName = &""

## Replaces satisfied_path_shift/unhelped_path_shift for this visit.
@export var path_shift: int = 0

## Only offered if StoryFlags has this — advice the molfar can't give
## until he's learned it himself. Empty (the default) always offers it.
@export var required_flag: StringName = &""
