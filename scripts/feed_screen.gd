extends StaticBody3D

@onready var mesh: MeshInstance3D = $MeshInstance3D2

var probe_bays = []
var probe_idx: int = 0

func _ready() -> void:
	for node in get_tree().current_scene.get_children():
		if node is ProbeBay:
			probe_bays.append(node)

var refresh_timer := 0.0

func _process(delta: float) -> void:
	refresh_timer += delta

	if refresh_timer > 0.5:
		refresh_timer = 0.0
		var bay = probe_bays.get(probe_idx)

		var probe = bay.probe

		if probe:
			var view: SubViewport = probe.view

			view.get_node("Label").text = "Probe %d" % probe_idx

			var img = view.get_texture().get_image()

			var texture = ImageTexture.create_from_image(img)

			var mat = StandardMaterial3D.new()

			mat.albedo_texture = texture

			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

			mesh.set_surface_override_material(0, mat)
