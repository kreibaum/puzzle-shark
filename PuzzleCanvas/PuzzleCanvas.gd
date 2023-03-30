class_name PuzzleCanvas extends Node2D

var handle_scene = preload("res://drag_drop_handle.tscn")
var edge_scene = preload("res://Edge/edge.tscn")

@export var camera: Camera2D

var points = {}
var edges = []

var current_hover = null

# We can only use a dictionary, there are no dedicated sets.
# The actual value does not matter.
## The set of currently selected handles.
var current_selection: Dictionary = Dictionary()

## Triggered when the selection changes.
signal selection_changed

# Variables related to dragging. INF means we are not dragging.
var drag_start: Vector2 = Vector2.INF


# Called when the node enters the scene tree for the first time.
func _ready():
	var w = 7
	var h = 5
	
	for x in range(0, w):
		for y in range(0, h):
			var handle = handle_scene.instantiate()
			points[Vector2i(x, y)] = handle
			handle.position = Vector2(150 * x, 150 * y)
			handle.z_index = 2
			handle.camera = camera

			# Since all events potentially affect multiple handles, we delegate
			# the events to the canvas (Self), which can then handle them.
			handle.captured_input_event.connect(handle_delegated_input_event)
			handle.captured_hover_event.connect(handle_delegated_hover_event)
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
	edge.captured_input_event.connect(handle_delegated_edge_input_event)

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
	

func handle_delegated_input_event(handle: DragDropHandle, event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# We are now dragging.
				drag_start = get_global_mouse_position()
			else:
				# Is this adding to the selection?
				if is_additive_selection():
					if current_selection.has(handle):
						deselect(handle)
					else:
						select(handle)
				else:
					# Exclusive mode, so we deselect everything else.
					deselect_all()
					select(handle)
				
				handle_mouse_release()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Rollback the drag.
			drag_start = Vector2.INF
			for any_handle in current_selection:
				any_handle.rollback_drag()

			# Remove the selection box without effect.
			$SelectionBox.end_selection()

	elif event is InputEventMouseMotion:
		handle_mouse_motion(event)

## Handles mouse motion based on the global mouse position.
func handle_mouse_motion(event: InputEventMouseMotion):
	if drag_start != Vector2.INF:
		# We are dragging, so we need to move all selected handles.
		var delta = get_global_mouse_position() - drag_start
		apply_on_selection(func(handle): handle.preview_drag(delta))

	if event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		$SelectionBox.move_selection()

func apply_on_selection(fkt):
	for any_handle in current_selection:
		fkt.call(any_handle)
	if current_hover != null and current_hover not in current_selection:
		fkt.call(current_hover)

## Handles release of the left mouse button.
func handle_mouse_release():
	# Are we dragging? If so, we need to commit the drag.
	if drag_start != Vector2.INF:
		var delta = get_global_mouse_position() - drag_start
		apply_on_selection(func(handle): handle.commit_drag(delta))
		drag_start = Vector2.INF

	# We also commit the selection box, if we have one:
	if $SelectionBox.is_selecting:
		# Is this adding to the selection?
		if !is_additive_selection():
			# Exclusive mode, so we deselect everything else.
			deselect_all()

		for handle in $SelectionBox.current_selection:
			select(handle)

		$SelectionBox.end_selection()


func handle_delegated_hover_event(handle: DragDropHandle, is_hovering: bool):
	# TODO: This does not handle overlapping handles in a great way.

	# If we are already hovering something, we don't want to change that.
	if current_hover != null and handle != current_hover:
		return

	handle.hovered = is_hovering

	# Our state machine should remember what we are currently hovering.
	if !handle.hovered:
		current_hover = null
	else:
		current_hover = handle


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if current_hover == null:
					$SelectionBox.start_selection()
			else:
				handle_mouse_release()

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Remove the selection box without effect.
			$SelectionBox.end_selection()

	elif event is InputEventMouseMotion:
		handle_mouse_motion(event)

	elif is_ctrl_s_down(event):
		print("Saving to file...")
		print(OS.get_user_data_dir())
		saveToFile()

var edge_on_which_click_started: Edge = null

func handle_delegated_edge_input_event(edge: Edge, event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				edge_on_which_click_started = edge
			else:
				if edge_on_which_click_started == edge:
					deselect_all()
					select(edge.left_handle)
					select(edge.right_handle)
				edge_on_which_click_started = null


## To select multiple handles at once, you can add nodes to the selection set
## by shift clicking or shift dragging a selection box.
## Shift clicking a node can also remove it from the selection set.
func is_additive_selection():
	return Input.is_key_pressed(KEY_SHIFT)


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


## Returns true if the given event is a ctrl+s key press.
## This is used to save the current state of the graph.
func is_ctrl_s_down(event) -> bool:
	return event is InputEventKey and event.keycode == KEY_S and event.ctrl_pressed and event.pressed

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
