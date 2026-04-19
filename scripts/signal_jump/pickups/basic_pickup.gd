class_name SignalJumpBasicPickup
extends Area2D

@export var radius : float = 18.0 : set = set_radius
@export var tint : Color = Color(0.98, 0.79, 0.27, 1.0) : set = set_tint

@onready var collision_shape : CollisionShape2D = $CollisionShape2D
@onready var polygon : Polygon2D = $Polygon2D

func _ready() -> void:
	_refresh_visuals()

func activate(pickup_position : Vector2, new_radius : float, new_tint : Color) -> void:
	global_position = pickup_position
	show()
	collision_shape.disabled = false
	radius = new_radius
	tint = new_tint
	_refresh_visuals()

func deactivate() -> void:
	hide()
	global_position = Vector2(-10000.0, -10000.0)
	collision_shape.disabled = true

func set_radius(value : float) -> void:
	radius = value
	_refresh_visuals()

func set_tint(value : Color) -> void:
	tint = value
	_refresh_visuals()

func _refresh_visuals() -> void:
	if not is_node_ready():
		return

	var shape : CircleShape2D
	if collision_shape.shape is CircleShape2D:
		shape = collision_shape.shape
	else:
		shape = CircleShape2D.new()
	shape.radius = radius
	collision_shape.shape = shape
	polygon.polygon = _build_circle_points(radius, 18)
	polygon.color = tint

func _build_circle_points(circle_radius : float, segments : int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(segments):
		var angle := TAU * float(index) / float(segments)
		points.append(Vector2.RIGHT.rotated(angle) * circle_radius)
	return points
