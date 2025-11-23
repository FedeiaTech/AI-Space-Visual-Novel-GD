extends Button

# REFERENCIA AL HIJO QUE TIENE EL SHADER
@onready var background_effect = $BackgroundEffect

# Variables para la lógica
var _exit_tween: Tween
var _is_mouse_over = false
var _center1 = Vector2(0.5, 0.5)
var _center2 = Vector2(0.5, 0.5)

func _ready():
	if background_effect and background_effect.material:
		# Crea una copia única del material solo para ESTE botón
		background_effect.material = background_effect.material.duplicate()
		
	# Verificamos que el nodo hijo y su material existan
	if background_effect and background_effect.material:
		var mat = background_effect.material # <-- USAMOS EL MATERIAL DEL HIJO
		
		mat.set("shader_parameter/size", size)
		mat.set("shader_parameter/time1", 1.0)
		mat.set("shader_parameter/time2", 0.0)
		
		# CONFIGURACIÓN DE COLOR
		# Cambia este color por el que quieras (R, G, B, A)
		mat.set("shader_parameter/color", Color(0.8, 0.8, 0.8, 0.8)) 

	# Conectamos señales
	pressed.connect(_on_pressed)
	mouse_exited.connect(_on_mouse_exited)
	mouse_entered.connect(_on_mouse_entered)
	resized.connect(_on_resized)

func _process(_delta):
	# Si no hay panel o material, no hacemos nada
	if not background_effect or not background_effect.material: return
	
	# Calculamos la posición del mouse relativa al PANEL
	var local_mouse = (background_effect.get_global_transform().affine_inverse() * get_global_mouse_position()) / size
	
	if _is_mouse_over:
		_center2 = local_mouse
		background_effect.material.set("shader_parameter/center2", _center2)
	
	background_effect.material.set("shader_parameter/center1", _center1)

func _on_resized():
	if background_effect and background_effect.material:
		background_effect.material.set("shader_parameter/size", size)

func _on_pressed():
	if not background_effect or not background_effect.material: return
	
	_center1 = (background_effect.get_global_transform().affine_inverse() * get_global_mouse_position()) / size
	
	# Animación rápida del click en el material del HIJO
	var tw = create_tween()
	tw.tween_property(background_effect.material, "shader_parameter/time1", 1.0, 0.5).from(0.0)

func _on_mouse_entered():
	if not background_effect or not background_effect.material: return
	_is_mouse_over = true
	if _exit_tween: _exit_tween.kill()
	
	set_process(true)
	
	# Animación de entrada (Hover) en el material del HIJO
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(background_effect.material, "shader_parameter/glow", 2.0, 0.2)
	tw.tween_property(background_effect.material, "shader_parameter/time2", 0.35, 0.2)

func _on_mouse_exited():
	if not background_effect or not background_effect.material: return
	_is_mouse_over = false
	
	var center = Vector2(0.5, 0.5)
	var exit_target = center + (_center2 - center).normalized() * 2.0
	
	_exit_tween = create_tween()
	_exit_tween.set_parallel(true)
	_exit_tween.tween_property(self, "_center2", exit_target, 0.3)
	
	# Animamos las propiedades del material del HIJO
	_exit_tween.tween_property(background_effect.material, "shader_parameter/time2", 0.0, 0.3)
	_exit_tween.tween_property(background_effect.material, "shader_parameter/glow", 0.0, 0.2)
	
	_exit_tween.chain().tween_callback(_reset_center_after_exit)

func _reset_center_after_exit():
	_center2 = Vector2(0.5, 0.5)
	set_process(false)
