extends RigidBody3D
class_name  Item

@warning_ignore_start("unused_parameter")

func _pickup(player: CharacterBody3D):
	player.held_item = self
	gravity_scale = 0.0

func pickup(player: CharacterBody3D):
	_pickup(player)

func _drop(player: CharacterBody3D):
	gravity_scale = 1.0

	if player.held_item == self:
		player.held_item = null

func drop(player: CharacterBody3D):
	_drop(player)
