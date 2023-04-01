class_name StateMachine extends Node

@export var canvas: PuzzleCanvas
@export var ui_canvas: CanvasLayer

var current_state: State


# Called when the node enters the scene tree for the first time.
func _ready():
	current_state = SelectState.new()
	current_state.enter_state(canvas, ui_canvas)


func set_state(new_state: State):
	current_state.exit_state()
	current_state = new_state
	current_state.enter_state(canvas, ui_canvas)


func drag_drop_handle_input_event(handle: DragDropHandle, event: InputEvent):
	current_state.drag_drop_handle_input_event(handle, event)


func drag_drop_handle_hover_event(handle: DragDropHandle, is_hovering: bool):
	current_state.drag_drop_handle_hover_event(handle, is_hovering)


func edge_input_event(handle: Edge, event: InputEvent):
	current_state.edge_input_event(handle, event)


func unhandled_input(event: InputEvent):
	current_state.unhandled_input(event)
