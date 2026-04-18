class_name BasePickup
extends Area2D

signal consumed(pickup : BasePickup)

@export var radius : float = 18.0 : set = set_radius
@export var tint : Color = Color(1.0, 0.9, 0.3, 1.0) : set = set_tint

@onready var collision_shape : CollisionShape2D = $CollisionShape2D
@onready var polygon : Polygon2D = $Polygon2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_refresh_visuals()

func activate(pickup_position : Vector2, new_radius : float, new_tint : Color) -> void:
	global_position = pickup_position
	show()
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	collision_shape.set_deferred("disabled", false)
	setup(new_radius, new_tint)

func deactivate() -> void:
	hide()
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	collision_shape.set_deferred("disabled", true)

func setup(new_radius : float, new_tint : Color) -> void:
	radius = new_radius
	tint = new_tint
	_refresh_visuals()

func set_radius(value : float) -> void:
	radius = value
	_refresh_visuals()

func set_tint(value : Color) -> void:
	tint = value
	_refresh_visuals()

func apply_to_player(_player : JumperPlayer) -> void:
	pass

func _on_body_entered(body : Node) -> void:
	if body is not JumperPlayer:
		return
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	collision_shape.set_deferred("disabled", true)
	apply_to_player(body)
	call_deferred("_emit_consumed")

func _emit_consumed() -> void:
	consumed.emit(self)

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
