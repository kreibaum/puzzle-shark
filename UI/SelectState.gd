class_name SelectState extends State

# Variables related to dragging. INF means we are not dragging.
## The constrained mouse position in the last frame while we were dragging.
var drag_position: Vector2 = Vector2.INF
## The vertex that is used to execute drag operations. This is important for
## properly constraining the drag.
var drag_vertex: DragDropHandle = null


func remember_drag_start(vertex: DragDropHandle):
	drag_position = canvas.get_global_mouse_position()
	drag_position = canvas.enforce_constraints(vertex, drag_position)
	drag_vertex = vertex


func clear_drag_start():
	drag_position = Vector2.INF
	drag_vertex = null


func drag_drop_handle_input_event(handle: DragDropHandle, event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# We are now dragging.
				canvas.apply_on_selected_handles(canvas.drag_handle_start)
				remember_drag_start(handle)
			else:
				# Is this adding to the selection?
				if is_additive_selection():
					if canvas.current_selection.has(handle):
						canvas.deselect_handle(handle)
					else:
						canvas.select_handle(handle)
				else:
					# Exclusive mode, so we deselect everything else.
					canvas.deselect_all_handles()
					canvas.select_handle(handle)

				handle_mouse_release()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Rollback the drag.
			canvas.apply_on_selected_handles(canvas.drag_handle_rollback)
			clear_drag_start()

			# Remove the selection box without effect.
			canvas.selection_box.end_selection()

	elif event is InputEventMouseMotion:
		handle_mouse_motion(event)


## To select multiple handles at once, you can add nodes to the selection set
## by shift clicking or shift dragging a selection box.
## Shift clicking a node can also remove it from the selection set.
func is_additive_selection():
	return Input.is_key_pressed(KEY_SHIFT)


## Returns true if the given event is a ctrl+s key press.
## This is used to save the current state of the graph.
func is_ctrl_s_down(event) -> bool:
	return (
		event is InputEventKey and event.keycode == KEY_S and event.ctrl_pressed and event.pressed
	)


## Handles release of the left mouse button.
func handle_mouse_release():
	# Are we dragging? If so, we need to commit the drag.
	if drag_position != Vector2.INF:
		var mouse_position = canvas.get_global_mouse_position()
		var mouse_position_bbox = canvas.enforce_constraints(drag_vertex, mouse_position)
		var delta = mouse_position_bbox - drag_position
		canvas.move_selected_handles_by(delta)
		canvas.apply_on_selected_handles(canvas.drag_handle_end)
		clear_drag_start()

	# We also commit the selection box, if we have one:
	elif canvas.selection_box.is_selecting:
		# Is this adding to the selection?
		if !is_additive_selection():
			# Exclusive mode, so we deselect everything else.
			canvas.deselect_all_handles()

		for handle in canvas.selection_box.current_selection:
			canvas.select_handle(handle)

		canvas.selection_box.end_selection()


## Handles mouse motion based on the global mouse position.
func handle_mouse_motion(event: InputEventMouseMotion):
	if drag_position != Vector2.INF:
		# We are dragging, so we need to move all selected handles.
		var mouse_position = canvas.get_global_mouse_position()
		var mouse_position_constrained = canvas.enforce_constraints(drag_vertex, mouse_position)
		var delta = mouse_position_constrained - drag_position
		canvas.move_selected_handles_by(delta)
		drag_position = mouse_position_constrained  #canvas.project_bbox(mouse_position)

	if event.button_mask == MOUSE_BUTTON_MASK_LEFT:
		canvas.selection_box.move_selection()


func drag_drop_handle_hover_event(handle: DragDropHandle, is_hovering: bool):
	# TODO: This does not handle overlapping handles in a great way.

	# If we are already hovering something, we don't want to change that.
	if canvas.current_hover != null and handle != canvas.current_hover:
		return

	handle.hovered = is_hovering

	# Our state machine should remember what we are currently hovering.
	if !handle.hovered:
		canvas.current_hover = null
	else:
		canvas.current_hover = handle


var edge_on_which_click_started: Edge = null


func edge_input_event(edge: Edge, event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				edge_on_which_click_started = edge
			else:
				if edge_on_which_click_started == edge:
					canvas.deselect_all_handles()
					canvas.select_handle(edge.left_handle)
					canvas.select_handle(edge.right_handle)
				edge_on_which_click_started = null


func unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if canvas.current_hover == null:
					canvas.selection_box.start_selection()
			else:
				handle_mouse_release()

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Remove the selection box without effect.
			canvas.selection_box.end_selection()

	elif event is InputEventMouseMotion:
		handle_mouse_motion(event)

	elif is_ctrl_s_down(event):
		print("Saving to file...")
		print(OS.get_user_data_dir())
		canvas.saveToFile()
