class_name SelectionBox extends Area2D

## A SelectionBox to select arbitrary Area2D objects. If they have an
## .in_selection member, then they'll be notified if they are currently in the
## selection.

var current_selection: Array = Array()

var is_selecting: bool = false
var selection_start: Vector2
var selection_end: Vector2
var selection_needs_update: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

## Start using the SelectionBox at the current mouse position.
func start_selection():
	is_selecting = true
	selection_start = get_global_mouse_position()
	selection_end = selection_start
	_update_selection()
	show()

## Called for each mouse motion while the selection is active
func move_selection():
	if is_selecting:
		selection_end = get_global_mouse_position()
		_update_selection()

## Hides and closes the SelectionBox
func end_selection():
	is_selecting = false
	selection_start = Vector2.INF
	selection_end = Vector2.INF
	_update_selection()
	selection_needs_update = 2

# Update collider & visual elements of the SelectionBox.
func _update_selection():
	transform = Transform2D(0, self.selection_end - self.selection_start, 0, self.selection_start)
	selection_needs_update = 2
	
	if !is_selecting:
		hide()

func _process(_delta):
	# For performance reasons collisions are all processed at the same time.
	# This means updating the selection must happen defered.
	if selection_needs_update > 0:
		for handle in current_selection:
			if "in_selection_box" in handle:
				handle.in_selection_box = false
		current_selection = get_overlapping_areas()
		for handle in current_selection:
			if "in_selection_box" in handle:
				handle.in_selection_box = true
		selection_needs_update -= 1
