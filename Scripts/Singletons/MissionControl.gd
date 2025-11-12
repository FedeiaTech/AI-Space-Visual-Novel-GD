# MissionControl.gd
extends Node

# Señal para que la UI se actualice
signal quest_log_updated

# Enum para los estados de la misión
enum QuestState {
	LOCKED,  # La misión aún no se descubre
	ACTIVE,  # La misión está en progreso
	COMPLETED # La misión se ha completado
}

# -------------------------------------------------------------------
# --- BASE DE DATOS DE MISIONES (La "Fuente de Verdad") ---
# -------------------------------------------------------------------
const QUEST_DATABASE = {
	"find_ori": {
		"title": "Encuentra a Ori",
		"description": "Astro necesita encontrar a Ori. Se mencionó que podría estar en el Centro de Mando."
	},
	"fix_anomaly": {
		"title": "Investiga la Anomalía",
		"description": "Una extraña lectura de energía proviene de la bahía de carga. Debería investigarlo."
	}
	# ... (Añade aquí todas las misiones de tu juego) ...
}

# -------------------------------------------------------------------
# --- ESTADO DEL JUGADOR ---
# -------------------------------------------------------------------

# 1. Banderas simples (tu sistema actual)
var quest_flags: Dictionary = {
	"debug_flag_test": false,
	"mision_anomalia": false,
	"zona_segura_desbloqueada": false,
	"npc_encontrado_ori": false,
	
}

# 2. Estados de misiones complejas
var quest_states: Dictionary = {}


# -------------------------------------------------------------------
# --- INICIALIZACIÓN ---
# -------------------------------------------------------------------

func _ready():
	# Inicializa el diccionario de estados de misiones
	# Todas las misiones empiezan como "LOCKED" (Bloqueadas)
	for quest_id in QUEST_DATABASE:
		quest_states[quest_id] = QuestState.LOCKED


# -------------------------------------------------------------------
# --- API PÚBLICA (Funciones para otros scripts) ---
# -------------------------------------------------------------------

# --- Funciones de Banderas Simples ---

func set_quest_flag(flag_id: String, value: bool):
	if quest_flags.has(flag_id):
		quest_flags[flag_id] = value
		print("ControlDeMision: Bandera '", flag_id, "' establecida a: ", value)
	else:
		printerr("Advertencia: Intentando establecer bandera no definida: ", flag_id)

func get_quest_flag(flag_id: String) -> bool:
	return quest_flags.get(flag_id, false)

# --- Funciones de Misiones Complejas ---

# Activa una misión (la marca como "En Progreso")
func activate_quest(quest_id: String):
	if quest_states.has(quest_id):
		if quest_states[quest_id] == QuestState.LOCKED:
			quest_states[quest_id] = QuestState.ACTIVE
			print("ControlDeMision: Misión activada '", quest_id, "'")
			quest_log_updated.emit()
	else:
		printerr("Error: Intento de activar misión inexistente: ", quest_id)

# Completa una misión
func complete_quest(quest_id: String):
	if quest_states.has(quest_id):
		if quest_states[quest_id] == QuestState.ACTIVE:
			quest_states[quest_id] = QuestState.COMPLETED
			print("ControlDeMision: Misión completada '", quest_id, "'")
			quest_log_updated.emit()
	else:
		printerr("Error: Intento de completar misión inexistente: ", quest_id)

# Devuelve el estado actual de una misión
func get_quest_state(quest_id: String) -> QuestState:
	return quest_states.get(quest_id, QuestState.LOCKED)

# Devuelve un Array de todas las misiones ACTIVAS (para la UI)
func get_active_quests() -> Array[Dictionary]:
	var active_quest_list: Array[Dictionary] = []
	for quest_id in quest_states:
		if quest_states[quest_id] == QuestState.ACTIVE:
			# Si está activa, combina la ID con sus datos de la DB
			var quest_data = QUEST_DATABASE[quest_id].duplicate()
			quest_data["id"] = quest_id
			active_quest_list.append(quest_data)
	return active_quest_list

# (Opcional) Devuelve un Array de todas las misiones COMPLETADAS
func get_completed_quests() -> Array[Dictionary]:
	var completed_quest_list: Array[Dictionary] = []
	for quest_id in quest_states:
		if quest_states[quest_id] == QuestState.COMPLETED:
			var quest_data = QUEST_DATABASE[quest_id].duplicate()
			quest_data["id"] = quest_id
			completed_quest_list.append(quest_data)
	return completed_quest_list
