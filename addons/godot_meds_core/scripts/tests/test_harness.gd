extends RefCounted
class_name TestHarness

var checks: int = 0
var failures: PackedStringArray = []

func run_test(test_name: String, test_callable: Callable) -> void:
	var failure_count_before := failures.size()
	await test_callable.call()
	if failures.size() == failure_count_before:
		print("PASS %s" % test_name)
	else:
		printerr("FAIL %s" % test_name)

func expect_true(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append("%s. Expected true, got false." % message)

func expect_bool(actual: bool, expected: bool, message: String) -> void:
	checks += 1
	if actual != expected:
		failures.append("%s. Expected %s, got %s." % [message, str(expected), str(actual)])

func expect_int(actual: int, expected: int, message: String) -> void:
	checks += 1
	if actual != expected:
		failures.append("%s. Expected %d, got %d." % [message, expected, actual])

func expect_float(actual: float, expected: float, message: String) -> void:
	checks += 1
	if not is_equal_approx(actual, expected):
		failures.append("%s. Expected %s, got %s." % [message, str(expected), str(actual)])

func expect_string(actual: String, expected: String, message: String) -> void:
	checks += 1
	if actual != expected:
		failures.append("%s. Expected %s, got %s." % [message, expected, actual])

func expect_color(actual: Color, expected: Color, message: String) -> void:
	checks += 1
	if actual != expected:
		failures.append("%s. Expected %s, got %s." % [message, str(expected), str(actual)])

func expect_vector2(actual: Vector2, expected: Vector2, message: String) -> void:
	checks += 1
	if actual != expected:
		failures.append("%s. Expected %s, got %s." % [message, str(expected), str(actual)])

func expect_vector3(actual: Vector3, expected: Vector3, message: String) -> void:
	checks += 1
	if actual != expected:
		failures.append("%s. Expected %s, got %s." % [message, str(expected), str(actual)])

func finish(suite_name: String, tree: SceneTree) -> void:
	if failures.is_empty():
		print("%s passed (%d checks)." % [suite_name, checks])
		tree.quit(0)
		return

	for failure in failures:
		push_error(failure)
	printerr("%s failed (%d/%d checks)." % [suite_name, failures.size(), checks])
	tree.quit(1)