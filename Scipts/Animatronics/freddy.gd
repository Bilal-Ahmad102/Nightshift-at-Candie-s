extends Node3D

signal jumpscare_triggered

enum State { IDLE, IN_OFFICE, JUMPSCARING }

# ── Gaze meter ──────────────────────────────────────────────
@export var meter_drain_rate: float = 0.04   # per second when NOT watched
@export var meter_fill_rate: float  = 0.05   # per second when watched
@export var meter_min: float        = 0.0
@export var meter_max: float        = 1.0
@export var danger_low: float       = 0.15   # below this → enters office
@export var danger_high: float      = 0.85   # above this → enters office


var meter: float = 0.5             # start in the safe middle
var is_being_watched: bool = false
var current_state: State = State.IDLE

# ── Camera roaming ───────────────────────────────────────────
var all_cams: Array[String] = [
	"cam_2","cam_1","cam_6","cam_7","cam_8","cam_9"
]
var current_cam: String = "cam_11"
var cam_positions: Dictionary = {}
var cam_watching: String 
@export var cam_markers_root: Node   # parent node holding Marker3D children keyed by cam name
@onready var _roam_timer: Timer = %RoamTimer
@onready var watch_meter: ProgressBar = %watch_meter

# ── Mask ─────────────────────────────────────────────────────
var mask_on: bool = false

# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	_build_cam_dict()
	_style_watch_meter()
	watch_meter.min_value = 0.0
	watch_meter.max_value = 100.0
	watch_meter.value     = 50.0
	hide_meter()

	_roam_timer.timeout.connect(_on_roam_timer)
	CamGlobal.cam_switched.connect(notify_watched)
	NightManager.night_started.connect(_on_night_started)
	watch_meter.hide()
	set_process(false)
	
func _on_night_started(night: int) -> void:
	if NightManager.is_animatronic_active("Frednic"):
		_roam_timer.start(_roam_interval())

func _build_cam_dict() -> void:
	if not cam_markers_root:
		return
	for marker in cam_markers_root.get_children():
		cam_positions[marker.name] = marker   # name each Marker3D after its cam, e.g. "cam_3"

# ─────────────────────────────────────────────────────────────
# Called every frame by the game loop (or connect to a signal)
# ─────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	if current_state != State.IDLE:
		return

	# Update meter
	if is_being_watched:
		meter = clampf(meter + meter_fill_rate * delta, meter_min, meter_max)
	else:
		meter = clampf(meter - meter_drain_rate * delta, meter_min, meter_max)
	# Push to bar
	watch_meter.value = meter * 100.0
	_update_meter_color()
	# Check danger thresholds
	if meter <= danger_low or meter >= danger_high:
		_enter_office()
		
# ─────────────────────────────────────────────────────────────
func _update_meter_color() -> void:
	var fill := StyleBoxFlat.new()
	fill.set_corner_radius_all(5)

	if meter <= danger_low or meter >= danger_high:
		var flicker = 0.85 + abs(sin(Time.get_ticks_msec() * 0.004)) * 0.15
		fill.bg_color = Color(flicker, flicker * 0.3, flicker * 0.3, 1.0)
	else:
		fill.bg_color = Color(0.9, 0.9, 0.9, 1.0)

	watch_meter.add_theme_stylebox_override("fill", fill)
	
	
# ─────────────────────────────────────────────────────────────
# Call these from your CameraSystem when the player views a cam
# ─────────────────────────────────────────────────────────────
func notify_watched(prev_id:int, current_id:int) -> void:
	cam_watching = "cam_" + str(current_id)
	is_being_watched = (cam_watching == current_cam)
	show_meter()
func _check_being_watched():
	if !cam_watching:return
	is_being_watched = (cam_watching == current_cam)
func notify_camera_closed() -> void:
	is_being_watched = false
	hide_meter()
# ─────────────────────────────────────────────────────────────
# Roaming
# ─────────────────────────────────────────────────────────────
func _on_roam_timer() -> void:
	if current_state != State.IDLE:
		return
	_move_to_random_cam()
	_roam_timer.start(_roam_interval())
	_check_being_watched()
func _move_to_random_cam() -> void:
	var options = all_cams.filter(func(c): return c != current_cam)
	current_cam = options[randi() % options.size()]
	var marker = cam_positions.get(current_cam)
	if marker:
		global_position = marker.global_position
		global_rotation = marker.global_rotation
	print("Frednic moved to: ", current_cam)

func _roam_interval() -> float:
	return 5.0
	# var ai_level = NightManager.get_ai_level("Frednic")
	# return max(2.0, 8.0 - ai_level * 1.0)

# ─────────────────────────────────────────────────────────────
# Office
# ─────────────────────────────────────────────────────────────
func _enter_office() -> void:
	current_state = State.IN_OFFICE
	is_being_watched = false
	print("Frednic entered the office!")
	# TODO: move to office position / play animation

func notify_mask_put_on() -> void:
	if current_state == State.IN_OFFICE:
		mask_on = true
		_leave_office()

func notify_mask_removed() -> void:
	mask_on = false

func _leave_office() -> void:
	# Reset meter to safe middle and return to roaming
	meter = 0.5
	current_state = State.IDLE
	current_cam = "cam_1"
	var marker = cam_positions.get(current_cam)
	if marker:
		global_position = marker.global_position
		global_rotation = marker.global_rotation
	_roam_timer.start(_roam_interval())
	print("Frednic left the office.")

# ─────────────────────────────────────────────────────────────
# Jumpscare (if mask is NOT put on in time — hook this up if needed)
# ─────────────────────────────────────────────────────────────
func _trigger_jumpscare() -> void:
	current_state = State.JUMPSCARING
	print("Frednic jumpscare!")
	emit_signal("jumpscare_triggered")
	

# ── Visibility ───────────────────────────────────────────────
func show_meter() -> void:
	watch_meter.visible = true

func hide_meter() -> void:
	watch_meter.visible = false

func _style_watch_meter() -> void:
	# --- Size & position ---
	watch_meter.custom_minimum_size = Vector2(300, 10)
	watch_meter.anchor_left   = 0.5
	watch_meter.anchor_right  = 0.5
	watch_meter.anchor_top    = 0.0
	watch_meter.anchor_bottom = 0.0
	watch_meter.offset_left   = -150
	watch_meter.offset_right  = 150
	watch_meter.offset_top    = 20
	watch_meter.offset_bottom = 30

	watch_meter.show_percentage = false

	# --- Background ---
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.15, 0.15, 0.6)
	bg.set_border_width_all(1)
	bg.border_color = Color(1.0, 1.0, 1.0, 0.15)
	bg.set_corner_radius_all(5)

	# --- Fill ---
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.9, 0.9, 0.9, 1.0)
	fill.set_corner_radius_all(5)

	# --- Apply ---
	var theme := Theme.new()
	theme.set_stylebox("background", "ProgressBar", bg)
	theme.set_stylebox("fill",       "ProgressBar", fill)
	watch_meter.theme = theme
