extends Node3D

@onready var cam_info: Label = $"../../Cameras_info"
@onready var sub_viewport: SubViewport = $SubViewport
@onready var main_camera: Camera3D = %Main_camera
var cameras: Array = []
var current_index: int = 0
@onready var shared_cam: Camera3D = $SubViewport/Camera3D

enum SwitchMode {
	VIEWPORT,   # renders into SubViewport (monitor feed)
	DIRECT      # makes camera current directly (player view)
}

@export var switch_mode: SwitchMode = SwitchMode.VIEWPORT

func _ready() -> void:
	cameras = get_children().filter(func(c): return c != sub_viewport)
	for cam in cameras:
		cam.current = false
	switch_to(0)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_right"):
		next_camera()
	elif event.is_action_pressed("ui_left"):
		prev_camera()

func next_camera() -> void:
	switch_to((current_index + 1) % cameras.size())

func prev_camera() -> void:
	switch_to((current_index - 1 + cameras.size()) % cameras.size())

func switch_to(index: int) -> void:
	CamGlobal.cam_switched.emit(cameras[current_index].cam_id, cameras[index].cam_id)
	current_index = index
	var target_marker = cameras[current_index]

	match switch_mode:
		SwitchMode.VIEWPORT:
			_apply_to_shared(target_marker)
		SwitchMode.DIRECT:
			_apply_direct(target_marker)

	cam_info.text = "CAM %d - %s" % [target_marker.cam_id, target_marker.room_name]
	print("CAM %d - %s" % [target_marker.cam_id, target_marker.room_name])

func _apply_to_shared(target_marker: Camera3D) -> void:
	shared_cam.global_transform = target_marker.global_transform
	shared_cam.projection = target_marker.projection
	shared_cam.fov = target_marker.fov
	shared_cam.size = target_marker.size
	shared_cam.near = target_marker.near
	shared_cam.far = target_marker.far
	shared_cam.cull_mask = target_marker.cull_mask
	shared_cam.h_offset = target_marker.h_offset
	shared_cam.v_offset = target_marker.v_offset
	shared_cam.doppler_tracking = target_marker.doppler_tracking
	shared_cam.environment = target_marker.environment
	shared_cam.attributes = target_marker.attributes

func _apply_direct(target_marker: Camera3D) -> void:
	for cam in cameras:
		cam.current = false
	target_marker.current = true

func activate_camera_monitor() -> void:
	switch_mode = SwitchMode.DIRECT
	main_camera.current = false
	shared_cam.current = true

func deactivate_camera_monitor() -> void:
	switch_mode = SwitchMode.VIEWPORT
	shared_cam.current = false
	main_camera.current = true
