class_name JumperPlayer
extends CharacterBody2D

signal bounced(platform : BasePlatform)

@export_group("移动")
@export var move_speed : float = 340.0
@export var horizontal_acceleration : float = 2200.0
@export var wrap_margin : float = 32.0

@export_group("跳跃")
@export var gravity : float = 1500.0
@export var max_fall_speed : float = 900.0
@export var jump_velocity : float = -760.0

@export_group("道具")
@export var default_rocket_velocity : float = -1200.0
@export var default_rocket_duration : float = 1.35

var controls_enabled : bool = true
var _world_width : float = 720.0
var _rocket_timer : float = 0.0
var _rocket_velocity : float = -1200.0
var _stored_collision_mask : int = 0

func _ready() -> void:
	_stored_collision_mask = collision_mask

func set_world_width(value : float) -> void:
	_world_width = value

func reset(start_position : Vector2) -> void:
	global_position = start_position
	velocity = Vector2.ZERO
	controls_enabled = true
	_rocket_timer = 0.0
	collision_mask = _stored_collision_mask
	set_physics_process(true)

func disable() -> void:
	controls_enabled = false
	velocity = Vector2.ZERO
	set_physics_process(false)

func trigger_spring(new_jump_velocity : float) -> void:
	velocity.y = min(velocity.y, new_jump_velocity)

func trigger_rocket(new_rocket_velocity : float = default_rocket_velocity, duration : float = default_rocket_duration) -> void:
	_rocket_velocity = new_rocket_velocity
	_rocket_timer = max(_rocket_timer, duration)
	velocity.y = _rocket_velocity
	collision_mask = 0

func _physics_process(delta : float) -> void:
	var axis := 0.0
	if controls_enabled:
		axis = Input.get_axis("move_left", "move_right")

	velocity.x = move_toward(velocity.x, axis * move_speed, horizontal_acceleration * delta)

	if _rocket_timer > 0.0:
		_rocket_timer = max(0.0, _rocket_timer - delta)
		velocity.y = _rocket_velocity
		if _rocket_timer <= 0.0:
			collision_mask = _stored_collision_mask
	else:
		velocity.y = min(velocity.y + gravity * delta, max_fall_speed)

	var was_falling := velocity.y > 0.0 and _rocket_timer <= 0.0
	move_and_slide()

	if was_falling and is_on_floor():
		var bounced_platform := _find_floor_platform()
		velocity.y = jump_velocity
		if bounced_platform != null:
			bounced.emit(bounced_platform)

	_wrap_horizontally()

func _find_floor_platform() -> BasePlatform:
	for collision_index in range(get_slide_collision_count()):
		var collision := get_slide_collision(collision_index)
		if collision == null:
			continue
		if collision.get_normal().y > -0.7:
			continue
		if collision.get_collider() is BasePlatform:
			return collision.get_collider()
	return null

func _wrap_horizontally() -> void:
	if global_position.x < -wrap_margin:
		global_position.x = _world_width + wrap_margin
	elif global_position.x > _world_width + wrap_margin:
		global_position.x = -wrap_margin
