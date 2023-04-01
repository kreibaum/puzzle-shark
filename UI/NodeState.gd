class_name NodeState extends State

## This state makes a ghost handle follow the mouse. By clicking you place it
## and it becomes a real handle. By clicking on a handle you can move it.
## By right clicking you can delete a handle.

## Tracks on which object the mouse started its action
var vertex_on_which_click_started = null

# Variables related to dragging. INF means we are not dragging.
var drag_position: Vector2 = Vector2.INF

var preview = get_square()


## Called, before any events may be passed to this state.
func after_enter_state():
	ui_canvas.add_child(preview)
	preview.visible = canvas.current_hover == null


## Called when the state is exited. After this there won't be any new events.
func exit_state():
	preview.queue_free()


## This code is currently being shared with SelectState.gd via copy-paste.
func drag_drop_handle_hover_event(handle: DragDropHandle, is_hovering: bool):
	# If we are already hovering something, we don't want to change that.
	if canvas.current_hover != null and handle != canvas.current_hover:
		return

	handle.hovered = is_hovering

	# Our state machine should remember what we are currently hovering.
	if !handle.hovered:
		canvas.current_hover = null
	else:
		canvas.current_hover = handle

	preview.visible = canvas.current_hover == null


func unhandled_input(event):
	if event is InputEventMouseMotion:
		preview.position = ui_canvas.get_viewport().get_mouse_position()
	if event is InputEventMouseButton:
		if canvas.current_hover == null && event.button_index == MOUSE_BUTTON_LEFT:
			# Create a new vertex at the current position
			# This vertex is then automatically selected
			var handle = canvas.create_vertex(canvas.get_global_mouse_position())
			canvas.current_hover = handle
			canvas.deselect_all_handles()
			canvas.select_handle(handle)
			preview.visible = canvas.current_hover == null


## A squares that goes from -10 to 10 in both x and y
func get_square() -> Polygon2D:
	var points = PackedVector2Array()
	points.append(Vector2(-10, -10))
	points.append(Vector2(-10, 10))
	points.append(Vector2(10, 10))
	points.append(Vector2(10, -10))

	var square = Polygon2D.new()
	square.polygon = points
	square.color = Color(0.54901963472366, 0.29411765933037, 0.80000001192093, 0.61568629741669)
	return square
