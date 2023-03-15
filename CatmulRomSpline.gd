class_name CatmulRomSpline extends Line2D

@export var guide: Line2D
@export var samples: int = 25

# A spline follows several points. These points are called "control points".
var control_points: PackedVector2Array

# Each control point is associated with a time value.
var control_times: PackedFloat32Array

var is_relevant: bool = false


# Called when the node enters the scene tree for the first time.
func refresh_samples():
	# We do a Catmul-Rom spline interpolation between the points of the Line2D
	# node that guides the spline.

	control_points = guide.points
	if control_points.size() < 4:
		return

	control_times = PackedFloat32Array()
	control_times.append(0.0)
	for i in range(1, control_points.size()):
		var alpha = 0.5  # Regular Catmul-Rom spline.
		var distance = control_points[i - 1].distance_to(control_points[i])
		control_times.append(control_times[i - 1] + pow(distance, alpha))

	var sample_points = PackedVector2Array()
	sample_points.append(control_points[0])

	var max_control_time = control_times[control_times.size() - 1]

	for i in range(1, samples):
		var t = max_control_time * i / samples

		# Find the index of the control time that is just before t.
		# This means that t0 <= t1 <= t <= t2 <= t3.
		var index = 0
		while index < control_times.size() - 1 and control_times[index + 1] < t:
			index += 1

		var t0 = control_times[clp(index - 1)]
		var t1 = control_times[clp(index)]
		var t2 = control_times[clp(index + 1)]
		var t3 = control_times[clp(index + 2)]

		var p0 = control_points[clp(index - 1)]
		var p1 = control_points[clp(index)]
		var p2 = control_points[clp(index + 1)]
		var p3 = control_points[clp(index + 2)]

		var point = interpolate_one_point(p0, p1, p2, p3, t0, t1, t2, t3, t)
		sample_points.append(point)

	sample_points.append(control_points[control_points.size() - 1])

	points = sample_points
	is_relevant = true


# Clamp function, that is context aware.
func clp(index: int) -> int:
	return clamp(index, 0, control_points.size() - 1)
	# if index < 0:
	# 	return 0
	# elif index >= control_points.size():
	# 	return control_points.size() - 1
	# else:
	# 	return index


func interpolate_one_point(
	p0: Vector2,
	p1: Vector2,
	p2: Vector2,
	p3: Vector2,
	t0: float,
	t1: float,
	t2: float,
	t3: float,
	t: float
) -> Vector2:
	var a1 = interpolate_one_layer(p0, p1, t0, t1, t)
	var a2 = interpolate_one_layer(p1, p2, t1, t2, t)
	var a3 = interpolate_one_layer(p2, p3, t2, t3, t)

	var b1 = interpolate_one_layer(a1, a2, t0, t2, t)
	var b2 = interpolate_one_layer(a2, a3, t1, t3, t)

	return interpolate_one_layer(b1, b2, t1, t2, t)


func interpolate_one_layer(p0: Vector2, p1: Vector2, t0: float, t1: float, t: float) -> Vector2:
	if basically_equal(p0, p1):
		return p0
	return p0 * ((t1 - t) / (t1 - t0)) + p1 * ((t - t0) / (t1 - t0))


func basically_equal(a: Vector2, b: Vector2) -> bool:
	return a.distance_to(b) < 0.1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
