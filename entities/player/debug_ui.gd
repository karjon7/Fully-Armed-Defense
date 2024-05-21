extends Control

@export var player : Player 

@onready var text_label = %RichTextLabel
@onready var line_edit = %LineEdit

var text_history : Array[String] = [] : set = _set_text_history
var history_index : int = 0 : set = _set_history_index

func _ready():
	Debug.debug_messege.connect(add_label_text)
	


func _input(event):
	if Input.is_action_just_released("debug"):
		if player.menu_open and not visible: return
		
		visible = !visible
		player.menu_open = visible
		
		if visible: #Opened
			line_edit.grab_focus()
			line_edit.clear()
			
	
	if Input.is_action_just_pressed("ui_up"):
		if not line_edit.has_focus(): return
		
		history_index -= 1
	
	if Input.is_action_just_pressed("ui_down"):
		if not line_edit.has_focus(): return
		
		history_index += 1


func _set_text_history(value):
	text_history = value
	
	if text_history.size() > 10: text_history.pop_front()


func _set_history_index(value):
	history_index = value
	
	if abs(history_index) > text_history.size(): history_index = text_history.size() * -1
	
	if history_index == 0:
		line_edit.clear()
	elif history_index < 0:
		line_edit.text = text_history[history_index]
		line_edit.set_caret_column(line_edit.get_text().length())
	elif history_index > 0:
		history_index = 0
	


func add_label_text(text : String):
	text_label.append_text(text)
	text_label.newline()


func handle_input(text : String):
	text_history.append(text)
	
	var split_text = Array(text.split(" "))
	
	var command_id : String = split_text.pop_front()
	var command_args : Array = split_text
	
	Debug.command_evaluation(command_id, command_args)


func _on_line_edit_text_submitted(new_text : String):
	if new_text.is_empty(): return
	
	add_label_text("[font_size=12][color=gray]%s[/color][/font_size]" % [new_text])
	handle_input(new_text)
	text_label.newline()
	line_edit.clear()
	history_index = 0
