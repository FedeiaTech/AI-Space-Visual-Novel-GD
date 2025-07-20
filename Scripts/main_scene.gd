extends Node2D

@onready var background: TextureRect = %Background
@onready var background_music: AudioStreamPlayer = %BackgroundMusic
@onready var character_sprite = $CanvasMain/Control/CharacterSprite
@onready var dialog_ui: Control = $CanvasMain/DialogUI
@onready var next_sentence_sound: AudioStreamPlayer = %NextSentenceSound

@onready var item_acquired_notification: Label = %ItemAcquiredNotification
@onready var notification_timer: Timer = %NotificationTimer

const InventoryUIScene = preload("res://Scenes/UI/inventory_ui.tscn")

var transition_effect: String = "fade"
var dialog_file: String = "res://Resources/Story/intro.json"
var dialog_index : int = 0
var dialog_lines : Array = []
# Variable para almacenar la instancia del inventario abierto
var current_inventory_ui: CanvasLayer = null
#Cola de notificaciones para adquisicion de items simultaneos
var notification_queue: Array = []

func _ready() -> void:
	#Cargar dialogo
	dialog_lines = load_dialog(dialog_file)
	#Conectar señales
	dialog_ui.text_animation_done.connect(_on_text_animation_done)
	dialog_ui.choice_selected.connect(_on_choice_selected)
	SceneManager.transition_out_completed.connect(_on_transition_out_completed)
	SceneManager.transition_in_completed.connect(_on_transition_in_completed)
	#primera linea de dialogo
	dialog_index = 0
	SceneManager.transition_in()
	# Timer de notificacion de item
	notification_timer.timeout.connect(_on_notification_timer_timeout)
	GameEvents.item_acquired_notification_requested.connect(show_item_acquired_notification_requested)
	
func _input(event: InputEvent) -> void:
	var line = dialog_lines[dialog_index]
	var has_choices = line.has("choices")
	# Avanzar en el dialogo
	if event.is_action_pressed("next_line") and not has_choices:
		if dialog_ui.animate_text:
			dialog_ui.skip_text_animation()
		else:
			if dialog_index < len(dialog_lines) - 1:
				dialog_index += 1
				next_sentence_sound.play()
				process_current_line()
	#Inventario
	if event.is_action_pressed("toggle_inventory"): # Asume que tienes esta acción en Project Settings
		if current_inventory_ui == null:
			# Abrir el inventario
			open_inventory()
		else:
			close_inventory()

func process_current_line():
	if dialog_index >= dialog_lines.size() or dialog_index < 0:
		printerr("Error: dialog_index out of bounds", dialog_index)
		return
	#Extrae la linea actual
	var line = dialog_lines[dialog_index]
	
	# Procesa la adquisición de ítems si la línea actual los tiene
	if line.has("item_given"):
		var item_data = line["item_given"]
		if item_data is Array: # Si es un array de ítems
			for item_details in item_data:
				if item_details is Dictionary and not item_details.is_empty():
					InventoryManager.add_item(InventoryManager.current_player_character, item_details)
		elif item_data is Dictionary and not item_data.is_empty(): # Si es un solo ítem
			InventoryManager.add_item(InventoryManager.current_player_character, item_data)
	
	#Verifica si es el final de la escena
	if line.has("next_scene"):
		var next_scene = line["next_scene"]
		dialog_file = "res://Resources/Story/" + next_scene + ".json" if !next_scene.is_empty() else ""
		transition_effect = line.get("transition", "fade")
		SceneManager.transition_out(transition_effect)
		return
	#Verifica si se debe cambiar la musica de fondo
	if line.has("music"):
		var music_file = load("res://Assets/Sounds/BGM/" + line["music"] + ".mp3")
		if background_music.stream != music_file:
			background_music.stop()
			background_music.stream = music_file
			#Se puede definir desde donde reproducir(float)
			background_music.play(0.0)
	#Verifica si se debe cambiar la escena(location)
	if line.has("location"):
		#Cambiar la imagen de fondo de escena
		var background_file = "res://Assets/Scenes_images/" + line["location"] + ".png"
		background.texture = load(background_file)
		#avanzar a la siguente lnea sin esperar reaccion (input) de usuario
		dialog_index += 1
		process_current_line()
		return
	#Verificar si es un comando "goto"
	if line.has("goto"):
		dialog_index = get_anchor_position(line["goto"])
		process_current_line()
		return
	#Verifica si es solo una declaracion del ancla (contenido no mostrable)
	if line.has("anchor"):
		dialog_index += 1
		process_current_line()
		return
	# Actualizar el sprite del personaje según corresponda, 
	#el valor de imagen predeterminado es el comando "speaker" si show_character 
	#no está presente
	if line.has("show_character"):
		var character_name = Character.get_enum_from_string(line["show_character"])
		character_sprite.change_character(character_name, false, line.get("expression", ""))
	elif line.has("speaker"):
		var character_name = Character.get_enum_from_string(line["speaker"])
		character_sprite.change_character(character_name, true, line.get("expression", ""))
	#Verifica si hay opciones de dialogo
	if line.has("choices"):
		#mostrar opciones
		dialog_ui.display_choices(line["choices"])
	elif line.has("text"):
		#Leer linea de dialogo
		var speaker_name = Character.get_enum_from_string(line["speaker"])
		dialog_ui.change_line(speaker_name, line["text"])
	else:
		#no hay opciones o lineas de dialogo
		dialog_index += 1
		process_current_line()
		return

func get_anchor_position(anchor: String):
	#Encontrar la entrada de ancla haciendo match
	for i in range(dialog_lines.size()):
		if dialog_lines[i].has("anchor") and dialog_lines[i]["anchor"] == anchor:
			return i
	#Si no encuentra el ancla para hacer match
	printerr("Error: Could not find anchor '", anchor, "'")
	return null

func load_dialog(file_path):
	#Verifica si el dialogo existe
	if not FileAccess.file_exists(file_path):
		printerr("Error: File JSON does not exist", file_path)
		return null
	#Abrir archivo
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Error: Failed to open the file", file_path)
		return null
	#Leer contenido como texto
	var content = file.get_as_text()
	#Parse JSON
	var json_content = JSON.parse_string(content)
		#verifica que se pudo parsear
	if json_content == null:
		printerr("Error: Failed to parse JSON from file", file_path)
		return null
	#devolver dialogo
	return json_content

"""Funciones de inventario"""
func open_inventory():
	if current_inventory_ui == null:
		current_inventory_ui = InventoryUIScene.instantiate()
		# Conecta la señal `inventory_closed` del inventario
		current_inventory_ui.inventory_closed.connect(_on_inventory_closed_signal_received)
		# Añade el inventario como hijo de la Main Scene
		add_child(current_inventory_ui)
		#o
		#get_tree().root.add_child(current_inventory_ui)

		# Opcional: Pausar el juego mientras el inventario está abierto
		get_tree().paused = true 

		# Asegurarse de que la interfaz de diálogo esté oculta o inactiva
		# Esto es importante para evitar que el jugador siga avanzando el diálogo
		# mientras el inventario está abierto.
		dialog_ui.hide() 

func close_inventory():
	if current_inventory_ui:
		# Es importante desconectar la señal antes de liberar el nodo para evitar errores
		# si la señal se dispara justo mientras el nodo está siendo liberado.
		current_inventory_ui.inventory_closed.disconnect(_on_inventory_closed_signal_received)
		current_inventory_ui.queue_free() # Libera el nodo del inventario
		current_inventory_ui = null # Limpia la referencia
		get_tree().paused = false # Despausa el juego
		dialog_ui.show() # Muestra de nuevo la interfaz de diálogo

func show_item_acquired_notification_requested(item_name: String):
	var notification_message = "¡Item adquirido!\n" + item_name
	notification_queue.append(notification_message)
	
	# Si el temporizador no está corriendo, significa que no hay notificación visible,
	# así que mostramos la primera de la cola inmediatamente.
	if notification_timer.is_stopped() and notification_queue.size() == 1:
		_display_next_notification_from_queue()
	#item_acquired_notification.text = "¡Item adquirido!\n" + item_name
	#item_acquired_notification.show() # Hacer visible
	#notification_timer.start() # Iniciar el temporizador

func _display_next_notification_from_queue():
	if notification_queue.is_empty():
		item_acquired_notification.hide()
	else:
		var next_message = notification_queue.pop_front() # Obtener y eliminar el primer mensaje
		item_acquired_notification.text = next_message
		item_acquired_notification.show()
		notification_timer.start() # Iniciar/Reiniciar el temporizador

func _on_notification_timer_timeout():
	#item_acquired_notification.hide() # Ocultar la notificación
	_display_next_notification_from_queue() # Llama a la función para mostrar la siguiente

func _on_inventory_closed_signal_received():
	# Esta función se llama cuando el botón de cerrar del inventario es presionado.
	close_inventory()

"""Funciones para señales"""
func _on_text_animation_done():
	character_sprite.play_idle_animation()

# MODIFICADO: Añadido item_given_data como parámetro opcional con valor por defecto
func _on_choice_selected(anchor: String, _item_given_data = null): #Dictionary = {}): # Añade `item_given_data` como parámetro opcional
	#if item_given_data is Array: # Si es un array de ítems
	#	for item_details in item_given_data:
	#		if item_details is Dictionary and not item_details.is_empty():
	#			InventoryManager.add_item(InventoryManager.current_player_character, item_details)
	#elif item_given_data is Dictionary and not item_given_data.is_empty(): # Si es un solo ítem (el comportamiento anterior)
	#	InventoryManager.add_item(InventoryManager.current_player_character, item_given_data)
   
	dialog_index = get_anchor_position(anchor)
	process_current_line()
	next_sentence_sound.play()

func _on_transition_out_completed():
	#Cargar nuevo dialogo
	if !dialog_file.is_empty():
		dialog_lines = load_dialog(dialog_file)
		dialog_index = 0
		var first_line = dialog_lines[dialog_index]
		if first_line.has("location"):
			background.texture = load("res://Assets/Scenes_images/" + first_line["location"] + ".png")
			dialog_index += 2
		SceneManager.transition_in(transition_effect)
	else:
		print("Fin del juego")

func _on_transition_in_completed():
	#Comenzar dialogo de procesamiento
	process_current_line()
