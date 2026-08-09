class_name Visitor
extends Resource
## Someone knocking at the hut door.

@export var display_name: String = "Подорожній"
@export_multiline var problem_text: String = "..."

## Groundwork for a folklore beat: not everyone who knocks is necessarily
## human — упирі/нечисть traditionally can't cross a threshold without
## being invited. Always true for now; nothing branches on it yet, but the
## invite/refuse choice is built to have real consequences once it does.
@export var is_human: bool = true
