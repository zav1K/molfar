class_name MoonPhase
extends RefCounted
## Shared vocabulary for the moon's phase — GameCalendar computes it,
## Ingredient reads it to decide whether a rare/moon-sensitive plant may be
## sown today. Split out as its own class_name (same trick as Threat) so a
## Resource script can @export a field typed to it; GameCalendar itself has
## no class_name, so its own enums aren't exportable from other resources.

enum Phase {
	ANY,     ## no requirement — common ingredients always use this
	NEW,     ## молодик — bad for sowing any moon-sensitive plant
	WAXING,  ## зростальний — favors above-ground/fruiting growth
	FULL,    ## повня — bad for sowing any moon-sensitive plant
	WANING,  ## спадний — favors root/bulb growth
}
