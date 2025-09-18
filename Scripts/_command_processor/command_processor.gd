# command_processor.gd
# Este nodo se encarga de ejecutar comandos embebidos en líneas de diálogo.
# Interpreta líneas específicas del JSON de diálogos para alterar el estado del juego.
extends Node

# Referencia a la escena principal que este procesador controlará
var main_scene: Node2D

# variables para guardar el estado de la línea anterior
var previous_speaker: String = ""
var previous_listener: String = ""

# En la parte superior del script, define un diccionario para los personajes.
var active_characters: Dictionary = {}

# Diccionario para almacenar la posición en píxeles de cada personaje en pantalla
var character_positions: Dictionary = {}

# Y una referencia a los nodos del personaje para acceso rápido.
var character_nodes: Dictionary = {}

# Este diccionario guardará el estado de la orientación.
# Clave: "left", "center", etc. Valor: "left", "right", "center".
var character_facing_state: Dictionary = {}

# Guarda el estado de las expresiones.
# Clave: "left", "center", etc. Valor: "idle", "happy", etc.
var character_expression_state: Dictionary = {}

# Diccionario de Manejadores de Comandos
var command_handlers: Dictionary = {
	"characters": _handle_character_visuals,
	"action": _handle_action,
	"set_flag": _handle_set_flag,
	"item_given": _handle_item_given,
	"music": _handle_music,
	"location": _handle_location,
	"anchor": _handle_anchor,
	"object": _handle_object,
	"set_time_absolute": _handle_set_time_absolute,
	"modify_time": _handle_modify_time,
	"show_time_ui": _handle_show_time_ui,
	"choices": _handle_choices,
	"text": _handle_text,
	"goto": _handle_goto,
	"flow": _handle_flow,
	"show_cg": _handle_show_cg,
	"hide_cg": _handle_hide_cg,
	"move_character": _handle_move_character,
}

func execute(line: Dictionary, is_preprocessing: bool = false) -> String:
	# Ejecuta una línea de diálogo con comandos.
	for command_name in command_handlers.keys():
		if line.has(command_name):
			print("Paso 3: CommandProcessor.execute() ha recibido la línea: ", line)
			var result = command_handlers[command_name].call(line, is_preprocessing)
			if result == "stop_processing":
				return "stop_processing"
	return ""

# Esta función permite que la escena principal se "presente" a sí misma.
func set_main_scene_reference(scene_node: Node2D):
	self.main_scene = scene_node

# ----------------------------------------------
# Manejadores de comandos individuales
# ----------------------------------------------

func _recursive_find_by_object_id(node: Node, id: String) -> Node:
	for child in node.get_children():
		if child == null: continue
		if child.has_meta("object_id") and str(child.get_meta("object_id")) == id:
			return child
		var got = child.get("object_id")
		if got != null and str(got) == id:
			return child
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
	var target_object: Node = null
	for i in range(location_container.get_child_count()):
		var candidate = location_container.get_child(i)
		if candidate != null and candidate.has_method("get_object_by_id"):
			var found = candidate.get_object_by_id(target_id)
			if found != null:
				target_object = found
				print("CommandProcessor: objeto '", target_id, "' encontrado en InteractionManager: ", candidate.name)
				break
	if target_object == null:
		target_object = _recursive_find_by_object_id(location_container, target_id)
		if target_object != null:
			print("CommandProcessor (fallback): objeto '", target_id, "' encontrado recursivamente en: ", target_object.get_path())
	if target_object != null:
		if object_data.has("visible"):
			target_object.visible = bool(object_data.get("visible"))
	else:
		printerr("CommandProcessor Error: No se encontró el objeto con ID '", target_id, "' en InteractiveLocation.")
		for i in range(location_container.get_child_count()):
			var c = location_container.get_child(i)
			if c != null and c.has_method("get_object_by_id"):
				var keys = c.get("clickable_objects") if c.get("clickable_objects") != null else "(no expone clickable_objects)"
				print(" - InteractionManager candidate:", c.name, " -> keys:", keys)
	if not is_preprocessing and not (line.has("text") or line.has("choices")):
		main_scene.dialogue_manager.advance_index()
		main_scene.dialogue_manager.process_current_line.call_deferred()
	return "stop_processing"

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
				#main_scene.character_sprite.hide_instantly()
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

func _handle_item_given(line: Dictionary,_is_preprocessing: bool = false) -> String:
	main_scene._process_item_given(line["item_given"])
	return ""

func _handle_music(line: Dictionary,_is_preprocessing: bool = false) -> String:
	var music_file = load("res://Assets/Sounds/BGM/" + line["music"] + ".mp3")
	if main_scene.background_music.stream != music_file:
		main_scene.background_music.stop()
		main_scene.background_music.stream = music_file
		main_scene.background_music.play(0.0)
	return ""

func _handle_location(line: Dictionary, is_preprocessing: bool) -> String:
	var location_container = main_scene.get_node("InteractiveLocation")
	for i in range(location_container.get_child_count() - 1, -1, -1):
		var child = location_container.get_child(i)
		child.queue_free()
	var location_name = line["location"]
	var location_scene = SceneLibrary.get_scene(location_name)
	if location_scene == null:
		printerr("Error: La escena '", location_name, "' no está definida o precargada en SceneLibrary.gd.")
		return ""
	var location_instance = location_scene.instantiate()
	location_container.add_child(location_instance)
	print("-- DEBUG: hijos de InteractiveLocation --")
	for i in range(location_container.get_child_count()):
		var c = location_container.get_child(i)
		print("child[", i, "]: name=", c.name, " type=", c.get_class(), " has_get_object_by_id=", c.has_method("get_object_by_id"))
		for j in range(c.get_child_count()):
			var sc = c.get_child(j)
			print("  subchild[", j, "]: name=", sc.name, " type=", sc.get_class(), " has_signal_object_clicked=", sc.has_signal("object_clicked"))
	print("-- fin DEBUG --")
	var new_interaction_manager = location_instance.get_node_or_null("InteractionManager")
	if new_interaction_manager and new_interaction_manager.has_method("_register_clickable_objects"):
		new_interaction_manager._register_clickable_objects(new_interaction_manager)
	var interactables_layer = location_instance.get_node("CanvasLayer")
	if interactables_layer:
		for child in interactables_layer.get_children():
			if child.has_signal("object_clicked"):
				if not child.object_clicked.is_connected(main_scene._on_object_clicked):
					child.object_clicked.connect(main_scene._on_object_clicked)
	else:
		printerr("Error: La escena de ubicación '", location_name, "' no tiene un nodo hijo llamado 'CanvasLayer'.")
	if not is_preprocessing and not (line.has("text") or line.has("choices") or line.has("action")):
		main_scene.dialogue_manager.advance_index()
		main_scene.dialogue_manager.process_current_line.call_deferred()
		return "stop_processing"
	return ""

func _handle_goto(line: Dictionary, _is_preprocessing: bool) -> String:
	main_scene.dialogue_manager.jump_to_anchor.call_deferred(line["goto"])
	return "stop_processing"

func _handle_anchor(_line: Dictionary, is_preprocessing: bool) -> String:
	if not is_preprocessing:
		main_scene.dialogue_manager.advance_index()
		main_scene.dialogue_manager.process_current_line.call_deferred()
		return "stop_processing"
	return ""

# Función corregida para manejar el error "Invalid character name: none"
func _handle_character_visuals(line: Dictionary, _is_preprocessing: bool = false) -> String:
	var characters_data = line.get("characters", {})
	var expressions_data = line.get("expressions", {})
	var facing_data = line.get("facing", {}) # Leemos el diccionario facing, puede estar vacío
	var speaker_name = line.get("speaker", "")
	var text_data = line.get("text", "")
	var positions_data = line.get("positions", {})
	
	main_scene.set_current_speaker(null)

	# Si la línea contiene una clave "characters", SIEMPRE actualizamos
	# la lista de personajes activos en la escena.
	if not characters_data.is_empty():
		active_characters = characters_data.duplicate()
		if positions_data.is_empty():
			for pos_str in active_characters.keys():
				var pos_enum = Character.get_position_enum_from_string(pos_str)
				if pos_enum != -1:
					character_positions[pos_str] = Character.POSITIONS[pos_enum]
		else:
			character_positions = positions_data.duplicate()

	var speaker_position_str = ""
	for position_str in character_nodes.keys():
		var character_node = character_nodes[position_str]

		if active_characters.has(position_str) and is_instance_valid(character_node):
			var character_name = active_characters[position_str]
			var expression = expressions_data.get(position_str, "idle")
			var is_talking = (character_name.to_lower() == speaker_name.to_lower())

			if is_talking:
				main_scene.set_current_speaker(character_node)
				speaker_position_str = position_str

			var character_enum = Character.get_enum_from_string(character_name)
			if character_enum != -1:
				var target_pos = character_positions.get(position_str, Vector2.ZERO)
				
				# --- NUEVA LÓGICA DE DECISIÓN DE ORIENTACIÓN ---
				var final_facing_direction: String

				# 1. ¿Hay una orden explícita en el JSON para esta posición?
				if facing_data.has(position_str):
					final_facing_direction = facing_data[position_str]
				
				# 2. Si no, ¿tenemos un estado guardado para esta posición?
				elif character_facing_state.has(position_str):
					final_facing_direction = character_facing_state[position_str]
				
				# 3. Si no, es la primera vez. Usamos la lógica por defecto.
				else:
					var pos_enum_default = Character.get_position_enum_from_string(position_str)
					if pos_enum_default == Character.Position.RIGHT or pos_enum_default == Character.Position.FAR_RIGHT:
						final_facing_direction = "left"
					else:
						final_facing_direction = "right"
				
				# ¡Guardamos el estado para la próxima vez!
				character_facing_state[position_str] = final_facing_direction
				# --- FIN DE LA NUEVA LÓGICA ---
				
				# Pasamos la dirección final al nodo del personaje
				character_node.change_character_with_position(character_enum, is_talking, expression, target_pos, final_facing_direction)
		else:
			if is_instance_valid(character_node):
				character_node.hide_instantly()
	
	self.character_expression_state = expressions_data.duplicate()

	main_scene.dialog_ui.change_line(speaker_name, text_data, expressions_data.get(speaker_position_str, "idle"))

	return "stop_processing"

func _handle_choices(line: Dictionary,_is_preprocessing: bool = false) -> String:
	var all_choices = line["choices"]
	var playable_choices: Array = []
	for choice in all_choices:
		var is_item_condition_met = true
		var is_flag_condition_met = true
		var required_item_id = choice.get("requires_item", "")
		if not required_item_id.is_empty():
			is_item_condition_met = InventoryManager.has_item(InventoryManager.current_player_character, required_item_id)
		var required_flag_id = choice.get("requires_flag", "")
		if not required_flag_id.is_empty():
			var expected_flag_value = choice.get("flag_value", true)
			is_flag_condition_met = GameManager.get_quest_flag(required_flag_id) == expected_flag_value
			if not is_flag_condition_met:
				print("Opción '", choice.get("text", "Sin texto"), "' omitida: requiere bandera '", required_flag_id, "' sea ", expected_flag_value)
		if is_item_condition_met and is_flag_condition_met:
			playable_choices.append(choice)
		elif not is_item_condition_met:
			print("Opción '", choice.get("text", "Sin texto"), "' omitida: requiere ítem '", required_item_id, "' que no está en el inventario.")
	if playable_choices.is_empty():
		main_scene.dialog_ui.change_line("Narrador", "No puedo hacer eso en este momento.")
		main_scene.dialogue_manager.advance_index()
		main_scene.dialogue_manager.process_current_line.call_deferred()
		return "stop_processing"
	main_scene.dialog_ui.display_choices(playable_choices)
	return "stop_processing"

func _handle_text(line: Dictionary, _is_preprocessing: bool = false) -> String:
	# Si la línea ya tiene un comando "characters", no hagas nada,
	# ya que _handle_character_visuals se encargará de todo.
	if line.has("characters"):
		return ""

	var speaker_name_str = line.get("speaker", "NARRATOR")

	# --- CASO 1: HAY UN ORADOR (NO ES EL NARRADOR) ---
	if not speaker_name_str.is_empty() and speaker_name_str.to_upper() != "NARRATOR":
		# Si no hay personajes activos en escena, no hacemos nada.
		if active_characters.is_empty():
			printerr("Error: Se intentó una línea de diálogo para '", speaker_name_str, "' pero no hay personajes en escena.")
			# Avanzamos para no quedarnos atascados
			main_scene.dialogue_manager.advance_index()
			main_scene.dialogue_manager.process_current_line.call_deferred()
			return "stop_processing"

		# Preparamos los datos para renderizar, usando el estado guardado como base.
		var visuals_data = {
			"characters": active_characters.duplicate(),
			"speaker": speaker_name_str,
			"text": line.get("text", ""),
			"positions": character_positions.duplicate(),
			"facing": character_facing_state.duplicate() # Mantenemos la orientación
		}
		
		# Decidimos qué expresiones usar
		if line.has("expressions"):
			# Si la línea define nuevas expresiones, las usamos.
			visuals_data["expressions"] = line.get("expressions")
		else:
			# Si no, usamos las últimas expresiones guardadas.
			visuals_data["expressions"] = character_expression_state.duplicate()
		
		# Llamamos a la función principal de renderizado con los datos completos.
		_handle_character_visuals(visuals_data, _is_preprocessing)

	# --- CASO 2: ES UNA LÍNEA DEL NARRADOR ---
	else:
		# El narrador OCULTA a todos los personajes y limpia el estado.
		if not active_characters.is_empty():
			for position_str in character_nodes.keys():
				var character_node = character_nodes[position_str]
				if is_instance_valid(character_node):
					character_node.hide_instantly()
			
			# Limpiamos los diccionarios de estado para un inicio limpio la próxima vez
			active_characters.clear()
			character_expression_state.clear()
			character_facing_state.clear()
		
		# Mostramos el texto del narrador
		main_scene.set_current_speaker(null)
		main_scene.dialog_ui.change_line("Narrador", line.get("text", ""), "idle")
		
	return "stop_processing"

## Funcion auxiliar para buscar la posición de un personaje que ya está en pantalla
func _find_character_position(character_name: String) -> String:
	for position_str in character_nodes.keys():
		var character_node = character_nodes[position_str]
		if is_instance_valid(character_node) and character_node.has_method("get_current_character_name"):
			if character_node.get_current_character_name() == character_name:
				return position_str
	return ""

func _handle_flow(line: Dictionary, _is_preprocessing: bool = false) -> String:
	var mode = line.get("flow", "")
	if mode == "explore":
		main_scene.enter_interaction_mode()
		return "stop_processing"
	return ""

func _handle_set_flag(line: Dictionary,_is_preprocessing: bool = false) -> String:
	var flag_data = line["set_flag"]
	if typeof(flag_data) == TYPE_DICTIONARY:
		var flag_id = flag_data.get("id", "")
		var value = flag_data.get("value", true)
		if not flag_id.is_empty():
			GameManager.set_quest_flag(flag_id, value)
		else:
			printerr("Error: 'set_flag' sin 'id' de bandera.")
	else:
		printerr("Error: Formato incorrecto para el comando 'set_flag'. Esperado {id: 'flag_id', value: true/false}.")
	return ""

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

func _handle_move_character(line: Dictionary, _is_preprocessing: bool = false) -> String:
	var move_data = line.get("move_character", {})
	var target_pos_str = move_data.get("position", "") # Ej: "center"
	var offset = move_data.get("offset", 0)
	var duration = float(move_data.get("duration", 0.5))
	
	# Asegurarnos de que hay un personaje activo en esa posición
	if active_characters.has(target_pos_str):
		# Obtenemos el nodo de control de esa posición
		var character_node = character_nodes[target_pos_str]
		
		# Calculamos la nueva posición sumando el offset
		var current_pos = character_positions[target_pos_str]
		var new_pos = Vector2(current_pos.x + offset, current_pos.y)
		
		# Actualizamos el estado en nuestro diccionario
		character_positions[target_pos_str] = new_pos
		
		# Le decimos al nodo del personaje que se mueva
		if is_instance_valid(character_node):
			character_node.slide_to_position(new_pos, duration)
			return "stop_processing" # Importante para que no siga procesando
			
	printerr("Error en move_character: No se encontró un personaje en la posición '", target_pos_str, "'")
	return ""

# Función para recibir las referencias de los nodos
func set_character_nodes(nodes: Dictionary):
	self.character_nodes = nodes
	# Inicializar el diccionario de posiciones con los valores nominales por defecto
	for pos_str in character_nodes.keys():
		var pos_enum = Character.get_position_enum_from_string(pos_str)
		if pos_enum != -1:
			character_positions[pos_str] = Character.POSITIONS[pos_enum]
