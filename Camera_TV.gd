extends Node3D

@export var viewport: SubViewport
@onready var area_3d: Area3D = $Area3D
@onready var cam_layout: MeshInstance3D = $CamLayout
@onready var camera_interface: Control = %camera_interface
@onready var cams: Node3D = %Cams

const DOUBLE_CLICK_TIME = 0.3
var click_count: int = 0
var click_timer: float = 0.0
var is_hovered: bool = false

func _ready():
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = viewport.get_texture()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission_texture = viewport.get_texture()
	mat.emission_energy_multiplier = 0.8
	cam_layout.set_surface_override_material(0, mat)

	area_3d.mouse_entered.connect(_on_mouse_entered)
	area_3d.mouse_exited.connect(_on_mouse_exited)
	area_3d.input_event.connect(_on_area_input)

func _process(delta: float) -> void:
	if click_count > 0:
		click_timer += delta
		if click_timer >= DOUBLE_CLICK_TIME:
			# Timer expired — commit whatever count we have
			if click_count == 1:
				on_single_click()
			click_count = 0
			click_timer = 0.0

func _on_mouse_entered() -> void:
	is_hovered = true
	$Label.text = "entered"
func _on_mouse_exited() -> void:
	is_hovered = false
	$Label.text = "exited"

func _on_area_input(_camera, event: InputEvent, _pos, _normal, _idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		click_count += 1
		click_timer = 0.0
		if click_count == 2:
			on_double_click()
			click_count = 0
			click_timer = 0.0

func on_single_click() -> void:
	cam_layout.visible = !cam_layout.visible
	print("Single click on monitor")

func on_double_click() -> void:
	camera_interface.visible = !camera_interface.visible
	cams.activate_camera_monitor()
	print("Double click on monitor")
