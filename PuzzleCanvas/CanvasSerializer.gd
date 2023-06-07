class_name CanvasSerializer extends Node

## We use the CanvasSerializer to store and load the state of the puzzle.
## This can also be (ab-)used to implement undo/redo functionality.
## This means we also store some ephemeral state like the current selection.


static func serialize(canvas: PuzzleCanvas) -> Dictionary:
	var json = {}
	return json


## Mutate the canvas and apply all data from the json.
static func deserialize(canvas: PuzzleCanvas, json: Dictionary):
	canvas.clear()
