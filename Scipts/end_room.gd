extends Node3D

# ── Look-around points ──────────────────────────────────────────────────────
@export_group("Look Points")
@export var look_points: Array[Marker3D] = []
@export var dwell_time: float = 1.6
@export var wander_speed: float = 0.9
@export var wander_ease: float = -2.0

# ── Final lock-on target ─────────────────────────────────────────────────────
@export_group("Lock Target")
@export var lock_target: Node3D
@export var lock_offset: Vector3 = Vector3(0, 1.65, 0)
@export var lock_speed: float = 2.4
@export var lock_ease: float = -2.0
@export var lock_threshold_deg: float = 1.8

# ── Eye open effect ──────────────────────────────────────────────────────────
@export_group("Eye Open")
@export var eye_open_duration: float = 1.4
@export var eye_open_tilt_deg: float = 18.0
@export var eye_open_recover_speed: float = 0.55

# ── Natural noise ────────────────────────────────────────────────────────────
@export_group("Camera Noise")
@export var noise_amplitude: Vector2 = Vector2(0.9, 0.5)
@export var noise_frequency: Vector2 = Vector2(0.45, 0.6)
@export var noise_phase_offset: float = 1.3

# ── Voice line ───────────────────────────────────────────────────────────────
@export_group("Voice Line")
## Pause before text starts appearing after lock completes (seconds)
@export var voice_start_delay: float = 0.6
## Seconds per character for typewriter effect
@export var typewriter_speed: float = 0.045
## How fast the head bobs up and down while speaking
@export var head_bob_speed: float = 9.0
## Y position when mouth is open
@export var head_y_open: float = 0.7
## Y position when mouth is closed
@export var head_y_closed: float = 0.635

# ── Signals ──────────────────────────────────────────────────────────────────
signal cutscene_done

# ── Internal state ───────────────────────────────────────────────────────────
enum State { IDLE, EYE_OPEN, WANDERING, LOCKING, LOCKED, SPEAKING, DONE }

@onready var camera_3d: Camera3D = $Camera3D
@onready var eyelid: ColorRect = $CanvasLayer/EyelidOverlay
@onready var text: Label = $CanvasLayer/Text
@onready var head: Sprite3D = $bear/head
@onready var the_end_panel: ColorRect = %End

const VOICE_LINE := "Do you really need to remind me when you test me,\nto see if i can fullfill our promise?"

var _state: State = State.IDLE
var _time: float = 0.0
var _dwell_timer: float = 0.0
var _point_index: int = 0
var _noise_alpha: float = 0.0
var _base_basis: Basis

# Eye open
var _eye_timer: float = 0.0
var _open_basis: Basis

# Momentum
var _move_momentum: float = 0.0
var _lock_momentum: float = 0.0

# Voice line
var _voice_timer: float = 0.0
var _typewriter_timer: float = 0.0
var _visible_chars: int = 0
var _is_speaking: bool = false      # true while characters are still printing
var _head_base_y: float = 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_base_basis = camera_3d.global_basis
	eyelid.color = Color(0, 0, 0, 1)
	eyelid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.text = ""
	text.visible_characters = 0
	_head_base_y = head.position.y
	play()


func play() -> void:
	if look_points.is_empty():
		push_warning("CutsceneCamera: no look_points set")
		return
	_point_index = 0
	_dwell_timer = 0.0
	_time = 0.0
	_noise_alpha = 0.0
	_eye_timer = 0.0
	_move_momentum = 0.0
	_lock_momentum = 0.0
	_voice_timer = 0.0
	_typewriter_timer = 0.0
	_visible_chars = 0
	_is_speaking = false
	text.text = ""
	text.visible_characters = 0

	var tilt := Basis(Vector3.RIGHT, deg_to_rad(eye_open_tilt_deg))
	_base_basis = camera_3d.global_basis * tilt
	camera_3d.global_basis = _base_basis
	_open_basis = camera_3d.global_basis * Basis(Vector3.RIGHT, deg_to_rad(-eye_open_tilt_deg))

	_state = State.EYE_OPEN


func _process(delta: float) -> void:
	_time += delta

	match _state:
		State.EYE_OPEN:
			_process_eye_open(delta)
		State.WANDERING:
			_process_wander(delta)
		State.LOCKING:
			_process_lock(delta)
		State.LOCKED:
			_begin_voice_line()
		State.SPEAKING:
			_process_speaking(delta)


# ── States ───────────────────────────────────────────────────────────────────

func _process_eye_open(delta: float) -> void:
	_eye_timer += delta
	var t := clampf(_eye_timer / eye_open_duration, 0.0, 1.0)
	eyelid.color.a = ease(1.0 - t, 0.42)
	_base_basis = _base_basis.slerp(_open_basis, eye_open_recover_speed * delta)
	camera_3d.global_basis = _base_basis

	if t >= 1.0:
		eyelid.color.a = 0.0
		_noise_alpha = 1.0
		_move_momentum = 0.0
		_state = State.WANDERING


func _process_wander(delta: float) -> void:
	var target_pos: Vector3 = look_points[_point_index].global_position
	var desired_basis := _look_at_basis(camera_3d.global_position, target_pos)

	_move_momentum = move_toward(_move_momentum, 1.0, delta * wander_speed)
	var eased := ease(_move_momentum, wander_ease)
	_base_basis = _base_basis.slerp(desired_basis, eased * wander_speed * delta)
	camera_3d.global_basis = _apply_noise(_base_basis)

	var angle_err := _base_basis.z.angle_to(desired_basis.z)
	if angle_err < deg_to_rad(3.0):
		_dwell_timer += delta

	if _dwell_timer >= dwell_time:
		_dwell_timer = 0.0
		_point_index += 1
		_move_momentum = 0.0

		if _point_index >= look_points.size():
			if lock_target:
				_lock_momentum = 0.0
				_state = State.LOCKING
			else:
				_state = State.LOCKED


func _process_lock(delta: float) -> void:
	var target_pos: Vector3 = lock_target.global_position + lock_offset
	var desired_basis := _look_at_basis(camera_3d.global_position, target_pos)

	_lock_momentum = move_toward(_lock_momentum, 1.0, delta * lock_speed)
	var eased := ease(_lock_momentum, lock_ease)
	_base_basis = _base_basis.slerp(desired_basis, eased * lock_speed * delta)

	_noise_alpha = move_toward(_noise_alpha, 0.0, delta * lock_speed)
	camera_3d.global_basis = _apply_noise(_base_basis)

	var angle_err := rad_to_deg(_base_basis.z.angle_to(desired_basis.z))
	if angle_err <= lock_threshold_deg:
		camera_3d.global_basis = desired_basis
		_state = State.LOCKED


func _begin_voice_line() -> void:
	# Called once per frame while LOCKED — gate with _is_speaking flag
	if _is_speaking:
		return
	_is_speaking = true
	_voice_timer = 0.0
	_typewriter_timer = 0.0
	_visible_chars = 0
	text.text = VOICE_LINE
	text.visible_characters = 0
	_state = State.SPEAKING


func _process_speaking(delta: float) -> void:
	_voice_timer += delta

	# Wait for the start delay before printing anything
	if _voice_timer < voice_start_delay:
		return

	# Typewriter: reveal one character at a time
	var full_len := VOICE_LINE.length()
	if _visible_chars < full_len:
		_typewriter_timer += delta
		while _typewriter_timer >= typewriter_speed and _visible_chars < full_len:
			_typewriter_timer -= typewriter_speed
			_visible_chars += 1
			text.visible_characters = _visible_chars

	if _visible_chars >= full_len:
		_state = State.DONE
		cutscene_done.emit()
		await get_tree().create_timer(4).timeout
		the_end_panel.show()
		await get_tree().create_timer(10).timeout
		get_tree().change_scene_to_file("res://Scenes/Main_menu.tscn")


# ── Helpers ──────────────────────────────────────────────────────────────────

func _look_at_basis(from: Vector3, to: Vector3) -> Basis:
	var fwd := (to - from).normalized()
	if fwd.is_zero_approx():
		return camera_3d.global_basis
	var up := Vector3.UP
	if abs(fwd.dot(up)) > 0.98:
		up = Vector3.RIGHT
	return Basis.looking_at(fwd, up)


func _apply_noise(base: Basis) -> Basis:
	if _noise_alpha <= 0.0:
		return base
	var nx := sin(_time * noise_frequency.x * TAU) * noise_amplitude.x * _noise_alpha
	var ny := sin(_time * noise_frequency.y * TAU + noise_phase_offset) * noise_amplitude.y * _noise_alpha
	var rot := Basis(Vector3.RIGHT, deg_to_rad(ny)) * Basis(Vector3.UP, deg_to_rad(nx))
	return base * rot
