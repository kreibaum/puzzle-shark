class_name StickerParser extends Node

## Parser for Sticker Json files.
## This reads a json file which looks like this:
##
## {
##     "name": "Ellipse Example",
##     "lines": [
##         {
##             "d": "m 87.239429,100.4722 -0.08605,3.0041 -0.25256,2.91733 -0.410694,2.81577 -0.56045,2.69946 -0.701829,2.56837 -0.834831,2.42252 -0.959453,2.2619 -1.0757,2.08651 -1.183568,1.89634 -1.283059,1.69142 -1.374172,1.47171 -1.456908,1.23726 -1.531265,0.98801 -1.597246,0.72401 -1.654848,0.44524 -1.704074,0.15169 -1.704074,-0.15169 -1.654848,-0.44524 -1.597246,-0.72401 -1.531265,-0.98801 -1.456908,-1.23726 -1.374172,-1.47171 -1.283059,-1.69142 -1.183568,-1.89634 -1.0757,-2.08651 -0.959453,-2.2619 -0.834831,-2.42252 -0.701829,-2.56837 -0.56045,-2.69946 -0.410694,-2.81577 -0.25256,-2.91733 -0.08605,-3.0041 0.08605,-3.004103 0.25256,-2.917324 0.410693,-2.815776 0.560451,-2.69946 0.701829,-2.568374 0.83483,-2.422521 0.959454,-2.261898 1.075699,-2.086506 1.183569,-1.896345 1.283059,-1.691416 1.374172,-1.471718 1.456907,-1.23725 1.531266,-0.988015 1.597246,-0.72401 1.654849,-0.445237 1.704074,-0.151694 1.704074,0.151694 1.654849,0.445237 1.597246,0.72401 1.531266,0.988015 1.456907,1.23725 1.374172,1.471718 1.283059,1.691416 1.183569,1.896345 1.075699,2.086506 0.959454,2.261898 0.83483,2.422521 0.701829,2.568374 0.560451,2.69946 0.410693,2.815776 0.25256,2.917324 0.08605,3.004103 z",
##             "sticky": true
##         }
##     ]
## }
##
## I will then produce a Sticker which can be incorporated into the jigsaw.
##
## This also listens for files getting dropped into the program to open them.

@export var canvas: PuzzleCanvas


func _ready():
	get_window().files_dropped.connect(_on_files_dropped)


func _on_files_dropped(files):
	var drop_origin = canvas.get_global_mouse_position()

	for filename in files:
		if filename.ends_with(".json"):
			var sticker = load_sticker(filename)
			if sticker != null:
				canvas.add_sticker(sticker)
				canvas.move_sticker_to(sticker, drop_origin)


## Open the file and parse it as a json file.
func load_sticker(filename: String) -> Sticker:
	var file = FileAccess.open(filename, FileAccess.READ)
	var json = file.get_as_text()
	file.close()

	var data = JSON.parse_string(json)
	if data == null:
		print("Error parsing json file")
		return

	print("Loaded sticker: ", data["name"])

	return build_sticker(data)


## Parses the sticker json and svg content into a Sticker.
## This part is also reused when loading and saving files.
## Stickers are always "embedded" into the .shark file and not referenced.
static func build_sticker(data: Dictionary) -> Sticker:
	var sticker = Sticker.new()
	for line in data["lines"]:
		for parsed_line in parse_line(line):
			print(parsed_line[0], parsed_line[-1])
			sticker.add_polyline(parsed_line, line["sticky"])
	sticker.set_source_data(data)
	return sticker


## Parses a line with a "d" attribute.
## Right now we only support a reduced set of svg path commands wih produce
## straight lines. Those are "m", "M", "l", "L", "v", "V", "h", "H". We also
## support "z" which closes the path.
##
## Please refer to
## https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/d#path_commands
## for more information on the commands.
static func parse_line(line):
	var d = line["d"]

	var pen_position = Vector2.ZERO
	var mode = null

	var tokens = d.split(" ")

	var all_lines = []
	var current_line = null

	for token in tokens:
		# If the token is a mode switch token, then we switch modes and don't
		# move the pen at all. The supported tokens are:
		# - "m" for move to
		# - "M" for absolute move to
		# - "l" for line to
		# - "L" for absolute line to
		# - "v" for vertical line to
		# - "V" for absolute vertical line to
		# - "h" for horizontal line to
		# - "H" for absolute horizontal line to
		# As well as some non-consuming tokens:
		# - "z" for close path
		if "mMlLvVhH".contains(token):
			mode = token
			continue
		if "zZ".contains(token):
			mode = null
			pen_position = current_line[0]
			current_line.append(pen_position)
			# Commit current line and start a new one.
			all_lines.append(current_line)
			#current_line = [pen_position]
			current_line = null
			continue
		if mode == "m":
			# Commit current line and start a new one.
			if current_line != null:
				all_lines.append(current_line)
			pen_position += parse_vector2(token)
			current_line = [pen_position]
			mode = "l"
		elif mode == "M":
			# Commit current line and start a new one.
			if current_line != null:
				all_lines.append(current_line)
			pen_position = parse_vector2(token)
			current_line = [pen_position]
			mode = "L"
		elif mode == "l":
			pen_position += parse_vector2(token)
			current_line.append(pen_position)
		elif mode == "L":
			pen_position = parse_vector2(token)
			current_line.append(pen_position)
		elif mode == "v":
			pen_position.y += float(token)
			current_line.append(pen_position)
		elif mode == "V":
			pen_position.y = float(token)
			current_line.append(pen_position)
		elif mode == "h":
			pen_position.x += float(token)
			current_line.append(pen_position)
		elif mode == "H":
			pen_position.x = float(token)
			current_line.append(pen_position)
		else:
			print("Error: Unknown mode: ", mode)
			return

	# Commit current line and start a new one.
	if current_line != null:
		all_lines.append(current_line)

	return all_lines


static func parse_vector2(token: String):
	var parts = token.split(",")
	if parts.size() != 2:
		print("Error: Invalid vector2: ", token)
		return
	return Vector2(float(parts[0]), float(parts[1]))
