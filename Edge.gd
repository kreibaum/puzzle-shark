class_name Edge extends Node2D

@export var left_handle: DragDropHandle
@export var right_handle: DragDropHandle

@export var camera: Camera2D

signal captured_input_event(Edge, InputEvent)

var baseline: Vector2 = Vector2(0, 0)
var must_update_position: bool = true


func set_points_before_init(new_points: PackedVector2Array):
	$EdgeShape.points = new_points


# TODO: This should be combined with some general shape management code.
func make_straight():
	var left = Vector2.ZERO
	var right = Vector2.RIGHT
	var points = PackedVector2Array()
	points.append(left)
	points.append(right)
	$EdgeShape.points = points

	update_position()
	update_width()
	update_carea(true)


# Called when the node enters the scene tree for the first time.
# At this point, all other nodes already exist, even though they may not be
# members of the scene tree yet.
func _ready():
	camera.zoom_changed.connect(update_width)

	left_handle.position_changed.connect(query_update_position)
	right_handle.position_changed.connect(query_update_position)

	$CatmulRomSpline.refresh_samples()
	if $CatmulRomSpline.is_relevant:
		$EdgeShape.points = $CatmulRomSpline.points.duplicate()

	# Initial alignment
	update_position()
	update_width()
	update_carea(true)


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
		$EdgeCollisionArea.recalculate($EdgeShape.points, 9 / self.scale.x)


# Update the width of the edge
func update_width(zoom = camera.zoom):
	$EdgeShape.width = 3 / (zoom.x * self.scale.x)


func build_transformation_matrix() -> Transform2D:
	var left: Vector2 = $EdgeShape.points[0]
	var right: Vector2 = $EdgeShape.points[-1]

	var baseline = right - left
	var shape_length = baseline.length()
	var shape_angle = baseline.angle()

	var target_baseline = right_handle.position - left_handle.position
	var target_length = target_baseline.length()
	var target_angle = target_baseline.angle()

	var scale_vector = Vector2(target_length / shape_length, target_length / shape_length)

	# It is important that we first move
	var zero_out = Transform2D(0, Vector2.ONE, 0, -left)
	return Transform2D(target_angle - shape_angle, scale_vector, 0, left_handle.position) * zero_out


# Return absolute point coordinates of the edge
func get_shape_points() -> PackedVector2Array:
	return self.transform * $EdgeShape.points


## Check for overlap with another edge.
func _process(_delta):
	if must_update_position:
		update_position()
		update_width()
		update_carea(false)
		must_update_position = false

	if $EdgeCollisionArea.monitoring:
		var collisions = $EdgeCollisionArea.get_overlapping_areas()
		if collisions.size() > 0:
			$EdgeShape.modulate = Color(1, 0, 0)
		else:
			$EdgeShape.modulate = Color(1, 1, 1)
