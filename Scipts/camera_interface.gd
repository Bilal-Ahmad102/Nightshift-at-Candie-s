extends Control

@onready var cam_btns: Control = $cam_btns
@onready var cam_noise: Control = $Cam_Noise
@onready var cam_dark_overlay: ColorRect = $Cam_Dark  # add this ColorRect to your scene

var cam_error_delay_min: int = 1
var cam_error_delay_max: int = 5
var spread_time: float = 8.0

var light_blips: Array[ColorRect] = []
var current_cam: int = 1
var _blink_tween: Tween
var _error_loop_running: bool = false

var error_cams: Array[int] = []
var error_timers: Dictionary = {}
var monitor_up : bool = false

const CAM_NEIGHBORS: Dictionary = {
	1: [2],
	2: [1, 3, 5],
	3: [2, 4],
	4: [3],
	5: [2, 6, 9],
	6: [5, 7],
	7: [6, 8],
	8: [7, 9],
	9: [5, 8],
}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameManger.animatronic_moved.connect(_on_animatronic_moved)
	CamGlobal.cam_interface_up.connect(func():
		monitor_up = true
		print("UP"))
	CamGlobal.cam_interface_back.connect(func():
		monitor_up = false
		print("down"))

	for cam_btn in cam_btns.get_children():
		var blip: ColorRect = cam_btn.get_child(0)
		blip.color.a = 0.0
		light_blips.append(blip)
	_start_blip(0)
	cam_dark_overlay.visible = false
	connect_signals()
	cam_noise.visible = false

func connect_signals():
	CamGlobal.cam_switched.connect(_on_cam_switched)
	CamGlobal.night3_cams_updated.connect(_on_night3_cams_updated)
	CamGlobal.add_cam_error.connect(_add_dead_error)
func _on_cam_switched(prev_cam: int, next_cam: int) -> void:
	if prev_cam > 0 and prev_cam - 1 < light_blips.size():
		light_blips[prev_cam - 1].color.a = 0.0
	current_cam = next_cam
	_start_blip(next_cam - 1)
	_update_noise_visibility()
	_update_dark_overlay()  # add this line

func _start_blip(idx: int) -> void:
	if idx < 0 or idx >= light_blips.size():
		return
	if _blink_tween and _blink_tween.is_valid():
		_blink_tween.kill()
	var blip: ColorRect = light_blips[idx]
	blip.color.a = 0.0
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_property(blip, "color:a", 1.0, 0.05)
	_blink_tween.tween_interval(0.15)
	_blink_tween.tween_property(blip, "color:a", 0.0, 0.05)
	_blink_tween.tween_interval(0.35)

func _update_noise_visibility() -> void:
	cam_noise.visible = current_cam in error_cams

func _process(delta: float) -> void:
	# gate everything behind Dave active + visible
	if not NightManager.is_animatronic_active("Dave") or not self.visible:
		return

	solve_cam_error(delta)
	
	if !GameManger.can_dave_cam_error:
		return

	# spread only if there are active errors
	if not error_cams.is_empty():
		_tick_error_spread(delta)

	if not _error_loop_running and GameManger.can_dave_cam_error:
		_try_start_error_loop()

# --- spread ---
func _tick_error_spread(delta: float) -> void:
	# stop spreading if all errors are cleared
	if error_cams.is_empty():
		return

	var cams_snapshot := error_cams.duplicate()
	for cam in cams_snapshot:
		error_timers[cam] = error_timers.get(cam, 0.0) + delta
		if error_timers[cam] >= spread_time:
			error_timers[cam] = 0.0
			_spread_error(cam)

func _spread_error(from_cam: int) -> void:
	# stop spreading if all errors somehow cleared mid-frame
	if error_cams.is_empty():
		return
	if from_cam not in CAM_NEIGHBORS:
		return
	var neighbors: Array = CAM_NEIGHBORS[from_cam]
	var available := neighbors.filter(func(n): return n not in error_cams)
	if available.is_empty():
		return
	available.shuffle()
	_add_error(available[0])

# --- error loop ---
func _try_start_error_loop() -> void:
	if not NightManager.is_animatronic_active("Dave") or not self.visible:
		return
	if not GameManger.can_dave_cam_error:
		return
	_error_loop_running = true
	_error_loop()

func _error_loop() -> void:
	var delay := randi_range(cam_error_delay_min, cam_error_delay_max)
	await get_tree().create_timer(delay).timeout

	# re-check all conditions after await
	if not NightManager.is_animatronic_active("Dave") or not self.visible or not GameManger.can_dave_cam_error:
		_error_loop_running = false
		return

	GameManger.can_dave_cam_error = false
	make_random_error()

	# wait for ALL errors to be solved before looping again
	while not error_cams.is_empty():
		await get_tree().process_frame

	_error_loop_running = false  # reset so _process can restart the loop naturally

# --- error management ---
func make_random_error() -> void:
	var available: Array[int] = []
	for i in range(1, light_blips.size() + 1):
		if i not in error_cams:
			available.append(i)
	if available.is_empty():
		return
	available.shuffle()
	var count: int = randi_range(1, min(3, available.size()))
	for i in range(count):
		_add_error(available[i])

func _add_dead_error(cam_idx: int) -> void:
	if cam_idx in error_cams:
		return
	error_cams.append(cam_idx)
	error_timers[cam_idx] = 0.0
	get_node("cam_btns/cam_" + str(cam_idx) + "/ColorRect/error_anim").show()
	get_node("cam_btns/cam_" + str(cam_idx) + "/ColorRect/error_anim/dead_error").show()
	get_node("cam_btns/cam_" + str(cam_idx) + "/ColorRect/error_anim/AnimatedSprite2D").hide()
	get_node("cam_btns/cam_" + str(cam_idx) + "/ColorRect/error_anim/ProgressBar2").hide()

	_update_noise_visibility()

func _add_error(cam_idx: int) -> void:
	if cam_idx in error_cams:
		return
	error_cams.append(cam_idx)
	error_timers[cam_idx] = 0.0
	get_node("cam_btns/cam_" + str(cam_idx) + "/ColorRect/error_anim").show()

	_update_noise_visibility()

func _clear_error(cam_idx: int) -> void:
	get_node("cam_btns/cam_" + str(cam_idx) + "/ColorRect/error_anim").hide()
	error_cams.erase(cam_idx)
	error_timers.erase(cam_idx)
	# if last error cleared, stop all spreading naturally
	_update_noise_visibility()

func solve_cam_error(delta: float) -> void:
	if current_cam not in error_cams:
		return
	var progress_bar: ProgressBar = get_node("cam_btns/cam_" + str(current_cam) + "/ColorRect/error_anim/ProgressBar2")
	if Input.is_action_pressed("solve_error"):
		error_timers[current_cam] = 0.0  # reset spread timer while fixing
		progress_bar.value += 50.0 * delta
		if progress_bar.value >= progress_bar.max_value:
			progress_bar.value = 0.0
			_clear_error(current_cam)
	else:
		progress_bar.value = max(0.0, progress_bar.value - 30.0 * delta)


func _on_night3_cams_updated(cams: Array) -> void:
	_update_dark_overlay()


func _update_dark_overlay() -> void:
	# show dark overlay if current cam is bricked by Ambassador
	var is_bricked: bool = current_cam in get_tree().get_first_node_in_group("Ambassador").bricked_cams
	cam_dark_overlay.visible = is_bricked
	
	# hide noise on bricked cams — dark is more fitting than static
	if is_bricked:
		cam_noise.visible = false
@onready var transition_error: AnimatedSprite2D = $transition_error


func _on_animatronic_moved(from: String, to: String):
	var from_id := int(from.right(2))
	var to_id := int(to.right(2))
	print(from_id," : ", to_id)

	if (current_cam == from_id or current_cam == to_id) and monitor_up: 
		transition_error.show()

		await get_tree().create_timer(1).timeout
		transition_error.hide()
