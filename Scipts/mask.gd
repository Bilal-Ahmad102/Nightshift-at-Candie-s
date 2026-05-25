extends TextureRect

# Emitted whenever the mask goes up or down. Animatronics that can be fooled
# by the mask (Frednic, Bronnie) should connect to this OR poll is_up()
# at the moment they'd trigger their jumpscare.
signal mask_state_changed(up: bool)

# Tweakable visual feedback values.
@export var off_scale: Vector2 = Vector2(0.7, 0.7)
@export var on_scale: Vector2 = Vector2(1.0, 1.0)
@export var off_alpha: float = 0.5
@export var on_alpha: float = 1.0
@export var transition_duration: float = 0.3

var mask_up: bool = false
var _cams_open: bool = false
var _is_active: bool = false
var _tween: Tween

func _ready() -> void:
	NightManager.night_started.connect(_on_night_started)
	NightManager.night_ended.connect(_on_night_ended)
	CamGlobal.cam_interface_up.connect(_on_cam_up)
	CamGlobal.cam_interface_back.connect(_on_cam_down)

	# Pivot in the center so it scales from the middle, not the top-left.
	pivot_offset = size / 2.0
	_apply_visual_state(false, true)  # instant init to "off" pose
	self.hide()

# ─────────────────────────────────────────────────────────────
# Public API for animatronics
# ─────────────────────────────────────────────────────────────
func is_up() -> bool:
	return mask_up

# ─────────────────────────────────────────────────────────────
# Night activation
# ─────────────────────────────────────────────────────────────
func _on_night_started(_night: int) -> void:
	if NightManager.is_animatronic_active("Frednic") \
		or NightManager.is_animatronic_active("Bronnie"):
		_is_active = true
		_set_mask(false, true)  # snap to off pose on night start
		self.show()
	else:
		_is_active = false
		self.hide()

func _on_night_ended(_night: int, _success: bool) -> void:
	_is_active = false
	_set_mask(false, true)
	self.hide()

# ─────────────────────────────────────────────────────────────
# Camera interaction — opening cams forces mask down
# ─────────────────────────────────────────────────────────────
func _on_cam_up() -> void:
	_cams_open = true
	
	if mask_up:
		_set_mask(false)

func _on_cam_down() -> void:
	_cams_open = false

# ─────────────────────────────────────────────────────────────
# Input
# ─────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if not _is_active:
		return
	if event.is_action_pressed("mask"):
		if _cams_open and not mask_up:
			return
		_set_mask(not mask_up)
		get_viewport().set_input_as_handled()

# ─────────────────────────────────────────────────────────────
# State change + tween
# ─────────────────────────────────────────────────────────────
func _set_mask(up: bool, instant: bool = false) -> void:
	if mask_up == up:
		return
	mask_up = up
	_apply_visual_state(up, instant)
	mask_state_changed.emit(up)

func _apply_visual_state(up: bool, instant: bool) -> void:
	# Kill any in-progress tween so a rapid toggle starts cleanly.
	if _tween != null and _tween.is_valid():
		_tween.kill()

	var target_scale: Vector2 = on_scale if up else off_scale
	var target_modulate: Color = modulate
	target_modulate.a = on_alpha if up else off_alpha

	if instant:
		scale = target_scale
		modulate = target_modulate
		return

	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "scale", target_scale, transition_duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate", target_modulate, transition_duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
