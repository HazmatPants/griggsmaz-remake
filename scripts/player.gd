extends CharacterBody3D

@onready var camera := $Camera3D
@onready var front_ray := $Camera3D/RayCast3D
@onready var collision_shape := $CollisionShape3D

@export var crouch_top_speed := 10.0
@export var walk_top_speed := 20.0
@export var sprint_top_speed := 50.0
@export var jump_power := 4.0
@export var gravity := Vector3(0.0, -9.81, 0.0)
@export var mouse_sensitivity := 0.004
@export var mouse_smoothness := 0.2

@export var viewbob_frequency: float = 6.0
@export var viewbob_amplitude: float = 0.01
var viewbob_time := 0.0
var viewbob_width := 0.5
var viewbob_height := 0.2

var speed := 0.0

var consciousness := 1.0
var oxygen := 0.2

var is_sprinting := false
var is_crouching := false
var can_move := true
var noclip := false

var look_angle := Vector3.ZERO
var viewpunch := Vector3.ZERO
var viewpunch_target := Vector3.ZERO
var viewbob_rot := Vector3.ZERO
var mouse_delta := Vector2.ZERO

var held_item: Item = null

const SFX_FOOTSTEP = {
	&"default": {
		&"walk": [
			preload("res://assets/audio/sfx/player/footsteps/default/default_step1.wav"),
			preload("res://assets/audio/sfx/player/footsteps/default/default_step2.wav"),
			preload("res://assets/audio/sfx/player/footsteps/default/default_step3.wav"),
			preload("res://assets/audio/sfx/player/footsteps/default/default_step4.wav")
		]
	},
	&"concrete": {
		&"walk": [
			preload("res://assets/audio/sfx/player/footsteps/concrete/walk/concrete_walk1.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/concrete/walk/concrete_walk2.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/concrete/walk/concrete_walk3.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/concrete/walk/concrete_walk4.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/concrete/walk/concrete_walk5.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/concrete/walk/concrete_walk6.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/concrete/walk/concrete_walk7.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/concrete/walk/concrete_walk8.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/concrete/walk/concrete_walk9.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/concrete/walk/concrete_walk10.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/concrete/walk/concrete_walk11.ogg"),
		]
	},
	&"metal": {
		&"walk": [
			preload("res://assets/audio/sfx/player/footsteps/metal/walk/metal_walk1.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/metal/walk/metal_walk2.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/metal/walk/metal_walk3.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/metal/walk/metal_walk4.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/metal/walk/metal_walk5.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/metal/walk/metal_walk6.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/metal/walk/metal_walk7.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/metal/walk/metal_walk8.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/metal/walk/metal_walk9.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/metal/walk/metal_walk10.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/metal/walk/metal_walk11.ogg"),
		]
	},
	&"alumalloy": {
		&"run": [
			preload("res://assets/audio/sfx/player/footsteps/alumalloy/run/alumalloy_run1.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/alumalloy/run/alumalloy_run2.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/alumalloy/run/alumalloy_run3.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/alumalloy/run/alumalloy_run4.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/alumalloy/run/alumalloy_run5.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/alumalloy/run/alumalloy_run6.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/alumalloy/run/alumalloy_run7.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/alumalloy/run/alumalloy_run8.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/alumalloy/run/alumalloy_run9.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/alumalloy/run/alumalloy_run10.ogg"),
		],
		&"walk": [
			preload("res://assets/audio/sfx/player/footsteps/alumalloy/walk/alumalloy_walk1.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/alumalloy/walk/alumalloy_walk2.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/alumalloy/walk/alumalloy_walk3.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/alumalloy/walk/alumalloy_walk4.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/alumalloy/walk/alumalloy_walk5.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/alumalloy/walk/alumalloy_walk6.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/alumalloy/walk/alumalloy_walk7.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/alumalloy/walk/alumalloy_walk8.ogg"),
			preload("res://assets/audio/sfx/player/footsteps/alumalloy/walk/alumalloy_walk9.ogg"),
		]
	}
}

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			mouse_delta = event.relative

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		if front_ray.is_colliding():
			var collider = front_ray.get_collider()
			if collider.has_method("interact"):
				collider.interact()
			elif collider is Item:
				if not held_item:   
					collider.pickup(GLOBAL.player)

	if Input.is_action_just_pressed("drop"):
		if held_item:
			held_item.drop(self)

	var station = get_tree().current_scene

	if is_sprinting:
		station.oxygen -= 0.0002 * delta

	station.oxygen -= 0.0001 * delta

	oxygen = lerpf(oxygen, station.oxygen, 0.005)
 
	consciousness -= ((0.2 - oxygen) * 4) * delta

	consciousness = lerpf(consciousness, 1.0, 0.01)

	if oxygen < 0.14:
		$PantSFX.volume_linear = lerpf($PantSFX.volume_linear, 0.05, 0.01)
	else:
		$PantSFX.volume_linear = lerpf($PantSFX.volume_linear, 0.0, 0.01)

	consciousness = clampf(consciousness, 0.0, 1.0)
	oxygen = clampf(oxygen, 0.0, 1.0)

	if is_unconscious():
		$UnconscAmb.volume_linear = lerpf($UnconscAmb.volume_linear, 1.0, 0.001)
	else:
		$UnconscAmb.volume_linear = lerpf($UnconscAmb.volume_linear, 0.0, 0.001)

var last_viewbob_y := 0.0
var was_on_floor := false
func _physics_process(delta: float) -> void:
	if is_sprinting:
		viewbob_time += (delta * viewbob_frequency) * (velocity.length() / 4)
	else:
		viewbob_time += (delta * viewbob_frequency) * (velocity.length() / 3)

	is_crouching = Input.is_action_pressed("crouch") and can_move

	collision_shape.disabled = noclip
	if noclip:
		velocity = Vector3.ZERO

	if is_crouching:
		if noclip:
			global_position.y -= 10.0 * delta
		else:
			collision_shape.shape.height = lerp(collision_shape.shape.height, 0.7, 0.05 * consciousness)
	elif is_unconscious():
		collision_shape.shape.height = lerp(collision_shape.shape.height, 0.2, 0.01)
	else:
		collision_shape.shape.height = lerp(collision_shape.shape.height, 2.0, 0.05 * consciousness)

	viewpunch = viewpunch.lerp(viewpunch_target, 0.1 * consciousness)
	viewpunch_target = viewpunch_target.lerp(Vector3.ZERO, 0.1 * consciousness)

	viewpunch_target += (Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	) * 0.0005) * (2.0 - consciousness)

	if can_move:
		camera.position.y += viewpunch.x
		camera.position = camera.position.lerp(Vector3(0, 0.6, 0), 0.3)
		look_angle.x -= mouse_delta.y * mouse_sensitivity
		look_angle.y -= mouse_delta.x * mouse_sensitivity

		viewpunch_target.z -= velocity.dot(camera.global_basis.x) / 1000
		viewpunch_target.z += mouse_delta.x / 2000

		var camera_angle := Vector3.ZERO
		camera_angle.x += look_angle.x
		camera_angle += viewpunch
  
		camera.rotation.x = lerp_angle(camera.rotation.x, camera_angle.x, mouse_smoothness * consciousness)
		camera.rotation.y = lerp_angle(camera.rotation.y, camera_angle.y, mouse_smoothness * consciousness)
		camera.rotation.z = lerp_angle(camera.rotation.z, camera_angle.z, mouse_smoothness * consciousness)

		rotation.y = lerp_angle(rotation.y, look_angle.y, mouse_smoothness * consciousness)

	var viewbob_y = sin(viewbob_time * 2.0) * viewbob_height

	if is_on_floor() and absf(velocity.length()) > 0.2:
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
		do_footstep_sfx()

	if not was_on_floor and is_on_floor(): # land
		do_footstep_sfx(10.0)
		viewpunch_target += Vector3(
			-0.3,
			0,
			0
		)

	last_viewbob_y = viewbob_y

	look_angle.x = clampf(look_angle.x, deg_to_rad(-85), deg_to_rad(85))

	mouse_delta = Vector2.ZERO

	var forward := -global_basis.z
	var right := global_basis.x

	var input_vector := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	).normalized()

	if Input.is_action_pressed("jump"):
		if noclip:
			global_position.y += 10.0 * delta
		else:
			viewpunch_target += Vector3(
				-0.01,
				0,
				0
			)

	if Input.is_action_just_released("jump") and can_move and not noclip:
		if is_on_floor():
			velocity.y += jump_power
			do_footstep_sfx(10.0)
			viewpunch_target += Vector3(
				0.1,
				0,
				0
			)

	if Input.is_action_pressed("zoom"):
		camera.fov = lerpf(camera.fov, 30.0, 0.2)
	else:
		camera.fov = lerpf(camera.fov, 75.0, 0.2)

	if not can_move:
		input_vector = Vector2.ZERO

	if input_vector != Vector2.ZERO and is_on_floor():
		if is_sprinting:
			speed += (40.0 * (oxygen / 0.17)) * delta
		else:
			speed += (70.0 * (oxygen / 0.17)) * delta
	else:
		speed -= 45.0 * delta

	is_sprinting = Input.is_action_pressed("sprint") and not is_crouching

	var top_speed: float

	if is_sprinting:
		top_speed = sprint_top_speed
	elif is_crouching:
		top_speed = crouch_top_speed
	else:
		top_speed = walk_top_speed

	top_speed *= oxygen / 0.17

	speed = clampf(speed, 0.0, top_speed)

	var horizontal_velocity := velocity

	if noclip:
		global_position -= (forward * 10.0) * input_vector.y * delta
		global_position += (right * 10.0) * input_vector.x * delta
	elif is_on_floor():
		horizontal_velocity -= forward * input_vector.y * speed * delta
		horizontal_velocity += right * input_vector.x * speed * delta
		horizontal_velocity = horizontal_velocity.lerp(Vector3.ZERO, 0.1)

	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

	if not noclip:
		velocity += gravity * delta

	was_on_floor = is_on_floor()

	move_and_slide()

	if held_item:
		held_item.global_position = held_item.global_position.lerp(camera.global_position - (camera.global_basis.z * 2), 0.2)

func get_floor_material():
	if $FootRay.is_colliding():
		var collider = $FootRay.get_collider()
		if collider:
			if collider.has_meta(&"material"):
				return collider.get_meta(&"material")
	return &"default"

func do_footstep_sfx(volume: float=1.0):
	var mat = get_floor_material()

	var sound_list = SFX_FOOTSTEP.get(mat, [])

	var vol = 0.05 if is_sprinting else 0.02

	Audio.playrandom3d(
		sound_list.get(&"run" if is_sprinting else &"walk", sound_list.get(&"walk", [])),
		global_position,
		vol * volume
	)

func is_unconscious() -> bool:
	return consciousness < 0.01
