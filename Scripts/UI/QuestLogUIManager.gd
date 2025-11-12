# QuestLogUIManager.gd
# Este script vive en MainScene. Se encarga de pausar el juego
# e instanciar/destruir la escena QuestLogUI.
extends Node

const QuestLogUIScene = preload("res://Scenes/UI/QuestLogUI.tscn")
var current_quest_log_ui: CanvasLayer = null
var main_scene: Node2D

func _ready():
	main_scene = get_parent()

func toggle_quest_log():
	if current_quest_log_ui == null:
		_open()
	else:
		_close()

func _open():
	if current_quest_log_ui != null: return

	current_quest_log_ui = QuestLogUIScene.instantiate()
	current_quest_log_ui.quest_log_closed.connect(_on_quest_log_closed_from_ui)
	add_child(current_quest_log_ui)

	get_tree().paused = true
	main_scene.is_dialog_input_blocked = true
	print("Registro de Misiones abierto, juego pausado.")

func _close():
	if current_quest_log_ui == null: return

	current_quest_log_ui.quest_log_closed.disconnect(_on_quest_log_closed_from_ui)
	current_quest_log_ui.queue_free()
	current_quest_log_ui = null

	get_viewport().set_input_as_handled()
	get_tree().paused = false
	main_scene.is_dialog_input_blocked = false
	print("Registro de Misiones cerrado, juego reanudado.")
	main_scene.dialog_ui.show()

func _on_quest_log_closed_from_ui():
	_close()
