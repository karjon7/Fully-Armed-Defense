extends Node
class_name Map

@export var new_wave_button : bool = false :
	set(value):
		new_wave_button = false
		new_wave()

@export_group("Required Nodes")

@export_subgroup("Navigation")
@export var nav_region : NavigationRegion3D

@export_subgroup("Holders")
@export var workshop_holder : Node


@export_group("Workshop")
@export var max_workshop_chance : int = 20
var waves_since_new_workshop : int = 0


@export_group("Wave")
@export var intermission : bool = false
@export var wave : int = 0


func _ready():
	randomize()
	
	#Nav Check
	assert(nav_region, "No Nav Region")
	assert(nav_region.navigation_mesh, "No Nav Mesh")
	assert(not nav_region.get_children().is_empty(), "No Mesh for navigation")
	#FIXME: nav_region.bake_navigation_mesh()
	
	#Holders Check
	assert(workshop_holder, "No Workshops")
	
	
	#
	change_workshop()


func new_wave():
	roll_workshop()


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
