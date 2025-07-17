extends Control

signal text_animation_done
signal choice_selected

#precarga de escena de eleccion
const ChoiceButtonScene = preload("res://Scenes/player_choice.tscn")

@onready var dialog_line: RichTextLabel = %DialogLine
@onready var speaker_name: Label = %SpeakerName
@onready var choice_list: VBoxContainer = %ChoiceList
@onready var text_blip_sound: AudioStreamPlayer = $TextBlipSound
@onready var text_blip_timer: Timer = $TextBlipTimer
@onready var sentence_pause_timer: Timer = %SentencePauseTimer


const ANIMATION_SPEED : int = 30
const NO_SOUND_CHARS : Array = [".", "!", "?"]

var animate_text : bool = false
var current_visible_characters : int = 0
var current_character_details : Dictionary

func _ready() -> void:
	#Resetear display
	choice_list.hide()
	dialog_line.text = ""
	speaker_name.text = ""
	
	#conectar señales
	text_blip_timer.timeout.connect(_on_text_blip_timeout)
	sentence_pause_timer.timeout.connect(_on_sentence_pause_timeout)

func _process(delta: float) -> void:
	if animate_text and sentence_pause_timer.is_stopped():
		if dialog_line.visible_ratio < 1:
			dialog_line.visible_ratio += (1.0 / dialog_line.text.length()) * (ANIMATION_SPEED * delta)
			if dialog_line.visible_characters > current_visible_characters:
				current_visible_characters = dialog_line.visible_characters
				var current_char = dialog_line.text[current_visible_characters - 1]
				if current_visible_characters < dialog_line.text.length():
					var next_char = dialog_line.text[current_visible_characters]
					if NO_SOUND_CHARS.has(current_char) and next_char == " ":
						text_blip_timer.stop()
						sentence_pause_timer.start()
		else:
			animate_text = false
			text_blip_timer.stop()
			text_animation_done.emit()

func change_line(character_name: Character.Name, line : String):
	current_character_details = Character.CHARACTER_DETAILS[character_name]
	speaker_name.text = current_character_details["name"]
	current_visible_characters = 0
	dialog_line.text = line
	dialog_line.visible_characters = 0
	animate_text = true
	text_blip_timer.start()

func display_choices(choices: Array):
	#primero borrar cualquier opcion existente anterior
	for child in choice_list.get_children():
		child.queue_free()
	#Crear un nuevo boton por cada opcion
	for choice in choices:
		var choice_button = ChoiceButtonScene.instantiate()
		choice_button.text = choice["text"]
		#Adjuntar señal al botón
		choice_button.pressed.connect(_on_choice_button_pressed.bind(choice["goto"]))
		#agregar boton al la lista de opciones
		choice_list.add_child(choice_button)
	#mostrar la lista de opciones (visible)
	choice_list.show()

func skip_text_animation():
	dialog_line.visible_ratio = 1

func _on_text_blip_timeout():
	text_blip_sound.play_sound(current_character_details)

func _on_sentence_pause_timeout():
	text_blip_timer.start()

func _on_choice_button_pressed(anchor: String):
	choice_selected.emit(anchor)
	choice_list.hide()
