extends Camera3D

@export var tilt_amount: float = 2.0
@export var smoothing: float = 5.0

var origin_rotation: Vector3
var cam_movement: bool = false
var _target_y: float = 0.0

func _ready() -> void:
	origin_rotation = rotation_degrees
	_target_y = origin_rotation.y

func _process(delta: float) -> void:
	if !cam_movement:
		return
	
	var input_x := Input.get_axis("ui_right", "ui_left")  # -1 left, 1 right
	_target_y = origin_rotation.y + (input_x * tilt_amount)
	rotation_degrees.y = lerp(rotation_degrees.y, _target_y, delta * smoothing)

func cam_mov(mov_toggle: bool) -> void:
	cam_movement = mov_toggle
	if not mov_toggle:
		_target_y = origin_rotation.y  # snap back to center when disabled
