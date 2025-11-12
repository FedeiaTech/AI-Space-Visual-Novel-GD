# text_blip_sound.gd
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
const SOUNDS_NARRATOR: Array[AudioStream] = [
	preload("res://Assets/Sounds/Voices/keyboard_sound.mp3")
]

var current_gender_sounds: Array[AudioStream]
var is_active: bool = false
var is_playing_expression_sound: bool = false

func _ready():
	# Conectar la señal `finished` del propio AudioStreamPlayer.
	finished.connect(_on_audio_finished)

# Esta función se encargará de iniciar el bucle de sonidos de diálogo.
func play_sound():
	if not is_active:
		is_active = true
		_start_next_random_sound()

func start_dialogue_sound(character_details: Dictionary, expression: String):
	if is_active:
		return

	is_active = true
	is_playing_expression_sound = false

	var character_name = character_details.get("name", "")

	# 1. ESTABLECER EL GÉNERO PRIMERO (para que _on_audio_finished funcione)
	# Esto establece el sonido "de reserva" que se reproducirá después 
	# de la expresión, o si no hay expresión.
	if character_name == "":
		# Es el Narrador
		current_gender_sounds = SOUNDS_NARRATOR
		pitch_scale = 1.0
	else:
		# Es un personaje, establecer su género
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
	
	# 2. AHORA, buscar y reproducir el sonido de la expresión (si existe)
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

func stop_sound():
	is_active = false
	is_playing_expression_sound = false
	stop()

func _start_next_random_sound():
	# Verifica si la matriz no está vacía antes de llamar a pick_random()
	if not is_active or current_gender_sounds.is_empty():
		return
	
	var random_sound = current_gender_sounds.pick_random()
	stream = random_sound
	play()

func _on_audio_finished():
	if not is_active:
		return

	if is_playing_expression_sound:
		is_playing_expression_sound = false
		_start_next_random_sound()
	else:
		_start_next_random_sound()
