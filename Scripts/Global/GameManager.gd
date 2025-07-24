# GameManager.gd
extends Node

#Este nodo interferira para moverse de un escenario a otro de manera no lineal

# Señal para notificar a otras partes (como MainScene) que se debe cargar un nuevo archivo JSON de diálogo.
signal new_dialog_file_requested(file_path: String, anchor: String)

var current_dialog_file: String = "" # Para saber en qué archivo JSON estamos
var previous_dialog_file: String = "" # Para "volver"
var previous_dialog_index: int = 0 # Para "volver" al punto exacto

# Método para solicitar una carga de escena de dialogo especifica
func request_scene_load(scene_file_name: String, anchor_name: String = ""):
	var path = "res://Resources/Story/" + scene_file_name + ".json"
	
	if not FileAccess.file_exists(path):
		printerr("GameManager Error: El archivo de escena no existe: ", path)
		return
	
	# Aquí podrías guardar el estado actual si fuera necesario para volver con precisión
	# (e.g., current_dialog_file, dialog_index en MainScene)
	# Por ahora, MainScene lo guardará antes de pedir la carga.

	print("GameManager: Solicitando carga de escena: ", path, " ancla: ", anchor_name)
	# Emitir la señal que MainScene escuchará para cargar el nuevo JSON
	new_dialog_file_requested.emit(path, anchor_name)

# Puedes añadir más funciones aquí para gestionar el estado del juego, inventario, etc.
# Sin embargo, el inventario ya lo tienes en InventoryManager.
