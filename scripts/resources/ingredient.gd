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

## Day-of-year window the ingredient can be gathered/sown, on
## GameCalendar's condensed scale (1..GameCalendar.DAYS_PER_YEAR). Full
## range = year-round. See GameCalendar's docstring: this is only rescaled
## for GARDEN-source ingredients so far.
@export var season_start_day: int = 1
@export var season_end_day: int = 84

## Ritual/holiday this ingredient is tied to, if any (matches GameCalendar festival id).
@export var festival_id: StringName = &""

## Which moon phase favors sowing this ingredient — MoonPhase.Phase.ANY
## (default) means it's common and unaffected by the moon at all. A rare
## ingredient sets WAXING (above-ground/fruiting growth) or WANING
## (root/bulb growth); GardenState still lets it be sown in the other
## phase (just slower to ripen) but blocks NEW/FULL outright for any
## moon-sensitive ingredient — see GardenState.check_plantable().
@export var favorable_moon_phase: MoonPhase.Phase = MoonPhase.Phase.ANY

## Calendar days to fully ripen once planted in the garden, before any
## watering bonus. Only meaningful for GARDEN-source ingredients.
@export var base_growth_days: int = 3

## Stand-in visuals until final hand-painted art exists.
@export var placeholder_color: Color = Color.WEB_GREEN

## Drying-bundle art shown on the hut's beam while the player holds this
## ingredient. Null until an artist provides one — the bundle just stays
## hidden in that case, no placeholder box.
@export var bundle_icon: Texture2D

## Threat category this ingredient wards against when hung over the door,
## or Threat.Type.NONE if it isn't a ward at all.
@export var ward_threat: Threat.Type = Threat.Type.NONE

## Ambiguous hint shown near the door when this ward reacts to a knocking
## visitor's hidden nature — never a flat confirmation, just unease.
@export var ward_hint_text: String = ""
