# InventoryManager.gd (Autoload / Singleton)
# Capa de Datos: maneja los datos del inventario (qué ítems tienes, cuántos, etc.)
extends Node

const ITEM_DATABASE = {
	"pocket_watch": {
		"name": "Reloj Antiguo",
		"description": "Un reloj que me ayuda a concentrarme... me lo dió mi abuelo y significa mucho para mí.",
		"icon_path": "res://Assets/Inventory_icons/pocket_watch.png"
	},
	"mapa_rasgado": {
		"name": "Mapa Rasgado",
		"description": "Un fragmento de mapa que no lleva a ninguna parte... por ahora.",
		"icon_path": "res://Assets/Inventory_icons/scroll_map.png"
	},
	"moneda_oro": {
		"name": "Moneda de Oro",
		"description": "Una brillante moneda de oro. Quizás tenga valor o no, pero es un bonito recuerdo de mi abuelo.",
		"icon_path": "res://Assets/Inventory_icons/coin.png"
	},
	"safety_tether": {
		"name": "Cable de sujeción",
		"description": "Un cable retráctil de alta resistencia diseñado para mantener al astronauta conectado a la nave o estación durante actividades extravehiculares. Fabricado con fibras compuestas y recubrimiento metálico, soporta tensión extrema y evita la deriva en el vacío. Su sistema de anclaje rápido permite asegurarlo a múltiples puntos de la nave.",
		"icon_path": "res://Assets/Inventory_icons/rope.png"
	},
	# Añade aquí CUALQUIER otro ítem que exista en tu juego
}

# Diccionario para guardar inventarios.
# La clave será el enum Character.Name (ej. Character.Name.ASTRO)
# El valor será un Array de diccionarios de ítems (ej. [{"id": "Llave Antigua", "name": "...", "description": "..."}, {...}])
var inventories: Dictionary = {}

# El personaje cuyo inventario está actualmente activo para el jugador
var current_player_character: Character.Name = Character.Name.ASTRO

func _ready():
	# Inicializar un inventario vacío para cada personaje definido en Character.Name
	for character_name_enum in Character.Name.values():
		inventories[character_name_enum] = [] # Inicializa como una lista vacía de ítems

	# --- Ítems de prueba (puedes eliminarlos después) ---
	add_item(Character.Name.ASTRO, "pocket_watch", 1)
	add_item(Character.Name.ASTRO, "mapa_rasgado", 1)
	add_item(Character.Name.ASTRO, "moneda_oro", 1)
	# --- Fin de ítems de prueba ---

# `item_details` ahora es un diccionario con "id", "name", "description", etc.
func add_item(character_name: Character.Name, item_id_to_add: String, quantity_to_add: int = 1):
	# 1. Validar que el ítem existe en nuestra base de datos
	if not ITEM_DATABASE.has(item_id_to_add):
		printerr("Error: Intento de añadir ítem '", item_id_to_add, "' que no existe en ITEM_DATABASE.")
		return

	if not inventories.has(character_name):
		printerr("Error: El personaje no tiene inventario.")
		return

	var inventory = inventories[character_name]
	var item_data = ITEM_DATABASE[item_id_to_add] # Obtiene los detalles de la DB
	var final_item_name = item_data.get("name", item_id_to_add)
	var is_new_item = true

	# 2. Buscar si el jugador ya tiene el ítem
	# (Este bucle es el que se optimiza con el Diccionario de la Optimización #2)
	var item_found_in_inventory = false
	for existing_item in inventory:
		if existing_item.has("id") and existing_item["id"] == item_id_to_add:
			var current_quantity = existing_item.get("quantity", 0)
			existing_item["quantity"] = current_quantity + quantity_to_add
			item_found_in_inventory = true
			is_new_item = false
			print("Cantidad de ítem '", final_item_name, "' actualizada a ", existing_item["quantity"])
			break

	# 3. Si no lo tiene, crear una nueva entrada
	if not item_found_in_inventory:
		# Creamos la entrada del inventario duplicando los datos de la DB
		var new_item_entry = item_data.duplicate(true)
		new_item_entry["id"] = item_id_to_add # Aseguramos que la ID esté
		new_item_entry["quantity"] = quantity_to_add

		inventories[character_name].append(new_item_entry)
		print("Nuevo ítem '", final_item_name, "' añadido al inventario.")

	# 4. Emitir la señal de notificación
	GameEvents.item_acquired_notification_requested.emit(final_item_name, quantity_to_add, is_new_item)
	
func remove_item(character_name: Character.Name, item_id: String) -> bool:
	if inventories.has(character_name):
		var inv = inventories[character_name]
		for i in range(inv.size()):
			if inv[i].get("id") == item_id: # Buscamos por el 'id' dentro del diccionario de ítem
				inv.remove_at(i)
				print("Item con ID '", item_id, "' removido del inventario de ", Character.CHARACTER_DETAILS[character_name]["name"])
				return true
	return false

# Retorna true si el personaje tiene el ítem (por su ID), false si no
func has_item(character_name: Character.Name, item_id: String) -> bool:
	if inventories.has(character_name):
		for item_details in inventories[character_name]:
			if item_details.get("id") == item_id: # Buscamos por el 'id' dentro del diccionario de ítem
				return true
	return false

# Obtiene la lista completa de diccionarios de ítems para un personaje específico
func get_inventory(character_name: Character.Name) -> Array:
	return inventories.get(character_name, [])

# Obtiene la lista de diccionarios de ítems del personaje que es el "jugador" actual
func get_current_player_inventory() -> Array:
	return get_inventory(current_player_character)
