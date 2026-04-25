extends Node3D

@export var viewport: SubViewport

@onready var area_3d: Area3D = $Area3D
@onready var cam_layout: MeshInstance3D = $CamLayout
@onready var camera_interface: Control = %camera_interface
@onready var cams: Node3D = %Cams

var interface_open: bool = false

func _ready() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = viewport.get_texture()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission_texture = viewport.get_texture()
	mat.emission_energy_multiplier = 0.8
	cam_layout.set_surface_override_material(0, mat)

	camera_interface.visible = false
	CamGlobal.cam_interface_back.connect(_on_cam_interface_back)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("tab"):  # Tab
		_set_interface_open(!interface_open)
		if interface_open:
			cams.activate_camera_monitor()
		else:
			CamGlobal.cam_interface_back.emit()
			
func _on_cam_interface_back() -> void:
	_set_interface_open(false)

func _set_interface_open(open: bool) -> void:
	interface_open = open
	camera_interface.visible = open
