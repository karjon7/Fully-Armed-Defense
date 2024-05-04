extends StaticBody3D
class_name Interactable


@export var can_interact : bool = true
@export var interact_message : String = "Press E to interact"
@export var cant_interact_message : String = "You can't interact with this"


func interact():
	print("interacted with " + self.name)
