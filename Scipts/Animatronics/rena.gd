extends Node3D

signal jumpscare_requested(animatronic_id: String)

const ANIMATRONIC_ID := "Rena"

@export var cam11_route : Node       # Marker3D children: state1, state2, state3
@export var window_route : Node      # CAM_11 → CAM_05 → window
@export var right_door_route : Node  # CAM_11 → CAM_02 → CAM_03 → CAM_04

@onready var _move_timer: Timer = %move_timer
@onready var anim_player: AnimationPlayer = $AnimationPlayer

enum State { IDLE, ESCALATING, MOVING, ATTACKING, RETURNING }

const ROUTE_WINDOW    = ["CAM_11", "CAM_05", "WINDOW"]
const ROUTE_RIGHT_DOOR = ["CAM_11", "CAM_02", "CAM_03", "CAM_04"]

# CAM_11 has 3 internal positions (state1=restrained, state2=facing cam, state3=center)
const CAM11_STATES = ["cam11_state1", "cam11_state2", "cam11_state3"]

var cam_positions: Dictionary = {}
var current_state: State = State.IDLE
var current_cam: String = "CAM_11"
var current_route: Array = []
var route_index: int = 0
var cam11_escalation_index: int = 0  # tracks which of the 3 CAM_11 poses she's in

func _ready() -> void:
	_move_timer.timeout.connect(_on_move_timer)
	NightManager.night_started.connect(_on_night_started)
	_fill_cam_positions()

	# Place her at CAM_11 state 1 immediately
	move_to_cam("cam11_state1")
	GameManger.register_animatronic(self)
	
func _on_night_started(night: int) -> void:
	if NightManager.is_animatronic_active("Rena"):
		current_state = State.ESCALATING
		_move_timer.start(get_move_interval())

func _fill_cam_positions() -> void:
	# CAM_11 internal positions
	var cam11_markers = cam11_route.get_children()
	for i in cam11_markers.size():
		cam_positions[CAM11_STATES[i]] = cam11_markers[i]

	# Window route
	var win_markers = window_route.get_children()
	for i in win_markers.size():
		cam_positions[ROUTE_WINDOW[i]] = win_markers[i]

	# Right door route (skip index 0 — CAM_11 already filled above)
	var door_markers = right_door_route.get_children()
	for i in door_markers.size():
		cam_positions[ROUTE_RIGHT_DOOR[i]] = door_markers[i]

func move_to_cam(cam_id: String) -> void:
	match cam_id:
		"cam11_state1": anim_player.play("pose_1")
		"cam11_state2": anim_player.play("pose_2")
		"cam11_state3": anim_player.play("pose_3")

	var marker = cam_positions.get(cam_id)
	if marker:
		global_position = marker.global_position
		global_rotation = marker.global_rotation
		current_cam = cam_id

func get_move_interval() -> float:
	var base = AnimatronicConfig.get_value("Rena", "move_interval_base", 8.0)
	var min_v = AnimatronicConfig.get_value("Rena", "move_interval_min", 2.0)
	var mult = AnimatronicConfig.get_value("Rena", "ai_level_multiplier", 1.2)
	var ai_level = NightManager.get_ai_level("Rena")
	return max(min_v, base - (ai_level * mult))
	# Or, for a flat value: return AnimatronicConfig.get_value("Bronnie", "move_interval", 3.0)

func _on_move_timer() -> void:
	match current_state:
		State.ESCALATING:
			_escalate_cam11()
		State.MOVING:
			_advance_route()
		State.RETURNING:
			_return_to_cam11()

func _escalate_cam11() -> void:
	cam11_escalation_index += 1

	if cam11_escalation_index < CAM11_STATES.size():
		# Advance to next pose within CAM_11
		move_to_cam(CAM11_STATES[cam11_escalation_index])
		_move_timer.start(get_move_interval())
	else:
		# She's left CAM_11 — pick a route
		_begin_route()

func _begin_route() -> void:
	var window_chance = AnimatronicConfig.get_value("Rena", "window_route_chance", 0.5)
	if randf() < window_chance:
		current_route = ROUTE_WINDOW
	else:
		current_route = ROUTE_RIGHT_DOOR


	route_index = 0
	current_state = State.MOVING
	move_to_cam(current_route[route_index])
	_move_timer.start(get_move_interval())

func _advance_route() -> void:
	route_index += 1
	if route_index >= current_route.size():
		_attempt_attack()
		return
	move_to_cam(current_route[route_index])
	_move_timer.start(get_move_interval())

func _attempt_attack() -> void:
	if current_route == ROUTE_WINDOW:
		if DoorManager.is_window_closed():
			# Blocked — play bang + flash, then return
			_on_window_blocked()
		else:
			_trigger_jumpscare()
	else:
		# Right door
		if DoorManager.is_door_closed("right"):
			current_state = State.RETURNING
			_move_timer.start(3.0)
		else:
			_trigger_jumpscare()

func _on_window_blocked() -> void:
	# TODO: signal to GameManager to play bang SFX + stop light flash
	current_state = State.RETURNING
	_move_timer.start(3.0)   # brief pause before returning, matching the "lights stop" beat

func _return_to_cam11() -> void:
	# Reset fully back to CAM_11 state 1
	cam11_escalation_index = 0
	move_to_cam(CAM11_STATES[0])
	current_state = State.ESCALATING
	_move_timer.start(get_move_interval())

func _trigger_jumpscare() -> void:
	jumpscare_requested.emit(ANIMATRONIC_ID)
