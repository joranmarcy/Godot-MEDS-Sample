extends SceneTree

const FLOAT_VARIABLE_SCRIPT := preload("res://addons/godot_meds_core/scripts/variables/float-variable.gd")

var _checks: int = 0
var _failures: PackedStringArray = []

func _init() -> void:
	_run_test("defaults_to_initial_value", _test_defaults_to_initial_value)
	_run_test("value_changed_emits_only_on_change", _test_value_changed_emits_only_on_change)
	_run_test("clamp_disabled_preserves_value", _test_clamp_disabled_preserves_value)
	_run_test("clamp_enabled_clamps_initial_and_current_value", _test_clamp_enabled_clamps_initial_and_current_value)
	_run_test("reversed_bounds_are_normalized_for_clamping", _test_reversed_bounds_are_normalized_for_clamping)
	_run_test("range_changed_emits_normalized_bounds", _test_range_changed_emits_normalized_bounds)

	if _failures.is_empty():
		print("FloatVariable tests passed (%d checks)." % _checks)
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	printerr("FloatVariable tests failed (%d/%d checks)." % [_failures.size(), _checks])
	quit(1)

func _run_test(test_name: String, test_callable: Callable) -> void:
	var failure_count_before := _failures.size()
	test_callable.call()
	if _failures.size() == failure_count_before:
		print("PASS %s" % test_name)
	else:
		printerr("FAIL %s" % test_name)

func _test_defaults_to_initial_value() -> void:
	var variable: FloatVariable = FLOAT_VARIABLE_SCRIPT.new()
	_expect_float(variable.value, 0.0, "new FloatVariable should expose the default initial value")

func _test_value_changed_emits_only_on_change() -> void:
	var variable: FloatVariable = FLOAT_VARIABLE_SCRIPT.new()
	var emitted_values: Array[float] = []
	variable.value_changed.connect(func(new_value: float) -> void:
		emitted_values.append(new_value)
	)

	variable.value = 2.5
	variable.value = 2.5
	variable.set_value(-1.25)

	_expect_float(variable.value, -1.25, "set_value should update the stored value")
	_expect_int(emitted_values.size(), 2, "value_changed should only emit when the value actually changes")
	_expect_float(emitted_values[0], 2.5, "value_changed should emit the first assigned value")
	_expect_float(emitted_values[1], -1.25, "value_changed should emit subsequent distinct values")

func _test_clamp_disabled_preserves_value() -> void:
	var variable: FloatVariable = FLOAT_VARIABLE_SCRIPT.new()
	variable.min_value = -1.0
	variable.max_value = 1.0
	variable.clamp_value = false
	variable.value = 5.75

	_expect_float(variable.value, 5.75, "value should not be clamped when clamp_value is false")

func _test_clamp_enabled_clamps_initial_and_current_value() -> void:
	var variable: FloatVariable = FLOAT_VARIABLE_SCRIPT.new()
	variable.clamp_value = true
	variable.min_value = -2.0
	variable.max_value = 1.5
	variable.initial_value = 9.0

	_expect_float(variable.initial_value, 1.5, "initial_value should be sanitized through the clamp range")
	_expect_float(variable.value, 1.5, "current value should track the sanitized initial value")

	variable.value = -6.0
	_expect_float(variable.value, -2.0, "assigned values should be clamped to the lower bound")

func _test_reversed_bounds_are_normalized_for_clamping() -> void:
	var variable: FloatVariable = FLOAT_VARIABLE_SCRIPT.new()
	variable.clamp_value = true
	variable.min_value = 10.0
	variable.max_value = 2.0

	variable.value = 20.0
	_expect_float(variable.value, 10.0, "reversed bounds should still clamp using the normalized upper bound")

	variable.value = -4.0
	_expect_float(variable.value, 2.0, "reversed bounds should still clamp using the normalized lower bound")

func _test_range_changed_emits_normalized_bounds() -> void:
	var variable: FloatVariable = FLOAT_VARIABLE_SCRIPT.new()
	var emitted_ranges: Array[Array] = []
	variable.range_changed.connect(func(clamp_enabled: bool, min_value: float, max_value: float) -> void:
		emitted_ranges.append([clamp_enabled, min_value, max_value])
	)

	variable.clamp_value = true
	variable.min_value = 4.0
	variable.max_value = -3.0

	_expect_int(emitted_ranges.size(), 3, "range_changed should emit for clamp toggle and each bound update")
	_expect_bool(emitted_ranges[2][0], true, "range_changed should report the current clamp state")
	_expect_float(emitted_ranges[2][1], -3.0, "range_changed should emit the normalized minimum value")
	_expect_float(emitted_ranges[2][2], 4.0, "range_changed should emit the normalized maximum value")

func _expect_float(actual: float, expected: float, message: String) -> void:
	_checks += 1
	if not is_equal_approx(actual, expected):
		_failures.append("%s. Expected %s, got %s." % [message, str(expected), str(actual)])

func _expect_int(actual: int, expected: int, message: String) -> void:
	_checks += 1
	if actual != expected:
		_failures.append("%s. Expected %d, got %d." % [message, expected, actual])

func _expect_bool(actual: bool, expected: bool, message: String) -> void:
	_checks += 1
	if actual != expected:
		_failures.append("%s. Expected %s, got %s." % [message, str(expected), str(actual)])