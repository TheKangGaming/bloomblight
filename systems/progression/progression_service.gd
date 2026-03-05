extends Node

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var current_seed: int = 0


func _ready() -> void:
	if current_seed == 0:
		seed_from_run(Time.get_unix_time_from_system())


func seed_from_run(run_seed: int) -> void:
	_set_seed(run_seed)


func seed_from_map(map_seed: int) -> void:
	_set_seed(map_seed)


func seed_from_save(save_seed: int) -> void:
	_set_seed(save_seed)


func roll_growth(chance_percent: int) -> bool:
	var clamped_chance := clampi(chance_percent, 0, 100)
	return rng.randf() < (clamped_chance / 100.0)


func _set_seed(seed_value: int) -> void:
	current_seed = seed_value
	rng.seed = current_seed
