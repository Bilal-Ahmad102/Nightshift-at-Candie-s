extends MeshInstance3D

@export var is_window: bool = false

@export var door: MeshInstance3D
@export var door_id : String

@onready var hint_label: Label3D = $hint_label

var is_closed: bool = false
var is_player_looking : bool = false




func _ready() -> void:
	if !door:
		door = self
func _input(event: InputEvent) -> void:
	if !is_player_looking: return
	if event.is_action_pressed("E") :
		if is_closed:
			open_door()
			DoorManager.open_door(door_id)
		else:
			close_door()
			DoorManager.close_door(door_id)





func looking(val):
	hint_label.visible = val
	is_player_looking = val

func close_door() -> void:
	is_closed = true
	hint_label.text = "Press E to open"  # closed = offer to open ✓
	var tween = door.create_tween()
	if !is_window:
		tween.tween_property(door, "position:y", 1.0, 0.3)\
			.set_ease(Tween.EASE_IN)\
			.set_trans(Tween.TRANS_CUBIC)
	else:
		tween.tween_property(door, "position:y", 31.0, 0.3)\
			.set_ease(Tween.EASE_IN)\
			.set_trans(Tween.TRANS_CUBIC)
			
func open_door() -> void:
	is_closed = false
	hint_label.text = "Press E to close"  # open = offer to close ✓
	var tween = door.create_tween()
	if !is_window:
		tween.tween_property(door, "position:y", 50.0, 0.5)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_BACK)
	else:
		tween.tween_property(door, "position:y", 60, 0.5)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_BACK)
