extends Node3D
class_name ProbeBay

enum PROBE_STATUS {
	APPROACH,
	IDLE,
	SCANNING,
	RETURN,
	MANUAL_CTRL
}

var probe_status := PROBE_STATUS.IDLE

var probe: Probe

var is_reloading := false

signal reloaded

func _ready() -> void:
	probe = preload("res://scenes/probe.tscn").instantiate()

	probe.name = name.replace("Bay", "")

	get_tree().current_scene.add_child.call_deferred(probe)

	probe.bay = self

	await probe.tree_entered

	%PathFollow3D.progress_ratio = 0.0
	probe.global_position = %PathFollow3D.global_position
	probe.look_at(probe.global_position + Vector3.FORWARD)

func launch() -> void:
	probe.launch()

func reload():
	if not probe.is_docked: 
		reloaded.emit(false)
		return

	await get_tree().create_timer(1.0).timeout

	is_reloading = true

	Audio.playsound3d(
		preload("res://assets/audio/sfx/machine/probe_load.ogg"),
		global_position,
		4.0,
		&"Probe",
		0.7
	)

func _physics_process(delta: float) -> void:
	if probe and probe.is_inside_tree() and is_reloading:
		probe.collider.disabled = true
		%PathFollow3D.progress_ratio += 0.2 * delta
		probe.global_position = %PathFollow3D.global_position
		if %PathFollow3D.progress_ratio >= 1.0:
			probe.collider.disabled = false
			reloaded.emit(true)
			is_reloading = false
