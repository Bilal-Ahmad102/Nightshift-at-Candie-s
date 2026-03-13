extends Control

@onready var cam_btns: Control = $cam_btns
var light_blips: Array[ColorRect] = []
var current_cam: int = 0
var _blink_tween: Tween

func _ready() -> void:
	for cam_btn in cam_btns.get_children():
		cam_btn.get_child(0).color.a = 0.0
		light_blips.append(cam_btn.get_child(0))
	_start_blip(0)
	CamGlobal.cam_switched.connect(_on_cam_switched)

func _on_cam_switched(prev_cam: int, next_cam: int) -> void:
	#print(prev_cam," ",next_cam)
	# Turn off previous cam's blip
	if prev_cam > 0 and prev_cam - 1 < light_blips.size():
		light_blips[prev_cam - 1].color.a = 0.0
	current_cam = next_cam
	_start_blip(next_cam - 1)  # adjust if your cam index is 0-based

func _start_blip(idx: int) -> void:
	if idx < 0 or idx >= light_blips.size():
		return

	# Kill any existing tween
	if _blink_tween and _blink_tween.is_valid():
		_blink_tween.kill()

	var blip: ColorRect = light_blips[idx]
	_blink_tween = create_tween().set_loops()

	# Fast flicker: on for 0.15s, off for 0.35s — FNaF-style uneven blink
	_blink_tween.tween_property(blip, "color:a", 1.0, 0.05)
	_blink_tween.tween_interval(0.15)
	_blink_tween.tween_property(blip, "color:a", 0.0, 0.05)
	_blink_tween.tween_interval(0.35)
