extends Node

signal door_state_changed(door_id: String, is_closed: bool)

# ------------------------------------
# State
# ------------------------------------
var _doors: Dictionary = {
	"left": false,   # false = open
	"right": false,
}

# ------------------------------------
# Core API
# ------------------------------------
func close_door(door_id: String) -> void:
	if not _doors.has(door_id):
		return
	if _doors[door_id]:
		return  # already closed
	_doors[door_id] = true
	emit_signal("door_state_changed", door_id, true)
	print("[DoorManager] %s door closed." % door_id)

func open_door(door_id: String) -> void:
	if not _doors.has(door_id):
		return
	if not _doors[door_id]:
		return  # already open
	_doors[door_id] = false
	emit_signal("door_state_changed", door_id, false)
	print("[DoorManager] %s door opened." % door_id)

func toggle_door(door_id: String) -> void:
	if is_door_closed(door_id):
		open_door(door_id)
	else:
		close_door(door_id)

func is_door_closed(door_id: String) -> bool:
	return _doors.get(door_id, false)

func is_door_open(door_id: String) -> bool:
	return not is_door_closed(door_id)

func get_all_states() -> Dictionary:
	return _doors.duplicate()
