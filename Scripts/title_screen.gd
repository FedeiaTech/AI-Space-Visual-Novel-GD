#title_screen.gd
extends Node2D

# === Referencias a nodos ===
@onready var main_menu: Control = %MainMenu
@onready var options_panel: Control = %OptionsPanel
@onready var options_button: Button = %OptionsButton
@onready var new_game_button: Button = %NewGameButton
@onready var quit_game_button: Button = %QuitGameButton
@onready var resolution_option_button: OptionButton = %ResolutionOptionButton
@onready var fullscreen_check_button: CheckButton = %FullscreenCheckButton

# Referencias para los sliders y labels
@onready var bgm_slider: HSlider = %BGMSlider
@onready var voices_slider: HSlider = %VoicesSlider
@onready var sfx_slider: HSlider = %SFXSlider

@onready var bgm_value_label: Label = %BGMValueLabel
@onready var voices_value_label: Label = %VoicesValueLabel
@onready var sfx_value_label: Label = %SFXValueLabel

@onready var options_back_button: Button = %OptionsBackButton

# Variables para los AudioBuses
var bgm_bus_index: int = AudioServer.get_bus_index("BGM")
var voices_bus_index: int = AudioServer.get_bus_index("Voices")
var sfx_bus_index: int = AudioServer.get_bus_index("SFX")

# === Variables de estado ===
var available_resolutions: Array = [
	Vector2i(1920, 1080), # Full HD
	Vector2i(1366, 768),
	Vector2i(1280, 720),  # HD
	Vector2i(1152, 648),  # HD
	Vector2i(960, 540)    # Media
]

func _ready() -> void:
	# Conectar los botones del menú principal
	new_game_button.pressed.connect(_on_new_game_button_pressed)
	options_button.pressed.connect(_on_options_button_pressed)
	quit_game_button.pressed.connect(_on_quit_game_button_pressed)
	
	# Conectar los sliders y el botón de volver del panel de opciones
	bgm_slider.value_changed.connect(_on_bgm_slider_changed)
	voices_slider.value_changed.connect(_on_voices_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	options_back_button.pressed.connect(_on_options_back_button_pressed)

	# === Configuración de pantalla completa ===
	fullscreen_check_button.toggled.connect(_on_fullscreen_toggled)
	# Establecer el estado inicial del botón
	_update_fullscreen_button_state()
	
	# Ocultar el panel de opciones al inicio y mostrar menu principal
	main_menu.show()
	options_panel.hide()

	# Cargar valores guardados (usando un archivo de configuración, por ejemplo)
	# Por ahora, solo cargaremos los valores del sistema de audio
	bgm_slider.value = AudioServer.get_bus_volume_db(bgm_bus_index)
	voices_slider.value = AudioServer.get_bus_volume_db(voices_bus_index)
	sfx_slider.value = AudioServer.get_bus_volume_db(sfx_bus_index)
	_on_bgm_slider_changed(bgm_slider.value)
	_on_voices_slider_changed(voices_slider.value)
	_on_sfx_slider_changed(sfx_slider.value)
	SceneManager.transition_out_completed.connect(_on_transition_out_completed, CONNECT_ONE_SHOT)
	# === Configuración de opciones gráficas ===
	_populate_resolutions()
	resolution_option_button.item_selected.connect(_on_resolution_selected)

func _populate_resolutions():
	resolution_option_button.clear()
	for res in available_resolutions:
		resolution_option_button.add_item(str(res.x) + "x" + str(res.y))
	
	# Selecciona la resolución actual al cargar el menú
	var current_res = DisplayServer.window_get_size()
	for i in range(available_resolutions.size()):
		if available_resolutions[i] == current_res:
			resolution_option_button.select(i)
			break

func _on_options_button_pressed():
	main_menu.hide()
	options_panel.show()

func _on_options_back_button_pressed():
	options_panel.hide()
	main_menu.show()
	# Aquí podrías guardar las opciones en un archivo si no lo haces en tiempo real.

# === Lógica de Sliders ===
func _on_bgm_slider_changed(value: float):
	# El valor del slider es un valor en dB (-80 a 0).
	AudioServer.set_bus_volume_db(bgm_bus_index, value)

	# Usa remap() para mapear el valor de dB (-80 a 0) a un porcentaje (0 a 100).
	var percentage = int(remap(value, -45.0, 0.0, 0.0, 100.0))
	
	# Asegúrate de que el valor no sea negativo (aunque remap ya lo maneja).
	percentage = max(0, percentage)

	bgm_value_label.text = str(percentage) + "%"

func _on_voices_slider_changed(value: float):
	AudioServer.set_bus_volume_db(voices_bus_index, value)
	
	# Usa remap() para mapear el valor de dB a un porcentaje.
	var percentage = int(remap(value, -45.0, 0.0, 0.0, 100.0))
	percentage = max(0, percentage)

	voices_value_label.text = str(percentage) + "%"

func _on_sfx_slider_changed(value: float):
	AudioServer.set_bus_volume_db(sfx_bus_index, value)
	
	# Usa remap() para mapear el valor de dB a un porcentaje.
	var percentage = int(remap(value, -45.0, 0.0, 0.0, 100.0))
	percentage = max(0, percentage)

	sfx_value_label.text = str(percentage) + "%"
	
func _on_new_game_button_pressed():
	SceneManager.change_scene("res://Scenes/mainScene.tscn")
	
func _on_quit_game_button_pressed():
	SceneManager.transition_out()
	
func _on_transition_out_completed():
	get_tree().quit()

func _on_resolution_selected(index: int):
	# 1. Obtiene la nueva resolución
	var new_resolution = available_resolutions[index]
	
	# 2. Establece la nueva resolución base del proyecto
	#    Esto fuerza a Godot a reescalar todo el juego
	get_tree().root.size = new_resolution
	
	# 3. Mantiene el modo de pantalla completa o ventana
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		# Si ya está en pantalla completa, se ajustará al nuevo viewport.
		# No necesitas hacer nada más aquí.
		pass
	else:
		# Si está en modo ventana, también cambia el tamaño de la ventana
		DisplayServer.window_set_size(new_resolution)
	
	print("Resolución base cambiada a: ", new_resolution)

func _on_fullscreen_toggled(button_pressed: bool):
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _update_fullscreen_button_state():
	# Establece el estado del botón al estado actual de la ventana
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		fullscreen_check_button.button_pressed = true
	else:
		fullscreen_check_button.button_pressed = false
