class_name EdgeState extends State

## The edge state can be used to easily modify properties of edges and to
## create new edges between specific nodes.

## Tracks on which object the mouse started its action
## This is to create edges between two nodes
var vertex_on_which_click_started = null

var preview_edge = null


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


func input(event: InputEvent):
	# This is how you consume an event and prevent it from being passed to other nodes
	# ui_canvas.get_viewport().set_input_as_handled()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("Handling mouse button event", vertex_on_which_click_started, event)

			if canvas.current_hover != null && event.pressed:
				vertex_on_which_click_started = canvas.current_hover
				print("Started click on " + vertex_on_which_click_started.name)
			elif vertex_on_which_click_started != null && !event.pressed:
				if canvas.current_hover != null:
					canvas.create_edge(vertex_on_which_click_started, canvas.current_hover)
				else:
					# In this case, we create a new vertex and then create an edge to it.
					var new_vertex = canvas.create_vertex(canvas.get_global_mouse_position())
					canvas.create_edge(vertex_on_which_click_started, new_vertex)
