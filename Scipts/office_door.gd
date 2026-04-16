extends MeshInstance3D

@export var door_id: String = "left"  # set to "left" or "right" in Inspector

@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	DoorManager.door_state_changed.connect(_on_door_state_changed)

func _on_door_state_changed(id: String, is_closed: bool) -> void:
	if id != door_id:
		return
	if is_closed:
		anim.play("door_close")
	else:
		anim.play("door_open")
