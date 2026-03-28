extends RigidBody3D
class_name Probe

@onready var view := $SubViewport
@onready var camera := $SubViewport/Camera3D

var targeting_enabled := false
var is_target_locked := false
var thruster := false
var is_docked := true
var is_scanning := false

var scan_progress := 0.0
var fuel := 1.0
var battery := 1.0

var bay: ProbeBay

var target := Vector3()

signal target_locked
signal launched

func _ready() -> void:
	target = global_position + Vector3(
		randf_range(-5000, 5000),
		randf_range(-50, 50),
		randf_range(-5000, -500),
	)

func launch():
	await get_tree().create_timer(1.0).timeout
	Audio.playsound3d(
		preload("res://assets/audio/sfx/machine/mortar_fire1.wav"),
		global_position,
		1.0,
		&"Probe"
	)

	apply_central_impulse(-global_basis.z * 4.0)

	is_docked = false

	launched.emit()

	bay.probe_status = ProbeBay.PROBE_STATUS.APPROACH

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

func _physics_process(delta: float) -> void:
	$Thruster/GPUParticles3D.emitting = thruster
	if thruster:
		if linear_velocity.length() < 30.0:
			if not $ThrusterSFX.playing:
				$ThrusterSFX.play()
			apply_central_force(-global_basis.z * 10.0)
			fuel -= 0.005 * delta
		else:
			$ThrusterSFX.stop()

	if targeting_enabled:
		if is_target_locked:
			global_transform = global_transform.interpolate_with(global_transform.looking_at(target), 0.2)
		else:
			global_transform = global_transform.interpolate_with(global_transform.looking_at(target), 0.01)

		if not is_target_locked and rad_to_deg((-global_basis.z).angle_to(target)) < 10.0:
			target_locked.emit()
			is_target_locked = true

		if global_position.distance_to(target) < 30.0 and bay.probe_status == ProbeBay.PROBE_STATUS.APPROACH:
			linear_velocity = Vector3.ZERO
			targeting_enabled = false
			thruster = false
			global_position = target + Vector3(
				randf_range(-1, 1),
				randf_range(-1, 1),
				randf_range(-1, 1)
			)
			bay.probe_status = ProbeBay.PROBE_STATUS.SCANNING
			is_scanning = true
			target = bay.global_position
			look_at(target)

func _process(delta: float) -> void:
	camera.global_position = global_position + Vector3(0, 0, -2.23)
	if is_docked:
		battery += 0.0008 * delta

	if is_scanning:
		if scan_progress < 1.0:
			scan_progress += delta / 200
			battery -= 0.0008 * delta
		else:
			bay.probe_status = ProbeBay.PROBE_STATUS.RETURN
			is_scanning = false
			thruster = true
			targeting_enabled = true

	if bay.probe_status == ProbeBay.PROBE_STATUS.RETURN:
		if global_position.distance_squared_to(bay.global_position) < 1.0:
			is_docked = true
			targeting_enabled = false
			is_target_locked = false
			thruster = false
			scan_progress = 0.0
			$ThrusterSFX.stop()
			linear_velocity = Vector3.ZERO
			global_position = bay.global_position - bay.global_basis.y
			bay.probe_status = ProbeBay.PROBE_STATUS.IDLE
			Audio.playsound3d(
				preload("res://assets/audio/sfx/machine/launcher_reload.ogg"),
				global_position,
				1.0,
				"Probe",
				0.7
			)


	scan_progress = clampf(scan_progress, 0.0, 1.0)
	battery = clampf(battery, 0.0, 1.0)
	fuel = clampf(fuel, 0.0, 1.0)
