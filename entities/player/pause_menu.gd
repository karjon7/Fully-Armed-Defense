extends Control

@export var player : Player


func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		if player.menu_open and not visible: return
		
		visible = !visible
		player.menu_open = visible


func _process(delta):
	%PauseGameButton.text = "Resume Game" if get_tree().paused else "Pause Game"


func return_to_game():
	visible = false
	player.menu_open = visible


func pause():
	get_tree().paused = false if get_tree().paused else true


func request_evac():
	pass


func options():
	pass


func exit():
	get_tree().quit()
