extends Node3D

@onready var night_BG: ColorRect = $night_board/Night
@onready var night_label: Label = %night_label
@onready var main_camera: Camera3D = %Main_camera
@onready var nigh_1_monologue: AudioStreamPlayer = %Nigh1Monologue
@onready var night_2_monologue: AudioStreamPlayer = %Night2Monologue
@onready var night_3_monologue: AudioStreamPlayer = %Night3Monologue
@onready var night_4_monologue: AudioStreamPlayer = %Night4Monologue
@onready var night_5_monologue: AudioStreamPlayer = %Night5Monologue
@onready var hotel_2: AudioStreamPlayer = %Hotel2
@onready var skip_label: Label = $Audios/Control/skip_label
@onready var skip_progress_bar: ProgressBar = $Audios/Control/skip_label/skip_bar

var current_night: int = 1
var skip_requested := false
var _holding_skip := false
var monologue_to_play: AudioStreamPlayer

func _ready() -> void:
	connect_signals()
	current_night = SaveManager.get_current_night()
	skip_progress_bar.value = 0.0
	skip_progress_bar.max_value = 100.0
	skip_label.hide()
	call_deferred("_start_sequence")
func connect_signals():
	NightManager.night_ended.connect( _on_night_ended)
func _on_night_ended(night: int , success: bool):
	current_night = night + 1
	if success:
		SaveManager.save_night_progress(current_night)
	_start_sequence()
func _start_sequence() -> void:
	await show_night_panel(current_night)
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
	match current_night:
		1: monologue_to_play = nigh_1_monologue
		2: monologue_to_play = night_2_monologue
		3: monologue_to_play = night_3_monologue
		4: monologue_to_play = night_4_monologue
		5: monologue_to_play = night_5_monologue
		_:
			# No monologue defined for this night — skip straight to gameplay.
			main_camera.cam_mov(true)
			NightManager.start_night(current_night)
			return
	
	skip_requested = false
	skip_label.show()
	monologue_to_play.play()
	while monologue_to_play.playing and not skip_requested:
		await get_tree().process_frame
	skip_label.hide()
	main_camera.cam_mov(true)
	NightManager.start_night(current_night)
func _on_skip_pressed() -> void:
	if not skip_requested and monologue_to_play != null and monologue_to_play.playing:
		skip_requested = true
		_holding_skip = false
		skip_progress_bar.value = 0.0
		monologue_to_play.stop()
func show_night_panel(night: int) -> void:
	night_label.text = "Night " + str(night)
	night_BG.show()
	await get_tree().create_timer(3).timeout
	night_BG.hide()
