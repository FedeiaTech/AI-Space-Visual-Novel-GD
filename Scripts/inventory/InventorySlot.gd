extends Control

signal item_selected(item_details: Dictionary) # Señal para cuando se hace clic en este slot

@onready var background: Panel = %Background # Asegúrate que tu nodo de fondo sea un Panel
@onready var item_icon: TextureRect = %ItemIcon
@onready var quantity_label: Label = %QuantityLabel

var item_details: Dictionary = {} # Almacena los detalles del ítem en este slot

func _ready():
	# Conectar la señal `gui_input` para detectar clics en el slot
	gui_input.connect(_on_gui_input)

	# Ocultar la cantidad si no hay un ítem o si la cantidad no es relevante
	quantity_label.hide()

func set_item_details(details: Dictionary):
	item_details = details
	# Actualizar la visualización del slot con los detalles del ítem
	update_display()

func get_item_details() -> Dictionary:
	return item_details

func update_display():
	if item_details.is_empty():
		item_icon.texture = null # No hay ícono
		quantity_label.hide()
		# Puedes mostrar un "slot vacío" si quieres
	else:
		# Puedes cargar el ícono del ítem aquí.
		# Asumiendo que item_details podría tener una clave "icon_path" o similar.
		# Por ahora, puedes usar un ícono de prueba o dejarlo sin texturar.
		# Ejemplo: item_icon.texture = load(item_details.get("icon_path", "res://path/to/default_icon.png"))

		# Para la prueba, simplemente mostraremos un icono de marcador de posición si tienes uno.
		# Si no tienes un Path o iconos específicos, puedes comentarlo.
		# Puedes cargar un ícono de Godot por defecto si quieres probar:
		# item_icon.texture = load("res://icon.svg") 

		# Si tienes un campo 'icon_path' en tu JSON, úsalo:
		if item_details.has("icon_path") and not item_details["icon_path"].is_empty():
			item_icon.texture = load(item_details["icon_path"])
		else:
			# Opcional: poner un ícono por defecto si no hay path
			item_icon.texture = null # O un ícono de marcador de posición

		# Si el ítem tiene una cantidad (ej. si es apilable), mostrarla
		var quantity = item_details.get("quantity", 1) # Asume 1 si no hay cantidad
		if quantity > 1:
			quantity_label.text = str(quantity)
			quantity_label.show()
		else:
			quantity_label.hide()

func _on_gui_input(event: InputEvent):
	# Detectar el clic del mouse izquierdo en el slot
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not item_details.is_empty(): # Asegurarse de que el slot no esté vacío
			item_selected.emit(item_details) # Emitir la señal con los detalles del ítem
		get_viewport().set_input_as_handled() # Prevenir que el clic se propague
