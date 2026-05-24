extends Node
const CONFIG_PATH := "res://animatronics_config.json"

var _data: Dictionary = {}

func _ready() -> void:
	load_config()

func load_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		push_error("AnimatronicConfig: file not found at %s" % CONFIG_PATH)
		return
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("AnimatronicConfig: failed to parse JSON")
		return
	_data = parsed
	print("AnimatronicConfig: loaded ", _data.keys())

# Reload at runtime (useful for tuning without restarting the game).
func reload() -> void:
	load_config()

# Get a single value with a fallback default.
#   AnimatronicConfig.get_value("Frednic", "roam_interval", 10.0)
func get_value(animatronic_id: String, key: String, default_value = null):
	if not _data.has(animatronic_id):
		push_warning("AnimatronicConfig: unknown animatronic '%s'" % animatronic_id)
		return default_value
	var section: Dictionary = _data[animatronic_id]
	if not section.has(key):
		push_warning("AnimatronicConfig: '%s' has no key '%s'" % [animatronic_id, key])
		return default_value
	return section[key]

# Get the whole section for an animatronic.
func get_section(animatronic_id: String) -> Dictionary:
	return _data.get(animatronic_id, {})
