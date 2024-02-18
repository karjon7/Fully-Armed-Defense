extends Control

@onready var camera = %Camera3D

@onready var view_cast = %ViewCast
@onready var fire_cast = %FireCast
@onready var fire_point = %FirePoint
@onready var arm_clearance = %ArmClearance

@onready var crosshair = %Crosshair


@export var player : Player

@export_group("Crosshair")
@export var crosshair_rotation_degrees : int = 0
@export var crosshair_spacing : int = 7
@export var crosshair_length : int = 7
@export var crosshair_width : int = 2
@export var crosshair_lerp_speed : float = 10

var arm_cleared : bool = true

var new_crosshair_pos : Vector2
var crosshair_pos_lerp_speed : float = 5


func _ready():
	pass # Replace with function body.


#FIXME
func _process(delta):
	#Crosshair Aiming
	check_clearance()
	
	var target_point : Vector3 = view_cast.get_target_position()
	var point_collision : Vector3 = view_cast.get_collision_point() if view_cast.is_colliding() else view_cast.to_global(target_point)
	
	fire_cast.look_at(fire_cast.to_local(point_collision))
	fire_cast.set_target_position(fire_cast.to_local(point_collision))
	#FIXME: move to player.gdfor clearity ^
	
	var unprojected_view_cast : Vector2 = camera.unproject_position(view_cast.get_collision_point() \
	if view_cast.is_colliding() else view_cast.to_global(view_cast.get_target_position()))
	var unprojected_fire_cast : Vector2 = camera.unproject_position(fire_cast.get_collision_point() \
	if fire_cast.is_colliding() else fire_cast.to_global(fire_cast.get_target_position()))
	
	new_crosshair_pos = unprojected_fire_cast if fire_cast.is_colliding() and arm_cleared \
	and unprojected_fire_cast.distance_to(unprojected_view_cast) > 10 and not player.sprinting else unprojected_view_cast
	
	crosshair.modulate = Color.WHITE if arm_cleared else Color.RED
	crosshair.position = crosshair.position.lerp(new_crosshair_pos - crosshair.size / 2, crosshair_pos_lerp_speed * delta)
	
	#Crosshair Styling
	crosshair_style(delta)
	
	crosshair_rotation_degrees = 45 if not arm_cleared \
	or (fire_cast.get_collider() and fire_cast.get_collider().is_in_group("Enemy")) \
	or (view_cast.get_collider() and view_cast.get_collider().is_in_group("Enemy")) else 0
	
	crosshair_spacing = 0 if not arm_cleared else 7
	crosshair_length = 10 if not arm_cleared else 7
	


func crosshair_style(delta):
	#Width
	for line in crosshair.get_children():
		line.width = crosshair_width
	
	#Spacing
	%Line2D.points[0].x = lerpf(%Line2D.points[0].x, -crosshair_spacing, crosshair_lerp_speed * delta)
	%Line2D2.points[0].x = lerpf(%Line2D2.points[0].x, crosshair_spacing, crosshair_lerp_speed * delta)
	%Line2D3.points[0].y = lerpf(%Line2D3.points[0].y, -crosshair_spacing, crosshair_lerp_speed * delta)
	%Line2D4.points[0].y = lerpf(%Line2D4.points[0].y, crosshair_spacing, crosshair_lerp_speed * delta)
	
	#Length
	%Line2D.points[1].x = lerpf(%Line2D.points[1].x, -crosshair_spacing - crosshair_length, crosshair_lerp_speed * delta)
	%Line2D2.points[1].x = lerpf(%Line2D2.points[1].x, crosshair_spacing + crosshair_length, crosshair_lerp_speed * delta)
	%Line2D3.points[1].y = lerpf(%Line2D3.points[1].y, -crosshair_spacing - crosshair_length, crosshair_lerp_speed * delta)
	%Line2D4.points[1].y = lerpf(%Line2D4.points[1].y, crosshair_spacing + crosshair_length, crosshair_lerp_speed * delta)
	
	#Rotation
	crosshair.rotation = lerp_angle(deg_to_rad(crosshair.rotation_degrees), deg_to_rad(crosshair_rotation_degrees), crosshair_lerp_speed * 2 * delta)
	


func check_clearance():
	arm_cleared = !arm_clearance.has_overlapping_bodies()
