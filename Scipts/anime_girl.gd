extends Node3D

@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var sprite_3d_2: Sprite3D = $Sprite3D2
@onready var sprite_3d_3: Sprite3D = $Sprite3D3
@onready var sprite_3d_4: Sprite3D = $Sprite3D4
@onready var sprite_3d_5: Sprite3D = $Sprite3D5
@onready var sprite_3d_6: Sprite3D = $Sprite3D6
@onready var sprite_3d_7: Sprite3D = $Sprite3D7
@onready var sprite_3d_8: Sprite3D = $Sprite3D8

var frames: Array[Sprite3D] = []
var current_frame: int = 0
var fps: float = 8.0
var timer: float = 0.0

func _ready() -> void:
	frames = [
		sprite_3d, sprite_3d_2, sprite_3d_3, sprite_3d_4,
		sprite_3d_5, sprite_3d_6, sprite_3d_7, sprite_3d_8
	]
	_show_frame(0)

func _process(delta: float) -> void:
	timer += delta
	if timer >= 1.0 / fps:
		timer = 0.0
		current_frame = (current_frame + 1) % frames.size()
		_show_frame(current_frame)

func _show_frame(index: int) -> void:
	for i in frames.size():
		frames[i].visible = (i == index)
