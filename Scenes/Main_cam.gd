extends Camera3D

@export var tilt_amount: float = 2.0
@export var smoothing: float = 5.0

var origin_rotation: Vector3

func _ready() -> void:
	origin_rotation = rotation_degrees

func _process(delta: float) -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var mouse_pos = get_viewport().get_mouse_position()
	
	# Distance from center, normalized by half-width
	# center=0.0, right edge=1.0, left edge=-1.0
	var half_width = viewport_size.x / 2.0
	var offset_from_center = mouse_pos.x - half_width
	var normalized_x = offset_from_center / half_width  # -1.0 to 1.0
	
	var target_y = origin_rotation.y - (normalized_x * tilt_amount)
	rotation_degrees.y = lerp(rotation_degrees.y, target_y, delta * smoothing)
