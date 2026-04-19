class_name SignalJumpPlayer
extends CharacterBody2D

@export_group("Movement")
@export var move_speed : float = 320.0
@export var horizontal_acceleration : float = 2200.0
@export var gravity : float = 1500.0
@export var max_fall_speed : float = 900.0
@export var jump_velocity : float = -820.0

@export_group("Camera")
@export var camera_lead : float = 240.0

@export_group("World")
@export var wrap_world_width : float = 720.0

@export_group("Visual")
@export var body_color : Color = Color(0.97, 0.43, 0.37, 1.0) : set = set_body_color

var _camera_anchor_x : float = 0.0
var _is_signal_lost : bool = false

@onready var camera : Camera2D = $Camera2D
@onready var collision_shape : CollisionShape2D = $CollisionShape2D
@onready var polygon : Polygon2D = $Polygon2D
@onready var signal_strength : SignalStrengthComponent = $SignalStrength

func _ready() -> void:
	_refresh_visuals()
	if signal_strength != null and not signal_strength.signal_changed.is_connected(_on_signal_strength_changed):
		signal_strength.signal_changed.connect(_on_signal_strength_changed)
		_on_signal_strength_changed(
			signal_strength.get_signal_percent(),
			signal_strength.get_jump_multiplier(),
			signal_strength.is_disconnected()
		)

func reset(start_position : Vector2) -> void:
	global_position = start_position
	velocity = Vector2.ZERO
	_camera_anchor_x = start_position.x
	_exit_signal_lost_state()
	if collision_shape != null:
		collision_shape.disabled = false
	if signal_strength != null:
		signal_strength.reset_signal()
	camera.global_position = Vector2(_camera_anchor_x, get_viewport_rect().size.y * 0.5)
	set_physics_process(true)

func disable() -> void:
	velocity = Vector2.ZERO
	set_physics_process(false)

func set_wrap_world_width(value : float) -> void:
	wrap_world_width = maxf(value, 1.0)

func set_signal_percent(value : float) -> void:
	if signal_strength != null:
		signal_strength.set_signal_percent(value)

func add_signal_percent(value : float) -> void:
	if signal_strength != null:
		signal_strength.add_signal_percent(value)

func get_signal_percent() -> float:
	if signal_strength == null:
		return 0.0
	return signal_strength.get_signal_percent()

func get_signal_debug_summary() -> String:
	if signal_strength == null:
		return "none"
	return signal_strength.get_debug_summary()

func _physics_process(delta : float) -> void:
	var axis := Input.get_axis("move_left", "move_right")
	velocity.x = move_toward(velocity.x, axis * move_speed, horizontal_acceleration * delta)
	velocity.y = min(velocity.y + gravity * delta, max_fall_speed)

	if _is_signal_lost:
		move_and_slide()
		_wrap_horizontal()
		_update_camera()
		return

	var was_falling := velocity.y > 0.0
	move_and_slide()
	_wrap_horizontal()

	if was_falling and is_on_floor():
		var landed_platform := _find_landed_platform()
		if landed_platform != null:
			_apply_platform_bounce(landed_platform)
		else:
			velocity.y = _get_base_jump_velocity()

	_update_camera()

func set_body_color(value : Color) -> void:
	body_color = value
	_refresh_visuals()

func _refresh_visuals() -> void:
	if not is_node_ready():
		return
	polygon.color = body_color

func _update_camera() -> void:
	camera.global_position.x = _camera_anchor_x
	camera.global_position.y = min(camera.global_position.y, global_position.y - camera_lead)

func _wrap_horizontal() -> void:
	var wrap_margin : float = _get_wrap_margin()
	if global_position.x < -wrap_margin:
		global_position.x = wrap_world_width + wrap_margin
	elif global_position.x > wrap_world_width + wrap_margin:
		global_position.x = -wrap_margin

func _get_wrap_margin() -> float:
	if collision_shape != null and collision_shape.shape is CapsuleShape2D:
		var capsule := collision_shape.shape as CapsuleShape2D
		return capsule.radius
	if collision_shape != null and collision_shape.shape is CircleShape2D:
		var circle := collision_shape.shape as CircleShape2D
		return circle.radius
	if collision_shape != null and collision_shape.shape is RectangleShape2D:
		var rect := collision_shape.shape as RectangleShape2D
		return rect.size.x * 0.5
	return 20.0

func _get_base_jump_velocity() -> float:
	return jump_velocity

func _get_signal_jump_multiplier() -> float:
	if signal_strength == null:
		return 1.0
	return signal_strength.get_jump_multiplier()

func _find_landed_platform() -> SignalJumpPlatformBase:
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		if collision == null:
			continue
		if collision.get_normal().dot(Vector2.UP) <= 0.5:
			continue

		var platform := collision.get_collider() as SignalJumpPlatformBase
		if platform != null:
			return platform

	return null

func _apply_platform_bounce(platform : SignalJumpPlatformBase) -> void:
	var platform_multiplier := platform.on_player_landed(self)
	if _is_signal_lost:
		return

	velocity.y = _get_base_jump_velocity() * _get_signal_jump_multiplier() * platform_multiplier

func _on_signal_strength_changed(_signal_percent : float, _jump_multiplier : float, disconnected : bool) -> void:
	if disconnected:
		_enter_signal_lost_state()
	else:
		_exit_signal_lost_state()

func _enter_signal_lost_state() -> void:
	_is_signal_lost = true
	if collision_shape != null:
		collision_shape.disabled = true
	velocity.y = maxf(velocity.y, 180.0)

func _exit_signal_lost_state() -> void:
	_is_signal_lost = false
	if collision_shape != null:
		collision_shape.disabled = false
