extends SceneTree

const INT_VARIABLE_SCRIPT := preload("res://addons/godot_meds_core/scripts/variables/int-variable.gd")
const TEST_HARNESS_SCRIPT := preload("res://addons/godot_meds_core/scripts/tests/test_harness.gd")

var _harness := TEST_HARNESS_SCRIPT.new()

func _init() -> void:
	await _harness.run_test("defaults_to_initial_value", _test_defaults_to_initial_value)
	await _harness.run_test("value_changed_emits_only_on_change", _test_value_changed_emits_only_on_change)
	await _harness.run_test("clamp_disabled_preserves_value", _test_clamp_disabled_preserves_value)
	await _harness.run_test("clamp_enabled_clamps_initial_and_current_value", _test_clamp_enabled_clamps_initial_and_current_value)
	await _harness.run_test("reversed_bounds_are_normalized_for_clamping", _test_reversed_bounds_are_normalized_for_clamping)
	await _harness.run_test("range_changed_emits_normalized_bounds", _test_range_changed_emits_normalized_bounds)
	_harness.finish("IntVariable tests", self)

func _test_defaults_to_initial_value() -> void:
	var variable: IntVariable = INT_VARIABLE_SCRIPT.new()
	_harness.expect_int(variable.value, 0, "new IntVariable should expose the default initial value")

func _test_value_changed_emits_only_on_change() -> void:
	var variable: IntVariable = INT_VARIABLE_SCRIPT.new()
	var emitted_values: Array[int] = []
	variable.value_changed.connect(func(new_value: int) -> void:
		emitted_values.append(new_value)
	)

	variable.value = 2
	variable.value = 2
	variable.set_value(-1)

	_harness.expect_int(variable.value, -1, "set_value should update the stored value")
	_harness.expect_int(emitted_values.size(), 2, "value_changed should only emit when the value actually changes")
	_harness.expect_int(emitted_values[0], 2, "value_changed should emit the first assigned value")
	_harness.expect_int(emitted_values[1], -1, "value_changed should emit subsequent distinct values")

func _test_clamp_disabled_preserves_value() -> void:
	var variable: IntVariable = INT_VARIABLE_SCRIPT.new()
	variable.min_value = -1
	variable.max_value = 1
	variable.clamp_value = false
	variable.value = 6

	_harness.expect_int(variable.value, 6, "value should not be clamped when clamp_value is false")

func _test_clamp_enabled_clamps_initial_and_current_value() -> void:
	var variable: IntVariable = INT_VARIABLE_SCRIPT.new()
	variable.clamp_value = true
	variable.min_value = -2
	variable.max_value = 1
	variable.initial_value = 9

	_harness.expect_int(variable.initial_value, 1, "initial_value should be sanitized through the clamp range")
	_harness.expect_int(variable.value, 1, "current value should track the sanitized initial value")

	variable.value = -6
	_harness.expect_int(variable.value, -2, "assigned values should be clamped to the lower bound")

func _test_reversed_bounds_are_normalized_for_clamping() -> void:
	var variable: IntVariable = INT_VARIABLE_SCRIPT.new()
	variable.clamp_value = true
	variable.min_value = 10
	variable.max_value = 2

	variable.value = 20
	_harness.expect_int(variable.value, 10, "reversed bounds should still clamp using the normalized upper bound")

	variable.value = -4
	_harness.expect_int(variable.value, 2, "reversed bounds should still clamp using the normalized lower bound")

func _test_range_changed_emits_normalized_bounds() -> void:
	var variable: IntVariable = INT_VARIABLE_SCRIPT.new()
	var emitted_ranges: Array[Array] = []
	variable.range_changed.connect(func(clamp_enabled: bool, min_value: int, max_value: int) -> void:
		emitted_ranges.append([clamp_enabled, min_value, max_value])
	)

	variable.clamp_value = true
	variable.min_value = 4
	variable.max_value = -3

	_harness.expect_int(emitted_ranges.size(), 3, "range_changed should emit for clamp toggle and each bound update")
	_harness.expect_bool(emitted_ranges[2][0], true, "range_changed should report the current clamp state")
	_harness.expect_int(emitted_ranges[2][1], -3, "range_changed should emit the normalized minimum value")
	_harness.expect_int(emitted_ranges[2][2], 4, "range_changed should emit the normalized maximum value")