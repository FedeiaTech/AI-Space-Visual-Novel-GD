@tool
extends CanvasItem

# Este script detecta si estamos en el editor y avisa al shader.
func _ready():
	if material is ShaderMaterial:
		# Si estamos en el editor, static_mode = true (ahorra recursos)
		# Si estamos jugando, static_mode = false (efectos completos)
		var is_editor = Engine.is_editor_hint()
		material.set_shader_parameter("static_mode", is_editor)
