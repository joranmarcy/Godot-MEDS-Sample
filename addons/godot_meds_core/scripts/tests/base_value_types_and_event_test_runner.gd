extends SceneTree

const TEST_HARNESS_SCRIPT := preload("res://addons/godot_meds_core/scripts/tests/test_harness.gd")
const BOOL_VARIABLE_SCRIPT := preload("res://addons/godot_meds_core/scripts/variables/bool-variable.gd")
const STRING_VARIABLE_SCRIPT := preload("res://addons/godot_meds_core/scripts/variables/string-variable.gd")
const COLOR_VARIABLE_SCRIPT := preload("res://addons/godot_meds_core/scripts/variables/color-variable.gd")
const VECTOR2_VARIABLE_SCRIPT := preload("res://addons/godot_meds_core/scripts/variables/vector2-variable.gd")
const VECTOR3_VARIABLE_SCRIPT := preload("res://addons/godot_meds_core/scripts/variables/vector3-variable.gd")
const EVENT_SCRIPT := preload("res://addons/godot_meds_core/scripts/events/event.gd")

class _EventCounter:
	extends RefCounted

	var raised_count := 0

	func record_raise() -> void:
		raised_count += 1

var _harness := TEST_HARNESS_SCRIPT.new()

func _init() -> void:
	await _harness.run_test("bool_variable_defaults_and_emits_on_change", _test_bool_variable_defaults_and_emits_on_change)
	await _harness.run_test("string_variable_defaults_and_emits_on_change", _test_string_variable_defaults_and_emits_on_change)
	await _harness.run_test("color_variable_defaults_and_emits_on_change", _test_color_variable_defaults_and_emits_on_change)
	await _harness.run_test("vector2_variable_defaults_and_emits_on_change", _test_vector2_variable_defaults_and_emits_on_change)
	await _harness.run_test("vector3_variable_defaults_and_emits_on_change", _test_vector3_variable_defaults_and_emits_on_change)
	await _harness.run_test("event_raise_event_emits_once_per_call", _test_event_raise_event_emits_once_per_call)
	_harness.finish("Base value type and event tests", self)

func _test_bool_variable_defaults_and_emits_on_change() -> void:
	var variable: BoolVariable = BOOL_VARIABLE_SCRIPT.new()
	var emitted_values: Array[bool] = []
	variable.value_changed.connect(func(new_value: bool) -> void:
		emitted_values.append(new_value)
	)

	_harness.expect_bool(variable.value, false, "new BoolVariable should expose the default initial value")

	variable.value = true
	variable.value = true
	variable.set_value(false)

	_harness.expect_bool(variable.value, false, "BoolVariable should keep the most recent value")
	_harness.expect_int(emitted_values.size(), 2, "BoolVariable should only emit when the value actually changes")
	_harness.expect_bool(emitted_values[0], true, "BoolVariable should emit the first assigned value")
	_harness.expect_bool(emitted_values[1], false, "BoolVariable should emit subsequent distinct values")

func _test_string_variable_defaults_and_emits_on_change() -> void:
	var variable: StringVariable = STRING_VARIABLE_SCRIPT.new()
	var emitted_values: Array[String] = []
	variable.value_changed.connect(func(new_value: String) -> void:
		emitted_values.append(new_value)
	)

	_harness.expect_string(variable.value, "", "new StringVariable should expose the default initial value")

	variable.value = "MEDS"
	variable.value = "MEDS"
	variable.set_value("Core")

	_harness.expect_string(variable.value, "Core", "StringVariable should keep the most recent value")
	_harness.expect_int(emitted_values.size(), 2, "StringVariable should only emit when the value actually changes")
	_harness.expect_string(emitted_values[0], "MEDS", "StringVariable should emit the first assigned value")
	_harness.expect_string(emitted_values[1], "Core", "StringVariable should emit subsequent distinct values")

func _test_color_variable_defaults_and_emits_on_change() -> void:
	var variable: ColorVariable = COLOR_VARIABLE_SCRIPT.new()
	var emitted_values: Array[Color] = []
	variable.value_changed.connect(func(new_value: Color) -> void:
		emitted_values.append(new_value)
	)

	_harness.expect_color(variable.value, Color.WHITE, "new ColorVariable should expose the default initial value")

	variable.value = Color(0.1, 0.2, 0.3, 1.0)
	variable.value = Color(0.1, 0.2, 0.3, 1.0)
	variable.set_value(Color(0.9, 0.8, 0.7, 1.0))

	_harness.expect_color(variable.value, Color(0.9, 0.8, 0.7, 1.0), "ColorVariable should keep the most recent value")
	_harness.expect_int(emitted_values.size(), 2, "ColorVariable should only emit when the value actually changes")
	_harness.expect_color(emitted_values[0], Color(0.1, 0.2, 0.3, 1.0), "ColorVariable should emit the first assigned value")
	_harness.expect_color(emitted_values[1], Color(0.9, 0.8, 0.7, 1.0), "ColorVariable should emit subsequent distinct values")

func _test_vector2_variable_defaults_and_emits_on_change() -> void:
	var variable: Vector2Variable = VECTOR2_VARIABLE_SCRIPT.new()
	var emitted_values: Array[Vector2] = []
	variable.value_changed.connect(func(new_value: Vector2) -> void:
		emitted_values.append(new_value)
	)

	_harness.expect_vector2(variable.value, Vector2.ZERO, "new Vector2Variable should expose the default initial value")

	variable.value = Vector2(4.0, -2.0)
	variable.value = Vector2(4.0, -2.0)
	variable.set_value(Vector2(-6.0, 1.5))

	_harness.expect_vector2(variable.value, Vector2(-6.0, 1.5), "Vector2Variable should keep the most recent value")
	_harness.expect_int(emitted_values.size(), 2, "Vector2Variable should only emit when the value actually changes")
	_harness.expect_vector2(emitted_values[0], Vector2(4.0, -2.0), "Vector2Variable should emit the first assigned value")
	_harness.expect_vector2(emitted_values[1], Vector2(-6.0, 1.5), "Vector2Variable should emit subsequent distinct values")

func _test_vector3_variable_defaults_and_emits_on_change() -> void:
	var variable: Vector3Variable = VECTOR3_VARIABLE_SCRIPT.new()
	var emitted_values: Array[Vector3] = []
	variable.value_changed.connect(func(new_value: Vector3) -> void:
		emitted_values.append(new_value)
	)

	_harness.expect_vector3(variable.value, Vector3.ZERO, "new Vector3Variable should expose the default initial value")

	variable.value = Vector3(4.0, -2.0, 9.0)
	variable.value = Vector3(4.0, -2.0, 9.0)
	variable.set_value(Vector3(-6.0, 1.5, 0.5))

	_harness.expect_vector3(variable.value, Vector3(-6.0, 1.5, 0.5), "Vector3Variable should keep the most recent value")
	_harness.expect_int(emitted_values.size(), 2, "Vector3Variable should only emit when the value actually changes")
	_harness.expect_vector3(emitted_values[0], Vector3(4.0, -2.0, 9.0), "Vector3Variable should emit the first assigned value")
	_harness.expect_vector3(emitted_values[1], Vector3(-6.0, 1.5, 0.5), "Vector3Variable should emit subsequent distinct values")

func _test_event_raise_event_emits_once_per_call() -> void:
	var event_resource: Event = EVENT_SCRIPT.new()
	var counter := _EventCounter.new()
	event_resource.connect("event_raised", Callable(counter, "record_raise"))

	event_resource.raise_event()
	event_resource.raise_event()

	_harness.expect_int(counter.raised_count, 2, "Event.raise_event should emit exactly once per call")
