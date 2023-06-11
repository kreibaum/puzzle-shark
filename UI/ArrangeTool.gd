class_name SelectTool extends State

## Source object that an action originates from
var source_object: PuzzleObject = null

## Selection box
var selection_box_scene = preload("res://UI/selection_box.tscn")
var selection_box: SelectionBox = null

# Variables related to dragging. INF means we are not dragging.
## The constrained mouse position in the last frame while we were dragging.
var drag_position: Vector2 = Vector2.INF


## To select multiple vertices at once, you can add nodes to the selection set
## by shift clicking or shift dragging a selection box.
## Shift clicking a node can also remove it from the selection set.
func is_additive_selection():
	return Input.is_key_pressed(KEY_SHIFT)


#
# Vertex actions
#
# Scope:
# - select individual vertices by clicking on them
# - additive / subtractive selection is enabled by CTRL
# - move vertices (alone or as in group)
#


func remember_drag_start_vertex(vertex: Vertex):
	drag_position = canvas.get_global_mouse_position()
	drag_position = canvas.apply_vertex_constraints(vertex, drag_position)


func handle_click_vertex(vertex: Vertex):
	# There are three possible scenarios when left-clicking on a vertex.
	# 1. The selection is additive. Then we can immediately add or remove
	#    the clicked vertex from the current selection of the canvas.
	#    Crucially, we don't have the problem that we might want to deselect
	#    all other currently selected vertices when no dragging event occurs.
	#    The latter problem is a bit inconvenient, since we only know about
	#    dragging once the mouse moves for the first time
	# 2. The selection is not additive and we click on an already selected
	#    vertex. In this case, all other selected vertices should be
	#    incorporated in a potential dragging event, but if no dragging event
	#    happens, we want to deselect all other selected vertices. This is
	#    communicated by setting drag_vertex to the clicked vertex and setting
	#    drag_position = INF. If this is not changed during a drag event, we
	#    can deselect the vertices on release.
	# 3. The selection is not additive and we click on an unselected vertex.
	#    In this case, even if a drag event starts, we can safely deselect
	#    all other selected vertices right from the beginning

	canvas.deselect_sticker()

	if is_additive_selection():
		if canvas.selected_vertices.has(vertex):
			canvas.deselect_vertex(vertex)
		else:
			canvas.select_vertex(vertex)
		remember_drag_start_vertex(vertex)
		for selected in canvas.selected_vertices:
			selected.store_position()
	elif canvas.selected_vertices.has(vertex):
		# Deselection of all other vertices only happens if no dragging
		# event is induced
		canvas.select_vertex(vertex)
		# Signal for handle_motion_vertex that a new dragging event might begin
		# and that we want to deselect all vertices except for drag_vertex
		# if no dragging event takees place
		drag_position = Vector2.INF
	else:
		canvas.deselect_all()
		canvas.select_vertex(vertex)
		remember_drag_start_vertex(vertex)
		vertex.store_position()
	set_input_as_handled()


## Handles mouse motion based on the global mouse position.
func handle_motion_vertex(vertex: Vertex):
	if drag_position == Vector2.INF:
		# We are in setting 2. described above and want to initiate a drag
		# event
		remember_drag_start_vertex(vertex)
		for selected in canvas.selected_vertices:
			selected.store_position()
		return

	# Move all selected vertices
	var mouse_position = canvas.get_global_mouse_position()
	var mouse_position_constrained = canvas.apply_vertex_constraints(vertex, mouse_position)
	var delta = mouse_position_constrained - drag_position
	canvas.move_selected_vertices_by(delta)
	drag_position = mouse_position_constrained
	# If we set motion events as handled, we are not able to focus / hover
	# over other objects while dragging. However, we for example want to register
	# if we drag the vertex onto a sticker for anchoring purposes
	# set_input_as_handled()


## Handles release of the left mouse button.
func handle_release_vertex(vertex: Vertex):
	if vertex != null and drag_position == Vector2.INF:
		canvas.deselect_all()
		canvas.select_vertex(vertex)
		source_object = null

	elif drag_position != Vector2.INF:
		handle_motion_vertex(vertex)
		drag_position = Vector2.INF
		source_object = null
		for selected in canvas.selected_vertices:
			selected.unstore_position()
	set_input_as_handled()


func handle_interrupt_vertex(_vertex: Vertex):
	if drag_position != Vector2.INF:
		# Dragging event was going on. Roll it back
		drag_position = Vector2.INF
		source_object = null
		for selected in canvas.selected_vertices:
			selected.restore_position()
	set_input_as_handled()


#
# Edge actions
#
# Scope:
# - select individual vertices by clicking on them
# - additive / subtractive selection is enabled by CTRL
# - move vertices (alone or as in group)
#


func handle_click_edge(edge: Edge):
	# Select vertices
	if !is_additive_selection():
		canvas.deselect_all()
	canvas.select_vertex(edge.left_vertex)
	canvas.select_vertex(edge.right_vertex)

	# Prepare drag
	drag_position = canvas.get_global_mouse_position()
	drag_position = canvas.project_bbox(drag_position)
	for selected in canvas.selected_vertices:
		selected.store_position()
	set_input_as_handled()


func handle_motion_edge(_edge: Edge):
	var mouse_position = canvas.get_global_mouse_position()
	var mouse_position_constrained = canvas.project_bbox(mouse_position)
	var delta = mouse_position_constrained - drag_position
	canvas.move_selected_vertices_by(delta)
	drag_position = mouse_position_constrained
	set_input_as_handled()


func handle_release_edge(edge: Edge):
	handle_motion_edge(edge)
	drag_position = Vector2.INF
	source_object = null
	for selected in canvas.selected_vertices:
		selected.unstore_position()
	set_input_as_handled()


func handle_interrupt_edge(_edge: Edge):
	if drag_position != Vector2.INF:
		drag_position = Vector2.INF
		source_object = null
		for selected in canvas.selected_vertices:
			selected.restore_position()
	set_input_as_handled()


#
# Sticker actions
#
# Scope:
# - select individual vertices by clicking on them
# - additive / subtractive selection is enabled by CTRL
# - move vertices (alone or as group)
#


func handle_click_sticker(sticker: Sticker):
	canvas.deselect_all()
	canvas.select_sticker(sticker)
	sticker.store_position()
	drag_position = canvas.get_global_mouse_position()
	set_input_as_handled()


func handle_motion_sticker(sticker: Sticker):
	var new_position = canvas.get_global_mouse_position()
	var delta = new_position - drag_position
	canvas.move_sticker_by(sticker, delta)
	drag_position = new_position
	set_input_as_handled()


func handle_release_sticker(sticker: Sticker):
	drag_position = Vector2.INF
	source_object = null
	sticker.unstore_position()
	set_input_as_handled()


func handle_interrupt_sticker(sticker: Sticker):
	sticker.restore_position()
	handle_release_sticker(sticker)


#
# Rotations and scalings of Stickers and edges
#


## Returns the object that is currently affected by rotations
func get_rotation_object():
	# If an object is focused, take it
	var object = canvas.get_focused_object()
	if object != null:
		return object
	# If no object is focused, search for either a selected sticker or
	# a single selected edge
	else:
		var edges = canvas.get_selected_edges()
		if canvas.selected_sticker != null:
			return canvas.selected_sticker
		elif len(edges) == 1:
			return edges[0]
		else:
			return


## Returns the object that is currently affected by scalings
func get_scale_object():
	return get_rotation_object()


#
# Rectangle selection
#
# Scope:
# - draw a rectangle and select all vertices within it
# - does not select stickers, these have to be moved by hand
# - initialized if user is not clicking on any other selectable object
#


func handle_click_box():
	if !is_additive_selection():
		canvas.deselect_all()
	selection_box = selection_box_scene.instantiate()
	# canvas.camera.zoom_changed.connect(selection_box.on_zoom_change)
	canvas.add_child(selection_box)
	selection_box.start_selection()
	set_input_as_handled()


func handle_motion_box():
	if selection_box != null:
		selection_box.move_selection()
	set_input_as_handled()


func handle_release_box():
	if selection_box != null:
		if !is_additive_selection():
			canvas.deselect_all()
		for vertex in selection_box.current_selection:
			canvas.select_vertex(vertex)
		selection_box.end_selection()
		selection_box.queue_free()
		selection_box = null
	set_input_as_handled()


func handle_interrupt_box():
	if selection_box != null:
		selection_box.end_selection()
		for vertex in selection_box.current_selection:
			if not canvas.selected_vertices.has(vertex):
				vertex.set_active(false)
		selection_box.queue_free()
		selection_box = null
	set_input_as_handled()


func handle_anchor(object: PuzzleObject, backwards = false):
	# First see if an object is focused. The focused object receives priority
	# for setting the anchor
	if object != null:
		object.cycle_anchor_mode(canvas.hovered_objects, backwards)
	# If nothing is focused, search for selected objects
	# Depending on the context of the action, we either want the object to be
	# able to anchor on other puzzle objects or not
	elif len(canvas.selected_vertices) > 0:
		for vertex in canvas.selected_vertices:
			if len(canvas.selected_vertices) == 1 and vertex in canvas.hovered_objects:
				vertex.cycle_anchor_mode(canvas.hovered_objects, backwards)
			else:
				vertex.cycle_anchor_mode([], backwards)
	elif canvas.selected_sticker != null:
		if canvas.selected_sticker == object:
			canvas.selected_sticker.cycle_anchor_mode(canvas.hovered_objects, backwards)
		else:
			canvas.selected_sticker.cycle_anchor_mode([], backwards)
	set_input_as_handled()


func input(event):
	if event is InputEventMouseButton:
		# A right click when we are not currently involved in any actions means
		# that we cycle through anchor modes
		var idle = drag_position == Vector2.INF and selection_box == null
		if Input.is_action_just_pressed("RightClick") and idle:
			var object = canvas.get_focused_object()
			if Input.is_key_pressed(KEY_SHIFT):
				handle_anchor(object, true)
			else:
				handle_anchor(object, false)

		# A left click means that we directly select new objects, start draggiing,
		# draw a rectangle selection box
		elif Input.is_action_just_pressed("LeftClick"):
			# The left mouse button has just been clicked
			# First, find out which object is focused and set it as the
			# source for the action to come.
			source_object = canvas.get_focused_object()

			if source_object is Vertex:
				handle_click_vertex(source_object)
			elif source_object is Edge:
				handle_click_edge(source_object)
			elif source_object is Sticker:
				handle_click_sticker(source_object)
			elif source_object == null:
				handle_click_box()

		# A right click means that we directly select new objects, start dragging,
		# or draw a rectangle selection box
		elif Input.is_action_just_pressed("RightClick"):
			if source_object is Vertex:
				handle_interrupt_vertex(source_object)
			elif source_object is Edge:
				handle_interrupt_edge(source_object)
			elif source_object is Sticker:
				handle_interrupt_sticker(source_object)
			elif source_object == null:
				handle_interrupt_box()

		# Release of a left click means that we finish a selection or drag
		# event
		elif Input.is_action_just_released("LeftClick"):
			if source_object is Vertex:
				handle_release_vertex(source_object)
			elif source_object is Edge:
				handle_release_edge(source_object)
			elif source_object is Sticker:
				handle_release_sticker(source_object)
			elif source_object == null:
				handle_release_box()

	elif event is InputEventMouseMotion:
		if Input.is_action_pressed("LeftClick"):
			if source_object is Vertex:
				handle_motion_vertex(source_object)
			elif source_object is Edge:
				handle_motion_edge(source_object)
			elif source_object is Sticker:
				handle_motion_sticker(source_object)
			elif source_object == null:
				handle_motion_box()

	if Input.is_action_just_pressed("RotateRightFine"):
		source_object = get_rotation_object()
		if source_object is Edge:
			canvas.rotate_edge(source_object, 1.0 * PI / 180)
		elif source_object is Sticker:
			canvas.rotate_sticker(source_object, 1.0 * PI / 180)
		set_input_as_handled()

	elif Input.is_action_just_pressed("RotateRight"):
		source_object = get_rotation_object()
		if source_object is Edge:
			canvas.rotate_edge(source_object, 10.0 * PI / 180.0)
		elif source_object is Sticker:
			canvas.rotate_sticker(source_object, 10.0 * PI / 180.0)
		set_input_as_handled()

	elif Input.is_action_just_pressed("RotateLeftFine"):
		source_object = get_rotation_object()
		if source_object is Edge:
			canvas.rotate_edge(source_object, -1.0 * PI / 180.0)
		elif source_object is Sticker:
			canvas.rotate_sticker(source_object, -1.0 * PI / 180.0)
		set_input_as_handled()

	elif Input.is_action_just_pressed("RotateLeft"):
		source_object = get_rotation_object()
		if source_object is Edge:
			canvas.rotate_edge(source_object, -10.0 * PI / 180.0)
		elif source_object is Sticker:
			canvas.rotate_sticker(source_object, -10.0 * PI / 180.0)
		set_input_as_handled()

	elif Input.is_action_just_pressed("ScaleUpFine"):
		source_object = get_scale_object()
		if source_object is Edge:
			canvas.scale_edge(source_object, 1.01)
		elif source_object is Sticker:
			canvas.scale_sticker(source_object, 1.01)
		set_input_as_handled()

	elif Input.is_action_just_pressed("ScaleUp"):
		source_object = get_scale_object()
		if source_object is Edge:
			canvas.scale_edge(source_object, 1.1)
		elif source_object is Sticker:
			canvas.scale_sticker(source_object, 1.1)
		set_input_as_handled()

	elif Input.is_action_just_pressed("ScaleDownFine"):
		source_object = get_scale_object()
		if source_object is Edge:
			canvas.scale_edge(source_object, 1 / 1.01)
		elif source_object is Sticker:
			canvas.scale_sticker(source_object, 1 / 1.01)
		set_input_as_handled()

	elif Input.is_action_just_pressed("ScaleDown"):
		source_object = get_scale_object()
		if source_object is Edge:
			canvas.scale_edge(source_object, 1 / 1.1)
		elif source_object is Sticker:
			canvas.scale_sticker(source_object, 1 / 1.1)
		set_input_as_handled()

	# TODO: This really shouldn't be in the ArrangeTool.
	elif Input.is_action_just_pressed("ExportPuzzle"):
		print("Saving to file...")
		print(OS.get_user_data_dir())
		canvas.saveToFile()

	# Delete all selected vertices
	if Input.is_action_just_pressed("Delete"):
		var keys = canvas.selected_vertices.keys()
		for vertex in keys:
			canvas.delete_vertex(vertex)
