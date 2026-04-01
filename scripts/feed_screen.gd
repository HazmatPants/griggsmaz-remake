extends StaticBody3D

@onready var mesh: MeshInstance3D = $MeshInstance3D2

var viewport: SubViewport = null
var camera: Camera3D = null
var feed_text: String = ""

var refresh_timer := 0.0

var is_terminal_open := false

func interact():
	is_terminal_open = true

func _process(delta: float) -> void:
	if is_terminal_open:
		var tx = global_transform

		tx = tx.translated(global_basis.z)

		GLOBAL.player.camera.global_transform = GLOBAL.player.camera.global_transform.interpolate_with(tx, 0.3)
		GLOBAL.player.can_move = false

		if Input.is_action_just_pressed("escape"):
			is_terminal_open = false
			GLOBAL.player.can_move = true

	if not viewport or not camera:
		mesh.set_surface_override_material(0, null)

		return
	refresh_timer += delta

	if refresh_timer > 0.1:
		refresh_timer = 0.0
		var img = viewport.get_texture().get_image()

		var dist = Vector3.ZERO.distance_to(camera.global_position)

		for px in range(dist):
			var x = randi_range(0, img.get_size().x - 1)
			var y = randi_range(0, img.get_size().y - 1)

			img.set_pixel(x, y, Color(randf(), randf(), randf()))

		var texture = ImageTexture.create_from_image(img)

		var mat = StandardMaterial3D.new()

		mat.albedo_texture = texture
		mat.emission_texture = texture
		mat.emission_enabled = true
		mat.emission_energy_multiplier = 6.0

		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

		mesh.set_surface_override_material(0, mat)
		$SubViewport2/Label.text = feed_text
