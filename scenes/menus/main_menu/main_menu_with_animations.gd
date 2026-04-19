extends MainMenu
## Main menu extension that adds intro animation and hides unused prototype buttons.

@export var level_select_packed_scene: PackedScene

var animation_state_machine : AnimationNodeStateMachinePlayback

@onready var continue_game_button = %ContinueGameButton
@onready var level_select_button = %LevelSelectButton

func new_game() -> void:
	GameState.start_game()
	load_game_scene()

func intro_done() -> void:
	animation_state_machine.travel("OpenMainMenu")

func _is_in_intro() -> bool:
	return animation_state_machine.get_current_node() == "Intro"

func _event_skips_intro(event : InputEvent) -> bool:
	return event.is_action_released("ui_accept") or \
		event.is_action_released("ui_select") or \
		event.is_action_released("ui_cancel") or \
		_event_is_mouse_button_released(event)

func _open_sub_menu(menu : PackedScene) -> Node:
	animation_state_machine.travel("OpenSubMenu")
	return super._open_sub_menu(menu)

func _close_sub_menu() -> void:
	super._close_sub_menu()
	animation_state_machine.travel("OpenMainMenu")

func _input(event : InputEvent) -> void:
	if _is_in_intro() and _event_skips_intro(event):
		intro_done()
		return
	super._input(event)

func _ready() -> void:
	super._ready()
	continue_game_button.hide()
	level_select_button.hide()
	animation_state_machine = $MenuAnimationTree.get("parameters/playback")

func _on_continue_game_button_pressed() -> void:
	load_game_scene()

func _on_level_select_button_pressed() -> void:
	var level_select_scene := _open_sub_menu(level_select_packed_scene)
	if level_select_scene.has_signal("level_selected"):
		level_select_scene.connect("level_selected", load_game_scene)

func _on_new_game_confirmation_confirmed() -> void:
	load_game_scene()
