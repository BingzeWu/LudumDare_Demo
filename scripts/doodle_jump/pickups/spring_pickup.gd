class_name SpringPickup
extends BasePickup

@export var spring_jump_velocity : float = -980.0

func apply_to_player(player : JumperPlayer) -> void:
	player.trigger_spring(spring_jump_velocity)
