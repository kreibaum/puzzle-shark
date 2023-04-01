class_name FixedPointTransform2D extends Object

## This class is a helper class to construct a Transform2D given two points
## "sourceLeft" and "sourceRight" and their corresponding points
## "targetLeft" and "targetRight" in the target coordinate system.


## Build a transformation matrix that maps the source points to the target points.
static func build_transformation_matrix(
	sLeft: Vector2, sRight: Vector2, tLeft: Vector2, tRight: Vector2
):
	var baseline = sRight - sLeft
	var shape_length = baseline.length()
	var shape_angle = baseline.angle()

	var target_baseline = tRight - tLeft
	var target_length = target_baseline.length()
	var target_angle = target_baseline.angle()

	# If the target length is too small, this code results in a c++ exception
	# further down in the code. Better avoid this
	if target_length < 1: return

	var scale_vector = Vector2(target_length / shape_length, target_length / shape_length)

	# It is important that we first move
	var zero_out = Transform2D(0, Vector2.ONE, 0, -sLeft)
	return Transform2D(target_angle - shape_angle, scale_vector, 0, tLeft) * zero_out
