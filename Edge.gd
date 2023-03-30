class_name Edge extends Node2D

@export var left_handle: DragDropHandle
@export var right_handle: DragDropHandle

@export var camera: Camera2D

signal captured_input_event(Edge, InputEvent)

var baseline: Vector2 = Vector2(0, 0)
var must_update_position: bool = true
var points: PackedVector2Array
var original_points: PackedVector2Array

var color: Color = Color.WHITE
var color_default: Color = Color.WHITE
var color_collision: Color = Color.RED

var bounding_box: Rect2 = Rect2()


func set_points_before_init(new_points: PackedVector2Array):
	self.points = new_points


func _draw():
	# A width of -1 always creates a visually thin line
	draw_polyline(self.points, self.color, -1, true)


# TODO: This should be combined with some general shape management code.
func make_straight():
	var left = Vector2.ZERO
	var right = Vector2.RIGHT
	var edge_shape = PackedVector2Array()
	edge_shape.append(left)
	edge_shape.append(right)
	self.points = edge_shape

	update_position()
	update_carea(true)
	queue_redraw()


# Called when the node enters the scene tree for the first time.
# At this point, all other nodes already exist, even though they may not be
# members of the scene tree yet.
func _ready():
	self.original_points = self.points.duplicate()
	left_handle.position_changed.connect(query_update_position)
	right_handle.position_changed.connect(query_update_position)
	smooth_and_update()


func smooth_and_update():
	$CatmulRomSpline.refresh_samples(self.points)
	if $CatmulRomSpline.is_relevant:
		self.points = $CatmulRomSpline.points.duplicate()

	# Initial alignment
	update_position()
	update_carea(true)
	queue_redraw()


# Ask the node to update its transformation in the next _process step
func query_update_position():
	self.must_update_position = true


# Called to set up the edge in the correct position and then again whenever one
# of the handles moves.
func update_position():
	var transformation = build_transformation_matrix()
	set_transform(transformation)


# Update the collision area of the edge
func update_carea(force = false):
	var target_baseline = right_handle.position - left_handle.position
	if force or target_baseline.distance_to(self.baseline) > 0.1:
		self.baseline = target_baseline
		$EdgeCollisionArea.recalculate(self.points, 9 / self.scale.x)
		# Get the bounding box of the collision area. We do this by taking
		# the max and min of the x and y coordinates of all points in the
		# collision polygon.
		var polygon = $EdgeCollisionArea/Polygon.polygon
		var rect = Rect2()
		for point in polygon:
			rect = rect.expand(point)
		self.bounding_box = rect


# Construct the transformation matrix that maps the node polyline to its handles
func build_transformation_matrix() -> Transform2D:
	var left: Vector2 = self.points[0]
	var right: Vector2 = self.points[-1]

	return FixedPointTransform2D.build_transformation_matrix(
		left, right, left_handle.position, right_handle.position
	)


# Return absolute point coordinates of the edge
func get_shape_points() -> PackedVector2Array:
	return self.transform * self.points


func set_color(col: Color):
	if self.color != col:
		self.color = col
		queue_redraw()


## Check for overlap with another edge.
func _process(_delta):
	if must_update_position:
		must_update_position = false
		update_position()
		update_carea(false)
		queue_redraw()

	# if $EdgeCollisionArea.monitoring:
	# 	var collisions = $EdgeCollisionArea.get_overlapping_areas()
	# 	if collisions.size() > 0:
	# 		set_color(self.color_collision)
	# 	else:
	# 		set_color(self.color_default)


func check_collision_against(other: Edge) -> bool:
	return (
		Geometry2D.intersect_polygons(self.collision_polygon(), other.collision_polygon()).size()
		> 0
	)


func collision_polygon() -> PackedVector2Array:
	print(transform * bounding_box)
	return transform * $EdgeCollisionArea/Polygon.polygon
