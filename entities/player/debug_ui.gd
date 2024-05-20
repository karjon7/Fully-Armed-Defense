extends Control

@export var player : Player 

@onready var text_label = %RichTextLabel
@onready var line_edit = %LineEdit


func _ready():
	Debug.debug_messege.connect(add_label_text)


func _unhandled_input(event):
	if Input.is_action_just_pressed("debug"):
		if player.menu_open and not visible: return
		
		visible = !visible
		player.menu_open = visible
		line_edit.grab_focus()


func add_label_text(text : String):
	text_label.append_text(text)
	text_label.newline()


func handle_input(text : String):
	var split_text = Array(text.split(" "))
	
	var command_id : String = split_text.pop_front()
	var command_args : Array = split_text
	
	Debug.command_evaluation(command_id, command_args)


func _on_line_edit_text_submitted(new_text : String):
	if new_text.is_empty(): return
	
	handle_input(new_text)
	line_edit.clear()
