class_name State extends Node

var canvas: PuzzleCanvas
var ui_canvas: CanvasLayer


## Called, before any events may be passed to this state.
func enter_state(new_canvas: PuzzleCanvas, new_ui_canvas: CanvasLayer):
	canvas = new_canvas
	ui_canvas = new_ui_canvas
	after_enter_state()


## Version of enter_state that is called after enter_state and does not
## require the canvas and ui_canvas to be passed.
## This does nothing so no need to call super.
func after_enter_state():
	pass


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
