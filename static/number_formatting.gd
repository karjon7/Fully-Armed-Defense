extends Node

var metric = true


func temperature(value : int) -> String:
	
	value = (value * 9 / 5) + 32 if not metric else value
	
	return "%sº%s" % [value, "C" if metric else "F"]
