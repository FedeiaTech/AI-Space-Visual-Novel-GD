#character_sprite.gd
extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	self.modulate.a = 0

func show_sprite():
	# Muestra el sprite con un fundido de entrada (fade-in)
	if self.modulate.a < 1.0:
		create_tween().tween_property(self, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE)

func hide_sprite():
	# Oculta el sprite con un fundido de salida (fade-out)
	if self.modulate.a > 0.0:
		create_tween().tween_property(self, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE)

func change_character(character_name : Character.Name, is_talking:bool, expression: String):
	# Obtenemos los detalles para asegurar que el personaje tiene un sprite
	var character_details = Character.CHARACTER_DETAILS.get(character_name)
	if not character_details or not character_details.get("sprite_frames"):
		# Si se intenta cambiar a un personaje sin sprite (como IA o Narrador),
		# simplemente no hacemos nada aquí.
		return
	
	var sprite_frames = Character.CHARACTER_DETAILS[character_name]["sprite_frames"]
	var stance = "talking" if is_talking else "idle"
	var animation_name = expression + "-" + stance if expression else stance
	#Si el personaje tiene sprite frames, actualiza animated_sprite y reproduce la animacion
	if sprite_frames:
		animated_sprite.sprite_frames = sprite_frames
		#Verifica si la animacion de la expresion asociada existe
		#Si no, reproduce la animacion por defecto (stance)
		if animated_sprite.sprite_frames.has_animation(animation_name):
			animated_sprite.play(animation_name)
		else:
			animated_sprite.play(stance)
""""""
	#else:
		##Cambia a la animacion "idle" del personaje actual mostrado
		#play_idle_animation()
	#
	#if self.modulate.a == 0:
		#create_tween().tween_property(self, "modulate:a", 1.0, 0.3)

func play_idle_animation():
	var last_animation = animated_sprite.animation
	if last_animation and not last_animation.ends_with("-idle"):
		#Si una expresion personalizada es mostrada, intenta buscar equivalente "idle"
		#Si existe, la reproduce o de lo contrario, reproduce "idle"
		var idle_expression = last_animation.replace("talking", "idle")
		if animated_sprite.sprite_frames.has_animation(idle_expression):
			animated_sprite.play(idle_expression)
		else:
			animated_sprite.play("idle")
