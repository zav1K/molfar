class_name Threat
extends RefCounted
## Shared vocabulary of threat categories that wards can react to. Extend
## as the narrative introduces specific creature types — wards check
## against the category here, not a specific species, so adding a new
## species later doesn't require touching the ward system itself.

enum Type {
	NONE,       ## an ordinary person — no ward should react
	WITCHCRAFT, ## відьми/чаклунство — countered by wormwood (полин)
	UNDEAD,     ## упирі/нечисть — countered by garlic (часник)
	SORCERY,    ## чаклуни — countered by iron/needle (no ingredient models this yet)
}
