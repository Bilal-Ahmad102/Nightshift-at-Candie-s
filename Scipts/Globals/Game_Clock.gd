extends Node

signal time_changed(hour: int, minute: int)
signal hour_changed(current_hour: int)
signal night_complete

const NIGHT_HOUR_DURATIONS: Dictionary = {
	1: 75.0,
	2: 68.0,
	3: 60.0,
	4: 52.0,
	5: 45.0
}

var current_night: int = 1
var current_hour: int = 12
var current_minute: int = 0

var _timer: Timer
var _seconds_per_minute: float = 0.0

func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = false
	_timer.timeout.connect(_on_minute_passed)
	add_child(_timer)
	NightManager.night_started.connect(start_night)

func start_night(night: int) -> void:
	current_night = night
	current_hour = 12
	current_minute = 0

	var seconds_per_hour: float = NIGHT_HOUR_DURATIONS.get(night, 75.0)
	_seconds_per_minute = seconds_per_hour / 60.0

	_timer.wait_time = _seconds_per_minute
	_timer.start()

func _on_minute_passed() -> void:
	current_minute += 1

	if current_minute >= 60:
		current_minute = 0
		_advance_hour()

	emit_signal("time_changed", current_hour, current_minute)

func _advance_hour() -> void:
	if current_hour == 12:
		current_hour = 1
	else:
		current_hour += 1

	emit_signal("hour_changed", current_hour)

	if current_hour == 6:
		_timer.stop()
		emit_signal("night_complete")

func get_display_time() -> String:
	return "%d:%02d" % [current_hour, current_minute]
