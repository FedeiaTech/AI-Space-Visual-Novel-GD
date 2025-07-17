extends Node2D

@onready var new_game_button: Button = %NewGameButton
@onready var quit_game_button: Button = %QuitGameButton

func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_button_pressed)
	quit_game_button.pressed.connect(_on_quit_game_button)
	SceneManager.transition_out_completed.connect(_on_transition_out_completed, CONNECT_ONE_SHOT)

func _on_new_game_button_pressed():
	SceneManager.change_scene("res://Scenes/mainScene.tscn")
	
func _on_quit_game_button():
	SceneManager.transition_out()
	
func _on_transition_out_completed():
	get_tree().quit()
