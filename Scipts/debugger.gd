extends Control

@onready var label: Label = $HBoxContainer/Label
@onready var label_2: Label = $HBoxContainer/Label2
var s_number: int = 0 
var n_number: int = 0
func _ready() -> void:
	NightManager.night_started.connect(func(night:int):
		s_number += 1
		label.text = "night started" + str(s_number))

	NightManager.night_ended.connect(func(night:int, success: bool):
		n_number += 1
		label_2.text = "night ended" + str(n_number))
