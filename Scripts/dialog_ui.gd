# dialog_ui.gd
extends Control

signal text_animation_done
signal choice_selected(choice_data: Dictionary, item_given_data: Dictionary)

@onready var dialog_line: RichTextLabel = %DialogLine
@onready var speaker_box: PanelContainer = %SpeakerBox
@onready var speaker_name: Label = %SpeakerName
@onready var choice_list: VBoxContainer = %ChoiceList
@onready var text_blip_sound: AudioStreamPlayer = $TextBlipSound # Asumiendo que es un AudioStreamPlayer
@onready var sentence_pause_timer: Timer = %SentencePauseTimer
@onready var dialog_box: PanelContainer = %DialogBox
@onready var triangle_next: Polygon2D = %triangleNext

#precarga de escena de eleccion
const ChoiceButtonScene = preload("res://Scenes/player_choice.tscn")

const ANIMATION_SPEED : int = 30
const NO_SOUND_CHARS : Array = [".", "!", "?"]

var animate_text : bool = false
var current_visible_characters : int = 0
var current_character_details : Dictionary

# === NUEVAS VARIABLES: Serán asignadas por main_scene ===
var dialogue_manager_ref: Node = null
var next_sentence_sound_ref: AudioStreamPlayer = null

func _ready() -> void:
	#Resetear display
	choice_list.hide()
	dialog_line.text = ""
	speaker_name.text = ""
	triangle_next.hide()
	
	#conectar señales
	dialog_box.dialog_clicked.connect(_handle_mouse_click)
	sentence_pause_timer.timeout.connect(_on_sentence_pause_timeout)

func _handle_mouse_click():
	if dialogue_manager_ref == null or next_sentence_sound_ref == null:
		printerr("Error: Dependencias del diálogo no asignadas en DialogUI.")
		return

	var current_line = {}
	if dialogue_manager_ref.dialog_index < dialogue_manager_ref.dialog_lines.size():
		current_line = dialogue_manager_ref.dialog_lines[dialogue_manager_ref.dialog_index]

	var has_choices = current_line.has("choices")

	if not has_choices:
		if animate_text:
			skip_text_animation()
		else:
			next_sentence_sound_ref.play()
			dialogue_manager_ref.advance_index()
			dialogue_manager_ref.process_current_line()

func set_dialog_dependencies(dm: Node, nss: AudioStreamPlayer):
	dialogue_manager_ref = dm
	next_sentence_sound_ref = nss
	#print("DialogUI: Dependencias asignadas correctamente.") # Para depuración

func _process(delta: float) -> void:
	# Si la animación está activa y el temporizador no está contando...
	if animate_text and sentence_pause_timer.is_stopped():
		if dialog_line.visible_ratio < 1:
			dialog_line.visible_ratio += (1.0 / dialog_line.text.length()) * (ANIMATION_SPEED * delta)
			if dialog_line.visible_characters > current_visible_characters:
				current_visible_characters = dialog_line.visible_characters
				var current_char = dialog_line.text[current_visible_characters - 1]
				# Si el siguiente caracter es un espacio y el actual es un signo de puntuación...
				if current_visible_characters < dialog_line.text.length():
					var next_char = dialog_line.text[current_visible_characters]
					if NO_SOUND_CHARS.has(current_char) and next_char == " ":
						# Asegurarse de que text_blip_sound tiene una propiedad is_playing_expression_sound
						# o ajusta a text_blip_sound.playing si es un AudioStreamPlayer normal
						if text_blip_sound and text_blip_sound.is_playing(): # Usar is_playing() para AudioStreamPlayer
							sentence_pause_timer.start()
						else:
							text_blip_sound.stop() # Usar stop() para AudioStreamPlayer
							sentence_pause_timer.start()
		else:
			# Si la animación ha terminado
			animate_text = false
			if text_blip_sound: # Asegurarse de que no es null antes de llamar stop
				text_blip_sound.stop()
			text_animation_done.emit()
			triangle_next.show()

func change_line(character_name: Character.Name, line : String, expression: String = ""):
	# Obtiene los detalles del personaje
	current_character_details = Character.CHARACTER_DETAILS[character_name]
	var speaker_color = current_character_details.get("color", Color.WHITE)
	
	# Detener cualquier sonido de la línea anterior
	if text_blip_sound: # Asegurarse de que no es null antes de llamar stop
		text_blip_sound.stop()
	
	# Comprueba si el personaje es el narrador
	if current_character_details.get("name", "") == "":
		speaker_box.hide() # Oculta la caja del orador
		speaker_name.text = "" # Asegúrate de que el nombre del orador esté vacío
	else:
		speaker_box.show() # Muestra la caja del orador
		speaker_name.text = current_character_details["name"]
		speaker_name.add_theme_color_override("font_color", speaker_color)
		
		# Asegurarse de que text_blip_sound tiene un método start_dialogue_sound
		if text_blip_sound:
			text_blip_sound.start_dialogue_sound(current_character_details, expression)
	
	current_visible_characters = 0
	dialog_line.text = line
	dialog_line.visible_characters = 0
	animate_text = true
	triangle_next.hide()

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
	if text_blip_sound: # Asegurarse de que no es null antes de llamar stop
		text_blip_sound.stop()
	triangle_next.show()

func _on_sentence_pause_timeout():
	# Reanuda el audio y la animación después de la pausa
	if text_blip_sound: # Asegurarse de que no es null antes de llamar
		text_blip_sound.start_dialogue_sound(current_character_details, "")
