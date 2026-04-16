extends Control

@onready var play: Button = %play
@onready var options: Button = %options
@onready var quit: Button = %quit
@onready var main_menu: VBoxContainer = %main_menu
@onready var options_menu: VBoxContainer = %options_menu
@onready var back: Button = %back
@onready var loading_bar: ProgressBar = $loading/loading_bar
@onready var loading_screen: VBoxContainer = $loading
@onready var anim_player: AnimationPlayer = $loading/AnimationPlayer

const SCENE_TO_LOAD = "res://Scenes/Map.tscn"

var _load_progress: Array = []
var _is_loading: bool = false

func _ready() -> void:
	play.pressed.connect(_on_play_pressed)
	options.pressed.connect(_on_options_pressed)
	quit.pressed.connect(_on_quit_pressed)
	back.pressed.connect(_on_options_back_pressed)
	loading_screen.hide()

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

func _on_play_pressed() -> void:
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
