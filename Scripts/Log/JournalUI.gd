# JournalUI.gd
extends Control

@onready var entries_list: VBoxContainer = %EntriesList # Asegúrate que el VBoxContainer se llame EntriesList en la escena

var needs_update: bool = true

func _ready() -> void:
	# Conectamos la señal 'visibility_changed' de este mismo nodo (self)
	# a una nueva función que crearemos, llamada '_on_visibility_changed'.
	visibility_changed.connect(_on_visibility_changed)
	
	JournalManager.entry_added.connect(populate_journal.bind(true))
	
# Esta es la función que se ejecutará CADA VEZ que el nodo se muestre u oculte.
func _on_visibility_changed():
	if is_visible():
		get_tree().paused = true
		# Se llama a populate_journal cuando el diario se abre
		populate_journal(false) 
	else:
		get_tree().paused = false

func populate_journal(from_signal: bool):
	if from_signal and not is_visible():
		return
	
	for child in entries_list.get_children():
		child.queue_free()

	var all_entries = JournalManager.get_all_entries()

	if all_entries.is_empty():
		return

	for entry in all_entries:
		# === CAMBIAMOS A NODO LABEL ===
		var entry_label = Label.new()
		
		var speaker_name = entry.speaker
		var text = entry.text
		
		var text_color = Color.WHITE # Usamos un Color en lugar de una cadena
		if speaker_name == "Astro":
			text_color = Color("lightblue")
		elif speaker_name == "IA":
			text_color = Color("lightgreen")
		
		# Como es un Label, usamos texto plano y un `\n` para los saltos de línea.
		var final_text = speaker_name + ": " + text
		
		entry_label.text = final_text
		entry_label.add_theme_color_override("font_color", text_color)
		
		entry_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		entry_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		entries_list.add_child.call_deferred(entry_label)
