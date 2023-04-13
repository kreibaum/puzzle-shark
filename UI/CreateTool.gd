class_name CreateTool extends State

## The edge state can be used to easily modify properties of edges and to
## create new edges between specific nodes.

## Tracks the last vertex that was clicked in the chain.
var chain_vertex: Vertex = null
var source_object: PuzzleObject

var preview_edge: Edge
var preview_vertex: Vertex

## On entering this state, we create a virtual vertex that follows the mouse.
func after_enter_state():
	var mouse_position = canvas.get_global_mouse_position()
	preview_vertex = canvas.create_vertex(mouse_position)
	preview_vertex.set_virtual(true)
	# We only want to interact with vertices or stickers in this tool
	canvas.set_hover_filter(func(object): return object is Vertex or object is Sticker)
	canvas.focus_changed.connect(update_preview_visibility)
	update_preview_visibility()

func exit_state():
	## Deleting the vertex automatically deletes a preview edge, if there is one.
	canvas.focus_changed.disconnect(update_preview_visibility)
	canvas.delete_vertex(preview_vertex)
	canvas.reset_hover_filter()

func update_preview_visibility():
	var object = canvas.get_focused_object()
	if object is Vertex and preview_vertex != null:
		preview_vertex.visible = false
	elif object is Sticker and preview_vertex != null:
		preview_vertex.set_inset_shape(Vertex.ANCHOR.STICKER)
		preview_vertex.visible = true
	else:
		preview_vertex.set_inset_shape(Vertex.ANCHOR.FREE)
		preview_vertex.visible = true

func delete_preview_edge():
	if preview_edge != null:
		canvas.delete_edge(preview_edge)
		preview_edge = null

func update_preview_edge(from: Vertex, to: Vertex):
	delete_preview_edge()
	preview_edge = canvas.create_edge(from, to)
	preview_edge.make_straight()
	preview_edge.set_virtual(true)

func get_sticky_mouse_position() -> Vector2:
	var mouse_position = canvas.get_global_mouse_position()
	var hover_sticker = canvas.get_topmost_hovered_sticker()
	if hover_sticker == null:
		return mouse_position
	else:
		return hover_sticker.find_nearest_sticky_point(mouse_position)
	
# TODO: more general auto-anchoring. Should also include auto-anchoring to
# the bounding box of the canvas. This can easily be done while reducing the
# number of cases below, just by defining an auxiliary function that manages
# anchoring based on the focused object.
func input(event: InputEvent):
	if event is InputEventMouseMotion:
		canvas.move_vertex_to(preview_vertex, get_sticky_mouse_position())
		# Here, we can not set the input as handled. Otherwise, the canvas
		# won't get notifications about hovering events

	# This is how you consume an event and prevent it from being passed to other nodes
	# ui_canvas.get_viewport().set_input_as_handled()
	if event is InputEventMouseButton:
		if Input.is_action_just_pressed("LeftClick"):
			var object = canvas.get_focused_object()

			# Case 1: We clicked the virtual vertex and are not currently drawing a chain.
			# In this case the chain starts with a new vertex.
			if object == null and chain_vertex == null:
				var new_vertex = canvas.create_vertex(get_sticky_mouse_position())
				update_preview_edge(new_vertex, preview_vertex)
				chain_vertex = new_vertex

			# Case 2: We clicked an actual vertex and are not currently drawing a chain.
			# In this case we start drawing a chain and don't create any objects.
			elif object is Vertex and chain_vertex == null:
				update_preview_edge(object, preview_vertex)
				chain_vertex = object

			# Case 3: We clicked a sticker and are not currently drawing a chain.
			elif object is Sticker and chain_vertex == null:
				var new_vertex = canvas.create_vertex(get_sticky_mouse_position())
				new_vertex.set_anchor_mode(Vertex.ANCHOR.STICKER, [object])
				update_preview_edge(new_vertex, preview_vertex)
				chain_vertex = new_vertex

			# Case 4: We clicked the virtual vertex and are currently drawing a chain.
			elif object == null and chain_vertex != null:
				var new_vertex = canvas.create_vertex(get_sticky_mouse_position())
				canvas.create_edge(chain_vertex, new_vertex)
				update_preview_edge(new_vertex, preview_vertex)
				chain_vertex = new_vertex

			# Case 5: We clicked an actual vertex and are currently drawing a chain.
			elif object is Vertex and chain_vertex != null:
				canvas.create_edge(chain_vertex, object)
				update_preview_edge(object, preview_vertex)
				chain_vertex = object

			# Case 6: We clicked a sticker and are currently drawing a chain.
			elif object is Sticker and chain_vertex != null:
				var new_vertex = canvas.create_vertex(get_sticky_mouse_position())
				new_vertex.set_anchor_mode(Vertex.ANCHOR.STICKER, [object])
				canvas.create_edge(chain_vertex, new_vertex)
				update_preview_edge(new_vertex, preview_vertex)
				chain_vertex = new_vertex

			set_input_as_handled()

		# If we right-click, we cancel the chain.
		if Input.is_action_just_pressed("RightClick"):
			delete_preview_edge()
			chain_vertex = null
			set_input_as_handled()
