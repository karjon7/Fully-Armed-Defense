extends CharacterBody3D

@onready var camera = %Camera3D
@onready var arm_model = %arm_model

@onready var ray_cast_3d = %RayCast3D
@onready var fire_point = %FirePoint

@onready var animation_tree = %AnimationTree


#Health
@export_group("Health")
@export var invincible : bool = false

#Money
@export_group("Money")
@export var money : float = 0.0

#Camera
@export_group("Camera")
@export var can_look : bool = true
@export_range(0.01, 0.1, 0.01) var mouse_sensitivity : float = 0.05
@export var fov_effects : bool = true
@export_range(0.25, 2.0, 0.05) var fov_multiplier : float = 1
@export_range(0.25, 1) var camera_min_fov_multiplier : float = 0.75
@export_range(1, 2) var camera_max_fov_multiplier : float = 1.25

var camera_input : Vector2
var camera_rotation_velocity : Vector2
var camera_base_fov : int
const LOOK_SMOOTHNESS = 50.0
const TILT_SMOOTHNESS = 20.0
const MAX_CAMERA_LOOK_ANGLE_DEGREES = 90
const MAX_CAMERA_TILT_DEGREES = 2.5

#Arms
@export_group("Arms")
@export var can_shoot : bool = true
@export_range(1, 3, 0.1) var arm_tilt_amount : float = 2
@export_range(0.1, 2, 0.1) var arm_offset_amount : float = 0.1
@export var arm_sway_amount : float = 0.05
@export var max_sway_angle : float = 10.0

var current_arm_sway = Vector2.ZERO
var current_arm_offset = 0.0
const SWAY_SMOOTHNESS = 6

#Movement
@export_group("Movement")
@export var gravity_on = true
@export var can_move = true

var spawn_point : Vector3
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var input_dir : Vector2
const SPEED = 7.5
const SPRINT_SPEED = 10.0
const JUMP_VELOCITY = 4.5
const ACCELERATION = 10.0
const AIR_ACCELERATION = 3.0

#States
var sprinting : bool = false

#Animation
var anim_walk_blend : float = 0

#Perks
@export_group("Perks")
@export var perks_on : bool = true


func _ready():
	spawn_point = position
	camera_base_fov = camera.fov
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event):
	var anim_node : AnimationNode = animation_tree.get_tree_root().get_node("Shoot")
	
	if event is InputEventMouseMotion: #Mouse Motion
		if can_look: camera_input = -event.relative
	
	#FIXME
	if Input.is_action_just_pressed("primary_fire"):
		var anim_recoil = animation_tree.get("parameters/Recoil State/current_state")
		
		anim_node.filter_enabled = false if anim_recoil == "Laser Recoil" else true
		
		animation_tree.set("parameters/Shoot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	#FIXME
	if Input.is_action_just_released("primary_fire"):
		if not animation_tree.get("parameters/Recoil State/current_state") == "Laser Recoil": return
		
		animation_tree.set("parameters/Shoot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)
	
	if Input.is_action_just_pressed("melee"):
		if animation_tree.get("parameters/Melee/active"): return
		
		animation_tree.set("parameters/Melee/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		
	
	if Input.is_action_just_pressed("quit"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
		can_look = true if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else false
	




func _physics_process(delta):
	handle_arms(delta)
	handle_camera(delta)
	handle_movement(delta)


func handle_arms(delta):
	#Arm Tilt
	current_arm_sway.x += arm_tilt_amount * move_toward(camera.rotation_degrees.y, \
	(-velocity.dot(global_transform.basis.x) / SPEED) * float(is_on_floor()), \
	SWAY_SMOOTHNESS * delta)
	
	#Arm Offset
	current_arm_sway.y += lerpf(current_arm_offset, -velocity.y * arm_offset_amount, SWAY_SMOOTHNESS * delta)
	
	#Arms Sway
	current_arm_sway = current_arm_sway.lerp(camera_input * arm_sway_amount, SWAY_SMOOTHNESS * delta)
	
	var sway_x = clamp(current_arm_sway.x, -max_sway_angle, max_sway_angle)
	var sway_y = clamp(current_arm_sway.y, -max_sway_angle, max_sway_angle)
	
	arm_model.rotation_degrees.x = -sway_y
	arm_model.rotation_degrees.y = sway_x - 180
	


func handle_camera(delta):
	#Rotation Lerp
	camera_rotation_velocity = camera_rotation_velocity.lerp(camera_input * mouse_sensitivity, LOOK_SMOOTHNESS * delta)
	
	#Apply Rotation
	rotate_y(camera_rotation_velocity.x * mouse_sensitivity)
	camera.rotate_x(camera_rotation_velocity.y * mouse_sensitivity)
	
	#Roll Tilt
	camera.rotation_degrees.z = move_toward(camera.rotation_degrees.z, \
	((-velocity.dot(global_transform.basis.x) / SPEED) * MAX_CAMERA_TILT_DEGREES) * float(is_on_floor()), \
	(TILT_SMOOTHNESS / 2) * delta)
	
	#Fov Scale
	var wish_fov = lerpf(camera_base_fov, camera_base_fov * 1.1, -velocity.dot(global_transform.basis.z) * fov_multiplier / SPEED)
	wish_fov = clamp(wish_fov, camera_base_fov * camera_min_fov_multiplier, camera_base_fov * camera_max_fov_multiplier)
	
	camera.fov = wish_fov if fov_effects else camera.fov #if wish_fov > camera_base_fov else camera_base_fov
	
	#Clamps
	camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -MAX_CAMERA_LOOK_ANGLE_DEGREES, MAX_CAMERA_LOOK_ANGLE_DEGREES)
	camera.rotation_degrees.y = clamp(camera.rotation_degrees.y, 0, 0)
	camera.rotation_degrees.z = clamp(camera.rotation_degrees.z, -MAX_CAMERA_TILT_DEGREES, MAX_CAMERA_TILT_DEGREES)
	
	#
	camera_input = Vector2.ZERO


func handle_movement(delta):
	#Input
	input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Add Gravity
	if not is_on_floor() and gravity_on:
		velocity.y -= gravity * delta
	
	# Handle Jump
	if Input.is_action_just_pressed("jump") and is_on_floor(): 
		velocity.y = JUMP_VELOCITY
		#Little horizontal boost when jumping
		velocity.x *= 1.1
		velocity.z *= 1.1
	
	# Handle Sprinting
	sprinting = true if Input.is_action_pressed("sprint") and \
				Input.is_action_pressed("forward") and \
				is_on_floor() else false
	
	#Calculate Movement
	var wish_velocity = direction * SPEED if can_move else Vector3.ZERO
	wish_velocity = direction * SPRINT_SPEED if sprinting else wish_velocity
	
	var accel = ACCELERATION if is_on_floor() else AIR_ACCELERATION
	
	velocity.x = velocity.lerp(wish_velocity, accel * delta).x
	velocity.z = velocity.lerp(wish_velocity, accel * delta).z
	
	move_and_slide()
	
	# Animations
	var blend_velocity = Vector2(velocity.x, velocity.z)
	var blend_value = remap(blend_velocity.length(), 0, SPEED, 0, 1) + remap(blend_velocity.length(), SPEED, SPRINT_SPEED, 0, 1)
	
	anim_walk_blend = lerpf(anim_walk_blend, blend_value, accel * delta)
	
	animation_tree.set("parameters/Grounded/transition_request", "Grounded" if is_on_floor() else "Not Grounded")
	animation_tree.set("parameters/Walk Blend/blend_position", clamp(anim_walk_blend, 0, 2))
