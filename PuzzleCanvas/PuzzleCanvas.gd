class_name PuzzleCanvas extends Node2D

var vertex_scene = preload("res://vertex.tscn")
var edge_scene = preload("res://Edge/edge.tscn")

@export var state_machine: StateMachine
@export var camera: Camera2D

var bbox: Rect2
var edges = []
var vertices = []
var stickers = []

#
# Handling of hovered objects
#

# List of all objects that are currently under the mouse cursor.
# Objects that have been entered last are at the end of the list.
var hovered_objects: Array = []
var hover_filter: Callable

signal focus_changed


func clear():
	reset_hover_filter()
	# This needs to duplicate the list, because otherwise we would delete from
	# a list while iterating over it.
	for edge in edges.duplicate():
		delete_edge(edge)

	# This work without a .duplicate() call, because we only queue_free the
	# vertices which removes them from the scene tree later. This means we don't
	# actually invalidate the iterator.
	for vertex in $VertexContainer.get_children():
		delete_vertex(vertex)

	# This needs to duplicate the list, because otherwise we would delete from
	# a list while iterating over it.
	for sticker in stickers.duplicate():
		delete_sticker(sticker)


## Sets up a hover filter which can restrict hover events to a subset of
## objects. For example you can make edges not hoverable.
func set_hover_filter(f: Callable):
	hovered_objects = hovered_objects.filter(f)
	hover_filter = f


## Removes the hover filter which restricts which objects can be hovered.
func reset_hover_filter():
	hover_filter = func(_object): return true


## Called when an object in the puzzle canves receives mouse focus
func handle_hover_event(object: PuzzleObject, mouse_enters: bool = true):
	# Only need to handle hover events if they are not filtered
	if not hover_filter.call(object):
		return

	# Remember the focused object
	var prior_focus = get_focused_object()

	# Have to distinguish between mouse enter and mouse leave events
	if mouse_enters:
		var index = hovered_objects.find(object)
		if index != -1:
			# If we land here, the mouse_exits event has not been handled
			# successfully, since the mouse entered an object that is already
			# hovered. Probably, this will not happen.
			hovered_objects.remove_at(index)
		# Manually tell the previous top object in the hovered_objects list
		# that it should not be regarded to be hovered anymore
		if len(hovered_objects) > 0:
			hovered_objects[-1].set_focused(false)
		# The new object is now on top of the list. It is considered the
		# currently hovered object
		hovered_objects.append(object)
		object.set_focused(true)
	else:
		var index = hovered_objects.find(object)
		if index >= 0:
			hovered_objects.remove_at(index)
			object.set_focused(false)
		# If we have just removed the
		# Manually tell the next topmost object in the hovered_objects list
		# that it should be regarded to be hovered
		if len(hovered_objects) > 0 and index == len(hovered_objects):
			hovered_objects[-1].set_focused(true)

	# Compare new focus to old focus
	var new_focus = get_focused_object()
	if prior_focus != new_focus:
		# Emit a signal that the hovered object has changed
		focus_changed.emit()


## Returns the currently hovered object
func get_focused_object():
	if len(hovered_objects) > 0:
		return hovered_objects[-1]


func get_hovered_objects():
	return hovered_objects


func get_topmost_hovered_vertex():
	for index in range(len(hovered_objects) - 1, -1, -1):
		if hovered_objects[index] is Vertex:
			return hovered_objects[index]


func get_topmost_hovered_edge():
	for index in range(len(hovered_objects) - 1, -1, -1):
		if hovered_objects[index] is Vertex:
			return hovered_objects[index]


func get_topmost_hovered_sticker():
	for index in range(len(hovered_objects) - 1, -1, -1):
		if hovered_objects[index] is Sticker:
			return hovered_objects[index]


## Remove an item from the list of hovered objects. This should only be called
## as cleanup by code that deletes objects.
func unhover_object(object: PuzzleObject):
	var index = hovered_objects.find(object)
	if index >= 0:
		hovered_objects.remove_at(index)


#
# Handling of selected objects
#

# We can only use a dictionary, there are no dedicated sets.
# The actual value does not matter.
## The set of currently selected vertices.
var selected_vertices: Dictionary = Dictionary()
var selected_sticker: Sticker = null

## Triggered when the selection changes.
signal selection_changed


## Set the bounding box of the puzzle canvas
func set_bbox(rect: Rect2):
	bbox = rect
	var points = PackedVector2Array()
	points.append(bbox.position)
	points.append(bbox.position + Vector2(bbox.size.x, 0))
	points.append(bbox.position + bbox.size)
	points.append(bbox.position + Vector2(0, bbox.size.y))
	points.append(bbox.position)
	$BBox/Line2D.set_points(points)
	$BBox/Polygon2D.set_polygon(points)
	on_zoom_change(camera.zoom)


## The line thickness of the bbox is zoom-dependent
func on_zoom_change(zoom):
	$BBox/Line2D.width = 7 / zoom.x


## Project a point onto the puzzle canvas bbox
func project_bbox(point: Vector2):
	return point.clamp(bbox.position, bbox.position + bbox.size)


## Enforce all vertex constraints. If the vertex has the flags
## fixed_horizontal or fixed_vertical set to true, their y or x
## positions are not changed (unless required by the bbox projection)
func apply_vertex_constraints(vertex: Vertex, point: Vector2):
	var new_point = vertex.apply_anchor_constraints(point)
	return project_bbox(new_point)


func apply_sticker_constraints(sticker: Sticker, trafo: Transform2D):
	var new_trafo = sticker.apply_anchor_constraint(trafo)
	return new_trafo


#
# Edge management
#


## Creates an edge between the two vertices.
func create_edge(
	left: Vertex, right: Vertex, skeleton: PackedVector2Array = $EdgeGenerator.random_line()
) -> Edge:
	var edge: Edge = edge_scene.instantiate()
	edge.set_skeleton(skeleton)
	edge.set_focused(false, true)  # force all edges in non-focused mode
	edge.captured_hover_event.connect(handle_hover_event)
	camera.zoom_changed.connect(edge.on_zoom_change)

	edges.append(edge)
	edge.left_vertex = left
	edge.right_vertex = right
	add_child(edge)
	selection_changed.emit()
	return edge


func scale_edge(edge: Edge, zoom: float):
	var vertex_transform = FixedPointTransform2D.build_scale_matrix(zoom, edge.get_center())
	move_vertex_to(edge.left_vertex, vertex_transform * edge.left_vertex.position)
	move_vertex_to(edge.right_vertex, vertex_transform * edge.right_vertex.position)


func rotate_edge(edge: Edge, angle: float):
	var vertex_transform = FixedPointTransform2D.build_rotation_matrix(angle, edge.get_center())
	move_vertex_to(edge.left_vertex, vertex_transform * edge.left_vertex.position)
	move_vertex_to(edge.right_vertex, vertex_transform * edge.right_vertex.position)


## Remove an edge from the puzzle canvas
func delete_edge(edge: Edge):
	unhover_object(edge)
	edges.erase(edge)
	edge.queue_free()
	selection_changed.emit()


## Returns the edge between the two vertices, or null if there is none.
func find_edge(left: Vertex, right: Vertex) -> Edge:
	for edge in edges:
		if edge.left_vertex == left and edge.right_vertex == right:
			return edge
		elif edge.left_vertex == right and edge.right_vertex == left:
			return edge
	return null


func find_edges_to_active_vertices(vertex: Vertex) -> Array:
	var found_edges = []
	for edge in edges:
		if edge.left_vertex == vertex and edge.right_vertex.active:
			found_edges.append(edge)
		if edge.right_vertex == vertex and edge.left_vertex.active:
			found_edges.append(edge)
	return found_edges


## Returns an array containing all currently selected edges
func get_selected_edges() -> Array:
	var result = []
	for edge in edges:
		if edge.left_vertex in selected_vertices and edge.right_vertex in selected_vertices:
			result.append(edge)
	return result


#
# Vertex management
#


## Creates a new vertex and adds it to the canvas.
func create_vertex(target_position: Vector2) -> Vertex:
	var vertex = vertex_scene.instantiate()
	move_vertex_to(vertex, target_position)
	camera.zoom_changed.connect(vertex.on_zoom_change)
	vertex.on_zoom_change(camera.zoom)

	# Hovering events are currently managed by the canvas
	vertex.captured_hover_event.connect(handle_hover_event)

	$VertexContainer.add_child(vertex)
	vertices.append(vertex)
	return vertex


## Delete a vertex from the puzzle canvas
func delete_vertex(vertex: Vertex):
	var edges_to_delete = []
	for edge in edges:
		if edge.is_connected_to(vertex):
			edges_to_delete.append(edge)

	for edge in edges_to_delete:
		delete_edge(edge)

	if vertex.anchor_sticker != null:
		vertex.anchor_sticker.unanchor_vertex(vertex)

	deselect_vertex(vertex)
	unhover_object(vertex)
	vertices.erase(vertex)
	vertex.queue_free()


## Move a vertex to a target position. If this position is outside of
## the bounding box, project the vertex onto it. *All* modifications
## of a vertex' position should go through this function.
func move_vertex_to(vertex: Vertex, target_position: Vector2):
	var new_position = apply_vertex_constraints(vertex, target_position)
	if vertex.position != new_position:
		vertex.position = new_position
		vertex.position_changed.emit()


## Translate a vertex by an offset vector, respecting the canvas bounding box
func move_vertex_by(vertex: Vertex, delta: Vector2):
	var target_position = vertex.position + delta
	move_vertex_to(vertex, target_position)


## Removes a vertex from the selection set, if it is inside.
func deselect_vertex(vertex):
	selected_vertices.erase(vertex)
	vertex.set_active(false)
	for edge in find_edges_to_active_vertices(vertex):
		edge.set_active(false)
	selection_changed.emit()


## Removes all vertices from the selection set.
func deselect_all_vertices():
	for vertex in selected_vertices:
		vertex.set_active(false)
	for edge in edges:
		edge.set_active(false)
	selected_vertices.clear()
	selection_changed.emit()


## Adds a vertex to the selection set.
func select_vertex(vertex):
	selected_vertices[vertex] = true
	vertex.set_active(true)
	for edge in find_edges_to_active_vertices(vertex):
		edge.set_active(true)
	selection_changed.emit()


## Applies a function to all currently selected vertices.
## It also applies on the current hover if it is not selected.
func apply_on_selected_vertices(fkt):
	for any_vertex in selected_vertices:
		fkt.call(any_vertex)


func move_selected_vertices_by(delta: Vector2):
	apply_on_selected_vertices(func(vertex): move_vertex_by(vertex, delta))


#
# Sticker management
#


func add_sticker(sticker: Sticker):
	stickers.append(sticker)
	add_child(sticker)
	sticker.captured_hover_event.connect(handle_hover_event)
	camera.zoom_changed.connect(sticker.on_zoom_change)


func select_sticker(sticker: Sticker):
	if selected_sticker == sticker:
		return
	if selected_sticker != null:
		selected_sticker.set_active(false)
	selected_sticker = sticker
	selected_sticker.set_active(true)


func deselect_sticker():
	if selected_sticker != null:
		selected_sticker.set_active(false)
		selected_sticker = null


func move_sticker_to(sticker: Sticker, target_position: Vector2):
	var new_transform = Transform2D(0, target_position) * sticker.transform_target
	new_transform = apply_sticker_constraints(sticker, new_transform)
	sticker.set_transform_hard(new_transform)
	sticker.position_changed.emit()


func move_sticker_by(sticker: Sticker, delta: Vector2):
	var new_transform = sticker.transform_target.translated(delta)
	new_transform = apply_sticker_constraints(sticker, new_transform)
	sticker.set_transform_hard(new_transform)
	sticker.position_changed.emit()


## Change the sticker size by a factor of zoom while keeping the global
## mouse position pinned.
func scale_sticker(sticker: Sticker, zoom: float):
	var additional_transform = FixedPointTransform2D.build_scale_matrix(zoom, sticker.get_center())
	var new_transform = additional_transform * sticker.transform_target
	new_transform = apply_sticker_constraints(sticker, new_transform)
	sticker.set_transform_smooth(new_transform)
	sticker.position_changed.emit()


## Rotate a given sticker
func rotate_sticker(sticker: Sticker, sticker_rotation: float):
	var additional_transform = FixedPointTransform2D.build_rotation_matrix(
		sticker_rotation, sticker.get_center()
	)
	var new_transform = additional_transform * sticker.transform_target
	new_transform = apply_sticker_constraints(sticker, new_transform)
	sticker.set_transform_smooth(new_transform)
	sticker.position_changed.emit()


## Delets a sticker. Any Vertices that are currently attached to the sticker
## will be detached and kept in the puzzle.
func delete_sticker(sticker: Sticker):
	for vertex in sticker.anchored_vertices.duplicate():
		vertex.set_anchor_mode(Vertex.ANCHOR.FREE)
	unhover_object(sticker)
	stickers.erase(sticker)
	sticker.queue_free()


func deselect_all():
	deselect_all_vertices()
	deselect_sticker()


## Save the current puzzle canvas to an svg file
func saveToFile():
	var file = FileAccess.open("user://jigsaw.svg", FileAccess.WRITE)
	file.store_string('<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n')
	(
		file
		. store_string(
			'<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">\n'
		)
	)
	file.store_string('<svg xmlns="http://www.w3.org/2000/svg" version="1.1">\n')

	for edge in edges:
		# Svg path format: M x1 y1 L x2 y2 L x3 y3 ...
		file.store_string(
			'<path d="' + edge_path(edge) + '" stroke="black" stroke-width="2" fill="none"/>\n'
		)

	for sticker in stickers:
		print("Sticker: " + str(sticker))
		for line in sticker.lines:
			print("Line: " + str(line))
			file.store_string(
				(
					'<path d="'
					+ array2d_path(sticker.transform * line.points)
					+ '" stroke="black" stroke-width="2" fill="none"/>\n'
				)
			)

	file.store_string("</svg>")

	file.close()


func edge_path(edge: Edge) -> String:
	return array2d_path(edge.get_shape_points())


func array2d_path(array: Array) -> String:
	var svg_path = "M"
	# M is implicitly followed by L. So we don't have to include any L commands.
	for point in array:
		svg_path += " " + str(point.x) + " " + str(point.y)

	return svg_path


## Initialize the Puzzle Canvas on entering the scene tree
func _ready():
	# By default, the
	reset_hover_filter()

	var w = 7
	var h = 5

	var sharp_bbox = Rect2(Vector2(205, 105), Vector2((w - 1) * 150, (h - 1) * 150))
	set_bbox(sharp_bbox)
	camera.zoom_changed.connect(on_zoom_change)

	var positions = {}
	for x in range(0, w):
		for y in range(0, h):
			var vertex = create_vertex(Vector2(150 * x + 205, 150 * y + 105))
			positions[Vector2i(x, y)] = vertex

			var anchor_vertical = x == 0 or x == w - 1
			var anchor_horizontal = y == 0 or y == h - 1
			if anchor_vertical and anchor_horizontal:
				vertex.set_anchor_mode(Vertex.ANCHOR.CANVAS)
			elif anchor_vertical:
				vertex.set_anchor_mode(Vertex.ANCHOR.VERTICAL)
			elif anchor_horizontal:
				vertex.set_anchor_mode(Vertex.ANCHOR.HORIZONTAL)

	for x in range(1, w):
		for y in range(0, h):
			var edge = create_edge(positions[Vector2i(x - 1, y)], positions[Vector2i(x, y)])
			if y == 0 or y == h - 1:
				edge.make_straight()

	for x in range(0, w):
		for y in range(1, h):
			var edge = create_edge(positions[Vector2i(x, y - 1)], positions[Vector2i(x, y)])
			if x == 0 or x == w - 1:
				edge.make_straight()


## Pass along unhandled input to the state machine
func _unhandled_input(event):
	state_machine.unhandled_input(event)


## Pass along input to the state machine
func _input(event):
	state_machine.input(event)
