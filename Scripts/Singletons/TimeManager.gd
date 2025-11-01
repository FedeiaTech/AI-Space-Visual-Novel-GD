# TimeManager.gd (Autoload/Singleton)
extends Node

signal time_updated(new_time: String)
signal timer_finished

# Tiempo total en segundos.
var total_seconds: int = 0
var timer_active: bool = false
var timer_node: Timer = Timer.new()

func _ready():
	add_child(timer_node)
	timer_node.timeout.connect(_on_timer_timeout)

func start_timer(start_time_in_seconds: int):
	# Establece el tiempo inicial y comienza la cuenta regresiva.
	total_seconds = start_time_in_seconds
	timer_active = true
	timer_node.start(1) # El temporizador se activa cada segundo
	_update_display()

func stop_timer():
	timer_active = false
	timer_node.stop()

func add_time(seconds: int):
	# Añade o resta tiempo.
	total_seconds += seconds
	if total_seconds < 0:
		total_seconds = 0
	_update_display()
	
func set_time(hours: int, minutes: int):
	# Establece la hora a un valor específico.
	total_seconds = (hours * 3600) + (minutes * 60)
	_update_display()

func get_formatted_time() -> String:
	# Retorna el tiempo en formato HH:MM.
	@warning_ignore("integer_division")
	var hours = total_seconds / 3600
	@warning_ignore("integer_division")
	var minutes = (total_seconds % 3600) / 60
	var seconds = total_seconds % 60
	
	var formatted_time = "%02d:%02d:%02d" % [hours, minutes, seconds]
	# o  solo horas y minutos
	# return "%02d:%02d" % [hours, minutes]
	var final_string = formatted_time + "" # \n es un salto de línea
	return final_string

func _update_display():
	# Emite la señal para que la UI se actualice.
	time_updated.emit(get_formatted_time())

func _on_timer_timeout():
	if not timer_active: return
	total_seconds -= 1
	_update_display()
	if total_seconds <= 0:
		timer_active = false
		timer_finished.emit()
		timer_node.stop()
