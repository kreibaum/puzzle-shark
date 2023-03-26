class_name EdgeCollisionArea extends Area2D


# Create a polygon box
func box(center, radius):
	var points = PackedVector2Array()
	points.append(center + radius * Vector2(1, 1))
	points.append(center + radius * Vector2(1, -1))
	points.append(center + radius * Vector2(-1, -1))
	points.append(center + radius * Vector2(-1, 1))
	return points


# Recalculate the polygon for the collision area
# TODO: What happens if the diameter of the edge shape is not much greater
# or even smaller than thickness?
func recalculate(edge_shape: PackedVector2Array, thickness: float = 5.0):
	#print("recalculating collision area")
	#var hull = hull_polygon(edge_shape, thickness)
	var polys = Geometry2D.offset_polyline(edge_shape, thickness)
	if len(polys) == 0:
		return
	var hull = polys[0]

	var left_clip = box(edge_shape[0], 3 * thickness)
	polys = Geometry2D.clip_polygons(hull, left_clip)
	if len(polys) > 0:
		hull = polys[0]

	var right_clip = box(edge_shape[-1], 3 * thickness)
	polys = Geometry2D.clip_polygons(hull, right_clip)
	if len(polys) > 0:
		hull = polys[0]

	$Polygon.set_polygon(hull)


# Called when the mouse is pressed
func _input_event(_viewport, event, _shape_index):
	var edge: Edge = get_parent()
	edge.captured_input_event.emit(edge, event)
