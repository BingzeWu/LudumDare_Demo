class_name SignalJumpGame
extends Node2D

signal level_lost

@export var player_spawn_offset_from_platform : float = 96.0
@export var player_death_margin_below_camera : float = 120.0

@export_group("Debug")
@export var debug_log_enabled : bool = true
@export var debug_log_interval : float = 2.0

var _debug_log_timer : float = 0.0
var _is_player_dead : bool = false

@onready var background : ColorRect = $BackgroundLayer/Background
@onready var content_generator : SignalJumpContentGenerator = $ContentGenerator
@onready var platform_pool : SignalJumpPlatformPool = $Platforms
@onready var pickup_pool : SignalJumpPickupPool = $Pickups
@onready var player : SignalJumpPlayer = $Player

func _ready() -> void:
	_setup_scene()

func _physics_process(delta : float) -> void:
	_check_player_state(delta)
	_update_debug_logging(delta)

func _setup_scene() -> void:
	background.size = get_viewport_rect().size
	var spawn_position := Vector2(get_viewport_rect().size.x * 0.5, get_viewport_rect().size.y * 0.75)
	_is_player_dead = false

	if content_generator != null:
		player.set_wrap_world_width(content_generator.world_width)
		spawn_position = content_generator.get_player_spawn_position(player_spawn_offset_from_platform)
	else:
		player.set_wrap_world_width(get_viewport_rect().size.x)

	player.reset(spawn_position)

	if content_generator != null:
		content_generator.reset_content()

func _check_player_state(_delta : float) -> void:
	if _is_player_dead or player == null or player.camera == null:
		return

	var death_threshold_y : float = _get_camera_bottom_y() + player_death_margin_below_camera
	if player.global_position.y <= death_threshold_y:
		return

	_is_player_dead = true
	level_lost.emit()

func _update_debug_logging(delta : float) -> void:
	if not debug_log_enabled:
		return

	_debug_log_timer += delta
	if _debug_log_timer < debug_log_interval:
		return

	_debug_log_timer = 0.0
	_print_debug_snapshot()

func _print_debug_snapshot() -> void:
	var player_position := _format_vector(player.global_position)
	var signal_summary := player.get_signal_debug_summary()
	var generator_summary := "none"
	var platform_summary := platform_pool.get_debug_summary()
	var pickup_summary := pickup_pool.get_debug_summary()

	if content_generator != null:
		generator_summary = content_generator.get_debug_summary()

	print(
		"[SignalJumpDebug] player=", player_position,
		" | signal=", signal_summary,
		" | dead=", _is_player_dead,
		" | generator=", generator_summary,
		" | platforms=", platform_summary,
		" | pickups=", pickup_summary
	)

func _get_camera_bottom_y() -> float:
	var camera_half_height : float = get_viewport_rect().size.y * 0.5 * player.camera.zoom.y
	return player.camera.global_position.y + camera_half_height

func _format_vector(value : Vector2) -> String:
	return "(%.1f, %.1f)" % [value.x, value.y]
