extends Node3D

func _on_area_3d_body_entered(_body: Node3D) -> void:
	Audio.playsound3d(
		preload("res://assets/audio/sfx/door/holo_enter.wav"),
		global_position,
		0.1,
		"Master",
		0.9
	)

func _on_area_3d_body_exited(_body: Node3D) -> void:
	Audio.playsound3d(
		preload("res://assets/audio/sfx/door/holo_exit.wav"),
		global_position,
		0.1,
		"Master",
		0.9
	)
