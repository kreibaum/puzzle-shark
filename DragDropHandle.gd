class_name DragDropHandle extends Area2D

var position_before_drag: Vector2 = Vector2.INF

var hovered: bool = false:
	set(value):
		hovered = value
		update_color()

var selected: bool = false:
	set(value):
		selected = value
		update_color()

var in_selection_box: bool = false:
	set(value):
		in_selection_box = value
		update_color()

@export var camera: Camera2D

## Signal to notify edges that they need to update their position.
signal position_changed

signal captured_input_event(DragDropHandle, InputEvent)
signal captured_hover_event(DragDropHandle, bool)


# Called when the node enters the scene tree for the first time.
func _ready():
	camera.zoom_changed.connect(update_zoom)


## Moves the handle by the given offset, but remembers where it was before the
## drag started so that it can be rolled back.
func preview_drag(delta: Vector2):
	if position_before_drag == Vector2.INF:
		position_before_drag = self.position
	move_to(position_before_drag + delta)


## Commits the drag, i.e. the handle is moved to the new position and the
## position before the drag is forgotten.
func commit_drag(delta: Vector2):
	preview_drag(delta)
	position_before_drag = Vector2.INF


## Rolls back the drag, i.e. the handle is moved back to the position before the
## drag started.
func rollback_drag():
	if position_before_drag != Vector2.INF:
		move_to(position_before_drag)
		position_before_drag = Vector2.INF


# Sets the position and triggers the signal so dependent objects can update.
func move_to(new_position):
	if self.position != new_position:
		self.position = new_position
		position_changed.emit()


func transform(transformation: Transform2D):
	self.position = transformation * self.position
	position_changed.emit()


# Called when the mouse is pressed
func _input_event(_viewport, event, _shape_index):
	captured_input_event.emit(self, event)


func _mouse_enter():
	captured_hover_event.emit(self, true)


func _mouse_exit():
	captured_hover_event.emit(self, false)


func update_color():
	if selected:
		$Polygon2D.color = "f5bf42"
	elif hovered or in_selection_box:
		$Polygon2D.color = "eb00cf"
	else:
		$Polygon2D.color = "ad40a0"


func update_zoom(zoom):
	self.scale = Vector2(1 / zoom.x, 1 / zoom.y)
