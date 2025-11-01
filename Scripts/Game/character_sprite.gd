#character_sprite.gd
extends Control

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Variables para posición
var current_position: Character.Position = Character.Position.CENTER
var current_character_name: String = ""
var last_known_position: Vector2 = Vector2.ZERO
var current_facing_direction: String = "right"
var current_expression: String = "idle"

func _ready() -> void:
	self.modulate.a = 0

func show_sprite():
	self.visible = true
	# Muestra el sprite con un fundido de entrada (fade-in)
	if self.modulate.a < 1.0:
		create_tween().tween_property(self, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE)

func hide_sprite():
	# Oculta el sprite con un fundido de salida (fade-out)
	if self.modulate.a > 0.0:
		create_tween().tween_property(self, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE)

func hide_instantly():
	# En lugar de usar hide(), simplemente lo hacemos 100% transparente.
	# Así evitamos problemas con la propiedad 'visible'.
	modulate.a = 0.0
	
func change_character(character_name: Character.Name, is_talking: bool, expression: String, position_to_set: Character.Position = Character.Position.CENTER):
	var character_details = Character.CHARACTER_DETAILS.get(character_name)
	# Mover el sprite a la posición deseada.
	var target_x = Character.POSITIONS[position_to_set]
	var target_position = Vector2(target_x, position.y)
	
	# Usa la posición predefinida si el personaje cambia de posición
	move_to_position(target_position, 0.5)
	
	if not character_details or not character_details.get("sprite_frames"):
		hide_instantly()
		return
	
	# Guarda el nombre actual del personaje
	self.current_character_name = Character.CHARACTER_DETAILS.get(character_name, {}).get("name", "")
	
	var sprite_frames = character_details["sprite_frames"]
	var stance = "talking" if is_talking else "idle"
	var animation_name = expression + "-" + stance if expression and is_talking else stance
	
	if sprite_frames:
		animated_sprite.sprite_frames = sprite_frames
		if animated_sprite.sprite_frames.has_animation(animation_name):
			animated_sprite.play(animation_name)
		else:
			animated_sprite.play(stance)
	
	show_sprite()

func play_idle_animation():
	var last_animation = animated_sprite.animation
	if last_animation and not last_animation.ends_with("-idle"):
		var idle_expression = last_animation.replace("talking", "idle")
		if animated_sprite.sprite_frames.has_animation(idle_expression):
			animated_sprite.play(idle_expression)
		else:
			animated_sprite.play("idle")

func stop_talking():
	# Si la animación actual es la de hablar, deténla y vuelve al primer frame.
	if animated_sprite.current_animation.begins_with("talking"):
		animated_sprite.stop()
		animated_sprite.current_animation = animated_sprite.current_animation
		animated_sprite.advance(0)

func resume_talking():
	# Si la animación actual estaba en 'talking', reprodúcela de nuevo.
	if animated_sprite.current_animation.begins_with("talking"):
		animated_sprite.play()

# Función para cambiar el personaje y moverlo a una posición específica
# La firma de la función espera siempre una dirección, ya no hay modo "auto"
func change_character_with_position(character_enum: Character.Name, is_talking: bool, expression: String, target_position: Vector2, facing_direction: String):
	self.current_expression = expression
	
	var character_details = Character.CHARACTER_DETAILS.get(character_enum)
	
	if not character_details or not character_details.get("sprite_frames"):
		hide_instantly()
		return

	# Asigna los detalles básicos del personaje
	self.current_character_name = character_details.get("name", "")
	self.current_facing_direction = facing_direction
	var sprite_frames = character_details["sprite_frames"]
	animated_sprite.sprite_frames = sprite_frames
	
	# Mueve el personaje a su posición
	slide_to_position(target_position, 0.5)

	# --- LÓGICA DE BÚSQUEDA DE ANIMACIÓN CORREGIDA ---
	
	var stance = "talking" if is_talking else "idle"
	var final_animation_to_play = "" # Variable para guardar la animación final

	# CASO ESPECIAL: ASTRO (Lógica con direcciones _left, _center, _right)
	if self.current_character_name == "Astro":
		animated_sprite.flip_h = false # Astro nunca se voltea horizontalmente

		# Prioridad 1: Buscar la animación más específica (expresión-stance_dirección)
		# Ejemplo: "happy-talking_left"
		if not expression.is_empty():
			var specific_anim = expression + "-" + stance + "_" + self.current_facing_direction
			if sprite_frames.has_animation(specific_anim):
				final_animation_to_play = specific_anim

		# Prioridad 2: Si no se encontró, buscar la animación de stance con dirección
		# Ejemplo: "talking_left"
		if final_animation_to_play.is_empty():
			var base_directional_anim = stance + "_" + self.current_facing_direction
			if sprite_frames.has_animation(base_directional_anim):
				final_animation_to_play = base_directional_anim

	# CASO GENERAL: TODOS LOS DEMÁS PERSONAJES (Lógica con flip)
	else:
		# Aplica el flip según la dirección
		if self.current_facing_direction == "left":
			animated_sprite.flip_h = true
		else: # "right" o "center"
			animated_sprite.flip_h = false

		# Prioridad 1: Buscar animación con expresión (expresión-stance)
		# Ejemplo: "happy-idle"
		if not expression.is_empty():
			var specific_anim = expression + "-" + stance
			if sprite_frames.has_animation(specific_anim):
				final_animation_to_play = specific_anim
	
	# FALLBACK GENERAL: Si ninguna de las búsquedas anteriores tuvo éxito
	if final_animation_to_play.is_empty():
		# Usamos la animación de stance básica como último recurso
		# Ejemplo: "talking" o "idle"
		final_animation_to_play = stance

	# --- FIN DE LA LÓGICA DE BÚSQUEDA ---

	# Reproducir la animación encontrada o mostrar una advertencia si ni siquiera el fallback existe
	if sprite_frames.has_animation(final_animation_to_play):
		animated_sprite.play(final_animation_to_play)
	else:
		print("ADVERTENCIA: La animación de fallback '", final_animation_to_play, "' no fue encontrada. Revisa el recurso SpriteFrames del personaje.")
	
	show_sprite()

func get_current_expression() -> String:
	return self.current_expression

func get_current_character_name() -> String:
	return self.current_character_name

# Almacena la última posición
func set_last_known_position(pos: Vector2):
	last_known_position = pos

func set_expression(expression: String, is_talking: bool):
	self.current_expression = expression
	
	var stance = "talking" if is_talking else "idle"
	var animation_name = expression + "-" + stance
	
	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
	else:
		animated_sprite.play(stance)

func move_to_position(target_position: Vector2, duration: float = 0.5):
	""" Mueve el sprite a la posición deseada de forma suave. """
	var tween = create_tween()
	# Animamos la propiedad 'position' del nodo Control
	tween.tween_property(self, "position", target_position, duration)
	

func slide_offset(pixel_offset: float, duration: float = 0.5):
	""" Mueve el sprite horizontalmente con un efecto de slide. """
	var target_x = self.position.x + pixel_offset
	var tween = create_tween()
	tween.tween_property(self, "position:x", target_x, duration).set_trans(Tween.TRANS_SINE)

# Función modificada para recibir la posición de destino
func slide_to_position(target_position: Vector2, duration: float = 0.5) -> Tween:
	""" Mueve el sprite a la posición deseada de forma suave y devuelve el Tween. """
	var tween = create_tween()
	tween.tween_property(self, "position", target_position, duration).set_trans(Tween.TRANS_SINE)
	# Devuelve la instancia del tween para poder monitorearla
	return tween
