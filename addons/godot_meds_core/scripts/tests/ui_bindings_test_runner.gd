extends SceneTree

const TEST_HARNESS_SCRIPT := preload("res://addons/godot_meds_core/scripts/tests/test_harness.gd")
const FLOAT_VARIABLE_SCRIPT := preload("res://addons/godot_meds_core/scripts/variables/float-variable.gd")
const INT_VARIABLE_SCRIPT := preload("res://addons/godot_meds_core/scripts/variables/int-variable.gd")
const LABEL_SCRIPT := preload("res://addons/godot_meds_core/scripts/ui/variable-driven-label.gd")
const SLIDER_SCRIPT := preload("res://addons/godot_meds_core/scripts/ui/variable-driven-slider.gd")

var _harness := TEST_HARNESS_SCRIPT.new()

func _init() -> void:
	await process_frame
	await _harness.run_test("label_updates_from_initial_value_and_signal", _test_label_updates_from_initial_value_and_signal)
	await _harness.run_test("float_slider_tracks_value_and_clamped_range", _test_float_slider_tracks_value_and_clamped_range)
	await _harness.run_test("int_slider_uses_integer_step_and_rounding", _test_int_slider_uses_integer_step_and_rounding)
	_harness.finish("UI binding tests", self)

func _test_label_updates_from_initial_value_and_signal() -> void:
	var variable: StringVariable = preload("res://addons/godot_meds_core/scripts/variables/string-variable.gd").new()
	variable.initial_value = "Robot"

	var label: Label = LABEL_SCRIPT.new()
	label.variable = variable
	label.prefix = "Name: "
	label.suffix = "!"
	root.add_child(label)
	await process_frame

	_harness.expect_string(label.text, "Name: Robot!", "VariableDrivenLabel should render the initial variable value on ready")

	variable.set_value("MEDS")
	_harness.expect_string(label.text, "Name: MEDS!", "VariableDrivenLabel should update when the bound variable changes")

	label.queue_free()
	await process_frame

func _test_float_slider_tracks_value_and_clamped_range() -> void:
	var variable: FloatVariable = FLOAT_VARIABLE_SCRIPT.new()
	variable.clamp_value = true
	variable.min_value = -3.5
	variable.max_value = 7.25
	variable.initial_value = 2.5

	var slider := HSlider.new()
	slider.set_script(SLIDER_SCRIPT)
	slider.min_value = -100.0
	slider.max_value = 100.0
	slider.step = 0.25
	slider.set("variable", variable)
	root.add_child(slider)
	await process_frame

	_harness.expect_float(slider.value, 2.5, "VariableDrivenSlider should sync its initial value from the variable")
	_harness.expect_float(slider.min_value, -3.5, "VariableDrivenSlider should adopt the clamped minimum range")
	_harness.expect_float(slider.max_value, 7.25, "VariableDrivenSlider should adopt the clamped maximum range")
	_harness.expect_float(slider.step, 0.25, "VariableDrivenSlider should preserve the configured step for float variables")

	variable.value = 6.5
	_harness.expect_float(slider.value, 6.5, "VariableDrivenSlider should update when the variable value changes")

	slider.value = -10.0
	_harness.expect_float(variable.value, -3.5, "VariableDrivenSlider should clamp the value written back to the variable")

	variable.clamp_value = false
	_harness.expect_float(slider.min_value, -100.0, "VariableDrivenSlider should restore the default minimum when clamping is disabled")
	_harness.expect_float(slider.max_value, 100.0, "VariableDrivenSlider should restore the default maximum when clamping is disabled")

	slider.queue_free()
	await process_frame

func _test_int_slider_uses_integer_step_and_rounding() -> void:
	var variable: IntVariable = INT_VARIABLE_SCRIPT.new()
	variable.clamp_value = true
	variable.min_value = 0
	variable.max_value = 10
	variable.initial_value = 4

	var slider := HSlider.new()
	slider.set_script(SLIDER_SCRIPT)
	slider.step = 0.1
	slider.set("variable", variable)
	root.add_child(slider)
	await process_frame

	_harness.expect_float(slider.step, 1.0, "VariableDrivenSlider should force a step of 1 for IntVariable bindings")

	slider.value = 3.6
	_harness.expect_int(variable.value, 4, "VariableDrivenSlider should round slider values before writing to IntVariable")

	slider.value = 8.4
	_harness.expect_int(variable.value, 8, "VariableDrivenSlider should continue rounding subsequent IntVariable writes")

	slider.queue_free()
	await process_frame
