# clickable_object.gd
extends TextureButton

#el juego cargará y comenzará a reproducir el archivo de diálogo
# que hayas asignado.
## res://Resources/Story/intro.json
#            @export_file("*.json") var dialog_file: String = ""
#leerá esta linea y ejecutará la acción correspondiente.
## {"action": {"type": "load_scene", "scene_file": "decompression_chamber", "anchor": "first_choice"}}
## {"goto": "first_choice"}
# Por ejemplo: {"type": "set_flag", "id": "computer_used", "value": true}.
@export_multiline var action_command: String = ""
#verificará si la bandera de misión con el ID que ingresaste 
# ("mision_anomalia", por ejemplo) está activada (true) o desactivada 
# (false). Si la condición no se cumple, el objeto no se activará.
@export var required_flag: String = ""
#verificará si el InventoryManager contiene el ítem que ingresaste.
# Si no es así, el clic no tendrá efecto.
@export var required_item: String = ""

# Señal para comunicar al DialogueManager que se ha hecho clic en el objeto
signal object_clicked(action_command: Dictionary)

func _ready():
	# Conecta la señal `pressed` del botón a este script
	pressed.connect(on_object_clicked)

func on_object_clicked():
	print("Paso 1: ¡El botón ha sido clickeado!")
	# Primero, verifica si las condiciones se cumplen
	if not required_flag.is_empty() and not GameManager.get_quest_flag(required_flag):
		# Aquí podrías mostrar un mensaje de error o un diálogo de "no puedes hacer esto"
		return
	if not required_item.is_empty() and not InventoryManager.has_item(InventoryManager.current_player_character, required_item):
		return
	
	# Analiza la cadena de texto como un diccionario JSON
	var parsed_action_command = {}
	if not action_command.is_empty():
		var json_result = JSON.parse_string(action_command)
		if json_result is Dictionary:
			parsed_action_command = json_result
		else:
			printerr("Error de parseo JSON en action_command: ", action_command)
		if json_result == null:
			print("¡ERROR! El parseo de JSON falló. El string es inválido.")
	# Emite la señal con los datos relevantes
	object_clicked.emit(parsed_action_command)
