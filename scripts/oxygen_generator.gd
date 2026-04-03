extends StaticBody3D

var target_rot := Vector3.ZERO

var bond_plate: ItemCarbonBondPlate

var is_inserted := false

var enabled := false

func _ready() -> void:
	var plate = preload("res://scenes/carbon_bond_plate.tscn").instantiate()

	get_tree().current_scene.add_child.call_deferred(plate)

	await plate.tree_entered

	plate.global_position = to_global(Vector3(0, 0.15, 0))
	plate.global_basis = global_basis

func _process(delta: float) -> void:
	var station = get_tree().current_scene

	target_rot = Vector3(
		randf_range(-0.1, 0.1),
		0,
		randf_range(-0.1, 0.1),
	)

	$Laser.rotation = $Laser.rotation.lerp(target_rot, 0.06)

	if station.oxygen < 0.18:
		enabled = true
	if station.oxygen > 0.2:
		enabled = false

	if is_inserted and enabled:
		if not $AudioStreamPlayer3D.playing:
			$AudioStreamPlayer3D.play()
		$Laser.show()

		bond_plate.condition -= 0.0001 * delta
		station.oxygen += 0.0006 * delta

	else:
		$AudioStreamPlayer3D.stop()
		$Laser.hide()

	if bond_plate:
		var tx = global_transform

		tx.origin = to_global(Vector3(0, 0.15, 0))
		tx.basis = global_basis

		bond_plate.global_transform = bond_plate.global_transform.interpolate_with(tx, 0.2)

		if bond_plate.global_position.distance_to(tx.origin) < 0.01:
			if not is_inserted and enabled:
				Audio.playsound3d(
					preload("res://assets/audio/sfx/machine/laser_fire.wav"),
					global_position,
					0.2,
					&"Probe"
				)

			is_inserted = true

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is ItemCarbonBondPlate and not bond_plate:
		Audio.playsound3d(
			preload("res://assets/audio/sfx/machine/floppy_insert.ogg"),
			global_position,
			0.2,
			&"SFX",
			0.8
		)

		bond_plate = body

		bond_plate.is_inserted = true
		bond_plate.generator = self

		bond_plate.drop(GLOBAL.player)

		bond_plate.freeze = true
