extends Node2D

const FOREST_ENTRY_PLAYER_POS := Vector2(2099, 86)
const FOREST_ENTRY_TERA_POS := Vector2(2159, 100)
const FOREST_SILAS_PLAYER_POS := Vector2(2094, 252)
const FOREST_SILAS_TERA_POS := Vector2(2148, 236)
const FOREST_SILAS_POS := Vector2(2246, 224)
const CUTSCENE_GROUP_ZOOM := Vector2(1.62, 1.62)

@onready var player = $Objects/Player
@onready var player_camera: Camera2D = $Objects/Player/Camera2D
@onready var cutscene_camera: Camera2D = $CutsceneCamera
@onready var story_markers: Node = $StoryMarkers
@onready var tera_actor = $Objects/TeraActor
@onready var silas_actor = $Objects/SilasActor
@onready var story_dialogue = $CanvasLayer/StoryDialogueBox
@onready var main_menu = $CanvasLayer/MainMenu

var _overworld_system_menu_scene: PackedScene = preload("res://scenes/ui/menus/overworld_system_menu.tscn")
var _farm_scene_path := "res://scenes/level/game.tscn"
var _overworld_system_menu: Control = null
var _forest_intro_active := false
var _silas_encounter_started := false
var _day_timer_cycle_seconds := 0.0
var _player_camera_default_zoom := Vector2(2, 2)

func _ready() -> void:
	_day_timer_cycle_seconds = $DayTimer.wait_time
	if player_camera != null:
		_player_camera_default_zoom = player_camera.zoom

	_spawn_overworld_system_menu()
	_restore_intro_forest_day_time()

	if Global.pending_intro_forest_visit:
		Global.pending_intro_forest_visit = false
		call_deferred("_begin_intro_forest_visit")
	else:
		tera_actor.visible = false
		silas_actor.visible = false

func _restore_intro_forest_day_time() -> void:
	if Global.intro_forest_day_time_left <= 0.0:
		return

	var restored_time_left := clampf(Global.intro_forest_day_time_left, 1.0, _day_timer_cycle_seconds)
	$DayTimer.start(restored_time_left)
	$DayTimer.wait_time = _day_timer_cycle_seconds
	Global.intro_forest_day_time_left = 0.0

	var hud = get_node_or_null("CanvasLayer/DayTimeHUD")
	if hud and hud.has_method("_update_view"):
		hud._update_view(true)

func _begin_intro_forest_visit() -> void:
	_forest_intro_active = true
	player.can_move = false
	player.direction = Vector2.ZERO
	player.global_position = _marker_pos(&"IntroEntryPlayer", FOREST_ENTRY_PLAYER_POS)
	tera_actor.visible = true
	tera_actor.global_position = _marker_pos(&"IntroEntryTera", FOREST_ENTRY_TERA_POS)
	tera_actor.face_down()
	tera_actor.play_idle()
	silas_actor.visible = false
	_restore_player_camera(false)

	if DemoDirector:
		DemoDirector.show_context_prompt("farm_search_forest")

	await get_tree().process_frame
	player.can_move = true

func _on_silas_encounter_trigger_body_entered(body: Node) -> void:
	if body != player:
		return
	if not _forest_intro_active or _silas_encounter_started:
		return

	_silas_encounter_started = true
	call_deferred("_run_silas_intro_encounter")

func _run_silas_intro_encounter() -> void:
	player.can_move = false
	player.direction = Vector2.ZERO
	player.global_position = _marker_pos(&"SilasEncounterPlayer", FOREST_SILAS_PLAYER_POS)
	tera_actor.visible = true
	tera_actor.global_position = _marker_pos(&"SilasEncounterTera", FOREST_SILAS_TERA_POS)
	tera_actor.face_side(true)
	silas_actor.visible = true
	silas_actor.global_position = _marker_pos(&"SilasEncounterSilas", FOREST_SILAS_POS)
	silas_actor.face_side(false)

	if player.has_method("play_cutscene_shock"):
		player.play_cutscene_shock(Vector2.RIGHT)
	if tera_actor.has_method("play_shocked"):
		tera_actor.play_shocked()
	if silas_actor.has_method("play_bow_aim"):
		silas_actor.play_bow_aim()
	elif silas_actor.has_method("play_attack"):
		silas_actor.play_attack()
	await get_tree().create_timer(0.2).timeout

	await _play_story_dialogue([
		{"speaker": "Silas", "text": "Don't move. I'm not a fan of company."},
		{"speaker": "Savannah", "text": "Easy. We aren't looking for a fight. Lower the bow."},
		{"speaker": "Tera", "text": "We found the old farmstead. We're just looking for seeds."}
	], [player, tera_actor, silas_actor], CUTSCENE_GROUP_ZOOM)

	if silas_actor.has_method("play_idle"):
		silas_actor.play_idle()
	if player.has_method("play_cutscene_idle"):
		player.play_cutscene_idle(Vector2.RIGHT)
	if tera_actor.has_method("play_idle"):
		tera_actor.play_idle()

	await _play_story_dialogue([
		{"speaker": "Silas", "text": "The farm? You're either crazy or you've got a death wish. That soil's been dead for years."},
		{"speaker": "Tera", "text": "We're hungry. We'll take our chances."},
		{"speaker": "Silas", "text": "I've been through these woods every day this month. There's nothing left to grow."},
		{"speaker": "Savannah", "text": "Then you missed a spot."}
	], [player, tera_actor, silas_actor], CUTSCENE_GROUP_ZOOM)

	if silas_actor.has_method("play_impatient"):
		silas_actor.play_impatient()

	await _play_story_dialogue([
		{"speaker": "Silas", "text": "Fine. Take 'em. Ripped those off a dead caravan, they're likely too dry to sprout, anyway. Bury 'em, eat 'em, I don't care. Just get out of my woods."}
	], [player, tera_actor, silas_actor], CUTSCENE_GROUP_ZOOM)

	Global.add_item(Global.Items.CARROT_SEED, 1)
	Global.add_item(Global.Items.PARSNIP_SEED, 1)
	Global.pending_intro_forest_return = true
	Global.intro_forest_day_time_left = $DayTimer.time_left
	TransitionManager.change_scene_path(_farm_scene_path, 0.45)

func _spawn_overworld_system_menu() -> void:
	if _overworld_system_menu != null and is_instance_valid(_overworld_system_menu):
		return
	var canvas_layer := get_node_or_null("CanvasLayer")
	if canvas_layer == null:
		return
	_overworld_system_menu = _overworld_system_menu_scene.instantiate()
	canvas_layer.add_child(_overworld_system_menu)
	if _overworld_system_menu.has_method("setup"):
		_overworld_system_menu.call("setup", main_menu)

func _play_story_dialogue(lines: Array[Dictionary], focus_nodes: Array[Node2D] = [], zoom: Vector2 = CUTSCENE_GROUP_ZOOM) -> void:
	if not focus_nodes.is_empty():
		await _focus_cutscene_on_nodes(focus_nodes, 0.3, zoom)
	story_dialogue.play(lines)
	await story_dialogue.dialogue_finished

func _focus_cutscene_on_nodes(nodes: Array[Node2D], duration: float, zoom: Vector2) -> void:
	var positions: Array[Vector2] = []
	for node in nodes:
		if node != null and is_instance_valid(node):
			positions.append(node.global_position)
	await _focus_cutscene_on_positions(positions, duration, zoom)

func _focus_cutscene_on_positions(positions: Array[Vector2], duration: float, zoom: Vector2) -> void:
	if positions.is_empty():
		return

	var target := Vector2.ZERO
	for point in positions:
		target += point
	target /= float(positions.size())

	if not cutscene_camera.is_current():
		cutscene_camera.position_smoothing_enabled = false
		cutscene_camera.global_position = _get_current_camera_center()
		cutscene_camera.zoom = player_camera.zoom
		if cutscene_camera.has_method("reset_smoothing"):
			cutscene_camera.reset_smoothing()
	cutscene_camera.make_current()
	cutscene_camera.position_smoothing_enabled = true

	var tween = create_tween()
	tween.parallel().tween_property(cutscene_camera, "global_position", target, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(cutscene_camera, "zoom", zoom, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func _restore_player_camera(sync_to_cutscene: bool = false) -> void:
	if player and player.has_method("clear_cutscene_animation"):
		player.clear_cutscene_animation()
	if player_camera:
		if sync_to_cutscene and is_instance_valid(cutscene_camera):
			player_camera.position_smoothing_enabled = false
			player_camera.global_position = cutscene_camera.global_position
			player_camera.zoom = cutscene_camera.zoom
		else:
			player_camera.position_smoothing_enabled = false
			player_camera.global_position = player.global_position
			player_camera.zoom = _player_camera_default_zoom
		if player_camera.has_method("reset_smoothing"):
			player_camera.reset_smoothing()
		player_camera.make_current()
		player_camera.position_smoothing_enabled = true
		player_camera.position_smoothing_speed = 8.0

func _marker_pos(marker_name: StringName, fallback: Vector2) -> Vector2:
	if story_markers == null:
		return fallback
	var marker := story_markers.get_node_or_null(String(marker_name)) as Node2D
	if marker == null:
		return fallback
	return marker.global_position

func _get_current_camera_center() -> Vector2:
	if player_camera and player_camera.is_inside_tree():
		return player_camera.get_screen_center_position()
	return player.global_position
