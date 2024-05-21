extends Node

var debug_on : bool = false : set = _set_debug

class ArgumentFormat:
		var argument_name : String
		var argument_type : int
		var default_value 
		
		
		func _init(_name : String, _type : int, _default = null):
			argument_name = _name
			argument_type = _type
			default_value = _default

class DebugCommand:
	var id : String
	var description : String
	var command : Callable
	var format : Array[ArgumentFormat]
	
	
	func _init(_id : String, _description : String, _command : Callable, _format : Array[ArgumentFormat] = []):
		id = _id
		description = _description
		command = _command
		format = _format
	
	func invoke(args = []):
		command.callv(args)

#Commands
var DEBUG_COMMAND : DebugCommand = DebugCommand.new(\
	"debug", \
	"This command enables or disables the debug commands.", \
	_set_debug, \
	[ArgumentFormat.new("enable", TYPE_BOOL, true)])

var TEST_COMMAND : DebugCommand = DebugCommand.new(\
	"_test", \
	"This command is for testing purposes.", \
	func(): send_debug_messege("Test Command fired.") ; pass)
var PING_PONG_COMMAND : DebugCommand = DebugCommand.new(\
	"_ping", \
	"This command responds back.", \
	func(): send_debug_messege("Pong!"))
var REPEAT_COMMAND : DebugCommand = DebugCommand.new(\
	"_repeat", \
	"This command repeats back what was said.", \
	func(text : String): send_debug_messege(text), \
	[ArgumentFormat.new("text", TYPE_STRING)])
var NUMBER_NOTATE_COMMAND : DebugCommand = DebugCommand.new(\
	"_notate", \
	"This command notates the number given.", \
	func(number): send_debug_messege(NumberFormatting.notate(number)), \
	[ArgumentFormat.new("number", TYPE_FLOAT)])
var NUMBER_COMPACT_NOTATE_COMMAND : DebugCommand = DebugCommand.new(\
	"_compact_notate", \
	"This command notates the number given compactly.", \
	func(number, digits : int, abbr : bool): send_debug_messege(NumberFormatting.compact_notate(number, digits, abbr)), \
	[ArgumentFormat.new("number", TYPE_FLOAT), ArgumentFormat.new("digits", TYPE_INT, 3), ArgumentFormat.new("abbreviated", TYPE_BOOL, true)])

var HELP_COMMAND : DebugCommand = DebugCommand.new(\
	"help", \
	"This command shows all usable commands.", \
	help_command)
var SYNTAX_COMMAND
var DESCRIPTION_COMMAND

#NOTE:Money Commands
var MONEY : DebugCommand = DebugCommand.new(\
	"money", \
	"This command grants the specified amount of money.", \
	func(amount : int): player.deposit_money(amount) ; send_debug_messege("Gave player %s dollars" % amount), \
	[ArgumentFormat.new("amount", TYPE_INT)])
var ROSEBUD : DebugCommand = DebugCommand.new(\
	"rosebud", \
	"This command grants $9,999,999.", \
	func(amount : int = 9999999): player.deposit_money(amount) ; send_debug_messege("Gave player %s dollars" % amount))

#NOTE:Player Commands
var FLY_MODE #: DebugCommand = DebugCommand.new("fly_mode", "Toggles flight on the player.", player._set_flying, [TYPE_BOOL])
var NO_CLIP #: DebugCommand = DebugCommand.new("no_clip", "Toggles flight and collision on the player.", player._set_no_clip, [TYPE_BOOL])
var INVINCIBLE #: DebugCommand = DebugCommand.new("invincible", "Toggles whether player recieves damage or not.", player._set_invincible, [TYPE_BOOL])
var HIDDEN #: DebugCommand = DebugCommand.new("hidden", "Toggles whether player hidden from enemies or not.", player._set_hidden, [TYPE_BOOL])

var ARM_DATA
var ARM_HEAT #: DebugCommand = DebugCommand.new("arm_heat", "Sets the heat gain every shot.", player.arm_data._set_arm_heat_per_shot, [TYPE_INT])
var ARM_FIRERATE# : DebugCommand = DebugCommand.new("arm_firerate", "Sets the arm fire rate.", player.arm_data._set_shots_per_min, [TYPE_INT])
var ARM_AUTOMATIC #: DebugCommand = DebugCommand.new("arm_auto", "Sets arm to semi/automatic.", player.arm_data._set_is_auto, [TYPE_BOOL])
var OVERHEAT #: DebugCommand = DebugCommand.new("overheat", "Toggles whether player arm overheats or not.", player._set_overheat, [TYPE_BOOL])

var PERK #: DebugCommand = DebugCommand.new("perk", "Gives the player a perk.", player_grant_perk, [TYPE_INT])

#NOTE:Map Commands
var KILL_ALL : DebugCommand = DebugCommand.new(\
	"kill_all", \
	"Kills all enemies on the map.", \
	func(): map.kill_all_enemies() ; send_debug_messege("All enemies killed"))
var SKIP_WAVE : DebugCommand = DebugCommand.new(\
	"skip_wave", \
	"Skips to the next wave.", \
	func(): map.new_wave() ; send_debug_messege("Wave %s skipped. Starting Wave %s." % [map.wave - 1, map.wave]))
var WAVE
var FORCE_INTERMISSION : DebugCommand = DebugCommand.new(\
	"force_intermission", \
	"Forces intermission, stopping the wave.", \
	func(): map.start_intermission() ; send_debug_messege("Intermission forced"))

#Allowed Commands
var command_list : Array[DebugCommand] = [
	DEBUG_COMMAND,
	
	TEST_COMMAND,
	PING_PONG_COMMAND,
	REPEAT_COMMAND,
	NUMBER_NOTATE_COMMAND,
	NUMBER_COMPACT_NOTATE_COMMAND,
	
	HELP_COMMAND,
	
	MONEY,
	ROSEBUD,
	
	#
	
	KILL_ALL,
	SKIP_WAVE,
	FORCE_INTERMISSION,
]

#Refrences
var player : Player = null
var map : Map = null


#Signals
signal debug_messege


func _ready():
	pass


func _set_debug(value):
	debug_on = value
	
	send_debug_messege("Debug commands set to %s" % debug_on)


func command_evaluation(command_id : String, arguments : Array):
	var command : DebugCommand
	
	for cmd in command_list: #Convert ID to Command
		var cmd_name = cmd.id
		
		if cmd.id.begins_with("_"): cmd_name = cmd.id.substr(1, cmd.id.length() - 1)
		
		if cmd_name == command_id.to_lower():
			command = cmd
			break
	
	if not debug_on and command != DEBUG_COMMAND:#Debug commands on check
		send_debug_messege("Debug commands are not on")
		return
	
	if not command: #Valid Command Check
		send_debug_messege("Command not found")
		return
	
	
	#Arguments Check
	var required_arguments : int = 0
	
	for arg in command.format:
		if arg.default_value == null: required_arguments += 1
	
	if arguments.size() < required_arguments: 
		send_debug_messege('Not enough arguments given for the "%s" command' % command_id.capitalize())
		return
		
	if arguments.size() > command.format.size(): #Too many args
		send_debug_messege('Too many arguments given for the "%s" command' % command_id.capitalize())
		return
	
	
	#Convert Arguments to Type
	var passing_arguments : Array = []
	
	for n in range(command.format.size()):
		var current_arg : ArgumentFormat = command.format[n]
		
		if arguments.size() < n + 1: 
			passing_arguments.append(current_arg.default_value)
			continue
		
		match current_arg.argument_type:
			TYPE_BOOL:
				if arguments[n].to_lower() == "true": passing_arguments.append(true)
				elif arguments[n].to_lower() == "false": passing_arguments.append(false)
				else:
					send_debug_messege("Incorrect argument type (argument %s)" % [n + 1])
					return
			
			TYPE_FLOAT:
				passing_arguments.append(float(arguments[n]))
			
			TYPE_INT:
				passing_arguments.append(int(arguments[n]))
			
			TYPE_STRING:
				passing_arguments.append(arguments[n])
	
	command.invoke(passing_arguments)


func help_command():
	send_debug_messege("Commands:")
	
	for command in command_list:
		var arg_text : Array[String] = []
		
		for arg in command.format:
			var single_arg_text : String = ""
			
			match arg.argument_type:
				TYPE_BOOL:
					single_arg_text = "[color=red]<bool>[/color]"
				
				TYPE_INT:
					single_arg_text = "[color=darkblue]<int>[/color]"
				
				TYPE_FLOAT:
					single_arg_text = "[color=aqua]<float>[/color]"
				
				TYPE_STRING:
					single_arg_text = "[color=lawngreen]<string>[/color]"
			
			single_arg_text = "%s = %s %s" % [arg.argument_name, arg.default_value, single_arg_text] if arg.default_value \
				else "%s%s" % [arg.argument_name, single_arg_text]
			single_arg_text = "[%s]" % single_arg_text if arg.default_value else "(%s)" % single_arg_text
			arg_text.append(single_arg_text)
		
		if not command.id.begins_with("_"): \
		send_debug_messege("[b]>%s:[/b] %s [i]Parameters:[/i] %s" % [
			command.id.to_upper(), 
			command.description, 
			", ".join(arg_text) if not arg_text.is_empty() else "None"])


func send_debug_messege(text : String):
	debug_messege.emit(text)


func player_grant_perk(perk_id : int):
	pass



