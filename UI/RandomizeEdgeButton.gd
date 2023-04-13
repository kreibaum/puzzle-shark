extends PriorityButton


func _on_Button_pressed():
	# Check if exactly two points are selected in the canvas.selected_vertices
	# dictionary. If so, randomize the line between those two points.

	# Randomization essentially just deletes a line and creates a new one.
	var selected_edges = canvas.get_selected_edges()
	for edge in selected_edges:
		canvas.create_edge(edge.left_vertex, edge.right_vertex)
		canvas.delete_edge(edge)
