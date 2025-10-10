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
	"shake": _handle_shake,
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
	var location_container = main_scene.get_node("InteractiveControl").get_node("InteractiveLocation")
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
	# Informamos a MainScene sobre la nueva instancia de la localización.
	main_scene.register_new_location(location_instance)
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
	var facing_data = line.get("facing", {})
	var speaker_key = line.get("speaker", "")
	var text_data = line.get("text", "")
	var positions_data = line.get("positions", {})
	
	var is_ia_speaking = (speaker_key.to_upper() == "IA")
	main_scene.set_current_speaker(null)

	if not characters_data.is_empty():
		active_characters = characters_data.duplicate()
		if positions_data.is_empty():
			for pos_str in active_characters.keys():
				var pos_enum = Character.get_position_enum_from_string(pos_str)
				if pos_enum != -1: character_positions[pos_str] = Character.POSITIONS[pos_enum]
		else:
			character_positions = positions_data.duplicate()

	var speaker_position_str = ""
	for position_str in character_nodes.keys():
		var character_node = character_nodes[position_str]
		if active_characters.has(position_str) and is_instance_valid(character_node):
			var character_key = active_characters[position_str]
			var expression = expressions_data.get(position_str, "idle")
			var is_talking = (character_key.to_lower() == speaker_key.to_lower())

			if is_talking and not is_ia_speaking:
				main_scene.set_current_speaker(character_node)
				speaker_position_str = position_str
			elif is_ia_speaking and previous_speaker.to_lower() == character_key.to_lower():
				main_scene.set_current_speaker(character_node)

			var character_enum = Character.get_enum_from_string(character_key)
			if character_enum != -1:
				var target_pos = character_positions.get(position_str, Vector2.ZERO)
				var final_facing_direction: String
				if facing_data.has(position_str):
					final_facing_direction = facing_data[position_str]
				elif character_facing_state.has(position_str):
					final_facing_direction = character_facing_state[position_str]
				else:
					var pos_enum_default = Character.get_position_enum_from_string(position_str)
					final_facing_direction = "left" if pos_enum_default == Character.Position.RIGHT or pos_enum_default == Character.Position.FAR_RIGHT else "right"
				
				character_facing_state[position_str] = final_facing_direction
				character_node.change_character_with_position(character_enum, is_talking and not is_ia_speaking, expression, target_pos, final_facing_direction)
		else:
			if is_instance_valid(character_node): character_node.hide_instantly()
	
	self.character_expression_state = expressions_data.duplicate()

	# Obtenemos los detalles del hablante UNA SOLA VEZ.
	var speaker_details = Character.get_details_from_string(speaker_key)
	
	# --- LLAMADA CORREGIDA ---
	# Pasamos la clave, el texto, y el diccionario de detalles completo.
	main_scene.dialog_ui.change_line(speaker_key, text_data, speaker_details, expressions_data.get(speaker_position_str, "idle"))

	if not is_ia_speaking and not speaker_key.is_empty():
		previous_speaker = speaker_key

	return ""

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
	if line.has("characters"): return ""

	var speaker_key = line.get("speaker", "NARRATOR")

	# --- CASO 1: HAY UN ORADOR (NO ES EL NARRADOR) ---
	if not speaker_key.is_empty() and speaker_key.to_upper() != "NARRATOR":
		if active_characters.is_empty():
			printerr("Error: Diálogo para '", speaker_key, "' pero no hay personajes en escena.")
			main_scene.dialogue_manager.advance_index()
			main_scene.dialogue_manager.process_current_line.call_deferred()
			return "stop_processing"

		var visuals_data = {
			"characters": active_characters.duplicate(),
			"speaker": speaker_key,
			"text": line.get("text", ""),
			"positions": character_positions.duplicate(),
			"facing": character_facing_state.duplicate()
		}
		visuals_data["expressions"] = line.get("expressions", character_expression_state.duplicate())
		_handle_character_visuals(visuals_data, _is_preprocessing)

	# --- CASO 2: ES UNA LÍNEA DEL NARRADOR (LÓGICA MEJORADA) ---
	else:
		# Buscamos la nueva clave. Por defecto, ocultará a los personajes para
		# mantener la compatibilidad con tus JSONs antiguos.
		var should_hide = line.get("hide_characters", true)

		if should_hide:
			# Si debemos ocultar, ejecutamos la lógica de limpieza anterior.
			if not active_characters.is_empty():
				for character_node in character_nodes.values():
					if is_instance_valid(character_node):
						character_node.hide_instantly()
				
				# Limpiamos el estado POR COMPLETO.
				active_characters.clear()
				character_expression_state.clear()
				character_facing_state.clear()
		else:
			# Si NO debemos ocultar, simplemente ponemos a todos en modo 'idle'.
			# NO limpiamos el estado.
			main_scene.set_current_speaker(null) # Quitamos el foco del hablante anterior
			for position in active_characters.keys():
				var character_node = character_nodes[position]
				if is_instance_valid(character_node):
					character_node.play_idle_animation()
		
		# Esta parte se ejecuta en ambos casos (ocultando o no).
		var narrator_details = Character.get_details_from_string("NARRATOR")
		main_scene.set_current_speaker(null)
		main_scene.dialog_ui.change_line("NARRATOR", line.get("text", ""), narrator_details, "idle")
		
	return ""

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
	var move_data = line.get("move_character")
	if move_data == null: return ""

	var moves_to_execute = []
	if typeof(move_data) == TYPE_ARRAY:
		moves_to_execute = move_data
	elif typeof(move_data) == TYPE_DICTIONARY:
		moves_to_execute.append(move_data)

	if moves_to_execute.is_empty():
		return ""

	var should_wait_for_click = line.has("text") and not line.get("text", "").is_empty()

	# Llamamos a la nueva función que inicia todo el proceso
	_start_character_moves_and_timer(moves_to_execute, should_wait_for_click)
	
	return "stop_processing"

# Inicia los movimientos y el temporizador.
func _start_character_moves_and_timer(moves: Array, wait_for_click: bool):
	# 1. Bloqueamos el diálogo inmediatamente
	main_scene.is_dialogue_blocked = true
	main_scene.dialog_ui.set_click_to_continue_enabled(false)
	
	var max_duration = 0.0

	# 2. Iniciamos todas las animaciones de movimiento (tweens)
	for move in moves:
		var duration = float(move.get("duration", 0.5))
		# Buscamos la duración más larga para saber cuánto esperar
		if duration > max_duration:
			max_duration = duration
			
		var target_pos_str = move.get("position", "")
		var offset = move.get("offset", 0)
		
		if active_characters.has(target_pos_str):
			var character_node = character_nodes[target_pos_str]
			var current_pos = character_positions[target_pos_str]
			var new_pos = Vector2(current_pos.x + offset, current_pos.y)
			
			character_positions[target_pos_str] = new_pos
			
			if is_instance_valid(character_node):
				# Simplemente iniciamos el tween, no lo esperamos.
				character_node.slide_to_position(new_pos, duration)

	# 3. Si hubo movimiento, creamos un Timer para que nos avise cuando termine
	if max_duration > 0:
		# get_tree().create_timer() es una forma segura de crear un timer temporal.
		# Se destruirá solo después de activarse.
		var timer = get_tree().create_timer(max_duration)
		
		# Conectamos la señal 'timeout' del timer a nuestra función de finalización.
		# Usamos .bind() para pasarle el parámetro 'wait_for_click'.
		timer.timeout.connect(_on_movement_finished.bind(wait_for_click))
	else:
		# Si por alguna razón no hubo movimiento, nos desbloqueamos inmediatamente
		_on_movement_finished(wait_for_click)


# Se ejecuta CUANDO EL TIMER TERMINA.
func _on_movement_finished(wait_for_click: bool):
	# Esta función se llama de forma segura después de que el tiempo ha pasado.
	main_scene.is_dialogue_blocked = false
	
	if wait_for_click:
		# Permitimos que el usuario haga clic para avanzar.
		main_scene.dialog_ui.set_click_to_continue_enabled(true)
	else:
		# Avanzamos automáticamente (para movimientos sin texto).
		main_scene.dialogue_manager.advance_index()
		main_scene.dialogue_manager.process_current_line.call_deferred()
# Función para recibir las referencias de los nodos
func set_character_nodes(nodes: Dictionary):
	self.character_nodes = nodes
	# Inicializar el diccionario de posiciones con los valores nominales por defecto
	for pos_str in character_nodes.keys():
		var pos_enum = Character.get_position_enum_from_string(pos_str)
		if pos_enum != -1:
			character_positions[pos_str] = Character.POSITIONS[pos_enum]

func _handle_shake(line: Dictionary, _is_preprocessing: bool = false) -> String:
	var shake_data = line["shake"]
	var duration = float(shake_data.get("duration", 0.5))
	var magnitude = float(shake_data.get("magnitude", 10.0))
	
	if main_scene:
		var nodes_to_pass = [main_scene.main_canvas_control, main_scene.dialog_ui]
		
		# Le pedimos a MainScene la referencia a la localización activa
		var current_location = main_scene.get_current_location_node()
		
		# Comprobamos si es válida antes de añadirla
		if is_instance_valid(current_location):
			nodes_to_pass.append(current_location)
		
		main_scene.start_shake(duration, magnitude, nodes_to_pass)
	else:
		printerr("Error: No se ha asignado la referencia a la main_scene.")
	
	return ""
