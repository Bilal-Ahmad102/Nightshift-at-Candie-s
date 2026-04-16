extends Node

signal night_started(night: int)
signal night_ended(night: int, success: bool)
signal animatronics_updated(active_list: Array)

const NIGHT_ANIMATRONICS: Dictionary = {
	1: ["Dave"],
	2: ["Dave", "Frednic", "Rena"],
	3: ["Dave", "Rena", "Ambassador"],
	4: ["Dave", "Frednic", "Rena", "Ambassador"],
	5: ["TheRealFredbear", "Bronnie"],
}

const NIGHT_AI_LEVELS: Dictionary = {
	1: {"Dave": 1},
	2: {"Dave": 2, "Frednic": 1, "Rena": 1},
	3: {"Dave": 3, "Rena": 2, "Ambassador": 1},
	4: {"Dave": 4, "Frednic": 3, "Rena": 3, "Ambassador": 2},
	5: {"TheRealFredbear": 5, "Bronnie": 5},
}

var current_night: int = 1
var is_night_active: bool = false
var is_custom_night: bool = false

var custom_ai_levels: Dictionary = {
	"Dave": 0,
	"Frednic": 0,
	"Rena": 0,
	"Ambassador": 0,
	"TheRealFredbear": 0,
	"Bronnie": 0,
}

var _active_animatronics: Array = []

func start_night(night: int) -> void:
	current_night = night
	is_custom_night = false
	is_night_active = true
	_active_animatronics = NIGHT_ANIMATRONICS.get(night, [])
	emit_signal("night_started", night)
	emit_signal("animatronics_updated", _active_animatronics)
	print("[NightManager] Night %d started. Active: %s" % [night, str(_active_animatronics)])

func end_night(success: bool) -> void:
	if not is_night_active:
		return
	is_night_active = false
	emit_signal("night_ended", current_night, success)
	if success:
		print("[NightManager] Night %d completed." % current_night)
	else:
		print("[NightManager] Night %d failed." % current_night)

func get_active_animatronics() -> Array:
	return _active_animatronics

func is_animatronic_active(anim_name: String) -> bool:
	return anim_name in _active_animatronics

func get_ai_level(anim_name: String) -> int:
	if is_custom_night:
		return custom_ai_levels.get(anim_name, 0)
	return NIGHT_AI_LEVELS.get(current_night, {}).get(anim_name, 0)

func get_current_night() -> int:
	return current_night
