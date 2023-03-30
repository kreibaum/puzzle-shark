class_name DragDropHandle extends Area2D

var stored_position: Vector2 = Vector2.INF

func store_position(position_to_store: Vector2):
	stored_position = position_to_store

func unstore_position():
	stored_position = Vector2.INF

func restore_position():
	var position_to_restore = stored_position
	unstore_position()
	return position_to_restore

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

