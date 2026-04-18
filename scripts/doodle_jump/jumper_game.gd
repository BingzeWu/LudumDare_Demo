extends Node2D

const CONSTANT_PLATFORM_SCENE := preload("res://scenes/doodle_jump/platforms/constant_platform.tscn")
const SINGLE_USE_PLATFORM_SCENE := preload("res://scenes/doodle_jump/platforms/single_use_platform.tscn")
const MOVING_PLATFORM_SCENE := preload("res://scenes/doodle_jump/platforms/moving_platform.tscn")
const SOLID_PLATFORM_SCENE := preload("res://scenes/doodle_jump/platforms/solid_platform.tscn")
const SPRING_PICKUP_SCENE := preload("res://scenes/doodle_jump/pickups/spring_pickup.tscn")
const ROCKET_PICKUP_SCENE := preload("res://scenes/doodle_jump/pickups/rocket_pickup.tscn")

enum PlatformType {
	CONSTANT,
	SINGLE_USE,
	MOVING,
	SOLID
}

@export_group("世界尺寸")
## 是否在运行时自动把关卡逻辑宽度同步到当前视口宽度。
## 开启后，修改项目分辨率时，玩家穿屏范围和移动平台边界会一起更新。
@export var auto_sync_world_width_to_viewport : bool = true
## 是否在运行时自动把初始平台高度同步到当前视口高度。
## 开启后，修改项目分辨率时，玩家开局位置也会跟着调整。
@export var auto_sync_base_platform_y_to_viewport : bool = true
## 游戏逻辑使用的关卡宽度，角色穿屏和平台生成范围都基于它。
@export var world_width : float = 720.0
## 初始出生平台的 Y 坐标。数值越大，出生点越靠下。
@export var base_platform_y : float = 1140.0
## 初始平台的宽度，建议比普通平台更宽，方便开局稳定。
@export var base_platform_width : float = 220.0
## 初始平台距离屏幕底部的保留距离。
@export var base_platform_bottom_margin : float = 140.0
## 玩家开局时相对初始平台的上方偏移。
@export var player_spawn_offset_from_base_platform : float = 92.0

@export_group("平台生成")
## 普通平台最小宽度。减小会提升难度。
@export var min_platform_width : float = 88.0
## 普通平台最大宽度。增大会降低难度。
@export var max_platform_width : float = 156.0
## 相邻平台的最小垂直间距。增大会让跳跃更紧张。
@export var min_vertical_gap : float = 92.0
## 相邻平台的最大垂直间距。和最小值一起决定平台密度波动。
@export var max_vertical_gap : float = 146.0
## 平台距离左右边界保留的最小安全距离，避免贴边生成。
@export var horizontal_margin : float = 56.0
## 相机可视区域上方额外预生成的平台高度，防止向上移动时来不及补平台。
@export var spawn_buffer_above_camera : float = 1400.0
## 平台掉出相机下方多远后会被回收，避免场景中累积太多节点。
@export var despawn_margin_below_camera : float = 260.0

@export_group("平台类型概率")
## 单次平台出现概率。
@export_range(0.0, 1.0, 0.01) var single_use_platform_chance : float = 0.18
## 移动平台出现概率。
@export_range(0.0, 1.0, 0.01) var moving_platform_chance : float = 0.14
## 坚固平台出现概率。
@export_range(0.0, 1.0, 0.01) var solid_platform_chance : float = 0.12
## 移动平台距离屏幕边缘额外保留的边距。设为 0 表示贴边后反向。
@export var moving_platform_edge_margin : float = 0.0
## 移动平台移动速度。
@export var moving_platform_speed : float = 85.0

@export_group("道具概率")
## 弹簧生成概率。
@export_range(0.0, 1.0, 0.01) var spring_pickup_chance : float = 0.12
## 火箭生成概率。
@export_range(0.0, 1.0, 0.01) var rocket_pickup_chance : float = 0.05
## 道具圆球半径，视觉大小与碰撞体保持一致。
@export var pickup_radius : float = 18.0
## 道具距离平台顶部的偏移量。
@export var pickup_height_offset : float = 38.0

@export_group("镜头与失败")
## 相机在玩家上方预留的跟随提前量。数值越大，越能提前看到上方平台。
@export var camera_lead : float = 240.0
## 玩家掉到镜头下方多少距离后判定失败。
@export var game_over_margin : float = 240.0

var _rng := RandomNumberGenerator.new()
var _highest_player_y : float = 0.0
var _highest_spawned_y : float = 0.0
var _score : int = 0
var _is_game_over : bool = false
var _active_platforms : Array[BasePlatform] = []
var _active_pickups : Array[BasePickup] = []
var _platform_pool : Dictionary = {}
var _pickup_pool : Dictionary = {}

@onready var background : ColorRect = $BackgroundLayer/Background
@onready var platform_container : Node2D = $Platforms
@onready var pickup_container : Node2D = $Pickups
@onready var player : JumperPlayer = $Player
@onready var camera : Camera2D = $Camera2D
@onready var score_value_label : Label = $UILayer/Hud/HudRow/ScoreVBox/ScoreValueLabel
@onready var peak_value_label : Label = $UILayer/Hud/HudRow/ScoreVBox/PeakValueLabel
@onready var game_over_panel : PanelContainer = $UILayer/GameOverPanel
@onready var game_over_score_label : Label = $UILayer/GameOverPanel/GameOverVBox/GameOverScoreLabel
@onready var retry_button : Button = $UILayer/GameOverPanel/GameOverVBox/ButtonRow/RetryButton
@onready var main_menu_button : Button = $UILayer/GameOverPanel/GameOverVBox/ButtonRow/MainMenuButton
@onready var pause_menu_layer : CanvasLayer = $PauseMenuLayer

func _ready() -> void:
	_rng.randomize()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_refresh_runtime_dimensions()
	player.bounced.connect(_on_player_bounced)
	retry_button.pressed.connect(_restart)
	main_menu_button.pressed.connect(_back_to_menu)
	_start_run()

func _unhandled_input(event : InputEvent) -> void:
	if event.is_action_released("ui_cancel") and not _is_game_over:
		_toggle_pause_menu()
		return

	if _is_game_over and event.is_action_released("ui_accept"):
		_restart()

func _physics_process(_delta : float) -> void:
	if _is_game_over or pause_menu_layer.visible:
		return

	_update_camera()
	_update_score()
	_spawn_platforms_if_needed()
	_cleanup_platforms()
	_cleanup_pickups()
	_check_game_over()

func _start_run() -> void:
	background.color = Color(0.1, 0.6, 0.75, 0.8)
	_refresh_runtime_dimensions()
	_recycle_all_active_nodes()
	_is_game_over = false
	game_over_panel.hide()

	player.reset(Vector2(world_width * 0.5, base_platform_y - player_spawn_offset_from_base_platform))
	camera.position = Vector2(world_width * 0.5, get_viewport_rect().size.y * 0.5)
	_highest_player_y = player.global_position.y
	_highest_spawned_y = base_platform_y
	_score = 0
	_refresh_score_labels()

	_spawn_platform(PlatformType.CONSTANT, Vector2(world_width * 0.5, base_platform_y), Vector2(base_platform_width, 24.0))
	while _highest_spawned_y > camera.position.y - get_viewport_rect().size.y * 0.5 - spawn_buffer_above_camera:
		_spawn_next_platform()

func _toggle_pause_menu() -> void:
	if pause_menu_layer.visible:
		pause_menu_layer.hide()
	else:
		pause_menu_layer.show()

func _refresh_runtime_dimensions() -> void:
	var viewport_size := get_viewport_rect().size
	background.size = viewport_size
	if auto_sync_world_width_to_viewport:
		world_width = viewport_size.x
	if auto_sync_base_platform_y_to_viewport:
		base_platform_y = viewport_size.y - base_platform_bottom_margin
	player.set_world_width(world_width)
	player.global_position.x = clampf(player.global_position.x, -player.wrap_margin, world_width + player.wrap_margin)
	_refresh_active_moving_platform_bounds()

func _refresh_active_moving_platform_bounds() -> void:
	for platform in _active_platforms:
		if platform is not MovingPlatform:
			continue
		var moving_platform : MovingPlatform = platform
		var left_wall_x := moving_platform_edge_margin
		var right_wall_x := world_width - moving_platform_edge_margin
		moving_platform.setup_screen_bounds(left_wall_x, right_wall_x, moving_platform_speed)

func _on_viewport_size_changed() -> void:
	_refresh_runtime_dimensions()

func _restart() -> void:
	get_tree().paused = false
	_start_run()

func _back_to_menu() -> void:
	get_tree().paused = false
	SceneLoader.load_scene(AppConfig.main_menu_scene_path)

func _update_camera() -> void:
	camera.position.y = min(camera.position.y, player.global_position.y - camera_lead)

func _update_score() -> void:
	_highest_player_y = min(_highest_player_y, player.global_position.y)
	_score = int(max(0.0, base_platform_y - _highest_player_y))
	_refresh_score_labels()

func _refresh_score_labels() -> void:
	score_value_label.text = str(_score)
	peak_value_label.text = "%.0f 像素" % max(0.0, base_platform_y - _highest_player_y)

func _spawn_platforms_if_needed() -> void:
	var visible_top := camera.position.y - get_viewport_rect().size.y * 0.5
	while _highest_spawned_y > visible_top - spawn_buffer_above_camera:
		_spawn_next_platform()

func _spawn_next_platform() -> void:
	var vertical_gap := _rng.randf_range(min_vertical_gap, max_vertical_gap)
	_highest_spawned_y -= vertical_gap
	var platform_width := _rng.randf_range(min_platform_width, max_platform_width)
	var x_min := horizontal_margin + platform_width * 0.5
	var x_max := world_width - horizontal_margin - platform_width * 0.5
	var platform_x := _rng.randf_range(x_min, x_max)
	var platform_type := _roll_platform_type()
	var platform := _spawn_platform(platform_type, Vector2(platform_x, _highest_spawned_y), Vector2(platform_width, 24.0))
	if platform != null:
		_try_spawn_pickup(platform)

func _roll_platform_type() -> PlatformType:
	var roll := _rng.randf()
	if roll < single_use_platform_chance:
		return PlatformType.SINGLE_USE
	if roll < single_use_platform_chance + moving_platform_chance:
		return PlatformType.MOVING
	if roll < single_use_platform_chance + moving_platform_chance + solid_platform_chance:
		return PlatformType.SOLID
	return PlatformType.CONSTANT

func _spawn_platform(platform_type : PlatformType, platform_position : Vector2, size : Vector2) -> BasePlatform:
	var tint := Color(0.20, 0.67, 0.34, 1.0)

	match platform_type:
		PlatformType.CONSTANT:
			tint = Color(0.20, 0.67, 0.34, 1.0)
		PlatformType.SINGLE_USE:
			tint = Color(0.95, 0.74, 0.31, 1.0)
		PlatformType.MOVING:
			tint = Color(0.36, 0.68, 0.95, 1.0)
		PlatformType.SOLID:
			tint = Color(0.62, 0.44, 0.93, 1.0)

	var platform := _acquire_platform(platform_type)
	platform.activate(platform_position, size, tint)
	_active_platforms.append(platform)

	if platform is MovingPlatform:
		var left_wall_x := moving_platform_edge_margin
		var right_wall_x := world_width - moving_platform_edge_margin
		platform.setup_screen_bounds(left_wall_x, right_wall_x, moving_platform_speed)

	return platform

func _try_spawn_pickup(platform : BasePlatform) -> void:
	if platform is SolidPlatform or platform is MovingPlatform:
		return

	var roll := _rng.randf()
	if roll < rocket_pickup_chance:
		_spawn_pickup(ROCKET_PICKUP_SCENE, platform.global_position, Color(0.99, 0.45, 0.36, 1.0))
	elif roll < rocket_pickup_chance + spring_pickup_chance:
		_spawn_pickup(SPRING_PICKUP_SCENE, platform.global_position, Color(0.99, 0.84, 0.30, 1.0))

func _spawn_pickup(pickup_scene : PackedScene, platform_position : Vector2, tint : Color) -> void:
	var pickup_key := "spring"
	if pickup_scene == ROCKET_PICKUP_SCENE:
		pickup_key = "rocket"

	var pickup := _acquire_pickup(pickup_key)
	pickup.activate(platform_position + Vector2(0.0, -pickup_height_offset), pickup_radius, tint)
	_active_pickups.append(pickup)

func _cleanup_platforms() -> void:
	var visible_bottom := camera.position.y + get_viewport_rect().size.y * 0.5
	for index in range(_active_platforms.size() - 1, -1, -1):
		var platform := _active_platforms[index]
		if platform.global_position.y > visible_bottom + despawn_margin_below_camera:
			_recycle_platform(platform)

func _cleanup_pickups() -> void:
	var visible_bottom := camera.position.y + get_viewport_rect().size.y * 0.5
	for index in range(_active_pickups.size() - 1, -1, -1):
		var pickup := _active_pickups[index]
		if pickup.global_position.y > visible_bottom + despawn_margin_below_camera:
			_recycle_pickup(pickup)

func _check_game_over() -> void:
	var visible_bottom := camera.position.y + get_viewport_rect().size.y * 0.5
	if player.global_position.y <= visible_bottom + game_over_margin:
		return

	_is_game_over = true
	player.disable()
	game_over_score_label.text = "最终高度：%d" % _score
	game_over_panel.show()

func _recycle_all_active_nodes() -> void:
	for index in range(_active_platforms.size() - 1, -1, -1):
		_recycle_platform(_active_platforms[index])
	for index in range(_active_pickups.size() - 1, -1, -1):
		_recycle_pickup(_active_pickups[index])

func _on_player_bounced(platform : BasePlatform) -> void:
	platform.on_player_bounced(player)

func _acquire_platform(platform_type : PlatformType) -> BasePlatform:
	if not _platform_pool.has(platform_type):
		_platform_pool[platform_type] = []

	var pool : Array = _platform_pool[platform_type]
	if not pool.is_empty():
		return pool.pop_back()

	var platform_scene := _get_platform_scene(platform_type)
	var platform : BasePlatform = platform_scene.instantiate()
	platform_container.add_child(platform)
	platform.recycle_requested.connect(_on_platform_recycle_requested)
	platform.set_meta("pool_key", int(platform_type))
	platform.hide()
	platform.collision_shape.disabled = true
	return platform

func _acquire_pickup(pickup_key : String) -> BasePickup:
	if not _pickup_pool.has(pickup_key):
		_pickup_pool[pickup_key] = []

	var pool : Array = _pickup_pool[pickup_key]
	if not pool.is_empty():
		return pool.pop_back()

	var pickup_scene := _get_pickup_scene(pickup_key)
	var pickup : BasePickup = pickup_scene.instantiate()
	pickup_container.add_child(pickup)
	pickup.consumed.connect(_on_pickup_consumed)
	pickup.set_meta("pool_key", pickup_key)
	pickup.hide()
	pickup.monitoring = false
	pickup.monitorable = false
	pickup.collision_shape.disabled = true
	return pickup

func _recycle_platform(platform : BasePlatform) -> void:
	_active_platforms.erase(platform)
	platform.deactivate()
	var pool_key : int = int(platform.get_meta("pool_key", int(PlatformType.CONSTANT)))
	if not _platform_pool.has(pool_key):
		_platform_pool[pool_key] = []
	(_platform_pool[pool_key] as Array).append(platform)

func _recycle_pickup(pickup : BasePickup) -> void:
	_active_pickups.erase(pickup)
	pickup.deactivate()
	var pool_key : String = str(pickup.get_meta("pool_key", "spring"))
	if not _pickup_pool.has(pool_key):
		_pickup_pool[pool_key] = []
	(_pickup_pool[pool_key] as Array).append(pickup)

func _get_platform_scene(platform_type : PlatformType) -> PackedScene:
	match platform_type:
		PlatformType.CONSTANT:
			return CONSTANT_PLATFORM_SCENE
		PlatformType.SINGLE_USE:
			return SINGLE_USE_PLATFORM_SCENE
		PlatformType.MOVING:
			return MOVING_PLATFORM_SCENE
		PlatformType.SOLID:
			return SOLID_PLATFORM_SCENE
	return CONSTANT_PLATFORM_SCENE

func _get_pickup_scene(pickup_key : String) -> PackedScene:
	if pickup_key == "rocket":
		return ROCKET_PICKUP_SCENE
	return SPRING_PICKUP_SCENE

func _on_platform_recycle_requested(platform : BasePlatform) -> void:
	_recycle_platform(platform)

func _on_pickup_consumed(pickup : BasePickup) -> void:
	_recycle_pickup(pickup)
