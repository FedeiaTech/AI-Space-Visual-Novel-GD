# main_scene.gd
# Coordinador general. Maneja señales, input global, transiciones.
extends Node2D

# === Referencias a nodos ===
@onready var background: TextureRect = %Background
@onready var background_music: AudioStreamPlayer = %BackgroundMusic
@onready var character_sprite = $CanvasMain/Control/CharacterSprite
@onready var dialog_ui: Control = $CanvasMain/DialogUI # ¡Referencia a DialogUI!
@onready var next_sentence_sound: AudioStreamPlayer = %NextSentenceSound # Referencia a AudioStreamPlayer
@onready var journal_ui: Control = %JournalUI

# Notificaciones
@onready var item_acquired_notification: Label = %ItemAcquiredNotification
@onready var notification_timer: Timer = %NotificationTimer
@onready var time_label: Label = $CanvasNotification/TimeLabel

# Nodos Extra
@onready var command_processor: Node = %CommandProcessor
@onready var inventory_ui_manager: Node = %InventoryUIManager
@onready var dialogue_manager: Node = %DialogueManager # ¡Referencia a DialogueManager!

#UI Iconos
@onready var journal_icon_button: TextureButton = %JournalIconButton
@onready var inventory_icon_button: TextureButton = %InventoryIconButton
@onready var journal_icon_label: Label = %JournalIconLabel
@onready var inventoryl_icon_label: Label = %InventorylIconLabel
@onready var settings_icon_label: Label = %SettingsIconLabel

#Interactive
@onready var interactive_location: Control = %interactive_location

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

	# Pasar las referencias necesarias a DialogUI
	# Asegúrate de que dialog_ui sea una instancia válida y que los managers estén listos.
	if dialog_ui and is_instance_valid(dialog_ui) and dialogue_manager and next_sentence_sound:
		# Asumo que DialogUI tiene un método llamado set_dialog_dependencies
		dialog_ui.set_dialog_dependencies(dialogue_manager, next_sentence_sound)
	else:
		printerr("Error: No se pudieron obtener todas las referencias para DialogUI o DialogUI no es válido.")


	# Ocultar etiqueta tiempo
	time_label.hide()
	# Carga inicial manejada por DialogManager
	var initial_dialog_file = "intro"
	dialogue_manager.load_dialog_file(initial_dialog_file)
	
	is_transitioning = true
	SceneManager.transition_in(transition_effect)
	
	#Icons_ui_labels
	journal_icon_label.text = " "
	inventoryl_icon_label.text = " "
	settings_icon_label.text = " "

# Captura las entradas del jugador. Permite avanzar el diálogo y alternar el inventario.
func _input(event: InputEvent) -> void:
	# Si estamos en una transición, no procesar ninguna entrada.
	if is_transitioning: return
	
	# Si el inventario o diario está abierto, solo procesar su tecla de cierre
	if inventory_ui_manager.current_inventory_ui != null:
		if event.is_action_pressed("toggle_inventory"):
			inventory_ui_manager.toggle_inventory()
			get_viewport().set_input_as_handled()
		return
	
	if event.is_action_pressed("toggle_journal"):
		if journal_ui.visible:
			journal_ui.hide()
		else:
			journal_ui.show()
		get_viewport().set_input_as_handled()
		return

	# Si el diario está visible, no procesar más inputs de juego
	if journal_ui.visible: return

	# 1. Detectar SOLO las teclas "next_line" (Enter/Barra Espaciadora)
	# La lógica del clic del mouse ahora está en _gui_input de DialogUI.
	if event.is_action_pressed("next_line"): # Esto cubrirá Enter y Espacio
		# is_dialog_input_blocked debería ser manejado por el DialogUI si está activo
		if is_dialog_input_blocked: return
		
		var current_line = {}
		if dialogue_manager.dialog_index < dialogue_manager.dialog_lines.size():
			current_line = dialogue_manager.dialog_lines[dialogue_manager.dialog_index]
			
		var has_choices = current_line.has("choices")

		if not has_choices:
			# Estas llamadas irán a los métodos de DialogUI y DialogueManager
			dialog_ui.skip_text_animation() # Asumiendo que skip_text_animation es un método de DialogUI
			next_sentence_sound.play()
			dialogue_manager.advance_index()
			dialogue_manager.process_current_line()

	# 2. Manejar la tecla de inventario por separado
	if event.is_action_pressed("toggle_inventory"):
		inventory_ui_manager.toggle_inventory()
		get_viewport().set_input_as_handled()

func _on_object_clicked(action_command: Dictionary):
	print("Paso 2: La MainScene ha recibido la señal con el comando: ", action_command)
	
	if not action_command.is_empty():
		if is_instance_valid(command_processor):
			print("Paso 2.1: Referencia a CommandProcessor es válida. Llamando a execute().")
			command_processor.execute(action_command)
		else:
			printerr("Referencia nula a CommandProcessor en _on_object_clicked().")
			
# Se activa cada vez que el DialogueManager procesa una línea.
func _on_dialogue_manager_line_processed(line: Dictionary):
	# Pasamos la línea al CommandProcessor para que actúe
	command_processor.execute(line)

func _on_dialogue_manager_finished():
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
	
	var choice_text = choice_data.get("text", "Opción Desconocida")
	var journal_entry_text = "DECIDISTE " + choice_text.to_upper()
	JournalManager.add_entry("Elección", journal_entry_text)
	
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
	dialog_ui.show()
	
	dialogue_manager.process_current_line()
	is_transitioning = false

# Al recibir una solicitud de carga de nuevo archivo de diálogo,
# guarda el archivo y ancla.
func _on_new_dialog_file_requested(new_file_path: String, anchor: String = ""):
	dialogue_manager.dialog_file = new_file_path
	dialogue_manager.pending_anchor = anchor


func _on_journal_icon_button_pressed() -> void:
	journal_ui.show()


func _on_inventory_icon_button_pressed() -> void:
	inventory_ui_manager.toggle_inventory()
	get_viewport().set_input_as_handled()

"""Señales para IconsUI"""
func _on_journal_icon_button_mouse_entered() -> void:
	journal_icon_label.text = "Diario (J)"


func _on_journal_icon_button_mouse_exited() -> void:
	journal_icon_label.text = " "


func _on_inventory_icon_button_mouse_entered() -> void:
	inventoryl_icon_label.text = "Inventario (I)"


func _on_inventory_icon_button_mouse_exited() -> void:
	inventoryl_icon_label.text = " "


func _on_setting_icon_button_mouse_entered() -> void:
	settings_icon_label.text = "Opciones (Esc)"


func _on_setting_icon_button_mouse_exited() -> void:
	settings_icon_label.text = " "
