class_name CatmulRomSpline extends Object

# Called when the node enters the scene tree for the first time.
static func refresh_samples(control_points: PackedVector2Array, samples: int) -> PackedVector2Array:
	# We do a Catmul-Rom spline interpolation between the points of the Line2D
	# node that guides the spline.

	if control_points.size() < 4:
		return control_points.duplicate()

	var control_times = PackedFloat32Array()
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

		var size = control_points.size()
		var t0 = control_times[clp(index - 1, size)]
		var t1 = control_times[clp(index, size)]
		var t2 = control_times[clp(index + 1, size)]
		var t3 = control_times[clp(index + 2, size)]

		var p0 = control_points[clp(index - 1, size)]
		var p1 = control_points[clp(index, size)]
		var p2 = control_points[clp(index + 1, size)]
		var p3 = control_points[clp(index + 2, size)]

		var point = interpolate_one_point(p0, p1, p2, p3, t0, t1, t2, t3, t)
		sample_points.append(point)

	sample_points.append(control_points[control_points.size() - 1])
	return sample_points


# Clamp function, that is context aware.
static func clp(index: int, size: int) -> int:
	return clamp(index, 0, size - 1)
	# if index < 0:
	# 	return 0
	# elif index >= control_points.size():
	# 	return control_points.size() - 1
	# else:
	# 	return index


static func interpolate_one_point(
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


static func interpolate_one_layer(p0: Vector2, p1: Vector2, t0: float, t1: float, t: float) -> Vector2:
	if basically_equal(p0, p1):
		return p0
	return p0 * ((t1 - t) / (t1 - t0)) + p1 * ((t - t0) / (t1 - t0))


static func basically_equal(a: Vector2, b: Vector2) -> bool:
	return a.distance_to(b) < 0.1
