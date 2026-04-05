extends SceneTree

const TEST_HARNESS_SCRIPT := preload("res://addons/godot_meds_core/scripts/tests/test_harness.gd")
const BASE_VARIABLE_SCRIPT := preload("res://addons/godot_meds_core/scripts/variables/base-variable.gd")

var _harness := TEST_HARNESS_SCRIPT.new()

func _init() -> void:
	await _harness.run_test("application_start_reset_uses_runtime_cache_across_resource_instances", _test_application_start_reset_uses_runtime_cache_across_resource_instances)
	await _harness.run_test("scene_load_reset_does_not_restore_cached_runtime_value", _test_scene_load_reset_does_not_restore_cached_runtime_value)
	_harness.finish("Runtime cache tests", self)

func _test_application_start_reset_uses_runtime_cache_across_resource_instances() -> void:
	BaseVariable._runtime_value_cache.clear()
	var first_load: IntVariable = ResourceLoader.load(
		"res://samples/resources/robot-health.tres",
		"",
		ResourceLoader.CACHE_MODE_IGNORE
	)
	first_load.reset_on = BaseVariable.RESET_ON_APPLICATION_START
	first_load.set_value(37)

	var second_load: IntVariable = ResourceLoader.load(
		"res://samples/resources/robot-health.tres",
		"",
		ResourceLoader.CACHE_MODE_IGNORE
	)
	second_load.reset_on = BaseVariable.RESET_ON_APPLICATION_START

	_harness.expect_true(first_load != second_load, "runtime cache test should use distinct resource instances")
	_harness.expect_int(second_load.value, 37, "reset_on application start should restore the cached runtime value for the same resource path")

func _test_scene_load_reset_does_not_restore_cached_runtime_value() -> void:
	BaseVariable._runtime_value_cache.clear()
	var first_load: IntVariable = ResourceLoader.load(
		"res://samples/resources/robot-health.tres",
		"",
		ResourceLoader.CACHE_MODE_IGNORE
	)
	first_load.reset_on = BaseVariable.RESET_ON_SCENE_LOAD
	first_load.set_value(12)

	var second_load: IntVariable = ResourceLoader.load(
		"res://samples/resources/robot-health.tres",
		"",
		ResourceLoader.CACHE_MODE_IGNORE
	)
	second_load.reset_on = BaseVariable.RESET_ON_SCENE_LOAD

	_harness.expect_int(second_load.value, int(second_load.initial_value), "reset_on scene load should leave the reloaded resource at its serialized initial value")
