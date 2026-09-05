class_name Keepsake
extends Resource
## A decorative or story item — never consumed, never checked against a
## recipe or a visitor's desired_result_id, just something the player has
## and can look at. Shown in the chest's full stockpile screen alongside
## herbs/potions/sigils. Held the same way as everything else, as a plain
## PlayerInventory count.

@export var id: StringName
@export var display_name: String
@export_multiline var description: String

## Stand-in visuals until final hand-painted art exists.
@export var placeholder_color: Color = Color.WEB_GRAY
@export var icon: Texture2D
