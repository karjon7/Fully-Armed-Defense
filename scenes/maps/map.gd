extends Node3D
class_name Map

@export_group("Required Nodes")

@export_subgroup("Navigation")
@export var nav_region : NavigationRegion3D


func _ready():
	#Nav Check
	assert(nav_region, "No Nav Region")
	assert(nav_region.navigation_mesh, "No Nav Mesh")
	assert(not nav_region.get_children().is_empty(), "No Mesh for navigation")
	#nav_region.bake_navigation_mesh()
