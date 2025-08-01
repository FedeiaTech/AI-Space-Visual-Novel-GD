# inventory_ui
# Capa de vista: mostrar los datos que le pide al InventoryManager. 
# Sabe de botones, etiquetas y cómo reaccionar a un clic dentro de sí misma 
# (como por ejemplo mostrar la descripción de un ítem)
extends CanvasLayer

signal inventory_closed # Señal para notificar a la escena principal que el inventario se cerró

@onready var background_panel: ColorRect = %BackgroundPanel
@onready var close_button: Button = %CloseButton
@onready var item_list_container: VBoxContainer = $ItemListContainer
@onready var item_name_label: Label = %ItemNameLabel
@onready var item_description_label: Label = %ItemDescriptionLabel
@onready var item_icon_display: TextureRect = $ItemDetailsPanel/HBoxContainer/ItemIconDisplay

# Precarga de la escena para un slot de ítem individual
const InventorySlotScene = preload("res://Scenes/UI/InventorySlot.tscn") # Asegúrate de que esta ruta sea correcta

func _ready():
	close_button.pressed.connect(_on_close_button_pressed)

	# Ocultar los detalles del ítem al inicio
	item_name_label.text = ""
	item_description_label.text = ""
	
	update_inventory_display() # Llama a la función para llenar la lista

func update_inventory_display():
	# Limpiar cualquier elemento existente en la lista
	for child in item_list_container.get_children():
		child.queue_free()

	# Obtener el inventario del personaje actual
	var current_inventory = InventoryManager.get_current_player_inventory()

	if current_inventory.is_empty():
		var no_items_label = Label.new()
		no_items_label.text = "Inventario Vacío"
		item_list_container.add_child(no_items_label)
		item_name_label.text = "Inventario Vacío"
		item_description_label.text = "Sin descripción."
	else:
		# Crear una etiqueta (Label) para cada ítem
		for item_details in current_inventory:
			var item_label = Label.new()
			var quantity = item_details.get("quantity", 1)
			item_label.text = item_details.get("name", item_details.get("id", "Item Desconocido"))
			if quantity > 1:
				item_label.text += " (x" + str(int(quantity)) + ")"

			item_label.set_mouse_filter(Control.MOUSE_FILTER_STOP)
			item_label.gui_input.connect(_on_item_label_input.bind(item_details))

			item_list_container.add_child(item_label)

# Manejar eventos de mouse en las etiquetas de ítems
func _on_item_label_input(event: InputEvent, item_details: Dictionary):
	if event is InputEventMouseMotion: # Si el mouse se mueve sobre la etiqueta
		item_name_label.text = item_details.get("name", "Nombre Desconocido")
		item_description_label.text = item_details.get("description", "Sin descripción.")
		# --- LÓGICA PARA MOSTRAR EL ICONO ---
		var icon_path = item_details.get("icon_path")
		if icon_path and ResourceLoader.exists(icon_path):
			item_icon_display.texture = load(icon_path)
			item_icon_display.show()
		else:
			item_icon_display.texture = null
			item_icon_display.hide()
		# --- FIN LÓGICA ICONO ---
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Puedes añadir lógica aquí si quieres que un clic haga algo (ej. usar ítem)
		
		#print("Clic en ítem: ", item_details.get("name"))
		# Por ahora, solo mostrará la descripción al hacer clic también
		item_name_label.text = item_details.get("name", "Nombre Desconocido")
		item_description_label.text = item_details.get("description", "Sin descripción.")

		# Asegurarse de que el icono también se muestre al hacer clic
		var icon_path = item_details.get("icon_path")
		if icon_path and ResourceLoader.exists(icon_path):
			item_icon_display.texture = load(icon_path)
			item_icon_display.show()
		else:
			item_icon_display.texture = null
			item_icon_display.hide()
		
		# Para consumir el evento del click para evitar que avance el juego estando dentro del inventario
			get_viewport().set_input_as_handled() 
			# También podrías usar event.accept() si el evento fue creado específicamente para este Control,
			# pero get_viewport().set_input_as_handled() es más general para cualquier evento que ya llegó al Viewport.

func _on_item_slot_selected(item_details: Dictionary):
	# Actualizar las etiquetas con la información del ítem seleccionado
	item_name_label.text = item_details.get("name", "Nombre Desconocido")
	item_description_label.text = item_details.get("description", "Sin descripción.")

func _on_close_button_pressed():
	print("click cerrar inventario")
	# Emitir la señal para que la escena principal sepa que debe cerrar el inventario
	inventory_closed.emit()
	# Eliminar esta instancia del inventario del árbol de la escena
	queue_free()
