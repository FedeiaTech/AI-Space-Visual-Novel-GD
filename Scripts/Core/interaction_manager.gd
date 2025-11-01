# interaction_manager.gd
extends Control

# Un diccionario para acceder a los objetos por su ID.
var clickable_objects: Dictionary = {}

func _ready():
	# Inicia la búsqueda recursiva de objetos desde este nodo.
	_register_clickable_objects(self)
	print("InteractionManager: Diccionario de objetos construido -> ", clickable_objects)

# Nueva función recursiva para encontrar y registrar todos los objetos.
func _register_clickable_objects(node):
	# Itera sobre los hijos del nodo actual.
	for child in node.get_children():
		# Primero, verifica si el hijo es un ClickableObject.
		if "object_id" in child:
			if not child.object_id.is_empty():
				print("Registrando objeto: ", child.object_id)
				clickable_objects[child.object_id] = child
			
			if child.has_signal("object_clicked"):
				var main_scene = get_tree().current_scene
				child.object_clicked.connect(main_scene._on_object_clicked)

		# Después, si el hijo tiene sus propios hijos, llamamos a esta misma función
		# para que siga buscando en las capas más profundas.
		if child.get_child_count() > 0:
			_register_clickable_objects(child)

# Función para encontrar un objeto por su ID, usada por CommandProcessor.
func get_object_by_id(id: String) -> TextureButton:
	return clickable_objects.get(id, null)
