extends ColorRect

func _ready():
	# 1. CRUCIAL: Duplicamos el material para que esta onda tenga el suyo propio.
	# Si no hacemos esto, modificar el shader afectará a todas las ondas futuras.
	if material:
		material = material.duplicate()
		
		# 2. Reseteamos explícitamente el valor inicial
		# (Aunque usemos .from(0.0) abajo, es buena práctica asegurar el estado)
		material.set_shader_parameter("time", 0.0)

	# 3. Animamos
	var tween = create_tween()
	
	# Usamos .from(0.0) para forzar que la animación empiece desde el principio
	tween.tween_property(material, "shader_parameter/time", 1.0, 0.5).from(0.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	# Cuando termina, se autodestruye
	tween.finished.connect(queue_free)
