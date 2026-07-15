# InputManager.gd
# Este script es "tonto". No sabe NADA sobre el estado del juego.
# Su único trabajo es detectar las acciones de input y emitir una señal.
extends Node

# Señales que "anuncian" que una tecla fue presionada.
signal inventory_toggled
signal journal_toggled
signal next_line_pressed
signal pause_pressed # Para la tecla 'Escape'
signal quest_log_toggled

# Precargamos la escena del efecto visual
const ClickRippleScene = preload("res://Scenes/UI/ClickRipple.tscn")

# Referencia al CanvasLayer donde dibujaremos los efectos (se asigna en _ready)
var effects_layer: CanvasLayer

func _ready():
	# Creamos un CanvasLayer dedicado para que los efectos se vean POR ENCIMA de todo
	effects_layer = CanvasLayer.new()
	effects_layer.layer = 100 # Un número alto para que esté arriba de todo
	effects_layer.name = "ClickEffectsLayer"
	add_child(effects_layer)

func _input(event: InputEvent) -> void:
	# 1. Detectar CLIC IZQUIERDO
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_spawn_ripple(event.position)

	if event.is_action_pressed("toggle_inventory"):
		inventory_toggled.emit()
		# Marcamos el evento como manejado para que no siga
		# propagándose (ej. a la UI de diálogo).
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("toggle_journal"):
		journal_toggled.emit()
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("next_line"):
		next_line_pressed.emit()
		get_viewport().set_input_as_handled()

	# "ui_cancel" es la acción por defecto de la tecla 'Escape'
	if event.is_action_pressed("ui_cancel"):
		pause_pressed.emit()
		get_viewport().set_input_as_handled()
	
	if event.is_action_pressed("toggle_quest_log"):
		quest_log_toggled.emit()
		get_viewport().set_input_as_handled()

func _spawn_ripple(pos: Vector2):
	var ripple = ClickRippleScene.instantiate()
	
	# 1. Primero lo añadimos a la escena para que exista en el árbol
	effects_layer.add_child(ripple)
	
	# 2. Definimos el tamaño FINAL que queremos que tenga la onda
	var ripple_size = Vector2(100, 100) 
	
	# 3. Forzamos ese tamaño en el objeto
	ripple.size = ripple_size
	
	# 4. Calculamos la posición central
	# (Posición del Mouse) - (Mitad del tamaño de la onda)
	ripple.global_position = pos - (ripple_size / 2.0)
