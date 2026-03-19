extends Node3D

@onready var cam_info: Label = $"../../Cameras_info"
@onready var sub_viewport: SubViewport = $SubViewport
@onready var main_camera: Camera3D = %Main_camera
@onready var shared_cam: Camera3D = $SubViewport/Camera3D
@onready var camera_interface: Control = %camera_interface

var cameras: Array = []
var current_index: int = 0
var is_monitor_active: bool = false
var active_camera: Camera3D = null



func _ready() -> void:
	CamGlobal.cam_interface_back.connect(_on_cam_interface_back)
	CamGlobal.cam_texture_clicked.connect(_on_cam_texture_clicked)
	# Filter by type instead of reference comparison — more robust
	cameras = get_children().filter(func(c): return c is Camera3D)
	shared_cam.current = true
	
	switch_to(0)
func _on_cam_texture_clicked(cam_num:int):
	switch_to(cam_num)
func _input(event: InputEvent) -> void:
	# Only cycle cameras when the monitor UI is open
	if not is_monitor_active:
		return
	if event.is_action_pressed("ui_right"):
		next_camera()
	elif event.is_action_pressed("ui_left"):
		prev_camera()


func next_camera() -> void:
	switch_to((current_index + 1) % cameras.size())


func prev_camera() -> void:
	switch_to((current_index - 1 + cameras.size()) % cameras.size())


func switch_to(index: int) -> void:
	# Emit BEFORE changing current_index so prev_cam is the actual previous cam
	var prev_id: int = cameras[current_index].cam_id
	var next_id: int = cameras[index].cam_id
	current_index = index
	CamGlobal.cam_switched.emit(prev_id, next_id)

	var target_cam: Camera3D = cameras[current_index]
	if is_monitor_active:
		_apply_in_monitor_switch(target_cam)
	else:
		_apply_cam_switch(target_cam)

	cam_info.text = "CAM %d - %s" % [target_cam.cam_id, target_cam.room_name]


func _apply_cam_switch(target_cam: Camera3D) -> void:
	active_camera = target_cam
	copy_properties(target_cam)

func _apply_in_monitor_switch(target_cam: Camera3D):
	active_camera.current = false
	active_camera = target_cam
	active_camera.current = true

func activate_camera_monitor() -> void:
	is_monitor_active = true
	main_camera.current = false
	camera_interface.mouse_filter = Control.MOUSE_FILTER_PASS


func deactivate_camera_monitor() -> void:
	is_monitor_active = false
	main_camera.current = true
	camera_interface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy_properties(active_camera)

func _on_cam_interface_back() -> void:
	deactivate_camera_monitor()
func copy_properties(src: Camera3D) -> void:
	shared_cam.global_transform     = src.global_transform
	shared_cam.fov                  = src.fov
	shared_cam.near                 = src.near
	shared_cam.far                  = src.far
