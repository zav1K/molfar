class_name Ingredient
extends Resource

enum Source { WILD, GARDEN }

## Unique lookup key, e.g. &"garlic".
@export var id: StringName
@export var display_name: String
@export_multiline var description: String

@export var source: Source = Source.GARDEN
## 1 = common ... 5 = legendary/one-off.
@export_range(1, 5) var rarity: int = 1

## Day-of-year window (1-366) the ingredient can be gathered. Full range = year-round.
@export var season_start_day: int = 1
@export var season_end_day: int = 366

## Ritual/holiday this ingredient is tied to, if any (matches GameCalendar festival id).
@export var festival_id: StringName = &""

## Stand-in visuals until final hand-painted art exists.
@export var placeholder_color: Color = Color.WEB_GREEN

## Drying-bundle art shown on the hut's beam while the player holds this
## ingredient. Null until an artist provides one — the bundle just stays
## hidden in that case, no placeholder box.
@export var bundle_icon: Texture2D
