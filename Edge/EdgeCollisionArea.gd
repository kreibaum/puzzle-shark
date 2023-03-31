class_name EdgeCollisionArea extends Area2D

var disabled = false

func is_disabled():
	return self.disabled

func disable():
	$Polygon.set_polygon(PackedVector2Array())
	self.disabled = true

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
	var baseline = edge_shape[0] - edge_shape[-1]
	var hull = PackedVector2Array()

	if baseline.length() > 0:
		var polys = Geometry2D.offset_polyline(edge_shape, thickness)
		if len(polys) == 0: return
		hull = polys[0]

		var cutfraction = baseline.length() / (2 * thickness)
		var cutradius = min(cutfraction, 3) * thickness

		var left_clip = box(edge_shape[0], cutradius)
		polys = Geometry2D.clip_polygons(hull, left_clip)
		if len(polys) > 0:
			hull = polys[0]

		var right_clip = box(edge_shape[-1], cutradius)
		polys = Geometry2D.clip_polygons(hull, right_clip)
		if len(polys) > 0:
			hull = polys[0]

	self.disabled = false
	$Polygon.set_polygon(hull)


# Called when the mouse is pressed
func _input_event(_viewport, event, _shape_index):
	var edge: Edge = get_parent()
	edge.captured_input_event.emit(edge, event)
