extends Camera3D

@export var tilt_amount: float = 2.0
@export var smoothing: float = 5.0
@onready var button_door_left: MeshInstance3D = %ButtonDoorLeft
@onready var button_door_right: MeshInstance3D = %ButtonDoorRight

var origin_rotation: Vector3
var cam_movement: bool = false
var _target_y: float = 0.0

func _ready() -> void:
	origin_rotation = rotation_degrees
	_target_y = origin_rotation.y

# Camera3D script - _process
func _process(delta: float) -> void:
	if !cam_movement:
		return
	
	var input_x := Input.get_axis("right", "left")
	_target_y = origin_rotation.y + (input_x * tilt_amount)
	rotation_degrees.y = lerp(rotation_degrees.y, _target_y, delta * smoothing)
	
	# use threshold instead of exact == 1/-1
	button_door_left.looking(input_x > 0.5)
	button_door_right.looking(input_x < -0.5)

func cam_mov(mov_toggle: bool) -> void:
	cam_movement = mov_toggle
	if not mov_toggle:
		_target_y = origin_rotation.y  # snap back to center when disabled
