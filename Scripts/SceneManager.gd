extends Node2D

#Señales
signal transition_out_completed
signal transition_in_completed
#signal load_new_dialog_file_requested(new_file_path: String, anchor: String)

#ColorRect transition Animation
var transition_layer = CanvasLayer
var transition_rect = ColorRect
var transition_time : float = 1.5

func _ready() -> void:
	transition_layer = CanvasLayer.new()
	transition_layer.layer = 100 #Capa superior
	transition_rect = ColorRect.new()
	transition_rect.color = Color.BLACK
	#llenar con el rectangulo la capa padre
	transition_rect.anchor_right = 1.0
	transition_rect.anchor_bottom = 1.0
	#Esconder rectangulo
	transition_rect.visible = false
	transition_layer.add_child(transition_rect)
	get_tree().root.add_child.call_deferred(transition_layer)

func change_scene(path: String):
	get_tree().change_scene_to_file(path)

func transition_out(effect: String = "fade"):
	match effect:
		"fade":
			_fade_out()
		"slide":
			_slide_out()
		_:
			_fade_out()

func transition_in(effect: String = "fade"):
	match effect:
		"fade":
			_fade_in()
		"slide":
			_slide_in()
		_:
			_fade_in()

func _fade_out():
	transition_rect.position = Vector2.ZERO
	transition_rect.modulate.a = 0
	transition_rect.z_index = 999
	transition_rect.visible = true
	
	var tween = create_tween()
	tween.tween_property(transition_rect, "modulate:a", 1.0, transition_time)
	tween.tween_callback(func():
		transition_out_completed.emit()
	)

func _fade_in():
	transition_rect.position = Vector2.ZERO
	transition_rect.modulate.a = 1
	transition_rect.z_index = 999
	transition_rect.visible = true
	
	var tween = create_tween()
	tween.tween_property(transition_rect, "modulate:a", 0.0, transition_time)
	tween.tween_callback(func():
		transition_rect.visible = false
		transition_in_completed.emit()
	)

func _slide_out():
	transition_rect.modulate.a = 1
	transition_rect.z_index = 999
	transition_rect.visible = true
	#Setear posicion inicial a la izquierda de la pantalla
	var viewport_size = get_viewport_rect().size
	transition_rect.position.x = viewport_size.x
	transition_rect.position.y = 0
	var tween = create_tween()
	tween.tween_property(transition_rect, "position:x", 0, transition_time)
	tween.tween_callback(func():
		transition_out_completed.emit()
	)
	
func _slide_in():
	transition_rect.modulate.a = 1
	transition_rect.z_index = 999
	transition_rect.visible = true
	#Setear posicion inicial a la derecha de la pantalla
	var viewport_size = get_viewport_rect().size
	transition_rect.position.x = 0
	transition_rect.position.y = 0
	var tween = create_tween()
	tween.tween_property(transition_rect, "position:x", -viewport_size.x, transition_time)
	tween.tween_callback(func():
		transition_rect.visible = false
		transition_in_completed.emit()
	)
	
