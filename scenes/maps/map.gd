@tool
extends Node
class_name Map

@export_group("Required Nodes")

@export var player : Player

@export_subgroup("Navigation")
@export var nav_region : NavigationRegion3D

@export_subgroup("Holders")
@export var workshop_holder : Node
@export var enemy_holder : Node
@export var enemy_spawner_holder : Node


@export_group("Weather")
enum WEATHER {CLEAR, RAIN, SNOW}

@export var weather : WEATHER : set = set_weather
@export_range(0.0, 1.0, 0.01) var precipitation_ratio : float = 1 : set = set_precipitation
@export var precipitation_tween_speed : float = 3.0
@export var rain_particles : GPUParticles3D
@export var snow_particles : GPUParticles3D
@export var particles_height_map : GPUParticlesCollisionHeightField3D


@export_group("Wave")
@export var intermission : bool = false
@export var wave : int = 0


@export_group("Workshop")
@export var max_workshop_chance : int = 20
var waves_since_new_workshop : int = 0


@export_group("Enemies")
@export var max_enemies_alive : int

@export var basic_enemy_scene : PackedScene = preload("res://entities/enemies/basic enemy/basic_enemy.tscn")


func _ready():
	if not Engine.is_editor_hint(): Debug.map = self
	randomize()
	
	#Player Check
	assert(player, "No Player")
	
	#Nav Check
	assert(nav_region, "No Nav Region")
	assert(nav_region.navigation_mesh, "No Nav Mesh")
	assert(not nav_region.get_children().is_empty(), "No Mesh for navigation")
	#FIXME: nav_region.bake_navigation_mesh()
	
	#Holders Check
	assert(workshop_holder, "No Workshop Holder")
	assert(enemy_holder, "No Enemy Holder")
	assert(enemy_spawner_holder, "No Enemy Spawners Holder")
	
	
	#Weather
	assert(particles_height_map, "No Height Map for particles")
	
	precipitation_ratio = precipitation_ratio
	weather = weather
	
	#Workshop
	change_workshop()


func _process(delta):
	rain_particles.position = Vector3(player.position.x, rain_particles.position.y, player.position.z)
	snow_particles.position = Vector3(player.position.x, snow_particles.position.y, player.position.z)


#Weather
func set_precipitation(value : float):
		precipitation_ratio = value
		
		if not rain_particles or not snow_particles: return
		
		var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		tween.tween_property(rain_particles, "amount_ratio", precipitation_ratio, precipitation_tween_speed)
		tween.tween_property(snow_particles, "amount_ratio", precipitation_ratio, precipitation_tween_speed)


func set_weather(value : WEATHER):
	weather = value
	
	if not rain_particles or not snow_particles: return
	
	rain_particles.emitting = false
	snow_particles.emitting = false
	
	match weather:
		WEATHER.CLEAR:
			pass
		
		WEATHER.RAIN:
			assert(rain_particles, "No Rain Particles")
			rain_particles.emitting = true
		
		WEATHER.SNOW:
			assert(snow_particles, "No Snow Particles")
			snow_particles.emitting = true
	


#Waves
func start_intermission():
	print("intermission started")
	intermission = true


func new_wave():
	print("Wave: %s" % wave)
	intermission = false
	wave += 1
	roll_workshop()


#Workshop
func roll_workshop():
	var x = randi_range(0, max(max_workshop_chance - waves_since_new_workshop, 0))
	waves_since_new_workshop += 1
	
	if x == 0: change_workshop() 


func change_workshop():
	if not workshop_holder: return
	if workshop_holder.get_child_count() == 1: return
	
	var old_workshop : Interactable
	var new_workshop : Interactable
	
	#Save old workshop to prevent re-rolling the same workshop
	for child in workshop_holder.get_children():
		var workshop : Interactable = child
		
		if workshop.can_interact == true: old_workshop = workshop
	
	#Disable all workshops first
	for child in workshop_holder.get_children():
		var workshop : Interactable = child
		
		workshop.can_interact = false
	
	#Enable new workshop
	while true:
		new_workshop = workshop_holder.get_child(randi() % workshop_holder.get_child_count())
		
		if new_workshop != old_workshop: break
	
	new_workshop.can_interact = true
	waves_since_new_workshop = 0


#Enemies
func spawn_enemy():
	pass


func enemy_killed():
	pass


func kill_all_enemies():
	print("all enemies killed")
	for enemy in enemy_holder.get_children():
		enemy.dead()
