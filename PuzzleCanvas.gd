class_name PuzzleCanvas extends Node2D

var handle_scene = preload("res://drag_drop_handle.tscn")
var edge_scene = preload("res://edge.tscn")

@export var camera: Camera2D

var points = {}

var current_hover = null

# Called when the node enters the scene tree for the first time.
func _ready():
	var w = 5
	var h = 3
	for x in range(0, w):
		for y in range(0, h):
			var handle = handle_scene.instantiate()
			points[Vector2i(x, y)] = handle
			handle.position = Vector2(200 * x, 200 * y)
			handle.z_index = 2
			handle.camera = camera
			handle.hover_changed.connect(current_hover_changed)
			add_child(handle)
	
	for x in range(1, w):
		for y in range(0, h):
			var edge : Edge = edge_scene.instantiate()
			edge.left_handle = points[Vector2i(x-1, y)]
			edge.right_handle = points[Vector2i(x, y)]
			edge.camera = camera
			add_child(edge)
	
	for x in range(0, w):
		for y in range(1, h):
			var edge : Edge = edge_scene.instantiate()
			edge.left_handle = points[Vector2i(x, y-1)]
			edge.right_handle = points[Vector2i(x, y)]
			edge.camera = camera
			add_child(edge)

func current_hover_changed(handle: DragDropHandle):
	if !handle.hovered:
		current_hover = null
	else:
		current_hover = handle

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and current_hover == null:
				$SelectionBox.start_selection()
			else:
				$SelectionBox.end_selection()
				
	elif event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_MASK_LEFT:
			$SelectionBox.move_selection()


