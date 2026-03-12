extends Node3D


@onready var cam_info: Label = $"../../Cameras_info"

var cameras: Array = []
var current_index: int = 0

func _ready() -> void:
	cameras = get_children()
	switch_to(0)
	for i in range(cameras.size()):
		cameras[i].cam_id = i

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
	current_index = index
	for i in cameras.size():
		cameras[i].current = (i == current_index)
	
	# Display current room info
	var cam = cameras[current_index]
	cam_info.text = "CAM %d - %s" % [cam.cam_id, cam.room_name]
	print("CAM %d - %s" % [cam.cam_id, cam.room_name])
