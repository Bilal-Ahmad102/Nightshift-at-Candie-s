extends Node3D

@export var movement_positions: Node 
@onready var _gaze_timer: Timer = %gaze_timer
@onready var _warning_timer: Timer = %warning_timer
@onready var _marker_timer: Timer = %marker_timer
@onready var gaze_btn: Control = $Gaze_btn
@onready var realfreddy_warning: AudioStreamPlayer = $RealfreddyWarning

enum State { INACTIVE, WARNING, IN_OFFICE, LEAVING }

var current_state: State = State.INACTIVE
var gaze_count: int = 0
var gaze_required: int = 10
var positions_markers: Array = []
var current_marker_index: int = 0

var original_pos = Vector3(0,0,-200)

signal fredbear_appeared
signal fredbear_left

func _ready() -> void:

	_gaze_timer.timeout.connect(_on_gaze_timer)
	_warning_timer.timeout.connect(_on_warning_timer)
	_marker_timer.timeout.connect(_on_marker_timer)

	NightManager.night_started.connect(_on_night_started)
	NightManager.night_ended.connect(_on_night_ended)

	fredbear_appeared.connect(_on_fredbear_appeared)
	fredbear_left.connect(_on_fredbear_left)

	positions_markers = movement_positions.get_children()

	gaze_btn.visible = false
	gaze_btn.on_completed = _repel

func _on_fredbear_appeared() -> void:
	gaze_btn.visible = true

func _on_fredbear_left() -> void:
	gaze_btn.visible = false

func _trigger_jumpscare() -> void:
	gaze_btn.visible = false
	_gaze_timer.stop()
	_marker_timer.stop()
	print("TheRealFredbear jumpscare!")
	
	
func _on_night_started(night: int) -> void:
	#if NightManager.is_animatronic_active("TheRealFredbear"):
	_schedule_next_warning()

func _on_night_ended(night: int, success: bool) -> void:
	_reset()

func _schedule_next_warning() -> void:
	current_state = State.INACTIVE
	_warning_timer.wait_time = get_warning_interval()
	_warning_timer.start()

func _on_warning_timer() -> void:
	_play_trumpet_sound()
	current_state = State.WARNING
	_gaze_timer.wait_time = 3.0
	_gaze_timer.start()

func _on_gaze_timer() -> void:

	match current_state:
		State.WARNING:
			_enter_office()
		State.IN_OFFICE:
			_trigger_jumpscare()

func _enter_office() -> void:
	current_state = State.IN_OFFICE
	gaze_count = 0
	gaze_required = _get_gaze_required()
	current_marker_index = 0
	fredbear_appeared.emit()

	_move_to_current_marker()
	_gaze_timer.wait_time = get_gaze_deadline()
	_gaze_timer.start()
	_marker_timer.wait_time = 2.0
	_marker_timer.start()

func _on_marker_timer() -> void:
	match current_state:
		State.IN_OFFICE:
			current_marker_index += 1
			if current_marker_index >= positions_markers.size():
				_trigger_jumpscare()
				return
			_move_to_current_marker()
			_marker_timer.start()
		State.LEAVING:
			_walk_back()

func _move_to_current_marker() -> void:
	if current_marker_index >= positions_markers.size():
		return
	var marker: Marker3D = positions_markers[current_marker_index]
	global_position = marker.global_position
	global_rotation = marker.global_rotation

func on_gaze_button_pressed() -> void:
	if current_state != State.IN_OFFICE:
		return
	gaze_count += 1
	if gaze_count >= gaze_required:
		_repel()

func _repel() -> void:
	current_state = State.LEAVING
	_gaze_timer.stop()
	_marker_timer.stop()
	fredbear_left.emit()
	_walk_back()

func _walk_back() -> void:
	if current_marker_index <= 0:
		_on_walk_back_finished()
		return
	current_marker_index -= 1
	var marker: Marker3D = positions_markers[current_marker_index]
	global_position = marker.global_position
	global_rotation = marker.global_rotation
	_marker_timer.wait_time = 0.3
	_marker_timer.start()

func _on_walk_back_finished() -> void:
	current_marker_index = 0
	
	_schedule_next_warning()

func _play_trumpet_sound() -> void:
	realfreddy_warning.play()


func _reset() -> void:
	current_state = State.INACTIVE
	gaze_count = 0
	current_marker_index = 0
	_gaze_timer.stop()
	_warning_timer.stop()
	_marker_timer.stop()

func get_warning_interval() -> float:
	var ai_level := NightManager.get_ai_level("TheRealFredbear")
	return 2
	
	#return max(5.0, 45.0 - (ai_level * 3.0))

func get_gaze_deadline() -> float:
	var ai_level := NightManager.get_ai_level("TheRealFredbear")
	return 10
	return max(4.0, 10.0 - (ai_level * 0.6))

func _get_gaze_required() -> int:
	var ai_level := NightManager.get_ai_level("TheRealFredbear")
	return 8 + ai_level
