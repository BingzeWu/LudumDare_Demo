class_name SignalJumpContentGenerator
extends Node

const BASE_CHUNK_SCENE := preload("res://scenes/game_scene/signal_jump/chunks/base_chunk.tscn")
const OPENING_CHUNK_SCENE := preload("res://scenes/game_scene/signal_jump/chunks/signal_warmup_chunk.tscn")
const RELAY_STAIR_CHUNK_SCENE := preload("res://scenes/game_scene/signal_jump/chunks/relay_stair_chunk.tscn")
const CROSSWIND_BRIDGE_CHUNK_SCENE := preload("res://scenes/game_scene/signal_jump/chunks/crosswind_bridge_chunk.tscn")
const DRIFT_LANE_CHUNK_SCENE := preload("res://scenes/game_scene/signal_jump/chunks/drift_lane_chunk.tscn")
const SPRING_LADDER_CHUNK_SCENE := preload("res://scenes/game_scene/signal_jump/chunks/spring_ladder_chunk.tscn")
const INTERFERENCE_GATE_CHUNK_SCENE := preload("res://scenes/game_scene/signal_jump/chunks/interference_gate_chunk.tscn")
const FRAGILE_ARC_CHUNK_SCENE := preload("res://scenes/game_scene/signal_jump/chunks/fragile_arc_chunk.tscn")
const ZIGZAG_TRIAL_CHUNK_SCENE := preload("res://scenes/game_scene/signal_jump/chunks/zigzag_trial_chunk.tscn")
const REDLINE_ECHO_CHUNK_SCENE := preload("res://scenes/game_scene/signal_jump/chunks/redline_echo_chunk.tscn")
const OSCILLATION_GAUNTLET_CHUNK_SCENE := preload("res://scenes/game_scene/signal_jump/chunks/oscillation_gauntlet_chunk.tscn")

const EASY_CHUNK_SCENES : Array[PackedScene] = [
	OPENING_CHUNK_SCENE,
	BASE_CHUNK_SCENE,
	RELAY_STAIR_CHUNK_SCENE,
	CROSSWIND_BRIDGE_CHUNK_SCENE,
]

const MID_CHUNK_SCENES : Array[PackedScene] = [
	DRIFT_LANE_CHUNK_SCENE,
	SPRING_LADDER_CHUNK_SCENE,
	INTERFERENCE_GATE_CHUNK_SCENE,
]

const HARD_CHUNK_SCENES : Array[PackedScene] = [
	FRAGILE_ARC_CHUNK_SCENE,
	ZIGZAG_TRIAL_CHUNK_SCENE,
	REDLINE_ECHO_CHUNK_SCENE,
	OSCILLATION_GAUNTLET_CHUNK_SCENE,
]

@export_group("Dependencies")
@export var player_path : NodePath
@export var platform_pool_path : NodePath
@export var pickup_pool_path : NodePath

@export_group("Layout")
@export var world_width : float = 720.0
@export var base_platform_y : float = 1140.0
@export var spawn_buffer_height : float = 720.0
@export var recycle_margin_below_camera : float = 120.0
@export var platform_spawn_horizontal_margin : float = 84.0
@export var initial_chunk_scene : PackedScene = OPENING_CHUNK_SCENE

@export_group("Chunk Difficulty")
@export var medium_chunk_height_threshold : float = 1800.0
@export var hard_chunk_height_threshold : float = 4200.0

@export_group("Pickups")
@export var pickup_radius : float = 18.0
@export var pickup_color : Color = Color(0.98, 0.79, 0.27, 1.0)

var _active_platforms : Array[SignalJumpPlatformBase] = []
var _active_pickups : Array[SignalJumpBasicPickup] = []
var _is_initialized : bool = false
var _rng := RandomNumberGenerator.new()
var _next_chunk_spawn_y : float = 0.0
var _last_generated_chunk_name : String = "none"

var _player : SignalJumpPlayer
var _platform_pool : SignalJumpPlatformPool
var _pickup_pool : SignalJumpPickupPool

func _ready() -> void:
	_rng.randomize()
	_resolve_dependencies()

func _physics_process(_delta : float) -> void:
	if not _is_runtime_ready():
		return

	_recycle_platforms_below_camera()
	_recycle_pickups_below_camera()
	_fill_chunk_buffer()

func reset_content() -> void:
	_resolve_dependencies()
	_clear_active_content()

	if not _has_required_dependencies():
		_is_initialized = false
		return

	_next_chunk_spawn_y = base_platform_y
	_last_generated_chunk_name = "none"
	_spawn_initial_chunk()
	_fill_chunk_buffer()
	_is_initialized = true

func clear_content() -> void:
	_clear_active_content()
	_is_initialized = false

func get_player_spawn_position(player_spawn_offset_from_platform : float) -> Vector2:
	var base_platform_position := get_base_platform_position()
	return Vector2(base_platform_position.x, base_platform_position.y - player_spawn_offset_from_platform)

func get_base_platform_position() -> Vector2:
	return Vector2(world_width * 0.5, base_platform_y)

func get_active_platforms() -> Array[SignalJumpPlatformBase]:
	return _active_platforms.duplicate()

func get_debug_summary() -> String:
	var lowest_platform := _get_lowest_platform()
	var highest_platform := _get_highest_platform()
	var lowest_text := "none"
	var highest_text := "none"
	var window_text := "n/a"

	if lowest_platform != null:
		lowest_text = _format_vector(lowest_platform.global_position)
	if highest_platform != null:
		highest_text = _format_vector(highest_platform.global_position)
	if _player != null:
		window_text = "[%.1f, %.1f]" % [_get_target_top_y(), _get_camera_top_y()]

	return "platforms=%d pickups=%d lowest=%s highest=%s window=%s next_chunk_y=%.1f last_chunk=%s" % [
		_active_platforms.size(),
		_active_pickups.size(),
		lowest_text,
		highest_text,
		window_text,
		_next_chunk_spawn_y,
		_last_generated_chunk_name,
	]

func _resolve_dependencies() -> void:
	_player = get_node_or_null(player_path) as SignalJumpPlayer
	_platform_pool = get_node_or_null(platform_pool_path) as SignalJumpPlatformPool
	_pickup_pool = get_node_or_null(pickup_pool_path) as SignalJumpPickupPool

func _is_runtime_ready() -> bool:
	return _is_initialized and _has_required_dependencies()

func _has_required_dependencies() -> bool:
	return _player != null and _platform_pool != null

func _spawn_initial_chunk() -> void:
	_spawn_chunk(_get_initial_chunk_scene())

func _fill_chunk_buffer() -> void:
	var target_top_y : float = _get_target_top_y()
	var safety_counter : int = 0

	while _next_chunk_spawn_y > target_top_y and safety_counter < 64:
		_spawn_chunk(_get_random_chunk_scene())
		safety_counter += 1

func _get_random_chunk_scene() -> PackedScene:
	var height_progress := _get_height_progress()
	if height_progress < medium_chunk_height_threshold:
		return _pick_chunk_from_pool(EASY_CHUNK_SCENES, OPENING_CHUNK_SCENE)
	if height_progress < hard_chunk_height_threshold:
		if _rng.randf() < 0.30:
			return _pick_chunk_from_pool(EASY_CHUNK_SCENES, OPENING_CHUNK_SCENE)
		return _pick_chunk_from_pool(MID_CHUNK_SCENES, OPENING_CHUNK_SCENE)

	var roll := _rng.randf()
	if roll < 0.15:
		return _pick_chunk_from_pool(EASY_CHUNK_SCENES, OPENING_CHUNK_SCENE)
	if roll < 0.50:
		return _pick_chunk_from_pool(MID_CHUNK_SCENES, OPENING_CHUNK_SCENE)
	return _pick_chunk_from_pool(HARD_CHUNK_SCENES, OPENING_CHUNK_SCENE)

func _spawn_chunk(chunk_scene : PackedScene) -> void:
	if chunk_scene == null:
		return

	var chunk := chunk_scene.instantiate() as Node2D
	if chunk == null:
		return

	var chunk_origin := Vector2(world_width * 0.5, _next_chunk_spawn_y)
	_spawn_chunk_platforms(chunk, chunk_origin)
	_spawn_chunk_pickups(chunk, chunk_origin)
	_update_next_chunk_spawn_y(chunk, chunk_origin)
	_last_generated_chunk_name = chunk.name
	chunk.free()

func _spawn_chunk_platforms(chunk : Node2D, chunk_origin : Vector2) -> void:
	var spawn_root := chunk.get_node_or_null("PlatformSpawns")
	if spawn_root == null:
		return

	for child in spawn_root.get_children():
		var marker := child as Node2D
		if marker == null:
			continue

		var typed_marker := marker as SignalJumpPlatformSpawnMarker
		var platform_type := SignalJumpPlatformBase.TYPE_GREEN
		if typed_marker != null:
			platform_type = typed_marker.platform_type

		var spawn_position := _get_platform_spawn_position(chunk_origin, marker, typed_marker)
		var platform := _platform_pool.spawn_platform(platform_type, spawn_position, typed_marker)
		if platform == null:
			continue
		if not platform.recycle_requested.is_connected(_on_platform_recycle_requested):
			platform.recycle_requested.connect(_on_platform_recycle_requested)
		_active_platforms.append(platform)

func _spawn_chunk_pickups(chunk : Node2D, chunk_origin : Vector2) -> void:
	if _pickup_pool == null:
		return

	var spawn_root := chunk.get_node_or_null("PickupSpawns")
	if spawn_root == null:
		return

	for child in spawn_root.get_children():
		var marker := child as Node2D
		if marker == null:
			continue

		var pickup := _pickup_pool.acquire_pickup()
		pickup.activate(chunk_origin + marker.position, pickup_radius, pickup_color)
		_active_pickups.append(pickup)

func _update_next_chunk_spawn_y(chunk : Node2D, chunk_origin : Vector2) -> void:
	var chunk_end := chunk.get_node_or_null("ChunkEnd") as Node2D
	if chunk_end == null:
		_next_chunk_spawn_y -= 320.0
		return

	_next_chunk_spawn_y = chunk_origin.y + chunk_end.position.y

func _recycle_platforms_below_camera() -> void:
	var recycle_threshold_y : float = _get_camera_bottom_y() + recycle_margin_below_camera

	for index in range(_active_platforms.size() - 1, -1, -1):
		var platform := _active_platforms[index]
		if not is_instance_valid(platform):
			_active_platforms.remove_at(index)
			continue

		if platform.global_position.y <= recycle_threshold_y:
			continue

		_platform_pool.recycle_platform(platform)
		_active_platforms.remove_at(index)

func _recycle_pickups_below_camera() -> void:
	if _pickup_pool == null:
		return

	var recycle_threshold_y : float = _get_camera_bottom_y() + recycle_margin_below_camera

	for index in range(_active_pickups.size() - 1, -1, -1):
		var pickup := _active_pickups[index]
		if not is_instance_valid(pickup):
			_active_pickups.remove_at(index)
			continue

		if pickup.global_position.y <= recycle_threshold_y:
			continue

		_pickup_pool.recycle_pickup(pickup)
		_active_pickups.remove_at(index)

func _clear_active_content() -> void:
	if _platform_pool != null:
		for index in range(_active_platforms.size() - 1, -1, -1):
			var platform := _active_platforms[index]
			if not is_instance_valid(platform):
				continue
			_platform_pool.recycle_platform(platform)

	if _pickup_pool != null:
		for index in range(_active_pickups.size() - 1, -1, -1):
			var pickup := _active_pickups[index]
			if not is_instance_valid(pickup):
				continue
			_pickup_pool.recycle_pickup(pickup)

	_active_platforms.clear()
	_active_pickups.clear()
	_next_chunk_spawn_y = base_platform_y
	_last_generated_chunk_name = "none"

func _get_lowest_platform() -> SignalJumpPlatformBase:
	var result : SignalJumpPlatformBase = null

	for platform in _active_platforms:
		if not is_instance_valid(platform):
			continue
		if result == null or platform.global_position.y > result.global_position.y:
			result = platform

	return result

func _get_highest_platform() -> SignalJumpPlatformBase:
	var result : SignalJumpPlatformBase = null

	for platform in _active_platforms:
		if not is_instance_valid(platform):
			continue
		if result == null or platform.global_position.y < result.global_position.y:
			result = platform

	return result

func _get_target_top_y() -> float:
	return _get_camera_top_y() - spawn_buffer_height

func _get_camera_top_y() -> float:
	var camera_half_height : float = _get_camera_half_height()
	return _player.camera.global_position.y - camera_half_height

func _get_camera_bottom_y() -> float:
	var camera_half_height : float = _get_camera_half_height()
	return _player.camera.global_position.y + camera_half_height

func _get_camera_half_height() -> float:
	return get_viewport().get_visible_rect().size.y * 0.5 * _player.camera.zoom.y

func _format_vector(value : Vector2) -> String:
	return "(%.1f, %.1f)" % [value.x, value.y]

func _get_height_progress() -> float:
	return maxf(0.0, base_platform_y - _next_chunk_spawn_y)

func _pick_chunk_from_pool(pool : Array[PackedScene], fallback : PackedScene) -> PackedScene:
	if pool.is_empty():
		return fallback
	return pool[_rng.randi_range(0, pool.size() - 1)]

func _get_initial_chunk_scene() -> PackedScene:
	if initial_chunk_scene != null:
		return initial_chunk_scene
	return OPENING_CHUNK_SCENE

func _get_platform_spawn_position(chunk_origin : Vector2, marker : Node2D, typed_marker : SignalJumpPlatformSpawnMarker) -> Vector2:
	var spawn_position := chunk_origin + marker.position
	if typed_marker != null and typed_marker.randomize_x and typed_marker.x_random_range > 0.0:
		spawn_position.x += _rng.randf_range(-typed_marker.x_random_range, typed_marker.x_random_range)

	var min_x := platform_spawn_horizontal_margin
	var max_x := world_width - platform_spawn_horizontal_margin
	spawn_position.x = clampf(spawn_position.x, min_x, max_x)
	return spawn_position

func _on_platform_recycle_requested(platform : SignalJumpPlatformBase) -> void:
	if platform == null or not is_instance_valid(platform):
		return

	for index in range(_active_platforms.size() - 1, -1, -1):
		if _active_platforms[index] != platform:
			continue
		_active_platforms.remove_at(index)
		break

	if _platform_pool != null:
		_platform_pool.recycle_platform(platform)
