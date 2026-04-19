class_name SignalJumpPlatformPool
extends Node2D

const GREEN_PLATFORM_SCENE := preload("res://scenes/game_scene/signal_jump/platforms/constant_platform.tscn")
const BLUE_PLATFORM_SCENE := preload("res://scenes/game_scene/signal_jump/platforms/blue_platform.tscn")
const RED_PLATFORM_SCENE := preload("res://scenes/game_scene/signal_jump/platforms/red_platform.tscn")
const MOVING_PLATFORM_SCENE := preload("res://scenes/game_scene/signal_jump/platforms/moving_platform.tscn")
const FRAGILE_PLATFORM_SCENE := preload("res://scenes/game_scene/signal_jump/platforms/fragile_platform.tscn")
const SPRING_PLATFORM_SCENE := preload("res://scenes/game_scene/signal_jump/platforms/spring_platform.tscn")

var _pool_by_type : Dictionary = {}

func spawn_platform(platform_type : String, platform_position : Vector2, spawn_marker : SignalJumpPlatformSpawnMarker = null) -> SignalJumpPlatformBase:
	var key := _normalize_platform_type(platform_type)
	var pool := _get_pool_for_type(key)
	var platform : SignalJumpPlatformBase

	if not pool.is_empty():
		platform = pool.pop_back()
	else:
		platform = _instantiate_platform(key)

	if platform == null:
		return null

	platform.apply_spawn_marker(spawn_marker)
	platform.activate(platform_position)
	return platform

func recycle_platform(platform : Node2D) -> void:
	var typed_platform := platform as SignalJumpPlatformBase
	if typed_platform == null or not is_instance_valid(typed_platform):
		return

	var key := _normalize_platform_type(typed_platform.get_pool_type())
	var pool := _get_pool_for_type(key)
	if pool.has(typed_platform):
		return

	typed_platform.deactivate()
	pool.append(typed_platform)

func get_debug_summary() -> String:
	var active_entries : Array[String] = []
	var pooled_count : int = 0

	for child in get_children():
		var platform := child as SignalJumpPlatformBase
		if platform == null:
			continue
		if _is_platform_pooled(platform):
			continue
		active_entries.append("%s@%s" % [platform.get_debug_label(), _format_vector(platform.global_position)])

	for pool in _pool_by_type.values():
		pooled_count += (pool as Array).size()

	return "active=%d pooled=%d [%s]" % [
		active_entries.size(),
		pooled_count,
		", ".join(active_entries),
	]

func _instantiate_platform(platform_type : String) -> SignalJumpPlatformBase:
	var scene := _get_scene_for_type(platform_type)
	if scene == null:
		return null

	var platform := scene.instantiate() as SignalJumpPlatformBase
	if platform == null:
		return null

	add_child(platform)
	platform.deactivate()
	return platform

func _get_scene_for_type(platform_type : String) -> PackedScene:
	match platform_type:
		SignalJumpPlatformBase.TYPE_GREEN:
			return GREEN_PLATFORM_SCENE
		SignalJumpPlatformBase.TYPE_BLUE:
			return BLUE_PLATFORM_SCENE
		SignalJumpPlatformBase.TYPE_RED:
			return RED_PLATFORM_SCENE
		SignalJumpPlatformBase.TYPE_YELLOW:
			return MOVING_PLATFORM_SCENE
		SignalJumpPlatformBase.TYPE_WHITE:
			return FRAGILE_PLATFORM_SCENE
		SignalJumpPlatformBase.TYPE_ORANGE:
			return SPRING_PLATFORM_SCENE
		_:
			return GREEN_PLATFORM_SCENE

func _get_pool_for_type(platform_type : String) -> Array:
	if not _pool_by_type.has(platform_type):
		_pool_by_type[platform_type] = []
	return _pool_by_type[platform_type]

func _normalize_platform_type(platform_type : String) -> String:
	if platform_type.is_empty():
		return SignalJumpPlatformBase.TYPE_GREEN
	if not _is_known_platform_type(platform_type):
		return SignalJumpPlatformBase.TYPE_GREEN
	return platform_type

func _is_platform_pooled(platform : SignalJumpPlatformBase) -> bool:
	for pool in _pool_by_type.values():
		if (pool as Array).has(platform):
			return true
	return false

func _is_known_platform_type(platform_type : String) -> bool:
	return platform_type == SignalJumpPlatformBase.TYPE_GREEN \
		or platform_type == SignalJumpPlatformBase.TYPE_BLUE \
		or platform_type == SignalJumpPlatformBase.TYPE_RED \
		or platform_type == SignalJumpPlatformBase.TYPE_YELLOW \
		or platform_type == SignalJumpPlatformBase.TYPE_WHITE \
		or platform_type == SignalJumpPlatformBase.TYPE_ORANGE

func _format_vector(value : Vector2) -> String:
	return "(%.1f, %.1f)" % [value.x, value.y]
