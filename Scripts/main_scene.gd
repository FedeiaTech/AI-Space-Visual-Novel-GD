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
var dialog_file: String
var dialog_index : int = 0
var dialog_lines : Array = []
# Variable para almacenar la instancia del inventario abierto
var current_inventory_ui: CanvasLayer = null
#Cola de notificaciones para adquisicion de items simultaneos
var notification_queue: Array = []
#booleano para bloquear ciertos inputs durante la pausa
var is_dialog_input_blocked: bool = false
# Para almacenar el ancla de destino después de una carga de escena
var pending_anchor: String = ""
# Variable para controlar si es la primera carga (al inicio del juego)
var is_initial_load_complete: bool = true


func _ready() -> void:
	#Conectar señales
	dialog_ui.text_animation_done.connect(_on_text_animation_done)
	dialog_ui.choice_selected.connect(_on_choice_selected)
	#Conectar señales de SceneManager
	SceneManager.transition_out_completed.connect(_on_transition_out_completed)
	SceneManager.transition_in_completed.connect(_on_transition_in_completed)
	#Conectar señales de SceneManager
	GameManager.new_dialog_file_requested.connect(_on_new_dialog_file_requested)
	
	#primera linea de dialogo
	#dialog_index = 0
	#SceneManager.transition_in() #Transicion de entrada
	
	# Timer de notificacion de item
	notification_timer.timeout.connect(_on_notification_timer_timeout)
	GameEvents.item_acquired_notification_requested.connect(show_item_acquired_notification_requested)
	
	# === Lógica de carga inicial ===
	dialog_file = "res://Resources/Story/intro.json"
	dialog_lines = load_dialog(dialog_file)
	if dialog_lines == null or dialog_lines.is_empty():
		printerr("Error crítico: El archivo de diálogo inicial está vacío o es inválido: ", dialog_file)
		return

	dialog_index = 0
	
	if dialog_lines.size() > 0:
		var initial_line = dialog_lines[dialog_index]
		if initial_line.has("location"):
			var background_file = "res://Assets/Scenes_images/" + initial_line["location"] + ".png"
			background.texture = load(background_file)
		if initial_line.has("music"):
			var music_file = load("res://Assets/Sounds/BGM/" + initial_line["music"] + ".mp3")
			if background_music.stream != music_file:
				background_music.stop()
				background_music.stream = music_file
				background_music.play(0.0)
		
		# Si la primera línea es solo de ambientación (location/music/anchor),
		# avanzamos el índice para que la primera línea de diálogo real
		# sea la que se procese después de la transición de entrada.
		# Esto es crucial para que el texto no aparezca antes de la transición.
		if not (initial_line.has("text") or initial_line.has("choices") or initial_line.has("speaker")):
			# Avanzar el índice solo si la línea no tiene contenido de diálogo
			# y es una línea de ambientación o ancla.
			# Esto evita que el usuario tenga que "clicar" para pasar una línea vacía.
			dialog_index += 1

	# Iniciar la transición de entrada (aparecer la escena)
	SceneManager.transition_in(transition_effect)

func _input(event: InputEvent) -> void:
	# Bloquear input de diálogo si la bandera está activa
	if is_dialog_input_blocked:
		# Si la bandera está activa y el evento es de ratón/tecla, lo consumimos.
		# Es importante consumirlos para que no se "guarden" para después.
		if event.is_action_pressed("next_line"): # Si el evento es una acción para avanzar el diálogo
			return #Simplemente sale de la función, ignorando el avance del diálogo.

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
			else:
				# Si llegamos al final del diálogo y no hay 'next_scene' o 'action',
				# podría ser el fin de este archivo de diálogo o del juego.
				print("Fin del archivo de diálogo actual. No hay más líneas.")
	
	#Inventario
	if event.is_action_pressed("toggle_inventory"): # Asume que tienes esta acción en Project Settings
		if current_inventory_ui == null:
			# Abrir el inventario
			open_inventory()
		else:
			close_inventory()
		# Consumir el evento para que no se propague más allá
		get_viewport().set_input_as_handled()

func process_current_line():
	if dialog_lines.is_empty():
		printerr("Error: dialog_lines está vacío. No se pueden procesar líneas.")
		# Podrías añadir lógica aquí para un "Game Over" o reiniciar.
		return
		
	if dialog_index >= dialog_lines.size() or dialog_index < 0:
		printerr("Error: dialog_index out of bounds", dialog_index)
		return
	
	#Extrae la linea actual
	var line = dialog_lines[dialog_index]
	
	#Verifica si es el final de la escena o transiciones más "forzadas"
	if line.has("next_scene"):
		var next_scene = line["next_scene"]
		if !next_scene.is_empty():
			# Guardar el estado actual para un posible "volver"
			GameManager.previous_dialog_file = dialog_file
			GameManager.previous_dialog_index = dialog_index
		
			# Iniciar transición y luego cargar la nueva escena a través de GameManager
			transition_effect = line.get("transition", "fade")
			SceneManager.transition_out(transition_effect)
			# Sin ancla específica para 'next_scene'
			GameManager.request_scene_load(next_scene, "")
			return
		else:
		# Si next_scene está vacío, podrías hacer algo más aquí,
		# como emitir una señal de "fin de diálogo de este archivo"
			print("Fin del diálogo.")
		# ¡Importante!: Asegúrate de que el flujo del juego no intente procesar más líneas
		# o que vuelva al inicio de alguna manera no deseada.
			return
	
	# Manejar acciones complejas (incluyendo transiciones de escena) 
	# y navegaciones no lineales
	# Si prefieres que TODAS las transiciones de escena usen "action", puedes quitar el if line.has("next_scene"):
	# y convertir esos casos en un "action":{"type": "load_scene", ...}
	if line.has("action"):
		var action_data = line["action"]
		var action_type = action_data.get("type", "")
		
		match action_type:
			"load_scene":
				# Guardar el estado actual antes de la transición para un posible "volver"
				GameManager.previous_dialog_file = dialog_file
				GameManager.previous_dialog_index = dialog_index

				var target_scene_file = action_data.get("scene_file", "")
				var target_anchor = action_data.get("anchor", "")
				# Obtener efecto de transición del JSON
				transition_effect = action_data.get("transition", "fade") # Obtener efecto de transición del JSON

				if target_scene_file.is_empty():
					printerr("Error: 'load_scene' action missing 'scene_file'.")
					return

				#OcultarDialogUI y character_sprite
				dialog_ui.hide()
				character_sprite.hide()
				# Iniciar la transición de salida
				SceneManager.transition_out(transition_effect)
			   # GameManager pedirá la carga del nuevo archivo JSON, y MainScene lo escuchará
				GameManager.request_scene_load(target_scene_file, target_anchor)
				return # Importante: salir para no procesar como línea de diálogo normal
			# Puedes añadir otros tipos de acciones aquí, como "open_map", "trigger_event", etc.
			"goto_internal": # Si quieres un tipo de acción explícito para goto dentro del mismo JSON
				dialog_index = get_anchor_position(action_data.get("anchor", ""))
				if dialog_index != null:
					process_current_line()
				return
			_:
				printerr("Acción no reconocida: ", action_type)
				pass # O manejar error
		return # Salir después de procesar la acción

	# Procesa la adquisición de ítems si la línea actual los tiene
	if line.has("item_given"):
		var item_data = line["item_given"]
		if item_data is Array: # Si es un array de ítems
			for item_details in item_data:
				if item_details is Dictionary and not item_details.is_empty():
					InventoryManager.add_item(InventoryManager.current_player_character, item_details)
		elif item_data is Dictionary and not item_data.is_empty(): # Si es un solo ítem
			InventoryManager.add_item(InventoryManager.current_player_character, item_data)
	
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
		if not (line.has("text") or line.has("choices") or line.has("action") or line.has("speaker")):
			dialog_index += 1
			process_current_line()
		return
	
	#Verificar si es un comando "goto"
	if line.has("goto"):
		dialog_index = get_anchor_position(line["goto"])
		if dialog_index != null:
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
		var speaker_name = Character.Name.NARRATOR # Asume NARRATOR por defecto
		if line.has("speaker"):
			speaker_name = Character.get_enum_from_string(line["speaker"])
		dialog_ui.change_line(speaker_name, line["text"])
	else:
		#no hay opciones o lineas de dialogo
		dialog_index += 1
		process_current_line()
		return

"""TODO: Verificar si esta funcion y la que sigue sirven"""
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
		is_dialog_input_blocked = true # Bloquea el input del diálogo
		# Asegúrate de que cualquier input que haya ocurrido Justo antes de pausar no se "libere" al despausar
		get_viewport().set_input_as_handled() # Consumir cualquier input pendiente o reciente
		
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
		is_dialog_input_blocked = false # Desbloquea el input del diálogo
		# Consumir cualquier input que haya ocurrido mientras el inventario estaba abierto
		get_viewport().set_input_as_handled() # Esto es crucial al despausar
		dialog_ui.show() # Muestra de nuevo la interfaz de diálogo

func show_item_acquired_notification_requested(item_name: String, quantity_change: int, is_new_item: bool):
	var notification_message: String = ""
	if is_new_item:
		notification_message = "¡Item adquirido!\n" + item_name
	else:
		notification_message = "Cantidad de " + item_name + " aumentada.\n"
		if quantity_change > 0:
			notification_message += "(+" + str(quantity_change) + ")"
		# Puedes añadir un "total actual" si lo deseas, pero eso requeriría pasar la cantidad total actual
		# o buscarla en InventoryManager aquí, lo cual podría ser costoso para cada notificación.
		# Por simplicidad, solo mostramos el cambio.
	notification_queue.append(notification_message)
	
	if notification_timer.is_stopped() and notification_queue.size() == 1:
		_display_next_notification_from_queue()


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
	# Solo reproduce la animación de idle si el último personaje NO es el narrador.
	# Asume que dialog_ui.current_character_details ya está actualizado con el personaje que acaba de hablar.
	
	# Verifica si hay detalles de personaje y si el nombre del personaje no está vacío (indicando que no es el narrador)
	# y si tiene un sprite_frames asignado para poder animarlo.
	if dialog_ui.current_character_details.has("name") and \
	   dialog_ui.current_character_details["name"] != "" and \
	   dialog_ui.current_character_details.has("sprite_frames") and \
	   dialog_ui.current_character_details["sprite_frames"] != null:
		character_sprite.play_idle_animation()

func _on_choice_selected(choice_data: Dictionary, _item_given_data = null):
	next_sentence_sound.play()

	# Procesa la adquisición de ítems si la elección misma tiene 'item_given'
	if choice_data.has("item_given"):
		var item_data = choice_data["item_given"]
		if item_data is Array:
			for item_details in item_data:
				if item_details is Dictionary and not item_details.is_empty():
					InventoryManager.add_item(InventoryManager.current_player_character, item_details)
		elif item_data is Dictionary and not item_data.is_empty():
			InventoryManager.add_item(InventoryManager.current_player_character, item_data)

	# Decide si es una acción (carga de escena) o un salto interno (goto)
	if choice_data.has("action"):
		var action_data = choice_data["action"]
		var action_type = action_data.get("type", "")

		# Asegúrate que esta sección del match sea la que tienes.
		match action_type:
			"load_scene": # <-- ¡Aquí debe estar "load_scene" para que coincida con tu JSON!
				# Guardar el estado actual para un posible "volver"
				GameManager.previous_dialog_file = dialog_file
				GameManager.previous_dialog_index = dialog_index

				var target_scene_file_name = action_data.get("scene_file", "")
				var target_anchor = action_data.get("anchor", "")
				transition_effect = action_data.get("transition", "fade")

				#Ocultar DialogUI y character_sprite
				dialog_ui.hide()
				character_sprite.hide()

				if target_scene_file_name.is_empty():
					printerr("Error: 'load_scene' action missing 'scene_file'.")
					return

				SceneManager.transition_out(transition_effect)
				GameManager.request_scene_load(target_scene_file_name, target_anchor)

			"goto_internal":
				dialog_index = get_anchor_position(action_data.get("anchor", ""))
				if dialog_index != null:
					process_current_line()
			_:
				# Si estás viendo este error, es porque el valor de action_type no está coincidiendo
				# con ninguna de las ramas de arriba, a pesar de que "load_scene" debería estar.
				printerr("Acción no reconocida en la elección: ", action_type)
	elif choice_data.has("goto"):
		dialog_index = get_anchor_position(choice_data["goto"])
		if dialog_index != null:
			process_current_line()
	else:
		printerr("Error: La elección no tiene ni 'action' ni 'goto'.", choice_data)

# Manejar la solicitud de GameManager para cargar un nuevo archivo de diálogo**
func _on_new_dialog_file_requested(new_file_path: String, anchor: String = ""):
	dialog_file = new_file_path # Actualiza la ruta del archivo de diálogo principal
	pending_anchor = anchor # Guarda el ancla para usarla después de la transición
	# La transición de salida ya se inició desde process_current_line (action: load_dialog_scene)
	# o desde el antiguo 'next_scene'
	# No hacemos transition_out() aquí para evitar doble inicio.

func _on_transition_out_completed():
	## Este método se llama cuando la pantalla ya está completamente negra/cubierta.
	if !dialog_file.is_empty():
		# Carga el nuevo archivo JSON
		dialog_lines = load_dialog(dialog_file)
		if dialog_lines == null or dialog_lines.is_empty(): # Verificamos si es null o vacío
			printerr("Error crítico: El archivo de diálogo cargado está vacío o es inválido: ", dialog_file)
			SceneManager.transition_in(transition_effect)
			return # ¡Importante! Salir si el JSON está vacío para evitar el error 'Out of bounds'

		dialog_index = 0
		
		# Si hay un ancla pendiente, salta a ella
		if !pending_anchor.is_empty():
			var temp_index = get_anchor_position(pending_anchor)
			if temp_index != null: # Si el ancla se encontró
				dialog_index = temp_index
			else: # Si el ancla no se encuentra en el nuevo archivo
				printerr("Error: Ancla '", pending_anchor, "' no encontrada en el nuevo archivo de diálogo: ", dialog_file)
				dialog_index = 0 # Volver al principio si no se encuentra
			pending_anchor = "" # Limpiar el ancla después de usarla
		
		var initial_setup_done = false
		while not initial_setup_done and dialog_index < dialog_lines.size():
			var current_line = dialog_lines[dialog_index]
			
			var is_setup_line = false

			if current_line.has("location"):
				var background_file = "res://Assets/Scenes_images/" + current_line["location"] + ".png"
				background.texture = load(background_file)
				is_setup_line = true
				#if not (current_line_after_load.has("text") or current_line_after_load.has("choices") or current_line_after_load.has("action") or current_line_after_load.has("speaker")):
				#	dialog_index += 1

			# Manejar la música aquí también, si no se hace en process_current_line inicialmente (NUEVO)
			if current_line.has("music"):
				var music_file = load("res://Assets/Sounds/BGM/" + current_line["music"] + ".mp3")
				if background_music.stream != music_file:
					background_music.stop()
					background_music.stream = music_file
					background_music.play(0.0)
			is_setup_line = true
			
			if current_line.has("anchor"):
				# Esta línea es solo una marca, así que la consideramos de configuración.
				is_setup_line = true
			
			if is_setup_line and not (current_line.has("text") or current_line.has("choices") or current_line.has("action")):
				dialog_index += 1
			else:
				# Si encontramos una línea con contenido visible, detenemos el bucle.
				initial_setup_done = true
		SceneManager.transition_in(transition_effect)
	else:
		print("Fin del juego")
		SceneManager.transition_in(transition_effect)

func _on_transition_in_completed():
	# Una vez que la pantalla está visible de nuevo, comienza a procesar la línea actual
	# Si es la primera carga, no queremos procesar la línea de nuevo si ya se hizo en _ready (que ya no lo hace).
	#if is_initial_load_complete:
	#	is_initial_load_complete = false # Marcar que la carga inicial ya se completó
		# Esto asegura que dialog_file tenga un valor para la primera carga en _on_transition_out_completed.
	process_current_line() # Procesa la primera línea después de la carga inicial
	dialog_ui.show()
	character_sprite.show()
	#else:
		# Para cargas de escenas subsiguientes, process_current_line ya se llamó
		# o se llamará después de que el jugador avance el diálogo.
	#	pass
