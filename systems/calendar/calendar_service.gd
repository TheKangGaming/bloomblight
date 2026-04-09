extends Node
# systems/calendar/calendar_service.gd

const DAYS_PER_SEASON := 28
const SEASON_ORDER: Array[StringName] = [Global.SPRING, Global.SUMMER, Global.FALL, Global.WINTER]

# Emitted when a new day officially begins
signal day_changed(new_day: int, encounter_data: Dictionary)

# Hidden encounter schedule. These drive combat beats, but should not be shown as
# public calendar notices unless explicitly surfaced elsewhere.
const HIDDEN_THREAT_CALENDAR: Dictionary = {
	2: {
		"id": &"bandit_warband",
		"display_name": "Bandit Warband",
		"combat_scene": "res://scenes/level/day_two_battle.tscn",
		"difficulty_tier": 1
	}
}

# Public calendar entries shown in the almanac/menu. The demo keeps this empty so
# the Day 2 bandit battle remains a surprise.
const PUBLIC_CALENDAR_ENTRIES: Dictionary = {}

## Returns the encounter data for a specific day. Returns empty dict if peaceful.
func get_encounter_for_day(day: int) -> Dictionary:
	if HIDDEN_THREAT_CALENDAR.has(day):
		return HIDDEN_THREAT_CALENDAR[day].duplicate(true)
	return {}

## Quick boolean check if a day has an attack scheduled
func has_encounter(day: int) -> bool:
	return HIDDEN_THREAT_CALENDAR.has(day)

func get_public_calendar_entries_for_day(day: int) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for entry in PUBLIC_CALENDAR_ENTRIES.get(day, []):
		if entry is Dictionary:
			entries.append((entry as Dictionary).duplicate(true))
	return entries

## Called by the global clock when the day officially advances
func trigger_day_change(new_day: int) -> void:
	var encounter = get_encounter_for_day(new_day)
	day_changed.emit(new_day, encounter)

## Converts world day to a season. Day 1 starts in Spring.
func get_season_for_day(day: int) -> StringName:
	if day <= 0:
		return Global.SPRING

	var season_index := get_season_index_for_day(day)
	return SEASON_ORDER[season_index]

func get_current_season() -> StringName:
	return get_season_for_day(Global.current_day)

func get_season_index_for_day(day: int) -> int:
	if day <= 0:
		return 0
	return int(floor(float(day - 1) / float(DAYS_PER_SEASON))) % SEASON_ORDER.size()

func get_day_in_season(day: int) -> int:
	if day <= 0:
		return 1
	return ((day - 1) % DAYS_PER_SEASON) + 1

func get_current_day_in_season() -> int:
	return get_day_in_season(Global.current_day)

func get_season_start_day(day: int) -> int:
	var safe_day: int = day
	if safe_day <= 0:
		safe_day = 1
	return safe_day - get_day_in_season(safe_day) + 1

func get_season_end_day(day: int) -> int:
	return get_season_start_day(day) + DAYS_PER_SEASON - 1
