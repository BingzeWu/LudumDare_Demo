class_name SignalJumpFragilePlatform
extends SignalJumpPlatformBase

const DEFAULT_TINT := Color(0.92, 0.94, 0.98, 1.0)
const DISAPPEAR_DELAY := 0.5

var _disappear_timer : float = -1.0

func _init() -> void:
	platform_type = TYPE_WHITE
	platform_size = Vector2(140.0, 24.0)
	tint = DEFAULT_TINT
	jump_multiplier = 1.0

func activate(platform_position : Vector2) -> void:
	_disappear_timer = -1.0
	super.activate(platform_position)

func deactivate() -> void:
	_disappear_timer = -1.0
	super.deactivate()

func on_player_landed(_player : SignalJumpPlayer) -> float:
	if _disappear_timer < 0.0:
		_disappear_timer = DISAPPEAR_DELAY
		set_physics_process(true)
	return jump_multiplier

func _physics_process(delta : float) -> void:
	if _disappear_timer < 0.0:
		return

	_disappear_timer -= delta
	if _disappear_timer > 0.0:
		return

	_disappear_timer = -1.0
	request_recycle()
