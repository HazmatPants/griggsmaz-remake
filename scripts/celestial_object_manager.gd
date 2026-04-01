extends Node

@export var max_bodies: int = 3

enum BODY_TYPE {
	RIFT
}

const BODY_SCENES = {
	BODY_TYPE.RIFT: preload("res://scenes/bodies/rift.tscn")
}

var spawn_timer := 58.0
var scanner_instability := randf_range(1.0, 1.5)

var body_count: int = 0

var bodies = {}

var scanned_bodies = {}

func _ready() -> void:
	spawn_body(Vector3(0, 0, -200), BODY_TYPE.RIFT, "test")
	scanned_bodies["test"] = bodies["test"]
	for i in range(randi_range(1, max_bodies)):
		spawn_body()

func _process(delta: float) -> void:
	spawn_timer += delta
	if spawn_timer > 60.0:
		if body_count < max_bodies:
			spawn_body()
		spawn_timer = 0.0

	scanner_instability += randf_range(-0.01, 0.01) * delta

	scanner_instability = clampf(scanner_instability, 1.0, 2.0)

	for body in bodies.values():
		body["scan_progress"] = clampf(body["scan_progress"], 0.0, 1.0)

func spawn_body(pos: Vector3=Vector3.ZERO, type: BODY_TYPE=BODY_TYPE.RIFT, id: String=""):
	var body_id = str(randi()) if not id else id
	var body_type = BODY_TYPE.values().pick_random() if not type else type
	var body_position = Vector3(
		randf_range(-5000, 5000),
		randf_range(-100, 100),
		randf_range(-5000, -100),
	) if not pos else pos

	bodies[body_id] = {
		"id": body_id,
		"type": body_type,
		"position": body_position, 
		"active": true,
		"scan_progress": 0.0
	}

	var body = BODY_SCENES[body_type].instantiate()

	get_tree().current_scene.add_child.call_deferred(body)

	await body.tree_entered

	body.global_position = body_position

	body_count += 1
