extends Object
class_name VariableRuntimeReporter


static func report(variable: Resource, value: Variant) -> void:
	if variable == null:
		return

	# Only report when running with an active debugger connection.
	if not EngineDebugger.is_active():
		return

	var path := ""
	if variable.resource_path != null:
		path = String(variable.resource_path)

	var id := path
	if id == "":
		id = str(variable.get_instance_id())

	var name := ""
	if path != "":
		name = path.get_file()
	else:
		name = String(variable.resource_name)
		if name == "":
			name = id

	var payload: Dictionary = {
		"id": id,
		"path": path,
		"name": name,
		"type": variable.get_class(),
		"value_str": str(value),
		"ticks_msec": Time.get_ticks_msec(),
	}

	EngineDebugger.send_message("variable_values:update", [payload])
