#This whole script is yandere dev/spagetti code
@tool
extends Interactable

@onready var mesh = $CSGCombiner3D
@onready var workshop_ui = %WorkshopUI

#HUD
@onready var money_label = %MoneyLabel

@onready var global_upgrade_button_1 = %GlobalUpgradeButton1
@onready var global_upgrade_button_2 = %GlobalUpgradeButton2
@onready var global_upgrade_button_3 = %GlobalUpgradeButton3

@onready var type_upgrade_button_1 = %TypeUpgradeButton1
@onready var type_upgrade_button_2 = %TypeUpgradeButton2
@onready var type_upgrade_button_3 = %TypeUpgradeButton3

@onready var global_input_blocker = %GlobalInputBlocker
@onready var type_input_blocker = %TypeInputBlocker

@onready var exit_button = %ExitButton
@onready var purchase_button = %PurchaseButton


var menu_opened : bool = false

@export var player : Player
@export var purchase_price : int = 950
var final_price : int

@export_group("Global Upgrades")
var global_upgrade_selected : GlobalUpgradeData = null :
	set(value):
		global_upgrade_selected = value
		calculate_final_price()
@export var global_upgrades : Array[GlobalUpgradeData]

@export var global_upgrade_1 : GlobalUpgradeData
@export var global_upgrade_2 : GlobalUpgradeData
@export var global_upgrade_3 : GlobalUpgradeData

@export_group("Type Upgrades")
@export_subgroup("Bullet Type Upgrades")
var type_upgrade_selected : UpgradeData = null :
	set(value):
		type_upgrade_selected = value
		calculate_final_price()
@export var type_upgrades : Array[UpgradeData]

@export var type_upgrade_1 : UpgradeData
@export var type_upgrade_2 : UpgradeData
@export var type_upgrade_3 : UpgradeData


func _ready():
	if not Engine.is_editor_hint(): assert(player)
	
	menu_opened = false
	workshop_ui.visible = menu_opened
	
	mesh.material_override = StandardMaterial3D.new()
	roll_upgrades()


func _process(delta):
	mesh.transparency = 0.0 if can_interact else 0.5
	mesh.material_override.albedo_color = Color.GREEN if can_interact else Color.RED
	
	if Engine.is_editor_hint(): return
	
	money_label.text = "Money: $%s" % [NumberFormatting.notate(player.money)]
	
	purchase_button.disabled = player.money < final_price or final_price == 0
	
	purchase_button.text = "Purchase Upgrades (%s)" % [final_price] \
		if final_price > 0 else "Select Upgrades"
	
	purchase_button.text = "Insufficiant Funds" if player.money < final_price else purchase_button.text


func _physics_process(delta):
	if Engine.is_editor_hint(): return
	
	mesh.use_collision = can_interact
	
	


func interact():
	player.menu_open = true
	workshop_ui.show()
	


func calculate_final_price():
	var gl_selected = true if global_upgrade_selected else false
	var ty_selected = true if type_upgrade_selected else false
	
	var multiplier : float = remap(float(gl_selected) + float(ty_selected), 0.0, 2.0, 0.0, 1.0)
	final_price = int(purchase_price * multiplier)


#FIXME:Lowkey yandere dev typa code, def could of done this better but i wanna get this done, i can fix it later
func roll_upgrades():
	if Engine.is_editor_hint(): return
	
	global_upgrade_selected = null
	type_upgrade_selected = null
	
	global_input_blocker.hide()
	type_input_blocker.hide()
	
	#Global Upgrades
	while true:
		global_upgrade_1 = global_upgrades[randi() % global_upgrades.size()]
		global_upgrade_2 = global_upgrades[randi() % global_upgrades.size()]
		global_upgrade_3 = global_upgrades[randi() % global_upgrades.size()]
		
		if not (global_upgrade_1 == global_upgrade_2 or \
			global_upgrade_2 == global_upgrade_3 or \
			global_upgrade_3 == global_upgrade_1): break
	
	#Type Upgrades
	while true:
		type_upgrade_1 = type_upgrades[randi() % type_upgrades.size()]
		type_upgrade_2 = type_upgrades[randi() % type_upgrades.size()]
		type_upgrade_3 = type_upgrades[randi() % type_upgrades.size()]
		
		if not (type_upgrade_1 == type_upgrade_2 or \
			type_upgrade_2 == type_upgrade_3 or \
			type_upgrade_3 == type_upgrade_1): break
	
	
	global_upgrade_check()
	
	match player.arm_data.shooting_type:
		ArmData.SHOOTING_TYPES.BULLETS:
			bullet_upgrade_check()
		
		ArmData.SHOOTING_TYPES.SHELLS:
			pass
		
		ArmData.SHOOTING_TYPES.GRENADES:
			pass
		
		ArmData.SHOOTING_TYPES.LASER:
			pass
	
	global_upgrade_button_1.text = global_upgrade_1.upgrade_name
	global_upgrade_button_2.text = global_upgrade_2.upgrade_name
	global_upgrade_button_3.text = global_upgrade_3.upgrade_name
	
	type_upgrade_button_1.text = type_upgrade_1.upgrade_name
	type_upgrade_button_2.text = type_upgrade_2.upgrade_name
	type_upgrade_button_3.text = type_upgrade_3.upgrade_name
	
	
	global_upgrade_button_1.disabled = global_upgrade_1.max_reached
	global_upgrade_button_2.disabled = global_upgrade_2.max_reached
	global_upgrade_button_3.disabled = global_upgrade_3.max_reached
	
	type_upgrade_button_1.disabled = type_upgrade_1.max_reached
	type_upgrade_button_2.disabled = type_upgrade_2.max_reached
	type_upgrade_button_3.disabled = type_upgrade_3.max_reached


func purchase_upgrades():
	if player.money < final_price: return
	
	player.money -= final_price
	if global_upgrade_selected: apply_global_upgrade()
	
	if type_upgrade_selected:
		match player.arm_data.shooting_type:
			ArmData.SHOOTING_TYPES.BULLETS:
				apply_bullet_upgrade()
			
			ArmData.SHOOTING_TYPES.SHELLS:
				pass
			
			ArmData.SHOOTING_TYPES.GRENADES:
				pass
			
			ArmData.SHOOTING_TYPES.LASER:
				pass
	
	roll_upgrades()
	
	#Reset Buttons
	global_upgrade_button_1.button_pressed = false
	global_upgrade_button_2.button_pressed = false
	global_upgrade_button_3.button_pressed = false
	
	type_upgrade_button_1.button_pressed = false
	type_upgrade_button_2.button_pressed = false
	type_upgrade_button_3.button_pressed = false
	


func global_upgrade_check():
	var n = [global_upgrade_1, global_upgrade_2, global_upgrade_3]
	
	for i in n:
		var upgrade : GlobalUpgradeData = i
		
		match upgrade.stat_upgrading:
			GlobalUpgradeData.STATS.HEAT:
				upgrade.max_reached = player.arm_data.heat_per_shot <= upgrade.upgrade_max
			
			GlobalUpgradeData.STATS.FIRERATE:
				upgrade.max_reached = player.arm_data.shots_per_min >= upgrade.upgrade_max
			
			GlobalUpgradeData.STATS.AUTO:
				upgrade.max_reached = int(player.arm_data.is_auto) >= upgrade.upgrade_max


func bullet_upgrade_check():
	var n = [type_upgrade_1, type_upgrade_2, type_upgrade_3]
	
	for i in n:
		var upgrade : BulletUpgradeData = i
		
		match upgrade.stat_upgrading:
			BulletUpgradeData.STATS.BOUNCES:
				upgrade.max_reached = player.arm_data.bullet_bounces >= upgrade.upgrade_max
			
			BulletUpgradeData.STATS.BOUNCE_ANGLE:
				upgrade.max_reached = player.arm_data.min_bounce_angle <= upgrade.upgrade_max
			
			BulletUpgradeData.STATS.DAMAGE:
				upgrade.max_reached = player.arm_data.bullet_damage >= upgrade.upgrade_max
			
			BulletUpgradeData.STATS.KNOCKBACK:
				upgrade.max_reached = player.arm_data.bullet_knockback >= upgrade.upgrade_max
			
			BulletUpgradeData.STATS.PIERCE:
				upgrade.max_reached = player.arm_data.bullet_pierce >= upgrade.upgrade_max
			
			BulletUpgradeData.STATS.RANGE:
				upgrade.max_reached = player.arm_data.bullet_range >= upgrade.upgrade_max
			
			BulletUpgradeData.STATS.SPEED:
				upgrade.max_reached = player.arm_data.bullet_speed >= upgrade.upgrade_max


func apply_global_upgrade():
	match global_upgrade_selected.stat_upgrading:
		GlobalUpgradeData.STATS.HEAT:
			player.arm_data.heat_per_shot -= int(global_upgrade_selected.upgrade_increment)
		
		GlobalUpgradeData.STATS.FIRERATE:
			player.arm_data.shots_per_min += int(global_upgrade_selected.upgrade_increment)
		
		GlobalUpgradeData.STATS.AUTO:
			player.arm_data.is_auto = bool(global_upgrade_selected.upgrade_increment)
	


func apply_bullet_upgrade():
	var selected : BulletUpgradeData = type_upgrade_selected
	
	match selected.stat_upgrading:
			BulletUpgradeData.STATS.BOUNCES:
				player.arm_data.bullet_bounces += int(selected.upgrade_increment)
			
			BulletUpgradeData.STATS.BOUNCE_ANGLE:
				player.arm_data.min_bounce_angle -= selected.upgrade_increment
			
			BulletUpgradeData.STATS.DAMAGE:
				player.arm_data.bullet_damage += selected.upgrade_increment
			
			BulletUpgradeData.STATS.KNOCKBACK:
				player.arm_data.bullet_knockback += selected.upgrade_increment
			
			BulletUpgradeData.STATS.PIERCE:
				player.arm_data.bullet_pierce += int(selected.upgrade_increment)
			
			BulletUpgradeData.STATS.RANGE:
				player.arm_data.bullet_range += selected.upgrade_increment
			
			BulletUpgradeData.STATS.SPEED:
				player.arm_data.bullet_speed += selected.upgrade_increment
	


func _on_global_upgrade_button_1_toggled(toggled_on):
	if not toggled_on: return
	
	global_input_blocker.show()
	global_upgrade_selected = global_upgrade_1
	global_upgrade_button_2.button_pressed = false
	global_upgrade_button_3.button_pressed = false


func _on_global_upgrade_button_2_toggled(toggled_on):
	if not toggled_on: return
	
	global_input_blocker.show()
	global_upgrade_selected = global_upgrade_2
	global_upgrade_button_1.button_pressed = false
	global_upgrade_button_3.button_pressed = false


func _on_global_upgrade_button_3_toggled(toggled_on):
	if not toggled_on: return
	
	global_input_blocker.show()
	global_upgrade_selected = global_upgrade_3
	global_upgrade_button_1.button_pressed = false
	global_upgrade_button_2.button_pressed = false


func _on_type_upgrade_button_1_toggled(toggled_on):
	if not toggled_on: return
	
	type_input_blocker.show()
	type_upgrade_selected = type_upgrade_1
	type_upgrade_button_2.button_pressed = false
	type_upgrade_button_3.button_pressed = false


func _on_type_upgrade_button_2_toggled(toggled_on):
	if not toggled_on: return
	
	type_input_blocker.show()
	type_upgrade_selected = type_upgrade_2
	type_upgrade_button_1.button_pressed = false
	type_upgrade_button_3.button_pressed = false


func _on_type_upgrade_button_3_toggled(toggled_on):
	if not toggled_on: return
	
	type_input_blocker.show()
	type_upgrade_selected = type_upgrade_3
	type_upgrade_button_1.button_pressed = false
	type_upgrade_button_2.button_pressed = false


func _on_exit_button_pressed():
	player.menu_open = false
	workshop_ui.hide()


func _on_purchase_button_pressed():
	purchase_upgrades()
