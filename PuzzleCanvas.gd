class_name PuzzleCanvas extends Node2D

var handle_scene = preload("res://drag_drop_handle.tscn")
var edge_scene = preload("res://edge.tscn")

@export var camera: Camera2D

var points = {}

var current_hover = null
var current_selection:Array = Array()

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
			handle.was_clicked.connect(handle_was_clicked)
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

func handle_was_clicked(handle:DragDropHandle):
	print(handle)
	# This behaves a lot differently, depending on if you are in "shift mode"
	# where selection is additive.
	var selection_index = current_selection.find(handle)
	if Input.is_key_pressed(KEY_SHIFT):
		if selection_index >= 0:
			current_selection.remove_at(selection_index)
			handle.selected = false
		else:
			current_selection.append(handle)
			handle.selected = true
	elif selection_index < 0:
		for other_handle in current_selection:
			other_handle.selected = false
		current_selection.clear()
		current_selection.append(handle)
		handle.selected = true

func selection_box_finished(handles: Array):
	print("Selection box finished", handles)
	# This behaves a lot differently, depending on if you are in "shift mode"
	# where selection is additive.
	if Input.is_key_pressed(KEY_SHIFT):
		for handle in handles:
			if current_selection.find(handle) < 0:
				current_selection.append(handle)
				handle.selected = true
	else:
		for other_handle in current_selection:
			other_handle.selected = false
		current_selection.clear()
		current_selection.append_array(handles)
		for handle in handles:
			handle.selected = true

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and current_hover == null:
				$SelectionBox.start_selection()
			elif $SelectionBox.is_selecting:
				selection_box_finished($SelectionBox.current_selection)
				$SelectionBox.end_selection()
				
	elif event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_MASK_LEFT:
			$SelectionBox.move_selection()


