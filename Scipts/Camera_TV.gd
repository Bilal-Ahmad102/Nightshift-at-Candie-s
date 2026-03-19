extends Node3D

@export var viewport: SubViewport

@onready var area_3d: Area3D = $Area3D
@onready var cam_layout: MeshInstance3D = $CamLayout
@onready var camera_interface: Control = %camera_interface
@onready var cams: Node3D = %Cams

const DOUBLE_CLICK_TIME: float = 0.3

var click_count: int = 0
var click_timer: float = 0.0
var is_hovered: bool = false
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

	area_3d.mouse_entered.connect(_on_mouse_entered)
	area_3d.mouse_exited.connect(_on_mouse_exited)
	area_3d.input_event.connect(_on_area_input)
	CamGlobal.cam_interface_back.connect(_on_cam_interface_back)


func _process(delta: float) -> void:
	if click_count > 0:
		click_timer += delta
		if click_timer >= DOUBLE_CLICK_TIME:
			if click_count == 1:
				_on_single_click()
			click_count = 0
			click_timer = 0.0


func _on_mouse_entered() -> void:
	is_hovered = true


func _on_mouse_exited() -> void:
	is_hovered = false


func _on_area_input(_camera, event: InputEvent, _pos, _normal, _idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		click_count += 1
		click_timer = 0.0
		if click_count == 2:
			_on_double_click()
			click_count = 0
			click_timer = 0.0


func _on_single_click() -> void:
	cam_layout.visible = !cam_layout.visible


func _on_double_click() -> void:
	_set_interface_open(true)
	cams.activate_camera_monitor()


# Called when the Back panel is hovered inside the camera interface
func _on_cam_interface_back() -> void:
	_set_interface_open(false)


func _set_interface_open(open: bool) -> void:
	interface_open = open
	camera_interface.visible = open
