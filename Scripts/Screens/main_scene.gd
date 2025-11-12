# main_scene.gd
# Coordinador general. Maneja señales, input global, transiciones.
extends Node2D

# -------------------------------------------------------------------
# --- Nodos y Variables ---
# -------------------------------------------------------------------

# === Referencias a nodos ===
@onready var background: TextureRect = %Background
@onready var background_music: AudioStreamPlayer = %BackgroundMusic
@onready var character_sprite_1: Control = %CharacterSprite
@onready var character_sprite_2: Control = %CharacterSprite2
@onready var character_sprite_3: Control = %CharacterSprite3
@onready var character_sprite_4: Control = %CharacterSprite4
@onready var dialog_ui: Control = %DialogUI
@onready var next_sentence_sound: AudioStreamPlayer = %NextSentenceSound
@onready var journal_ui: Control = %JournalUI
@onready var canvas_main: CanvasLayer = %CanvasMain
@onready var main_canvas_control: Control = %MainCanvasControl

# Notificaciones
@onready var item_acquired_notification: Label = %ItemAcquiredNotification
@onready var notification_timer: Timer = %NotificationTimer
@onready var explorer_mode_icon: TextureRect = %ExplorerModeIcon
@onready var time_icon: TextureRect = %TimeIcon
@onready var time_label: Label = %TimeLabel

# Nodos Extra
@onready var command_processor: Node = %CommandProcessor
@onready var inventory_ui_manager: Node = %InventoryUIManager
@onready var dialogue_manager: Node = %DialogueManager
@onready var input_manager: Node = %InputManager
@onready var character_stage_manager: Node = %CharacterStageManager
@onready var camera_shaker: Node = %CameraShaker
@onready var quest_log_ui_manager: Node = %QuestLogUIManager

# UI Iconos
@onready var journal_icon_button: TextureButton = %JournalIconButton
@onready var inventory_icon_button: TextureButton = %InventoryIconButton
@onready var journal_icon_label: Label = %JournalIconLabel
@onready var inventory_icon_label: Label = %InventorylIconLabel
@onready var settings_icon_label: Label = %SettingsIconLabel
@onready var settings_icon_button: TextureButton = %SettingsIconButton

# Escena interactiva
@onready var interactive_location: Control = %interactive_location
@onready var viewer_canvas: CanvasLayer = %ViewerCanvas
@onready var protect_control: Control = %ProtectControl
@onready var look_button: Button = %LookButton
@onready var return_button: Button = %ReturnButton

# CG
@onready var cg_viewer: TextureRect = %CGSprite

# === Precarga de escenas ===
const PauseMenuScene = preload("res://Scenes/pause_menu.tscn")

# === Variables de estado ===
var current_speaking_character: Control = null
var transition_effect: String = "fade"
var is_in_interaction_mode: bool = false
var is_dialogue_blocked: bool = false
var notification_queue: Array = []
var is_dialog_input_blocked: bool = false
var pending_anchor: String = ""
var is_initial_load_complete: bool = true
var is_transitioning: bool = false
var _current_location_node: Node = null

# -------------------------------------------------------------------
# --- Funciones Nativas de Godot ---
# -------------------------------------------------------------------

# Carga inicial, conexión de señales y arranque del juego.
func _ready() -> void:
	# Conexión de señales de gestores
	SceneManager.transition_out_completed.connect(_on_transition_out_completed)
	SceneManager.transition_in_completed.connect(_on_transition_in_completed)
	GameManager.new_dialog_file_requested.connect(_on_new_dialog_file_requested)
	GameEvents.item_acquired_notification_requested.connect(show_item_acquired_notification_requested)
	TimeManager.time_updated.connect(func(new_time): time_label.text = new_time)

	# Conexión de señales de diálogo
	dialogue_manager.line_processed.connect(_on_dialogue_manager_line_processed)
	dialogue_manager.dialogue_finished.connect(_on_dialogue_manager_finished)
	dialog_ui.text_animation_done.connect(_on_text_animation_done)
	dialog_ui.choice_selected.connect(_on_choice_selected)
	
	# Conexión de señales de UI
	notification_timer.timeout.connect(_on_notification_timer_timeout)
	cg_viewer.cg_clicked.connect(_on_cg_viewer_cg_clicked)
	cg_viewer.cg_visibility_changed.connect(_on_cg_visibility_changed)
	
	#Conexión de señales Input
	input_manager.inventory_toggled.connect(_on_inventory_toggled)
	input_manager.journal_toggled.connect(_on_journal_toggled)
	input_manager.next_line_pressed.connect(_on_next_line_pressed)
	input_manager.pause_pressed.connect(_on_pause_pressed)
	input_manager.quest_log_toggled.connect(_on_quest_log_toggled)

	# Inyección de dependencias
	dialog_ui.set_dialog_dependencies(dialogue_manager, next_sentence_sound, self)
	var character_nodes_dict = {
		"left": character_sprite_1,
		"center": character_sprite_2,
		"right": character_sprite_3,
		"far_right": character_sprite_4
	}
	character_stage_manager.set_character_nodes(character_nodes_dict)
	character_stage_manager.set_main_scene_reference(self)

	command_processor.set_main_scene_reference(self)
	command_processor.set_stage_manager(character_stage_manager)
	
	camera_shaker.set_main_scene_reference(self)
	command_processor.set_camera_shaker(camera_shaker)
	
	# Estado inicial de la UI
	explorer_mode_icon.hide()
	time_label.hide()
	time_icon.texture = SceneLibrary.get_ui_icon("time_inactive_icon")
	journal_icon_label.text = " "
	inventory_icon_label.text = " "
	settings_icon_label.text = " "
	
	# Carga inicial y transición
	var initial_dialog_file = "intro" # Carga por defecto

	if GameManager.start_in_debug_mode:
		initial_dialog_file = "debug_story" # Carga de depuración
		GameManager.start_in_debug_mode = false # Resetea la bandera

	dialogue_manager.load_dialog_file(initial_dialog_file)
	set_process(false) 
	is_transitioning = true
	look_button.hide()
	SceneManager.transition_in(transition_effect)
	
# -------------------------------------------------------------------
# --- Manejadores de Input (Conectados a InputManager) ---
# -------------------------------------------------------------------

# Se activa cuando se presiona la tecla de inventario.
func _on_inventory_toggled():
	# La lógica de prioridad se mantiene.
	# Si el diario está visible, no hacer nada.
	if journal_ui.visible: return

	# Si no, simplemente llama al toggle.
	inventory_ui_manager.toggle_inventory()

# Se activa cuando se presiona la tecla del registro de misiones.
func _on_quest_log_toggled():
	if journal_ui.visible: return
	if inventory_ui_manager.current_inventory_ui != null: return

	quest_log_ui_manager.toggle_quest_log()

# Se activa cuando se presiona la tecla del diario.
func _on_journal_toggled():
	# Si el inventario está abierto, no hacer nada.
	if inventory_ui_manager.current_inventory_ui != null:
		return

	# Si no, mostrar/ocultar el diario.
	if journal_ui.visible:
		journal_ui.hide()
	else:
		journal_ui.show()

# Se activa cuando se presiona la tecla de "siguiente línea" (Enter/Espacio).
func _on_next_line_pressed():
	if is_transitioning: return
	if journal_ui.visible: return
	if inventory_ui_manager.current_inventory_ui != null: return

	# 1. Si el CG está visible, avanza el diálogo directamente.
	if cg_viewer.is_visible():
		_on_cg_viewer_cg_clicked()
		return

	if is_dialog_input_blocked: return

	var current_line = {}
	if dialogue_manager.dialog_index < dialogue_manager.dialog_lines.size():
		current_line = dialogue_manager.dialog_lines[dialogue_manager.dialog_index]

	var has_choices = current_line.has("choices")
	
	if not has_choices:
		dialog_ui.skip_text_animation()
		next_sentence_sound.play()
		dialogue_manager.advance_index()
		dialogue_manager.process_current_line()

# Se activa cuando se presiona la tecla 'Escape'.
func _on_pause_pressed():
	# Si hay un menú abierto, no abrir el menú de pausa
	if journal_ui.visible: return
	if inventory_ui_manager.current_inventory_ui != null: return

	# Llama a la misma función que el botón de la rueda dentada
	_on_settings_icon_button_pressed()


# -------------------------------------------------------------------
# --- Métodos Públicos y de Estado ---
# -------------------------------------------------------------------

# Registra la escena de localización actual (llamado por CommandProcessor).
func register_new_location(new_location_node: Node):
	print("MainScene: Registrando nueva localización -> ", new_location_node.name)
	_current_location_node = new_location_node

# Devuelve la localización activa (llamado por CommandProcessor).
func get_current_location_node() -> Node:
	return _current_location_node

# Carga una nueva escena de diálogo sin transición visual.
func load_new_scene_content_instantly(file_path: String, anchor: String):
	dialog_ui.hide()
	dialogue_manager.load_dialog_file(file_path, anchor)
	
	if dialogue_manager.dialog_lines.is_empty():
		printerr("MainScene: No hay líneas de diálogo para mostrar en '", file_path, "'.")
		return

	# Bucle de pre-procesamiento
	while dialogue_manager.dialog_index < dialogue_manager.dialog_lines.size():
		var current_line = dialogue_manager.dialog_lines[dialogue_manager.dialog_index]
		var is_setup_line = not (current_line.has("text") or current_line.has("choices"))
		
		if is_setup_line:
			command_processor.execute(current_line, true)
			dialogue_manager.advance_index()
		else:
			break
	
	dialog_ui.show()
	dialogue_manager.process_current_line()

# Almacena el sprite del personaje que está hablando (llamado por CommandProcessor).
func set_current_speaker(speaker_node: Control):
	current_speaking_character = speaker_node

# Añade uno o más ítems al inventario (llamado por CommandProcessor o _on_choice_selected).
func _process_item_given(item_data) -> void:
	# Caso 1: El JSON provee un array de ítems
	if item_data is Array:
		for item_details in item_data:
			if item_details is Dictionary and item_details.has("id"):
				var item_id = item_details.get("id")
				var quantity = item_details.get("quantity", 1)
				InventoryManager.add_item(InventoryManager.current_player_character, item_id, quantity)

	# Caso 2: El JSON provee un solo ítem
	elif item_data is Dictionary and item_data.has("id"):
		var item_id = item_data.get("id")
		var quantity = item_data.get("quantity", 1)
		InventoryManager.add_item(InventoryManager.current_player_character, item_id, quantity)

# Activa el modo de exploración.
func enter_interaction_mode():
	print("MainScene: Entrando en modo de interacción.")
	is_in_interaction_mode = true
	is_dialog_input_blocked = true
	canvas_main.hide()
	viewer_canvas.hide()
	explorer_mode_icon.show()
	explorer_mode_icon.get_node("AnimationPlayer").play("pulse")

# Desactiva el modo de exploración.
func exit_interaction_mode():
	if not is_in_interaction_mode: return

	print("MainScene: Saliendo del modo de interacción.")
	is_in_interaction_mode = false
	is_dialog_input_blocked = false
	canvas_main.show()
	viewer_canvas.show()
	explorer_mode_icon.hide()
	explorer_mode_icon.get_node("AnimationPlayer").stop()


# -------------------------------------------------------------------
# --- Manejadores de Señales (Gestores Principales) ---
# -------------------------------------------------------------------

# Se activa cuando un objeto clicable es presionado.
func _on_object_clicked(action_command: Dictionary):
	print("Paso 2: La MainScene ha recibido la señal con el comando: ", action_command)
	if not action_command.is_empty():
		if is_instance_valid(command_processor):
			print("Paso 2.1: Referencia a CommandProcessor es válida. Llamando a execute().")
			command_processor.execute(action_command)
		else:
			printerr("Referencia nula a CommandProcessor en _on_object_clicked().")
			
# Se activa cuando DialogueManager tiene una nueva línea lista.
func _on_dialogue_manager_line_processed(line: Dictionary):
	command_processor.execute(line)

# Se activa cuando DialogueManager llega al final del archivo de diálogo.
func _on_dialogue_manager_finished():
	print("Se ha terminado un archivo de diálogo.")

# Se activa cuando GameManager solicita una carga de escena (ej. desde una acción).
func _on_new_dialog_file_requested(new_file_path: String, anchor: String = ""):
	dialogue_manager.dialog_file = new_file_path
	dialogue_manager.pending_anchor = anchor

# Se activa cuando SceneManager termina la transición de SALIDA.
func _on_transition_out_completed():
	pending_anchor = dialogue_manager.pending_anchor
	dialogue_manager.load_dialog_file(dialogue_manager.dialog_file, pending_anchor)
	dialogue_manager.pending_anchor = ""

	if dialogue_manager.dialog_lines.is_empty():
		SceneManager.transition_in(transition_effect)
		return

	# Bucle de pre-procesamiento
	while dialogue_manager.dialog_index < dialogue_manager.dialog_lines.size():
		var current_line = dialogue_manager.dialog_lines[dialogue_manager.dialog_index]
		var is_setup_line = not (current_line.has("text") or current_line.has("choices"))
		
		if is_setup_line:
			command_processor.execute(current_line, true)
			dialogue_manager.advance_index()
		else:
			break
	
	SceneManager.transition_in(transition_effect)

# Se activa cuando SceneManager termina la transición de ENTRADA.
func _on_transition_in_completed():
	dialog_ui.show()
	dialogue_manager.process_current_line()
	is_transitioning = false
	look_button.show()


# -------------------------------------------------------------------
# --- Manejadores de Señales (UI y Elementos de Escena) ---
# -------------------------------------------------------------------

# Se activa cuando la animación de texto de DialogUI termina.
func _on_text_animation_done():
	if is_instance_valid(current_speaking_character):
		current_speaking_character.play_idle_animation()

# Se activa cuando el jugador selecciona una opción de diálogo.
func _on_choice_selected(choice_data: Dictionary, _item_given_data = null):
	next_sentence_sound.play()
	
	var choice_text = choice_data.get("text", "Opción Desconocida")
	var journal_entry_text = "DECIDISTE " + choice_text.to_upper()
	JournalManager.add_entry("Elección", journal_entry_text)
	
	if choice_data.has("item_given"):
		_process_item_given(choice_data["item_given"])

	if choice_data.has("action"):
		command_processor._handle_action(choice_data, false)
	elif choice_data.has("goto"):
		command_processor._handle_goto(choice_data, false)
	else:
		printerr("Error: La elección no tiene ni 'action' ni 'goto'.", choice_data)

# Se activa cuando el jugador hace clic en un CG.
func _on_cg_viewer_cg_clicked():
	next_sentence_sound.play()
	dialogue_manager.advance_index()
	dialogue_manager.process_current_line()
	canvas_main.show()
	viewer_canvas.show()

# Se activa cuando CGViewer emite la señal de que su visibilidad cambia.
func _on_cg_visibility_changed(show_main_canvas: bool):
	if show_main_canvas:
		canvas_main.show()
		viewer_canvas.show()
	else:
		canvas_main.hide()
		viewer_canvas.hide()

# Se activa al presionar el botón "Mirar".
func _on_look_button_pressed() -> void:
	protect_control.show()
	look_button.hide()
	return_button.show()
	canvas_main.hide()
	is_dialog_input_blocked = true

# Se activa al presionar el botón "Volver".
func _on_return_button_pressed() -> void:
	protect_control.show()
	look_button.show()
	return_button.hide()
	canvas_main.show()
	is_dialog_input_blocked = false

# Se activa al presionar el botón del menú de pausa (rueda dentada).
func _on_settings_icon_button_pressed() -> void:
	var menu = PauseMenuScene.instantiate()
	menu.main_menu_requested.connect(_on_main_menu_requested)
	add_child(menu)
	get_tree().paused = true

# Se activa cuando el menú de pausa solicita volver al menú principal.
func _on_main_menu_requested():
	get_tree().change_scene_to_file("res://Scenes/title_screen.tscn")

# Se activa al presionar el botón del diario.
func _on_journal_icon_button_pressed() -> void:
	journal_ui.show()

# Se activa al presionar el botón del inventario.
func _on_inventory_icon_button_pressed() -> void:
	inventory_ui_manager.toggle_inventory()
	get_viewport().set_input_as_handled()


# -------------------------------------------------------------------
# --- Manejadores de Señales (Iconos de UI - Mouse Over) ---
# -------------------------------------------------------------------

func _on_journal_icon_button_mouse_entered() -> void:
	journal_icon_label.text = "Diario (J)"

func _on_journal_icon_button_mouse_exited() -> void:
	journal_icon_label.text = " "

func _on_inventory_icon_button_mouse_entered() -> void:
	inventory_icon_label.text = "Inventario (I)"

func _on_inventory_icon_button_mouse_exited() -> void:
	inventory_icon_label.text = " "

func _on_setting_icon_button_mouse_entered() -> void:
	settings_icon_label.text = "Opciones (Esc)"

func _on_setting_icon_button_mouse_exited() -> void:
	settings_icon_label.text = " "


# -------------------------------------------------------------------
# --- Lógica de Notificaciones ---
# -------------------------------------------------------------------

# Se activa cuando GameEvents solicita mostrar una notificación de ítem.
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

# Muestra la siguiente notificación en la cola.
func _display_next_notification_from_queue():
	if notification_queue.is_empty():
		item_acquired_notification.hide()
	else:
		var next_message = notification_queue.pop_front()
		item_acquired_notification.text = next_message
		item_acquired_notification.show()
		notification_timer.start()

# Se activa cuando el temporizador de notificación termina.
func _on_notification_timer_timeout():
	_display_next_notification_from_queue()
