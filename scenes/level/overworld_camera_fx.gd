extends Node
class_name OverworldCameraFx

var _active_tween: Tween = null

func play_shake(camera: Camera2D, intensity: float = 4.0, duration: float = 0.16) -> Tween:
	if camera == null:
		return null
	if SettingsManager != null and not SettingsManager.is_screen_shake_enabled():
		return null

	if _active_tween != null and is_instance_valid(_active_tween):
		_active_tween.kill()

	var base_offset: Vector2 = camera.offset
	var step_time: float = max(duration / 4.0, 0.01)
	_active_tween = create_tween()
	_active_tween.tween_property(camera, "offset", base_offset + Vector2(intensity, -intensity * 0.28), step_time)
	_active_tween.tween_property(camera, "offset", base_offset + Vector2(-intensity * 0.72, intensity * 0.18), step_time)
	_active_tween.tween_property(camera, "offset", base_offset + Vector2(intensity * 0.42, intensity * 0.12), step_time)
	_active_tween.tween_property(camera, "offset", base_offset, step_time)
	return _active_tween
