extends Resource
class_name BoolVariable

@export var prefs_key: String = "bool_variable"
@export var prefs_file_path: String = "user://player_prefs.cfg"
@export var default_value: bool = false

var _value: bool = false

@export var value: bool:
	set(new_value):
		set_value(new_value)
	get:
		return _value

func _init():
	_value = default_value
	_load_from_prefs()

func set_value(new_value: bool) -> void:
	if _value == new_value:
		return
	_value = new_value
	_save_to_prefs()

func get_value() -> bool:
	return _value

func _load_from_prefs() -> void:
	var config := ConfigFile.new()
	var err := config.load(prefs_file_path)
	if err == OK and config.has_section_key("player_prefs", prefs_key):
		_value = config.get_value("player_prefs", prefs_key, default_value)
	elif err != OK:
		# Missing file is fine; we keep default and create on first save.
		pass

func _save_to_prefs() -> void:
	var config := ConfigFile.new()
	var err := config.load(prefs_file_path)
	if err != OK:
		config = ConfigFile.new()
	config.set_value("player_prefs", prefs_key, _value)
	config.save(prefs_file_path)
	
