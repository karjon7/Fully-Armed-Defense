extends Node

var is_debug_on : bool = false : set = set_is_debug_on

var commands = {}


func _ready():
	register_command("Test", "testing", self, test)
	register_command("set debug", "Sets the debug to the passed boolean.", self, set_is_debug_on)


func register_command(command_name : String, description : String, target : Node, method : Callable):
	command_name = command_name.to_snake_case()
	
	if commands.has(command_name): #command already in command list
		push_warning("Command already added to commmand list.")
		return
	
	if not get_node(get_path_to(target)): #target not found
		push_error("This target(%s) does not exist." % [target])
	
	if not target.has_method(method.get_method()):  #target dosent have the function
		push_error("This target(%s) does not have this method: %s." % [command_name, method])
		return
	
	var command = {
		"description" : description,
		"target" : target,
		"method" : method,
	}
	
	commands[command_name] = command


func execute_command(command_name : String, arguments : Array[Variant] = []):
	command_name = command_name.to_snake_case()
	
	if not is_debug_on and command_name != "set_debug": #Checks if debug is on
		push_warning("Debug is not on.")
		return
	
	if not commands.has(command_name): #Command not found in command list
		push_error("Command not found: %s." % [command_name])
		return
	
	var command_data = commands[command_name]
	var target : Node = command_data.target
	var method : Callable = command_data.method
	
	target.callv(method.get_method(), arguments)
	print("executed command %s" % command_name)


func set_is_debug_on(value):
	is_debug_on = !is_debug_on
	print("Debug is %s" % [is_debug_on])


func test(x : String = ""):
	print("testing " + str(x))
