class_name BattleDamagePopup extends Label

const FLOAT_DURATION := 0.55
const FLOAT_DISTANCE := 38.0
const CRIT_DRIFT_X := -10.0
const NORMAL_DRIFT_X := 8.0
const MISS_DRIFT_X := 14.0

var _drift_x := NORMAL_DRIFT_X

func setup_from_strike(strike: CombatStrike) -> void:
	if not strike.is_hit:
		text = "Miss"
		modulate = Color(0.78, 0.82, 0.88)
		scale = Vector2.ONE
		_drift_x = MISS_DRIFT_X
	elif strike.is_crit:
		text = str(strike.damage_dealt) + "!"
		modulate = Color(1.0, 0.84, 0.28)
		scale = Vector2(1.32, 1.32)
		_drift_x = CRIT_DRIFT_X
	else:
		text = str(strike.damage_dealt)
		modulate = Color(1.0, 1.0, 1.0)
		scale = Vector2.ONE
		_drift_x = NORMAL_DRIFT_X

	add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08))
	add_theme_constant_override("outline_size", 5)
	add_theme_font_size_override("font_size", 26)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func play() -> void:
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y - FLOAT_DISTANCE, FLOAT_DURATION)
	tween.tween_property(self, "position:x", position.x + _drift_x, FLOAT_DURATION)
	tween.tween_property(self, "modulate:a", 0.0, FLOAT_DURATION)
	tween.chain().tween_callback(queue_free)
