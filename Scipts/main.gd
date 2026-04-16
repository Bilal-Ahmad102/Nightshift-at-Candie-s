extends Node3D

@onready var night_BG: ColorRect = $night_board/Night
@onready var night_label: Label = %night_label
@onready var main_camera: Camera3D = %Main_camera

@onready var nigh_1_monologue: AudioStreamPlayer = %Nigh1Monologue
@onready var skip_monologue_btn: Button = $Audios/Control/skip_monologue_btn
@onready var hotel_2: AudioStreamPlayer = %Hotel2

var current_night: int = 1
var skip_requested := false

func _ready() -> void:
	NightManager.night_started.connect(_on_night_started_label)
	skip_monologue_btn.pressed.connect(_on_skip_pressed)

	current_night = SaveManager.get_current_night()
	await show_night_panel()
	await start_monologue()
	BG_soundtrack()
	
func BG_soundtrack():
	if current_night <= 4:
		hotel_2.play()

func start_monologue():
	print("START")
	if current_night == 1:
		skip_requested = false
		skip_monologue_btn.disabled = false
		skip_monologue_btn.show()

		nigh_1_monologue.play()

		# Wait until either audio finishes OR skip is pressed
		while nigh_1_monologue.playing and not skip_requested :
			await get_tree().process_frame

		# Cleanup
		skip_monologue_btn.hide()
		skip_monologue_btn.disabled = true

		main_camera.cam_mov(true)
		NightManager.start_night(1)


func _on_skip_pressed():
	if not skip_requested:
		skip_requested = true
		nigh_1_monologue.stop()


func _input(event):
	if event.is_action_pressed("ui_accept"):
		_on_skip_pressed()


func show_night_panel() -> void:
	night_label.text = "Night " + str(current_night)
	night_BG.show()
	await get_tree().create_timer(3).timeout
	night_BG.hide()

func _on_night_started_label(night: int):
	if night == 1:
		return

	night_BG.show()
	night_label.text = "Night " + str(night)
