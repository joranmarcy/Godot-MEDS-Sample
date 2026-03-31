extends Node

@export var audio_player: AudioStreamPlayer
@export var health: IntVariable;
@export var min_pitch_scale: float = 1.0
@export var max_pitch_scale: float = 2.0

func _ready() -> void:
	if audio_player != null:
		audio_player.finished.connect(_on_audio_finished)
		if not audio_player.playing:
			audio_player.play()

	if health != null:
		health.value_changed.connect(_on_health_changed)
		health.range_changed.connect(_on_health_range_changed)
		_update_volume_from_health(health.value)


func _on_audio_finished() -> void:
	if audio_player != null:
		audio_player.play()


func _on_health_changed(new_health: int) -> void:
	_update_volume_from_health(new_health)


func _on_health_range_changed(_clamp_enabled: bool, _min_value: int, _max_value: int) -> void:
	if health != null:
		_update_volume_from_health(health.value)


func _update_volume_from_health(current_health: int) -> void:
	if audio_player == null or health == null:
		return

	var min_health := health.min_value
	var max_health := health.max_value
	if min_health == max_health:
		audio_player.volume_db = -80.0
		audio_player.pitch_scale = min_pitch_scale
		return

	var health_ratio := inverse_lerp(float(min_health), float(max_health), float(current_health))
	var inverse_health_ratio := 1.0 - clampf(health_ratio, 0.0, 1.0)
	var volume_percent := (1.0 - clampf(health_ratio, 0.0, 1.0)) * 100.0
	var linear_volume := volume_percent / 100.0

	audio_player.volume_db = -80.0 if linear_volume <= 0.0 else linear_to_db(linear_volume)
	audio_player.pitch_scale = lerpf(min_pitch_scale, max_pitch_scale, inverse_health_ratio)
