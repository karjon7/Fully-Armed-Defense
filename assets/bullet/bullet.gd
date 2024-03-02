extends Node3D
class_name Bullet

@export_group("Required Nodes")
@export var mesh : MeshInstance3D
@export var flyby_detection : Area3D
@export var light : OmniLight3D

@export_group("Bullet Hole")
@export var decal_bullet_hole : PackedScene

@export_group("Particle")
@export var particle_bullet_hit : PackedScene

@export_group("Sound")
@export var sound_bullet_hit : AudioStream
@export var sound_bullet_enemy_hit : AudioStream
@export var sound_bullet_flyby : AudioStream
@export var sound_bullet_ricochet : AudioStream


var bullet_speed : float = 50
var bullet_damage : float = 0
var bullet_knockback : float = 0

var bullet_fly_direction : Vector3
var prev_pos : Vector3 = Vector3()

var total_distance : float = 0
var max_distance : float = 100

var is_hit : bool = false

var disable_flyby_detect : bool = false

#Ricochet
var bounces_left : int = 3
var can_bounce : bool = false
var min_bounce_angle : float = 45

var pierce_left : int = 3
var can_pierce : bool = false


var color : Color = Color.GOLD
var energy : float = 0.25

var life_time : float = 30


var player : Player


func _ready():
	assert(mesh, "No Bullet Mesh")
	assert(flyby_detection, "No Flyby Detection")
	assert(light, "No Omni Light")
	
	bullet_fly_direction = global_transform.basis.z
	prev_pos = global_transform.origin
	
	light.omni_range = energy * 100
	light.light_energy = energy
	light.light_color = color
	mesh.mesh.surface_get_material(0).albedo_color = color * 100
	
	flyby_detection.body_entered.connect(flyby_detection_body_entered)
	flyby_detection.collision_layer = 0
	flyby_detection.collision_mask = pow(2, 2 - 1)
	
	get_tree().create_timer(life_time).timeout.connect(destroy)


func _physics_process(delta):
	#New pos of bullet
	var new_pos : Vector3 = global_transform.origin - (bullet_fly_direction * bullet_speed * delta)
	
	global_transform.origin = new_pos
	
	#Cast ray from prev to new pos
	var query = PhysicsRayQueryParameters3D.create(prev_pos, new_pos)
	
	query.exclude = [self] if not player else [self, player]
	
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	
	if result:
		is_hit = true
		new_pos = result.position if not result.collider.is_in_group("Enemy") else new_pos
		
		if result.collider.has_method("damage"):
			if result.collider.is_in_group("Enemy") and not result.collider.is_dead:
				player.money += bullet_damage
				spawn_sound_at_position(result.collider, result.position, sound_bullet_enemy_hit, -10)
				print("hit enemy")
			
			result.collider.damage(bullet_damage, result.position, bullet_fly_direction, bullet_knockback)
		
		if result.collider is CharacterBody3D:
			result.collider.velocity += bullet_fly_direction * bullet_knockback
			print("velocity added" + str(bullet_knockback))
		
		spawn_sound_at_position(result.collider, result.position, sound_bullet_hit)
		
		#Bounce
		if not result.collider.is_in_group("Enemy") and can_bounce:
			if bullet_fly_direction.angle_to(result.normal) >= deg_to_rad(min_bounce_angle) \
			and bounces_left > 0 and total_distance > 0.75:
				bullet_fly_direction = bullet_fly_direction.bounce(result.normal)
				bounces_left -= 1
				look_at(global_transform.origin - bullet_fly_direction, Vector3(1, 1, 0))
				spawn_sound_at_position(result.collider, result.position, sound_bullet_ricochet, -15)
			else:
				destroy()
		
		#Pierce
		elif result.collider.is_in_group("Enemy") and can_pierce:
			var enemy : Enemy = result.collider
			
			if pierce_left <= 0 and not enemy.is_dead: destroy()
			
			pierce_left -= 1 if not enemy.is_dead else 0
		
		#Didnt pierce or bounce
		else: 
			destroy()
	
	#
	total_distance += prev_pos.distance_to(new_pos)
	
	#Next frame
	prev_pos = new_pos
	
	#Max distance reached
	if total_distance >= max_distance: destroy()


func destroy():
	queue_free()


func spawn_sound_at_position(_owner : Node, _position : Vector3, sound : AudioStream, volume_db : float = 0):
	var sound_player = AudioStreamPlayer3D.new()
	_owner.add_child(sound_player)
	sound_player.global_position = _position
	sound_player.stream = sound
	sound_player.volume_db = volume_db
	sound_player.set_bus("Bullet SFX")
	sound_player.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_PHYSICS_STEP
	sound_player.play()
	
	await sound_player.finished
	sound_player.queue_free()


func spawn_bullet_hole_at_position(result : Dictionary, hole : PackedScene):
	pass


func spawn_particle_at_position(result : Dictionary, particlescene : PackedScene):
	pass


func flyby_detection_body_entered(body : Node3D):
	if not body is Player: return
	if not is_hit and player: return #player bullet hasn't ricocheted hit
	
	spawn_sound_at_position(get_tree().current_scene, global_position, sound_bullet_flyby)
