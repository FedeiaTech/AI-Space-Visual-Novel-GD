# command_processor.gd
# Interpreta las líneas de diálogo y delega la ejecución de comandos.
# Actúa como el "cerebro" central que conecta la historia con el juego.
extends Node

# -------------------------------------------------------------------
# --- Variables y Referencias ---
# -------------------------------------------------------------------

var main_scene: Node2D
var stage_manager: Node
var camera_shaker: Node

var previous_listener: String = ""

# -------------------------------------------------------------------
# --- Diccionario de Comandos ---
# -------------------------------------------------------------------

# Define qué función maneja cada clave JSON en una línea de diálogo.
# Estos comandos se ejecutan PRIMERO y no detienen el procesamiento.
var setup_and_display_handlers: Dictionary = {
	# Comandos de estado
	"set_flag": _handle_set_flag,
	"item_given": _handle_item_given,
	"remove_item": _handle_remove_item,
	"activate_quest": _handle_activate_quest,
	"complete_quest": _handle_complete_quest,
	
	# Comandos de escena y UI
	"location": _handle_location,
	"object": _handle_object,
	"music": _handle_music,
	"shake": _handle_shake,
	"show_time_ui": _handle_show_time_ui,
	"set_time_absolute": _handle_set_time_absolute,
	"modify_time": _handle_modify_time,
	
	# Comandos de escenario (Delegados)
	"characters": _handle_character_visuals,
	"text": _handle_text,
	"show_cg": _handle_show_cg,
	"hide_cg": _handle_hide_cg,
}

# Estos comandos se ejecutan AL FINAL y detienen el procesamiento.
var flow_control_handlers: Dictionary = {
	"move_character": _handle_move_character,
	"action": _handle_action,
	"goto": _handle_goto,
	"flow": _handle_flow,
	"anchor": _handle_anchor,
	"choices": _handle_choices,
}


# -------------------------------------------------------------------
# --- Funciones Principales y de Configuración ---
# -------------------------------------------------------------------

# Punto de entrada principal. Recibe una línea y ejecuta los comandos.
func execute(line: Dictionary, is_preprocessing: bool = false) -> String:
	
	var flow_command_found: String = ""
	var display_command_found: bool = false

	# --- Bucle 1: Ejecutar TODOS los comandos de setup/display (¡AHORA PRIMERO!) ---
	for command_name in setup_and_display_handlers.keys():
		if line.has(command_name):
			print("Paso 3: Procesando (Setup/Display): ", command_name)
			setup_and_display_handlers[command_name].call(line, is_preprocessing)
			
			if command_name == "text" or command_name == "show_cg":
				display_command_found = true

	# --- Bucle 2: Buscar el comando de flujo MÁS IMPORTANTE ---
	var flow_priority = ["choices", "action", "goto", "move_character", "flow", "anchor"]
	
	for command_name in flow_priority:
		if line.has(command_name):
			flow_command_found = command_name
			break # Encontramos el más importante, detenemos la búsqueda

	# --- Bucle 3: Decidir qué hacer con el comando de flujo ---
	if not flow_command_found.is_empty():
		
		var cmd = flow_command_found
		
		# Si hay texto (y no estamos pre-procesando), debemos ser selectivos.
		if display_command_found and not is_preprocessing:
			
			# CASO A: "choices". Debe ejecutarse AHORA.
			if cmd == "choices":
				print("Paso 3: Ejecutando (Flow): ", cmd)
				return flow_control_handlers[cmd].call(line, is_preprocessing)
			
			# CASO B: "goto" o "action". NO deben ejecutarse. Se manejan al clic.
			elif cmd == "goto" or cmd == "action":
				print("Paso 3: Omitiendo (Flow) para clic: ", cmd)
				return "" # Omite el comando, espera el clic
				
			# CASO C: "anchor", "move_character", "flow".
			# Estos SÍ deben ejecutarse (sus 'handlers' saben qué hacer).
			else:
				print("Paso 3: Ejecutando (Flow) con texto: ", cmd)
				return flow_control_handlers[cmd].call(line, is_preprocessing)
		
		else:
			# Si NO hay texto (o es pre-procesamiento), ejecutamos el comando de flujo ahora.
			print("Paso 3: Ejecutando (Flow): ", cmd)
			return flow_control_handlers[cmd].call(line, is_preprocessing)

	return ""

# Recibe la referencia a MainScene (Inyección de dependencia).
func set_main_scene_reference(scene_node: Node2D):
	self.main_scene = scene_node

# Recibe la referencia al CharacterStageManager (Inyección de dependencia).
func set_stage_manager(manager: Node):
	self.stage_manager = manager

# Recibe la referencia al CameraShaker (Inyección de dependencia).
func set_camera_shaker(shaker: Node):
	self.camera_shaker = shaker

# -------------------------------------------------------------------
# --- Manejadores: Escenario y Personajes (Delegados) ---
# -------------------------------------------------------------------

# Delega el manejo de aparición/cambio de personajes al StageManager.
func _handle_character_visuals(line: Dictionary, is_preprocessing: bool = false) -> String:
	return stage_manager.handle_character_visuals(line, is_preprocessing)

# Delega el manejo de texto (narrador o personaje) al StageManager.
func _handle_text(line: Dictionary, is_preprocessing: bool = false) -> String:
	return stage_manager.handle_text(line, is_preprocessing)

# Delega el manejo de movimiento de personajes al StageManager.
func _handle_move_character(line: Dictionary, is_preprocessing: bool = false) -> String:
	return stage_manager.handle_move_character(line, is_preprocessing)


# -------------------------------------------------------------------
# --- Manejadores: Flujo, Lógica y Estado ---
# -------------------------------------------------------------------

# Maneja acciones complejas, como cargar nuevas escenas.
func _handle_action(line: Dictionary, _is_preprocessing: bool = false) -> String:
	var action_data = line["action"]
	var action_type = action_data.get("type", "")
	match action_type:
		"load_scene":
			main_scene.exit_interaction_mode()
			var target_file = action_data.get("scene_file", "")
			var target_anchor = action_data.get("anchor", "")
			var perform_transition = line.get("has_transition", true)
			var effect_type = line.get("transition_type", action_data.get("transition", "fade"))
			if perform_transition and not effect_type.is_empty():
				main_scene.transition_effect = effect_type
				main_scene.dialog_ui.hide()
				main_scene.is_transitioning = true
				main_scene.look_button.hide()
				SceneManager.transition_out(main_scene.transition_effect)
				GameManager.request_scene_load(target_file, target_anchor)
			else:
				main_scene.load_new_scene_content_instantly(target_file, target_anchor)
			return "stop_processing"
		"goto_internal":
			return _handle_goto({"goto": action_data.get("anchor", "")}, true)
		_:
			printerr("Acción no reconocida: ", action_type)
	return ""

# Pide al DialogueManager que salte a una nueva ancla.
func _handle_goto(line: Dictionary, _is_preprocessing: bool) -> String:
	main_scene.dialogue_manager.jump_to_anchor.call_deferred(line["goto"])
	return "stop_processing"

# Pasa el control del diálogo al modo de exploración.
func _handle_flow(line: Dictionary, _is_preprocessing: bool = false) -> String:
	var mode = line.get("flow", "")
	if mode == "explore":
		main_scene.enter_interaction_mode()
		return "stop_processing"
	return ""

# Procesa un ancla (no hace nada si está pre-procesando, avanza si no).
func _handle_anchor(line: Dictionary, is_preprocessing: bool) -> String:
	
	# Si estamos pre-procesando, solo detenemos (comportamiento antiguo).
	if is_preprocessing:
		return "stop_processing"
		
	# Si la línea de ancla TAMBIÉN tiene texto o elecciones,
	# entonces es una línea normal y debe detenerse para esperar el clic.
	if line.has("text") or line.has("choices") or line.has("show_cg"):
		return "stop_processing"

	# Si es SÓLO un ancla (o un ancla con 'setup' como 'set_flag'),
	# avanza automáticamente a la siguiente línea.
	# ¡ESTO ARREGLA EL BUG DEL "DOBLE CLIC"!
	main_scene.dialogue_manager.advance_index()
	main_scene.dialogue_manager.process_current_line.call_deferred()
	
	return "stop_processing"

# Muestra un set de elecciones en la UI.
func _handle_choices(line: Dictionary,_is_preprocessing: bool = false) -> String:
	var all_choices = line["choices"]
	var playable_choices: Array = []
	
	# Filtra las elecciones según las flags y los items del jugador
	for choice in all_choices:
		# 1. Asumimos que todas las condiciones se cumplen por defecto
		var is_item_condition_met = true
		var is_flag_condition_met = true
		var is_quest_condition_met = true

		# 2. Comprobar Ítem
		var required_item_id = choice.get("requires_item", "")
		if not required_item_id.is_empty():
			is_item_condition_met = InventoryManager.has_item(InventoryManager.current_player_character, required_item_id)
		
		# 3. Comprobar Flag (bandera simple)
		var required_flag_id = choice.get("requires_flag", "")
		if not required_flag_id.is_empty():
			var expected_flag_value = choice.get("flag_value", true)
			is_flag_condition_met = MissionControl.get_quest_flag(required_flag_id) == expected_flag_value
		
		# 4. Comprobar Quest (misión compleja)
		var required_quest_id = choice.get("requires_quest", "")
		if not required_quest_id.is_empty():
			var required_state_str = choice.get("quest_state", "ACTIVE").to_upper()
			var required_state = MissionControl.QuestState.ACTIVE # Por defecto

			if required_state_str == "LOCKED":
				required_state = MissionControl.QuestState.LOCKED
			elif required_state_str == "COMPLETED":
				required_state = MissionControl.QuestState.COMPLETED

			is_quest_condition_met = (MissionControl.get_quest_state(required_quest_id) == required_state)
		
		# 5. Decisión final: Solo si TODAS las condiciones son verdaderas
		if is_item_condition_met and is_flag_condition_met and is_quest_condition_met:
			playable_choices.append(choice)
		
		# (Debug: imprime por qué se omitió una opción)
		elif not is_item_condition_met:
			print("Opción '", choice.text, "' omitida: Requiere ítem.")
		elif not is_flag_condition_met:
			print("Opción '", choice.text, "' omitida: Requiere flag.")
		elif not is_quest_condition_met:
			print("Opción '", choice.text, "' omitida: Requiere estado de misión.")

	# ... (el resto de tu función es perfecto) ...
	if playable_choices.is_empty():
		main_scene.dialog_ui.change_line("Narrador", "No puedo hacer eso en este momento.")
		main_scene.dialogue_manager.advance_index()
		main_scene.dialogue_manager.process_current_line.call_deferred()
		return "stop_processing"
		
	main_scene.dialog_ui.display_choices(playable_choices)
	return "stop_processing"

# Establece el valor de una bandera de misión en GameManager.
func _handle_set_flag(line: Dictionary,_is_preprocessing: bool = false) -> String:
	var flag_data = line["set_flag"]
	if typeof(flag_data) == TYPE_DICTIONARY:
		var flag_id = flag_data.get("id", "")
		var value = flag_data.get("value", true)
		if not flag_id.is_empty():
			MissionControl.set_quest_flag(flag_id, value)
		else:
			printerr("Error: 'set_flag' sin 'id' de bandera.")
	else:
		printerr("Error: Formato incorrecto para 'set_flag'.")
	return ""

# Pasa la información del ítem a MainScene para que lo añada al inventario.
func _handle_item_given(line: Dictionary,_is_preprocessing: bool = false) -> String:
	main_scene._process_item_given(line["item_given"])
	return ""

# Elimina un ítem del inventario del jugador.
func _handle_remove_item(line: Dictionary, _is_preprocessing: bool = false) -> String:
	var item_data = line.get("remove_item")

	if item_data is String:
		# Caso 1: Se proporciona un solo string (ID)
		InventoryManager.remove_item(InventoryManager.current_player_character, item_data)
	elif item_data is Array:
		# Caso 2: Se proporciona un array de strings (IDs)
		for item_id in item_data:
			if item_id is String:
				InventoryManager.remove_item(InventoryManager.current_player_character, item_id)
	return ""
	
# Activa una nueva misión en el MissionControl
func _handle_activate_quest(line: Dictionary, _is_preprocessing: bool = false) -> String:
	var quest_data = line.get("activate_quest")
	
	if quest_data is String:
		# Caso 1: Se proporciona un solo string (como antes)
		MissionControl.activate_quest(quest_data)
	elif quest_data is Array:
		# Caso 2: Se proporciona un array de strings
		for quest_id in quest_data:
			if quest_id is String:
				MissionControl.activate_quest(quest_id)
	return ""

# Completa una misión activa en el MissionControl
func _handle_complete_quest(line: Dictionary, _is_preprocessing: bool = false) -> String:
	var quest_data = line.get("complete_quest")
	
	if quest_data is String:
		# Caso 1: Se proporciona un solo string
		MissionControl.complete_quest(quest_data)
	elif quest_data is Array:
		# Caso 2: Se proporciona un array de strings
		for quest_id in quest_data:
			if quest_id is String:
				MissionControl.complete_quest(quest_id)
	return ""

# -------------------------------------------------------------------
# --- Manejadores: Escena, Efectos y UI ---
# -------------------------------------------------------------------

# Carga una nueva escena de localización interactiva.
func _handle_location(line: Dictionary, is_preprocessing: bool) -> String:
	var location_container = main_scene.get_node("InteractiveControl").get_node("InteractiveLocation")
	# Limpia la localización anterior
	for i in range(location_container.get_child_count() - 1, -1, -1):
		var child = location_container.get_child(i)
		child.queue_free()
	
	# Carga e instancia la nueva
	var location_name = line["location"]
	var location_scene = SceneLibrary.get_scene(location_name)
	if location_scene == null:
		printerr("Error: La escena '", location_name, "' no está en SceneLibrary.gd.")
		return ""
	var location_instance = location_scene.instantiate()
	location_container.add_child(location_instance)
	main_scene.register_new_location(location_instance)
	
	# Conecta los objetos clicables de la nueva localización
	var new_interaction_manager = location_instance.get_node_or_null("InteractionManager")
	if new_interaction_manager and new_interaction_manager.has_method("_register_clickable_objects"):
		new_interaction_manager._register_clickable_objects(new_interaction_manager)
		
	# Avanza automáticamente si no hay más comandos en esta línea
	if not is_preprocessing and not (line.has("text") or line.has("choices") or line.has("action")):
		main_scene.dialogue_manager.advance_index()
		main_scene.dialogue_manager.process_current_line.call_deferred()
		return "stop_processing"
	return ""

# Modifica un objeto interactivo en la escena (ej. hacerlo visible/invisible).
func _handle_object(line: Dictionary, is_preprocessing: bool = false) -> String:
	var object_data = line.get("object", {})
	var target_id = str(object_data.get("id", ""))
	if target_id == "":
		printerr("CommandProcessor Error: 'object' no tiene 'id'.")
		return ""
		
	var location_container = main_scene.get_node("InteractiveLocation")
	if location_container == null or location_container.get_child_count() == 0:
		printerr("CommandProcessor Error: No hay localización cargada.")
		return ""
		
	var target_object: Node = null
	
	# Busca el objeto a través del InteractionManager de la localización
	for i in range(location_container.get_child_count()):
		var candidate = location_container.get_child(i)
		if candidate != null and candidate.has_method("get_object_by_id"):
			var found = candidate.get_object_by_id(target_id)
			if found != null:
				target_object = found
				break
	
	# Modifica el objeto si se encontró
	if target_object != null:
		if object_data.has("visible"):
			target_object.visible = bool(object_data.get("visible"))
	else:
		printerr("CommandProcessor Error: No se encontró el objeto con ID '", target_id, "'.")

	# Avanza automáticamente
	if not is_preprocessing and not (line.has("text") or line.has("choices")):
		main_scene.dialogue_manager.advance_index()
		main_scene.dialogue_manager.process_current_line.call_deferred()
	return "stop_processing"

# Cambia la música de fondo.
func _handle_music(line: Dictionary,_is_preprocessing: bool = false) -> String:
	var music_file = load("res://Assets/Sounds/BGM/" + line["music"] + ".mp3")
	if main_scene.background_music.stream != music_file:
		main_scene.background_music.stop()
		main_scene.background_music.stream = music_file
		main_scene.background_music.play(0.0)
	return ""

# Muestra una imagen de CG (Computer Graphic).
func _handle_show_cg(line: Dictionary, _is_preprocessing: bool) -> String:
	var image_name = line["show_cg"]
	if image_name.is_empty():
		printerr("Comando 'show_cg' no tiene un nombre de archivo.")
		return ""
	var image_path = "res://Assets/CGs/" + image_name + ".png"
	var cg_viewer = main_scene.get_node("CGCanvas/CGSprite")
	var is_instant = line.get("instant", false)
	var is_full_screen = line.get("full_screen", false)
	if cg_viewer:
		cg_viewer.show()
		if is_instant:
			cg_viewer.show_cg_instant(image_path, is_full_screen)
		else:
			cg_viewer.show_cg_transition(image_path, is_full_screen)
	return "stop_processing"

# Oculta el CG actual.
func _handle_hide_cg(line: Dictionary, _is_preprocessing: bool) -> String:
	var cg_viewer = main_scene.get_node("CGCanvas/CGSprite")
	if cg_viewer:
		var is_instant = line.get("instant", false)
		if is_instant:
			cg_viewer.hide_cg_instant()
			main_scene.get_node("InteractiveLocation").show()
		else:
			cg_viewer.hide_cg_transition()
			main_scene.get_node("InteractiveLocation").show()
	return ""

# Pide a MainScene que inicie un temblor de pantalla.
func _handle_shake(line: Dictionary, _is_preprocessing: bool = false) -> String:
	var shake_data = line["shake"]
	var duration = float(shake_data.get("duration", 0.5))
	var magnitude = float(shake_data.get("magnitude", 10.0))
	
	if camera_shaker:
		var nodes_to_pass = [main_scene.main_canvas_control, main_scene.dialog_ui]
		var current_location = main_scene.get_current_location_node()
		if is_instance_valid(current_location):
			nodes_to_pass.append(current_location)
		
		camera_shaker.start_shake(duration, magnitude, nodes_to_pass)
	else:
		printerr("Error: No se ha asignado la referencia al camera_shaker.")

	return ""

# -------------------------------------------------------------------
# --- Manejadores: Lógica de Tiempo ---
# -------------------------------------------------------------------

# Establece el temporizador global a una hora absoluta.
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

# Añade o resta segundos al temporizador global.
func _handle_modify_time(line: Dictionary,_is_preprocessing: bool = false) -> String:
	var seconds_to_modify = int(line["modify_time"])
	TimeManager.add_time(seconds_to_modify)
	return ""

# Muestra u oculta la UI del temporizador.
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
