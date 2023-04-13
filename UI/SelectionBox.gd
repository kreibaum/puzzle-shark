class_name SelectionBox extends Area2D

## A SelectionBox to select arbitrary Area2D objects. If they have an
## .in_selection member, then they'll be notified if they are currently in the
## selection.

var current_selection: Array = []
var bbox: Rect2

var is_selecting: bool = false
var selection_start: Vector2
var selection_end: Vector2
var selection_needs_update: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass  # Replace with function body.

func _draw():
	var points = PackedVector2Array()
	points.append(Vector2(0, 0))
	points.append(Vector2(0, 1))
	points.append(Vector2(1, 1))
	points.append(Vector2(1, 0))
	points.append(Vector2(0, 0))
	draw_polyline(points, Color(0.3, 0.3, 0.3), -1, false)

## Start using the SelectionBox at the current mouse position.
func start_selection():
	is_selecting = true
	current_selection = []
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
	selection_needs_update = 0
	selection_start = Vector2.INF
	selection_end = Vector2.INF
	hide()
	# _update_selection()
	# selection_needs_update = 2


# Update collider & visual elements of the SelectionBox.
func _update_selection():
	transform = Transform2D(0, self.selection_end - self.selection_start, 0, self.selection_start)
	bbox = Rect2(transform * Vector2.ZERO, Vector2.ZERO)
	bbox = bbox.expand(transform * Vector2.ONE)
	selection_needs_update = 2

	if !is_selecting:
		hide()


func _process(_delta):
	# For performance reasons collisions are all processed at the same time.
	# This means updating the selection must happen defered.
	if selection_needs_update > 0:
		for vertex in current_selection:
			vertex.set_active(false)

		var overlapping_areas = get_overlapping_areas()
		current_selection = []

		
		for vertex in overlapping_areas:
			if vertex is Vertex and bbox.has_point(vertex.global_position):
				vertex.set_active(true)
				current_selection.append(vertex)

		selection_needs_update -= 1

