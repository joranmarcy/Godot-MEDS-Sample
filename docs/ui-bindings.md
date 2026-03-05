## Built-in UI bindings

The core addon includes a few small “driven” UI scripts you can attach directly to common UI controls to keep them synced with variables.

### Basic usage

1. Add the UI control (`CheckBox`, `Slider`, `Label`, `ColorPickerButton`, …).
2. Attach the matching script from `addons/godot_meds_core/scripts/ui/`.
3. In the Inspector, assign the exported `*Variable` resource.

### Included bindings

| Script | Attach to | Exported property | Sync behavior |
| --- | --- | --- | --- |
| `addons/godot_meds_core/scripts/ui/bool-driven-checkbox.gd` | `CheckBox` | `bool_var: BoolVariable` | Two-way: checkbox toggles update the variable, and variable changes update the checkbox. |
| `addons/godot_meds_core/scripts/ui/float-driven-slider.gd` | `Slider` | `float_variable: FloatVariable` | Two-way: slider changes update the variable, and variable changes update the slider. |
| `addons/godot_meds_core/scripts/ui/string-driven-label.gd` | `Label` | `string_variable: StringVariable` | One-way: variable changes update the label text. |
| `addons/godot_meds_core/scripts/ui/float-driven-label.gd` | `Label` | `float_variable: FloatVariable` | One-way: variable changes update the label text (via `str(...)`). |
| `addons/godot_meds_core/scripts/ui/color-driven-color-picker.gd` | `ColorPickerButton` | `color_variable: ColorVariable` | Two-way: picker changes update the variable, and variable changes update the picker. |

Notes:

- These scripts assume the exported variable is assigned (otherwise you’ll hit null errors at runtime).
- “Two-way” bindings use `set_value(..., self)` so the variable can track the change source.

