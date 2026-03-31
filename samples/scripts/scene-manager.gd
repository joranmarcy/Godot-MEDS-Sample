extends Node

@export var health: IntVariable
@export_file("*.tscn") var death_scene_path: String

var _is_transitioning := false


func _ready() -> void:
	if health != null:
		health.value_changed.connect(_on_health_changed)
		_on_health_changed(health.value)


func _on_health_changed(new_health: int) -> void:
	if new_health > 0 or _is_transitioning or death_scene_path.is_empty():
		return

	_is_transitioning = true
	call_deferred("_change_scene", death_scene_path)


func _change_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)

