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

var bullet_hit_pos : Vector3 = Vector3.ZERO

#Hit Label
@export_group("Hit Label")
@export var show_label : bool = false
@export var label_pos_lerp_speed : float = 15
@export var label_fade_lerp_speed : float = 5
@export var label_num_lerp_speed : float = 5
@export var label_time : float = 3
var label_damage : float = 0

#Signals
signal damage_taken


func _ready():
	assert(hit_label, "No Hit Label")
	assert(label_timer, "No Hit Label Timer")
	
	hit_label.modulate.a = 0


func _process(delta):
	hit_label_positioning(delta)
	hit_label_fade(delta)
	
	hit_label.text = str(floor(label_damage))

func hit_label_fade(delta):
	if not label_timer.time_left > 0: show_label = false 
	
	#Not even on screen (finally works)
	if (hit_label.position.x < 0) or (hit_label.position.x > get_window().size.x)\
	or (hit_label.position.y < 0) or (hit_label.position.y > get_window().size.y): 
		show_label = false 
		hit_label.modulate.a = 0
	
	hit_label.modulate.a = lerpf(hit_label.modulate.a, 0, label_fade_lerp_speed * delta) \
		if not show_label else 1
	
	if hit_label.modulate.a <= 0.01: label_damage = 0


func hit_label_positioning(delta):
	var new_label_pos = hit_label.position.lerp(\
		get_viewport().get_camera_3d().unproject_position(bullet_hit_pos),\
		label_pos_lerp_speed * delta)
	
	if not bullet_hit_pos: return
	hit_label.position = new_label_pos


func damage(damage_value : float, hit_pos : Vector3, bullet_direction : Vector3, knockback_force : float):
	damage_taken.emit()
	
	var new_damage = health if (health - damage_value) <= 0 else damage_value
	
	health -= new_damage
	
	bullet_hit_pos = hit_pos
	
	label_timer.start(label_time)
	label_damage += new_damage 
	show_label = true
