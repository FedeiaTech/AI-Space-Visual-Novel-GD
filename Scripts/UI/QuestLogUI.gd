# QuestLogUI.gd
# (Script para la escena res://Scenes/UI/QuestLogUI.tscn)
extends CanvasLayer

signal quest_log_closed

# --- Referencias a los nodos de la escena ---
@onready var close_button: Button = %CloseButton
@onready var quest_list_container: VBoxContainer = %QuestListContainer
@onready var detail_title_label: Label = %MissionTitleLabel
@onready var detail_description_label: Label = %DescriptionLabel

# (Opcional, pero recomendado: un Label para el mensaje de "vacío")
# Si no tienes este nodo, la función 'display_empty_details' fallará.
# Si no lo quieres, puedes comentar las líneas que usan esta variable.
@onready var empty_list_message_label: Label = %EmptyListMessageLabel

var _current_selected_quest_data: Dictionary = {}

func _ready():
	close_button.pressed.connect(_on_close_button_pressed)
	MissionControl.quest_log_updated.connect(populate_quest_list)
	
	detail_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	# _ready() ahora solo llama a populate_quest_list().
	# La lógica de qué mostrar se mueve DENTRO de esa función.
	populate_quest_list()

func _on_close_button_pressed():
	quest_log_closed.emit()
	queue_free()

# Esta función crea los botones Y decide qué mostrar en el panel de detalles
func populate_quest_list():
	# --- Limpiar lista antigua ---
	for child in quest_list_container.get_children():
		child.queue_free()

	# --- ¡NUEVO! ESTILO DE FUENTE HEREDADO ---
	# Aplicamos los estilos de fuente al contenedor padre UNA SOLA VEZ.
	# Todos los hijos (Label y Button) heredarán esto.
	
	# quest_list_container.add_theme_font_size_override("font_size", 20)
	quest_list_container.add_theme_color_override("font_color", Color.WHITE)
	quest_list_container.add_theme_color_override("font_hover_color", Color.LIGHT_BLUE)
	quest_list_container.add_theme_color_override("font_pressed_color", Color.STEEL_BLUE)
	quest_list_container.add_theme_color_override("font_disabled_color", Color.DARK_GRAY)
	# --- FIN DEL ESTILO HEREDADO ---

	# --- Título para Misiones Activas ---
	var active_quests_header = Label.new()
	active_quests_header.text = "MISIONES ACTIVAS"
	# (Opcional) Haz que el título sea más grande que el resto
	#active_quests_header.add_theme_font_size_override("font_size", 24) 
	quest_list_container.add_child(active_quests_header)

	var active_quests = MissionControl.get_active_quests()
	if active_quests.is_empty():
		var lbl = Label.new()
		lbl.text = "  No hay misiones activas."
		lbl.modulate = Color.GRAY
		quest_list_container.add_child(lbl)
	else:
		for quest in active_quests:
			var quest_button = Button.new()
			quest_button.text = "  " + quest.get("title", "Misión Desconocida")
			quest_button.flat = true
			quest_button.alignment = HORIZONTAL_ALIGNMENT_LEFT # Alinear a la izquierda

			# ESTO SÍ VA DENTRO DEL BUCLE:
			# Quita el borde de "focus" (el recuadro blanco al cliquear)
			var empty_stylebox = StyleBoxEmpty.new()
			quest_button.add_theme_stylebox_override("focus", empty_stylebox)

			quest_button.pressed.connect(_on_quest_selected.bind(quest))
			quest_list_container.add_child(quest_button)

	# --- Título para Misiones Completadas ---
	quest_list_container.add_child(HSeparator.new())
	var completed_quests_header = Label.new()
	completed_quests_header.text = "MISIONES COMPLETADAS"
	#completed_quests_header.add_theme_font_size_override("font_size", 24)
	quest_list_container.add_child(completed_quests_header)
	
	var completed_quests = MissionControl.get_completed_quests()
	if completed_quests.is_empty():
		var lbl = Label.new()
		lbl.text = "  Ninguna misión completada."
		lbl.modulate = Color.GRAY
		quest_list_container.add_child(lbl)
	else:
		for quest in completed_quests:
			var quest_button = Button.new()
			quest_button.text = "  " + quest.get("title", "Misión Desconocida")
			quest_button.flat = true
			quest_button.disabled = true
			quest_button.modulate = Color.GRAY
			quest_button.alignment = HORIZONTAL_ALIGNMENT_LEFT # Alinear a la izquierda

			# (No necesita el 'focus' override porque está deshabilitado)
			
			quest_button.pressed.connect(_on_quest_selected.bind(quest))
			quest_list_container.add_child(quest_button)

	# --- Lógica de selección de detalles ---
	if not active_quests.is_empty():
		_on_quest_selected(active_quests[0])
	elif not completed_quests.is_empty():
		_on_quest_selected(completed_quests[0])
	else:
		display_empty_details()

# Muestra los detalles de la misión seleccionada en el panel derecho
func _on_quest_selected(quest_data: Dictionary):
	_current_selected_quest_data = quest_data
	detail_title_label.text = quest_data.get("title", "Error al cargar misión")
	detail_description_label.text = quest_data.get("description", "Descripción no disponible.")
	
	# Asegúrate de que los labels estén visibles
	detail_title_label.show()
	detail_description_label.show()
	if is_instance_valid(empty_list_message_label): # Comprobación de seguridad
		empty_list_message_label.hide() # Oculta el mensaje de "Vacío"

# Muestra un mensaje cuando no hay misiones para seleccionar
func display_empty_details():
	_current_selected_quest_data = {}
	detail_title_label.hide()
	detail_description_label.hide()
	
	if is_instance_valid(empty_list_message_label): # Comprobación de seguridad
		empty_list_message_label.show()
		empty_list_message_label.text = "No hay misión seleccionada."
		empty_list_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_list_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	else:
		# Fallback si no creaste el nodo EmptyListMessageLabel
		detail_title_label.show()
		detail_description_label.show()
		detail_title_label.text = "Registro Vacío"
		detail_description_label.text = "No hay misiones activas."
