extends Node

signal game_over
signal night_won(night: int)
signal skip_monologue
func _ready() -> void:
	SaveManager.load_save()
	_apply_saved_settings()

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
