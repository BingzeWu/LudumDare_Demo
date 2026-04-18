extends Node2D

@export_group("测试场景")
## 是否自动把逻辑宽度同步到当前视口宽度，方便测试不同分辨率下的平台效果。
@export var auto_sync_world_width_to_viewport : bool = true
## 角色左右穿屏和移动平台整屏往返使用的逻辑宽度。
@export var world_width : float = 720.0
## 是否让镜头跟随玩家的横向位置。
## 测试左右穿屏时建议关闭，否则镜头也会一起瞬移，视觉上看不出穿屏。
@export var camera_follow_player_x : bool = false
## 是否让镜头跟随玩家的纵向位置，方便测试高低不同位置的平台。
@export var camera_follow_player_y : bool = true

var _platform_initial_states : Dictionary = {}

@onready var background : ColorRect = $BackgroundLayer/Background
@onready var left_boundary_guide : ColorRect = $BackgroundLayer/LeftBoundaryGuide
@onready var right_boundary_guide : ColorRect = $BackgroundLayer/RightBoundaryGuide
@onready var platforms_root : Node2D = $Platforms
@onready var player : JumperPlayer = $Player
@onready var camera : Camera2D = $Camera2D
@onready var spawn_point : Marker2D = $SpawnPoint

func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_refresh_runtime_dimensions()
	player.bounced.connect(_on_player_bounced)
	_cache_platform_setup()
	_reset_test_scene()

func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_released("ui_accept"):
		_reset_test_scene()

func _physics_process(_delta : float) -> void:
	var target_position := camera.global_position
	if camera_follow_player_x:
		target_position.x = player.global_position.x
	else:
		target_position.x = world_width * 0.5
	if camera_follow_player_y:
		target_position.y = player.global_position.y
	camera.global_position = target_position

func _refresh_runtime_dimensions() -> void:
	var viewport_size := get_viewport_rect().size
	background.size = viewport_size
	if auto_sync_world_width_to_viewport:
		world_width = viewport_size.x
	left_boundary_guide.position = Vector2.ZERO
	left_boundary_guide.size = Vector2(4.0, viewport_size.y)
	right_boundary_guide.position = Vector2(world_width - 4.0, 0.0)
	right_boundary_guide.size = Vector2(4.0, viewport_size.y)
	player.set_world_width(world_width)
	_refresh_moving_platform_bounds()

func _cache_platform_setup() -> void:
	_platform_initial_states.clear()
	_cache_platform_setup_in_node(platforms_root)

func _cache_platform_setup_in_node(root_node : Node) -> void:
	for child in root_node.get_children():
		if child is BasePlatform:
			var platform : BasePlatform = child
			_platform_initial_states[platform] = {
				"position": platform.global_position,
				"size": platform.platform_size,
				"tint": platform.tint,
				"one_way": platform.one_way_collision_enabled,
			}
			if not platform.recycle_requested.is_connected(_on_platform_recycle_requested):
				platform.recycle_requested.connect(_on_platform_recycle_requested)
		_cache_platform_setup_in_node(child)

func _reset_test_scene() -> void:
	for platform in _platform_initial_states.keys():
		if not is_instance_valid(platform):
			continue
		var state : Dictionary = _platform_initial_states[platform]
		platform.activate(state["position"], state["size"], state["tint"])
		platform.set_one_way_collision_enabled(state["one_way"])

	_refresh_moving_platform_bounds()
	player.reset(spawn_point.global_position)
	camera.global_position = Vector2(
		player.global_position.x if camera_follow_player_x else world_width * 0.5,
		player.global_position.y if camera_follow_player_y else get_viewport_rect().size.y * 0.5
	)

func _refresh_moving_platform_bounds() -> void:
	for platform in _platform_initial_states.keys():
		if not is_instance_valid(platform) or platform is not MovingPlatform:
			continue
		var moving_platform : MovingPlatform = platform
		moving_platform.setup_screen_bounds(0.0, world_width, moving_platform.move_speed)

func _on_player_bounced(platform : BasePlatform) -> void:
	platform.on_player_bounced(player)

func _on_platform_recycle_requested(platform : BasePlatform) -> void:
	platform.deactivate()

func _on_viewport_size_changed() -> void:
	_refresh_runtime_dimensions()
