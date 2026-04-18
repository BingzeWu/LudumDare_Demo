class_name RocketPickup
extends BasePickup

@export var rocket_velocity : float = -1200.0
@export var rocket_duration : float = 1.35

func apply_to_player(player : JumperPlayer) -> void:
	player.trigger_rocket(rocket_velocity, rocket_duration)
