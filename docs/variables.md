### Variables (typed Resource state)

Variables are `Resource`s that hold a typed value and emit a signal when the value changes.

Available variable types (scripts live under `addons/godot_flow_core/scripts/variables/`):

- `BoolVariable`
- `IntVariable`
- `FloatVariable`
- `StringVariable`
- `ColorVariable`
- `Vector2Variable`
- `Vector3Variable`

Common API (implemented via `BaseVariable`):

- `value` property (typed per variable)
- `value_changed(new_value)` signal
- `initial_value` exported property
- `debug_logs` exported bool: when enabled, logs value changes + a stack trace + which listeners are connected
- `save_to_device` exported bool: persists changes to `user://settings.cfg` and reloads on startup
  - stored in section `variables`
  - key is the variable’s `resource_path.get_basename()`

#### Creating a variable resource

1. In the FileSystem dock: **Right click → New Resource…**
2. Pick e.g. `BoolVariable` and save it as a `.tres`.
3. Assign that `.tres` to exported fields in scripts.

#### Using variables in scripts

```gdscript
extends Node

@export var bool_variable: BoolVariable

func _ready() -> void:
	bool_variable.value_changed.connect(_on_bool_changed)
	print("Initial value:", bool_variable.value)

func _on_bool_changed(new_value: bool) -> void:
	print("Bool changed to:", new_value)
```

When you want better debug output that includes the caller, prefer the typed helper method:

```gdscript
bool_variable.set_value(true, self)
```
