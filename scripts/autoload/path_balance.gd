extends Node
## Autoload. Tracks how far the player's choices have leaned toward the
## white or black молфар path — separate from a single brew's light/dark
## stir choice (see Recipe), this is cumulative across the whole
## playthrough. Currently only moved by ReceptionUI's "demand money"
## override (insisting on payment a visitor wasn't already offering).
## Purely observational for now — nothing reads it yet, and Viktor asked
## to hold off on a full reputation/consequences system, so this stays a
## single number with no mechanical effect until that's revisited.

signal changed(value: int)

const DEMAND_MONEY_SHIFT := -1 ## negative = darker

var value: int = 0

func shift(amount: int) -> void:
	value += amount
	changed.emit(value)
