@tool
extends Interactable

@onready var mesh = $CSGCombiner3D
@onready var workshop_hud = %WorkshopHUD

@export var player : Player
@export var global_upgrades : Array[GLOBAL_UPGRADES]
@export var type_upgrades : Array[GLOBAL_UPGRADES]
var menu_opened : bool = false

enum GLOBAL_UPGRADES {
	AUTOMATIC_UPGRADE,
	HEAT_UPGRADE,
	FIRE_RATE_UPGRADE,
}

enum BULLET_UPGRADES {
	SPEED_UPGRADE,
	DAMAGE_UPGRADE,
	KNOCKBACK_UPGRADE,
	RANGE_UPGRADE,
	PIERCE_UPGRADE,
	BOUNCE_UPGRADE,
	BOUNCE_ANGLE_UPGRADE,
}


func _ready():
	if not Engine.is_editor_hint(): assert(player)
	
	menu_opened = false
	workshop_hud.visible = menu_opened
	
	mesh.material_override = StandardMaterial3D.new()


func _input(event):
	if not menu_opened: return
	
	if Input.is_action_just_pressed("interact"):
		interact()
		


func _process(delta):
	mesh.transparency = 0.0 if can_interact else 0.5
	mesh.material_override.albedo_color = Color.GREEN if can_interact else Color.RED
	


func _physics_process(delta):
	mesh.use_collision = can_interact


func interact():
	menu_opened = !menu_opened
	
	workshop_hud.visible = menu_opened
	
	#Player stuff
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if menu_opened else Input.MOUSE_MODE_CAPTURED
	player.can_shoot = !menu_opened
	player.can_look = !menu_opened
	player.can_move = !menu_opened
	player.hud.visible = !menu_opened


