extends Control

@onready var cam_btns: Control = $cam_btns
@onready var cam_noise: Control = $Cam_Noise

var cam_error_delay_min : int = 1
var cam_error_delay_max : int = 5

var light_blips: Array[ColorRect] = []
var current_cam: int = 0
var _blink_tween: Tween

# error tracking
var error_cams: Array[int] = []  # which cams have errors active

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	connect_signals()
	for cam_btn in cam_btns.get_children():
		var blip: ColorRect = cam_btn.get_child(0)
		blip.color.a = 0.0
		light_blips.append(blip)
	_start_blip(0)
	CamGlobal.cam_switched.connect(_on_cam_switched)
	cam_noise.visible = false

func connect_signals() -> void:
	for cam_texture: TextureRect in cam_btns.get_children():
		cam_texture.gui_input.connect(_on_cam_texture_click.bind(cam_texture.name))
		cam_texture.mouse_entered.connect(_on_mouse_entered.bind(cam_texture.name))

func _on_mouse_entered(cam_name):
	pass

func _on_cam_texture_click(event: InputEvent, cam_name: String) -> void:
	CamGlobal.cam_texture_clicked.emit((int(cam_name.split("_")[-1])) - 1)

func _on_cam_switched(prev_cam: int, next_cam: int) -> void:
	if prev_cam > 0 and prev_cam - 1 < light_blips.size():
		light_blips[prev_cam - 1].color.a = 0.0
	current_cam = next_cam
	_start_blip(next_cam - 1)
	_update_noise_visibility()

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
	# show static only if the camera you're currently watching has an error
	cam_noise.visible = current_cam in error_cams
	

func _process(delta: float) -> void:
	start_cam_error()
	
func solve_cam_error() -> void:
	if current_cam not in error_cams:
		return
	
	var progress_bar: ProgressBar = get_node("cam_btns/cam_" + str(current_cam) + "/ColorRect/error_anim/ProgressBar2")
	
	if Input.is_action_pressed("solve_error"):
		progress_bar.value += 50.0 * get_process_delta_time()
		if progress_bar.value >= progress_bar.max_value:
			progress_bar.value = 0.0
			_clear_error(current_cam)
	else:
		# drain back down when not holding
		progress_bar.value -= 30.0 * get_process_delta_time()
		progress_bar.value = max(0.0, progress_bar.value)

func start_cam_error():
	if not NightManager.is_animatronic_active("Dave") or not self.visible:
		return
	solve_cam_error()

	if !GameManger.can_dave_cam_error:
		return

	GameManger.can_dave_cam_error  = false
	var error_delay = randi_range(cam_error_delay_min,cam_error_delay_max)
	await  get_tree().create_timer(error_delay).timeout

	make_random_error()
	# $cam_btns/cam_1/error_anim
	if !error_cams.is_empty():
		for cam in error_cams:
			get_node("cam_btns/cam_"+str(cam)+"/ColorRect/error_anim").show()

func make_random_error() -> void:
	

	# pick 1–3 random cameras that don't already have an error
	var available: Array[int] = []
	for i in range(1, light_blips.size() + 1):
		if i not in error_cams:
			available.append(i)

	if available.is_empty():
		return

	available.shuffle()
	var count: int = randi_range(1, min(3, available.size()))

	for i in range(count):
		var cam_idx: int = available[i]
		error_cams.append(cam_idx)

	_update_noise_visibility()

func _clear_error(cam_idx: int) -> void:
	get_node("cam_btns/cam_" + str(cam_idx) + "/ColorRect/error_anim").hide()
	error_cams.erase(cam_idx)
	_update_noise_visibility()

func _on_panel_2_mouse_entered() -> void:
	CamGlobal.cam_interface_back.emit()
