# SceneLibrary.gd
extends Node

# Este diccionario contendrá las referencias a todas tus escenas de locación.
const SCENES = {
	"outside_starship": preload("res://Scenes/Locations/outside_starship.tscn"),
	"decompression_chamber": preload("res://Scenes/Locations/decompression_chamber.tscn"),
	"command_center": preload("res://Scenes/Locations/command_center.tscn"),
	
	# Añade aquí TODAS tus escenas de locación
	# "nombre_en_json": preload("res://ruta/a/la/escena.tscn")
}

# Este diccionario contendrá las referencias a las texturas UI.
const UI_ICON = {
	"time_active_icon": preload("res://Assets/UI_assets/Icons/clock_mini.png"),
	"time_inactive_icon": preload("res://Assets/UI_assets/Icons/clock_mini_inactive.png"),
	
	# Añade aquí TODAS las imagenes de iconos ui
	# "nombre_en_json": preload("res://ruta/a/la/escena.tscn")
}

# Función de ayuda para obtener una escena de forma segura
func get_scene(scene_name: String) -> PackedScene:
	return SCENES.get(scene_name, null)

func get_ui_icon(icon_name: String) -> Texture2D:
	return UI_ICON.get(icon_name, null)
