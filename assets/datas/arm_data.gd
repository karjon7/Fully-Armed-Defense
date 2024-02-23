extends Resource
class_name ArmData

@export var build_name : String = ""
@export_multiline var description = ""
@export var is_semi : bool = false
@export var light_color : Color = Color.GOLD
@export_range(0, 1, 0.01) var light_energy : float = 0.25
@export_range(0, 1000, 1, "or_greater") var heat_per_shot : int = 50
@export_range(1, 1000, 1, "suffix:per min", "or_greater") var shots_per_min : int = 500
@export_enum("Light Recoil", "Medium Recoil", "Heavy Recoil", "Laser Recoil") var recoil_type : String = "Light Recoil"
@export_enum("Bullets", "Shells", "Grenades", "Laser") var shooting_type = "Bullets"

@export var shoot_scene : PackedScene
@export var shoot_particles_scene : PackedScene
@export var shoot_sound : AudioStream

var times_upgraded : int = 0

@export_group("Bullets Settings")
@export_range(0, 100, 0.1, "or_greater") var bullet_damage : float = 0
@export_range(0, 100, 0.5, "or_greater", "suffix:m") var bullet_range : float = 100
@export_range(0, 10, 1, "or_greater") var bullet_pierce : int = 0
@export_range(0, 10, 1, "or_greater") var bullet_bounces : int = 0
@export_range(0, 45, 0.5) var min_bounce_angle : float = 45
@export_range(0, 1000, 1) var bullet_speed : float = 50

@export_group("Shells Settings")

@export_group("Grenades Settings")

@export_group("Laser Settings")
