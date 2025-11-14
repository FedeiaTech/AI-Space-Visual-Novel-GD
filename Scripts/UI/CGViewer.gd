# CGViewer.gd
extends PanelContainer

@onready var cg_sprite_node: TextureRect = $CGSprite

# Señal para avisar a la escena principal que se hizo clic.
signal cg_clicked
signal cg_visibility_changed(show_main_canvas: bool)

var is_full_screen: bool = false

func _ready():
	hide() # Oculta el PanelContainer

func _gui_input(event: InputEvent):
	# Si el input es un clic izquierdo...
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		
		# ...Y ESTAMOS en modo de pantalla completa...
		if is_full_screen:
			# ...entonces SÍ emitimos la señal para avanzar.
			cg_clicked.emit()
		
		# Si NO estamos en pantalla completa (full_screen == false),
		# no hacemos nada. Dejamos que el clic "pase"
		# y sea manejado por el DialogBox, que sí está visible.

func show_cg_transition(image_path: String, full_screen: bool = false):
	var loaded_texture = load(image_path)
	self.is_full_screen = full_screen
	if not loaded_texture:
		printerr("No se pudo cargar la textura: ", image_path)
		return
	
	cg_sprite_node.texture = loaded_texture # <-- CAMBIADO (aplica a la imagen)
	
	# Aplica el fade-in al PanelContainer (a 'self')
	self.modulate.a = 0.0
	self.show()
	
	show_full_screen(not full_screen)
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)

func show_cg_instant(image_path: String, full_screen: bool = false):
	var loaded_texture = load(image_path)
	self.is_full_screen = full_screen
	if not loaded_texture:
		printerr("No se pudo cargar la textura: ", image_path)
		return

	cg_sprite_node.texture = loaded_texture # <-- CAMBIADO
	self.modulate.a = 1.0
	self.show()
	
	show_full_screen(not full_screen)

func hide_cg_transition():
	if not self.visible:
		return
	
	show_full_screen(true)
	
	var tween = create_tween()
	# Aplica el fade-out al PanelContainer (a 'self')
	tween.tween_property(self, "modulate:a", 0.0, 0.7).set_trans(Tween.TRANS_SINE)
	
	await tween.finished
	self.hide()

func hide_cg_instant():
	if not self.visible:
		return
	self.hide()
	self.modulate.a = 1.0
	show_full_screen(true)
	
func show_full_screen(show_main_canvas: bool):
	cg_visibility_changed.emit(show_main_canvas)
