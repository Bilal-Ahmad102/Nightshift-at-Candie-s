extends Node3D

# Emitted when this animatronic catches the player.
# GameManger listens to this and shows the jumpscare overlay.
signal jumpscare_requested(animatronic_id: String)

const ANIMATRONIC_ID := "Dave"

@export var left_door_route_1 : Node
@export var left_door_route_2 : Node
@export var right_door_route : Node
@onready var _move_timer: Timer = %move_timer

enum State { IDLE, MOVING, ATTACKING, RETURNING }

const ROUTE_LEFT_DOOR     = ["CAM_01", "CAM_02", "CAM_05", "CAM_08", "CAM_07", "CAM_06"]
const ROUTE_LEFT_DOOR_ALT = ["CAM_01", "CAM_02", "CAM_09", "CAM_08", "CAM_07", "CAM_06"]
const ROUTE_RIGHT_DOOR    = ["CAM_01", "CAM_02", "CAM_05", "CAM_03", "CAM_04"]

var cam_positions: Dictionary = {}
var current_state: State = State.IDLE
var current_cam: String = "CAM_01"
var current_route: Array = []
var route_index: int = 0


func _ready() -> void:
	_move_timer.timeout.connect(_on_move_timer)
	NightManager.night_started.connect(_on_night_started)
	NightManager.night_ended.connect(_on_night_ended)
	
	GameManger.register_animatronic(self)


func _on_night_ended(night: int, success: bool):
	_reset_position()


func _on_night_started(night: int) -> void:
	if NightManager.is_animatronic_active(ANIMATRONIC_ID):
		_move_timer.start(get_move_interval())

	
func _fill_cam_positions(is_path_3: bool, _nine: bool):
	var markers: Array
	if is_path_3:
		markers = right_door_route.get_children()
	elif _nine:
		markers = left_door_route_1.get_children()
	else:
		markers = left_door_route_2.get_children()
	var i: int = 0
	for marker: Marker3D in markers:
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
		var previous_cam := current_cam
		GameManger.animatronic_moved.emit(previous_cam, cam_id)
		await  get_tree().create_timer(1).timeout
		
		global_position = marker.global_position
		global_rotation = marker.global_rotation
		current_cam = cam_id


func get_move_interval() -> float:
	var base = AnimatronicConfig.get_value("Dave", "move_interval_base", 8.0)
	var min_v = AnimatronicConfig.get_value("Dave", "move_interval_min", 2.0)
	var mult = AnimatronicConfig.get_value("Dave", "ai_level_multiplier", 1.2)
	var ai_level = NightManager.get_ai_level("Dave")
	return max(min_v, base - (ai_level * mult))


func begin_route() -> void:
	var chances = AnimatronicConfig.get_value("Dave", "route_chances", {})
	var left = chances.get("left_door", 0.33)
	var left_alt = chances.get("left_door_alt", 0.33)
	var roll = randf()
	var is_path_3 := false
	var is_nine := false
	if roll < left:
		current_route = ROUTE_LEFT_DOOR
	elif roll < left + left_alt:
		is_nine = true
		current_route = ROUTE_LEFT_DOOR_ALT
	else:
		is_path_3 = true
		current_route = ROUTE_RIGHT_DOOR

	_fill_cam_positions(is_path_3, is_nine)
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
	# Stop moving — GameManger will show the overlay and (probably) end the night.
	_move_timer.stop()
	current_state = State.ATTACKING
	jumpscare_requested.emit(ANIMATRONIC_ID)
