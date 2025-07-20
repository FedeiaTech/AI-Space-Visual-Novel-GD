# InventoryManager.gd (Autoload / Singleton)
extends Node

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
	# Asegúrate de que los ítems de prueba ahora sean diccionarios completos
	add_item(Character.Name.ASTRO, {
		"id": "llave_antigua",
		"name": "Llave Antigua",
		"description": "Una llave oxidada que parece abrir algo muy viejo.",
		"quantity": 3,
		"icon_path": "res://Assets/Inventory_icons/old_key.png"
	})
	add_item(Character.Name.ASTRO, {
		"id": "pocion_roja",
		"name": "Poción Roja",
		"description": "Un líquido burbujeante de color carmesí. Podría curar.",
		"icon_path": "res://Assets/Inventory_icons/red_potion.png"
	})
	add_item(Character.Name.ASTRO, {
		"id": "mapa_rasgado",
		"name": "Mapa Rasgado",
		"description": "Un fragmento de mapa que no lleva a ninguna parte... por ahora.",
		"icon_path": "res://Assets/Inventory_icons/scroll_map.png"
	})
	add_item(Character.Name.ASTRO, {
		"id": "moneda_oro",
		"name": "Moneda de Oro",
		"description": "Una brillante moneda de oro. Quizás tenga valor.",
		"icon_path": "res://Assets/Inventory_icons/coin.png"
	})
	# --- Fin de ítems de prueba ---

# `item_details` ahora es un diccionario con "id", "name", "description", etc.
func add_item(character_name: Character.Name, item_details: Dictionary):
	if inventories.has(character_name):
		# Crea una copia mutable del diccionario para añadir la propiedad 'is_new'
		var item_to_add = item_details.duplicate()

		# Asignar una cantidad inicial si no existe (útil para apilables)
		if not item_to_add.has("quantity"):
			item_to_add["quantity"] = 1

		# Por ahora, simplemente añade el diccionario completo del ítem a la lista.
		# Más adelante, si necesitas, podemos añadir lógica para ítems apilables, límites de inventario, etc.
		inventories[character_name].append(item_details)
		print("Item '", item_details.get("name", item_details.get("id", "Item Desconocido")), "' añadido al inventario de ", Character.CHARACTER_DETAILS[character_name]["name"])
		# Llamar a la función de notificación en la escena principal
		# Asegúrate de que tu nodo principal tenga un nombre reconocible si no es el root directo,
		# o que la variable 'main_scene_instance' se obtenga correctamente
		#GameEvents.item_acquired_notification_requested.emit(item_to_add.get("name", "Item Desconocido"))
		GameEvents.item_acquired_notification_requested.emit(item_to_add.get("name", "Item Desconocido"))
	else:
		printerr("Error: El personaje ", Character.CHARACTER_DETAILS[character_name]["name"], " no tiene un inventario inicializado en InventoryManager.")

# Retorna true si el ítem fue removido, false si no se encontró
# Ahora busca por el "id" dentro de los diccionarios de ítems
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
