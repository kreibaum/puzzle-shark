class_name Edge extends Node2D

@export var left_handle: DragDropHandle
@export var right_handle: DragDropHandle

@export var camera: Camera2D

var template_points


# Called when the node enters the scene tree for the first time.
# At this point, all other nodes already exist, even though they may not be
# members of the scene tree yet.
func _ready():
	camera.zoom_changed.connect(update_zoom)

	left_handle.position_changed.connect(update_position)
	right_handle.position_changed.connect(update_position)

	# Store the template points so we can always use them to generate the actual points.
	self.template_points = $EdgeShape.points.duplicate()

	# Initial alignment
	update_position()


# Called to set up the edge in the correct position and then again whenever one
# of the handles moves.
func update_position():
	$EdgeShape.points = build_transformation_matrix() * self.template_points


func build_transformation_matrix() -> Transform2D:
	var left: Vector2 = template_points[0]
	var right: Vector2 = template_points[$EdgeShape.get_point_count() - 1]

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


func update_zoom(zoom):
	$EdgeShape.width = 3 / zoom.x
