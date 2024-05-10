extends Resource
class_name ArmData

enum SHOOTING_TYPES {
	BULLETS,
	SHELLS,
	GRENADES,
	LASER,
}

@export var build_name : String = ""
@export_multiline var description = ""
@export var is_auto : bool = false
@export var light_color : Color = Color.GOLD
@export_range(0, 1, 0.01) var light_energy : float = 0.25
@export_range(0, 1000, 1, "or_greater") var heat_per_shot : int = 50
@export_range(1, 1000, 1, "suffix:per min", "or_greater") var shots_per_min : int = 500
@export_enum("Light Recoil", "Medium Recoil", "Heavy Recoil", "Laser Recoil") var recoil_type : String = "Light Recoil"
@export var shooting_type : SHOOTING_TYPES = SHOOTING_TYPES.BULLETS

@export var shoot_scene : PackedScene
@export var shoot_particles_scene : PackedScene
@export var shoot_sound : AudioStream

var times_upgraded : int = 0

@export_group("Bullets Settings")
@export_range(0, 1000, 1) var bullet_speed : float = 50
@export_range(0, 100, 0.1, "or_greater") var bullet_damage : float = 0
@export_range(0, 10, 1) var bullet_knockback : float = 0
@export_range(0, 100, 0.5, "or_greater", "suffix:m") var bullet_range : float = 100
@export_range(0, 10, 1, "or_greater") var bullet_pierce : int = 0
@export_range(0, 10, 1, "or_greater") var bullet_bounces : int = 0
@export_range(0, 45, 0.5) var min_bounce_angle : float = 45

@export_group("Shells Settings")

@export_group("Grenades Settings")

@export_group("Laser Settings")


func upgrade():
	pass


func bullets_upgrade():
	pass


func shells_upgrade():
	pass


func grenades_upgrade():
	pass


func laser_upgrade():
	pass
