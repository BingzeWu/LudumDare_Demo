class_name SignalJumpMovingPlatform
extends SignalJumpPlatformBase

const DEFAULT_TINT := Color(0.96, 0.81, 0.27, 1.0)

@export var move_distance : float = 180.0
@export var move_speed : float = 110.0

var _origin_x : float = 0.0
var _move_direction : float = 1.0

func _init() -> void:
	platform_type = TYPE_YELLOW
	platform_size = Vector2(140.0, 24.0)
	tint = DEFAULT_TINT
	jump_multiplier = 1.0

func apply_spawn_marker(spawn_marker : SignalJumpPlatformSpawnMarker) -> void:
	if spawn_marker == null:
		return
	move_distance = maxf(spawn_marker.move_distance, 0.0)
	move_speed = maxf(spawn_marker.move_speed, 0.0)
	if visible:
		_refresh_motion_state()

func _on_activated() -> void:
	_refresh_motion_state()

func _refresh_motion_state() -> void:
	_origin_x = global_position.x
	_move_direction = 1.0
	set_physics_process(move_distance > 0.0 and move_speed > 0.0)

func _on_deactivated() -> void:
	_origin_x = 0.0
	_move_direction = 1.0
	super._on_deactivated()

func _physics_process(delta : float) -> void:
	if move_distance <= 0.0 or move_speed <= 0.0:
		return

	global_position.x += move_speed * delta * _move_direction
	var min_x := _origin_x - move_distance * 0.5
	var max_x := _origin_x + move_distance * 0.5

	if global_position.x <= min_x:
		global_position.x = min_x
		_move_direction = 1.0
	elif global_position.x >= max_x:
		global_position.x = max_x
		_move_direction = -1.0
