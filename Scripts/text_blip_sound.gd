#text_blip_sound.gd
extends AudioStreamPlayer

# Diccionario de audios por género.
const SOUNDS_MALE: Array[AudioStream] = [
	preload("res://Assets/Sounds/Voices/male/man_bubbling 1.wav"),
	preload("res://Assets/Sounds/Voices/male/man_bubbling 2.wav"),
	preload("res://Assets/Sounds/Voices/male/man_bubbling 3.wav"),
	preload("res://Assets/Sounds/Voices/male/man_bubbling 4.wav"),
	preload("res://Assets/Sounds/Voices/male/man_bubbling 5.wav"),
	preload("res://Assets/Sounds/Voices/male/man_bubbling 6.wav"),
	preload("res://Assets/Sounds/Voices/male/man_bubbling 7.wav"),
	preload("res://Assets/Sounds/Voices/male/man_bubbling 8.wav"),
	]

const SOUNDS_FEMALE: Array[AudioStream] = SOUNDS_MALE
const SOUNDS_OTHER: Array[AudioStream] = SOUNDS_MALE

var current_gender_sounds: Array[AudioStream]
var is_active: bool = false
var is_playing_expression_sound: bool = false 
#var audio_completed_timer: Timer = Timer.new()

func _ready():
	# Conectar la señal `finished` del propio AudioStreamPlayer.
	finished.connect(_on_audio_finished)
	# Conectar una señal del Timer para gestionar la reproducción.
	##add_child(audio_completed_timer)
	##audio_completed_timer.timeout.connect(_on_audio_finished)

func start_dialogue_sound(character_details: Dictionary, expression: String):
	if is_active:
		return
	
	is_active = true
	is_playing_expression_sound = false
	
	# 1. Configurar los sonidos aleatorios para más tarde
	var character_gender = character_details.get("gender", "-")
	match character_gender:
		"male":
			current_gender_sounds = SOUNDS_MALE
			pitch_scale = 1.0
		"female":
			current_gender_sounds = SOUNDS_FEMALE
			pitch_scale = 1.5
		_:
			current_gender_sounds = SOUNDS_OTHER
			pitch_scale = 0.5
			
	# 2. Buscar y reproducir el sonido de la expresión
	var expression_sounds = character_details.get("expression_sounds", {})
	if not expression.is_empty() and expression_sounds.has(expression):
		var expression_sound = expression_sounds[expression]
		if expression_sound is AudioStream:
			is_playing_expression_sound = true
			stream = expression_sound
			play()
			return # Salimos para esperar a que termine el sonido de expresión
			
	# 3. Si no hay sonido de expresión, empezar directamente con los aleatorios
	_start_next_random_sound()

#func play_random_sound(character_details: Dictionary):
	## Si ya está activo, no hacemos nada para evitar superposiciones.
	#if is_active:
		#return
	#
	#is_active = true
	#var character_gender = character_details["gender"]
	#
	## Seleccionar el array de audios según el género.
	#match character_gender:
		#"male":
			#current_gender_sounds = SOUNDS_MALE
			#pitch_scale = 1.0
		#"female":
			#current_gender_sounds = SOUNDS_FEMALE
			#pitch_scale = 1.5
		#_: # Para cualquier otro caso (p. ej. "-")
			#current_gender_sounds = SOUNDS_OTHER
			#pitch_scale = 0.5
#
	#_start_next_random_sound()

func stop_sound():
	is_active = false
	is_playing_expression_sound = false
	stop()
	#audio_completed_timer.stop()

func _start_next_random_sound():
	# Si no está activo, no reproducir nada.
	if not is_active:
		return
	
	var random_sound = current_gender_sounds.pick_random()
	stream = random_sound
	play()
	
	# El timer actúa como un fallback si la señal `finished` falla.
	# Le damos un poco más de tiempo para asegurarnos de que la reproducción ha finalizado.
	#audio_completed_timer.start(stream.get_length() + 0.1)

func _on_audio_finished():
	if is_active:
		# Reproduce un nuevo audio aleatorio si el sistema está activo.
		_start_next_random_sound()
	# Si el sonido que terminó era el de la expresión...
	if is_playing_expression_sound:
		is_playing_expression_sound = false
		# ...ahora comenzamos el bucle de sonidos aleatorios.
		_start_next_random_sound()
	else:
		# Si era un sonido aleatorio, continuamos con el siguiente.
		_start_next_random_sound()
