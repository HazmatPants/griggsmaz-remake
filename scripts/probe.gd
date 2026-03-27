extends RigidBody3D

var targeting_enabled := false
var is_target_locked := false
var thruster := false

var target := Vector3(50, 30, -300)

signal target_locked

func launch():
	Audio.playsound3d(
		preload("res://assets/audio/sfx/machine/mortar_fire1.wav"),
		global_position,
		1.0,
		&"Probe"
	)

	apply_central_impulse(-global_basis.z * 4.0)

	await get_tree().create_timer(3.0).timeout

	targeting_enabled = true

	await target_locked

	await get_tree().create_timer(1.0).timeout

	Audio.playsound3d(
		preload("res://assets/audio/sfx/machine/thruster_ignition.wav"),
		global_position,
		1.0,
		&"Probe"
	)

	$ThrusterSFX.play()

	thruster = true

func _physics_process(_delta: float) -> void:
	$Thruster/GPUParticles3D.emitting = thruster
	if thruster:
		apply_central_force(-global_basis.z * 10.0)

	if targeting_enabled:
		if is_target_locked:
			global_transform = global_transform.interpolate_with(global_transform.looking_at(target), 0.2)
		else:
			global_transform = global_transform.interpolate_with(global_transform.looking_at(target), 0.01)

		if not is_target_locked and rad_to_deg((-global_basis.z).angle_to(target)) < 10.0:
			target_locked.emit()
			is_target_locked = true

		if global_position.distance_to(target) < 30.0:
			targeting_enabled = false
			thruster = false
			global_position = target
			Audio.playsound(preload("res://assets/audio/sfx/machine/target.wav"), 0.1)
