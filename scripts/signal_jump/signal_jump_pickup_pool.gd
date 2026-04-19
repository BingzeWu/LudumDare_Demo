class_name SignalJumpPickupPool
extends Node2D

const DEFAULT_PICKUP_SCENE := preload("res://scenes/game_scene/signal_jump/pickups/basic_pickup.tscn")

var _pool : Array[SignalJumpBasicPickup] = []

func acquire_pickup() -> SignalJumpBasicPickup:
	if not _pool.is_empty():
		return _pool.pop_back()

	var pickup := DEFAULT_PICKUP_SCENE.instantiate() as SignalJumpBasicPickup
	pickup.visible = false
	pickup.position = Vector2(-10000.0, -10000.0)
	add_child(pickup)
	pickup.deactivate()
	return pickup

func recycle_pickup(pickup : Node2D) -> void:
	var typed_pickup := pickup as SignalJumpBasicPickup
	if typed_pickup == null or not is_instance_valid(typed_pickup):
		return
	if _pool.has(typed_pickup):
		return
	typed_pickup.deactivate()
	_pool.append(typed_pickup)

func get_debug_summary() -> String:
	var active_entries : Array[String] = []
	var hidden_unpooled_entries : Array[String] = []

	for child in get_children():
		var pickup := child as SignalJumpBasicPickup
		if pickup == null:
			continue
		if _pool.has(pickup):
			continue
		if pickup.visible and not pickup.collision_shape.disabled:
			active_entries.append("%s@%s" % [pickup.name, _format_vector(pickup.global_position)])
		else:
			hidden_unpooled_entries.append("%s@%s" % [pickup.name, _format_vector(pickup.global_position)])

	return "active=%d pooled=%d hidden_unpooled=%d [active:%s] [hidden:%s]" % [
		active_entries.size(),
		_pool.size(),
		hidden_unpooled_entries.size(),
		", ".join(active_entries),
		", ".join(hidden_unpooled_entries),
	]

func _format_vector(value : Vector2) -> String:
	return "(%.1f, %.1f)" % [value.x, value.y]
