class_name DeleteTool extends State

func delete_focused_object():
	var object = canvas.get_focused_object()
	if object is Vertex:
		canvas.delete_vertex(object)
	elif object is Edge:
		canvas.delete_edge(object)
	elif object is Sticker:
		canvas.delete_sticker(object)

func delete_selected_objects():
	var keys = canvas.selected_vertices.keys()
	for vertex in keys:
		canvas.delete_vertex(vertex)

func unhandled_input(event):
	if event is InputEventMouseButton:
		if Input.is_action_just_pressed("LeftClick"):
			delete_focused_object()

		if Input.is_action_just_pressed("RightClick"):
			delete_selected_objects()

	elif event is InputEventMouseMotion:
		if Input.is_action_pressed("LeftClick"):
			delete_focused_object()


	if Input.is_action_just_pressed("Delete"):
		delete_selected_objects()
