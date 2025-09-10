# command_processor.gd
# Este nodo se encarga de ejecutar comandos embebidos en líneas de diálogo.
# Interpreta líneas específicas del JSON de diálogos para alterar el estado del juego.
extends Node

# Referencia a la escena principal que este procesador controlará
var main_scene: Node2D

# Diccionario de Manejadores de Comandos
var command_handlers: Dictionary = {
	# Comandos que deben ajustarse para leerse primeros
	"action": _handle_action,
	"set_flag": _handle_set_flag,
	"item_given": _handle_item_given,
	"music": _handle_music,
	"location": _handle_location,
	"anchor": _handle_anchor,
	"object": _handle_object,
	# Comandos de visualización y flujo
	"set_time_absolute": _handle_set_time_absolute,
	"modify_time": _handle_modify_time,
	"show_time_ui": _handle_show_time_ui,
	"show_character": _handle_show_character,
	"choices": _handle_choices,
	"text": _handle_text,
	"goto": _handle_goto,
	"flow": _handle_flow,
	"show_cg": _handle_show_cg,
	"hide_cg": _handle_hide_cg,
}

func _ready() -> void:
	# Al iniciar, obtiene una referencia al nodo padre (MainScene)
	main_scene = get_parent()

func execute(line: Dictionary, is_preprocessing: bool = false) -> String:
	# Ejecuta una línea de diálogo con comandos.
	# Busca cuál de los comandos está presente y llama al manejador correspondiente.
	# Si un comando devuelve "stop_processing", se detiene la ejecución del resto.
	for command_name in command_handlers.keys():
		if line.has(command_name):
			print("Paso 3: CommandProcessor.execute() ha recibido la línea: ", line)
	
			var result = command_handlers[command_name].call(line, is_preprocessing)
			if result == "stop_processing":
				return "stop_processing"
	return ""


# ----------------------------------------------
""" Manejadores de comandos individuales """
# ----------------------------------------------
# helper (top-level): búsqueda recursiva por object_id en todo el subtree
func _recursive_find_by_object_id(node: Node, id: String) -> Node:
	for child in node.get_children():
		if child == null:
			continue
		# 1) meta (si lo usás)
		if child.has_meta("object_id") and str(child.get_meta("object_id")) == id:
			return child

		# 2) intento de leer la propiedad exportada 'object_id' (get() devuelve null si no existe)
		var got = child.get("object_id")
		if got != null and str(got) == id:
			return child

		# 3) descender recursivamente
		var found = _recursive_find_by_object_id(child, id)
		if found != null:
			return found

	return null


func _handle_object(line: Dictionary, is_preprocessing: bool = false) -> String:
	var object_data = line.get("object", {})
	var target_id = str(object_data.get("id", ""))

	if target_id == "":
		printerr("CommandProcessor Error: El comando 'object' no tiene 'id'.")
		return ""

	var location_container = main_scene.get_node("InteractiveLocation")
	if location_container == null or location_container.get_child_count() == 0:
		printerr("CommandProcessor Error: No hay una escena de ubicación cargada en 'InteractiveLocation'.")
		return ""

	# 1) Intento: preguntar a cualquier InteractionManager disponible en children de location_container
	var target_object: Node = null
	for i in range(location_container.get_child_count()):
		var candidate = location_container.get_child(i)
		if candidate != null and candidate.has_method("get_object_by_id"):
			var found = candidate.get_object_by_id(target_id)
			if found != null:
				target_object = found
				print("CommandProcessor: objeto '", target_id, "' encontrado en InteractionManager: ", candidate.name)
				break

	# 2) Fallback: búsqueda recursiva en el subtree por propiedad 'object_id' o meta
	if target_object == null:
		target_object = _recursive_find_by_object_id(location_container, target_id)
		if target_object != null:
			print("CommandProcessor (fallback): objeto '", target_id, "' encontrado recursivamente en: ", target_object.get_path())

	# 3) Si lo encontramos, aplicamos cambios
	if target_object != null:
		if object_data.has("visible"):
			target_object.visible = bool(object_data.get("visible"))
	else:
		printerr("CommandProcessor Error: No se encontró el objeto con ID '", target_id, "' en InteractiveLocation.")
		# debug extra: listar posibles IDs registrados por cualquier InteractionManager
		for i in range(location_container.get_child_count()):
			var c = location_container.get_child(i)
			if c != null and c.has_method("get_object_by_id"):
				var keys = c.get("clickable_objects") if c.get("clickable_objects") != null else "(no expone clickable_objects)"
				print(" - InteractionManager candidate:", c.name, " -> keys:", keys)

	# comportamiento original: si era línea de setup, avanzar el índice y procesar la siguiente
	if not is_preprocessing and not (line.has("text") or line.has("choices")):
		main_scene.dialogue_manager.advance_index()
		main_scene.dialogue_manager.process_current_line.call_deferred()

	# detenemos procesamiento adicional de esta línea
	return "stop_processing"



	
func _handle_action(line: Dictionary, _is_preprocessing: bool = false) -> String:
	# Maneja acciones especiales como cambiar de escena o ir a un ancla interna.
	var action_data = line["action"]
	var action_type = action_data.get("type", "")

	match action_type:
		"load_scene":
			# Si estamos en modo de interacción, primero salimos
			#de él para restaurar la UI.
			main_scene.exit_interaction_mode()
			
			# ... (guardado de estado previo) ...
			var target_file = action_data.get("scene_file", "")
			var target_anchor = action_data.get("anchor", "")
			
			# Por defecto, asumimos que hay transición para mantener 
			#la compatibilidad con los diálogos
			var perform_transition = line.get("has_transition", true)
			# El tipo de transición puede venir del clickable_object
			# o del JSON del diálogo
			var effect_type = line.get("transition_type", action_data.get("transition", "fade"))
			
			# Si la transición está desactivada o no se especificó un tipo, se carga instantáneamente
			if perform_transition and not effect_type.is_empty():
				# Lógica de transición (la que ya tenías)
				main_scene.transition_effect = effect_type
				
				main_scene.dialog_ui.hide()
				main_scene.character_sprite.hide_instantly()
				main_scene.is_transitioning = true
				main_scene.look_button.hide()
				
				SceneManager.transition_out(main_scene.transition_effect)
				
				GameManager.request_scene_load(target_file, target_anchor)
			else:
				# Lógica de carga instantánea (sin transición visual)
				# Llamamos a una nueva función en main_scene para que haga el trabajo
				main_scene.load_new_scene_content_instantly(target_file, target_anchor)
			
			return "stop_processing"
		
		"goto_internal":
			# Redirige internamente a un ancla del mismo archivo
			return _handle_goto({"goto": action_data.get("anchor", "")}, true)
		
		_:
			printerr("Acción no reconocida: ", action_type)
	return ""

func _handle_item_given(line: Dictionary,_is_preprocessing: bool = false) -> String:
	# Maneja el evento de entrega de ítems al jugador
	main_scene._process_item_given(line["item_given"])
	return "" # Continuar procesando otros comandos en la misma línea

func _handle_music(line: Dictionary,_is_preprocessing: bool = false) -> String:
	# Cambia la música de fondo según el nombre especificado
	var music_file = load("res://Assets/Sounds/BGM/" + line["music"] + ".mp3")
	if main_scene.background_music.stream != music_file:
		main_scene.background_music.stop()
		main_scene.background_music.stream = music_file
		main_scene.background_music.play(0.0)
	return ""

func _handle_location(line: Dictionary, is_preprocessing: bool) -> String:
	# Cambia el fondo de la escena a una nueva ubicación
	# 1. Obtener la referencia al nodo donde se instanciarán las ubicaciones
	var location_container = main_scene.get_node("InteractiveLocation")
	
	# 2. Limpiamos el contenedor para evitar tener múltiples escenas cargadas
	# Lo hacemos en orden inverso para evitar problemas de índices.
	for i in range(location_container.get_child_count() - 1, -1, -1):
		var child = location_container.get_child(i)
		child.queue_free()

	# 3. Cargar la escena de ubicación desde nuestra librería global (Autoload).
	# La clave "location" en tu JSON debe ser uno de los nombres definidos en SceneLibrary.
	var location_name = line["location"]
	var location_scene = SceneLibrary.get_scene(location_name)
	
	# Verificar si la escena existe en nuestra librería antes de continuar.
	if location_scene == null:
		printerr("Error: La escena '", location_name, "' no está definida o precargada en SceneLibrary.gd.")
		return "" # Detenemos la ejecución para evitar un crash.

	# 4. Instanciar la escena y añadirla al contenedor
	var location_instance = location_scene.instantiate()
	location_container.add_child(location_instance)
	# Debug: listar hijos del location_container (inmediatamente después de add_child)
	print("-- DEBUG: hijos de InteractiveLocation --")
	for i in range(location_container.get_child_count()):
		var c = location_container.get_child(i)
		print("child[", i, "]: name=", c.name, " type=", c.get_class(), " has_get_object_by_id=", c.has_method("get_object_by_id"))
		# listar sub-hijos 1 nivel
		for j in range(c.get_child_count()):
			var sc = c.get_child(j)
			print("  subchild[", j, "]: name=", sc.name, " type=", sc.get_class(), " has_signal_object_clicked=", sc.has_signal("object_clicked"))
	print("-- fin DEBUG --")
	var new_interaction_manager = location_instance.get_node_or_null("InteractionManager") # Asegúrate de que el nodo se llame "InteractionManager"

	if new_interaction_manager and new_interaction_manager.has_method("_register_clickable_objects"):
	# Llamar a la función de registro para la nueva escena
		new_interaction_manager._register_clickable_objects(new_interaction_manager)
	
	# Referencia al CanvasLayer que contiene los objetos clickeables
	# Es importante que todas tus escenas de ubicación tengan esta misma estructura.
	var interactables_layer = location_instance.get_node("CanvasLayer")
	
	# Asegurarse de que el CanvasLayer existe antes de buscar hijos
	if interactables_layer:
		# Ahora busca hijos dentro del CanvasLayer
		for child in interactables_layer.get_children():
			if child.has_signal("object_clicked"):
				if not child.object_clicked.is_connected(main_scene._on_object_clicked):
					child.object_clicked.connect(main_scene._on_object_clicked)
	else:
		printerr("Error: La escena de ubicación '", location_name, "' no tiene un nodo hijo llamado 'CanvasLayer'.")
	
	# Si estamos en juego normal y esta es una línea de solo configuración, avanzamos.
	if not is_preprocessing and not (line.has("text") or line.has("choices") or line.has("action")):
		main_scene.dialogue_manager.advance_index()
		main_scene.dialogue_manager.process_current_line.call_deferred()
		return "stop_processing"
		
	# En cualquier otro caso (pre-procesamiento o si hay más comandos), continuamos.
	return ""

func _handle_goto(line: Dictionary, _is_preprocessing: bool) -> String:
	# Salta a una posición específica dentro del archivo de diálogo
	main_scene.dialogue_manager.jump_to_anchor.call_deferred(line["goto"])
	return "stop_processing"

func _handle_anchor(_line: Dictionary, is_preprocessing: bool) -> String:
	# Si NO estamos pre-procesando, avanzamos automáticamente para evitar el "clic extra".
	if not is_preprocessing:
		main_scene.dialogue_manager.advance_index()
		main_scene.dialogue_manager.process_current_line.call_deferred()
		return "stop_processing"
	
	# Si estamos pre-procesando, no hacemos nada y dejamos que el bucle de MainScene avance.
	return "" # Devolvemos "" para que se puedan ejecutar otros comandos en la misma línea si los hubiera


func _handle_show_character(line: Dictionary,_is_preprocessing: bool = false) -> String:
	# Muestra al personaje correspondiente en pantalla
	var character_name_str = line.get("show_character", line.get("speaker", "NARRATOR"))
	var character_name = Character.get_enum_from_string(character_name_str)
	
	# Verifica si este personaje es también quien habla
	var is_speaking = line.has("speaker") and line["speaker"] == character_name_str
	# Actualiza la apariencia del personaje
	main_scene.character_sprite.change_character(
		character_name, 
		is_speaking, 
		line.get("expression", "")
		)
	# Muestra el sprite con el fundido
	main_scene.character_sprite.show_sprite()
	return ""

func _handle_choices(line: Dictionary,_is_preprocessing: bool = false) -> String:
	# 1. Obtener todas las opciones disponibles de la línea.
	var all_choices = line["choices"]
	var playable_choices: Array = [] # Aquí almacenaremos las opciones que el jugador verá.

	# 2. Iterar sobre todas las opciones para filtrar por `requires_item`.
	for choice in all_choices:
		var is_item_condition_met = true
		var is_flag_condition_met = true
		
		# Verificacion de items
		var required_item_id = choice.get("requires_item", "")
		if not required_item_id.is_empty():
			is_item_condition_met = InventoryManager.has_item(InventoryManager.current_player_character, required_item_id)
		
		# Verificación de Banderas de Misión
		var required_flag_id = choice.get("requires_flag", "")
		if not required_flag_id.is_empty():
			var expected_flag_value = choice.get("flag_value", true) # Por defecto, la bandera debe ser 'true'
			is_flag_condition_met = GameManager.get_quest_flag(required_flag_id) == expected_flag_value
			
			if not is_flag_condition_met:
				print("Opción '", choice.get("text", "Sin texto"), "' omitida: requiere bandera '", required_flag_id, "' sea ", expected_flag_value)

		# Si ambas condiciones (ítem y bandera) se cumplen, la opción es jugable.
		if is_item_condition_met and is_flag_condition_met:
			playable_choices.append(choice)
		# Si ambas condiciones (ítem y bandera) se cumplen, la opción es jugable.
		elif not is_item_condition_met:
			print("Opción '", choice.get("text", "Sin texto"), "' omitida: requiere ítem '", required_item_id, "' que no está en el inventario.")
			# Opcional: Si la opción requiere un ítem que el jugador NO tiene,
			# puedes añadir una opción alternativa o modificar la existente.
			# Por ejemplo, una opción que diga "Necesitas la Llave Antigua (no tienes)".
			# O simplemente, no añadirla a `playable_choices`.
			# Por ahora, simplemente no la añadimos.
	# 3. Si no hay opciones jugables
	if playable_choices.is_empty():
		# Opción A: Mostrar un mensaje y continuar si no hay texto despues.
		main_scene.dialog_ui.change_line(Character.Name.NARRATOR, "No puedo hacer eso en este momento.")
		# También puedes avanzar la línea o redirigir a un ancla de fallback
		main_scene.dialogue_manager.advance_index()
		main_scene.dialogue_manager.process_current_line.call_deferred()
		return "stop_processing"
	
		# Opción B: Redirigir a un ancla de fallback si está definida en el JSON
		# var fallback_anchor = line.get("fallback_if_no_choices", "")
		# if not fallback_anchor.is_empty():
		#     main_scene.dialogue_manager.jump_to_anchor.call_deferred(fallback_anchor)
		#     return "stop_processing"
		# else:
		#     # Si no hay fallback, aún necesitas manejar la situación.
		#     main_scene.dialog_ui.change_line(Character.Name.NARRATOR, "No hay opciones disponibles.")
		#     return "stop_processing"
	
	# 4. Pasar solo las opciones jugables a la UI.
	main_scene.dialog_ui.display_choices(playable_choices)
	# Cuando hay choices, no hay un orador directo para mostrar.
	# Es buena práctica ocultar cualquier personaje que pudiera estar visible.
	_handle_show_character({"show_character": "NARRATOR"}) # Oculta al personaje
	
	return "stop_processing" # Las elecciones detienen el procesamiento de esta línea

func _handle_text(line: Dictionary, _is_preprocessing: bool = false) -> String:
	# --- 1. Determinar QUIÉN HABLA (para el diálogo y el diario) ---
	var speaker_enum = Character.Name.NARRATOR
	var speaker_name_for_journal = "Narrador"
	
	if line.has("speaker"):
		@warning_ignore("int_as_enum_without_cast")
		speaker_enum = Character.get_enum_from_string(line["speaker"])
		var speaker_details = Character.CHARACTER_DETAILS.get(speaker_enum)
		if speaker_details and not speaker_details.get("name", "").is_empty():
			speaker_name_for_journal = speaker_details["name"]

	# --- 2. Determinar QUIÉN APARECE EN PANTALLA ---
	var character_to_show_str = line.get("show_character", line.get("speaker", "NARRATOR"))
	var character_to_show_enum = Character.get_enum_from_string(character_to_show_str)
	var character_to_show_details = Character.CHARACTER_DETAILS.get(character_to_show_enum)
	
	# --- 3. Lógica del Sprite (basada en QUIÉN APARECE EN PANTALLA) ---
	var expression = line.get("expression", "")
	var is_talking = not line.has("show_character")
	
	var has_sprite = character_to_show_details and character_to_show_details.get("sprite_frames") != null
	
	if not has_sprite:
		main_scene.character_sprite.hide_sprite()
	else:
		main_scene.character_sprite.change_character(character_to_show_enum, is_talking, expression)
		main_scene.character_sprite.show_sprite()
	
	# --- 4. Mostrar el texto en la UI (con los datos de QUIÉN HABLA) ---
	main_scene.dialog_ui.change_line(speaker_enum, line["text"], expression)
	
	# --- 5. Registrar la entrada en el diario ---
	if not _is_preprocessing:
		var dialog_text: String = ""
		# Convertir el valor de 'text' a una cadena de texto limpia y segura
		if line.has("text") and typeof(line["text"]) == TYPE_STRING:
			dialog_text = str(line["text"])
		else:
			printerr("Error: La línea de diálogo no contiene texto o el formato es incorrecto.")
			return "" # Salir de la función si no hay texto válido

		JournalManager.add_entry(speaker_name_for_journal, dialog_text)
		
	return ""

func _handle_flow(line: Dictionary, _is_preprocessing: bool = false) -> String:
	var mode = line.get("flow", "")
	
	if mode == "explore":
		# Llamamos a la función que hemos creado en main_scene
		main_scene.enter_interaction_mode()
		# Detenemos el procesamiento para que el diálogo se pause aquí
		return "stop_processing"
		
	return ""

func _handle_set_flag(line: Dictionary,_is_preprocessing: bool = false) -> String:
	var flag_data = line["set_flag"]
	if typeof(flag_data) == TYPE_DICTIONARY:
		var flag_id = flag_data.get("id", "")
		var value = flag_data.get("value", true) # Por defecto, si no se especifica, se activa (true)

		if not flag_id.is_empty():
			GameManager.set_quest_flag(flag_id, value)
		else:
			printerr("Error: 'set_flag' sin 'id' de bandera.")
	else:
		printerr("Error: Formato incorrecto para el comando 'set_flag'. Esperado {id: 'flag_id', value: true/false}.")
	return "" # Continúa el procesamiento de otros comandos en la misma línea

func _handle_set_time_absolute(line: Dictionary,_is_preprocessing: bool = false) -> String:
	var time_str = line["set_time_absolute"]
	var parts = time_str.split(":")
	if parts.size() == 2:
		var hours = int(parts[0])
		var minutes = int(parts[1])
		var seconds = (hours * 3600) + (minutes * 60)
		TimeManager.start_timer(seconds)
	else:
		printerr("Error: Formato de hora incorrecto en 'set_time_absolute'. Esperado HH:MM.")
	return ""

func _handle_modify_time(line: Dictionary,_is_preprocessing: bool = false) -> String:
	var seconds_to_modify = int(line["modify_time"])
	TimeManager.add_time(seconds_to_modify)
	return ""

func _handle_show_time_ui(line: Dictionary,_is_preprocessing: bool = false) -> String:
	var show = line["show_time_ui"]
	if main_scene.is_node_ready():
		if show:
			main_scene.time_label.show()
			main_scene.time_icon.texture = SceneLibrary.get_ui_icon("time_active_icon")
		else:
			main_scene.time_label.hide()
			main_scene.time_icon.texture = SceneLibrary.get_ui_icon("time_inactive_icon")
	return ""

func _handle_show_cg(line: Dictionary, _is_preprocessing: bool) -> String:
	var image_name = line["show_cg"]
	if image_name.is_empty():
		printerr("Comando 'show_cg' no tiene un nombre de archivo.")
		return ""
		
	var image_path = "res://Assets/CGs/" + image_name + ".png" # Asumimos formato .png
	
	# Obtenemos una referencia a nuestro CGViewer
	var cg_viewer = main_scene.get_node("CGCanvas/CGSprite")
	var is_instant = line.get("instant", false) # Obtiene el valor, por defecto es false

	if cg_viewer:
		#main_scene.get_node("InteractiveLocation").hide()
		cg_viewer.show()

		if is_instant:
			cg_viewer.show_cg_instant(image_path)
		else:
			cg_viewer.show_cg_transition(image_path)

	return ""
	
func _handle_hide_cg(line: Dictionary, _is_preprocessing: bool) -> String:
	var cg_viewer = main_scene.get_node("CGCanvas/CGSprite")
	
	if cg_viewer:
		var is_instant = line.get("instant", false)
		
		if is_instant:
			# Oculta el CG instantáneamente
			cg_viewer.hide_cg_instant()
			# Muestra la ubicación interactiva.
			main_scene.get_node("InteractiveLocation").show()
		else:
			# Oculta el CG con transición y espera a que termine.
			cg_viewer.hide_cg_transition()
			# Muestra la ubicación interactiva solo después de que el CG se haya ido.
			main_scene.get_node("InteractiveLocation").show()

	return ""
