@tool
extends Interactable

@onready var mesh = $CSGCombiner3D


func _ready():
	$WorkshopHUD.hide()
	
	mesh.material_override = StandardMaterial3D.new()


func _process(delta):
	mesh.transparency = 0.0 if can_interact else 0.5
	mesh.material_override.albedo_color = Color.GREEN if can_interact else Color.RED


func _physics_process(delta):
	mesh.use_collision = can_interact


func interact():
	$WorkshopHUD.visible = !$WorkshopHUD.visible


func activate():
	can_interact = true


func deactivate():
	can_interact = false
