extends MeshInstance3D
#
#@export var window: MeshInstance3D
#@onready var area_3d: Area3D = $Area3D
#
#var is_closed: bool = false
#
#func _ready() -> void:
	#area_3d.input_event.connect(_on_area_input)
#
#func _on_area_input(_camera, event: InputEvent, _pos, _normal, _idx) -> void:
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		#if is_closed:
			#open_door()
		#else:
			#close_door()
#
#func close_door() -> void:
	#is_closed = true
	#var tween = window.create_tween()
	#tween.tween_property(window, "position:y", 1.0, 0.3)\
		#.set_ease(Tween.EASE_IN)\
		#.set_trans(Tween.TRANS_CUBIC)
#
#func open_door() -> void:
	#is_closed = false
	#var tween = window.create_tween()
	#tween.tween_property(window, "position:y", 50.0, 0.5)\
		#.set_ease(Tween.EASE_OUT)\
		#.set_trans(Tween.TRANS_BACK)
