extends Node

const SAVE_PATH = "user://save.cfg"

var _data: Dictionary = {
	"current_night": 1,
	"unlocked_nights": [1],
	"settings": {
		"master_volume": 1.0,
		"sfx_volume": 1.0,
		"music_volume": 1.0,
		"fullscreen": false,
	}
}

# ─────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────
func save() -> void:
	var config := ConfigFile.new()

	config.set_value("progress", "current_night",   _data["current_night"])
	config.set_value("progress", "unlocked_nights",  _data["unlocked_nights"])

	config.set_value("settings", "master_volume",  _data["settings"]["master_volume"])
	config.set_value("settings", "sfx_volume",     _data["settings"]["sfx_volume"])
	config.set_value("settings", "music_volume",   _data["settings"]["music_volume"])
	config.set_value("settings", "fullscreen",     _data["settings"]["fullscreen"])

	var err = config.save(SAVE_PATH)
	if err != OK:
		push_error("[SaveManager] Failed to save: %s" % err)
	else:
		print("[SaveManager] Game saved.")

func load_save() -> void:
	var config := ConfigFile.new()
	var err = config.load(SAVE_PATH)

	if err != OK:
		print("[SaveManager] No save found, using defaults.")
		return

	_data["current_night"]   = config.get_value("progress", "current_night",   1)
	_data["unlocked_nights"] = config.get_value("progress", "unlocked_nights",  [1])

	_data["settings"]["master_volume"] = config.get_value("settings", "master_volume", 1.0)
	_data["settings"]["sfx_volume"]    = config.get_value("settings", "sfx_volume",    1.0)
	_data["settings"]["music_volume"]  = config.get_value("settings", "music_volume",  1.0)
	_data["settings"]["fullscreen"]    = config.get_value("settings", "fullscreen",    false)

	print("[SaveManager] Save loaded. Night: %d" % _data["current_night"])

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		_data["current_night"]   = 1
		_data["unlocked_nights"] = [1]
		print("[SaveManager] Save deleted.")

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

# ─────────────────────────────────────────────────────────────
# Progress getters / setters
# ─────────────────────────────────────────────────────────────
func get_current_night() -> int:
	return _data["current_night"]

func set_current_night(night: int) -> void:
	_data["current_night"] = night

func unlock_night(night: int) -> void:
	if night not in _data["unlocked_nights"]:
		_data["unlocked_nights"].append(night)
		save()

# Call this when a night is completed. Only advances current_night
# if `night` is higher than what's already saved, so replaying earlier
# nights doesn't undo progress. Also unlocks the night.
func save_night_progress(night: int) -> void:
	var changed := false
	if night > _data["current_night"]:
		_data["current_night"] = night
		changed = true
	if night not in _data["unlocked_nights"]:
		_data["unlocked_nights"].append(night)
		changed = true
	if changed:
		save()

func is_night_unlocked(night: int) -> bool:
	return night in _data["unlocked_nights"]

func get_unlocked_nights() -> Array:
	return _data["unlocked_nights"]

# ─────────────────────────────────────────────────────────────
# Settings getters / setters
# ─────────────────────────────────────────────────────────────
func get_master_volume() -> float:
	return _data["settings"]["master_volume"]

func set_master_volume(value: float) -> void:
	_data["settings"]["master_volume"] = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))

func get_sfx_volume() -> float:
	return _data["settings"]["sfx_volume"]

func set_sfx_volume(value: float) -> void:
	_data["settings"]["sfx_volume"] = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))

func get_music_volume() -> float:
	return _data["settings"]["music_volume"]

func set_music_volume(value: float) -> void:
	_data["settings"]["music_volume"] = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))

func get_fullscreen() -> bool:
	return _data["settings"]["fullscreen"]

func set_fullscreen(value: bool) -> void:
	_data["settings"]["fullscreen"] = value
	if value:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
