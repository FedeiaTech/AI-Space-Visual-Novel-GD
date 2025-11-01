# CameraShaker.gd
# Gestiona el efecto de temblor de pantalla.
extends Node

var main_scene: Node2D

# Variables de estado (movidas desde MainScene)
var original_positions: Dictionary = {}
var _shake_duration: float = 0.0
var _shake_magnitude: float = 0.0
var nodes_to_shake: Array = []

func _ready():
	# El bucle de proceso está apagado por defecto
	set_process(false)

# Recibe la referencia a MainScene
func set_main_scene_reference(scene_node: Node2D):
	self.main_scene = scene_node

# Bucle principal, usado exclusivamente para el efecto de 'shake'.
func _process(delta: float):
	if _shake_duration > 0:
		_shake_duration -= delta

		if _shake_duration <= 0:
			# Resetea la posición de los nodos
			for node in nodes_to_shake:
				if is_instance_valid(node) and original_positions.has(node):
					node.position = original_positions[node]
			nodes_to_shake.clear()
			set_process(false) # Apaga el bucle
		else:
			# Aplica el temblor
			var offset = Vector2(randf_range(-_shake_magnitude, _shake_magnitude), randf_range(-_shake_magnitude, _shake_magnitude))
			for node in nodes_to_shake:
				if is_instance_valid(node) and original_positions.has(node):
					node.position = original_positions[node] + offset

# Inicia el efecto de 'shake' (llamado por CommandProcessor).
func start_shake(duration: float, magnitude: float, nodes: Array):
	# Guarda las posiciones originales la primera vez que vemos un nodo
	for node in nodes:
		if is_instance_valid(node) and not original_positions.has(node):
			print("CameraShaker: Registrando nueva posición original para: ", node.name)
			original_positions[node] = node.position

	_shake_duration = duration
	_shake_magnitude = magnitude
	nodes_to_shake = nodes
	set_process(true) # Activa el bucle
