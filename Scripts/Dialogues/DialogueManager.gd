# DialogueManager.gd
extends Node

# Señales para comunicar eventos importantes al resto del juego.
signal line_processed(line: Dictionary)
signal dialogue_finished

var dialog_file: String
var dialog_index: int = 0
var dialog_lines: Array = []
var pending_anchor: String = ""

# Carga un nuevo archivo de diálogo.
func load_dialog_file(file_path: String, anchor: String = ""):
	dialog_file = file_path
	if not FileAccess.file_exists(dialog_file):
		printerr("DialogueManager Error: El archivo no existe ", dialog_file)
		dialog_lines = []
		return

	var file = FileAccess.open(dialog_file, FileAccess.READ)
	var content = file.get_as_text()
	dialog_lines = JSON.parse_string(content)

	if dialog_lines == null or dialog_lines.is_empty():
		printerr("DialogueManager Error: El archivo JSON está vacío o es inválido: ", dialog_file)
		dialog_lines = []
		return

	dialog_index = 0
	if not anchor.is_empty():
		var anchor_pos = get_anchor_position(anchor)
		if anchor_pos != null:
			dialog_index = anchor_pos

# Inicia o avanza a la siguiente línea del diálogo.
#func advance_line():
	#if dialog_lines.is_empty():
		#return
#
	#if dialog_index >= dialog_lines.size():
		#dialogue_finished.emit()
		#print("Fin del diálogo en el archivo actual.")
		#return
#
	#var current_line = dialog_lines[dialog_index]
	#line_processed.emit(current_line)
	
func process_current_line():
	if dialog_lines.is_empty():
		return

	if dialog_index >= dialog_lines.size():
		dialogue_finished.emit()
		return

	var current_line = dialog_lines[dialog_index]
	line_processed.emit(current_line)

func advance_index():
	if dialog_index < dialog_lines.size():
		dialog_index += 1

# Busca la posición de un ancla en el diálogo actual.
func get_anchor_position(anchor: String) -> int:
	for i in range(dialog_lines.size()):
		if dialog_lines[i].has("anchor") and dialog_lines[i]["anchor"] == anchor:
			return i
	printerr("Error: No se encontró el ancla '", anchor, "'")
	return -1

# Manejar los saltos "goto"
func jump_to_anchor(anchor: String):
	var new_index = get_anchor_position(anchor)
	if new_index != null:
		dialog_index = new_index
		# Después de saltar, procesamos inmediatamente la nueva línea
		process_current_line()
