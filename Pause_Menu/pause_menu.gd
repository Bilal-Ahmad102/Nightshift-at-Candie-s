extends Control

@onready var resume: Button = %resume
@onready var options: Button = %options
@onready var quit: Button = %quit
@onready var main_menu: VBoxContainer = %main_menu
@onready var options_menu: VBoxContainer = %options_menu
@onready var load_night_menu: VBoxContainer = %load_night_menu
@onready var night_buttons: VBoxContainer = %night_buttons
@onready var load_back: Button = %load_back
@onready var back: Button = %back
@onready var sound_minus: Button = %sound_minus
@onready var sound_plus: Button = %sound_plus
@onready var sound_value: Label = %sound_value
@onready var fullscreen_toggle: Button = %fullscreen_toggle
@onready var anim_player: AnimationPlayer = $loading/AnimationPlayer
@onready var styler: Node = $styler

var _load_progress: Array = []
var _is_loading: bool = false

var paused: bool =  false
var can_paused: bool = false

func _ready() -> void:
	resume.pressed.connect(_on_resume_pressed)
	options.pressed.connect(_on_options_pressed)
	quit.pressed.connect(_on_quit_pressed)
	back.pressed.connect(_on_options_back_pressed)
	load_back.pressed.connect(_on_load_back_pressed)
	sound_minus.pressed.connect(_on_sound_minus_pressed)
	sound_plus.pressed.connect(_on_sound_plus_pressed)
	fullscreen_toggle.pressed.connect(_on_fullscreen_toggle_pressed)

	NightManager.night_started.connect(func(n:int):
		can_paused = true)
	NightManager.night_ended.connect(func(n:int,s:bool):
		can_paused = false)
	_refresh_sound_value()
	_refresh_fullscreen_value()



func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape") and can_paused:
		if paused:
			if options_menu.visible:
				_on_options_back_pressed()
			elif main_menu.visible:
				self.hide()
				paused = false
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			self.show()


func _on_resume_pressed() -> void:
	self.hide()
	paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_load_back_pressed() -> void:
	load_night_menu.hide()
	main_menu.show()




func _on_options_pressed() -> void:
	main_menu.hide()
	options_menu.show()

func _on_options_back_pressed() -> void:
	main_menu.show()
	options_menu.hide()

func _on_quit_pressed() -> void:
	get_tree().quit()


# ─────────────────────────────────────────────────────────────
# Sound volume controls (master bus, 0–100 in steps of 5)
# ─────────────────────────────────────────────────────────────
const VOLUME_STEP := 0.05

func _on_sound_minus_pressed() -> void:
	var new_value: float = clamp(SaveManager.get_master_volume() - VOLUME_STEP, 0.0, 1.0)
	SaveManager.set_master_volume(new_value)
	SaveManager.save()
	_refresh_sound_value()

func _on_sound_plus_pressed() -> void:
	var new_value: float = clamp(SaveManager.get_master_volume() + VOLUME_STEP, 0.0, 1.0)
	SaveManager.set_master_volume(new_value)
	SaveManager.save()
	_refresh_sound_value()

func _refresh_sound_value() -> void:
	sound_value.text = str(int(round(SaveManager.get_master_volume() * 100)))

# ─────────────────────────────────────────────────────────────
# Fullscreen toggle
# ─────────────────────────────────────────────────────────────
func _on_fullscreen_toggle_pressed() -> void:
	SaveManager.set_fullscreen(not SaveManager.get_fullscreen())
	SaveManager.save()
	_refresh_fullscreen_value()

func _refresh_fullscreen_value() -> void:
	fullscreen_toggle.text = " On " if SaveManager.get_fullscreen() else " Off "
