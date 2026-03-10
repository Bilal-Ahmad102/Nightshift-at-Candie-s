extends Camera3D

@export var room_name: String = "Unknown Room"
@export var room_description: String = ""
@export var cam_id: int = 0
@export var is_indoor: bool = true

func _ready() -> void:
	if room_name == "Unknown Room":
		room_name = name
