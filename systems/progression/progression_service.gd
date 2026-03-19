extends Node

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var current_seed: int = 0
var party_roster: Array[CharacterData] = []

func _ready() -> void:
	if current_seed == 0:
		seed_from_run(int(Time.get_unix_time_from_system()))
	
	# Load Savannah's data resource immediately when the game boots.
	# (Make sure this path perfectly matches your actual file structure!)	
	var savannah_data = load("res://Units/Data/Savannah/savannah_data.tres") as CharacterData
	
	if savannah_data:
		party_roster.append(savannah_data)

## Public accessors so other scripts don't have to guess array indices
func get_party_roster() -> Array[CharacterData]:
	return party_roster

func get_player_character_data() -> CharacterData:
	if not party_roster.is_empty():
		return party_roster[0]
	return null

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


func print_class_growth_debug_summary(characters: Array[CharacterData], levels_to_simulate: int = 20, simulations_per_class: int = 250) -> void:
	if characters.is_empty():
		print("[ProgressionService] No character entries were provided for growth summary.")
		return

	var level_count := maxi(levels_to_simulate, 0)
	var runs := maxi(simulations_per_class, 1)

	print("[ProgressionService] Growth summary across ", runs, " simulations and ", level_count, " level-ups.")
	for entry in characters:
		if entry == null or entry.class_data == null:
			continue

		var class_info := entry.class_data
		var gains_totals := {
			"MAX_HP": 0.0,
			"STR": 0.0,
			"DEF": 0.0,
			"DEX": 0.0,
			"INT": 0.0,
			"SPD": 0.0,
			"MOV": 0.0,
			"ATK_RNG": 0.0,
		}

		for _run in range(runs):
			var sim_stats := UnitStats.new()
			sim_stats.apply_class_progression(entry)
			var gains := sim_stats.apply_auto_levels(level_count)
			for growth_key in gains_totals.keys():
				gains_totals[growth_key] = float(gains_totals[growth_key]) + float(gains.get(growth_key, 0))

		var average_gains := {}
		for growth_key in gains_totals.keys():
			average_gains[growth_key] = snappedf(float(gains_totals[growth_key]) / runs, 0.01)

		var class_label := class_info.metadata_name if not class_info.metadata_name.is_empty() else entry.display_name
		print("[ProgressionService] ", class_label,
			" | role=", class_info.role,
			" | primary=", class_info.primary_damage_stat,
			" | secondary=", class_info.secondary_stat,
			" | avg gains=", average_gains)
