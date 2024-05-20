extends Node

var debug_on : bool = false

class DebugCommand:
	var id : String
	var description : String
	var command : Callable
	var format : Array[int]
	
	func _init(_id : String, _description : String, _command : Callable, _format : Array[int] = []):
		id = _id
		description = _description
		command = _command
		format = _format
	
	func invoke(args = []):
		command.callv(args)

#Commands
var TEST_COMMAND : DebugCommand = DebugCommand.new("_test", "This command is for testing purposes.", func(): send_debug_messege("Tested Test Command"))
var HELP_COMMAND : DebugCommand = DebugCommand.new("help", "This command shows all usable commands.", help_command)
var PING_PONG_COMMAND : DebugCommand = DebugCommand.new("_ping", "This command relays back.", func(): send_debug_messege("Pong!"))

#NOTE:Money Commands
var ROSEBUD : DebugCommand = DebugCommand.new("rosebud", "This commands grants 1,000 money.", func(): player.money += 1000)

#Allowed Commands
var command_list : Array[DebugCommand] = [
	TEST_COMMAND,
	PING_PONG_COMMAND,
	HELP_COMMAND,
	
	ROSEBUD,
]

#Refrences
var player : Player = null


#Signals
signal debug_messege


func _ready():
	pass


func command_evaluation(command_id : String, arguments : Array):
	var command : DebugCommand
	
	for cmd in command_list:
		var cmd_name = cmd.id
		
		if cmd.id.begins_with("_"): cmd_name = cmd.id.substr(1, cmd.id.length() - 1)
		
		if cmd_name == command_id.to_lower():
			command = cmd
			break
	
	if not command:
		send_debug_messege("Command not found")
		return
	
	command.invoke()


func help_command():
	send_debug_messege("Commands:")
	
	for command in command_list:
		var arg_text : Array[String] = []
		
		for arg in command.format:
			match arg:
				TYPE_BOOL:
					arg_text.append("[color=red]<bool>[/color]")
				
				TYPE_FLOAT:
					arg_text.append("[color=aqua]<float>[/color]")
				
				TYPE_INT:
					arg_text.append("[color=darkblue]<int>[/color]")
				
				TYPE_STRING:
					arg_text.append("[color=lawngreen]<str>[/color]")
		
		if not command.id.begins_with("_"): \
		send_debug_messege("[b]>%s:[/b] %s [i]Parameters:[/i] %s" % [command.id.to_upper(), command.description, " ".join(arg_text) if not arg_text.is_empty() else "None"])


func send_debug_messege(text : String):
	debug_messege.emit(text)
