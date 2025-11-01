# StoryLibrary.gd
extends Node

# Este diccionario contendrá los datos de todos los archivos JSON ya parseados.
var dialogues: Dictionary = {}

# Esta función se ejecuta una sola vez cuando el juego arranca.
func _ready() -> void:
	print("StoryLibrary: Cargando todos los archivos de diálogo...")
	var story_path = "res://Resources/Story/"
	var dir = DirAccess.open(story_path)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			# Nos aseguramos de que sea un archivo .json y no una carpeta.
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				# Leemos y parseamos el archivo
				var file = FileAccess.open(story_path + file_name, FileAccess.READ)
				if file:
					var content = file.get_as_text()
					var json_data = JSON.parse_string(content)
					if json_data != null:
						# La clave será el nombre del archivo SIN la extensión .json
						var key = file_name.get_basename()
						dialogues[key] = json_data
						print("  - Diálogo '", key, "' cargado.")
					else:
						printerr("StoryLibrary Error: El archivo JSON '", file_name, "' es inválido.")

			file_name = dir.get_next()
	else:
		printerr("StoryLibrary Error: No se pudo abrir el directorio: ", story_path)

# Función de ayuda para obtener un diálogo de forma segura
func get_dialogue(dialogue_name: String) -> Array:
	return dialogues.get(dialogue_name, null)
