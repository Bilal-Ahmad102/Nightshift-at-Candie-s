extends Control

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var space_btn_hint: TextureRect = $space_btn_hint

const FILL_RATE := 80.0
const DECAY_RATE := 15.0
const MAX_VALUE := 100.0

var is_pressing := false
var hint_tween: Tween
var on_completed: Callable

func _ready() -> void:
	progress_bar.max_value = MAX_VALUE
	progress_bar.value = 0.0
	await get_tree().process_frame
	_animate_hint()

func _animate_hint() -> void:
	if hint_tween:
		hint_tween.kill()
	hint_tween = create_tween()
	hint_tween.set_loops()
	hint_tween.tween_property(space_btn_hint, "scale", Vector2(1.08, 1.08), 0.35)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	hint_tween.tween_property(space_btn_hint, "scale", Vector2(1.0, 1.0), 0.35)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	space_btn_hint.pivot_offset = space_btn_hint.size / 2.0

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept"):
		is_pressing = true
	elif event.is_action_released("ui_accept"):
		is_pressing = false

func _process(delta: float) -> void:
	if not visible:
		return
	if is_pressing:
		progress_bar.value = move_toward(progress_bar.value, MAX_VALUE, FILL_RATE * delta)
	else:
		progress_bar.value = move_toward(progress_bar.value, 0.0, DECAY_RATE * delta)

	if progress_bar.value >= MAX_VALUE:
		is_pressing = false
		progress_bar.value = 0.0
		
		if on_completed.is_valid():
			on_completed.call()

func reset() -> void:
	is_pressing = false
	progress_bar.value = 0.0
