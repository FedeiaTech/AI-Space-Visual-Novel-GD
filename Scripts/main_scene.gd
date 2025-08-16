# main_scene.gd
# Coordinador general. Maneja señales, input global, transiciones.
extends Node2D

# === Referencias a nodos ===
@onready var background: TextureRect = %Background
@onready var background_music: AudioStreamPlayer = %BackgroundMusic
@onready var character_sprite = $CanvasMain/Control/CharacterSprite
@onready var dialog_ui: Control = $CanvasMain/DialogUI
@onready var next_sentence_sound: AudioStreamPlayer = %NextSentenceSound
@onready var journal_ui: Control = %JournalUI

# Notificaciones
@onready var item_acquired_notification: Label = %ItemAcquiredNotification
@onready var notification_timer: Timer = %NotificationTimer
@onready var time_label: Label = $CanvasNotification/TimeLabel
# Nodos Extra
@onready var command_processor: Node = $CommandProcessor
@onready var inventory_ui_manager: Node = %InventoryUIManager
@onready var dialogue_manager: Node = %DialogueManager

# === Variables de estado ===
var transition_effect: String = "fade"

var notification_queue: Array = []
var is_dialog_input_blocked: bool = false
var pending_anchor: String = ""
var is_initial_load_complete: bool = true
var is_transitioning: bool = false

# Carga los datos iniciales del diálogo,
# conecta señales necesarias y lanza la transición de entrada.
func _ready() -> void:
	# Señales
	dialog_ui.text_animation_done.connect(_on_text_animation_done)
	dialog_ui.choice_selected.connect(_on_choice_selected)
	SceneManager.transition_out_completed.connect(_on_transition_out_completed)
	SceneManager.transition_in_completed.connect(_on_transition_in_completed)
	GameManager.new_dialog_file_requested.connect(_on_new_dialog_file_requested)
	dialogue_manager.line_processed.connect(_on_dialogue_manager_line_processed)
	dialogue_manager.dialogue_finished.connect(_on_dialogue_manager_finished)
	notification_timer.timeout.connect(_on_notification_timer_timeout)
	GameEvents.item_acquired_notification_requested.connect(show_item_acquired_notification_requested)
	TimeManager.time_updated.connect(func(new_time): time_label.text = new_time)

	# Ocultar etiqueta tiempo
	time_label.hide()
	# Carga inicial manejada por DialogManager
	var initial_dialog_file = "res://Resources/Story/intro.json"
	dialogue_manager.load_dialog_file(initial_dialog_file)
	
	is_transitioning = true
	SceneManager.transition_in(transition_effect)

# Captura las entradas del jugador. Permite avanzar el diálogo y alternar el inventario.
func _input(event: InputEvent) -> void:
	# Si estamos en una transición, no procesar ninguna entrada.
	if is_transitioning: return
	
	if event.is_action_pressed("toggle_journal"):
		if journal_ui.visible:
			journal_ui.hide()
		else:
			journal_ui.show()
		# Marcamos el evento como manejado para que no interfiera con el diálogo
		get_viewport().set_input_as_handled()
		return # Salimos para no procesar "next_line" si estamos abriendo/cerrando el diario
	
	# Si el diario está visible, no procesar más inputs de juego
	if journal_ui.visible: return
	
	if is_dialog_input_blocked and event.is_action_pressed("next_line"): return

	var current_line = {}
	if dialogue_manager.dialog_index < dialogue_manager.dialog_lines.size():
		current_line = dialogue_manager.dialog_lines[dialogue_manager.dialog_index]

	var has_choices = current_line.has("choices")

	if event.is_action_pressed("next_line") and not has_choices:
		if dialog_ui.animate_text:
			dialog_ui.skip_text_animation()
		else:
			next_sentence_sound.play()
			dialogue_manager.advance_index()
			dialogue_manager.process_current_line()

	if event.is_action_pressed("toggle_inventory"):
		inventory_ui_manager.toggle_inventory()
		get_viewport().set_input_as_handled()

# Se activa cada vez que el DialogueManager procesa una línea.
func _on_dialogue_manager_line_processed(line: Dictionary):
	# Pasamos la línea al CommandProcessor para que actúe
	command_processor.execute(line)

func _on_dialogue_manager_finished():
	# Decide qué hacer cuando un archivo de diálogo termina.
	# Podrías ocultar la UI, cargar otro archivo, etc.
	print("Se ha terminado un archivo de diálogo.")


# Muestra una notificación cuando se adquiere o actualiza un ítem en el inventario.
func show_item_acquired_notification_requested(item_name: String, quantity_change: int, is_new_item: bool):
	var notification_message: String = ""
	if is_new_item:
		notification_message = "¡Item adquirido!\n" + item_name
	else:
		notification_message = "Cantidad de " + item_name + " aumentada.\n"
		if quantity_change > 0:
			notification_message += "(+" + str(quantity_change) + ")"
	
	notification_queue.append(notification_message)

	if notification_timer.is_stopped() and notification_queue.size() == 1:
		_display_next_notification_from_queue()

""" Señales """

#func _update_character_display(speaker_enum_value: Character.Name, line_text: String, expression: String):
	## Obtiene los detalles del personaje actual
	#var character_details = Character.CHARACTER_DETAILS.get(speaker_enum_value)
	## Comprueba si el personaje tiene sprites definidos
	#var has_sprite = character_details and character_details.get("sprite_frames") != null
#
	## Si el orador es el NARRATOR, o si no hay sprite_frames y el orador NO es un personaje con sprite
	## (ej. si IA está hablando, pero no tiene sprite, no queremos ocultar al personaje anterior)
	#if speaker_enum_value == Character.Name.NARRATOR:
		## Si el narrador habla, siempre ocultamos el sprite del personaje
		#if character_sprite.modulate.a > 0: # Solo si está visible, lo ocultamos con un tween
			#create_tween().tween_property(character_sprite, "modulate:a", 0.0, 0.3)
		## No llamamos a change_character aquí, solo aseguramos que se oculte.
	#elif has_sprite: # Si NO es el narrador y TIENE sprite_frames, entonces lo mostramos y actualizamos
		## Aseguramos que el sprite sea visible (modulate.a == 1)
		#if character_sprite.modulate.a == 0:
			#create_tween().tween_property(character_sprite, "modulate:a", 1.0, 0.3)
		#character_sprite.change_character(speaker_enum_value, true, expression)
	## Si NO es el narrador y NO tiene sprite_frames (como IA), no hacemos nada con la visibilidad del personaje actual.
	## El personaje que estaba antes en pantalla permanecerá.

# Agrega uno o más ítems al inventario del personaje actual.
func _process_item_given(item_data) -> void:
	if item_data is Array:
		for item_details in item_data:
			if item_details is Dictionary and not item_details.is_empty():
				InventoryManager.add_item(InventoryManager.current_player_character, item_details)
	elif item_data is Dictionary and not item_data.is_empty():
		InventoryManager.add_item(InventoryManager.current_player_character, item_data)

# Muestra la próxima notificación de ítem de la cola, si existe.
func _display_next_notification_from_queue():
	if notification_queue.is_empty():
		item_acquired_notification.hide()
	else:
		var next_message = notification_queue.pop_front()
		item_acquired_notification.text = next_message
		item_acquired_notification.show()
		notification_timer.start()

# Evento llamado cuando termina el temporizador de notificaciones.
# Dispara la siguiente en la cola.
func _on_notification_timer_timeout():
	_display_next_notification_from_queue()

# Se ejecuta cuando termina la animación del texto del diálogo.
# Activa la animación "idle" del personaje si corresponde.
func _on_text_animation_done():
	if dialog_ui.current_character_details.has("name") and \
	   dialog_ui.current_character_details["name"] != "" and \
	   dialog_ui.current_character_details.has("sprite_frames") and \
	   dialog_ui.current_character_details["sprite_frames"] != null:
		character_sprite.play_idle_animation()

# Se ejecuta cuando el jugador elige una opción de diálogo.
# Procesa acciones, ítems y transiciones.
func _on_choice_selected(choice_data: Dictionary, _item_given_data = null):
	next_sentence_sound.play()

	if choice_data.has("item_given"):
		command_processor._process_item_given(choice_data["item_given"])

	if choice_data.has("action"):
		command_processor._handle_action(choice_data, false)
	elif choice_data.has("goto"):
		command_processor._handle_goto(choice_data, false)
	else:
		printerr("Error: La elección no tiene ni 'action' ni 'goto'.", choice_data)

# Se ejecuta al finalizar la transición de salida. Carga el nuevo diálogo y salta a anclas si corresponde.
func _on_transition_out_completed():
	# 1. Carga el contenido del nuevo archivo de diálogo.
	pending_anchor = dialogue_manager.pending_anchor
	dialogue_manager.load_dialog_file(dialogue_manager.dialog_file, pending_anchor)
	dialogue_manager.pending_anchor = ""

	if dialogue_manager.dialog_lines.is_empty():
		SceneManager.transition_in(transition_effect)
		return

	# 2. Bucle de pre-procesamiento.
	while dialogue_manager.dialog_index < dialogue_manager.dialog_lines.size():
		var current_line = dialogue_manager.dialog_lines[dialogue_manager.dialog_index]
		
		# Es una línea de setup si no tiene contenido para el jugador (texto/elecciones)
		var is_setup_line = not (current_line.has("text") or current_line.has("choices"))
		
		if is_setup_line:
			# Pre-procesamiento: is_preprocessing es TRUE
			# Esto ejecutará TODOS los comandos en la línea (location, show_character, set_flag, etc.)
			# pero los manejadores que modificamos no intentarán avanzar el diálogo.
			command_processor.execute(current_line, true)
			
			# Nosotros, el bucle, avanzamos el índice.
			dialogue_manager.advance_index()
		else:
			# Encontramos la primera línea con contenido visible. Detenemos el bucle.
			break
	
	# 3. Iniciamos la transición de entrada.
	SceneManager.transition_in(transition_effect)

# Se ejecuta cuando finaliza la transición de entrada.
# Procesa la línea actual y muestra la UI de diálogo.
func _on_transition_in_completed():
	# is_transitioning se debe poner a false *después* de procesar la línea
	# para evitar que el jugador pueda hacer click mientras aparece el texto.
	#character_sprite.show()
	dialog_ui.show() 
	
	dialogue_manager.process_current_line()
	is_transitioning = false

# Al recibir una solicitud de carga de nuevo archivo de diálogo, 
#guarda el archivo y ancla.
func _on_new_dialog_file_requested(new_file_path: String, anchor: String = ""):
	dialogue_manager.dialog_file = new_file_path
	dialogue_manager.pending_anchor = anchor
