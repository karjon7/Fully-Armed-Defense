extends Control

@onready var line_edit = %LineEdit
@onready var label = %Label


func _input(event):
	if Input.is_action_just_pressed("debug"):
		line_edit.show()


func _process(delta):
	label.text = "FPS: %s" % [Engine.get_frames_per_second()]


func _on_line_edit_text_submitted(new_text : String):
	line_edit.hide()
	
	var text_array : Array = Array(new_text.split(" "))
	
	var command_name = text_array.pop_at(0)
	var arguments = text_array
	
	Debug.execute_command(command_name, arguments)
	prints(command_name, arguments)
