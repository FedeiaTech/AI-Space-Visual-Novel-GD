extends Node2D

@onready var background: TextureRect = %Background
@onready var background_music: AudioStreamPlayer = %BackgroundMusic
@onready var character_sprite = $CanvasLayer2/Control/CharacterSprite
@onready var dialog_ui: Control = $CanvasLayer2/DialogUI
@onready var next_sentence_sound: AudioStreamPlayer = %NextSentenceSound

var transition_effect: String = "fade"
var dialog_file: String = "res://Resources/Story/intro.json"
var dialog_index : int = 0
var dialog_lines : Array = []

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
	
func _input(event: InputEvent) -> void:
	var line = dialog_lines[dialog_index]
	var has_choices = line.has("choices")
	if event.is_action_pressed("next_line") and not has_choices:
		if dialog_ui.animate_text:
			dialog_ui.skip_text_animation()
		else:
			if dialog_index < len(dialog_lines) - 1:
				dialog_index += 1
				next_sentence_sound.play()
				process_current_line()


func process_current_line():
	if dialog_index >= dialog_lines.size() or dialog_index < 0:
		printerr("Error: dialog_index out of bounds", dialog_index)
		return
	#Extrae la linea actual
	var line = dialog_lines[dialog_index]
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

func _on_text_animation_done():
	character_sprite.play_idle_animation()

func _on_choice_selected(anchor: String):
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
