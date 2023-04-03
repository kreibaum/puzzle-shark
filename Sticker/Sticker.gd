class_name Sticker extends Node

## A sticker is a collection of polylines. Each of these polylines can be marked
## as "sticky" or "non sticky". Both types get exported into the svg and are
## shown in the editor. But Vertices only stick to sticky polylines.
##
## This means the sticky polylines are the "walls" of the sticker. The non
## sticky polylines are the "holes" in the sticker to make it read better.
##
## Stickers are loaded from a json file. The json file is a list of polylines.


func add_polyline(points: PackedVector2Array, is_sticky: bool):
	var line = Line2D.new()
	line.points = points
	# TODO: This should really render the same as the Edge, possibly with a
	# similar outline for sticky parts as the boundary box currently has.
	line.width = 2
	add_child(line)


# Called when the node enters the scene tree for the first time.
func _ready():
	pass  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
