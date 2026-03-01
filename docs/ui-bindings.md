## Built-in UI bindings

The core addon includes a few small “driven” UI scripts you can attach to UI controls to keep them synced with variables.

Examples:

- `addons/godot_flow_core/scripts/ui/bool-driven-checkbox.gd`
  - Attach to a `CheckBox`, assign `bool_var: BoolVariable`.
  - User toggles update the variable; variable changes update the checkbox.
- `addons/godot_flow_core/scripts/ui/float-driven-slider.gd`
  - Attach to a `Slider`, assign `float_variable: FloatVariable`.
- `addons/godot_flow_core/scripts/ui/string-driven-label.gd`
  - Attach to a `Label`, assign `string_variable: StringVariable`.
- `addons/godot_flow_core/scripts/ui/color-driven-color-picker.gd`
  - Attach to a `ColorPickerButton`, assign `color_variable: ColorVariable`.

