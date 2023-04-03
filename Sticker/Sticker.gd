class_name Sticker extends Area2D

## A sticker is a collection of polylines. Each of these polylines can be marked
## as "sticky" or "non sticky". Both types get exported into the svg and are
## shown in the editor. But Vertices only stick to sticky polylines.
##
## This means the sticky polylines are the "walls" of the sticker. The non
## sticky polylines are the "holes" in the sticker to make it read better.
##
## Stickers are loaded from a json file. The json file is a list of polylines.

signal captured_input_event(Sticker, InputEvent)
signal captured_hover_event(Sticker, bool)


func add_polyline(points: PackedVector2Array, is_sticky: bool):
	var line = Line2D.new()
	line.points = points
	# TODO: This should really render the same as the Edge, possibly with a
	# similar outline for sticky parts as the boundary box currently has.
	line.width = 2
	add_child(line)
	if is_sticky:
		line.modulate = Color(1.0, 1.0, 1.0)
		add_collider(line)
	else:
		line.modulate = Color(0.5, 0.5, 0.5)


## The collsision polygon is just a polygon based on the sticky polylines.
func add_collider(line: Line2D):
	var points = line.points
	var area = CollisionPolygon2D.new()
	area.polygon = points
	add_child(area)


func _input_event(_viewport, event, _shape_index):
	captured_input_event.emit(self, event)


func _mouse_enter():
	captured_hover_event.emit(self, true)


func _mouse_exit():
	captured_hover_event.emit(self, false)
