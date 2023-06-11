class_name CanvasSerializer extends Object

## We use the CanvasSerializer to store and load the state of the puzzle.
## This can also be (ab-)used to implement undo/redo functionality.
## This means we also store some ephemeral state like the current selection.


static func serialize_vector2(vector: Vector2) -> Dictionary:
	return {"x": vector.x, "y": vector.y}


static func serialize_vector2array(array: PackedVector2Array) -> Array:
	var points = []
	for point in array:
		points.append(serialize_vector2(point))
	return points


static func deserialize_vector2array(points: Array) -> PackedVector2Array:
	var array = PackedVector2Array()
	for point in points:
		array.append(Vector2(point["x"], point["y"]))
	return array


## Serialize the canvas to a json object.
## { vertices : [ { x: 23.4, y: 77.3 } ] }
static func serialize(canvas: PuzzleCanvas) -> Dictionary:
	# In the json, the edges must refer to the vertices by their index.
	# This is why we need to create a mapping from vertices to indices.
	# The same is true for stickers.
	var vertex_indices = {}
	var sticker_indices = {}
	var json = {}

	json["stickers"] = []
	json["vertices"] = []
	json["edges"] = []

	var sticker_index = 0
	for sticker in canvas.stickers:
		var source_data = sticker.source_data

		# The transformation matrix is made up of the origin, x and y vectors.
		var sticker_serialized = {
			"source_data": source_data,
			"origin": serialize_vector2(sticker.transform.origin),
			"x": serialize_vector2(sticker.transform.x),
			"y": serialize_vector2(sticker.transform.y),
		}
		json["stickers"].append(sticker_serialized)

		sticker_indices[sticker] = sticker_index
		sticker_index += 1

	var vertex_index = 0
	for vertex in canvas.vertices:
		var x = vertex.position.x
		var y = vertex.position.y
		var anchor = vertex.anchor

		var vertex_serialized = {"x": x, "y": y, "anchor": vertex.anchor}
		if anchor == Vertex.ANCHOR.STICKER:
			vertex_serialized["sticker_id"] = sticker_indices[vertex.anchor_sticker]

		json["vertices"].append(vertex_serialized)
		vertex_indices[vertex] = vertex_index
		vertex_index += 1

	for edge in canvas.edges:
		var left = vertex_indices[edge.left_vertex]
		var right = vertex_indices[edge.right_vertex]
		var skeleton = serialize_vector2array(edge.skeleton)
		json["edges"].append({"left": left, "right": right, "skeleton": skeleton})

	return json


## Mutate the canvas and apply all data from the json.
static func deserialize(canvas: PuzzleCanvas, json: Dictionary):
	canvas.clear()

	print("Sticker count: ", len(json["stickers"]))
	for sticker in json["stickers"]:
		var source_data = sticker["source_data"]
		var origin = Vector2(sticker["origin"]["x"], sticker["origin"]["y"])
		var x = Vector2(sticker["x"]["x"], sticker["x"]["y"])
		var y = Vector2(sticker["y"]["x"], sticker["y"]["y"])
		var transform = Transform2D(x, y, origin)
		var canvas_sticker = StickerParser.build_sticker(source_data)
		print("deserialized sticker: ", canvas_sticker.name)
		canvas.add_sticker(canvas_sticker)
		canvas_sticker.set_transform_hard(transform)

	for vertex in json["vertices"]:
		var canvas_vertex = canvas.create_vertex(Vector2(vertex["x"], vertex["y"]))
		# To attack vertices to stickers they are assigned to, we need to put
		# the Sticker object into the context.
		var context = []
		if "sticker_id" in vertex:
			var sticker = canvas.stickers[vertex["sticker_id"]]
			context.append(sticker)
		canvas_vertex.set_anchor_mode(vertex["anchor"], context)

	for edge in json["edges"]:
		var left = canvas.vertices[edge["left"]]
		var right = canvas.vertices[edge["right"]]
		var skeleton = deserialize_vector2array(edge["skeleton"])
		canvas.create_edge(left, right, skeleton)


### SVG-Export


## Turns the current state of the canvas into an svg file. Returns a rope that
## needs to be stored to a file. A rope is an array of strings.
static func exportToSvg(canvas: PuzzleCanvas) -> Array:
	var rope = []
	rope.append('<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n')
	(
		rope
		. append(
			'<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">\n'
		)
	)
	rope.append('<svg xmlns="http://www.w3.org/2000/svg" version="1.1">\n')

	for edge in canvas.edges:
		# Svg path format: M x1 y1 L x2 y2 L x3 y3 ...
		rope.append(
			'<path d="' + edge_path(edge) + '" stroke="black" stroke-width="2" fill="none"/>\n'
		)

	for sticker in canvas.stickers:
		print("Sticker: " + str(sticker))
		for line in sticker.lines:
			print("Line: " + str(line))
			rope.append(
				(
					'<path d="'
					+ array2d_path(sticker.transform * line.points)
					+ '" stroke="black" stroke-width="2" fill="none"/>\n'
				)
			)

	rope.append("</svg>")

	return rope


static func edge_path(edge: Edge) -> String:
	return array2d_path(edge.get_shape_points())


static func array2d_path(array: Array) -> String:
	var svg_path = "M"
	# M is implicitly followed by L. So we don't have to include any L commands.
	for point in array:
		svg_path += " " + str(point.x) + " " + str(point.y)

	return svg_path
