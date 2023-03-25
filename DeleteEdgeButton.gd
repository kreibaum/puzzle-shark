extends Button

@export var canvas: PuzzleCanvas


func _ready():
	# hook up the button's "pressed" signal to our "_on_Button_pressed" callback
	pressed.connect(_on_Button_pressed)


func _on_Button_pressed():
	# Check if exactly two points are selected in the canvas.current_selection
	# dictionary. If so, add a delete the edge between them.

	var selection: Dictionary = canvas.current_selection
	if selection.size() == 2:
		var points: Array = selection.keys()
		var edge = canvas.find_edge(points[0], points[1])
		canvas.delete_edge(edge)