extends Node3D


signal jumpscare_requested(animatronic_id: String)

const ANIMATRONIC_ID := "Bronnie"

@export var left_door_route : Node
@export var right_door_route : Node

@onready var _move_timer: Timer = %move_timer

enum State { IDLE, MOVING, IN_OFFICE, RETURNING }

const ROUTE_LEFT_DOOR = ["CAM_09", "CAM_08", "CAM_07", "CAM_06"]
const ROUTE_RIGHT_DOOR = ["CAM_09", "CAM_02", "CAM_03", "CAM_04"]

var cam_positions: Dictionary = {}
var current_state: State = State.IDLE
var current_cam: String = "CAM_09"
var current_route: Array = []
var route_index: int = 0

signal bronnie_appeared
signal bronnie_left

func _ready() -> void:
	_move_timer.timeout.connect(_on_move_timer)
	NightManager.night_started.connect(_on_night_started)
	NightManager.night_ended.connect(_on_night_ended)

func _on_night_ended(night: int, success: bool) -> void:
	_reset_position()

func _on_night_started(night: int) -> void:
	if NightManager.is_animatronic_active("Bronnie"):
		_move_timer.start(get_move_interval())

func _fill_cam_positions(is_right: bool) -> void:
	var markers: Array
	if is_right:
		markers = right_door_route.get_children()
	else:
		markers = left_door_route.get_children()
	var i: int = 0
	for marker: Marker3D in markers:
		if is_right:
			cam_positions[ROUTE_RIGHT_DOOR[i]] = marker
		else:
			cam_positions[ROUTE_LEFT_DOOR[i]] = marker
		i += 1

func move_to_cam(cam_id: String) -> void:
	var marker = cam_positions.get(cam_id)
	if marker:
		global_position = marker.global_position
		global_rotation = marker.global_rotation
		current_cam = cam_id

func get_move_interval() -> float:
	var base = AnimatronicConfig.get_value("Bronnie", "move_interval_base", 8.0)
	var min_v = AnimatronicConfig.get_value("Bronnie", "move_interval_min", 2.0)
	var mult = AnimatronicConfig.get_value("Bronnie", "ai_level_multiplier", 1.2)
	var ai_level = NightManager.get_ai_level("Bronnie")
	return max(min_v, base - (ai_level * mult))


func begin_route() -> void:
	var is_right: bool = randf() < 0.5
	if is_right:
		current_route = ROUTE_RIGHT_DOOR
	else:
		current_route = ROUTE_LEFT_DOOR
	_fill_cam_positions(is_right)
	route_index = 0
	current_state = State.MOVING
	_move_timer.start(get_move_interval())

func _on_move_timer() -> void:
	match current_state:
		State.IDLE:
			begin_route()
		State.MOVING:
			_advance_route()
		State.RETURNING:
			_return_to_start()

func _advance_route() -> void:
	route_index += 1
	if route_index >= current_route.size():
		_attempt_attack()
		return
	var next_cam = current_route[route_index]
	move_to_cam(next_cam)
	_move_timer.start(get_move_interval())

func _attempt_attack() -> void:
	# Bronnie forces the door open, no door check
	current_state = State.IN_OFFICE
	bronnie_appeared.emit()

func on_mask_equipped() -> void:
	if current_state != State.IN_OFFICE:
		return
	bronnie_left.emit()
	current_state = State.RETURNING
	_move_timer.start(AnimatronicConfig.get_value("Bronnie", "return_delay", 3.0))

func _reset_position() -> void:
	move_to_cam("CAM_09")
	current_state = State.IDLE

func _return_to_start() -> void:
	move_to_cam("CAM_09")
	current_state = State.IDLE
	_move_timer.start(get_move_interval())

func _trigger_jumpscare() -> void:
	jumpscare_requested.emit(ANIMATRONIC_ID)
