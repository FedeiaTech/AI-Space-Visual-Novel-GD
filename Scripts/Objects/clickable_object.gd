# clickable_object.gd
extends TextureButton

@export var object_id: String = ""

#leerá esta linea y ejecutará la acción correspondiente.
## {"action": {"type": "load_scene", "scene_file": "decompression_chamber", "anchor": "first_choice"}}
## {"goto": "first_choice"}
@export_multiline var action_command: String = ""

#verificará si la bandera de misión con el ID que ingresaste 
# El diccioario "quest_flags" en GameMAnager.gd
# ("mision_anomalia", por ejemplo) está activada (true) o desactivada 
# (false). Si la condición no se cumple, el objeto no hara nada.
@export var required_flag: String = ""

#verificará si "inventories" en InventoryManager contiene el ítem que ingresaste.
# Si no es así, el clic no tendrá efecto.
@export var required_item: String = ""

@export_subgroup("Transiciones")
@export var has_transition: bool = true
@export var transition_type: String #"fade" o "slide"

# Señal para comunicar al DialogueManager que se ha hecho clic en el objeto
signal object_clicked(action_command: Dictionary)

var normal_brightness = 1.0
var hover_brightness = 1.5 # Puedes ajustar este valor para más o menos brillo
var pressed_brightness = 2.0 # Valor para el brillo cuando se presiona
var tween # Para una transición suave

func _ready():
	if material:
		material = material.duplicate()
	# Conecta la señal `pressed` del botón a este script
	pressed.connect(on_object_clicked)
	
	# Conecta las señales del mouse para los efectos de brillo
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_mouse_pressed)
	button_up.connect(_on_mouse_button_up)
	
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
	
	parsed_action_command["has_transition"] = has_transition
	if not transition_type.is_empty():
		parsed_action_command["transition_type"] = transition_type
	
	# Emite la señal con los datos relevantes
	object_clicked.emit(parsed_action_command)

func _on_mouse_entered():
	# Si hay un tween anterior, lo cancelamos para evitar conflictos.
	if tween and tween.is_valid():
		tween.kill()
	
	# Creamos una animación suave hacia el brillo de hover.
	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(material, "shader_parameter/brightness_factor", hover_brightness, 0.2)

func _on_mouse_exited():
	# Si el mouse sale, cancelamos cualquier animación en curso.
	if tween and tween.is_valid():
		tween.kill()

	# Creamos una animación suave de vuelta al brillo normal.
	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(material, "shader_parameter/brightness_factor", normal_brightness, 0.2)

func _on_mouse_pressed():
	# Cancelamos cualquier animación anterior para una respuesta inmediata.
	if tween and tween.is_valid():
		tween.kill()
	# En lugar de un tween, aplicamos el brillo máximo al instante.
	# Esto asegura que el efecto de "clic" sea siempre visible.
	material.set_shader_parameter("brightness_factor", pressed_brightness)

func _on_mouse_button_up():
	# Usamos una sola función para decidir a qué estado volver (hover o normal).
	# Esto es más limpio y evita repetir código.
	if is_hovered():
		_on_mouse_entered()
	else:
		_on_mouse_exited()
