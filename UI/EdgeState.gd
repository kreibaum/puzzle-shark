class_name EdgeState extends State

## The edge state can be used to easily modify properties of edges and to
## create new edges between specific nodes.

## Tracks the last vertex that was clicked in the chain.
var last_vertex = null

var preview_edge
var preview_vertex


## On entering this state, we create a virtual vertex that follows the mouse.
func after_enter_state():
	var mouse_position = canvas.get_global_mouse_position()
	preview_vertex = canvas.create_vertex(mouse_position, Vertex.SUBSTANCE.VIRTUAL)
	preview_vertex.visible = canvas.current_hover == null


func exit_state():
	## Deleting the vertex automatically deletes a preview edge, if there is one.
	canvas.delete_vertex(preview_vertex)


func set_last_vertex(vertex: Vertex):
	last_vertex = vertex
	if preview_edge != null:
		canvas.delete_edge(preview_edge)
		preview_edge = null

	if last_vertex != null:
		preview_edge = canvas.create_edge(last_vertex, preview_vertex)
		preview_edge.make_straight()


## This code is currently being shared with SelectState.gd via copy-paste.
func vertex_hover_event(vertex: Vertex, is_hovering: bool):
	# If we are already hovering something, we don't want to change that.
	if canvas.current_hover != null and vertex != canvas.current_hover:
		return

	vertex.hovered = is_hovering

	# Our state machine should remember what we are currently hovering.
	if !vertex.hovered:
		canvas.current_hover = null
		preview_vertex.visible = true
	else:
		canvas.current_hover = vertex
		preview_vertex.visible = false


## The hovered vertex takes precedence over the preview vertex, if there is one.
func focused_vertex() -> Vertex:
	if canvas.current_hover != null:
		return canvas.current_hover
	else:
		return preview_vertex


func input(event: InputEvent):
	if event is InputEventMouseMotion:
		canvas.move_vertex_to(preview_vertex, canvas.get_global_mouse_position())

	# This is how you consume an event and prevent it from being passed to other nodes
	# ui_canvas.get_viewport().set_input_as_handled()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			# Case 1: We clicked the virtual vertex and are not currently drawing a chain.
			# In this case the chain starts with a new vertex.
			if last_vertex == null && canvas.current_hover == null:
				set_last_vertex(canvas.create_vertex(canvas.get_global_mouse_position()))
				vertex_hover_event(last_vertex, true)

			# Case 2: We clicked an actual vertex and are not currently drawing a chain.
			# In this case we start drawing a chain and don't create any objects.
			elif last_vertex == null && canvas.current_hover != null:
				set_last_vertex(canvas.current_hover)

			# Case 3: We clicked the virtual vertex and are currently drawing a chain.
			elif last_vertex != null && canvas.current_hover == null:
				var last_last_vertex = last_vertex
				set_last_vertex(canvas.create_vertex(canvas.get_global_mouse_position()))
				vertex_hover_event(last_vertex, true)
				canvas.create_edge(last_last_vertex, last_vertex)

			# Case 4: We clicked an actual vertex and are currently drawing a chain.
			elif last_vertex != null && canvas.current_hover != null:
				var last_last_vertex = last_vertex
				set_last_vertex(canvas.current_hover)
				canvas.create_edge(last_last_vertex, last_vertex)

		# If we right-click, we cancel the chain.
		if event.button_index == MOUSE_BUTTON_RIGHT:
			set_last_vertex(null)
