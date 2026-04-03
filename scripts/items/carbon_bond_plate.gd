extends Item
class_name ItemCarbonBondPlate

var is_inserted := false

var generator: StaticBody3D

var condition := 1.0

func pickup(player: CharacterBody3D):
	if is_inserted:
		if generator:
			generator.is_inserted = false
			generator.bond_plate = null
		remove()
		Audio.playsound3d(
			preload("res://assets/audio/sfx/machine/floppy_eject.ogg"),
			global_position,
			0.2,
			&"SFX",
			0.8
		)
		return
	freeze = false
	_pickup(player)

func remove():
	is_inserted = false
	freeze = false
	gravity_scale = 1.0

	apply_central_impulse(-global_basis.x * 5)
