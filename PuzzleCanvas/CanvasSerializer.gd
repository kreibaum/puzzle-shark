class_name CanvasSerializer extends Object

## We use the CanvasSerializer to store and load the state of the puzzle.
## This can also be (ab-)used to implement undo/redo functionality.
## This means we also store some ephemeral state like the current selection.


static func serialize_vector2array(array: PackedVector2Array) -> Array:
	var points = []
	for point in array:
		points.append({"x": point.x, "y": point.y})
	return points


static func deserialize_vector2array(points: Array) -> PackedVector2Array:
	var array = PackedVector2Array()
	for point in points:
		array.append(Vector2(point["x"], point["y"]))
	return array


## Serialize the canvas to a json object.
## { vertices : [ { x: 23.4, y: 77.3 } ] }
static func serialize(canvas: PuzzleCanvas) -> Dictionary:
	var indices = {}
	var json = {}

	json["vertices"] = []
	json["edges"] = []

	var index = 0
	for vertex in canvas.vertices:
		# TODO: stickerId must be serialized, after we got stickers
		var x = vertex.position.x
		var y = vertex.position.y
		var anchor = vertex.anchor

		json["vertices"].append({"x": x, "y": y, "anchor": vertex.anchor})
		indices[vertex] = index
		index += 1

	for edge in canvas.edges:
		var left = indices[edge.left_vertex]
		var right = indices[edge.right_vertex]
		var skeleton = serialize_vector2array(edge.skeleton)
		json["edges"].append({"left": left, "right": right, "skeleton": skeleton})
	
	return json


## Mutate the canvas and apply all data from the json.
static func deserialize(canvas: PuzzleCanvas, json: Dictionary):
	canvas.clear()

	for vertex in json["vertices"]:
		var canvas_vertex = canvas.create_vertex(Vector2(vertex["x"], vertex["y"]))
		canvas_vertex.set_anchor_mode(vertex["anchor"])
		

	for edge in json["edges"]:
		var left = canvas.vertices[edge["left"]]
		var right = canvas.vertices[edge["right"]]
		var skeleton = deserialize_vector2array(edge["skeleton"])
		canvas.create_edge(left, right, skeleton)
