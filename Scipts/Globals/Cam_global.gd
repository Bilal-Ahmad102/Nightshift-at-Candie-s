extends Node

@warning_ignore("unused_signal")
signal cam_switched(prev_cam: int, next_cam: int)

@warning_ignore("unused_signal")
signal cam_interface_back

@warning_ignore("unused_signal")
signal cam_interface_up


@warning_ignore("unused_signal")
signal cam_texture_clicked(cam_num: int)

@warning_ignore("unused_signal")
signal night3_cams_updated(cams: Array)

@warning_ignore("unused_signal")
signal add_cam_error(cam)

var current_camera_opened : int = 0
var error_cams : Array = []

func _ready() -> void:
	cam_switched.connect(_on_camera_swicted)
	
func _on_camera_swicted(cur_cam: int, prev_cam:int):
	current_camera_opened = cur_cam


func get_current_open_cam() -> int:
	return current_camera_opened

func add_error_cam(cam):
	pass
