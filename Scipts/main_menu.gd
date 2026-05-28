extends Control

@onready var continue_btn: Button = %continue_btn
@onready var new_game: Button = %new_game
@onready var load_night: Button = %load_night
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
@onready var loading_bar: ProgressBar = $loading/loading_bar
@onready var loading_screen: VBoxContainer = $loading
@onready var anim_player: AnimationPlayer = $loading/AnimationPlayer
@onready var styler: Node = $styler

const SCENE_TO_LOAD = "res://Scenes/Map.tscn"

var _load_progress: Array = []
var _is_loading: bool = false

func _ready() -> void:
	continue_btn.pressed.connect(_on_continue_pressed)
	new_game.pressed.connect(_on_new_game_pressed)
	load_night.pressed.connect(_on_load_night_pressed)
	options.pressed.connect(_on_options_pressed)
	quit.pressed.connect(_on_quit_pressed)
	back.pressed.connect(_on_options_back_pressed)
	load_back.pressed.connect(_on_load_back_pressed)
	sound_minus.pressed.connect(_on_sound_minus_pressed)
	sound_plus.pressed.connect(_on_sound_plus_pressed)
	fullscreen_toggle.pressed.connect(_on_fullscreen_toggle_pressed)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_refresh_sound_value()
	_refresh_fullscreen_value()
	_refresh_save_state_buttons()
	loading_screen.hide()

# Show Continue / Load Night only if the player has progressed past night 1.
func _refresh_save_state_buttons() -> void:
	var has_progress := SaveManager.get_current_night() > 1
	continue_btn.visible = has_progress
	load_night.visible = has_progress

func _process(_delta: float) -> void:
	if not _is_loading:
		return

	var status = ResourceLoader.load_threaded_get_status(SCENE_TO_LOAD, _load_progress)
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			loading_bar.value = _load_progress[0] * 100.0

		ResourceLoader.THREAD_LOAD_LOADED:
			loading_bar.value = 100.0
			_is_loading = false
			_on_load_complete()

		ResourceLoader.THREAD_LOAD_FAILED:
			_is_loading = false
			push_error("[LoadingScreen] Scene failed to load: %s" % SCENE_TO_LOAD)

func _on_continue_pressed() -> void:
	# current_night already reflects saved progress — just load the scene.
	_start_loading()

func _on_new_game_pressed() -> void:
	# Start from night 1, but DON'T touch the saved file. If the player
	# beats a higher night again it'll save through save_night_progress;
	# otherwise their existing progress stays intact.
	SaveManager.set_current_night(1)
	_start_loading()

func _on_load_night_pressed() -> void:
	main_menu.hide()
	_populate_night_buttons()
	load_night_menu.show()
	styler.style_children_recursive(self)

func _on_load_back_pressed() -> void:
	load_night_menu.hide()
	main_menu.show()

# Build one button per unlocked night, freshly each time the submenu opens
# so it stays in sync with progress.
func _populate_night_buttons() -> void:
	for child in night_buttons.get_children():
		child.queue_free()

	var nights := SaveManager.get_unlocked_nights().duplicate()
	nights.sort()
	for night in nights:
		var btn := Button.new()
		btn.text = "Night %d" % night
		btn.flat = true
		btn.add_theme_font_size_override("font_size", 32)
		btn.pressed.connect(_on_night_selected.bind(night))
		night_buttons.add_child(btn)

func _on_night_selected(night: int) -> void:
	SaveManager.set_current_night(night)
	load_night_menu.hide()
	_start_loading()

func _start_loading() -> void:
	main_menu.hide()
	loading_screen.show()
	anim_player.play("loading")
	loading_bar.value = 0.0
	ResourceLoader.load_threaded_request(SCENE_TO_LOAD)
	_is_loading = true

func _on_options_pressed() -> void:
	main_menu.hide()
	options_menu.show()

func _on_options_back_pressed() -> void:
	main_menu.show()
	options_menu.hide()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_load_complete() -> void:
	var packed = ResourceLoader.load_threaded_get(SCENE_TO_LOAD)
	get_tree().change_scene_to_packed(packed)

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
