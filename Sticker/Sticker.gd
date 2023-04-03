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

var lines = []


func add_polyline(points: PackedVector2Array, is_sticky: bool):
	var line = Line2D.new()
	line.points = points
	# TODO: This should really render the same as the Edge, possibly with a
	# similar outline for sticky parts as the boundary box currently has.
	line.width = 2
	lines.append(line)
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


## Finds the nearest point on the sticker to the given point.
## This function is very unoptimized right now but this is going to be an
## exciting challenge to optimize later.
func find_nearest_sticky_point(point: Vector2) -> Vector2:
	# Inverse transform the point to be in sticker coordinates.
	var local_point = transform.affine_inverse() * point

	# First, we make the assumption that the nearest sticky point is next to the
	# nearest polygon point on a sticky line. This is not always true, but it
	# should be a good enough approximation if the polygon always uses many points.

	var best_distance = 99999.0
	var best_line = null
	var best_index = -1
	for line in lines:
		# TODO: Only check sticky lines
		var points = line.points
		for i in range(points.size()):
			var distance = local_point.distance_to(points[i])
			if distance < best_distance:
				best_distance = distance
				best_line = line
				best_index = i

	# Now we have a point to work from. We now look at the strait lines to and
	# from the point and for each line find the closest point on the line.
	# TODO: Actually do this. For now we just return the point.

	if best_line != null:
		return transform * best_line.points[best_index]
	else:
		return point


func _input_event(_viewport, event, _shape_index):
	captured_input_event.emit(self, event)


func _mouse_enter():
	captured_hover_event.emit(self, true)


func _mouse_exit():
	captured_hover_event.emit(self, false)
