extends DirectionalLight3D

func _ready() -> void:
	await owner.ready
	for i in range(owner.generator.members):
		var member = preload("res://scenes/swarm_member.tscn").instantiate()

		$MeshInstance3D.add_child(member)
