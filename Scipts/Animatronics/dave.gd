extends Node3D

@export var left_door_route_1 : Node 
@export var left_door_route_2 : Node 
@export var right_door_route : Node 

@onready var _move_timer: Timer = %move_timer

enum State { IDLE, MOVING, ATTACKING, RETURNING }
const ROUTE_LEFT_DOOR = ["CAM_01", "CAM_02", "CAM_05", "CAM_08", "CAM_07", "CAM_06"]
const ROUTE_LEFT_DOOR_ALT = ["CAM_01", "CAM_02", "CAM_09", "CAM_08", "CAM_07", "CAM_06"]
const ROUTE_RIGHT_DOOR = ["CAM_01", "CAM_02", "CAM_05", "CAM_03", "CAM_04"]

var cam_positions: Dictionary = {}


var current_state: State = State.IDLE
var current_cam: String = "CAM_01"
var current_route: Array = []
var route_index: int = 0


func _ready() -> void:
	_move_timer.timeout.connect(_on_move_timer)

	NightManager.night_started.connect(_on_night_started)
	NightManager.night_ended.connect(_on_night_ended)
	# do NOT start the timer here anymore

func _on_night_ended(night: int , success: bool):
	_reset_position()

func _on_night_started(night: int) -> void:
	if NightManager.is_animatronic_active("Dave"):
		_move_timer.start(get_move_interval())
func _fill_cam_positions(is_path_3:bool,_nine:bool):
	var markers: Array
	if is_path_3:
		markers = right_door_route.get_children()
	elif _nine:
		markers = left_door_route_1.get_children()
	else:
		markers = left_door_route_2.get_children()

	var i :int  = 0
	for marker:Marker3D in markers:
		if is_path_3:
			cam_positions[ROUTE_RIGHT_DOOR[i]] = marker
		elif _nine:
			cam_positions[ROUTE_LEFT_DOOR_ALT[i]] = marker
		
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
	# faster on higher nights / higher hours
	return 3
	var base = 8.0
	var ai_level = NightManager.get_ai_level("Dave")
	return max(2.0, base - (ai_level * 1.2))

func begin_route() -> void:
	var roll = randf()
	var is_path_3 : bool = false
	var is_nine : bool =  false
	if roll < 0.33:
		current_route = ROUTE_LEFT_DOOR       # via CAM_05
	elif roll < 0.66:
		is_nine = true
		current_route = ROUTE_LEFT_DOOR_ALT   # via CAM_09
	else:
		is_path_3 = true
		current_route = ROUTE_RIGHT_DOOR

#
	#$"../../Label".text = "Path: "+ str(current_route)
	_fill_cam_positions(is_path_3,is_nine)
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
	var door_id = "left" if current_route == ROUTE_LEFT_DOOR else "right"
	# check if door is closed
	if DoorManager.is_door_closed(door_id):
		# blocked — return to start
		current_state = State.RETURNING
		_move_timer.start(3.0)
	else:
		# attack!
		_trigger_jumpscare()

func _reset_position():
	move_to_cam("CAM_01")
	current_state = State.IDLE

func _return_to_start() -> void:
	move_to_cam("CAM_01")
	current_state = State.IDLE
	_move_timer.start(get_move_interval())
	GameManger.can_dave_cam_error = true

func _trigger_jumpscare() -> void:
	print("Dave jumpscare!")
	# TODO: signal to GameManager
