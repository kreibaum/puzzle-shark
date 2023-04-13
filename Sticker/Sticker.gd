class_name Sticker extends PuzzleObject

## A sticker is a collection of polylines. Each of these polylines can be marked
## as "sticky" or "non sticky". Both types get exported into the svg and are
## shown in the editor. But Vertices only stick to sticky polylines.
##
## This means the sticky polylines are the "walls" of the sticker. The non
## sticky polylines are the "holes" in the sticker to make it read better.
##
## Stickers are loaded from a json file. The json file is a list of polylines.

## Dictionary with Line2D objects as keys and collider objects as values.
## If the collider is null, the polyline is not sticky.
var lines = {}

## Bounding box of the sticker
var bbox: Rect2 = Rect2(Vector2.INF, Vector2.INF)

## List of vertices that are anchored to the sticker
var anchored_vertices: Array = []

## Smooth transformations
var transform_target: Transform2D = transform
var transform_start: Transform2D
var transform_tween: Tween

func set_transform_hard(trafo: Transform2D):
	if transform_tween: transform_tween.kill()
	transform_target = trafo
	transform = trafo
	position_changed.emit()

func set_transform_smooth(trafo: Transform2D):
	if transform_tween: transform_tween.kill()
	transform_start = transform
	transform_target = trafo
	transform_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	transform_tween.tween_method(interpolate_transform, 0.0, 1.0, 0.5)

func interpolate_transform(t: float):
	transform = transform_start.interpolate_with(transform_target, t)
	position_changed.emit()


func anchor_vertex(vertex: Vertex):
	anchored_vertices.append(vertex)

func unanchor_vertex(vertex: Vertex):
	var index = anchored_vertices.find(vertex)
	anchored_vertices.remove_at(index)


## Anchor options of a sticker
enum ANCHOR {
	FREE = 0,
	CANVAS = 1
}

var anchor: ANCHOR

@export var line_width: float = 4.0
@export var collider_width: float = 12.0
# @export var line_texture: GradientTexture2D

## Store the current camera zoom level. Needed for adjusting the thickness
## of the drawn lines
var camera_zoom: float = 1.0

## Get the center of the sticker. It equals the center of the sticker's bounding
## box in global coordinates
func get_center():
	return self.transform * bbox.get_center()

## Add a polyline to the sticker
func add_polyline(points: PackedVector2Array, sticky: bool):
	# Adapt the bounding box
	if bbox.position == Vector2.INF:
		# first time a polyline is added
		bbox = Rect2(points[0], Vector2.ZERO)
	for point in points:
		bbox = bbox.expand(point)

	var line = Line2D.new()
	line.points = points
	line.width = line_width / camera_zoom / scale.x / 2
	line.show_behind_parent = true
	# line.texture = line_texture
	# line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
	add_child(line)

	if sticky:
		line.modulate = Color(1.0, 1.0, 1.0)
		var collider = CollisionPolygon2D.new()
		update_collider(collider, line.points)
		add_child(collider)
		lines[line] = collider

	else:
		line.modulate = Color(1.0, 1.0, 1.0, 0.5)
		lines[line] = null
	queue_redraw()

## Adjust the collision polygon of a collider to a polyline
func update_collider(collider: CollisionPolygon2D, points: PackedVector2Array):
	var thickness = collider_width / self.scale.x / 2
	var polys = Geometry2D.offset_polyline(points, thickness)
	if len(polys) == 0:
		push_warning("Unable to construct collider ", collider)
		return
	elif len(polys) == 1:
		collider.polygon = polys[0]
	# TODO: Here we get a collision shape with a hole. Make this work!
	elif len(polys) == 2:
		collider.polygon = polys[0]

## Update function that should be called whenever the geometry / transform
## of the sticker changes
func update():
	for line in lines:
		line.width = line_width / camera_zoom / scale.x
		var collider = lines[line]
		if collider != null:
			update_collider(collider, line.points)
	

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



func _ready():
	position_changed.connect(update)
	update()
	update_line_color()

func _draw():
	for line in lines:
		draw_polyline(line.points, Color("3d3d3d"))

func set_anchor_mode(new_anchor: ANCHOR, _context: Array = []) -> bool:
	if new_anchor == anchor:
		return true
	else:
		anchor = new_anchor
		if anchor == ANCHOR.FREE:
			for line in lines:
				line.self_modulate = Color(1.0, 1.0, 1.0)
		if anchor == ANCHOR.CANVAS:
			for line in lines:
				line.self_modulate = Color(0.65, 0.65, 0.65)
		return true

# TODO: This should become part of the PuzzleObject interface
func cycle_anchor_mode(context: Array = [], _backwards = false):
	var next_mode = (anchor + 1) % 2 as ANCHOR
	set_anchor_mode(next_mode, context)
	return

func apply_anchor_constraint(transformation):
	if anchor == ANCHOR.FREE:
		return transformation
	else:
		return self.transform

## Adapts the line color according to the current sticker state
func update_line_color():
	if focused and active:
		self.modulate = Color(1.2, 1.2, 1.2, 1.0)
		for line in lines:
			line.default_color = Color("cc9766")
	if not focused and active:
		self.modulate = Color(1.0, 1.0, 1.0, 1.0)
		for line in lines:
			line.default_color = Color("cc9766")
	elif focused and not active:
		self.modulate = Color(1.2, 1.2, 1.2, 1.0)
		for line in lines:
			line.default_color = Color.WHITE
	elif not focused and not active:
		self.modulate = Color(1.0, 1.0, 1.0, 1.0)
		for line in lines:
			line.default_color = Color.LIGHT_GRAY

func _set_virtual(value):
	if value:
		self.modulate = Color(1, 1, 1, 0.75)
		for line in lines:
			var collider = lines[line]
			if collider != null:
				collider.disabled = true
	else:
		self.modulate = Color(1, 1, 1, 1)
		for line in lines:
			var collider = lines[line]
			if collider != null:
				collider.disabled = false

func _set_focused(_value):
	update_line_color()

func _set_active(_value):
	update_line_color()

func on_zoom_change(zoom: Vector2):
	camera_zoom = zoom.x
	for line in lines:
		line.width = line_width / camera_zoom / scale.x

func project_onto_object(point: Vector2):
	return find_nearest_sticky_point(point)
