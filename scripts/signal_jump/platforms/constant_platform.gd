class_name SignalJumpConstantPlatform
extends SignalJumpPlatformBase

const DEFAULT_TINT := Color(0.24, 0.72, 0.37, 1.0)

func _init() -> void:
	platform_type = TYPE_GREEN
	platform_size = Vector2(140.0, 24.0)
	tint = DEFAULT_TINT
	jump_multiplier = 1.0
