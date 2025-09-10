# PauseMenu.gd
extends CanvasLayer

# Señal para avisar a la escena principal que debe volver al menú.
signal main_menu_requested

@onready var resume_button = %ResumeButton
@onready var main_menu_button = %MainMenuButton
@onready var options_button = %OptionsButton

func _ready():
	# Conectamos las señales de los botones a las funciones de este script.
	resume_button.pressed.connect(_on_resume_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	options_button.pressed.connect(_on_options_button_pressed)

func _input(event):
	# Permite al jugador cerrar el menú con la tecla Escape también.
	if event.is_action_pressed("ui_cancel"): # "ui_cancel" suele ser la tecla Esc
		_on_resume_button_pressed()

func _on_resume_button_pressed():
	# Reanuda el juego.
	get_tree().paused = false
	# Elimina el menú de la escena.
	queue_free()

func _on_main_menu_button_pressed():
	# Es importante reanudar el juego ANTES de cambiar de escena.
	get_tree().paused = false
	# Emitimos una señal para que MainScene se encargue del cambio.
	main_menu_requested.emit()

func _on_options_button_pressed():
	print("Botón de Opciones presionado (lógica futura).")
	# Aquí podrías instanciar y mostrar una escena de opciones.
	pass
