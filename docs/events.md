### Events (typed-less Resource signals)

Events are `Resources` that expose a single signal and a method to emit it.

- Script: `addons/godot_flow_core/scripts/events/event.gd`
- API:
  - `signal event_raised()`
  - `func raise_event() -> void`
  - `debug_logs` exported bool (prints a rich debug log when raised)

#### Using events in scripts

Listener:

```gdscript
extends Node

@export var event: Event

func _ready() -> void:
	event.event_raised.connect(_on_event_raised)

func _on_event_raised() -> void:
	print("Event received!")
```

Raiser:

```gdscript
extends Node

@export var event: Event

func trigger() -> void:
	event.raise_event()
```
