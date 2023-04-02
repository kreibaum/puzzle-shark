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


func vertex_input_event(vertex: Vertex, event: InputEvent):
	current_state.vertex_input_event(vertex, event)


func vertex_hover_event(vertex: Vertex, is_hovering: bool):
	current_state.vertex_hover_event(vertex, is_hovering)


func edge_input_event(edge: Edge, event: InputEvent):
	current_state.edge_input_event(edge, event)


func unhandled_input(event: InputEvent):
	current_state.unhandled_input(event)


func input(event: InputEvent):
	current_state.input(event)
