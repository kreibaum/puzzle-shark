class_name StateMachine extends Node

@export var canvas: PuzzleCanvas
@export var ui_canvas: CanvasLayer

var current_state: State


# Called when the node enters the scene tree for the first time.
func _ready():
	current_state = SelectTool.new()
	current_state.enter_state(canvas, ui_canvas)


func set_state(new_state: State):
	current_state.exit_state()
	current_state = new_state
	current_state.enter_state(canvas, ui_canvas)


func sticker_input_event(vertex: Sticker, event: InputEvent):
	current_state.sticker_input_event(vertex, event)


func sticker_hover_event(vertex: Sticker, is_hovering: bool):
	current_state.sticker_hover_event(vertex, is_hovering)


func edge_input_event(edge: Edge, event: InputEvent):
	current_state.edge_input_event(edge, event)


func unhandled_input(event: InputEvent):
	current_state.unhandled_input(event)


func input(event: InputEvent):
	current_state.input(event)
