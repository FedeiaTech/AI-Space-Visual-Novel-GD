# CharacterStageManager.gd
# Este script gestiona el estado visual de los personajes en el escenario.
extends Node

var main_scene: Node2D

# Variables de estado
var active_characters: Dictionary = {}
var character_positions: Dictionary = {}
var character_nodes: Dictionary = {}
var character_facing_state: Dictionary = {}
var character_expression_state: Dictionary = {}
var previous_speaker: String = ""

# Función para recibir la referencia de MainScene
func set_main_scene_reference(scene_node: Node2D):
	self.main_scene = scene_node

# Función para recibir las referencias de los nodos de personaje
func set_character_nodes(nodes: Dictionary):
	self.character_nodes = nodes
	for pos_str in character_nodes.keys():
		var pos_enum = Character.get_position_enum_from_string(pos_str)
		if pos_enum != -1:
			character_positions[pos_str] = Character.POSITIONS[pos_enum]

# --- FUNCIONES DE LÓGICA ---

func handle_character_visuals(line: Dictionary, is_preprocessing: bool = false) -> String:
	var characters_data = line.get("characters", {})
	var expressions_data = line.get("expressions", {})
	var facing_data = line.get("facing", {})
	var speaker_key = line.get("speaker", "")
	# --- CAMBIO CLAVE 1: No poner valor por defecto ---
	var text_data = line.get("text") # Si no hay texto, esto será 'null'
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
	# Este bucle aplica TODOS los cambios visuales (facing, expression, etc.)
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

	# --- CAMBIO CLAVE 2: Lógica Condicional ---
	
	# Comprobamos si esta línea REALMENTE tenía texto
	if text_data != null:
		# CASO A: SÍ tiene texto. Mostramos el diálogo y esperamos el clic.
		var speaker_details = Character.get_details_from_string(speaker_key)
		main_scene.dialog_ui.change_line(speaker_key, text_data, speaker_details, expressions_data.get(speaker_position_str, "idle"))

		if not is_ia_speaking and not speaker_key.is_empty():
			previous_speaker = speaker_key
	else:
		# CASO B: NO tiene texto (¡Tu línea!)
		# Es un comando de setup. No mostramos la caja de diálogo.
		# Avanzamos automáticamente a la siguiente línea.
		if not is_preprocessing:
			main_scene.dialogue_manager.advance_index()
			main_scene.dialogue_manager.process_current_line.call_deferred()
			return "stop_processing" # Importante
	
	return ""

func handle_text(line: Dictionary, _is_preprocessing: bool = false) -> String:
	if line.has("characters"): return ""

	var speaker_key = line.get("speaker", "NARRATOR")

	# --- CASO 1: HABLA UN PERSONAJE (ej. "ASTRO", "ORI") ---
	if not speaker_key.is_empty() and speaker_key.to_upper() != "NARRATOR":
		
		# --- LÓGICA DE BÚSQUEDA MEJORADA ---
		# Primero, buscamos si el hablante ya está en escena.
		var speaker_position = ""
		for position in active_characters:
			if active_characters[position].to_upper() == speaker_key.to_upper():
				speaker_position = position
				break
		
		if speaker_position != "":
			# --- SUB-CASO 1.1: El hablante ESTÁ EN ESCENA ---
			# (Esta es la lógica que ya tenías)
			var visuals_data = {
				"characters": active_characters.duplicate(),
				"speaker": speaker_key,
				"text": line.get("text", ""),
				"positions": character_positions.duplicate(),
			}
			visuals_data["expressions"] = line.get("expressions", character_expression_state.duplicate())
			visuals_data["facing"] = line.get("facing", character_facing_state.duplicate())
			handle_character_visuals(visuals_data, _is_preprocessing)
		
		else:
			# --- SUB-CASO 1.2: El hablante NO ESTÁ EN ESCENA (¡TU BUG!) ---
			# El personaje habla "fuera de cámara".
			
			# Ponemos a todos los que SÍ están en escena en 'idle'.
			main_scene.set_current_speaker(null)
			for position in active_characters.keys():
				var character_node = character_nodes[position]
				if is_instance_valid(character_node):
					character_node.play_idle_animation()
			
			# Obtenemos los detalles del hablante (ej. "ORI")
			var speaker_details = Character.get_details_from_string(speaker_key)
			var expression = line.get("expressions", {}).get(speaker_key.to_lower(), "idle")
			
			# Y enviamos la línea a la UI sin intentar animar a nadie.
			main_scene.dialog_ui.change_line(speaker_key, line.get("text", ""), speaker_details, expression)

	# --- CASO 2: HABLA EL NARRADOR ---
	else:
		# (Esta lógica ya es correcta)
		var should_hide = line.get("hide_characters", false) # Valor por defecto es 'false'
		if should_hide:
			if not active_characters.is_empty():
				for character_node in character_nodes.values():
					if is_instance_valid(character_node):
						character_node.hide_instantly()
				active_characters.clear()
				character_expression_state.clear()
				character_facing_state.clear()
		else:
			main_scene.set_current_speaker(null)
			for position in active_characters.keys():
				var character_node = character_nodes[position]
				if is_instance_valid(character_node):
					character_node.play_idle_animation()

		var narrator_details = Character.get_details_from_string("NARRATOR")
		main_scene.set_current_speaker(null)
		main_scene.dialog_ui.change_line("NARRATOR", line.get("text", ""), narrator_details, "idle")
	
	return ""

func handle_move_character(line: Dictionary, _is_preprocessing: bool = false) -> String:
	var move_data = line.get("move_character")
	if move_data == null: return ""

	var moves_to_execute = []
	if typeof(move_data) == TYPE_ARRAY:
		moves_to_execute = move_data
	elif typeof(move_data) == TYPE_DICTIONARY:
		moves_to_execute.append(move_data)

	if moves_to_execute.is_empty(): return ""

	var should_wait_for_click = line.has("text") and not line.get("text", "").is_empty()
	_start_character_moves_and_timer(moves_to_execute, should_wait_for_click)
	return "stop_processing"

func _start_character_moves_and_timer(moves: Array, wait_for_click: bool):
	# ¡BLOQUEA EL DIÁLOGO!
	# Esto previene que el jugador haga clic en _handle_mouse_click
	main_scene.is_dialogue_blocked = true
	main_scene.dialog_ui.set_click_to_continue_enabled(false) # Oculta el triángulo
	
	var max_duration = 0.0

	for move in moves:
		var duration = float(move.get("duration", 0.5))
		if duration > max_duration: max_duration = duration
		var target_pos_str = move.get("position", "")
		var offset = move.get("offset", 0)

		if active_characters.has(target_pos_str):
			var character_node = character_nodes[target_pos_str]
			var current_pos = character_positions[target_pos_str]
			var new_pos = Vector2(current_pos.x + offset, current_pos.y)
			character_positions[target_pos_str] = new_pos

			if is_instance_valid(character_node):
				character_node.slide_to_position(new_pos, duration)

	if max_duration > 0:
		var timer = get_tree().create_timer(max_duration)
		# Usamos .bind() para pasar el parámetro 'wait_for_click'.
		timer.timeout.connect(_on_movement_finished.bind(wait_for_click))
	else:
		# Si no hay movimiento, desbloquear inmediatamente
		_on_movement_finished(wait_for_click)

# Se ejecuta CUANDO EL TIMER TERMINA.
func _on_movement_finished(wait_for_click: bool):
	# Desbloqueamos la entrada del jugador
	main_scene.is_dialogue_blocked = false
	
	if wait_for_click:
		# CASO A: La línea tenía texto (ej. "¡Deslizando!").
		# El movimiento terminó. Mostramos el triángulo
		# y esperamos a que el jugador haga clic.
		main_scene.dialog_ui.set_click_to_continue_enabled(true)
	else:
		# CASO B: La línea NO tenía texto (ej. "text": "...").
		# El movimiento terminó. Avanzamos automáticamente.
		main_scene.dialogue_manager.advance_index()
		main_scene.dialogue_manager.process_current_line.call_deferred()

func _find_character_position(character_name: String) -> String:
	for position_str in character_nodes.keys():
		var character_node = character_nodes[position_str]
		if is_instance_valid(character_node) and character_node.has_method("get_current_character_name"):
			if character_node.get_current_character_name() == character_name:
				return position_str
	return ""
