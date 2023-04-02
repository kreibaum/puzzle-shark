class_name DeleteTool extends State

## This state makes a ghost vertex follow the mouse. By clicking you place it
## and it becomes a real vertex. By clicking on a vertex you can move it.
## By right clicking you can delete a vertex.

## Tracks on which object the mouse started its action
var vertex_on_which_click_started = null
var edge_on_which_click_started = null


## This code is currently being shared with SelectState.gd via copy-paste.
func vertex_hover_event(vertex: Vertex, is_hovering: bool):
	# If we are already hovering something, we don't want to change that.
	if canvas.current_hover != null and vertex != canvas.current_hover:
		return

	vertex.hovered = is_hovering

	# Our state machine should remember what we are currently hovering.
	if !vertex.hovered:
		canvas.current_hover = null
	else:
		canvas.current_hover = vertex


func edge_input_event(edge: Edge, event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				edge_on_which_click_started = edge
			elif edge_on_which_click_started == edge:
				canvas.delete_edge(edge)
				edge_on_which_click_started = null


func unhandled_input(event):
	if event is InputEventMouseButton:
		if canvas.current_hover != null && event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				vertex_on_which_click_started = canvas.current_hover
			elif vertex_on_which_click_started == canvas.current_hover:
				canvas.delete_vertex(canvas.current_hover)
				vertex_on_which_click_started = null
