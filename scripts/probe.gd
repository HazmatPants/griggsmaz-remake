extends RigidBody3D
class_name Probe

@onready var view := $SubViewport
@onready var camera := $SubViewport/Camera3D
@onready var collider := $CollisionShape3D

var targeting_enabled := false
var is_target_locked := false
var thruster := false
var is_docked := true
var is_scanning := false

var fuel := 1.0
var battery := 1.0

var bay: ProbeBay

var target := {}
var target_offset := Vector3.ZERO

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

	if target.is_empty(): 
		bay.probe_status = ProbeBay.PROBE_STATUS.IDLE
		return

	lock()

func lock():
	bay.probe_status = ProbeBay.PROBE_STATUS.APPROACH

	target_offset = Vector3(
		randf_range(-1, 1),
		randf_range(-1, 1),
		randf_range(-1, 1)
	) * 10.0

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
	cam_tx = cam_tx.translated(-global_basis.z * 2.3)
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

	if bay.probe_status == ProbeBay.PROBE_STATUS.MANUAL_CTRL:
		if GLOBAL.player.can_move: return
		thruster = Input.is_action_pressed("jump")

		angular_velocity -= basis.x * (Input.get_axis("move_backward", "move_forward") / 100)
		angular_velocity -= basis.y * (Input.get_axis("move_left", "move_right") / 100)
		angular_velocity -= basis.z * (Input.get_axis("roll_left", "roll_right") / 100)

		linear_velocity = linear_velocity.lerp(Vector3.ZERO, 0.02)
		angular_velocity = angular_velocity.lerp(Vector3.ZERO, 0.01)

	if targeting_enabled:
		if is_target_locked:
			if bay.probe_status == ProbeBay.PROBE_STATUS.APPROACH:
				global_transform = global_transform.interpolate_with(global_transform.looking_at(target["position"] + target_offset), 0.1)
			else:
				global_transform = global_transform.interpolate_with(global_transform.looking_at(target["position"]), 0.1)
		else:
			global_transform = global_transform.interpolate_with(global_transform.looking_at(target["position"] + target_offset), 0.01)

		if not is_target_locked and rad_to_deg((-global_basis.z).angle_to(target["position"])) < 10.0:
			target_locked.emit()
			is_target_locked = true

		if global_position.distance_to(target["position"]) < 30.0 and bay.probe_status == ProbeBay.PROBE_STATUS.APPROACH:
			thruster = false
			while linear_velocity.length() > 0.5:
				linear_velocity = linear_velocity.lerp(Vector3.ZERO, 0.01)
				await get_tree().process_frame
			bay.probe_status = ProbeBay.PROBE_STATUS.SCANNING
			is_scanning = true

func _process(delta: float) -> void:
	if is_docked:
		battery += 0.0008 * delta

	if is_scanning:
		if target["scan_progress"] < 1.0:
			target["scan_progress"] += delta / 200
			battery -= 0.0008 * delta
			if target.is_empty():
				bay.probe_status = ProbeBay.PROBE_STATUS.IDLE
				GLOBAL.player_log("%s target lost!" % name)
		else:
			bay.probe_status = ProbeBay.PROBE_STATUS.IDLE

	if bay.probe_status == ProbeBay.PROBE_STATUS.RETURN or bay.probe_status == ProbeBay.PROBE_STATUS.MANUAL_CTRL:
		if global_position.distance_squared_to(bay.global_position) < 10.0:
			var path = bay.get_node("Path3D/PathFollow3D")
			target = {}
			is_docked = true
			targeting_enabled = false
			is_target_locked = false
			thruster = false
			$ThrusterSFX.stop()
			linear_velocity = Vector3.ZERO
			global_position = path.global_position
			look_at(global_position + Vector3.FORWARD)
			bay.probe_status = ProbeBay.PROBE_STATUS.IDLE
			Audio.playsound3d(
				preload("res://assets/audio/sfx/machine/launcher_reload.ogg"),
				global_position,
				4.0,
				&"Probe",
				0.7
			)
			await get_tree().create_timer(2.0).timeout
			Audio.playsound3d(
				preload("res://assets/audio/sfx/machine/probe_load.ogg"),
				global_position,
				4.0,
				&"Probe",
				0.7
			)
			collider.disabled = true
			while path.progress_ratio > 0.0:
				path.progress_ratio -= 0.2 * delta
				global_position = path.global_position
				await get_tree().process_frame
			collider.disabled = false

	battery = clampf(battery, 0.0, 1.0)
	fuel = clampf(fuel, 0.0, 1.0)

func rtb():
	target = {}
	target["scan_progress"] = 1.0
	target["position"] = bay.global_position
	bay.probe_status = ProbeBay.PROBE_STATUS.RETURN
	targeting_enabled = true
	is_scanning = false
	await get_tree().create_timer(3.0).timeout
	thruster = true

func lerp_rot(from: Vector3, to: Vector3, weight: float) -> Vector3:
	var vec = from
	vec.x = lerp_angle(from.x, to.x, weight)
	vec.y = lerp_angle(from.y, to.y, weight)
	vec.z = lerp_angle(from.z, to.z, weight)
	return vec

func _on_area_3d_body_entered(_body: Node3D) -> void:
	if not linear_velocity.length() > 0.05: return
	thruster = false
	if bay.probe_status != ProbeBay.PROBE_STATUS.MANUAL_CTRL:
		bay.probe_status = ProbeBay.PROBE_STATUS.IDLE

	GLOBAL.player_log("%s collision detected!" % name)

func scan():
	if not target: return "no_target"
	if global_position.distance_to(target["position"]) > 30.0: return "out_of_range"

	targeting_enabled = false
	thruster = false
	while linear_velocity.length() > 0.5:
		linear_velocity = linear_velocity.lerp(Vector3.ZERO, 0.01)
		await get_tree().process_frame
	bay.probe_status = ProbeBay.PROBE_STATUS.SCANNING
	is_scanning = true
	return ""
