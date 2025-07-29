# command_processor.gd
# Este nodo se encarga de ejecutar comandos embebidos en líneas de diálogo.
# Interpreta líneas específicas del JSON de diálogos para alterar el estado del juego.
extends Node

# Referencia a la escena principal que este procesador controlará
var main_scene: Node2D

# Diccionario de Manejadores de Comandos
var command_handlers: Dictionary = {
	"action": _handle_action,
	"item_given": _handle_item_given,
	"music": _handle_music,
	"location": _handle_location,
	"goto": _handle_goto,
	"anchor": _handle_anchor,
	"show_character": _handle_show_character,
	"choices": _handle_choices,
	"text": _handle_text
}

func _ready() -> void:
	# Al iniciar, obtiene una referencia al nodo padre (MainScene)
	main_scene = get_parent()

func execute(line: Dictionary) -> String:
	# Ejecuta una línea de diálogo con comandos.
	# Busca cuál de los comandos está presente y llama al manejador correspondiente.
	# Si un comando devuelve "stop_processing", se detiene la ejecución del resto.
	for command_name in command_handlers.keys():
		if line.has(command_name):
			var result = command_handlers[command_name].call(line)
			if result == "stop_processing":
				return "stop_processing"
	return ""


# ----------------------------------------------
""" Manejadores de comandos individuales """
# ----------------------------------------------

func _handle_action(line: Dictionary) -> String:
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
			main_scene.character_sprite.hide()
			main_scene.is_transitioning = true
			SceneManager.transition_out(main_scene.transition_effect)
			GameManager.request_scene_load(target_file, target_anchor)
			return "stop_processing" # Detener el procesamiento de esta línea
		
		"goto_internal":
			# Redirige internamente a un ancla del mismo archivo
			return _handle_goto({"goto": action_data.get("anchor", "")})
			
		_:
			printerr("Acción no reconocida: ", action_type)
	return ""

func _handle_item_given(line: Dictionary) -> String:
	# Maneja el evento de entrega de ítems al jugador
	main_scene._process_item_given(line["item_given"])
	return "" # Continuar procesando otros comandos en la misma línea

func _handle_music(line: Dictionary) -> String:
	# Cambia la música de fondo según el nombre especificado
	var music_file = load("res://Assets/Sounds/BGM/" + line["music"] + ".mp3")
	if main_scene.background_music.stream != music_file:
		main_scene.background_music.stop()
		main_scene.background_music.stream = music_file
		main_scene.background_music.play(0.0)
	return ""

func _handle_location(line: Dictionary) -> String:
	# Cambia el fondo de la escena a una nueva ubicación
	main_scene.background.texture = load("res://Assets/Scenes_images/" + line["location"] + ".png")
	
	# Si no hay texto ni elecciones ni acciones, se avanza automáticamente
	if not (line.has("text") or line.has("choices") or line.has("action")):
		# Avanza y procesa la siguiente línea de forma diferida
		main_scene.dialogue_manager.advance_index()
		main_scene.dialogue_manager.process_current_line.call_deferred()
		return "stop_processing"
	return ""

func _handle_goto(line: Dictionary) -> String:
	# Salta a una posición específica dentro del archivo de diálogo
	main_scene.dialogue_manager.jump_to_anchor.call_deferred(line["goto"])
	return "stop_processing"

func _handle_anchor(_line: Dictionary) -> String:
	# Marca de posición en el archivo de diálogo. No hace nada visible.
	# Avanza y procesa la siguiente línea de forma diferida
	main_scene.dialogue_manager.advance_index()
	main_scene.dialogue_manager.process_current_line.call_deferred()
	return "stop_processing"

func _handle_show_character(line: Dictionary) -> String:
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

func _handle_choices(line: Dictionary) -> String:
	# Despliega opciones de diálogo para que el jugador elija
	main_scene.dialog_ui.display_choices(line["choices"])
	return ""

func _handle_text(line: Dictionary) -> String:
	# 1. Determinar el NOMBRE del hablante (para la UI).
	var speaker_enum = Character.Name.NARRATOR
	if line.has("speaker"):
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
	main_scene.dialog_ui.change_line(speaker_enum, line["text"])
	return ""
