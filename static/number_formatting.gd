extends Node

var metric = true


func temperature(value : float, decimals = false) -> String:
	
	value = (value * 9 / 5) + 32 if not metric else value
	
	value = floor(value) if not decimals else value
	
	return "%sº%s" % [value, "C" if metric else "F"]
