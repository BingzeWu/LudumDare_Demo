class_name SignalJumpRedPlatform
extends SignalJumpPlatformBase

const SIGNAL_PENALTY := -30.0
const SPECIAL_JUMP_MULTIPLIER := 1.8
const GREEN_TINT := Color(0.24, 0.72, 0.37, 1.0)
const RED_TINT := Color(0.92, 0.30, 0.28, 1.0)

var _is_degraded : bool = false

func _init() -> void:
	platform_type = TYPE_RED
	platform_size = Vector2(140.0, 24.0)
	tint = RED_TINT
	jump_multiplier = SPECIAL_JUMP_MULTIPLIER

func activate(platform_position : Vector2) -> void:
	_is_degraded = false
	jump_multiplier = SPECIAL_JUMP_MULTIPLIER
	tint = RED_TINT
	super.activate(platform_position)

func deactivate() -> void:
	_is_degraded = false
	jump_multiplier = SPECIAL_JUMP_MULTIPLIER
	tint = RED_TINT
	super.deactivate()

func on_player_landed(player : SignalJumpPlayer) -> float:
	if _is_degraded:
		return 1.0

	player.add_signal_percent(SIGNAL_PENALTY)
	_is_degraded = true
	jump_multiplier = 1.0
	tint = GREEN_TINT
	_refresh_visuals()
	return SPECIAL_JUMP_MULTIPLIER

func get_debug_label() -> String:
	if _is_degraded:
		return "%s->green" % platform_type
	return platform_type
