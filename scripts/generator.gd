extends StaticBody3D

@onready var line = $SubViewport/Line2D

var speed := 512.0
var width := 512.0
var height := 512.0
var members: int = 64
var instability := 0.0
var output := 100.0
var heat := 900.0

func _process(delta: float) -> void:
	var points: PackedVector2Array = line.points

	output = members * 4 + randf_range(-10, 10)

	heat += randf_range(-10, 10)
	heat = clampf(heat, 600.0, 1100.0)
	instability += randf_range(-1, 1)
	instability = clampf(instability, -50.0, 50.0)

	points.append(Vector2(width, 256.0 + randf_range(-instability, instability)))

	for i in range(points.size() - 1, -1, -1):
		points[i].x -= speed * delta
		
		if points[i].x <= 0.0:
			points.remove_at(i)

	line.points = points
