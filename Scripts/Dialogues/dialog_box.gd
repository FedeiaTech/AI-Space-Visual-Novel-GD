# dialog_box.gd
# Solo detecta interacciones con el mouse y por el momento solo seran de avance del dialogo
extends PanelContainer

signal dialog_clicked

func _ready() -> void:
	self.mouse_filter = MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("¡Clic en DialogBox!")
		dialog_clicked.emit()
		get_viewport().set_input_as_handled()
