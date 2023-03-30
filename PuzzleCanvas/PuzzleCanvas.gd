class_name PuzzleCanvas extends Node2D

var handle_scene = preload("res://drag_drop_handle.tscn")
var edge_scene = preload("res://Edge/edge.tscn")

@export var state_machine: StateMachine
@export var camera: Camera2D

@onready var selection_box = $SelectionBox

var points = {}
var edges = []

var current_hover = null

# We can only use a dictionary, there are no dedicated sets.
# The actual value does not matter.
## The set of currently selected handles.
var current_selection: Dictionary = Dictionary()

## Triggered when the selection changes.
signal selection_changed

func _ready():
	var w = 7
	var h = 5
	
	for x in range(0, w):
		for y in range(0, h):
			var handle = handle_scene.instantiate()
			points[Vector2i(x, y)] = handle
			handle.position = Vector2(150 * x + 205, 150 * y + 105)
			handle.z_index = 2
			handle.camera = camera

			# Since all events potentially affect multiple handles, we delegate
			# the events to the canvas (Self), which can then handle them.
			handle.captured_input_event.connect(state_machine.drag_drop_handle_input_event)
			handle.captured_hover_event.connect(state_machine.drag_drop_handle_hover_event)
			add_child(handle)

	for x in range(1, w):
		for y in range(0, h):
			var edge = create_edge(points[Vector2i(x - 1, y)], points[Vector2i(x, y)])
			if y == 0 or y == h - 1:
				edge.make_straight()

	for x in range(0, w):
		for y in range(1, h):
			var edge = create_edge(points[Vector2i(x, y - 1)], points[Vector2i(x, y)])
			if x == 0 or x == w - 1:
				edge.make_straight()

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


func get_selected_edges() -> Array:
	var result = []
	for edge in edges:
		if edge.left_handle in current_selection and edge.right_handle in current_selection:
			result.append(edge)
	return result

func delete_edge(edge: Edge):
	edges.erase(edge)
	edge.queue_free()
	selection_changed.emit()
	

## Applies a function to all currently selected handles. (Vertices)
## It also applies on the current hover if it is not selected.
func apply_on_selection(fkt):
	for any_handle in current_selection:
		fkt.call(any_handle)
	if current_hover != null and current_hover not in current_selection:
		fkt.call(current_hover)
		


func _unhandled_input(event):
	state_machine.unhandled_input(event)



## Removes a handle from the selection set, if it is inside.
func deselect(handle):
	current_selection.erase(handle)
	handle.selected = false
	selection_changed.emit()


## Removes all handles from the selection set.
func deselect_all():
	for handle in current_selection:
		handle.selected = false
	current_selection.clear()
	selection_changed.emit()


## Adds a handle to the selection set.
func select(handle):
	current_selection[handle] = true
	handle.selected = true
	selection_changed.emit()


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
