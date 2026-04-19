class_name SignalStrengthComponent
extends Node

signal signal_changed(signal_percent : float, jump_multiplier : float, disconnected : bool)

const FILLED_SEGMENT : String = "█"
const EMPTY_SEGMENT : String = "░"

@export_group("Signal")
@export_range(0.0, 100.0, 1.0) var starting_signal_percent : float = 70.0
@export_range(1.0, 100.0, 1.0) var max_signal_percent : float = 100.0
@export_range(0.0, 100.0, 1.0) var high_signal_threshold : float = 70.0
@export_range(0.0, 100.0, 1.0) var medium_signal_threshold : float = 40.0

@export_group("Jump")
@export var high_signal_jump_multiplier : float = 1.2
@export var normal_signal_jump_multiplier : float = 1.0
@export var low_signal_jump_multiplier : float = 0.8

@export_group("HUD")
@export_range(1, 20, 1) var meter_segments : int = 10

var current_signal_percent : float = 0.0

@onready var title_label : Label = $CanvasLayer/MarginContainer/PanelContainer/VBoxContainer/TitleLabel
@onready var meter_label : Label = $CanvasLayer/MarginContainer/PanelContainer/VBoxContainer/MeterLabel

func _ready() -> void:
	reset_signal()

func reset_signal() -> void:
	set_signal_percent(starting_signal_percent)

func set_signal_percent(value : float) -> void:
	current_signal_percent = clampf(value, 0.0, max_signal_percent)
	_refresh_hud()
	signal_changed.emit(current_signal_percent, get_jump_multiplier(), is_disconnected())

func add_signal_percent(amount : float) -> void:
	set_signal_percent(current_signal_percent + amount)

func consume_signal_percent(amount : float) -> void:
	set_signal_percent(current_signal_percent - amount)

func get_signal_percent() -> float:
	return current_signal_percent

func get_jump_multiplier() -> float:
	if is_disconnected():
		return 0.0
	if current_signal_percent >= high_signal_threshold:
		return high_signal_jump_multiplier
	if current_signal_percent >= medium_signal_threshold:
		return normal_signal_jump_multiplier
	return low_signal_jump_multiplier

func is_disconnected() -> bool:
	return current_signal_percent <= 0.0

func get_debug_summary() -> String:
	return "%.0f%% x%.2f disconnected=%s" % [
		current_signal_percent,
		get_jump_multiplier(),
		str(is_disconnected()),
	]

func _refresh_hud() -> void:
	if not is_node_ready():
		return

	title_label.text = "Signal"
	meter_label.text = "%s %d%%" % [_build_meter_bar(), int(round(current_signal_percent))]
	var hud_color : Color = _get_signal_color()
	title_label.modulate = hud_color
	meter_label.modulate = hud_color

func _build_meter_bar() -> String:
	var safe_segments : int = maxi(meter_segments, 1)
	var filled_segments : int = clampi(int(round(current_signal_percent / max_signal_percent * float(safe_segments))), 0, safe_segments)
	var empty_segments : int = safe_segments - filled_segments
	return FILLED_SEGMENT.repeat(filled_segments) + EMPTY_SEGMENT.repeat(empty_segments)

func _get_signal_color() -> Color:
	if is_disconnected():
		return Color(0.93, 0.30, 0.28, 1.0)
	if current_signal_percent >= high_signal_threshold:
		return Color(0.32, 0.86, 0.46, 1.0)
	if current_signal_percent >= medium_signal_threshold:
		return Color(0.95, 0.94, 0.86, 1.0)
	return Color(0.95, 0.72, 0.28, 1.0)
