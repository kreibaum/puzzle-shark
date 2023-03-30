extends Button

@export var canvas: PuzzleCanvas


func _ready():
	# hook up the button's "pressed" signal to our "_on_Button_pressed" callback
	pressed.connect(_on_Button_pressed)


func _on_Button_pressed():
	# Check if exactly two points are selected in the canvas.current_selection
	# dictionary. If so, add a delete the edge between them.

	for edge in canvas.get_selected_edges():
		canvas.delete_edge(edge)
