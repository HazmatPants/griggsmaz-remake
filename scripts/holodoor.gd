extends Node3D

func _on_area_3d_body_entered(_body: Node3D) -> void:
	Audio.playsound(
		preload("res://assets/audio/sfx/door/holo_enter.wav"),
		0.1,
		"Master"
	)

func _on_area_3d_body_exited(_body: Node3D) -> void:
	Audio.playsound(
		preload("res://assets/audio/sfx/door/holo_exit.wav"),
		0.1,
		"Master"
	)
