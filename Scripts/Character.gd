# Clase Character: Representa a un personaje del juego.
# Contiene un enum de nombres válidos, una base de datos de propiedades de personajes
# y una función utilitaria para convertir nombres en strings a sus valores de enum.

class_name Character
extends Node

# Enum con los identificadores únicos de cada personaje.
# Se usa para evitar errores de tipeo y facilitar el control centralizado.
enum Name {
	ASTRO,
	ASTRO_EVA,
	IA,
	MILKA,
	NARRATOR,
	ORI,
	VIKTOR
}

#Enum con las posiciones de los personajes en pantalla.
enum Position {
	LEFT,
	CENTER,
	RIGHT,
	FAR_RIGHT
}

# Diccionario que define la posición en píxeles para cada valor del enum Position.
const POSITIONS = {
	Position.LEFT: Vector2(-400,0), # Posición de la izquierda
	Position.CENTER:  Vector2(-200,0), # Posición central
	Position.RIGHT:  Vector2(100,0), # Posición de la derecha
	Position.FAR_RIGHT:  Vector2(300,0) # Agrega esta línea con un valor apropiado.
}

# Diccionario constante que almacena los detalles de cada personaje.
# Usa el enum como clave y un diccionario
const CHARACTER_DETAILS : Dictionary = {
	Name.ASTRO: {
		"name" : "Astro",
		"gender": "male",
		"sprite_frames": preload("res://Resources/Sprites_saves/Astro_sprites.tres"),
		"color": Color("#ff0000"), # Rojo
		#"color": Color("#FFD700"), # Un amarillo dorado
		"expression_sounds": {
			"scare": preload("res://Assets/Sounds/Voices/male/man_scare.wav"),
			"doubt": preload("res://Assets/Sounds/Voices/male/man_what.wav")
		}
	},
	Name.ASTRO_EVA: {
		"name" : "Astro",
		"gender": "male",
		"sprite_frames": preload("res://Resources/Sprites_saves/Astro_eva_sprites.tres"),
		"color": Color("#e61919") # Rojo desaturado
	},
	Name.IA: {
		"name" : "Spark (IA)",
		"gender": "-",
		"sprite_frames": null,
		"color": Color("#ffffff") # blanco
	},
	Name.MILKA: {
		"name" : "Milka",
		"gender": "female",
		"sprite_frames": preload("res://Resources/Sprites_saves/Milka_sprites.tres"),
		"color": Color("#fcd1c6") # rosa claro
	},
	Name.ORI: {
		"name" : "Ori",
		"gender": "female",
		"sprite_frames": preload("res://Resources/Sprites_saves/Ori_sprites.tres"),
		"color": Color("#FFD700"), # Un amarillo dorado
	},
	Name.VIKTOR: {
		"name" : "Viktor",
		"gender": "male",
		"sprite_frames": preload("res://Resources/Sprites_saves/Viktor_sprites.tres"),
		"color": Color("#3b83bd")
	},
	Name.NARRATOR: {
		"name" : "",
		"gender": "-",
		"sprite_frames": null,
		"color": Color("#B5B5B5") # Un gris oscuro (DarkGray)
	},
}

## Devuelve el diccionario de detalles de un personaje a partir de su string.
static func get_details_from_string(string_value: String) -> Dictionary:
	var upper_string = string_value.to_upper()
	if Name.has(upper_string):
		var character_enum = Name[upper_string]
		return CHARACTER_DETAILS.get(character_enum, {})
	if string_value != "":
		push_error("Nombre de personaje inválido: " + string_value)
	return {}

# Función estática que convierte un string (nombre) a su valor en el enum Name.
# Retorna el valor correspondiente si existe, o -1 si el nombre no es válido.
# Esto permite usar strings externos (por ejemplo, desde archivos de diálogo)
# y mapearlos a un valor de control interno.
static func get_enum_from_string(string_value: String) -> int:
	var upper_string = string_value.to_upper()
	if Name.has(upper_string):
		return Name[upper_string]
	else:
		push_error("Invalid character name: " + string_value)
		return -1 #o cualquier otro valor para indicar un error
	
static func get_position_enum_from_vector(vector_position: Vector2) -> int:
	for pos_enum in POSITIONS:
		# Comparamos solo la coordenada X, ya que la Y puede variar.
		if is_equal_approx(POSITIONS[pos_enum].x, vector_position.x):
			return pos_enum
	return -1 # No se encontró una posición coincidente

static func get_position_enum_from_string(string_value: String) -> int:
	match string_value.to_lower():
		"left":
			return Position.LEFT
		"center":
			return Position.CENTER
		"right":
			return Position.RIGHT
		"far_right":
			return Position.FAR_RIGHT
		_:
			push_error("Invalid position name: " + string_value)
			return -1
