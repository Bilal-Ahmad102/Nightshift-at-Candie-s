extends Node3D

@onready var time: Label3D = $MapBase_FlatMesh_002/time
@onready var label: Label = $"../Label"

func _ready() -> void:
	GameClock.time_changed.connect(_on_time_changed)
	GameClock.hour_changed.connect(_on_hour_changed)
	GameClock.night_complete.connect(_on_night_complete)
	GameClock.start_night(NightManager.current_night)
	NightManager.night_started.connect(_night_started)
func _on_time_changed(hour: int, minute: int) -> void:
	time.text = GameClock.get_display_time()

func _on_hour_changed(hour: int) -> void:
	pass

func _on_night_complete() -> void:
	pass

func _night_started(night:int):
	label.text = "night: "+str(night)
