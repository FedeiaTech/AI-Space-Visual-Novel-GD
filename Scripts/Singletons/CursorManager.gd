# CursorManager.gd
# Se encarga de gestionar y cambiar el aspecto del cursor globalmente.
extends Node

# Lista de colores disponibles basada en tus carpetas
const AVAILABLE_COLORS = ["blue", "green", "purple", "red", "yellow"]

# Ruta base
const BASE_PATH = "res://Assets/UI_assets/Cursors/delta-neon-%s/"

# Guardamos el color actual
var current_color: String = "blue"

func _ready():
	# Iniciar con el color por defecto (azul)
	set_cursor_theme("blue")

func set_cursor_theme(color_name: String):
	if not color_name in AVAILABLE_COLORS:
		printerr("CursorManager: Color no válido -> ", color_name)
		return
	
	current_color = color_name
	var path = BASE_PATH % color_name
	
	# --- CARGA DE TEXTURAS ---
	# Es importante usar 'load()' para traer el recurso .cur o .png
	
	# 1. Cursor Normal (Flecha)
	var arrow_tex = load(path + "Normal Select.png")
	# 2. Cursor de Enlace (Manito - para botones)
	var link_tex = load(path + "Link Select.png")
	# 3. Cursor de Texto (I-Beam - para inputs)
	var text_tex = load(path + "Text Select.png")
	# 4. Cursor de Espera/Ocupado
	var busy_tex = load(path + "Busy Waiting.png") 
	# (Nota: Los .ani a veces dan problemas en Godot, usa el .cur estático si el animado falla)

	# --- APLICACIÓN AL SISTEMA ---
	# Input.set_custom_mouse_cursor(imagen, forma_id, hotspot)
	
	# Forma: Flecha Normal
	Input.set_custom_mouse_cursor(arrow_tex, Input.CURSOR_ARROW, Vector2(7,6))
	
	# Forma: Manito (Botones)
	Input.set_custom_mouse_cursor(link_tex, Input.CURSOR_POINTING_HAND, Vector2(0,0))
	
	# Forma: Texto
	Input.set_custom_mouse_cursor(text_tex, Input.CURSOR_IBEAM, Vector2(16, 16)) # Ajusta el hotspot si es necesario
	
	# Forma: Espera
	Input.set_custom_mouse_cursor(busy_tex, Input.CURSOR_WAIT, Vector2(0,0))
	
	print("Cursor cambiado a tema: ", color_name)

# Función auxiliar para obtener la textura de la flecha de un color específico
# (Útil para mostrar el icono en el menú de opciones)
func get_preview_icon(color_name: String) -> Texture2D:
	var path = BASE_PATH % color_name
	return load(path + "Normal Select.png")
