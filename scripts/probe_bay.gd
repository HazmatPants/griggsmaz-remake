extends Node3D
class_name ProbeBay

enum PROBE_STATUS {
	APPROACH,
	IDLE,
	SCANNING,
	RETURN,
}

var probe_status := PROBE_STATUS.IDLE

var probe: Probe

var is_reloading := false

signal reloaded

func _ready() -> void:
	probe = preload("res://scenes/probe.tscn").instantiate()
	get_tree().current_scene.add_child.call_deferred(probe)

	probe.bay = self

	await probe.tree_entered

	probe.global_position = global_position - global_basis.y

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
		"Probe",
		0.9
	)

	probe.global_position = global_position + Vector3.BACK
	probe.look_at(global_position)
	reloaded.emit(true)
	await get_tree().create_timer(1.0).timeout
	is_reloading = false

func _physics_process(_delta: float) -> void:
	if probe and probe.is_inside_tree() and is_reloading:
		probe.global_position = probe.global_position.lerp(global_position + global_basis.y * 6.0, 0.05)
