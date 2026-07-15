# character_sprite.gd
extends Control

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Variables para posición y estado
var current_position: Character.Position = Character.Position.CENTER
var current_character_name: String = ""
var last_known_position: Vector2 = Vector2.ZERO
var current_facing_direction: String = "right"
var current_expression: String = "idle"

# --- NUEVAS VARIABLES PARA WAITING ---
var waiting_timer: Timer
var is_playing_waiting_anim: bool = false

func _ready() -> void:
	self.modulate.a = 0
	
	# 1. Crear y configurar el Timer por código
	waiting_timer = Timer.new()
	waiting_timer.one_shot = true
	waiting_timer.timeout.connect(_on_waiting_timer_timeout)
	add_child(waiting_timer)
	
	# 2. Conectar señal de fin de animación del sprite
	if animated_sprite:
		animated_sprite.animation_finished.connect(_on_sprite_animation_finished)

func show_sprite():
	self.visible = true
	if self.modulate.a < 1.0:
		create_tween().tween_property(self, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE)

func hide_sprite():
	waiting_timer.stop() # Parar timer si se oculta
	if self.modulate.a > 0.0:
		create_tween().tween_property(self, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE)

func hide_instantly():
	waiting_timer.stop()
	modulate.a = 0.0
	
func change_character(character_name: Character.Name, is_talking: bool, expression: String, position_to_set: Character.Position = Character.Position.CENTER):
	# (Mantenemos compatibilidad, aunque usas más la otra función)
	var character_details = Character.CHARACTER_DETAILS.get(character_name)
	var target_x = Character.POSITIONS[position_to_set]
	var target_position = Vector2(target_x, position.y)
	move_to_position(target_position, 0.5)
	
	if not character_details or not character_details.get("sprite_frames"):
		hide_instantly()
		return
	
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
	
	# Gestionar el timer de espera
	if not is_talking:
		_start_waiting_timer()
	else:
		waiting_timer.stop()
		is_playing_waiting_anim = false
	
	show_sprite()

func play_idle_animation():
	# Detenemos cualquier lógica de waiting anterior
	is_playing_waiting_anim = false
	
	var last_animation = animated_sprite.animation
	
	# Lógica para volver a idle desde talking
	if last_animation and not last_animation.ends_with("-idle") and not last_animation.contains("waiting"):
		var idle_expression = last_animation.replace("talking", "idle")
		if animated_sprite.sprite_frames.has_animation(idle_expression):
			animated_sprite.play(idle_expression)
		else:
			# Fallback inteligente según personaje
			if current_character_name == "Astro":
				animated_sprite.play("idle_" + current_facing_direction)
			else:
				animated_sprite.play("idle")
	
	# Iniciamos el contador para la animación de espera
	_start_waiting_timer()

func stop_talking():
	if animated_sprite.current_animation.begins_with("talking") or "talking" in animated_sprite.current_animation:
		# En lugar de solo parar, forzamos el idle para reiniciar el ciclo de espera
		play_idle_animation()

func resume_talking():
	waiting_timer.stop() # Si habla, no espera
	if animated_sprite.current_animation.begins_with("talking") or "talking" in animated_sprite.current_animation:
		animated_sprite.play()

# Función principal de cambio de personaje
func change_character_with_position(character_enum: Character.Name, is_talking: bool, expression: String, target_position: Vector2, facing_direction: String):
	self.current_expression = expression
	
	# Reseteamos estado de waiting porque hubo una acción nueva
	is_playing_waiting_anim = false
	waiting_timer.stop()
	
	var character_details = Character.CHARACTER_DETAILS.get(character_enum)
	
	if not character_details or not character_details.get("sprite_frames"):
		hide_instantly()
		return

	self.current_character_name = character_details.get("name", "")
	self.current_facing_direction = facing_direction
	var sprite_frames = character_details["sprite_frames"]
	animated_sprite.sprite_frames = sprite_frames
	
	slide_to_position(target_position, 0.5)

	# --- LÓGICA DE ANIMACIÓN ---
	var stance = "talking" if is_talking else "idle"
	var final_animation_to_play = ""

	# ASTRO
	if self.current_character_name == "Astro":
		animated_sprite.flip_h = false
		if not expression.is_empty():
			var specific_anim = expression + "-" + stance + "_" + self.current_facing_direction
			if sprite_frames.has_animation(specific_anim):
				final_animation_to_play = specific_anim

		if final_animation_to_play.is_empty():
			var base_directional_anim = stance + "_" + self.current_facing_direction
			if sprite_frames.has_animation(base_directional_anim):
				final_animation_to_play = base_directional_anim

	# OTROS PERSONAJES
	else:
		if self.current_facing_direction == "left":
			animated_sprite.flip_h = true
		else:
			animated_sprite.flip_h = false

		if not expression.is_empty():
			var specific_anim = expression + "-" + stance
			if sprite_frames.has_animation(specific_anim):
				final_animation_to_play = specific_anim
	
	# FALLBACK
	if final_animation_to_play.is_empty():
		final_animation_to_play = stance

	if sprite_frames.has_animation(final_animation_to_play):
		animated_sprite.play(final_animation_to_play)
	else:
		print("ADVERTENCIA: Animación no encontrada: ", final_animation_to_play)
	
	# Si NO está hablando (está idle), iniciamos la cuenta regresiva
	if not is_talking:
		_start_waiting_timer()
		
	show_sprite()

func get_current_expression() -> String:
	return self.current_expression

func get_current_character_name() -> String:
	return self.current_character_name

func set_last_known_position(pos: Vector2):
	last_known_position = pos

func set_expression(expression: String, is_talking: bool):
	# Cualquier cambio de expresión reinicia el timer
	is_playing_waiting_anim = false
	waiting_timer.stop()
	
	self.current_expression = expression
	var stance = "talking" if is_talking else "idle"
	var animation_name = expression + "-" + stance
	
	# (Nota: Aquí faltaría la lógica de Astro izquierda/derecha si quisieras ser exhaustivo,
	# pero asumimos que usas change_character_with_position casi siempre)
	
	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
	else:
		animated_sprite.play(stance)
		
	if not is_talking:
		_start_waiting_timer()

func move_to_position(target_position: Vector2, duration: float = 0.5):
	var tween = create_tween()
	tween.tween_property(self, "position", target_position, duration)

func slide_offset(pixel_offset: float, duration: float = 0.5):
	var target_x = self.position.x + pixel_offset
	var tween = create_tween()
	tween.tween_property(self, "position:x", target_x, duration).set_trans(Tween.TRANS_SINE)

func slide_to_position(target_position: Vector2, duration: float = 0.5) -> Tween:
	var tween = create_tween()
	tween.tween_property(self, "position", target_position, duration).set_trans(Tween.TRANS_SINE)
	return tween

# --- LÓGICA INTERNA DE WAITING ---

func _start_waiting_timer():
	# Excepciones: No aplicar a Spark ni Narrador (aunque Narrador no suele tener sprite aquí)
	if current_character_name == "Spark (IA)" or current_character_name == "Narrator":
		return
		
	# Tiempo aleatorio entre 10 y 20 segundos
	var time = randf_range(10.0, 20.0)
	waiting_timer.start(time)

func _on_waiting_timer_timeout():
	# Si el personaje está oculto o hablando, no hacer nada
	if modulate.a == 0 or animated_sprite.animation.contains("talking"):
		return

	var waiting_anim = ""
	
	# Determinar nombre de la animación
	if current_character_name == "Astro":
		waiting_anim = "waiting_" + current_facing_direction
	else:
		waiting_anim = "waiting" # El flip_h ya está configurado por el estado idle
	
	# Intentar reproducir
	if animated_sprite.sprite_frames.has_animation(waiting_anim):
		animated_sprite.play(waiting_anim)
		is_playing_waiting_anim = true
	else:
		# Si no tiene animación de espera, reiniciamos el timer para intentarlo luego
		# (o simplemente seguimos en idle)
		_start_waiting_timer()

func _on_sprite_animation_finished():
	# Solo si terminamos una animación de "waiting", volvemos a idle
	if is_playing_waiting_anim:
		is_playing_waiting_anim = false
		
		# Volver a la animación idle correcta según personaje y dirección
		if current_character_name == "Astro":
			# Intentar idle con expresión (ej: happy-idle_left)
			var specific_idle = current_expression + "-idle_" + current_facing_direction
			if animated_sprite.sprite_frames.has_animation(specific_idle):
				animated_sprite.play(specific_idle)
			else:
				animated_sprite.play("idle_" + current_facing_direction)
		else:
			# Personajes normales
			var specific_idle = current_expression + "-idle"
			if animated_sprite.sprite_frames.has_animation(specific_idle):
				animated_sprite.play(specific_idle)
			else:
				animated_sprite.play("idle")
		
		# Reiniciar el ciclo para que vuelva a esperar otra vez
		_start_waiting_timer()
