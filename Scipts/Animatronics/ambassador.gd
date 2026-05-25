extends Node3D

signal jumpscare_requested(animatronic_id: String)

const ANIMATRONIC_ID := "Ambassador"

@export var cam_markers_root: Node   # parent node holding Marker3D children keyed by cam name


# how long she stays on each camera before moving
var move_time_min: float = 5.0
var move_time_max: float = 8.0

# her current cameras
var occupied_cams: Array[int] = []
var strikes: int = 0
var bricked_cams: Array[int] = []
var _is_active: bool = false
var _monitor_open: bool = false
var _was_visible_when_closed: bool = false

# timers per occupied cam: cam_idx -> time elapsed
var _cam_timers: Dictionary = {}

const ALL_CAMS: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 11]

func _ready() -> void:
	move_time_min = AnimatronicConfig.get_value("Ambassador", "move_time_min", 5.0)
	move_time_max = AnimatronicConfig.get_value("Ambassador", "move_time_max", 8.0)
	NightManager.night_started.connect(_on_night_started)
	NightManager.night_ended.connect(_on_night_ended)

	GameManger.register_animatronic(self)

func _on_night_ended(night: int, success: bool) -> void:
	deactivate()
	
func _on_night_started(night: int) -> void:
	if NightManager.is_animatronic_active("Ambassador"):
		activate()  

func activate() -> void:

	CamGlobal.cam_switched.connect(_on_cam_switched)
	CamGlobal.cam_interface_up.connect(_on_monitor_opened)
	CamGlobal.cam_interface_back.connect(_on_monitor_closed)

	_is_active = true
	occupied_cams.clear()
	_cam_timers.clear()
	self.show()

func deactivate() -> void:

	CamGlobal.cam_switched.disconnect(_on_cam_switched)
	CamGlobal.cam_interface_up.disconnect(_on_monitor_opened)
	CamGlobal.cam_interface_back.disconnect(_on_monitor_closed)

	_is_active = false
	occupied_cams.clear()
	_cam_timers.clear()
	self.hide()

func _process(delta: float) -> void:
	if not _is_active:
		return
	_tick_cam_timers(delta)

# --- monitor open/close ---
func _on_monitor_opened() -> void:
	_monitor_open = true
	_was_visible_when_closed = false
	_spawn_on_random_cams()

func _on_monitor_closed() -> void:
	if not _is_active:
		return
	_monitor_open = false
	# check if she was visible on current cam when player lowered cameras
	if _was_visible_when_closed:
		_handle_strike()
	_was_visible_when_closed = false

func _on_cam_switched(_prev: int, next: int) -> void:
	# track if player is looking at her
	_update_visibility(next)

func _update_visibility(cam: int) -> void:
	if cam in occupied_cams and cam not in bricked_cams:
		_was_visible_when_closed = true
	else:
		_was_visible_when_closed = false

# --- spawn ---
func _move_from_cam(from_cam: int) -> void:
	var available := ALL_CAMS.filter(func(c): 
		return c not in occupied_cams and c not in bricked_cams
	)
	occupied_cams.erase(from_cam)
	_cam_timers.erase(from_cam)
	if available.is_empty():
		_notify_ui()
		return
	available.shuffle()
	var new_cam: int = available[0]
	occupied_cams.append(new_cam)
	_cam_timers[new_cam] = 0.0
	_move_model_to_cam(new_cam)  # move 3D model
	_notify_ui()

func _spawn_on_random_cams() -> void:
	var max_spawn = AnimatronicConfig.get_value("Ambassador", "max_spawn_count", 3)
	var available := ALL_CAMS.filter(func(c): return c not in bricked_cams)
	if available.is_empty():
		return

	var count: int = randi_range(1, min(max_spawn, available.size()))

	available.shuffle()
	occupied_cams.clear()
	_cam_timers.clear()
	for i in range(count):
		var cam: int = available[i]
		occupied_cams.append(cam)
		_cam_timers[cam] = 0.0
	# place model on first occupied cam
	print("occupied : ",occupied_cams)
	if not occupied_cams.is_empty():
		_move_model_to_cam(occupied_cams[0])
	_notify_ui()




# --- movement ---
func _tick_cam_timers(delta: float) -> void:
	var cams_snapshot := occupied_cams.duplicate()

	for cam in cams_snapshot:
		_cam_timers[cam] = _cam_timers.get(cam, 0.0) + delta
		if _cam_timers[cam] >= randf_range(move_time_min, move_time_max):
			_move_from_cam(cam)

func _move_model_to_cam(cam_idx: int) -> void:
	if cam_markers_root == null:
		return
	var marker = cam_markers_root.get_child(cam_idx-1)
	if marker == null:
		push_error("Ambassador: no marker found for " + marker)
		return
	global_position = marker.global_position
	global_rotation = marker.global_rotation

# --- strike system ---
func _handle_strike() -> void:
	var max_strikes = AnimatronicConfig.get_value("Ambassador", "strikes_to_jumpscare", 3)
	$Label.text = "strike: " + str(strikes)
	
	if strikes >= max_strikes:
		jumpscare_requested.emit(ANIMATRONIC_ID)
	elif strikes < max_strikes:
		_brick_cam(CamGlobal.get_current_open_cam())
	strikes += 1
func _brick_cam(cam: int) -> void:
	
	if cam in bricked_cams:
		return
	bricked_cams.append(cam)
	occupied_cams.erase(cam)
	_cam_timers.erase(cam)
	CamGlobal.add_cam_error.emit(cam)  # reuse your static noise for bricked cam
	_notify_ui()

# --- notify camera UI ---
func _notify_ui() -> void:
	CamGlobal.night3_cams_updated.emit(occupied_cams.duplicate())
