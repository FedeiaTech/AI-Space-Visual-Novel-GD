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
	# Comandos de visualización y flujo
	"set_time_absolute": _handle_set_time_absolute,
	"modify_time": _handle_modify_time,
	"show_time_ui": _handle_show_time_ui,
	"show_character": _handle_show_character,
	"choices": _handle_choices,
	"text": _handle_text,
	"goto": _handle_goto,
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
			var result = command_handlers[command_name].call(line, is_preprocessing)
			if result == "stop_processing":
				return "stop_processing"
	return ""


# ----------------------------------------------
""" Manejadores de comandos individuales """
# ----------------------------------------------

func _handle_action(line: Dictionary,_is_preprocessing: bool = false) -> String:
	# Maneja acciones especiales como cambiar de escena o ir a un ancla interna.
	var action_data = line["action"]
	var action_type = action_data.get("type", "")

	match action_type:
		"load_scene":
			# Guardamos el estado actual para poder volver si es necesario
			GameManager.previous_dialog_file = main_scene.dialogue_manager.dialog_file
			GameManager.previous_dialog_index = main_scene.dialogue_manager.dialog_index
			
			var target_file = action_data.get("scene_file", "")
			var target_anchor = action_data.get("anchor", "")
			main_scene.transition_effect = action_data.get("transition", "fade")
			
			if target_file.is_empty():
				printerr("Error: 'load_scene' action sin 'scene_file'.")
				return ""

			# Oculta elementos visuales y comienza transición
			main_scene.dialog_ui.hide()
			main_scene.character_sprite.hide_instantly()
			main_scene.is_transitioning = true
			SceneManager.transition_out(main_scene.transition_effect)
			GameManager.request_scene_load(target_file, target_anchor)
			return "stop_processing" # Detener el procesamiento de esta línea
		
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
	main_scene.background.texture = load("res://Assets/Scenes_images/" + line["location"] + ".png")
	
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

func _handle_text(line: Dictionary,_is_preprocessing: bool = false) -> String:
	# 1. Determinar el NOMBRE del hablante (para la UI).
	var speaker_enum = Character.Name.NARRATOR
	if line.has("speaker"):
		@warning_ignore("int_as_enum_without_cast")
		speaker_enum = Character.get_enum_from_string(line["speaker"])
	# 2. Determinar el SPRITE que se muestra en pantalla.
	var character_to_show_str = line.get("show_character", line.get("speaker", "NARRATOR"))
	var character_to_show_enum = Character.get_enum_from_string(character_to_show_str)
	# 3. Determinar la EXPRESIÓN a usar.
	var expression = line.get("expression", "")
	# 4. Determinar si el sprite está hablando o inactivo.
	#    - Si "show_character" existe, el personaje en pantalla NO habla -> "idle".
	#    - Si no existe, el personaje en pantalla SÍ habla -> "talking".
	var is_talking = not line.has("show_character")
	# 5. Obtener detalles del sprite y aplicar la lógica de visibilidad.
	var character_details = Character.CHARACTER_DETAILS.get(character_to_show_enum)
	var has_sprite_to_show = character_details and character_details.get("sprite_frames") != null

	if not has_sprite_to_show:
		main_scene.character_sprite.hide_sprite()
	else:
		# Pasamos la nueva variable `is_talking` a la función change_character.
		main_scene.character_sprite.change_character(character_to_show_enum, is_talking, expression)
		main_scene.character_sprite.show_sprite()
	
	# 6. Mostrar el texto en la UI con el nombre del hablante.
	main_scene.dialog_ui.change_line(speaker_enum, line["text"], expression)
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
		else:
			main_scene.time_label.hide()
	return ""
