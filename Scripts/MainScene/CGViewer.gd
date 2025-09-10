# CGViewer.gd
extends TextureRect

var main_scene: Node2D

# Señal para avisar a la escena principal que se hizo clic.
signal cg_clicked

func _ready():
	# El nodo empieza oculto.
	hide()
	main_scene = get_parent().get_parent()

# Esta función se activa cuando hay un input SOBRE ESTE NODO.
func _gui_input(event: InputEvent):
	# Si el input es un clic izquierdo del mouse y se acaba de presionar...
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# ...emitimos la señal para que MainScene se entere.
		cg_clicked.emit()

# Muestra el CG con una transición de "slide" desde la derecha.
func show_cg_transition(image_path: String):
	var loaded_texture = load(image_path)
	if not loaded_texture:
		printerr("No se pudo cargar la textura del CG en la ruta: ", image_path)
		return
	
	self.texture = loaded_texture
	
	# Preparamos la animación: nos colocamos fuera de la pantalla a la derecha.
	self.position.x = get_viewport_rect().size.x
	# Nos hacemos visibles MIENTRAS estamos fuera de la pantalla.
	self.show()
	main_scene.get_node("CanvasMain").hide()
	main_scene.get_node("ViewerCanvas").hide()
	
	# Creamos el tween para la animación de entrada.
	var tween = create_tween()
	tween.tween_property(self, "position:x", 0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# Muestra el CG instantáneamente.
func show_cg_instant(image_path: String):
	var loaded_texture = load(image_path)
	if not loaded_texture:
		printerr("No se pudo cargar la textura del CG en la ruta: ", image_path)
		return

	self.texture = loaded_texture
	self.position.x = 0
	self.show()
	main_scene.get_node("CanvasMain").hide()
	main_scene.get_node("ViewerCanvas").hide()

# Oculta el CG con una transición de "slide" hacia la izquierda.
func hide_cg_transition():
	if not self.visible:
		return

	var tween = create_tween()
	# Lo movemos hacia la izquierda hasta que salga de la pantalla.
	tween.tween_property(self, "position:x", -get_viewport_rect().size.x, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Cuando la animación termine, nos ocultamos por completo.
	await tween.finished
	self.hide()

# Oculta el CG instantáneamente.
func hide_cg_instant():
	if not self.visible:
		return
	self.hide()
	self.position.x = 0 # Reiniciamos la posición para la próxima vez que se muestre.
