extends Node3D

@onready var night_BG: ColorRect = $night_board/Night
@onready var night_label: Label = %night_label
@onready var main_camera: Camera3D = %Main_camera
@onready var nigh_1_monologue: AudioStreamPlayer = %Nigh1Monologue
@onready var hotel_2: AudioStreamPlayer = %Hotel2
@onready var skip_label: Label = $Audios/Control/skip_label
#@onready var skip_progress_bar: ProgressBar = $Audios/Control/skip_label/ProgressBar
@onready var skip_progress_bar: ProgressBar = $Audios/Control/skip_label/skip_bar

var current_night: int = 1
var skip_requested := false
var _holding_skip := false

func _ready() -> void:
	NightManager.night_started.connect(_on_night_started_label)
	current_night = SaveManager.get_current_night()
	skip_progress_bar.value = 0.0
	skip_progress_bar.max_value = 100.0
	skip_label.hide()
	call_deferred("_start_sequence")

func _start_sequence() -> void:
	await show_night_panel()
	await start_monologue()
	BG_soundtrack()

func _process(delta: float) -> void:
	if _holding_skip:
		skip_progress_bar.value += 60.0 * delta  # fills in ~1.6 sec
		if skip_progress_bar.value >= skip_progress_bar.max_value:
			_on_skip_pressed()
	else:
		skip_progress_bar.value = max(0.0, skip_progress_bar.value - 80.0 * delta)  # drains fast

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("skip"):
		_holding_skip = true
		
	if event.is_action_released("skip"):
		_holding_skip = false

func BG_soundtrack() -> void:
	if current_night <= 4:
		hotel_2.play()

func start_monologue() -> void:
	if current_night == 1:
		skip_requested = false
		skip_label.show()
		nigh_1_monologue.play()
		while nigh_1_monologue.playing and not skip_requested:
			await get_tree().process_frame
		skip_label.hide()
		main_camera.cam_mov(true)
		NightManager.start_night(1)

func _on_skip_pressed() -> void:
	if not skip_requested:
		skip_requested = true
		_holding_skip = false
		skip_progress_bar.value = 0.0
		nigh_1_monologue.stop()

func show_night_panel() -> void:
	night_label.text = "Night " + str(current_night)
	night_BG.show()
	await get_tree().create_timer(3).timeout
	night_BG.hide()

func _on_night_started_label(night: int) -> void:
	if night == 1:
		return
	night_BG.show()
	night_label.text = "Night " + str(night)
