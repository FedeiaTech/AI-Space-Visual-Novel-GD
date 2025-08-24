# SceneLibrary.gd
extends Node

# Este diccionario contendrá las referencias a todas tus escenas de locación.
const SCENES = {
	"outside_starship": preload("res://Scenes/Locations/outside_starship.tscn"),
	"decompression_chamber": preload("res://Scenes/Locations/decompression_chamber.tscn"),
	# Añade aquí TODAS tus escenas de locación
	# "nombre_en_json": preload("res://ruta/a/la/escena.tscn")
}

# Función de ayuda para obtener una escena de forma segura
static func get_scene(scene_name: String) -> PackedScene:
	return SCENES.get(scene_name, null)
