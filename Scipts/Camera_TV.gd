extends Node3D

@export var viewport: SubViewport

@onready var cam_layout: MeshInstance3D = $CamLayout
@onready var camera_interface: Control = %camera_interface
@onready var cams: Node3D = %Cams
@onready var hint_label: Label3D = $Label3D

var interface_open: bool = false
var night_started: bool  = false
func _ready() -> void:

	hint_label.hide()
	night_started = false

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = viewport.get_texture()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission_texture = viewport.get_texture()
	mat.emission_energy_multiplier = 0.8
	cam_layout.set_surface_override_material(0, mat)

	camera_interface.visible = false
	CamGlobal.cam_interface_back.connect(_on_cam_interface_back)
	NightManager.night_started.connect(_on_night_started)
	NightManager.night_ended.connect(_on_night_ended)

func _on_night_started(night:int):
	hint_label.show()
	night_started = true

func _on_night_ended(night:int,success:bool):
	hint_label.hide()
	night_started = false

func _unhandled_input(event: InputEvent) -> void:
	if !night_started: return
	if event.is_action_pressed("tab"):  # Tab
		_set_interface_open(!interface_open)
		if interface_open:
			cams.activate_camera_monitor()
			CamGlobal.cam_interface_up.emit()
		else:
			CamGlobal.cam_interface_back.emit()


func _on_cam_interface_back() -> void:
	_set_interface_open(false)

func _set_interface_open(open: bool) -> void:
	interface_open = open
	camera_interface.visible = open
