extends Control

@onready var camera = %Camera3D

@onready var view_cast = %ViewCast
@onready var fire_cast = %FireCast
@onready var fire_point = %FirePoint
@onready var interact_reach = %InteractReach
@onready var arm_clearance = %ArmClearance

@onready var crosshair = %Crosshair

@onready var money_label = %MoneyLabel

@onready var health_label = %HealthLabel
@onready var health_bar = %HealthBar
@onready var damage_bar = %DamageBar
@onready var damage_timer = %DamageTimer

@onready var temperature_label = %TemperatureLabel
@onready var temp_anim_player = %TempAnimationPlayer

@onready var interact_label = %InteractLabel

@export var player : Player

@export_group("Crosshair")
@export var crosshair_rotation_degrees : int = 0
@export var crosshair_spacing : int = 7
@export var crosshair_length : int = 7
@export var crosshair_width : int = 2
@export var crosshair_lerp_speed : float = 10
var new_crosshair_pos : Vector2
var crosshair_pos_lerp_speed : float = 5

@export_group("Health")
@export var healthy_color : Color = Color.GREEN
@export var moderate_color : Color = Color.ORANGE
@export var damaged_color : Color = Color.RED
@export var health_lerp_speed : float = 10
var old_health : float

var arm_cleared : bool = true


func _ready():
	pass # Replace with function body.


#FIXME
func _process(delta):
	#Crosshair Aiming
	check_clearance()
	crosshair_positioning(delta)
	
	#Crosshair Styling
	crosshair_style(delta)
	
	crosshair_rotation_degrees = 45 if not arm_cleared \
	or (fire_cast.get_collider() and fire_cast.get_collider().is_in_group("Enemy")) \
	or (view_cast.get_collider() and view_cast.get_collider().is_in_group("Enemy")) else 0
	
	crosshair_spacing = 0 if not arm_cleared else 7
	crosshair_length = 10 if not arm_cleared else 7
	
	#Temperature
	temperature()
	
	#Money
	money()
	
	#Health
	health(delta)
	
	#Interacting
	interacting()


func interacting():
	interact_label.visible = interact_reach.is_colliding()
	if not interact_reach.is_colliding(): return
	
	var interactable : Interactable = interact_reach.get_collider()
	
	interact_label.text = interactable.interact_message if interactable.can_interact \
	else interactable.cant_interact_message
	


func money():
	money_label.text = "Money: %s" % [player.money]


func health(delta):
	var health_normalized = player.health / player.max_health
	
	health_label.text = "Health: %s" % [player.health]
	health_bar.value = lerp(health_bar.value, health_normalized * 100, health_lerp_speed * delta)
	health_bar.self_modulate = moderate_color.lerp(healthy_color, \
		remap(health_normalized, 0.5, 1, 0, 1)) \
	if health_normalized >= 0.5 else damaged_color.lerp(moderate_color, \
		remap(health_normalized, 0, 0.5, 0, 1))
	
	if player.health < old_health:
		damage_timer.start()
	
	if damage_timer.get_time_left() <= 0:
			damage_bar.value = lerp(damage_bar.value, health_bar.value, health_lerp_speed * delta)
	
	old_health = player.health


func temperature():
	temperature_label.text = NumberFormatting.temperature(floor(player.arm_temp))
	
	temperature_label.self_modulate = Color.WHITE.lerp(Color.RED, player.arm_temp / player.max_arm_temp) \
	if not player.is_overheated else Color.WHITE
	
	if player.is_overheated:
		temp_anim_player.play("overheated")
	else:
		temp_anim_player.play("RESET")
	


func crosshair_positioning(delta):
	var target_point : Vector3 = view_cast.get_target_position()
	var point_collision : Vector3 = view_cast.get_collision_point() if view_cast.is_colliding() else view_cast.to_global(target_point)
	
	fire_cast.look_at(fire_cast.to_local(point_collision))
	fire_cast.set_target_position(fire_cast.to_local(point_collision))
	#FIXME: move to player.gd for clearity ^
	
	var unprojected_view_cast : Vector2 = camera.unproject_position(view_cast.get_collision_point() \
	if view_cast.is_colliding() else view_cast.to_global(view_cast.get_target_position()))
	var unprojected_fire_cast : Vector2 = camera.unproject_position(fire_cast.get_collision_point() \
	if fire_cast.is_colliding() else fire_cast.to_global(fire_cast.get_target_position()))
	
	new_crosshair_pos = unprojected_fire_cast if fire_cast.is_colliding() and arm_cleared \
	and unprojected_fire_cast.distance_to(unprojected_view_cast) > 10 and not player.sprinting else unprojected_view_cast
	
	crosshair.modulate = Color.WHITE if arm_cleared else Color.RED
	crosshair.position = crosshair.position.lerp(new_crosshair_pos - crosshair.size / 2, crosshair_pos_lerp_speed * delta)


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
