extends CharacterBody3D
class_name Player

#UI
@onready var hud : Control = %HUD
@onready var menu_overlay = %MenuOverlay
@onready var pause_menu = %PauseMenu
@onready var debug_ui = %DebugUI

#View
@onready var camera = %Camera3D
@onready var arm_model = %arm_model

#Shooting
@onready var view_cast = %ViewCast
@onready var fire_point = %FirePoint
@onready var interact_reach = %InteractReach
@onready var melee_box = %MeleeBox
@onready var arm_clearance = %ArmClearance
@onready var fire_rate_timer = %FireRateTimer
@onready var overheat_timer = %OverheatTimer

#Anims
@onready var animation_tree = %AnimationTree

#Audio
@onready var overheat_alarm_audio = %OverheatAlarm
@onready var overheated_audio = %Overheated
@onready var arm_cooling_audio = %ArmCooling

@onready var money_transaction = %MoneyTransaction


@export var test : bool = false : 
	set(value):
		test = value
		print(value)


#UI
@export_group("UI")
@export var menu_open : bool = false : set = _set_menu_overlay
@export var menu_tween_speed : float = 0.5


#Health
@export_group("Health")
@export var invincible : bool = false
@export var hidden : bool = false
@export var max_health : float = 100
var health : float = max_health : set = set_health

#Money
@export_group("Money")
@export var money : int = 0 :
	set(value):
		if value < money: money_transaction.play()
		
		money = value

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
var shot_clear = true
@export var arm_data : ArmData 

@export_subgroup("Heat")
var is_overheated : bool = false
var arm_temp : float = 20
@export var can_overheat : bool = false
@export var base_arm_temp : float = 20
@export var max_arm_temp : float = 1500
@export var heat_loss_rate_per_sec : float = 250
const OVERHEAT_TIME : float = 3

@export_subgroup("Arm Settings")
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
@export var flying = false
@export var can_no_clip = false
@export var can_move = true
@export var can_jump = true

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
	Debug.player = self
	
	spawn_point = position
	camera_base_fov = camera.fov
	
	hud.show()
	pause_menu.hide()
	debug_ui.hide()
	menu_open = false
	


func _unhandled_input(event):
	var anim_node : AnimationNode = animation_tree.get_tree_root().get_node("Shoot")
	
	if event is InputEventMouseMotion: #Mouse Motion
		if can_look: camera_input = -event.relative
	
	#DEPRECATED
	#if Input.is_action_just_pressed("primary_fire"):
	#	var anim_recoil = animation_tree.get("parameters/Recoil State/current_state")
	#	
	#	anim_node.filter_enabled = false if anim_recoil == "Laser Recoil" else true
	#	
	#	animation_tree.set("parameters/Shoot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	
	#FIXME
	if Input.is_action_just_released("primary_fire"):
		if not animation_tree.get("parameters/Recoil State/current_state") == "Laser Recoil": return
		
		animation_tree.set("parameters/Shoot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)
	
	
	if Input.is_action_just_pressed("interact"):
		if not interact_reach.is_colliding(): return
		
		var interactable : Interactable = interact_reach.get_collider()
		
		interactable.interact()
	
	
	if Input.is_action_just_pressed("melee"):
		if animation_tree.get("parameters/Melee/active"): return
		
		animation_tree.set("parameters/Melee/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	


func _physics_process(delta):
	#TESTING
	var target_point : Vector3 = view_cast.get_target_position()
	var hit_point : Vector3 = view_cast.get_collision_point() if view_cast.is_colliding() else view_cast.to_global(target_point)
	$LookMarker.global_position = hit_point
	
	fire_point.look_at(hit_point)
	fire_point.rotation = Vector3(0, 0, 0) if view_cast.global_position.distance_to(hit_point) < 1.5 else fire_point.rotation
	shot_clear = !arm_clearance.has_overlapping_bodies()
	
	handle_shooting()
	handle_arms(delta)
	handle_temperature()
	handle_camera(delta)
	handle_movement(delta)
	#print(melee_box.monitoring)


func _set_menu_overlay(value):
	menu_open = value
	
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(menu_overlay.material, "shader_parameter/effect_amount", float(menu_open), menu_tween_speed)
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if menu_open else Input.MOUSE_MODE_CAPTURED
	#menu_overlay.visible = menu_open
	hud.visible = !menu_open
	
	can_look = !menu_open
	can_shoot = !menu_open
	can_move = !menu_open
	can_jump = !menu_open


func set_health(value):
	health = clamp(value, 0, max_health)


func deposit_money(value : int):
	money += value
	money_transaction.play()


func damage(damage_value : float, hit_pos : Vector3, bullet_direction : Vector3):
	health -= damage_value
	
	print("player_hit")


func melee(body: Node3D):
	print("meleed")


func shoot_bullets():
	#Anims
	var anim_shoot_node : AnimationNode = animation_tree.get_tree_root().get_node("Shoot")
	
	anim_shoot_node.filter_enabled = true #false only for laser recoil
	animation_tree.set("parameters/Recoil State/transition_request", arm_data.recoil_type)
	animation_tree.set("parameters/Shoot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	animation_tree.set("parameters/Shoot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	
	#Instancing Bullet and Particles
	var bullet : Bullet = arm_data.shoot_scene.instantiate()
	var particles : ArmParticles = arm_data.shoot_particles_scene.instantiate()
	
	#Constant Player Assignment
	if can_overheat: arm_temp += arm_data.heat_per_shot
	
	#General Shot Assignment
	bullet.color = arm_data.light_color
	bullet.energy = arm_data.light_energy
	
	#Bullet Specific Assignment
	bullet.bullet_speed = arm_data.bullet_speed
	bullet.bullet_damage = arm_data.bullet_damage
	bullet.bullet_knockback = arm_data.bullet_knockback
	bullet.max_distance = arm_data.bullet_range
	bullet.pierce_left = arm_data.bullet_pierce
	bullet.bounces_left = arm_data.bullet_bounces
	bullet.min_bounce_angle = arm_data.min_bounce_angle
	
	#Player Bullet Constants
	bullet.can_bounce = true
	bullet.can_pierce = true
	bullet.disable_flyby_detect = true
	bullet.player = self
	fire_point.add_child(bullet)
	bullet.top_level = true
	
	fire_point.add_child(particles)
	particles.color = arm_data.light_color
	particles.emit_particles()
	
	#Audio
	var sound_player = AudioStreamPlayer3D.new()
	
	fire_point.add_child(sound_player)
	
	sound_player.stream = arm_data.shoot_sound
	sound_player.pitch_scale = remap(arm_temp, base_arm_temp, max_arm_temp, 1, 1.1)
	sound_player.set_bus("Bullet SFX")
	sound_player.play()
	
	sound_player.finished.connect(func(): sound_player.queue_free())
	
	#Setup Timer
	fire_rate_timer.start(60.0 / arm_data.shots_per_min)
	


func handle_shooting():
	#Requirments
	if not arm_data: return #Arm data actually exist 
	if not can_shoot: return #Allowed to shoot
	if not shot_clear: return #Not clear to shoot
	if is_overheated: return
	if fire_rate_timer.get_time_left() > 0: return
	if overheat_timer.get_time_left() > 0: return
	
	view_cast.target_position = Vector3(0, 0, -arm_data.bullet_range)
	
	#Firing
	#Semi auto firing
	if not arm_data.is_auto and Input.is_action_just_pressed("primary_fire"): shoot_bullets()
	
	#Auto firing
	if arm_data.is_auto and Input.is_action_pressed("primary_fire"): shoot_bullets()


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


func handle_temperature():
	if arm_temp <= base_arm_temp: is_overheated = false
	
	#Audio
	arm_cooling_audio.pitch_scale = remap(arm_temp, base_arm_temp, max_arm_temp, 1, 4)
	arm_cooling_audio.volume_db = remap(arm_temp, base_arm_temp, max_arm_temp, -40, 0) - 10
	
	overheat_alarm_audio.volume_db = remap(arm_temp, base_arm_temp, max_arm_temp, -50, 0) - 20
	if is_overheated and not overheat_alarm_audio.playing: overheat_alarm_audio.play()
	
	arm_temp = max(arm_temp - heat_loss_rate_per_sec / 60, base_arm_temp) \
	if overheat_timer.time_left <= 0 else arm_temp
	
	
	if arm_temp < max_arm_temp or is_overheated: return #Return if not overheated
	is_overheated = true
	arm_temp = max_arm_temp
	overheat_timer.start(OVERHEAT_TIME)
	overheated_audio.pitch_scale = randf_range(0.8, 1.2)
	overheated_audio.play()


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


func handle_flying(delta):
	pass


func handle_movement(delta):
	#Input
	input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Add Gravity
	if not is_on_floor() and gravity_on:
		velocity.y -= gravity * delta
	
	# Handle Jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and can_jump: 
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
