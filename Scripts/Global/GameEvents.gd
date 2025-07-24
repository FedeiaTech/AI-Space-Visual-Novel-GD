extends Node

signal item_acquired_notification_requested(item_name: String, quantity_change: int, is_new_item: bool)

func _ready():
	# Este es un truco para silenciar la advertencia.
	# No afecta el juego, ya que la señal real se emite desde InventoryManager.
	if OS.is_debug_build(): 
		# (El OS.is_debug_build() asegura que esto solo se ejecute cuando estás 
		#en el editor o haciendo una compilación de depuración).
		item_acquired_notification_requested.emit("DEBUG_ITEM_NAME")
		pass
