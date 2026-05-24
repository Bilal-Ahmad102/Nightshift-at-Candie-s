extends Node

## Animatronics emit this through GameManger to request a jumpscare.
## Connect each animatronic's `jumpscare_requested` signal to `_on_jumpscare_requested`.
signal jumpscare_shown(animatronic_id: String)
signal jumpscare_finished(animatronic_id: String)

signal game_over
signal night_won(night: int)
signal skip_monologue

## The Jumpscare node lives in the main scene. Assign it in the inspector,
## OR have the main scene call GameManger.set_jumpscare(node) on ready.
@export var jumpscare: Jumpscare


var can_dave_cam_error : bool = true

func _ready() -> void:
	SaveManager.load_save()
	_apply_saved_settings()
	if jumpscare != null:
		jumpscare.finished.connect(_on_jumpscare_finished)

func _apply_saved_settings() -> void:
	SaveManager.set_master_volume(SaveManager.get_master_volume())
	SaveManager.set_sfx_volume(SaveManager.get_sfx_volume())
	SaveManager.set_music_volume(SaveManager.get_music_volume())
	SaveManager.set_fullscreen(SaveManager.get_fullscreen())

func start_night(night: int) -> void:
	SaveManager.set_current_night(night)
	NightManager.start_night(night)
	GameClock.start_night(night)

func trigger_game_over() -> void:
	GameClock.stop()
	NightManager.end_night(false)
	emit_signal("game_over")

func trigger_night_won() -> void:
	var night = NightManager.current_night
	NightManager.end_night(true)
	SaveManager.unlock_night(night + 1)
	SaveManager.set_current_night(night + 1)
	SaveManager.save()
	emit_signal("night_won", night)

## Call this from the main scene if you can't set the export in the editor:
##     GameManger.set_jumpscare($Jumpscare)
func set_jumpscare(node: Jumpscare) -> void:
	if jumpscare != null and jumpscare.finished.is_connected(_on_jumpscare_finished):
		jumpscare.finished.disconnect(_on_jumpscare_finished)
	jumpscare = node
	if jumpscare != null:
		jumpscare.finished.connect(_on_jumpscare_finished)


## Register an animatronic so its jumpscare signal goes through GameManger.
## Call once per animatronic, e.g. from the main scene:
##     GameManger.register_animatronic($Dave)
func register_animatronic(animatronic: Node) -> void:
	if not animatronic.has_signal("jumpscare_requested"):
		push_warning("GameManger: %s has no 'jumpscare_requested' signal" % animatronic.name)
		return
	if not animatronic.jumpscare_requested.is_connected(_on_jumpscare_requested):
		animatronic.jumpscare_requested.connect(_on_jumpscare_requested)


# ---- Signal handlers --------------------------------------------------------

func _on_jumpscare_requested(animatronic_id: String) -> void:
	if jumpscare == null:
		push_error("GameManger: jumpscare node not assigned")
		return
	jumpscare.show_for(animatronic_id)
	jumpscare_shown.emit(animatronic_id)


func _on_jumpscare_finished(animatronic_id: String) -> void:
	jumpscare_finished.emit(animatronic_id)
	# TODO: trigger game over / restart night / etc.
	# Example:
	#   NightManager.end_night(false)
