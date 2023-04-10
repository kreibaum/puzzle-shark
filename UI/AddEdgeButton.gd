extends Button

@export var canvas: PuzzleCanvas


func _ready():
	# hook up the button's "pressed" signal to our "_on_Button_pressed" callback
	pressed.connect(_on_Button_pressed)


func _on_Button_pressed():
	# Check if exactly two points are selected in the canvas.selected_vertices
	# dictionary. If so, add a line between them.

	var selection: Dictionary = canvas.selected_vertices
	if selection.size() == 2 and canvas.get_selected_edges().size() == 0:
		var points: Array = selection.keys()
		canvas.create_edge(points[0], points[1])
