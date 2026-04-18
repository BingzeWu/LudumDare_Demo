class_name MovingPlatform
extends BasePlatform

@export_group("移动平台参数")
## 左右移动速度，数值越大平台横向位移越快。
@export var move_speed : float = 90.0
## 在编辑器里单独测试时，也按当前视口宽度做整屏往返。
@export var use_viewport_bounds_in_editor : bool = true

var _left_wall_x : float = 0.0
var _right_wall_x : float = 0.0
var _direction : float = 1.0

func _ready() -> void:
	super._ready()
	sync_to_physics = true
	if is_zero_approx(_left_wall_x - _right_wall_x) and use_viewport_bounds_in_editor:
		var viewport_width := get_viewport_rect().size.x
		setup_screen_bounds(0.0, viewport_width, move_speed)

func reset_runtime_state() -> void:
	_left_wall_x = 0.0
	_right_wall_x = 0.0
	_direction = 1.0
	set_physics_process(false)

func setup_screen_bounds(left_wall_x : float, right_wall_x : float, speed : float) -> void:
	_left_wall_x = minf(left_wall_x, right_wall_x)
	_right_wall_x = maxf(left_wall_x, right_wall_x)
	move_speed = speed
	var min_center_x := _left_wall_x + _get_half_width()
	var max_center_x := _right_wall_x - _get_half_width()
	global_position.x = clampf(global_position.x, min_center_x, max_center_x)
	var middle_x := (_left_wall_x + _right_wall_x) * 0.5
	_direction = 1.0 if global_position.x <= middle_x else -1.0
	set_physics_process(_has_movement_room())

func _physics_process(delta : float) -> void:
	if not _has_movement_room():
		return

	global_position.x += _direction * move_speed * delta
	var left_edge_x := global_position.x - _get_half_width()
	var right_edge_x := global_position.x + _get_half_width()
	if left_edge_x <= _left_wall_x:
		_direction = 1.0
	elif right_edge_x >= _right_wall_x:
		_direction = -1.0

func _get_half_width() -> float:
	return platform_size.x * 0.5

func _has_movement_room() -> bool:
	return (_right_wall_x - _left_wall_x) > platform_size.x
