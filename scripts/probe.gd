extends RigidBody3D
class_name Probe

@onready var view := $SubViewport
@onready var camera := $SubViewport/Camera3D

var targeting_enabled := false
var is_target_locked := false
var thruster := false
var is_docked := true
var is_scanning := false

var fuel := 1.0
var battery := 1.0

var bay: ProbeBay

var target := {}

signal target_locked
signal launched

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
	var cam_tx = global_transform
	cam_tx = cam_tx.translated(-global_basis.z * 2.23)
	camera.global_transform = cam_tx

	$Thruster/GPUParticles3D.emitting = thruster
	if thruster:
		if linear_velocity.length() < 50.0:
			if not $ThrusterSFX.playing:
				$ThrusterSFX.play()
			apply_central_force(-global_basis.z * 10.0)
			fuel -= 0.005 * delta
		else:
			$ThrusterSFX.stop()

	if targeting_enabled:
		if is_target_locked:
			global_transform = global_transform.interpolate_with(global_transform.looking_at(target["position"]), 0.1)
		else:
			global_transform = global_transform.interpolate_with(global_transform.looking_at(target["position"]), 0.01)

		if not is_target_locked and rad_to_deg((-global_basis.z).angle_to(target["position"])) < 10.0:
			target_locked.emit()
			is_target_locked = true

		if global_position.distance_to(target["position"]) < 30.0 and bay.probe_status == ProbeBay.PROBE_STATUS.APPROACH:
			targeting_enabled = false
			thruster = false
			while linear_velocity.length() > 1.0:
				linear_velocity = linear_velocity.lerp(Vector3.ZERO, 0.1)
				await get_tree().process_frame
			bay.probe_status = ProbeBay.PROBE_STATUS.SCANNING
			is_scanning = true

func _process(delta: float) -> void:
	if is_docked:
		battery += 0.0008 * delta

	if is_scanning:
		if target["scan_progress"] < 1.0:
			#target["scan_progress"] += delta / 200
			target["scan_progress"] += delta / 20
			battery -= 0.0008 * delta
		else:
			target = {}
			target["scan_progress"] = 1.0
			target["position"] = bay.global_position
			bay.probe_status = ProbeBay.PROBE_STATUS.RETURN
			targeting_enabled = true
			is_scanning = false
			await get_tree().create_timer(5.0).timeout
			thruster = true

	if bay.probe_status == ProbeBay.PROBE_STATUS.RETURN:
		if global_position.distance_squared_to(bay.global_position) < 1.0:
			is_docked = true
			targeting_enabled = false
			is_target_locked = false
			thruster = false
			$ThrusterSFX.stop()
			linear_velocity = Vector3.ZERO
			global_position = bay.global_position - bay.global_basis.y
			bay.probe_status = ProbeBay.PROBE_STATUS.IDLE
			Audio.playsound3d(
				preload("res://assets/audio/sfx/machine/launcher_reload.ogg"),
				global_position,
				4.0,
				"Probe",
				0.7
			)

	battery = clampf(battery, 0.0, 1.0)
	fuel = clampf(fuel, 0.0, 1.0)

func lerp_rot(from: Vector3, to: Vector3, weight: float) -> Vector3:
	var vec = from
	vec.x = lerp_angle(from.x, to.x, weight)
	vec.y = lerp_angle(from.y, to.y, weight)
	vec.z = lerp_angle(from.z, to.z, weight)
	return vec
