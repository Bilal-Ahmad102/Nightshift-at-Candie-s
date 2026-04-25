extends MeshInstance3D

@export var door: MeshInstance3D
@export var door_id : String
@onready var area_3d: Area3D = $Area3D

var is_closed: bool = false

func _ready() -> void:
	area_3d.input_event.connect(_on_area_input)

func _on_area_input(_camera, event: InputEvent, _pos, _normal, _idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_closed:
			open_door()
			DoorManager.open_door(door_id)
		else:
			close_door()
			DoorManager.close_door(door_id)

func close_door() -> void:
	is_closed = true
	var tween = door.create_tween()
	tween.tween_property(door, "position:y", 1.0, 0.3)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_CUBIC)

func open_door() -> void:
	is_closed = false
	var tween = door.create_tween()
	tween.tween_property(door, "position:y", 50.0, 0.5)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_BACK)
