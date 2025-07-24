extends Control

signal text_animation_done
signal choice_selected(choice_data: Dictionary, item_given_data: Dictionary)


@onready var dialog_line: RichTextLabel = %DialogLine
@onready var speaker_box: PanelContainer = %SpeakerBox
@onready var speaker_name: Label = %SpeakerName
@onready var choice_list: VBoxContainer = %ChoiceList
@onready var text_blip_sound: AudioStreamPlayer = $TextBlipSound
@onready var text_blip_timer: Timer = $TextBlipTimer
@onready var sentence_pause_timer: Timer = %SentencePauseTimer

#precarga de escena de eleccion
const ChoiceButtonScene = preload("res://Scenes/player_choice.tscn")

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
	# Obtiene los detalles del personaje
	current_character_details = Character.CHARACTER_DETAILS[character_name]
	
	# Comprueba si el personaje es el narrador
	if character_name == Character.Name.NARRATOR:
		speaker_box.hide() # Oculta la caja del orador
		speaker_name.text = "" # Asegúrate de que el nombre del orador esté vacío
	else:
		speaker_box.show() # Muestra la caja del orador
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
		
		# Obtener los datos del ítem, si existen
		var item_given_data = null
		if choice.has("item_given"):
			item_given_data = choice["item_given"]
			
		# Adjuntar señal al botón, pasando el 'item_given_data'
		choice_button.pressed.connect(func():
			# Emitir el diccionario 'choice' completo(MainScene decide si es 'goto' o 'action')
			choice_selected.emit(choice, item_given_data)
			choice_list.hide()
			)
		#agregar boton al la lista de opciones
		choice_list.add_child(choice_button)
	#mostrar la lista de opciones (visible)
	choice_list.show()

func skip_text_animation():
	dialog_line.visible_ratio = 1

func _on_text_blip_timeout():
	# Solo reproducir sonido si no es el narrador
	if current_character_details.get("name", "") != "": # Asume que el narrador tiene nombre vacío
		text_blip_sound.play_sound(current_character_details)

func _on_sentence_pause_timeout():
	text_blip_timer.start()

# Elimina o deja vacía esta función, ya no es necesaria si el botón conecta directamente.
# El método que recibe la señal del botón de elección ahora acepta el `item_given_data`
#func _on_choice_button_pressed(anchor: String, item_given_data: Dictionary):
	# Emitir la señal con los datos del ítem
	#choice_selected.emit(anchor, item_given_data) 
	#choice_list.hide()
