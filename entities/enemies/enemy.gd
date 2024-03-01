extends CharacterBody3D
class_name Enemy

#Required Nodes
@export_group("Required Nodes")

@export_subgroup("Hit Label")
@export var hit_label : Label
@export var label_timer : Timer

#Health
@export_group("Health")
@export var invincible : bool = false
@export var start_health : float = 100
var health : float = start_health
var is_dead : bool = false

var bullet_hit_pos : Vector3 = Vector3.ZERO

#Hit Label
@export_group("Hit Label")
@export var label_pos_lerp_speed : float = 15
@export var label_fade_lerp_speed : float = 5
@export var label_num_lerp_speed : float = 5
@export var label_time : float = 3
var show_label : bool = false
var label_damage : float = 0

#Signals
signal damage_taken


func _ready():
	assert(hit_label, "No Hit Label")
	assert(label_timer, "No Hit Label Timer")
	
	hit_label.modulate.a = 0


func _process(delta):
	handle_hit_label(delta)
	
	


func handle_hit_label(delta):
	hit_label.text = str(floor(label_damage))
	
	#Fade
	
	if not label_timer.time_left > 0: show_label = false 
	
	hit_label.modulate.a = lerpf(hit_label.modulate.a, 0, label_fade_lerp_speed * delta) \
		if not show_label else 1.0
	
	if hit_label.modulate.a <= 0.01: label_damage = 0
	
	#Position
	var current_cam = get_viewport().get_camera_3d()
	
	#Not even on screen (finally works(ish))
	if not current_cam.is_position_in_frustum(bullet_hit_pos):
		
		show_label = false 
		hit_label.modulate.a = 0.0
	
	var new_label_pos = hit_label.position.lerp(\
		current_cam.unproject_position(bullet_hit_pos),\
		label_pos_lerp_speed * delta)
	
	if not bullet_hit_pos: return
	hit_label.position = new_label_pos


func damage(damage_value : float, hit_pos : Vector3, bullet_direction : Vector3, knockback_force : float):
	if is_dead: return
	
	damage_taken.emit()
	
	var new_damage = health if (health - damage_value) <= 0.0 else damage_value
	new_damage = new_damage if not invincible else 0.0
	
	health -= new_damage
	if health == 0: dead()
	
	bullet_hit_pos = hit_pos
	
	label_timer.start(label_time)
	label_damage += new_damage 
	show_label = true


func dead():
	is_dead = true
	
	await get_tree().create_timer(3).timeout
	
	queue_free()


func navigation():
	pass
