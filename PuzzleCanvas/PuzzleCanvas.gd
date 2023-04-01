class_name PuzzleCanvas extends Node2D

var handle_scene = preload("res://drag_drop_handle.tscn")
var edge_scene = preload("res://Edge/edge.tscn")

@export var state_machine: StateMachine
@export var camera: Camera2D

@onready var selection_box = $SelectionBox

var bbox: Rect2
var positions = {}
var edges = []

var current_hover = null

# We can only use a dictionary, there are no dedicated sets.
# The actual value does not matter.
## The set of currently selected handles.
var current_selection: Dictionary = Dictionary()

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
	update_zoom(camera.zoom)

## The line thickness of the bbox is zoom-dependent
func update_zoom(zoom):
	$BBox/Line2D.width = 7 / zoom.x


## Project a point onto the puzzle canvas bbox
func project_bbox(point: Vector2):
	return point.clamp(bbox.position, bbox.position + bbox.size)


## Enforce all handle constraints. If the handle has the flags
## fixed_horizontal or fixed_vertical set to true, their y or x
## positions are not changed (unless required by the bbox projection)
func enforce_constraints(handle : DragDropHandle, point: Vector2):
	if handle.fixed_horizontal:
		point.y = handle.position.y
	if handle.fixed_vertical:
		point.x = handle.position.x
	return project_bbox(point)


func _ready():
	var w = 7
	var h = 5

	var sharp_bbox = Rect2(Vector2(205, 105), Vector2((w-1) * 150, (h-1) * 150))
	set_bbox(sharp_bbox)
	camera.zoom_changed.connect(update_zoom)
	
	for x in range(0, w):
		for y in range(0, h):
			var handle = create_vertex(Vector2(150 * x + 205, 150 * y + 105))
			positions[Vector2i(x, y)] = handle

			if x == 0 or x == w - 1: handle.fix_vertical()
			if y == 0 or y == h - 1: handle.fix_horizontal()

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

## Creates a new vertex and adds it to the canvas.
func create_vertex( target_position :Vector2 ) -> DragDropHandle:
	var handle = handle_scene.instantiate()
	move_handle_to(handle, target_position)
	handle.z_index = 2
	handle.camera = camera

	# Since all events potentially affect multiple handles, we delegate
	# the events to the canvas (Self), which can then handle them.
	handle.captured_input_event.connect(state_machine.drag_drop_handle_input_event)
	handle.captured_hover_event.connect(state_machine.drag_drop_handle_hover_event)
	add_child(handle)
	return handle


## Creates an edge between the two handles.
func create_edge(left: DragDropHandle, right: DragDropHandle) -> Edge:
	var edge: Edge = edge_scene.instantiate()
	edge.set_points_before_init($EdgeGenerator.random_line())
	edge.captured_input_event.connect(state_machine.edge_input_event)

	edges.append(edge)
	edge.left_handle = left
	edge.right_handle = right
	edge.camera = camera
	add_child(edge)
	selection_changed.emit()
	return edge

## Returns the edge between the two handles, or null if there is none.
func find_edge(left: DragDropHandle, right: DragDropHandle) -> Edge:
	for edge in edges:
		if edge.left_handle == left and edge.right_handle == right:
			return edge
		elif edge.left_handle == right and edge.right_handle == left:
			return edge
	return null


## Returns an array containing all currently selected edges
func get_selected_edges() -> Array:
	var result = []
	for edge in edges:
		if edge.left_handle in current_selection and edge.right_handle in current_selection:
			result.append(edge)
	return result

## Remove an edge from the puzzle canvas
func delete_edge(edge: Edge):
	edges.erase(edge)
	edge.queue_free()
	selection_changed.emit()

## Move a handle to a target position. If this position is outside of
## the bounding box, project the handle onto it. *All* modifications
## of a handle's position should go through this function.
func move_handle_to(handle: DragDropHandle, target_position: Vector2):
	var new_position = enforce_constraints(handle, target_position)
	if handle.position != new_position:
		handle.position = new_position
		handle.position_changed.emit()

## Translate a handle by an offset vector, respecting the canvas bounding box
func move_handle_by(handle: DragDropHandle, delta: Vector2):
	var target_position = handle.position + delta
	move_handle_to(handle, target_position)

## Notify handle that a dragging event starts
func drag_handle_start(handle: DragDropHandle):
	handle.store_position(handle.position)

## Notify handle that a dragging event finished sucessfully
func drag_handle_end(handle: DragDropHandle):
	handle.unstore_position()
	
## Notify handle that a dragging event was aborted
func drag_handle_rollback(handle: DragDropHandle):
	move_handle_to(handle, handle.restore_position())

## Removes a handle from the selection set, if it is inside.
func deselect_handle(handle):
	current_selection.erase(handle)
	handle.selected = false
	selection_changed.emit()


## Removes all handles from the selection set.
func deselect_all_handles():
	for handle in current_selection:
		handle.selected = false
	current_selection.clear()
	selection_changed.emit()


## Adds a handle to the selection set.
func select_handle(handle):
	current_selection[handle] = true
	handle.selected = true
	selection_changed.emit()

## Applies a function to all currently selected handles. (Vertices)
## It also applies on the current hover if it is not selected.
func apply_on_selected_handles(fkt):
	for any_handle in current_selection:
		fkt.call(any_handle)
	if current_hover != null and current_hover not in current_selection:
		fkt.call(current_hover)

func move_selected_handles_by(delta: Vector2):
	apply_on_selected_handles(func(handle): move_handle_by(handle, delta))




func saveToFile():
	var file = FileAccess.open("user://jigsaw.svg", FileAccess.WRITE)
	file.store_string("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n")
	file.store_string("<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">\n")
	file.store_string("<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\">\n")

	for edge in edges:
		# Svg path format: M x1 y1 L x2 y2 L x3 y3 ...
		file.store_string("<path d=\"" + edge_path(edge) + "\" stroke=\"black\" stroke-width=\"2\" fill=\"none\"/>\n")

	file.store_string("</svg>")

	file.close()

func edge_path(edge: Edge) -> String:
	var svg_path = "M "
	for point in edge.get_shape_points():
		svg_path += str(point.x) + " " + str(point.y) + " L "
	svg_path = svg_path.trim_suffix(" L ")

	return svg_path

## Pass along unhandled input to the state machine
func _unhandled_input(event):
	state_machine.unhandled_input(event)
