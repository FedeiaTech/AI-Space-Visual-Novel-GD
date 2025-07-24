class_name Character
extends Node

enum Name {
	ASTRO,
	ASTRO_EVA,
	IA,
	MILKA,
	NARRATOR,
	ORI,
	VIKTOR
}

const CHARACTER_DETAILS : Dictionary = {
	Name.ASTRO: {
		"name" : "Astro",
		"gender": "male",
		"sprite_frames": preload("res://Resources/Sprites_saves/Astro_sprites.tres"),
	},
	Name.ASTRO_EVA: {
		"name" : "Astro_EVA",
		"gender": "male",
		"sprite_frames": preload("res://Resources/Sprites_saves/Astro_eva_sprites.tres"),
	},
	Name.IA: {
		"name" : "IA",
		"gender": "-",
		"sprite_frames": null
	},
	Name.MILKA: {
		"name" : "Milka",
		"gender": "female",
		"sprite_frames": preload("res://Resources/Sprites_saves/Milka_sprites.tres"),
	},
	Name.NARRATOR: {
		"name" : "",
		"gender": "-",
		"sprite_frames": null,
	},
}

static func get_enum_from_string(string_value: String) -> int:
	var upper_string = string_value.to_upper()
	if Name.has(upper_string):
		return Name[upper_string]
	else:
		push_error("Invalid character name: " + string_value)
		return -1 #o cualquier otro valor para indicar un error
