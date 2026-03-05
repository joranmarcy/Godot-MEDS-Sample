````markdown

This sample script turns a `Event` resource into a scene-level signal you can easily connect to from the editor.

- Script: `samples/scripts/event-listener.gd`
- Exported fields:
  - `event: Event`
- Signals:
  - `event_raised()` (re-emitted when the assigned `Event` is raised)

#### Why this exists

You can always connect to an `Event` resource directly from code (see `docs/events.md`).

This wrapper is useful when you want to:

- Drop a listener node into a scene and wire connections from the **Node** tab.
- Keep your scene logic listening to a *node signal* instead of a *resource signal*.

#### Setup (in the editor)

1. Create an `Event` resource (a `.tres`).
2. Add a `Node` (or `Node3D`) to your scene.
3. Attach `samples/scripts/event-listener.gd`.
4. Assign your `.tres` to the exported `event` field.
5. Connect the node’s `event_raised` signal to any method you want.

Important: this script expects `event` to be assigned (non-null).

#### Setup (in code)

```gdscript
extends Node

@onready var listener := $EventListener

func _ready() -> void:
	listener.event_raised.connect(_on_event)

func _on_event() -> void:
	print("Event received via wrapper node")
````

The companion sample script `samples/scripts/raise-event.gd` raises the same `Event` resource:

```gdscript
extends Node

@export var event: Event

func trigger() -> void:
	event.raise_event()
```

To test the full flow:

- Create one `Event` `.tres`.
- Assign it to both:
  - a node with `event-listener.gd`
  - a node with `raise-event.gd`
- Call `trigger()` (or `raise_event()`, depending on your own script) and observe the listener firing.

#### Debugging

- If `debug_logs` is enabled on the `Event` resource, raising it prints a rich debug log.
- When the **Godot MEDS Editor Tools** plugin is enabled, the **Events** dock shows listener counts and raise counts.

See also:

- `docs/events.md`
- `docs/events-dock.md`

````
