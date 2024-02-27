extends Resource
class_name SaveLoad

@export var save_resources : Array[Resource]

const SAVE_FILE_PATH = "user://saved_data/"


func verify_save_directory(path : String):
	DirAccess.make_dir_absolute(path)


func save_data():
	verify_save_directory(SAVE_FILE_PATH)
	
	for save in save_resources:
		ResourceSaver.save(save, SAVE_FILE_PATH + save.resource_name)


func load_data():
	verify_save_directory(SAVE_FILE_PATH)
	
	for save in save_resources:
		save = ResourceLoader.load(SAVE_FILE_PATH + save.resource_name)
