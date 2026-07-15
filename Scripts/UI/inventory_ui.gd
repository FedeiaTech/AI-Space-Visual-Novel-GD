# inventory_ui.gd
extends CanvasLayer

signal inventory_closed

@onready var background_panel: ColorRect = %BackgroundPanel
@onready var close_button: Button = %CloseButton
@onready var item_list_container: VBoxContainer = %ItemListContainer
@onready var item_name_label: Label = %ItemNameLabel
@onready var item_description_label: Label = %ItemDescriptionLabel
@onready var item_icon_display: TextureRect = %ItemIconDisplay

const InventorySlotScene = preload("res://Scenes/UI/InventorySlot.tscn")

func _ready():
	close_button.pressed.connect(_on_close_button_pressed)
	item_name_label.text = ""
	item_description_label.text = ""
	update_inventory_display()

func update_inventory_display():
	for child in item_list_container.get_children():
		child.queue_free()

	var current_inventory = InventoryManager.get_current_player_inventory()

	if current_inventory.is_empty():
		var no_items_label = Label.new()
		no_items_label.text = "Inventario Vacío"
		no_items_label.modulate = Color.GRAY # Color gris para indicar vacío
		item_list_container.add_child(no_items_label)
		item_name_label.text = "Inventario Vacío"
		item_description_label.text = "Sin descripción."
	else:
		for item_details in current_inventory:
			var item_label = Label.new()
			var quantity = item_details.get("quantity", 1)
			item_label.text = item_details.get("name", item_details.get("id", "Item Desconocido"))
			if quantity > 1:
				item_label.text += " (x" + str(int(quantity)) + ")"

			# Configuración básica del label
			item_label.mouse_filter = Control.MOUSE_FILTER_STOP
			item_label.set_h_size_flags(Control.SIZE_EXPAND_FILL) # Ocupar ancho disponible
			
			# 1. Detectar Clic (Mantenemos gui_input solo para el clic)
			item_label.gui_input.connect(_on_item_label_clicked.bind(item_details))
			
			# 2. Detectar Entrada del Mouse (Hover) -> Activa Brillo y muestra Info
			item_label.mouse_entered.connect(_on_item_mouse_entered.bind(item_label, item_details))
			
			# 3. Detectar Salida del Mouse -> Desactiva Brillo
			item_label.mouse_exited.connect(_on_item_mouse_exited.bind(item_label))

			item_list_container.add_child(item_label)

func _on_item_mouse_entered(label: Label, item_details: Dictionary):
	# 1. Efecto Visual (Resplandor)
	var tween = create_tween()
	# Cambiar color a Amarillo Brillante suavemente
	tween.tween_property(label, "modulate", Color(1.2, 1.2, 0.5, 1.0), 0.1)
	
	# Añadir "Sombra" centrada que actúa como Glow (Brillo)
	label.add_theme_color_override("font_shadow_color", Color(1, 0.9, 0.2, 0.6)) # Amarillo semi-transparente
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	label.add_theme_constant_override("shadow_outline_size", 4) # Tamaño del brillo
	
	# 2. Mostrar Información (Movido aquí para optimizar)
	_update_item_details_display(item_details)

func _on_item_mouse_exited(label: Label):
	# 1. Quitar Efecto Visual
	var tween = create_tween()
	# Volver a Blanco normal
	tween.tween_property(label, "modulate", Color(1, 1, 1, 1), 0.1)
	
	# Quitar overrides de sombra
	label.remove_theme_color_override("font_shadow_color")
	label.remove_theme_constant_override("shadow_outline_size")
	
	# Opcional: Limpiar detalles al salir (o dejar el último visto)
	# item_name_label.text = "" 

# Función auxiliar para actualizar el panel de la derecha
func _update_item_details_display(item_details: Dictionary):
	item_name_label.text = item_details.get("name", "Nombre Desconocido")
	item_description_label.text = item_details.get("description", "Sin descripción.")
	
	var icon_path = item_details.get("icon_path")
	if icon_path and ResourceLoader.exists(icon_path):
		item_icon_display.texture = load(icon_path)
		item_icon_display.show()
	else:
		item_icon_display.texture = null
		item_icon_display.hide()

# Maneja solo el clic (separado del movimiento para limpieza)
func _on_item_label_clicked(event: InputEvent, item_details: Dictionary):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Reproducir sonido de clic si tienes uno
		# Forzar actualización de detalles (por si acaso)
		_update_item_details_display(item_details)
		get_viewport().set_input_as_handled()

func _on_close_button_pressed():
	print("click cerrar inventario")
	inventory_closed.emit()
	queue_free()
