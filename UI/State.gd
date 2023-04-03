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


## Prevents the event from being passed to other parts of the application.
## This also means it won't come in again as an unhandled_input event.
func set_input_as_handled():
	ui_canvas.get_viewport().set_input_as_handled()


func vertex_input_event(vertex: Vertex, event: InputEvent):
	pass


func vertex_hover_event(vertex: Vertex, is_hovering: bool):
	pass


func edge_input_event(edge: Edge, event: InputEvent):
	pass


func sticker_input_event(vertex: Sticker, event: InputEvent):
	pass


func sticker_hover_event(vertex: Sticker, is_hovering: bool):
	pass


func unhandled_input(event: InputEvent):
	pass


func input(event: InputEvent):
	pass
