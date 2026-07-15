# StoryLibrary.gd
extends Node

var dialogues: Dictionary = {}

func _ready() -> void:
	print("StoryLibrary: Cargando todos los archivos de diálogo...")
	var story_path = "res://Resources/Story/"
	var dir = DirAccess.open(story_path)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				var file = FileAccess.open(story_path + file_name, FileAccess.READ)
				if file:
					var content = file.get_as_text()
					file.close()
					var json_data = JSON.parse_string(content)
					if json_data != null:
						var key = file_name.get_basename()
						dialogues[key] = json_data
						print("  - Diálogo '", key, "' cargado.")
					else:
						printerr("StoryLibrary Error: '", file_name, "' tiene JSON inválido.")
				else:
					printerr("StoryLibrary Error: No se pudo abrir '", file_name, "'.")
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		printerr("StoryLibrary Error: No se pudo abrir el directorio: ", story_path)

func get_dialogue(dialogue_name: String) -> Array:
	return dialogues.get(dialogue_name, null)
