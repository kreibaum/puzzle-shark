class_name State extends Node

var canvas: PuzzleCanvas


## Called, before any events may be passed to this state.
func enter_state(new_canvas: PuzzleCanvas):
	canvas = new_canvas


## Called when the state is exited. After this there won't be any new events.
func exit_state():
	pass


func drag_drop_handle_input_event(handle: DragDropHandle, event: InputEvent):
	pass


func drag_drop_handle_hover_event(handle: DragDropHandle, is_hovering: bool):
	pass


func edge_input_event(handle: Edge, event: InputEvent):
	pass


func unhandled_input(event: InputEvent):
	pass
