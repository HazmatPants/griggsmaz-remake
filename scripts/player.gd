extends CharacterBody3D

@onready var camera := $Camera3D
@onready var front_ray := $Camera3D/RayCast3D

@export var walk_top_speed := 20.0
@export var sprint_top_speed := 40.0
@export var gravity := Vector3(0.0, -9.81, 0.0)
@export var mouse_sensitivity := 0.004

@export var viewbob_frequency: float = 6.0
@export var viewbob_amplitude: float = 0.01
var viewbob_time := 0.0
var viewbob_width := 1.0
var viewbob_height := 0.2

var speed := 0.0

var is_sprinting := false

var look_angle := Vector3.ZERO
var viewpunch := Vector3.ZERO
var viewpunch_target := Vector3.ZERO
var viewbob_rot := Vector3.ZERO

var mouse_delta := Vector2.ZERO

const SFX_FOOTSTEP = {
	"default": {
		"walk": [
			preload("res://assets/audio/sfx/player/footsteps/default/default_step1.wav"),
			preload("res://assets/audio/sfx/player/footsteps/default/default_step2.wav"),
			preload("res://assets/audio/sfx/player/footsteps/default/default_step3.wav"),
			preload("res://assets/audio/sfx/player/footsteps/default/default_step4.wav")
		]
	}
}

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_delta = event.relative

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		if front_ray.is_colliding():
			var collider = front_ray.get_collider()
			print(collider)
			if collider is Interactable:
				collider.interact()

var last_viewbob_y := 0.0
func _physics_process(delta: float) -> void:
	viewbob_time += (delta * viewbob_frequency) * (velocity.length() / 4)

	look_angle.x -= mouse_delta.y * mouse_sensitivity
	look_angle.y -= mouse_delta.x * mouse_sensitivity

	viewpunch_target.z -= velocity.dot(camera.global_basis.x) / 1000
	viewpunch_target.z -= mouse_delta.x / 2000

	viewpunch_target += Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	) * 0.0001

	viewpunch = viewpunch.lerp(viewpunch_target, 0.1)
	viewpunch_target = viewpunch_target.lerp(Vector3.ZERO, 0.1)

	look_angle += viewpunch

	var camera_angle := Vector3.ZERO
	camera_angle.x += look_angle.x
	camera_angle += viewpunch

	camera.rotation.x = lerp_angle(camera.rotation.x, camera_angle.x, 0.3)
	camera.rotation.y = camera_angle.y
	camera.rotation.z = camera_angle.z

	rotation.y = lerp_angle(rotation.y, look_angle.y, 0.3)

	var viewbob_y = sin(viewbob_time * 2.0) * viewbob_height

	if is_on_floor() and absf(velocity.length()) > 0.1:
		viewbob_rot = Vector3(
			viewbob_y,
			sin(viewbob_time) * viewbob_width,
			0.0
		) * 0.01
	else:
		viewbob_time = 0.0
		viewbob_rot = viewbob_rot.lerp(Vector3.ZERO, 0.01)

	camera.rotation += viewbob_rot

	if viewbob_y < 0.0 and last_viewbob_y > 0.0:
		Audio.playrandom3d(
			SFX_FOOTSTEP["default"]["walk"],
			global_position,
			0.1 if is_sprinting else 0.02
		)

	last_viewbob_y = viewbob_y

	camera.rotation.x = clampf(camera.rotation.x, deg_to_rad(-85), deg_to_rad(85))

	mouse_delta = Vector2.ZERO

	var forward := -global_basis.z
	var right := global_basis.x

	var input_vector := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	).normalized()

	if input_vector != Vector2.ZERO and is_on_floor():
		if is_sprinting:
			speed += 20.0 * delta
		else:
			speed += 70.0 * delta
	else:
		speed -= 45.0 * delta

	is_sprinting = Input.is_action_pressed("sprint")

	if is_sprinting:
		speed = clampf(speed, 0.0, sprint_top_speed)
	else:
		speed = clampf(speed, 0.0, walk_top_speed)

	var horizontal_velocity := velocity

	horizontal_velocity -= forward * input_vector.y * speed * delta
	horizontal_velocity += right * input_vector.x * speed * delta

	if is_on_floor():
		horizontal_velocity = horizontal_velocity.lerp(Vector3.ZERO, 0.1)

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

	velocity += gravity * delta

	move_and_slide()
