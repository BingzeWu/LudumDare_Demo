class_name SignalJumpSpringPlatform
extends SignalJumpPlatformBase

const DEFAULT_TINT := Color(0.98, 0.56, 0.18, 1.0)

func _init() -> void:
	platform_type = TYPE_ORANGE
	platform_size = Vector2(140.0, 24.0)
	tint = DEFAULT_TINT
	jump_multiplier = 2.5
