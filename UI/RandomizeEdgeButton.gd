extends Button

@export var canvas: PuzzleCanvas


func _ready():
	# hook up the button's "pressed" signal to our "_on_Button_pressed" callback
	pressed.connect(_on_Button_pressed)


func _on_Button_pressed():
	# Check if exactly two points are selected in the canvas.current_selection
	# dictionary. If so, randomize the line between those two points.

	# Randomization essentially just deletes a line and creates a new one.
	var selected_edges = canvas.get_selected_edges()
	for edge in selected_edges:
		canvas.create_edge(edge.left_vertex, edge.right_vertex)
		canvas.delete_edge(edge)
