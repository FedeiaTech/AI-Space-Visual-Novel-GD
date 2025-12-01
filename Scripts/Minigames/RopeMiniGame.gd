extends Node2D

signal minigame_finished(success: bool)

@onready var player: Node2D = %Player
@onready var sprite: Sprite2D = %Sprite2D
@onready var anim_player: AnimationPlayer = %AnimationPlayer

# --- ¡NUEVO! Referencia al indicador único ---
@onready var arrow_indicator: Sprite2D = %ArrowIndicator

@onready var slip_timer: Timer = $Timer

# --- ¡NUEVO! Precarga de las imágenes de las flechas ---
# ⚠️ REEMPLAZA ESTAS RUTAS CON LAS DE TUS IMÁGENES REALES ⚠️
# Imagen donde la flecha IZQUIERDA está iluminada (ej. image_10.png)
const TEX_LEFT_LIT = preload("res://Assets/Minigames/Rope/left_key_arrow.png") 
# Imagen donde la flecha DERECHA está iluminada (ej. image_7.png)
const TEX_RIGHT_LIT = preload("res://Assets/Minigames/Rope/right_key_arrow.png")


# Nombre exacto que pusimos en el Paso 2
@export var animation_name: String = "climb"

# Dificultad: Cuantos "tirones" para llegar arriba
@export var total_steps_to_win: int = 128

# Cuántos pasos pierde cada segundo
@export var slip_amount_per_second: int = 3

var current_step: int = 0
var animation_length: float = 0.0
var next_key = "ui_right"
var is_game_active: bool = true

# Variable para controlar el tween de temblequeo
var strain_tween: Tween

func _ready():
	if not anim_player.has_animation(animation_name):
		printerr("ERROR FATAL: No existe la animación '", animation_name, "'")
		return

	animation_length = anim_player.get_animation(animation_name).length
	anim_player.play(animation_name)
	anim_player.stop()
	anim_player.seek(0.0, true)
	
	# Inicializar el estado visual
	_update_arrow_visuals()

func _on_timer_timeout():
	if not is_game_active or current_step <= 0: return
	
	var prev_progress = float(current_step) / float(total_steps_to_win)
	var time_prev = prev_progress * animation_length

	current_step = max(0, current_step - slip_amount_per_second)

	var new_progress = float(current_step) / float(total_steps_to_win)
	var time_target = new_progress * animation_length

	_trigger_strain_effect(time_prev, time_target)


func _input(event):
	if not is_game_active: return

	if event.is_action_pressed("ui_right") and next_key == "ui_right":
		_advance_frame()
		next_key = "ui_left"
		# Actualizar imagen
		_update_arrow_visuals()

	elif event.is_action_pressed("ui_left") and next_key == "ui_left":
		_advance_frame()
		next_key = "ui_right"
		# Actualizar imagen
		_update_arrow_visuals()

# --- NUEVA FUNCIÓN: Intercambia las texturas ---
func _update_arrow_visuals():
	if next_key == "ui_right":
		# Toca derecha -> Ponemos la imagen con la derecha iluminada
		arrow_indicator.texture = TEX_RIGHT_LIT
	else:
		# Toca izquierda -> Ponemos la imagen con la izquierda iluminada
		arrow_indicator.texture = TEX_LEFT_LIT

func _advance_frame():
	# (Lógica de avance idéntica...)
	var prev_progress = float(current_step) / float(total_steps_to_win)
	var time_prev = prev_progress * animation_length

	current_step += 1

	var new_progress = float(current_step) / float(total_steps_to_win)
	var time_target = new_progress * animation_length

	_trigger_strain_effect(time_prev, time_target)

	if current_step >= total_steps_to_win:
		_win_game()

func _trigger_strain_effect(prev_time: float, target_time: float):
	# (Lógica de temblequeo idéntica...)
	if strain_tween and strain_tween.is_running():
		strain_tween.kill()

	strain_tween = create_tween()

	strain_tween.tween_callback(anim_player.seek.bind(target_time, true))
	strain_tween.tween_interval(0.01)
	strain_tween.tween_callback(anim_player.seek.bind(prev_time, true))
	strain_tween.tween_interval(0.01)
	strain_tween.tween_callback(anim_player.seek.bind(target_time, true))

func _win_game():
	is_game_active = false
	slip_timer.stop()
	
	# Ocultar el indicador al ganar
	arrow_indicator.hide()
	
	print("¡Trepaste!")
	await get_tree().create_timer(0.5).timeout
	minigame_finished.emit(true)
	queue_free()
