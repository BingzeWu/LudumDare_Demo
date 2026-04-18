class_name SingleUsePlatform
extends BasePlatform

var _used : bool = false

func reset_runtime_state() -> void:
	_used = false

func on_player_bounced(_player : JumperPlayer) -> void:
	if _used:
		return
	_used = true
	request_recycle()
