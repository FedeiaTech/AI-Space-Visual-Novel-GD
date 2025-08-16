# JournalManager.gd
# Un Singleton (Autoload) para gestionar los diálogos vistos por el jugador.
extends Node

# Un array de diccionarios, donde cada diccionario es una entrada del diario.
# Ejemplo: [{"speaker": "Astro", "text": "¿Qué fue todo eso?"}, {"speaker": "IA", "text": "Sistema..."}]
var journal_entries: Array[Dictionary] = []

# Señal que se emite cuando se añade una nueva entrada. Útil si quieres que la UI se actualice en vivo.
signal entry_added

# Función para añadir una nueva línea de diálogo al diario.
func add_entry(speaker_name: String, dialog_text: String):
	# Evitamos duplicados exactos consecutivos (si el jugador hace clic rápido)
	if not journal_entries.is_empty():
		var last_entry = journal_entries.back()
		if last_entry.speaker == speaker_name and last_entry.text == dialog_text:
			return # No añadir la misma línea dos veces seguidas

	var new_entry = {
		"speaker": speaker_name,
		"text": dialog_text
	}
	journal_entries.append(new_entry)
	entry_added.emit()
	print("Diario actualizado: ", new_entry) # Para depuración

# Función para obtener todas las entradas del diario.
func get_all_entries() -> Array[Dictionary]:
	return journal_entries

# Función para limpiar el diario (útil para una nueva partida).
func clear_journal():
	journal_entries.clear()
