extends MeshInstance3D


func animate_in() -> void:
	var tween = create_tween()
	tween.tween_property(self, "position:y", 1.0, 0.3)\
		.from(50.0)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_BOUNCE)

func animate_out() -> void:
	var tween = create_tween()
	tween.tween_property(self, "position:y", 50.0, 0.25)\
		.from(1.0)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_BACK)
