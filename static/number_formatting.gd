extends Node

var metric = true


func temperature(value : float, decimals = false) -> String:
	
	value = (value * 9 / 5) + 32 if not metric else value
	
	value = floor(value) if not decimals else value
	
	return "%sº%s" % [value, "C" if metric else "F"]


func notate(number: float) -> String:
	var str_number = str(number)
	var parts = str_number.split(".")
	var integer_part = parts[0]
	var decimal_part = ""
	
	if parts.size() > 1:
		decimal_part = "." + parts[1]
	
	var separated_number = ""
	var count = 0
	
	for i in integer_part.reverse():
		count += 1
		separated_number = i + separated_number
		if count % 3 == 0 and count != integer_part.length():
			separated_number = "," + separated_number
	
	return separated_number + decimal_part



func compact_notate(value : float, digits := 3, abbriviate := true) -> String:
	var lookup = [
		{"value" : 1, "suffix" : "", "symbol" :  ""},
		{"value" : 1e3, "suffix" : "Thousand", "symbol" :  "K"},
		{"value" : 1e6, "suffix" : "Million", "symbol" :  "M"},
		{"value" : 1e9, "suffix" : "Billion", "symbol" :  "B"},
		{"value" : 1e12, "suffix" : "Trillion", "symbol" :  "T"},
		{"value" : 1e15, "suffix" : "Quadrillion", "symbol" :  "Qa"},
		{"value" : 1e18, "suffix" : "Quintillion", "symbol" :  "Qi"},
	]
	lookup.reverse()
	
	var abs_value = abs(value)
	var notation = lookup.slice(0).filter(func(notation): return abs_value >= notation.value)[0] if value != 0 else 0
	
	var string_spaces = 8 if abs_value >= 1e3 else 4
	digits = digits if abs_value >= 1e3 else 0
	
	var format_string = "%.*f%s" if abbriviate else "%.*f %s"
	return format_string % [digits, sign(value) * (abs_value / notation.value), notation.symbol if abbriviate else notation.suffix] if value != 0 else "0"
