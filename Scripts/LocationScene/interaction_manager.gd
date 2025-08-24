# interaction_manager.gd
extends Control

func _ready():
	# Conecta las señales de todos los objetos clickeables
	for child in get_children():
		if child.has_signal("object_clicked"):
			child.object_clicked.connect(get_parent()._on_object_clicked)
