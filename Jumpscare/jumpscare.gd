extends CanvasLayer
class_name Jumpscare

## Generic jumpscare overlay used by every animatronic.
##
## Sequence:
##   show_for(id)
##     -> bloody red flash fades in (shader) + sound plays
##     -> flash fades out, revealing the jumpscare image + tips panel
##     -> player clicks / presses a key to dismiss

signal finished(animatronic_id: String)

# ---- Timing (tweak in the inspector) ----------------------------------------
@export var flash_in_duration: float = 0.10
@export var flash_hold_duration: float = 0.35
@export var flash_out_duration: float = 0.45
@export var input_lockout: float = 0.25

const DEFAULT_SOUND := ""

# ---- Per-animatronic data ---------------------------------------------------
const JUMPSCARE_DATA := {
	"Dave": {
		"title": "DAVE GOT YOU",
		"image": "res://Jumpscare/animatronic_image/dave.png",
		"sound": "res://Jumpscare/sounds/dave_sting.ogg",
		"tips": "How to avoid Dave:
- Watch the cameras and track his path from CAM_01.
- He moves toward either the LEFT door (via CAM_06) or the RIGHT door (via CAM_04).
- Close the correct door BEFORE he reaches it.
- He also causes camera errors — click and hold on the affected camera to fix them.",
	},
	"Frednic": {
		"title": "FREDNIC GOT YOU",
		"image": "res://Jumpscare/animatronic_image/freddy.png",
		"sound": "res://Jumpscare/sounds/frednic_sting.ogg",
		"tips": "How to avoid Frednic:
- Look at her on the cameras to keep her meter in the safe zone.
- If the meter is too low OR too full, she appears in the office.
- When she's in the office, put on the MASK to make her leave.",
	},
	"Rena": {
		"title": "RENA GOT YOU",
		"image": "res://Jumpscare/animatronic_image/rena.png",
		"sound": "res://Jumpscare/sounds/rena_sting.ogg",
		"tips": "How to avoid Rena:
- She starts on CAM_11 with three positions; watch which one she's in.
- When she leaves CAM_11, she jumps to CAM_05 — close the OPPOSITE window fast.
- Reopen the window after you hear the bang and the lights stop flashing.
- She can also go through the right door via CAM_02 → CAM_03 → CAM_04.",
	},
	"Ambassador": {
		"title": "AMBASSADOR GOT YOU",
		"image": "res://Jumpscare/animatronic_image/ambassador.png",
		"sound": "res://Jumpscare/sounds/ambassador_sting.ogg",
		"tips": "How to avoid the Ambassador:
- She appears on random cameras whenever you raise the monitor.
- If she is visible, DO NOT lower the cameras.
- Lowering once while she's visible bricks the cameras for the night.
- Lowering twice ends the night.",
	},
	"TheRealFredbear": {
		"title": "THE REAL FREDBEAR GOT YOU",
		"image": "res://assets/jumpscares/the_real_fredbear.png",
		"sound": "res://Jumpscare/sounds/fredbear_sting.ogg",
		"tips": "How to avoid The Real Fredbear:
- Listen for the trumpet sound (Old Sport Playing A Trumpet Really Badly).
- When it plays, click the PC in the office immediately.
- When he appears in the office, mash the GAZE button until he leaves.",
	},
	"Bronnie": {
		"title": "BRONNIE GOT YOU",
		"image": "res://Jumpscare/animatronic_image/kamen_rider.png",
		"sound": "res://Jumpscare/sounds/bronnie_sting.ogg",
		"tips": "How to avoid Bronnie:
- He starts at CAM_09 and takes either the left or right door route.
- Left path: CAM_09 → CAM_08 → CAM_07 → left door.
- Right path: CAM_02 → CAM_03 → CAM_04 (right door).
- He will force the door open regardless — wear the MASK to make him leave.",
	},
}

@onready var _image: TextureRect = $AnimatronicImage
@onready var _info_panel: PanelContainer = $InfoPanel
@onready var _title_label: Label = $InfoPanel/MarginContainer/VBox/Title
@onready var _tips_label: Label = $InfoPanel/MarginContainer/VBox/HowToAvoid
@onready var _red_flash: ColorRect = $RedFlash
@onready var _sound_player: AudioStreamPlayer = $SoundPlayer
@onready var crumbling_dreams_v_3: AudioStreamPlayer = $CrumblingDreamsV3

var _can_dismiss: bool = false
var _current_id: String = ""
var _flash_active: bool = false
var _flash_time: float = 0.0


func _ready() -> void:
	GameManger.set_jumpscare(self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_set_flash_intensity(0.0)
	_set_drip_progress(0.0)
	
	await get_tree().create_timer(1).timeout
	_sound_player.finished.connect(func():
		crumbling_dreams_v_3.play())


func _process(delta: float) -> void:
	if _flash_active:
		_flash_time += delta
		var mat := _red_flash.material as ShaderMaterial
		if mat != null:
			mat.set_shader_parameter("time_offset", _flash_time)


## Show the jumpscare for a known animatronic id.
func show_for(animatronic_id: String) -> void:
	_current_id = animatronic_id
	var data: Dictionary = JUMPSCARE_DATA.get(animatronic_id, {})
	if data.is_empty():
		push_warning("Jumpscare: no data for animatronic id '%s'" % animatronic_id)
	_apply_data(data)
	await _show()


## Show with arbitrary data.
func show_custom(data: Dictionary, id: String = "") -> void:
	_current_id = id
	_apply_data(data)
	await _show()


func _show() -> void:
	visible = true
	get_tree().paused = true
	_can_dismiss = false
	_image.visible = false
	_info_panel.visible = false

	# Reset shader animation state.
	_flash_time = 0.0
	_flash_active = true
	_set_flash_intensity(0.0)
	_set_drip_progress(0.0)

	# Play the sound right as the flash starts.
	_sound_player.play()
	print(_sound_player.playing)
	# Tween: intensity 0 -> 1 -> 1 -> 0, with reveal at the peak.
	# Drip progress runs across the whole flash so drips grow visibly during it.
	var total: float = flash_in_duration + flash_hold_duration + flash_out_duration

	var intensity_tween := create_tween()
	intensity_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	intensity_tween.tween_method(_set_flash_intensity, 0.0, 1.0, flash_in_duration)
	intensity_tween.tween_interval(flash_hold_duration)
	intensity_tween.tween_callback(func() -> void:
		_image.visible = true
		_info_panel.visible = true
	)
	intensity_tween.tween_method(_set_flash_intensity, 1.0, 0.0, flash_out_duration)
	intensity_tween.tween_callback(func() -> void:
		_flash_active = false
	)

	# Drip progress: 0 -> 1 over the full show, so drips keep growing
	# throughout the flash instead of being frozen.
	var drip_tween := create_tween()
	drip_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	drip_tween.tween_method(_set_drip_progress, 0.0, 1.0, total)

	await intensity_tween.finished

	await get_tree().create_timer(input_lockout).timeout
	_can_dismiss = true


func _set_flash_intensity(value: float) -> void:
	var mat := _red_flash.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("intensity", value)


func _set_drip_progress(value: float) -> void:
	var mat := _red_flash.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("drip_progress", value)


func _apply_data(data: Dictionary) -> void:
	if data.has("title"):
		_title_label.text = String(data["title"])
	if data.has("tips"):
		_tips_label.text = String(data["tips"])
	if data.has("image"):
		var img = data["image"]
		if img is Texture2D:
			_image.texture = img
		elif img is String and img != "":
			if ResourceLoader.exists(img):
				_image.texture = load(img)
			else:
				push_warning("Jumpscare: image not found at '%s'" % img)
				_image.texture = null
		else:
			_image.texture = null



func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _can_dismiss:
		return
	if event is InputEventMouseButton and event.pressed:
		_dismiss()
	elif event is InputEventKey and event.pressed and not event.echo:
		_dismiss()


func _dismiss() -> void:
	if not _can_dismiss:
		return
	_can_dismiss = false
	visible = false
	_flash_active = false
	_set_flash_intensity(0.0)
	_set_drip_progress(0.0)

	if crumbling_dreams_v_3.playing:
		crumbling_dreams_v_3.stop()
		
	get_tree().paused = false
	finished.emit(_current_id)
	_current_id = ""
	get_tree().change_scene_to_file("res://Scenes/Main_menu.tscn")
