extends Node3D

var probe: RigidBody3D

var is_launching := false

func launch() -> void:
	if is_launching: return

	is_launching = true

	if not probe:
		reload()
		await get_tree().create_timer(5.0).timeout

	probe.launch()
	probe = null

	await get_tree().create_timer(3.0).timeout
	is_launching = false

func reload():
	if not probe:
		await get_tree().create_timer(1.0).timeout
		Audio.playsound3d(
			preload("res://assets/audio/sfx/machine/launcher_reload.ogg"),
			global_position,
			1.0,
			"Probe"
		)
		probe = preload("res://scenes/probe.tscn").instantiate()

		get_tree().current_scene.add_child(probe)

		probe.global_position = global_position - global_basis.y * 6.0
		probe.look_at(global_position)

func _physics_process(_delta: float) -> void:
	if probe:
		probe.global_position = probe.global_position.lerp(global_position + global_basis.y * 6.0, 0.05)
