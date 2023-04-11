class_name PriorityButton extends Button

## Priority button that can consume events before the PuzzleCanvas.
## Is is important, that the priority button is BELOW the PuzzleCanvas
## in the scene tree.

@export var canvas: PuzzleCanvas

## Internal tracker to make sure we can capture a down-up sequence.
var click_started_on_button: bool = false


## Override this hook method with the actual button logic.
func _on_Button_pressed():
	pass


func _input(event):
	if is_hovered() || click_started_on_button:
		if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				click_started_on_button = true
				get_viewport().set_input_as_handled()
			else:
				click_started_on_button = false
				get_viewport().set_input_as_handled()
				if is_hovered():
					_on_Button_pressed()
