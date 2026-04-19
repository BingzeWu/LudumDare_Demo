class_name SignalJumpPlatformBase
extends AnimatableBody2D

signal recycle_requested(platform : SignalJumpPlatformBase)

const OFFSCREEN_POSITION := Vector2(-10000.0, -10000.0)
const TYPE_GREEN := "green"
const TYPE_BLUE := "blue"
const TYPE_RED := "red"
const TYPE_YELLOW := "yellow"
const TYPE_WHITE := "white"
const TYPE_ORANGE := "orange"

@export var platform_type : String = TYPE_GREEN
@export var platform_size : Vector2 = Vector2(140.0, 24.0) : set = set_platform_size
@export var tint : Color = Color(0.24, 0.72, 0.37, 1.0) : set = set_tint
@export var jump_multiplier : float = 1.0

@onready var collision_shape : CollisionShape2D = $CollisionShape2D
@onready var polygon : Polygon2D = $Polygon2D

func _ready() -> void:
	_refresh_visuals()

func activate(platform_position : Vector2) -> void:
	global_position = platform_position
	show()
	_set_collision_enabled(true)
	_on_activated()
	_refresh_visuals()

func deactivate() -> void:
	_on_deactivated()
	hide()
	global_position = OFFSCREEN_POSITION
	_set_collision_enabled(false)

func on_player_landed(_player : SignalJumpPlayer) -> float:
	return jump_multiplier

func apply_spawn_marker(_spawn_marker : SignalJumpPlatformSpawnMarker) -> void:
	pass

func request_recycle() -> void:
	recycle_requested.emit(self)

func get_pool_type() -> String:
	return platform_type

func get_debug_label() -> String:
	return platform_type

func set_platform_size(value : Vector2) -> void:
	platform_size = value
	_refresh_visuals()

func set_tint(value : Color) -> void:
	tint = value
	_refresh_visuals()

func _on_activated() -> void:
	set_physics_process(false)

func _on_deactivated() -> void:
	set_physics_process(false)

func _set_collision_enabled(enabled : bool) -> void:
	if collision_shape != null:
		collision_shape.disabled = not enabled

func _refresh_visuals() -> void:
	if not is_node_ready():
		return

	var shape : RectangleShape2D
	if collision_shape.shape is RectangleShape2D:
		shape = collision_shape.shape
	else:
		shape = RectangleShape2D.new()

	shape.size = platform_size
	collision_shape.shape = shape
	collision_shape.one_way_collision = true

	var extents := platform_size * 0.5
	polygon.polygon = PackedVector2Array([
		Vector2(-extents.x, -extents.y),
		Vector2(extents.x, -extents.y),
		Vector2(extents.x, extents.y),
		Vector2(-extents.x, extents.y),
	])
	polygon.color = tint
