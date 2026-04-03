extends Node3D

func _ready() -> void:
	global_rotate(Vector3.RIGHT, randf_range(0, TAU))

func _process(delta: float) -> void:
	global_position = get_parent().global_position

	global_position += global_basis.z * 100.0

	global_rotate(Vector3.RIGHT, 0.1 * delta)
