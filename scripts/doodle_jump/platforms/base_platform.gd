class_name BasePlatform
extends AnimatableBody2D

signal recycle_requested(platform : BasePlatform)

@export var platform_size : Vector2 = Vector2(140.0, 24.0) : set = set_platform_size
@export var tint : Color = Color(0.49, 0.86, 0.57, 1.0) : set = set_tint
@export var one_way_collision_enabled : bool = true : set = set_one_way_collision_enabled

@onready var collision_shape : CollisionShape2D = $CollisionShape2D
@onready var polygon : Polygon2D = $Polygon2D

func _ready() -> void:
	_refresh_visuals()

func activate(platform_position : Vector2, new_size : Vector2, new_tint : Color) -> void:
	global_position = platform_position
	show()
	collision_shape.disabled = false
	reset_runtime_state()
	setup(new_size, new_tint)

func deactivate() -> void:
	hide()
	collision_shape.disabled = true
	set_physics_process(false)

func setup(new_size : Vector2, new_tint : Color) -> void:
	platform_size = new_size
	tint = new_tint
	_refresh_visuals()

func reset_runtime_state() -> void:
	pass

func set_platform_size(value : Vector2) -> void:
	platform_size = value
	_refresh_visuals()

func set_tint(value : Color) -> void:
	tint = value
	_refresh_visuals()

func set_one_way_collision_enabled(value : bool) -> void:
	one_way_collision_enabled = value
	_refresh_visuals()

func on_player_bounced(_player : JumperPlayer) -> void:
	pass

func request_recycle() -> void:
	recycle_requested.emit(self)

func _refresh_visuals() -> void:
	if not is_node_ready():
		return

	var extents := platform_size * 0.5
	var shape : RectangleShape2D
	if collision_shape.shape is RectangleShape2D:
		shape = collision_shape.shape
	else:
		shape = RectangleShape2D.new()
	shape.size = platform_size
	collision_shape.shape = shape
	collision_shape.one_way_collision = one_way_collision_enabled
	polygon.polygon = PackedVector2Array([
		Vector2(-extents.x, -extents.y),
		Vector2(extents.x, -extents.y),
		Vector2(extents.x, extents.y),
		Vector2(-extents.x, extents.y)
	])
	polygon.color = tint
