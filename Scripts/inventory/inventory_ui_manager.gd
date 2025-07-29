# inventory_ui_manager.gd
# Capa de Controlador/Gestor (intermediario):
	# .Escucha la entrada del jugador ("abrir inventario").
	# .Decide cuándo crear (instantiate) y destruir (queue_free) la InventoryUI.
	# .Gestiona los efectos secundarios en el juego, como pausar/despausar y 
	#bloquear/desbloquear el input del diálogo.

extends Node
## Referencia a la escena de la UI del inventario para poder instanciarla.
const InventoryUIScene = preload("res://Scenes/UI/inventory_ui.tscn")

## Almacena la instancia de la UI del inventario cuando está abierta.
var current_inventory_ui: CanvasLayer = null

## Referencia a la escena principal para poder bloquear su input.
var main_scene: Node2D

func _ready():
	# Obtenemos la referencia al nodo padre (MainScene)
	main_scene = get_parent()

## Función pública para abrir o cerrar el inventario.
func toggle_inventory():
	if current_inventory_ui == null:
		_open()
	else:
		_close()

## Lógica privada para abrir el inventario.
func _open():
	if current_inventory_ui != null: return # Ya está abierto

	# Instanciar, conectar señal y añadir a la escena
	current_inventory_ui = InventoryUIScene.instantiate()
	current_inventory_ui.inventory_closed.connect(_on_inventory_closed_from_ui)
	# Se añade como hijo del manager para mantenerlo todo junto
	add_child(current_inventory_ui)

	# Gestionar el estado del juego
	get_tree().paused = true
	main_scene.is_dialog_input_blocked = true
	print("Inventario abierto, juego pausado.")

## Lógica privada para cerrar el inventario.
func _close():
	if current_inventory_ui == null: return # Ya está cerrado

	# queue_free() ya se encarga de desconectar las señales, pero hacerlo
	# manualmente es una buena práctica si la lógica fuera más compleja.
	current_inventory_ui.inventory_closed.disconnect(_on_inventory_closed_from_ui)
	#current_inventory_ui.inventory_closed.disconnect(_on_inventory_closed_signal_received)
	current_inventory_ui.queue_free() # Libera el nodo del inventario
	# La propia escena UI se libera con queue_free() al pulsar su botón de cerrar.
	# Aquí solo necesitamos resetear el estado del juego y la referencia.
	current_inventory_ui = null
	# Consumir cualquier input que haya ocurrido mientras el inventario estaba abierto
	get_viewport().set_input_as_handled() # Esto es crucial al despausar
	# Gestionar el estado del juego
	get_tree().paused = false
	main_scene.is_dialog_input_blocked = false
	print("Inventario cerrado, juego reanudado.")
	main_scene.dialog_ui.show() # Muestra de nuevo la interfaz de diálogo

## Se activa cuando la propia UI del inventario emite la señal de que debe cerrarse.
func _on_inventory_closed_from_ui():
	# La UI se elimina a sí misma con queue_free().
	# Nosotros solo necesitamos llamar a nuestra lógica de cierre para resetear el estado.
	_close()
