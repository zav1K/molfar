class_name Molfar
extends RefCounted
## Who the player actually is in Розділ І. Same "shared vocabulary in one
## place" pattern as Threat — nothing here is instanced, it's just the
## one spot that owns these strings so a rename is a one-line change
## instead of a grep across 40 .tres files.
##
## Розділ І is a prequel: the player is the OLD molfar, a man the village
## has relied on for decades, who disappears shortly after the chapter's
## seventh day. The full game is about the heir who comes after him and
## finds this hut — so the grimoire the player fills in over these seven
## days is, in-fiction, the very "щоденник попереднього мольфара" that
## CONCEPT.md already listed as a full-game feature (see STORY.md's
## prequel framing).
##
## Consequences of that framing, worth keeping in mind when writing
## visitor dialogue:
##   * He is NOT a novice. Nobody explains his own craft to him, and
##     tutorialisation has to live in the UI (hints), never in the
##     fiction ("ти ж казана ще не розпалював" is wrong for him).
##   * The villagers have known him their whole lives — deference and
##     long familiarity, not introductions.
##   * A fully-stocked drying beam and a long-established garden are
##     characterisation, not debug leftovers (see hut.gd's seeding).

## The village's name for him. Most visitors would say ДІД_NAME rather
## than this on its own.
const NAME := "Онуфрій"

## How a villager addresses him out loud.
const RESPECTFUL_ADDRESS := "дід Онуфрій"
