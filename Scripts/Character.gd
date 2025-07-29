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

# Diccionario constante que almacena los detalles de cada personaje.
# Usa el enum como clave y un diccionario
const CHARACTER_DETAILS : Dictionary = {
	Name.ASTRO: {
		"name" : "Astro",
		"gender": "male",
		"sprite_frames": preload("res://Resources/Sprites_saves/Astro_sprites.tres"),
		"color": Color("#ff0000") # Rojo
		#"color": Color("#FFD700") # Un amarillo dorado
	},
	Name.ASTRO_EVA: {
		"name" : "Astro_EVA",
		"gender": "male",
		"sprite_frames": preload("res://Resources/Sprites_saves/Astro_eva_sprites.tres"),
		"color": Color("#e61919") # Rojo desaturado
	},
	Name.IA: {
		"name" : "IA",
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
	Name.NARRATOR: {
		"name" : "",
		"gender": "-",
		"sprite_frames": null,
	},
}

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
