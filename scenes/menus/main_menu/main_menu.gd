extends MainMenu
## Main menu extension that hides unused prototype buttons.

@export var level_select_packed_scene: PackedScene

@onready var continue_game_button = %ContinueGameButton
@onready var level_select_button = %LevelSelectButton

func new_game() -> void:
	load_game_scene()

func _ready() -> void:
	super._ready()
	continue_game_button.hide()
	level_select_button.hide()

func _on_continue_game_button_pressed() -> void:
	load_game_scene()

func _on_level_select_button_pressed() -> void:
	var level_select_scene := _open_sub_menu(level_select_packed_scene)
	if level_select_scene.has_signal("level_selected"):
		level_select_scene.connect("level_selected", load_game_scene)

func _on_new_game_confirmation_confirmed() -> void:
	load_game_scene()
