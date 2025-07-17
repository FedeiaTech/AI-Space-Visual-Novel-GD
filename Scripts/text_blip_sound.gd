extends AudioStreamPlayer

const SOUNDS : Dictionary = {
	"male": preload("res://Assets/Sounds/Fx/r-key.wav"),
	"female": preload("res://Assets/Sounds/Fx/r-key.wav"),
	#prueba de tercer genero
	"-": preload("res://Assets/Sounds/Fx/r-key.wav")
}

func play_sound(character_details: Dictionary):
	var character_gender = character_details["gender"]
	"""Temporal"""
	if character_gender == "female":
		pitch_scale = 1.5
	if character_gender == "male":
		pitch_scale = 1
	if character_gender == "-":
		pitch_scale = 0.5
	"""end-region"""
	stream = SOUNDS[character_gender]
	#print(SOUNDS[character_gender])
	play()
