extends Node

const SAVE_PATH := "user://run_save.json"

var _pending_loop_state: Dictionary = {}

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

func save_current_run(loop_state: Dictionary = {}) -> bool:
	var payload := {
		"version": 1,
		"progression": Global.get_progression_save_data() if Global != null else {},
		"party": ProgressionService.get_save_data() if ProgressionService != null and ProgressionService.has_method("get_save_data") else {},
		"loop_state": loop_state.duplicate(true),
		"seen_tutorial_ids": DemoDirector.get_seen_tutorial_ids() if DemoDirector != null and DemoDirector.has_method("get_seen_tutorial_ids") else [],
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Failed to open save path for writing: %s" % SAVE_PATH)
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	return true

func load_current_run() -> bool:
	if not has_save():
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: Failed to open save path for reading: %s" % SAVE_PATH)
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is not Dictionary:
		push_error("SaveManager: Save file is invalid JSON.")
		return false

	var payload: Dictionary = parsed
	if Global != null and Global.has_method("apply_progression_save_data"):
		Global.apply_progression_save_data(payload.get("progression", {}))
	if ProgressionService != null and ProgressionService.has_method("apply_save_data"):
		ProgressionService.apply_save_data(payload.get("party", {}))
	if DemoDirector != null and DemoDirector.has_method("apply_seen_tutorial_ids"):
		DemoDirector.apply_seen_tutorial_ids(Array(payload.get("seen_tutorial_ids", [])))

	_pending_loop_state = Dictionary(payload.get("loop_state", {})).duplicate(true)
	return true

func consume_pending_loop_state() -> Dictionary:
	var state := _pending_loop_state.duplicate(true)
	_pending_loop_state.clear()
	return state

func has_pending_loop_state() -> bool:
	return not _pending_loop_state.is_empty()
