class_name Edge extends PuzzleObject

## First vertex that the edge is connected to
@export var left_vertex: Vertex

## Second vertex that the edge is connected to
@export var right_vertex: Vertex

## Thickness of the outline that is shown when hovered or active
@export var outline_width: float = 10.0
@export var	collider_width: float = 16.0

## Points of the edge skeleton (local coordinates)
## Skeleton points are normalized in local coordinates such that the
## left vertex is mapped to (0,0) and the right vertex to (100, 0).
var skeleton: PackedVector2Array

## Points of the smoothly interpolated edge (local coordinates)
var points: PackedVector2Array

## Difference vector from left to right vertex of the edge (global coordinates)
var baseline: Vector2 = Vector2(0, 0)

## Setting this variable to true induces a positional update in the next
## process step
var must_update_position: bool = true

## Store the current camera zoom
var camera_zoom: float = 1.0

## Indicator of collisions are disabled due to a short baseline
var collision_disabled = false


# TODO: This should be combined with some general shape management code.
func make_straight():
	var left = Vector2.ZERO
	var right = 100 * Vector2.RIGHT
	var edge_shape = PackedVector2Array()
	edge_shape.append(left)
	edge_shape.append(right)
	self.points = edge_shape
	update()


## Rotate and scale a skeleton to have a normalized local baseline from
## (0,0) to (100, 0).
func normalize_skeleton():
	var left = skeleton[0]
	var right = skeleton[-1]
	var transformation = FixedPointTransform2D.build_transformation_matrix(
		left, right, Vector2(0,0), Vector2(100, 0)
	)
	skeleton = transformation * skeleton

## Smooth the edge skeleton via a CatmulRomSpline
func smooth_skeleton():
	$CatmulRomSpline.refresh_samples(self.skeleton)
	if $CatmulRomSpline.is_relevant:
		self.points = $CatmulRomSpline.points.duplicate()

## Set a new skeleton for the edge
func set_skeleton(new_points: PackedVector2Array):
	self.skeleton = new_points
	normalize_skeleton()
	smooth_skeleton()


## Update the outline of the edge. The outline helps create visual effects (like
## a glow) when the edge is focused or active
func update_outline():
	$Outline.set_points(points)
	$Outline.width = outline_width / camera_zoom / scale.x

## Create a box around the interval [-1, 1]^2
## Used to cut away a part of the collider polygon close to the vertices
func margin_box(center, radius):
	var box_points = PackedVector2Array()
	box_points.append(center + radius * Vector2(1, 1))
	box_points.append(center + radius * Vector2(1, -1))
	box_points.append(center + radius * Vector2(-1, -1))
	box_points.append(center + radius * Vector2(-1, 1))
	return box_points

# Recalculate the polygon for the collision area
func update_collider():
	var thickness = collider_width / self.scale.x / 2
	var hull = PackedVector2Array()
	if baseline.length() > 0:
		# offset_polyline produces a "thickened" version of the polyline
		# as polygon. 
		var polys = Geometry2D.offset_polyline(points, thickness)
		if len(polys) == 0:
			collision_disabled = true
			return
		hull = polys[0]

		# A poor heuristic to decide how much should be cut from
		# the resulting polygon close to the vertices.
		var cutfraction = baseline.length() / (2 * thickness)
		var cutradius = min(cutfraction, 3) * thickness

		var left_clip = margin_box(points[0], cutradius)
		polys = Geometry2D.clip_polygons(hull, left_clip)
		if len(polys) > 0:
			hull = polys[0]

		var right_clip = margin_box(points[-1], cutradius)
		polys = Geometry2D.clip_polygons(hull, right_clip)
		if len(polys) > 0:
			hull = polys[0]

	collision_disabled = false
	input_pickable = true
	$Polygon.set_polygon(hull)

## Construct the transformation matrix that maps the node polyline to its vertices
func build_transformation_matrix():
	var left: Vector2 = self.points[0]
	var right: Vector2 = self.points[-1]
	return FixedPointTransform2D.build_transformation_matrix(
		left, right, left_vertex.position, right_vertex.position
	)

# Transform the edge to match the global coordinates of its vertices.
func update_position():
	baseline = right_vertex.position - left_vertex.position
	var transformation = build_transformation_matrix()
	# Check if the transformation is valid. It is invalid if the left and
	# right vertices are too close together in canvas-space. In this case,
	# setting the transformation would lead to a c++ error down the line.
	if transformation:
		if collision_disabled:
			update_collider()
		set_transform(transformation)
	else:
		# If we do not set a new transformation due to invaliditdy,
		# we should disable the edge
		collision_disabled = true
		input_pickable = false

## Combines various update functions to make sure that everything is up-to-date
## and drawn correctly
func update():
	update_position()
	update_collider()
	update_outline()
	queue_redraw()


## Return absolute point coordinates of the edge
func get_shape_points() -> PackedVector2Array:
	return self.transform * self.points

func get_center():
	return self.transform * Vector2(50, 0)

## Check if a vertex is part of this edge
func is_connected_to(vertex: Vertex):
	return left_vertex == vertex or right_vertex == vertex

# Ask the node to update its transformation in the next _process step
func query_update_position():
	self.must_update_position = true

# Called when the node enters the scene tree for the first time.
# At this point, all other nodes already exist, even though they may not be
# members of the scene tree yet.
func _ready():
	normalize_skeleton()
	left_vertex.position_changed.connect(query_update_position)
	right_vertex.position_changed.connect(query_update_position)
	smooth_skeleton()
	update()

func _draw():
	draw_polyline(points, Color.WHITE, -1, false)
	# if active or focused:
	var multiline = PackedVector2Array()
	for i in range(0, 26):
		multiline.append(Vector2(i * 4, 0))
	draw_multiline(multiline, Color(1.0, 1.0, 1.0, 0.8))

## Check for overlap with another edge.
func _process(_delta):
	if must_update_position:
		must_update_position = false
		update()

## Adapts the outline color according to the current edge state
func update_outline_color():
	$Outline.width = outline_width / camera_zoom / scale.x
	if focused and active:
		$Outline.default_color = Color("cc9766")
		$Outline.modulate = Color(1.2, 1.2, 1.2, 1.0)
	elif not focused and active:
		$Outline.default_color = Color("cc9766")
		$Outline.modulate = Color(1.0, 1.0, 1.0, 1.0)
	elif focused and not active:
		$Outline.default_color = Color.WHITE
		$Outline.modulate = Color(1.0, 1.0, 1.0, 0.40)
	elif not focused and not active:
		$Outline.modulate = Color(1.0, 1.0, 1.0, 0.0)

func _set_virtual(value):
	if value:
		self.modulate = Color(1, 1, 1, 0.75)
		$Polygon.disabled = true
		$Outline.visible = false
	else:
		self.modulate = Color(1, 1, 1, 1)
		$Polygon.disabled = false
		$Outline.visible = true

func _set_focused(_value):
	update_outline_color()

func _set_active(_value):
	update_outline_color()

func on_zoom_change(zoom: Vector2):
	camera_zoom = zoom.x
	if active or focused:
		$Outline.width = outline_width / camera_zoom / scale.x
