# InputManager.gd
# Este script es "tonto". No sabe NADA sobre el estado del juego.
# Su único trabajo es detectar las acciones de input y emitir una señal.
extends Node

# Señales que "anuncian" que una tecla fue presionada.
signal inventory_toggled
signal journal_toggled
signal next_line_pressed
signal pause_pressed # Para la tecla 'Escape'

func _input(event: InputEvent) -> void:
	# Usamos 'if' separados (no 'elif') porque un evento puede
	# ser manejado por múltiples acciones, aunque aquí las
	# acciones son únicas.

	if event.is_action_pressed("toggle_inventory"):
		inventory_toggled.emit()
		# Marcamos el evento como manejado para que no siga
		# propagándose (ej. a la UI de diálogo).
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("toggle_journal"):
		journal_toggled.emit()
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("next_line"):
		next_line_pressed.emit()
		get_viewport().set_input_as_handled()

	# "ui_cancel" es la acción por defecto de la tecla 'Escape'
	if event.is_action_pressed("ui_cancel"):
		pause_pressed.emit()
		get_viewport().set_input_as_handled()
