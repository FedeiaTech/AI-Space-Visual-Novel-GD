# CGViewer.gd
# (Script en el nodo PanelContainer 'CGViewerWindow')
extends PanelContainer

@onready var cg_sprite_node: TextureRect = $CGSprite
@onready var video_player_node: VideoStreamPlayer = $VideoPlayer

signal cg_clicked
signal cg_visibility_changed(show_main_canvas: bool)

var is_full_screen: bool = false
var is_video_playing: bool = false

# --- CONFIGURACIÓN ---
# Tiempo exacto en segundos donde queremos congelar el video.
const STOP_AT_SECONDS = 4.5 

func _ready():
	hide()
	set_process(false)
	
	# Mantenemos la señal como "Plan B" por si el video dura menos de 4.5s
	video_player_node.finished.connect(_on_video_finished_signal)

# --- MONITOR DE TIEMPO FIJO ---
func _process(_delta):
	# Si ya no estamos reproduciendo (o se pausó), apagamos el monitor.
	if not is_video_playing:
		set_process(false)
		return

	# Obtenemos la posición actual del video
	# (Esto SÍ funciona aunque get_stream_length devuelva 0)
	var current_pos = video_player_node.stream_position
	
	# Comprobamos si llegamos al segundo 4.5
	if current_pos >= STOP_AT_SECONDS:
		print("Tiempo límite alcanzado (", current_pos, "s). Congelando video.")
		_perform_pause_logic()

# --- LÓGICA DE PAUSA CENTRALIZADA ---
func _perform_pause_logic():
	if not is_video_playing: return

	# 1. Congelamos la imagen en el frame actual
	video_player_node.paused = true
	
	# 2. Liberamos el bloqueo de input
	is_video_playing = false
	
	# 3. Apagamos el monitor
	set_process(false)

# --- INPUT ---
func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		
		# CASO 1: El video se está reproduciendo -> IGNORAR
		if is_video_playing:
			print("Video en reproducción. Clic bloqueado.")
			return

		# CASO 2: El video HA TERMINADO (o es una imagen)
		print("Avanzando diálogo post-video/cg...")
		
		# --- ¡CORRECCIÓN CLAVE AQUÍ! ---
		# Si la escena NO era de pantalla completa, no la cerramos.
		# Solo avanzamos el diálogo.
		if not is_full_screen:
			# Solo avisamos a la escena principal de avanzar.
			cg_clicked.emit() 
			return
		# -----------------------------
		
		# Si era de pantalla completa (el comportamiento por defecto de un CG),
		# la cerramos y luego avanzamos.
		reset_and_hide()
		cg_clicked.emit()

# --- CALLBACK SEÑAL (PLAN B) ---
func _on_video_finished_signal():
	# Esto solo ocurre si el video termina ANTES de llegar a los 4.5s
	if is_video_playing:
		print("El video terminó antes de los 4.5s. Habilitando avance.")
		_perform_pause_logic()

# --- FUNCIONES DE VIDEO ---

func play_video_transition(video_stream: VideoStream, full_screen: bool = false):
	_reset_state()
	self.is_full_screen = full_screen
	self.is_video_playing = true
	
	cg_sprite_node.hide()
	video_player_node.stream = video_stream
	video_player_node.paused = false
	video_player_node.show()
	
	self.modulate.a = 0.0
	self.show()
	show_full_screen(not full_screen)
	
	video_player_node.play()
	set_process(true) # Encendemos el monitor
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)

func play_video_instant(video_stream: VideoStream, full_screen: bool = false):
	_reset_state()
	self.is_full_screen = full_screen
	self.is_video_playing = true
	
	cg_sprite_node.hide()
	video_player_node.stream = video_stream
	video_player_node.paused = false
	video_player_node.show()
	
	self.modulate.a = 1.0
	self.show()
	show_full_screen(not full_screen)
	
	video_player_node.play()
	set_process(true) # Encendemos el monitor

# --- FUNCIONES DE IMAGEN (Sin cambios) ---

func show_cg_transition(image_path: String, full_screen: bool = false):
	_reset_state()
	self.is_full_screen = full_screen
	var loaded_texture = load(image_path)
	if not loaded_texture: return
	video_player_node.hide()
	cg_sprite_node.texture = loaded_texture
	cg_sprite_node.show()
	self.modulate.a = 0.0
	self.show()
	show_full_screen(not full_screen)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)

func show_cg_instant(image_path: String, full_screen: bool = false):
	_reset_state()
	self.is_full_screen = full_screen
	var loaded_texture = load(image_path)
	if not loaded_texture: return
	video_player_node.hide()
	cg_sprite_node.texture = loaded_texture
	cg_sprite_node.show()
	self.modulate.a = 1.0
	self.show()
	show_full_screen(not full_screen)

# --- FUNCIONES DE OCULTAR Y AYUDA ---

func hide_cg_transition():
	if not self.visible: return
	reset_and_hide()
	show_full_screen(true)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.7).set_trans(Tween.TRANS_SINE)
	await tween.finished
	self.hide()

func hide_cg_instant():
	if not self.visible: return
	reset_and_hide()
	self.hide()
	self.modulate.a = 1.0
	show_full_screen(true)
	
func show_full_screen(show_main_canvas: bool):
	cg_visibility_changed.emit(show_main_canvas)

func reset_and_hide():
	video_player_node.stop()
	video_player_node.hide()
	cg_sprite_node.hide()
	is_video_playing = false
	set_process(false) 
	self.hide() 

func _reset_state():
	video_player_node.stop()
	video_player_node.hide()
	cg_sprite_node.hide()
	is_video_playing = false
	set_process(false)
