# dialog_ui.gd
extends Control

signal text_animation_done
signal choice_selected(choice_data: Dictionary, item_given_data: Dictionary)

@onready var dialog_line: RichTextLabel = %DialogLine
@onready var speaker_box: PanelContainer = %SpeakerBox
@onready var speaker_name: Label = %SpeakerName
@onready var choice_list: VBoxContainer = %ChoiceList
@onready var text_blip_sound: AudioStreamPlayer = $TextBlipSound
@onready var sentence_pause_timer: Timer = %SentencePauseTimer
@onready var dialog_box: PanelContainer = %DialogBox
@onready var triangle_next: Polygon2D = %triangleNext
@onready var triangle_particles: CPUParticles2D = %triangleParticles

#precarga de escena de eleccion
const ChoiceButtonScene = preload("res://Scenes/player_choice.tscn")

const ANIMATION_SPEED : int = 30
const SENTENCE_PAUSE : float = 0.5
const NO_SOUND_CHARS : Array = [".", "!", "?"]

var animate_text : bool = false
var current_visible_characters : int = 0
var current_character_details : Dictionary
var can_advance_dialogue: bool = true

# Variables asignadas por main_scene ===
var dialogue_manager_ref: Node = null
var next_sentence_sound_ref: AudioStreamPlayer = null
var main_scene_ref: Node = null

func _ready() -> void:
	#Resetear display
	choice_list.hide()
	dialog_line.text = ""
	speaker_name.text = ""
	triangle_next.hide()
	triangle_particles.hide()
	
	#conectar señales
	dialog_box.dialog_clicked.connect(_handle_mouse_click)
	sentence_pause_timer.timeout.connect(_on_sentence_pause_timeout)
	
func set_click_to_continue_enabled(enabled: bool):
	can_advance_dialogue = enabled
	if not enabled:
		triangle_next.hide()
		triangle_particles.hide()
	else:
		if not animate_text:
			triangle_next.show()
			triangle_particles.show()

func _handle_mouse_click():
	if main_scene_ref.is_dialogue_blocked:
		return
		
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

# Recibir referencia de la escena principal
func set_dialog_dependencies(dm: Node, nss: AudioStreamPlayer, ms: Node):
	dialogue_manager_ref = dm
	next_sentence_sound_ref = nss
	main_scene_ref = ms # Guardamos la referencia

func _process(delta: float) -> void:
	if animate_text and sentence_pause_timer.is_stopped():
		if dialog_line.visible_ratio < 1:
			dialog_line.visible_ratio += (1.0 / dialog_line.text.length()) * (ANIMATION_SPEED * delta)
			if dialog_line.visible_characters > current_visible_characters:
				current_visible_characters = dialog_line.visible_characters
				var current_char = dialog_line.text[current_visible_characters - 1]
				
				# Verifica si el caracter actual es un signo de puntuación
				if NO_SOUND_CHARS.has(current_char):
					# Detiene el sonido y la animación, y espera
					if text_blip_sound and text_blip_sound.is_playing():
						text_blip_sound.stop_sound()
					
					if current_visible_characters < dialog_line.text.length():
						sentence_pause_timer.start(SENTENCE_PAUSE)
				else:
					# Si no es un signo de puntuación, asegúrate de que el sonido se esté reproduciendo
					if text_blip_sound and not text_blip_sound.is_playing():
						text_blip_sound.play_sound()
		else:
			animate_text = false
			if text_blip_sound:
				text_blip_sound.stop_sound()
			text_animation_done.emit()
			triangle_next.show()
			triangle_particles.show()

# CORRECCIÓN 1: Cambia la firma para que reciba el nombre como String
func change_line(speaker_key: String, text: String, character_details: Dictionary, expression: String = ""):
	# Detener cualquier sonido de la línea anterior
	if text_blip_sound:
		text_blip_sound.stop_sound()
	
	# Si la clave es Narrador o está vacía...
	if speaker_key.to_upper() == "NARRATOR" or speaker_key.is_empty():
		speaker_box.hide()
		speaker_name.text = ""
		current_character_details = {}
		
		# --- COLOR DEL NARRADOR ---
		# Usa el color definido en Character.gd para el texto del diálogo.
		var narrator_text_color = character_details.get("color", Color.GRAY) # Gris como color de respaldo
		dialog_line.add_theme_color_override("default_color", narrator_text_color)
	else:
		# Lógica existente para otros personajes
		if not character_details.is_empty():
			speaker_box.show()
			speaker_name.text = character_details.get("name", speaker_key)
			var speaker_color = character_details.get("color", Color.WHITE)
			speaker_name.add_theme_color_override("font_color", speaker_color)
			
			if text_blip_sound:
				text_blip_sound.start_dialogue_sound(character_details, expression)
		else:
			printerr("Error en DialogUI: No se recibieron detalles para el personaje: ", speaker_key)
			speaker_box.show()
			speaker_name.text = speaker_key
		
		# Para cualquier otro personaje, nos aseguramos de que el texto sea blanco.
		dialog_line.add_theme_color_override("default_color", Color.WHITE)

	current_visible_characters = 0
	dialog_line.text = text
	dialog_line.visible_characters = 0
	animate_text = true
	triangle_next.hide()
	triangle_particles.hide()

func display_choices(choices: Array):
	for child in choice_list.get_children():
		child.queue_free()
		
	for choice in choices:
		var choice_button = ChoiceButtonScene.instantiate()
		choice_button.text = choice["text"]
		
		var item_given_data = null
		if choice.has("item_given"):
			item_given_data = choice["item_given"]
			
		choice_button.pressed.connect(func():
			choice_selected.emit(choice, item_given_data)
			choice_list.hide()
			)
		choice_list.add_child(choice_button)
		
	choice_list.show()

func skip_text_animation():
	dialog_line.visible_ratio = 1
	if text_blip_sound:
		text_blip_sound.stop_sound()
	triangle_next.show()
	triangle_particles.show()

func _on_sentence_pause_timeout():
	# Reanuda la animación y el sonido de diálogo
	animate_text = true
	if text_blip_sound:
		text_blip_sound.play_sound()
