class_name SignalJumpPlatformSpawnMarker
extends Marker2D

@export_enum("green", "blue", "red", "yellow", "white", "orange")
var platform_type : String = SignalJumpPlatformBase.TYPE_GREEN

@export var randomize_x : bool = false
@export_range(0.0, 160.0, 1.0) var x_random_range : float = 0.0
@export var move_distance : float = 180.0
@export var move_speed : float = 110.0
