class_name CanvasSerializer extends Node

## We use the CanvasSerializer to store and load the state of the puzzle.
## This can also be (ab-)used to implement undo/redo functionality.
## This means we also store some ephemeral state like the current selection.


## Serialize the canvas to a json object.
## { vertices : [ { x: 23.4, y: 77.3 } ] }
static func serialize(canvas: PuzzleCanvas) -> Dictionary:
	var json = {}
	json["vertices"] = []

	for vertex in canvas.vertices:
		# TODO: Missing id (iterated and put in map for vertex -> id lookup)
		# This lookup map is needed for the edges.
		# TODO: anchor type must be serialized
		# TODO: stickerId must be serialized, after we got stickers
		json["vertices"].append({"x": vertex.position.x, "y": vertex.position.y})

	return json


## Mutate the canvas and apply all data from the json.
static func deserialize(canvas: PuzzleCanvas, json: Dictionary):
	canvas.clear()

	for vertex in json["vertices"]:
		canvas.create_vertex(Vector2(vertex["x"], vertex["y"]))
