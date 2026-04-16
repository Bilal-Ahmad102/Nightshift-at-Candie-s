extends Control

@onready var cam_btns: Control = $cam_btns

var light_blips: Array[ColorRect] = []
var current_cam: int = 0
var _blink_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	connect_signals()
	for cam_btn in cam_btns.get_children():
		var blip: ColorRect = cam_btn.get_child(0)
		blip.color.a = 0.0
		light_blips.append(blip)

	_start_blip(0)
	CamGlobal.cam_switched.connect(_on_cam_switched)

func connect_signals() -> void:
	for cam_texture: TextureRect in cam_btns.get_children():
		cam_texture.gui_input.connect(_on_cam_texture_click.bind(cam_texture.name))
		cam_texture.mouse_entered.connect(_on_mouse_entered.bind(cam_texture.name))
func _on_mouse_entered(cam_name):
	pass
func _on_cam_texture_click(event: InputEvent, cam_name: String) -> void:

	#if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
	CamGlobal.cam_texture_clicked.emit((int(cam_name.split("_")[-1]))-1)
	#print("Click, ",(int(cam_name.split("_")[-1]))-1)
	#$Label.text = str("Click, ",(int(cam_name.split("_")[-1]))-1)
		
func _on_cam_switched(prev_cam: int, next_cam: int) -> void:
	# Reset the previous blip explicitly before starting the new one
	if prev_cam > 0 and prev_cam - 1 < light_blips.size():
		light_blips[prev_cam - 1].color.a = 0.0

	current_cam = next_cam
	_start_blip(next_cam - 1)


func _start_blip(idx: int) -> void:
	if idx < 0 or idx >= light_blips.size():
		return

	if _blink_tween and _blink_tween.is_valid():
		_blink_tween.kill()

	var blip: ColorRect = light_blips[idx]
	# Reset alpha so there's no leftover state from a killed tween
	blip.color.a = 0.0

	# FNaF-style uneven blink: fast on, slow off
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_property(blip, "color:a", 1.0, 0.05)
	_blink_tween.tween_interval(0.15)
	_blink_tween.tween_property(blip, "color:a", 0.0, 0.05)
	_blink_tween.tween_interval(0.35)


func _on_panel_2_mouse_entered() -> void:
	CamGlobal.cam_interface_back.emit()
